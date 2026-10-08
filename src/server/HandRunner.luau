--!strict
-- HandRunner.luau — one hand against the bot, server-authoritative (0097): Ante, four bets and four
-- passes on §8's timeline, numeric contact resolution and the showdown knockdown (§4). The rules
-- are the sim's modules (ReplicatedStorage.Rules = sim/, 0096, 0098); this file is Hand.play's
-- flow in real time, numeric hands only (0099), with the human's input arriving over Net.Input and
-- the bot (Bot.luau) acting at its scripted times (0107). Every value is Rules.Config or Slice.
--
-- The client sends input only; the server resolves contact after aim lock (§3 *Aim lock*), and
-- sends the client only what §3 *Public vs hidden* lists plus its own hole cards (§7).

local HttpService = game:GetService("HttpService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Workspace = game:GetService("Workspace")

local Rules = ReplicatedStorage:WaitForChild("Rules")
local Cards = require(Rules:WaitForChild("Cards"))
local Contact = require(Rules:WaitForChild("Contact"))
local Dial = require(Rules:WaitForChild("Dial"))
local Hand = require(Rules:WaitForChild("Hand"))
local Timeline = require(Rules:WaitForChild("Timeline"))
local Slice = require(ReplicatedStorage:WaitForChild("Shared"):WaitForChild("Slice"))

local Bot = require(script.Parent:WaitForChild("Bot"))
local CueLog = require(script.Parent:WaitForChild("CueLog"))

local HandRunner = {}
HandRunner.__index = HandRunner

type Commit = { t: number, aim: number? }

type Rider = {
	seat: number,
	hole: { number },
	posture: number,
	battered: number,
	contributed: number,
	-- per pass
	aim: number?,
	tAim: number?,
	commits: { Commit },
	firstExit: number?,
	lockAt: number?, -- s into the pass after which input is refused (lock + the ♠/♦ extra time, 0069)
}

type PendingBet = { facing: boolean, canRaise: boolean, action: string?, t: number? }

export type HandRunner = typeof(setmetatable(
	{} :: {
		player: Player,
		update: RemoteEvent,
		cfg: any,
		oddsRef: { table: any? },
		rng: Random,
		riders: { Rider },
		board: { number },
		pass: number,
		passStart: number?,
		hasReveal: boolean,
		pendingBet: PendingBet?,
		log: { [string]: any },
		alive: boolean,
	},
	HandRunner
))

local HUMAN, BOT = Slice.seats.human, Slice.seats.bot
local SHOWN = { [0] = 0, 0, 3, 4, 5 }

local function now(): number
	return Workspace:GetServerTimeNow()
end

function HandRunner.new(player: Player, update: RemoteEvent, cfg: any, oddsRef: { table: any? }): HandRunner
	local self = setmetatable({
		player = player,
		update = update,
		cfg = cfg,
		oddsRef = oddsRef,
		rng = Random.new(),
		riders = {},
		board = {},
		pass = 0,
		passStart = nil,
		hasReveal = false,
		pendingBet = nil,
		log = {},
		alive = true,
	}, HandRunner)
	return self
end

function HandRunner.send(self: HandRunner, kind: string, payload: { [string]: any })
	self.update:FireClient(self.player, kind, payload)
end

function HandRunner.stop(self: HandRunner)
	self.alive = false
end

-- ── input (the client sends input only) ─────────────────────────────────────────────────────────

function HandRunner.onInput(self: HandRunner, kind: string, value: any)
	if kind == "aim" then
		if value ~= nil and (typeof(value) ~= "number" or value % 1 ~= 0 or value < 0 or value >= Dial.POSITIONS) then
			return
		end
		self:setAim(HUMAN, value)
	elseif kind == "bet" then
		local pending = self.pendingBet
		if pending == nil or pending.action ~= nil then
			return
		end
		if value == "yield" and pending.facing then
			pending.action = "yield"
		elseif value == "raise" and pending.canRaise then
			pending.action = "raise"
		elseif value == "stay" or value == "raise" or value == "yield" then
			pending.action = "stay" -- a Yield with no raise to face, or a raise over the cap, is a Stay
		else
			return
		end
	end
end

local function extraTime(aim: number?, cfg: any): number
	local w = Dial.lean(aim, cfg.sim.halfStepShare)
	return cfg.sim.extraTime * math.min(1, w[2] + w[4])
end

-- A rider's lock (§3 *Aim lock*): 7.7 s, later by the extra time of a lean into ♠ or ♦ (0069),
-- fixed from the aim held at 7.7 s. A function of the clock alone, so a slow server frame can't let
-- a late input through.
function HandRunner.lockOf(self: HandRunner, r: Rider, t: number): number
	local tl = self.cfg.spec.timeline
	if r.lockAt == nil and t >= tl.lock then
		r.lockAt = tl.lock + extraTime(r.aim, self.cfg)
	end
	return r.lockAt or tl.lock
end

-- A rider's aim changes during a pass; refused at or after their lock. Public: both riders see it (§3).
function HandRunner.setAim(self: HandRunner, seat: number, aim: number?)
	local start = self.passStart
	if start == nil then
		return
	end
	local r = self.riders[seat]
	local t = now() - start
	if t >= self:lockOf(r, t) then
		return
	end
	if aim == r.aim then
		return
	end
	r.aim = aim
	r.tAim = if aim == nil then nil else t
	table.insert(r.commits, { t = t, aim = aim })
	if aim ~= nil and r.firstExit == nil then
		r.firstExit = t
	end
	self:send("aim", { seat = seat, aim = aim, t = t })
end

-- ── the deal ────────────────────────────────────────────────────────────────────────────────────

local function revealed(board: { number }, pass: number): { number }
	return table.move(board, 1, SHOWN[pass], 1, {})
end

local function colorOf(card: number): string
	local s = Cards.suit(card)
	return if s == Cards.HEART or s == Cards.DIAMOND then "red" else "black"
end

-- Numeric hands only (0099): redeal until neither rider can make a straight or better by the river.
function HandRunner.deal(self: HandRunner): number
	local redeals = 0
	while true do
		local deck = Cards.shuffled(function()
			return self.rng:NextNumber()
		end)
		local board = { deck[5], deck[6], deck[7], deck[8], deck[9] }
		local holes = { { deck[1], deck[2] }, { deck[3], deck[4] } }
		local numeric = true
		if Slice.deal.numericOnly then
			for _, hole in holes do
				local all = table.clone(hole)
				for _, c in board do
					table.insert(all, c)
				end
				if Cards.evaluate(all).category > Cards.TRIPS then
					numeric = false
				end
			end
		end
		if numeric or redeals >= Slice.deal.maxRedeals then
			self.board = board
			for seat = 1, 2 do
				self.riders[seat] = {
					seat = seat,
					hole = holes[seat],
					posture = self.cfg.spec.postureStart,
					battered = 0,
					contributed = self.cfg.spec.ante,
					aim = nil,
					tAim = nil,
					commits = {},
					firstExit = nil,
					lockAt = nil,
				}
			end
			return redeals
		end
		redeals += 1
	end
end

-- ── betting (§2 *Betting rules*) ─────────────────────────────────────────────────────────────────

function HandRunner.awaitHumanBet(self: HandRunner, facing: boolean, canRaise: boolean): (string, number)
	local pending: PendingBet = { facing = facing, canRaise = canRaise, action = nil, t = nil }
	self.pendingBet = pending
	local started = now()
	local deadline = started + Slice.betTimer
	while self.alive and pending.action == nil and now() < deadline do
		task.wait(0.05)
	end
	self.pendingBet = nil
	local t = now() - started
	return pending.action or "stay", math.min(t, Slice.betTimer) -- timeout defaults to Stay (§2)
end

-- One fixed-limit round: the button acts first, one re-raise cap, a Yield only facing a raise
-- (0081). Returns the seat that Yields, if any.
function HandRunner.betRound(self: HandRunner, round: number, known: { number }, button: number): number?
	local spec = self.cfg.spec
	local size = spec.raise[round]
	local raises, acted, i = 0, 0, button
	while self.alive do
		local r, o = self.riders[i], self.riders[3 - i]
		local facing = r.contributed < o.contributed
		local canRaise = raises < 2
		self:send("bet", {
			round = round,
			seat = i,
			facing = facing,
			canRaise = canRaise,
			raiseSize = size,
			contributed = { self.riders[1].contributed, self.riders[2].contributed },
			deadline = now() + Slice.betTimer,
			timer = Slice.betTimer,
		})
		local action: string, t: number
		local botOdds = false
		if i == HUMAN then
			action, t = self:awaitHumanBet(facing, canRaise)
		else
			local think = self.rng:NextNumber(Slice.bot.thinkMin, Slice.bot.thinkMax)
			task.wait(think)
			local odds = self.oddsRef.table
			botOdds = odds ~= nil
			local profile = self.cfg.riders[Slice.bot.profile]
			action = Bot.bet(profile, odds, round, r.hole, known, r.posture, o.posture, facing, canRaise, self.cfg, self.rng)
			t = think
		end
		table.insert(self.log.bets, { round = round, seat = i, action = action, t = t, facing = facing, bands = if i == BOT then botOdds else nil })
		if action == "yield" then
			self:send("betAction", { round = round, seat = i, action = action, contributed = { self.riders[1].contributed, self.riders[2].contributed } })
			return i
		end
		if action == "raise" then
			r.contributed = o.contributed + size
			raises += 1
			acted = 1
		else
			r.contributed = o.contributed
			acted += 1
		end
		self:send("betAction", { round = round, seat = i, action = action, contributed = { self.riders[1].contributed, self.riders[2].contributed } })
		if acted >= 2 then
			return nil
		end
		i = 3 - i
	end
	return nil
end

-- ── the pass (§8 timeline) ──────────────────────────────────────────────────────────────────────

-- Runs one pass: the charge on §8's timeline (the bot acting at its scripted times), then contact,
-- resolved as Hand.play resolves a numeric pass. Sends "contact" and adds the pass to the cue log.
function HandRunner.runPass(self: HandRunner, pass: number)
	local cfg = self.cfg
	local spec, sim = cfg.spec, cfg.sim
	local tl = spec.timeline
	local hasReveal = SHOWN[pass] > SHOWN[pass - 1]
	local prevBoard, newBoard = revealed(self.board, pass - 1), revealed(self.board, pass)
	for _, r in self.riders do
		r.aim, r.tAim, r.commits, r.firstExit, r.lockAt = nil, nil, {}, nil, nil
	end
	self.pass, self.hasReveal = pass, hasReveal
	local start = now()
	self.passStart = start
	self:send("pass", {
		pass = pass,
		startAt = start,
		board = prevBoard,
		reveal = if hasReveal then { at = start + tl.reveal, cards = newBoard } else nil,
		posture = { self.riders[1].posture, self.riders[2].posture },
		battered = { self.riders[1].battered > 0, self.riders[2].battered > 0 },
	})

	-- The bot's plan for the pass (Bot.luau: stance, re-stance, read).
	local bot, human = self.riders[BOT], self.riders[HUMAN]
	local profile = cfg.riders[Slice.bot.profile]
	local plan = Bot.stance(profile, bot.hole, prevBoard, cfg, self.rng)
	local committed, restanced, readDone, locked, reread = false, false, false, false, false
	local readTaken = false
	while self.alive do
		local t = now() - start
		if not committed and t >= plan.tAim then
			committed = true
			self:setAim(BOT, plan.aim)
		end
		if hasReveal and not restanced and t >= tl.slowEnd then
			restanced = true
			local a = Bot.restance(plan, bot.hole, newBoard, cfg, self.rng)
			if a ~= nil then
				plan.aim = a
				plan.tAim = math.max(plan.tAim, tl.slowEnd)
				if committed then
					self:setAim(BOT, a)
				end
			end
		end
		if not readDone and t >= sim.readTime then
			readDone = true
			if self.rng:NextNumber() < profile.read then
				readTaken = true
				local a = Bot.read(bot.hole, newBoard, bot.aim or plan.aim, bot.tAim or sim.readTime, bot.battered, human.aim, human.tAim, human.battered, pass, hasReveal, cfg)
				if a ~= bot.aim then
					self:setAim(BOT, a)
				end
			end
		end
		if not locked and t >= tl.lock then
			locked = true
			for _, r in self.riders do
				self:lockOf(r, t)
			end
		end
		-- Leaning further into ♠ or ♦ locks later (0069): a bot that read this pass and locks after
		-- the human re-reads against the human's final aim once the human is locked, as Hand.play's
		-- rider with more extra time does.
		if
			locked
			and readTaken
			and not reread
			and human.lockAt ~= nil
			and bot.lockAt ~= nil
			and (bot.lockAt :: number) > (human.lockAt :: number) + 1e-9
			and t >= (human.lockAt :: number)
		then
			reread = true
			local a = Bot.read(bot.hole, newBoard, bot.aim or plan.aim, bot.tAim or sim.readTime, bot.battered, human.aim, human.tAim, human.battered, pass, hasReveal, cfg)
			if a ~= bot.aim then
				self:setAim(BOT, a)
			end
		end
		if t >= spec.passLength then
			break
		end
		task.wait()
	end
	self.passStart = nil
	if not self.alive then
		return
	end

	-- Contact (§4 *Contact resolution*, as Hand.play resolves it for numeric hands).
	local arena: Contact.Arena = { street = spec.street[pass], openLists = 1, siege = 1 }
	local F: { Contact.Fighter } = {}
	local pts: { { number } } = {}
	for seat, r in self.riders do
		pts[seat] = Cards.points(r.hole, newBoard, spec)
		local S, cut = Hand.statsAt(pts[seat], r.aim, cfg)
		F[seat] = {
			aim = r.aim,
			h = Timeline.hold(r.tAim, cfg, hasReveal),
			S = S,
			buffer = cut,
			battered = r.battered,
			trick = nil,
			ward = 0,
		}
	end
	local made = { Contact.strike(F[1], F[2], arena, cfg), Contact.strike(F[2], F[1], arena, cfg) }
	local whole = cfg.switches.posture == "pips"
	local function pips(x: number): number
		return if whole then math.floor(x + 0.5) else x
	end
	local function healPips(x: number): number
		if whole and cfg.switches.healRound == "up" then
			return math.ceil(x - 1e-9)
		end
		return pips(x)
	end
	local knockdownPass = pass == 4 and cfg.switches.riverRule == "knockdown"
	local bars = {}
	local before = { self.riders[1].posture, self.riders[2].posture }
	for seat, r in self.riders do
		local o = self.riders[3 - seat]
		local taken, own = made[3 - seat], made[seat]
		local p = r.posture - pips(taken.dmg) - pips(own.reflect)
		if taken.cleanBlock then
			p = math.min(spec.postureStart, p + pips(spec.cleanBlockRestore))
		end
		local atContact = p
		-- Step 7: on Passes 1–3 a rider at 0 is unhorsed before any heal.
		if knockdownPass or p > 0 then
			local lost = before[seat] - p
			if lost > 0 then
				local share = sim.healBase + sim.healPerPoint * pts[seat][3]
				p = math.min(spec.postureStart, p + healPips(lost * math.min(1, share)))
			end
		end
		r.posture = p
		-- Battered (0068): this contact used it up; an aimed ♣ hit that got through applies it anew.
		r.battered = 0
		if taken.through > 0 then
			local wClub = Dial.lean(o.aim, sim.halfStepShare)[1]
			if wClub > 0 then
				r.battered = sim.battered * wClub
			end
		end
		bars[seat] = {
			before = before[seat],
			hit = before[seat] - atContact, -- half hearts lost at contact (negative: a clean block's restore)
			atContact = atContact,
			heal = p - atContact,
			after = p,
			battered = r.battered > 0,
		}
	end
	local strikes = {}
	local aims = {}
	for seat = 1, 2 do
		strikes[seat] = { tier = made[seat].tier, cleanBlock = made[seat].cleanBlock }
		aims[seat] = { aim = self.riders[seat].aim, tAim = self.riders[seat].tAim, h = F[seat].h, firstExit = self.riders[seat].firstExit }
	end
	self:send("contact", { pass = pass, strikes = strikes, bars = bars, aims = aims })

	-- The cue log's pass record.
	local riders = {}
	for seat = 1, 2 do
		local r = self.riders[seat]
		riders[seat] = {
			commits = r.commits,
			firstExit = r.firstExit,
			aim = r.aim,
			tAim = r.tAim,
			h = F[seat].h,
			tier = made[seat].tier,
			hit = bars[seat].hit,
			heal = bars[seat].heal,
			cleanBlock = made[3 - seat].cleanBlock,
			battered = F[seat].battered > 0,
			before = bars[seat].before,
			after = bars[seat].after,
		}
	end
	table.insert(self.log.passes, { pass = pass, riders = riders })
end

-- ── one hand ────────────────────────────────────────────────────────────────────────────────────

function HandRunner.playHand(self: HandRunner)
	local cfg = self.cfg
	local spec = cfg.spec
	local redeals = self:deal()
	local button = self.rng:NextInteger(1, 2)
	local handId = HttpService:GenerateGUID(false)
	local colors = {}
	for seat, r in self.riders do
		-- The lance shows one hole card's color and the shield the other's, assigned at random (§7).
		local lanceCard = self.rng:NextInteger(1, 2)
		colors[seat] = { lance = colorOf(r.hole[lanceCard]), shield = colorOf(r.hole[3 - lanceCard]) }
	end
	self.log = {
		handId = handId,
		placeId = game.PlaceId,
		time = os.time(),
		bot = { profile = Slice.bot.profile },
		button = button,
		seats = { human = HUMAN, bot = BOT },
		hole = { self.riders[1].hole, self.riders[2].hole },
		board = self.board,
		redeals = redeals,
		color = colors,
		passes = {},
		bets = {},
		finish = {},
	}
	self:send("hand", {
		handId = handId,
		you = HUMAN,
		button = button,
		hole = self.riders[HUMAN].hole,
		bot = { profile = if Slice.bot.showProfile then Slice.bot.profile else nil },
		colors = colors,
		posture = { spec.postureStart, spec.postureStart },
		contributed = { spec.ante, spec.ante },
	})

	local winner, how, endPass = 0, "showdown", 4
	local reveal = false -- hole cards revealed at hand end: unhorse or showdown, not a Yield (§7)
	for pass = 1, 4 do
		local yielder = self:betRound(pass, revealed(self.board, pass - 1), button)
		if not self.alive then
			return
		end
		if yielder then
			winner, how, endPass = 3 - yielder, "yield", pass
			break
		end
		self:runPass(pass)
		if not self.alive then
			return
		end
		local p1, p2 = self.riders[1].posture, self.riders[2].posture
		if pass < 4 and (p1 <= 0 or p2 <= 0) then
			local b = self.log.passes[#self.log.passes].riders
			if p1 <= 0 and p2 <= 0 then
				winner = if b[1].before > b[2].before then 1 elseif b[2].before > b[1].before then 2 else 0
			else
				winner = if p1 <= 0 then 2 else 1
			end
			how, endPass, reveal = "unhorse", pass, true
		end
		-- The beats after contact (0106): the hits, the ♥ heal, then the post-pass reveal (§7).
		task.wait(Slice.beats.reveal + Slice.beats.revealHold)
		if how == "unhorse" then
			break
		end
	end

	local bonus, category = { 0, 0 }, { 0, 0 }
	if how == "showdown" then
		-- The showdown knockdown (§4 *Tracks and showdown*, 0050, 0053): each hand bonus is added
		-- to Posture, below 0 included; the lower rider falls; level on half hearts, kickers decide.
		local e = {}
		local s = {}
		for seat, r in self.riders do
			local all = table.clone(r.hole)
			for _, c in self.board do
				table.insert(all, c)
			end
			e[seat] = Cards.evaluate(all)
			category[seat] = e[seat].category
			bonus[seat] = spec.showdownBonus * e[seat].category
			s[seat] = r.posture + bonus[seat]
		end
		local kickers = false
		if s[1] ~= s[2] then
			winner = if s[1] > s[2] then 1 else 2
		elseif e[1].value ~= e[2].value then
			winner = if e[1].value > e[2].value then 1 else 2
			kickers = true
		end
		reveal = true
		self:send("showdown", {
			hole = { self.riders[1].hole, self.riders[2].hole },
			category = category,
			bonus = bonus,
			standing = s,
			winner = winner,
			kickers = kickers,
		})
		task.wait(Slice.beats.showdownCards + Slice.beats.showdownBonus + Slice.beats.knockdown)
	end

	local units = { 0, 0 }
	if winner ~= 0 then
		local loser = self.riders[3 - winner]
		units[winner] = loser.contributed
		units[3 - winner] = -loser.contributed
	end
	self.log.finish = {
		winner = winner,
		how = how,
		pass = endPass,
		units = units,
		bonus = bonus,
		category = category,
		contributed = { self.riders[1].contributed, self.riders[2].contributed },
	}
	CueLog.write(self.log)
	self:send("handEnd", {
		winner = winner,
		how = how,
		pass = endPass,
		units = units,
		hole = if reveal then { self.riders[1].hole, self.riders[2].hole } else nil,
	})
end

-- Hand after hand while the player stays.
function HandRunner.run(self: HandRunner)
	task.spawn(function()
		while self.alive and self.player.Parent == Players do
			self:playHand()
			if self.alive then
				task.wait(Slice.beats.handEnd)
			end
		end
	end)
end

return HandRunner
