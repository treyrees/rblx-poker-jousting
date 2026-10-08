--!strict
-- Main.client.luau — the playable slice's client (0097). It sends input only (the wheel's aim
-- position during a pass, and bets); the server resolves everything (§3 *Aim lock*). It shows what
-- the server sends: GAME_SPEC §3's public cues plus the player's own hole cards, and the
-- opponent's hole cards only at hand end (§7).

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local Rules = ReplicatedStorage:WaitForChild("Rules")
local Cards = require(Rules:WaitForChild("Cards"))
local Config = require(Rules:WaitForChild("Config"))
local Dial = require(Rules:WaitForChild("Dial"))
local Hand = require(Rules:WaitForChild("Hand"))
local Timeline = require(Rules:WaitForChild("Timeline"))
local Shared = ReplicatedStorage:WaitForChild("Shared")
local Net = require(Shared:WaitForChild("Net"))
local Slice = require(Shared:WaitForChild("Slice"))

local Hud = require(script.Parent:WaitForChild("Hud"))
local Wheel = require(script.Parent:WaitForChild("Wheel"))

local cfg = Config.defaults()
local spec = cfg.spec
local tl = spec.timeline
local update, input = Net.client()
local hud = Hud.new(Players.LocalPlayer:WaitForChild("PlayerGui"))
hud.setTimeline(tl, spec.passLength)

local TIER = { crit = "Crit", normal = "Normal", block = "Block", weak = "Weak", parried = "Parried" }
local STREET = { [2] = "Flop", [3] = "Turn", [4] = "River" }

type Aim = { aim: number?, tAim: number? }

local state = {
	you = 1,
	opp = 2,
	oppName = "House rider",
	hole = {} :: { number },
	board = {} :: { number },
	pass = 0,
	startAt = nil :: number?,
	reveal = nil :: { at: number, cards: { number } }?,
	revealShown = false,
	aims = { {}, {} } :: { Aim },
	live = false, -- the wheel's position is being sent
	betDeadline = nil :: number?,
	contributed = { spec.ante, spec.ante },
}

local function now(): number
	return Workspace:GetServerTimeNow()
end

local function nameOf(seat: number): string
	return if seat == state.you then "You" else state.oppName
end

local function setPot()
	local c = state.contributed
	hud.setPot(string.format("pot %d units  (you %d, %s %d)", c[1] + c[2], c[state.you], state.oppName, c[state.opp]))
	hud.setUnits(state.you, string.format("in: %d", c[state.you]))
	hud.setUnits(state.opp, string.format("in: %d", c[state.opp]))
end

local function knownBoard(): { number }
	local r = state.reveal
	if r and state.revealShown then
		return r.cards
	end
	return state.board
end

local function extraTime(aim: number?): number
	local w = Dial.lean(aim, cfg.sim.halfStepShare)
	return cfg.sim.extraTime * math.min(1, w[2] + w[4])
end

local wheel = Wheel.new(hud.wheelHolder, cfg, function(pos: number?)
	if state.live then
		input:FireServer("aim", pos)
	end
end)

-- ── server updates ──────────────────────────────────────────────────────────────────────────────

local handlers: { [string]: (any) -> () } = {}

function handlers.hand(p: any)
	state.you, state.opp = p.you, 3 - p.you
	state.oppName = if p.bot.profile then "House rider: " .. string.upper(string.sub(p.bot.profile, 1, 1)) .. string.sub(p.bot.profile, 2) else "House rider"
	state.hole, state.board = p.hole, {}
	state.pass, state.startAt, state.reveal, state.revealShown = 0, nil, nil, false
	state.aims = { {}, {} }
	state.contributed = p.contributed
	hud.bindSeats(state.you)
	hud.hideResult()
	hud.hideBanner()
	hud.clearLog()
	hud.setName(state.you, "You")
	hud.setName(state.opp, state.oppName)
	for seat = 1, 2 do
		hud.setPosture(seat, p.posture[seat])
		hud.setHold(seat, nil)
		hud.setAim(seat, nil)
		hud.setColors(seat, p.colors[seat].lance, p.colors[seat].shield)
		hud.setStatus(seat, if seat == p.button then "button" else "")
	end
	hud.setHole(state.hole)
	hud.setOppHole(nil)
	hud.setBoard({})
	hud.setClock(nil, spec.passLength, "")
	wheel.reset()
	wheel.setOpponentAim(nil)
	wheel.setEnabled(false)
	setPot()
	hud.log(string.format("New hand. Button: %s (coin flip)", nameOf(p.button)))
end

function handlers.bet(p: any)
	state.contributed = p.contributed
	setPot()
	state.betDeadline = p.deadline
	local mine = p.seat == state.you
	local title = string.format("Bet before Pass %d", p.round)
	local info: string
	if mine then
		info = if p.facing then string.format("%s raised: Stay calls %d", state.oppName, p.raiseSize) else string.format("raise is %d unit%s", p.raiseSize, if p.raiseSize == 1 then "" else "s")
		if not p.canRaise then
			info ..= " · re-raise cap reached"
		end
	else
		info = state.oppName .. " is thinking…"
	end
	hud.showBet(title, info, mine, p.facing, p.canRaise, function(action: string)
		hud.lockBet()
		input:FireServer("bet", action)
	end)
end

function handlers.betAction(p: any)
	state.contributed = p.contributed
	setPot()
	local word = if p.action == "raise" then "Raise" elseif p.action == "yield" then "Yield" else "Stay"
	hud.log(string.format("Bet %d: %s %s", p.round, nameOf(p.seat), word))
	if p.seat == state.you then
		hud.lockBet()
	end
	if p.action == "yield" then
		hud.hideBet()
	end
end

function handlers.pass(p: any)
	hud.hideBet()
	state.betDeadline = nil
	state.pass, state.startAt = p.pass, p.startAt
	state.board = p.board
	state.reveal, state.revealShown = p.reveal, false
	state.aims = { {}, {} }
	hud.setBoard(state.board)
	for seat = 1, 2 do
		hud.setPosture(seat, p.posture[seat])
		hud.setHold(seat, 0)
		hud.setAim(seat, nil)
		local status = if p.battered[seat] then "Battered" else ""
		hud.setStatus(seat, status)
	end
	wheel.reset() -- Neutral at the start of every pass (§3)
	wheel.setOpponentAim(nil)
	wheel.setEnabled(true)
	state.live = true
	hud.log(string.format("Pass %d: charge", p.pass))
end

function handlers.aim(p: any)
	state.aims[p.seat] = { aim = p.aim, tAim = if p.aim == nil then nil else p.t }
	hud.setAim(p.seat, p.aim)
	if p.seat == state.opp then
		wheel.setOpponentAim(p.aim)
	end
end

function handlers.contact(p: any)
	state.live = false
	wheel.setEnabled(false)
	state.startAt = nil
	hud.setClock(spec.passLength, spec.passLength, string.format("Pass %d · contact", p.pass))
	-- The hits land at once (the ♥ buffer netted in, 0093).
	for seat = 1, 2 do
		local b = p.bars[seat]
		hud.setPosture(seat, b.atContact)
		hud.setHold(seat, p.aims[seat].h)
		if b.hit > 0 then
			hud.float(seat, "−" .. Hud.hearts(b.hit), Hud.COLOR.hit, Slice.beats.heal)
		elseif b.hit < 0 then
			hud.float(seat, "clean block +" .. Hud.hearts(-b.hit), Hud.COLOR.heal, Slice.beats.heal)
		else
			hud.float(seat, "no damage", Hud.COLOR.dim, Slice.beats.heal)
		end
	end
	-- The ♥ heal, its own beat (0093, 0106).
	task.delay(Slice.beats.heal, function()
		for seat = 1, 2 do
			local b = p.bars[seat]
			hud.setPosture(seat, b.after)
			if b.heal > 0 then
				hud.float(seat, "+" .. Hud.hearts(b.heal) .. " heal", Hud.COLOR.heal, Slice.beats.reveal - Slice.beats.heal + 0.4)
			end
			hud.setStatus(seat, if b.battered then "Battered" else "")
		end
	end)
	-- The post-pass reveal (§7): both aims, hold meters and the tiers landed.
	task.delay(Slice.beats.reveal, function()
		local lines = {}
		for _, seat in { state.you, state.opp } do
			local a = p.aims[seat]
			local s = p.strikes[seat]
			table.insert(lines, string.format("%s: %s, held %d%% · strike lands %s", nameOf(seat), Hud.aimName(a.aim), math.floor(a.h * 100 + 0.5), TIER[s.tier] or s.tier))
		end
		hud.banner(table.concat(lines, "\n"), Slice.beats.revealHold)
		local b = p.bars
		hud.log(string.format("Pass %d: you %s, them %s", p.pass, Hud.hearts(b[state.you].after - b[state.you].before), Hud.hearts(b[state.opp].after - b[state.opp].before)))
	end)
end

function handlers.showdown(p: any)
	-- The hole cards flip, each hand bonus pours into the bar, then the knockdown (§8 *Showdown*).
	hud.setOppHole(p.hole[state.opp])
	task.delay(Slice.beats.showdownCards, function()
		for seat = 1, 2 do
			local c = p.category[seat]
			hud.setPosture(seat, p.standing[seat])
			hud.float(seat, string.format("%s +%s", string.upper(Cards.NAME[c]), Hud.hearts(p.bonus[seat])), Hud.COLOR.gold, Slice.beats.showdownBonus + Slice.beats.knockdown)
		end
	end)
	task.delay(Slice.beats.showdownCards + Slice.beats.showdownBonus, function()
		local text: string
		if p.winner == 0 then
			text = "Level on Posture and on the hands: a split"
		else
			text = nameOf(3 - p.winner) .. (if 3 - p.winner == state.you then " are" else " is") .. " knocked down"
			if p.kickers then
				text ..= " (level on half hearts; kickers decide)"
			end
		end
		hud.banner(text, Slice.beats.knockdown)
	end)
end

function handlers.handEnd(p: any)
	hud.hideBet()
	state.live = false
	wheel.setEnabled(false)
	if p.hole then
		hud.setOppHole(p.hole[state.opp])
	end
	local how: string
	if p.how == "unhorse" then
		how = string.format("unhorsed on Pass %d", p.pass)
	elseif p.how == "yield" then
		how = string.format("%s yielded before Pass %d", nameOf(3 - p.winner), p.pass)
	else
		how = "showdown"
	end
	local headline: string
	if p.winner == 0 then
		headline = "Split"
	elseif p.winner == state.you then
		headline = string.format("You win +%d units", p.units[state.you])
	else
		headline = string.format("You lose %d units", -p.units[state.you])
	end
	hud.showResult(headline .. "\n" .. how .. "\nnext hand shortly")
end

update.OnClientEvent:Connect(function(kind: string, payload: any)
	local h = handlers[kind]
	if h then
		h(payload)
	end
end)

-- ── every frame: the clock, the hold meters, the reveal, the lock, the stat meter ───────────────

RunService.RenderStepped:Connect(function()
	local t0 = state.startAt
	if t0 then
		local t = now() - t0
		local hasReveal = state.reveal ~= nil
		local r = state.reveal
		local beat = if t < tl.reveal and hasReveal then "approach"
			elseif hasReveal and t < tl.slowEnd then "slow motion"
			elseif t < tl.lock then "decide"
			else "locked"
		hud.setClock(t, spec.passLength, string.format("Pass %d · %.1f s · %s", state.pass, math.min(t, spec.passLength), beat))
		hud.setSlow(hasReveal and t >= tl.reveal and t < tl.slowEnd)
		-- The reveal (§8): the card lands at 3.0 s; the UI evaluates the new hand at once.
		if r and not state.revealShown and now() >= r.at then
			state.revealShown = true
			hud.setBoard(r.cards)
			local _, sub = Cards.points(state.hole, r.cards, spec)
			local shown = {}
			for i = #state.board + 1, #r.cards do
				table.insert(shown, Cards.show(r.cards[i]))
			end
			hud.banner(string.format("%s: %s · you have %s", STREET[state.pass] or "Reveal", table.concat(shown, " "), Cards.NAME[sub]), tl.slowEnd - tl.reveal)
		end
		-- The public hold meters (§3 *Held aim*), live.
		for seat = 1, 2 do
			local a = state.aims[seat]
			hud.setHold(seat, Timeline.holdAt(a.tAim, t, cfg, hasReveal))
		end
		-- Aim lock (§3): at 7.7 s, a little later when leaning into ♠ or ♦ (0069). The server enforces it.
		if state.live and t >= tl.lock + extraTime(wheel.position()) then
			state.live = false
			wheel.setEnabled(false)
		end
	end
	local d = state.betDeadline
	if d then
		hud.setBetTimer((d - now()) / Slice.betTimer)
	end
	-- The stat meter: your four stats with the current lean, live as you rotate (§4).
	local pts = Cards.points(state.hole, knownBoard(), spec)
	local S, buffer = Hand.statsAt(pts, wheel.position(), cfg)
	hud.setStats(S, buffer, spec.statBase)
end)
