--!strict
-- Hand.luau — plays one hand: Ante, four bets, four passes, showdown (GAME_SPEC §2), with scripted
-- riders (§11 *Sim plan* step 2). Returns a record the runner turns into metrics.
--
-- The aim war is abstracted. Each pass a rider:
--   1. sets a stance at a time set by hold discipline: honest riders lean toward their loaded stats
--      (§4 *Stances*), the rest pick a random aim;
--   2. after the reveal, an honest rider whose best lean moved re-stances at the decision window;
--   3. decides unleashes (aggression) and, on an unleash pass, plays the trick to its design or not;
--   4. with chance `read`, switches late (readTime) to the best aim against the opponent's public
--      aim and hold. Reads are simultaneous and blind to each other, except that a rider whose aim
--      leans further into ♠ or ♦ locks later (0069) and so moves last.
-- With the reading model on (cfg.reading, sim/Read.luau), each rider also keeps a belief about the
-- opponent's hole cards from the public cues, and a read (reading.aim) or a bet (reading.betting)
-- can play against it.
-- h follows from when the final aim was set (Timeline). Contact resolves both strikes at once.

local Cards = require("./Cards")
local Dial = require("./Dial")
local Timeline = require("./Timeline")
local Tricks = require("./Tricks")
local Contact = require("./Contact")
local Odds = require("./Odds")
local Read = require("./Read")

local Hand = {}

type Profile = {
	read: number,
	hold: number,
	honesty: number,
	aggression: number,
	design: number,
	yieldBelow: number,
	raiseAt: { number },
	yieldAt: { number },
	readSkill: number?,
}

-- Hand.play options: `spots` records each rider's betting spot at every bet reached (Odds); `trace`
-- records Posture after each pass and the flop categories (--report info); `info` tallies what the
-- readers learned, cue by cue (Read).
export type Options = { spots: boolean?, trace: boolean?, info: { [string]: number }? }

type Rider = {
	id: number,
	p: Profile,
	hole: { number },
	posture: number,
	maxPosture: number,
	battered: number, -- Battered through the next contact (0068): extra share of damage taken
	batteredHand: number, -- Battered for the rest of the hand (♣ Shattering Blow, 0072)
	spent: boolean, -- the trick's once-per-hand unleash is used (or clashed)
	contributed: number,
	heldRung: number?, -- rung of a trick the rider held past a decision
	heldAbove: boolean, -- ...while above the opponent
	drawnOut: boolean,
	-- per pass
	aim: number?,
	tAim: number?,
	honest: boolean,
	plan: boolean, -- unleashing this pass
	lockAim: boolean, -- playing a trick to design: doesn't move
	status: Tricks.Status,
	obsA0: number, -- the stance committed at the start of the pass (the reading model's cue)
	obsEarly: boolean,
}

export type TrickRecord = {
	rider: number,
	rung: number,
	key: string,
	how: string, -- unleash | answer | autofire
	designed: boolean,
	oppRung: number, -- opponent's rung when it fired (their firing rung, else where they stand)
	pass: number,
	clashed: boolean,
	won: boolean?,
}

export type Record = {
	winner: number, -- 1, 2, or 0 for a split
	finish: string, -- unhorse | showdown | yield
	pass: number, -- pass the hand ended on (4 for showdown; 5 when a final charge was ridden)
	category: { number }, -- river best-five category per rider
	value: { number },
	riverRung: { number },
	tricks: { TrickRecord },
	heldAbove: { boolean }, -- held a trick past a decision while above the opponent
	drawnOut: { boolean },
	units: { number },
	contributed: { number }, -- what each rider put in: Ante plus calls and raises (1–13, §2)
	hole: { { number } }, -- each rider's hole cards (for per-class tallies: --report yard)
	beforeFinal: { number }?, -- Posture just before Pass 4's contact, if the hand got there
	afterFinal: { number }?, -- Posture after Pass 4's exchange and its heal (§4 step 7), before the showdown effect
	-- (bonus, mult, the hand's blows, the charge), when neither rider fell to the exchange itself
	chargeStanding: number?, -- switches.showdown = charge: the rider ahead before the charge (0: level)
	posture: { number }, -- Posture after the last contact (at the showdown, may be 0 or below: 0053)
	lanced: { boolean }, -- taken to 0 or below on Pass 4's contact (0053)
	reads: number, -- reads taken
	switches: number, -- reads that moved the aim (a late switch rather than staying on a held aim)
	spots: { { number } }?, -- opts.spots: {bet, rider, hand key, lead bucket, opponent key} at every bet reached
	after: { { number } }?, -- opts.trace: Posture {rider 1, rider 2} after each pass the hand rode on from
	flopCategory: { number }?, -- opts.trace: each rider's category on hole cards and the flop
}

-- ── stats ──────────────────────────────────────────────────────────────────────────────────────

-- Unleaned points with the held passive (§6 *Held behavior*). The straight's passive grows with
-- hold (0048), linear in h: a sim value.
local function points(r: Rider, board: { number }, h: number, firing: boolean, cfg: any): ({ number }, number)
	local pts, sub = Cards.points(r.hole, board, cfg.spec)
	local st = r.status
	if st.owns and not r.spent and not firing then
		local hp = cfg.spec.heldPassive
		local rung = st.ownRung
		if rung == 1 or rung == 5 then
			local suit = Tricks.topSuit(r.hole, board, st.eval.straightTop :: number)
			pts[suit] += hp.straight * h
		end
		if rung == 2 or rung == 5 then
			pts[st.eval.flushSuit :: number] += hp.flush
		elseif rung == 3 then
			pts[3] += hp.fullHouse
			pts[4] += hp.fullHouse
		elseif rung == 4 then
			for s = 1, 4 do
				pts[s] += hp.quads
			end
		end
	end
	return pts, sub
end

-- Max Posture is 32 (16 hearts) for every rider: ♥ is a buffer and a heal, not more health (0070).
local function maxPosture(_r: Rider, _board: { number }, cfg: any): number
	return cfg.spec.postureStart
end

-- Stat values at an aim: S = 20 + leaned points; ♥ takes its lean as a buffer at contact (§4).
-- `explode` is a firing flush: its suit's stat × (1 + (E − 1)·home factor) (§6 *Flush by suit*).
local function statsAt(pts: { number }, aim: number?, cfg: any, explode: { suit: number, E: number }?): ({ number }, number)
	local sim = cfg.sim
	local w = Dial.lean(aim, sim.halfStepShare)
	local S = table.create(4, 0)
	for s = 1, 4 do
		S[s] = cfg.spec.statBase + pts[s] * (1 + sim.lean * w[s])
	end
	local cut = sim.heartBuffer * pts[3] * sim.lean * w[3]
	if explode then
		local f = Dial.homeFactor(aim, explode.suit, sim.halfStepShare)
		local m = 1 + (explode.E - 1) * f
		if explode.suit == 3 then
			cut *= m
		else
			S[explode.suit] *= m
		end
	end
	return S, cut
end

-- The honest stance: the aim whose lean is worth most on the rider's own points (ties random).
local function honestAim(pts: { number }, cfg: any, rng: () -> number): number
	local best, bestV = 0, -math.huge
	local start = math.floor(rng() * 16)
	for i = 0, 15 do
		local a = (start + i) % 16
		local w = Dial.lean(a, cfg.sim.halfStepShare)
		local v = pts[1] * w[1] + pts[2] * w[2] + pts[3] * w[3] + pts[4] * w[4]
		if v > bestV + 1e-9 then
			best, bestV = a, v
		end
	end
	return best
end

-- The opponent as a reader estimates them: board points plus an average hole card per suit.
local function publicPoints(board: { number }, cfg: any): { number }
	local pts = Cards.points({}, board, cfg.spec)
	local avg = 2 * Cards.rankValue(8, cfg.spec) / 4
	for s = 1, 4 do
		pts[s] += avg
	end
	return pts
end

-- ── the hand ───────────────────────────────────────────────────────────────────────────────────

function Hand.play(cfg: any, rng: () -> number, p1: Profile, p2: Profile, button: number, opts: Options?): Record
	local spec, sim = cfg.spec, cfg.sim
	local bands = cfg.switches.betting == "bands"
	if bands and cfg._odds == nil then
		cfg._odds = Hand.calibrate(cfg)
	end
	local wantSpots = opts ~= nil and opts.spots == true
	local deck = Cards.shuffled(rng)
	local board = { deck[5], deck[6], deck[7], deck[8], deck[9] }
	local riders: { Rider } = {}
	for i, prof in { p1, p2 } do
		local r: Rider = {
			id = i,
			p = prof,
			hole = { deck[2 * i - 1], deck[2 * i] },
			posture = 0,
			maxPosture = 0,
			battered = 0,
			batteredHand = 0,
			spent = false,
			contributed = spec.ante,
			heldRung = nil,
			heldAbove = false,
			drawnOut = false,
			aim = nil,
			tAim = nil,
			honest = false,
			plan = false,
			lockAim = false,
			status = Tricks.status({ deck[2 * i - 1], deck[2 * i] }, {}),
			obsA0 = 0,
			obsEarly = false,
		}
		r.maxPosture = maxPosture(r, {}, cfg)
		r.posture = spec.postureStart -- everyone starts at 32, which is also the ceiling (0070, 0075)
		riders[i] = r
	end
	local tricks: { TrickRecord } = {}
	local rec: Record = {
		winner = 0,
		finish = "showdown",
		pass = 4,
		category = { 0, 0 },
		value = { 0, 0 },
		riverRung = { 0, 0 },
		tricks = tricks,
		heldAbove = { false, false },
		drawnOut = { false, false },
		units = { 0, 0 },
		contributed = { spec.ante, spec.ante },
		hole = { riders[1].hole, riders[2].hole },
		afterFinal = nil,
		chargeStanding = nil,
		posture = { 0, 0 },
		lanced = { false, false },
		reads = 0,
		switches = 0,
		spots = if wantSpots then {} else nil,
		after = nil,
		flopCategory = nil,
	}
	local trace = opts ~= nil and opts.trace == true
	if trace then
		rec.after = {}
	end

	-- The reading model (sim/Read.luau): each rider's belief about the opponent's hole pair. Off by
	-- default; it draws no random numbers, so the hand's stream is the same either way.
	local reading = cfg.reading
	local readAim = reading.aim == "belief"
	local readBets = reading.betting == "belief" and bands
	local readOn = readAim or readBets
	local ctx: Read.Ctx? = nil
	-- A rider at readSkill 0 keeps no belief: it reads and bets exactly as the sim always has.
	local beliefs: { [number]: Read.Belief? } = {}
	local assumed = cfg.riders[reading.assume]
	local info = if opts then opts.info else nil
	if readOn then
		ctx = Read.newHand(cfg, board)
		for _, r in riders do
			local o = riders[3 - r.id]
			local skill = r.p.readSkill or 0
			if skill > 0 then
				local b = Read.newBelief(r.hole, skill, info, Read.pairIndex(o.hole[1], o.hole[2]), reading.prune)
				if reading.cues.color == 1 then
					Read.color(b, Read.redCount(o.hole))
				end
				beliefs[r.id] = b
			end
		end
	end

	-- Community cards known once each pass's reveal has landed (§2 *Sequence*): Pass 1 rides on
	-- hole cards, and the flop, turn and river flip mid-charge on Passes 2–4.
	local SHOWN = { [0] = 0, 0, 3, 4, 5, 5 }
	local mode = cfg.switches.showdown
	local proto = cfg.proto
	-- The hand bonus (0050): steps of hand category above high card.
	local function handBonus(category: number): number
		return spec.showdownBonus * category
	end
	-- SHOWDOWN.md prototypes: the hand strikes. The blow a rider's hand lands on the opponent at
	-- contact, scaled by the tier their own strike landed; a trick's hit is its own, so none there.
	local function handBlow(category: number, made: Contact.Strike): number
		if made.trickHit or made.parried then
			return 0
		end
		local f = proto.riverTier[made.tier]
		if f == nil then
			return 0
		end
		return proto.riverPerStep * category * f
	end
	local function revealed(pass: number): { number }
		return table.move(board, 1, SHOWN[pass], 1, {})
	end

	local function finish(winner: number, how: string, pass: number)
		rec.winner, rec.finish, rec.pass = winner, how, pass
	end

	-- Betting strength: what a rider knows of their own hand and the public Posture race.
	local function strength(r: Rider, o: Rider, known: { number }): number
		local _, sub = Cards.points(r.hole, known, spec)
		local s = 0.12 * sub + 0.4 * (r.posture - o.posture) / spec.postureStart -- a full bar's lead is +0.4
		if r.status.owns and not r.spent then
			s += 0.5
		end
		return s + (rng() - 0.5) * 0.3
	end

	-- One fixed-limit round (§2 *Betting rules*): the button acts first, one re-raise cap. A rider
	-- Yields only facing a raise (0081). Returns the id of a rider who Yields, if any.
	--   script (default): raise on strength() above 1 − 0.9·aggression; Yield below yieldBelow.
	--   bands: the betting rider. Raise (or re-raise) when the rider's odds (Odds) are at least
	--          raiseAt[bet]; facing a raise, Yield when they are below yieldAt[bet].
	local function bet(round: number, known: { number }): number?
		local size = spec.raise[round]
		local raises, acted, i = 0, 0, button
		local est = { 0, 0 }
		if bands or wantSpots then
			local keys = { Odds.key(round, riders[1].hole, known), Odds.key(round, riders[2].hole, known) }
			for _, r in riders do
				local o = riders[3 - r.id]
				local key = keys[r.id]
				local bucket = Odds.bucket(r.posture - o.posture)
				if bands then
					est[r.id] = Odds.estimate(cfg._odds, round, key, bucket)
				end
				if rec.spots then
					table.insert(rec.spots, { round, r.id, key, bucket, keys[o.id] })
				end
			end
		end
		while true do
			local r, o = riders[i], riders[3 - i]
			local facing = r.contributed < o.contributed
			local raise: boolean
			if bands then
				-- A reader weighs what this round's bets have told it so far.
				local belief = beliefs[r.id]
				if readBets and belief then
					local key = Odds.key(round, r.hole, known)
					local bucket = Odds.bucket(r.posture - o.posture)
					local kw = Read.keyWeights(belief, ctx :: Read.Ctx, round, #known)
					est[r.id] = belief.skill * Odds.estimateBelief(cfg._odds, round, key, kw, bucket)
						+ (1 - belief.skill) * Odds.estimate(cfg._odds, round, key, bucket)
				end
				local s = est[r.id]
				if facing and s < r.p.yieldAt[round] then
					return r.id
				end
				raise = s >= r.p.raiseAt[round]
			else
				local s = strength(r, o, known)
				if facing and s < r.p.yieldBelow then
					return r.id
				end
				raise = s > 1 - r.p.aggression * 0.9
			end
			-- The bets cue (0094): the opponent reads this Stay or Raise.
			local ob = beliefs[o.id]
			if ob and reading.cues.bets == 1 then
				Read.bet(ob, ctx :: Read.Ctx, {
					round = round,
					n = #known,
					bands = bands,
					facing = facing,
					canRaise = raises < 2,
					raised = raises < 2 and raise,
					lead = r.posture - o.posture,
					spent = r.spent,
				}, assumed)
			end
			if raises < 2 and raise then
				r.contributed = o.contributed + size
				raises += 1
				acted = 1
			else
				r.contributed = o.contributed
				acted += 1
				if acted >= 2 then
					return nil
				end
			end
			i = 3 - i
		end
	end

	for pass = 1, 5 do
		-- Pass 5 is the final charge (switches.showdown = charge): cards up, no bet, no reveal, one
		-- more contact. It is ridden only when no one fell on Pass 4.
		local charge = pass == 5
		if charge then
			if mode ~= "charge" then
				break
			end
			if proto.chargeBonus == "posture" then
				for _, r in riders do
					local b = handBonus(r.status.eval.category)
					r.posture += b
					r.maxPosture += b
				end
			end
			local p1c, p2c = riders[1].posture, riders[2].posture
			rec.chargeStanding = if p1c > p2c then 1 elseif p2c > p1c then 2 else 0
		end
		-- Bet before the pass.
		local prevBoard = if pass == 1 then {} else revealed(pass - 1)
		local yielder = if charge then nil else bet(pass, prevBoard)
		if yielder then
			finish(3 - yielder, "yield", pass)
			break
		end
		local newBoard = revealed(pass)
		local hasReveal = SHOWN[pass] > SHOWN[pass - 1]
		local street = if charge then proto.chargeStreet else spec.street[pass]

		-- Stance, from the stats known at the start of the charge.
		for _, r in riders do
			r.plan = false
			r.lockAim = false
			local st = r.status
			if st.owns and not r.spent and not charge then
				r.plan = pass == 4 or rng() < r.p.aggression
			end
			local design = r.plan and rng() < r.p.design
			local pts = points(r, prevBoard, 1, false, cfg)
			r.honest = rng() < r.p.honesty
			r.aim = if r.honest then honestAim(pts, cfg, rng) else math.floor(rng() * 16)
			r.tAim = sim.earliestCommit + (1 - r.p.hold) * (spec.timeline.slowEnd - sim.earliestCommit)
			-- Playing to design: the straight holds from the first moment; the flush aims home.
			-- Full house and quads have no condition, so they stay free to read.
			local rung = st.ownRung
			if design and (rung == 1 or rung == 2 or rung == 5) then
				r.lockAim = true
				r.tAim = sim.earliestCommit
				if rung == 2 or rung == 5 then
					r.aim = Dial.HOME[st.eval.flushSuit :: number]
				end
			end
			r.obsA0 = r.aim :: number
			r.obsEarly = (r.tAim :: number) <= sim.earliestCommit + 1e-9
		end

		-- The reveal: new stats apply now (§8).
		if hasReveal then
			for _, r in riders do
				local before = r.status
				r.status = Tricks.status(r.hole, newBoard)
				r.maxPosture = maxPosture(r, newBoard, cfg)
				-- A trick that lands on this reveal: unleash now, or hold (aggression).
				if r.status.owns and not r.spent and not before.owns then
					r.plan = pass == 4 or rng() < r.p.aggression -- Pass 4: unused tricks auto-fire
					local rung = r.status.ownRung
					if r.plan and rng() < r.p.design and (rung == 1 or rung == 2 or rung == 5) then
						r.lockAim = true
						if rung == 2 or rung == 5 then
							local home = Dial.HOME[r.status.eval.flushSuit :: number]
							if r.aim ~= home then
								r.aim, r.tAim = home, spec.timeline.slowEnd
							end
						end
					end
				end
				-- Drawn out (0044): a rider holding a trick above the opponent sees them draw level
				-- or above (or the board play over it, 0042).
				-- A held trick lost to the board (0042) can't be unleashed.
				if not r.status.owns then
					r.plan = false
					r.lockAim = false
				end
				-- Re-stance on the new stats; a rider keeping a straight's meter doesn't move.
				if r.honest and not r.lockAim and not (r.status.owns and r.status.ownRung == 1) then
					local best = honestAim(points(r, newBoard, 1, false, cfg), cfg, rng)
					local w1 = Dial.lean(best, sim.halfStepShare)
					local w0 = Dial.lean(r.aim, sim.halfStepShare)
					local pts = points(r, newBoard, 1, false, cfg)
					local v1 = pts[1] * w1[1] + pts[2] * w1[2] + pts[3] * w1[3] + pts[4] * w1[4]
					local v0 = pts[1] * w0[1] + pts[2] * w0[2] + pts[3] * w0[3] + pts[4] * w0[4]
					if v1 > v0 + 1e-9 then
						r.aim, r.tAim = best, math.max(r.tAim :: number, spec.timeline.slowEnd)
					end
				end
			end
		end

		if hasReveal then
			for _, r in riders do
				local o = riders[3 - r.id]
				if r.heldAbove and not r.spent and not r.drawnOut and (o.status.rung >= (r.heldRung :: number) or not r.status.owns) then
					r.drawnOut = true
				end
			end
		end

		-- Unleashes and answers (§6 *Trick vs trick*).
		local fires: { [number]: string? } = {}
		for _, r in riders do
			if r.plan then
				fires[r.id] = if pass == 4 then "autofire" else "unleash"
			end
		end
		local boardClash = false
		for _, r in riders do
			local o = riders[3 - r.id]
			if fires[o.id] and not fires[r.id] then
				local oRung = o.status.ownRung
				if r.status.owns and not r.spent and r.status.ownRung >= oRung then
					fires[r.id] = "answer"
				elseif not r.status.owns and r.status.boardRung == oRung then
					boardClash = true -- the board's trick answers a same-rung unleash (0041)
				end
			end
		end
		-- Resolve which tricks act this pass.
		local clashed = false
		if fires[1] and fires[2] and riders[1].status.ownRung == riders[2].status.ownRung then
			clashed = true
		elseif boardClash then
			clashed = true
		end
		local firingRung = { 0, 0 }
		for _, r in riders do
			if fires[r.id] then
				firingRung[r.id] = r.status.ownRung
				r.spent = true
				if fires[r.id] == "answer" then
					r.lockAim = false -- an answer is automatic: the rider wasn't playing to it
				end
			end
		end

		-- Riders still holding a trick after this pass's decisions.
		for _, r in riders do
			if r.status.owns and not r.spent and not r.heldRung then
				r.heldRung = r.status.ownRung
				r.heldAbove = riders[3 - r.id].status.rung < r.heldRung
			end
		end

		-- Reads: late switches against the opponent's public aim (and any announced unleash).
		local function hOf(r: Rider, t: number?): number
			return Timeline.hold(t, cfg, hasReveal)
		end
		local cardsUp = charge and proto.chargeCardsUp == "yes"
		-- The reading model's cues before the reads: the stance each rider committed to, its timing and
		-- any re-stance after the reveal, and an announced unleash (§7, §6 *Unleash rules*).
		if readOn and not charge then
			for _, r in riders do
				local o = riders[3 - r.id]
				local b = beliefs[r.id]
				if b == nil then
					continue
				end
				Read.see(b, board, SHOWN[pass])
				Read.stance(b, ctx :: Read.Ctx, {
					pass = pass,
					a0 = o.obsA0,
					early = o.obsEarly,
					a1 = o.aim :: number,
					prevN = SHOWN[pass - 1],
					newN = SHOWN[pass],
					spent = o.spent and not fires[o.id],
				}, assumed)
				if fires[o.id] == "unleash" and reading.cues.unleash == 1 then
					local orung = o.status.ownRung
					Read.unleash(b, ctx :: Read.Ctx, SHOWN[pass], orung, if orung == 2 or orung == 5 then o.status.eval.flushSuit else nil)
				end
			end
		end
		local function bestResponse(r: Rider, o: Rider, oAim: number?, oT: number?): number?
			local myPts = points(r, newBoard, 1, false, cfg)
			-- The opponents a read plays against: the public estimate (an average hole card), the
			-- exact cards (the final charge's cards up), or a sample of the reader's belief.
			-- Each with its weight: read skill (0091) weighs the belief's sample by s, the average card by 1 − s.
			local opps: { { number } }
			local weights: { number }
			local belief = beliefs[r.id]
			if cardsUp then
				local oPts = points(o, newBoard, 1, false, cfg)
				opps, weights = { oPts }, { 1 }
			elseif readAim and belief then
				local sample = Read.sample(belief, reading.samples)
				opps, weights = { publicPoints(newBoard, cfg) }, { 1 - belief.skill }
				for _, k in sample do
					table.insert(opps, Read.pointsOf(ctx :: Read.Ctx, SHOWN[pass], k, 1, o.spent))
					table.insert(weights, belief.skill / #sample)
				end
			else
				opps, weights = { publicPoints(newBoard, cfg) }, { 1 }
			end
			local arena = { street = street, openLists = 1, siege = 1 }
			local oFs: { Contact.Fighter } = {}
			for i, oPts in opps do
				local oS, oCut = statsAt(oPts, oAim, cfg)
				oFs[i] = {
					aim = oAim, h = hOf(o, oT), S = oS, buffer = oCut,
					battered = math.max(o.battered, o.batteredHand), trick = nil, ward = 0,
				}
			end
			local facingUnleash = fires[o.id] == "unleash" and not clashed
			local hSwitch = hOf(r, sim.readTime)
			local best, bestV = r.aim, -math.huge
			for a = 0, 15 do
				local h = if a == r.aim then hOf(r, r.tAim) else hSwitch
				local S, cut = statsAt(myPts, a, cfg)
				local F: Contact.Fighter = {
					aim = a, h = h, S = S, buffer = cut,
					battered = math.max(r.battered, r.batteredHand), trick = nil, ward = 0,
				}
				local v = 0
				for i, oF in oFs do
					local wi = weights[i]
					if wi > 0 then
						v += wi * Contact.strike(F, oF, arena, cfg).dmg
						if not facingUnleash then
							v -= wi * Contact.strike(oF, F, arena, cfg).dmg
						end
					end
				end
				if v > bestV + 1e-9 then
					best, bestV = a, v
				end
			end
			return best
		end
		local readers = {}
		for _, r in riders do
			if not r.lockAim and rng() < r.p.read then
				table.insert(readers, r)
			end
		end
		local moves = {}
		for _, r in readers do
			local o = riders[3 - r.id]
			moves[r.id] = bestResponse(r, o, o.aim, o.tAim)
		end
		for _, r in readers do
			local a = moves[r.id]
			rec.reads += 1
			if a ~= r.aim then
				rec.switches += 1
				r.aim, r.tAim = a, sim.readTime
			end
		end
		-- Leaning into ♠ or ♦ locks later (0069): when both read, the rider with more extra time
		-- moves last and re-reads against the opponent's final aim.
		local function extraTime(r: Rider): number
			local w = Dial.lean(r.aim, sim.halfStepShare)
			return sim.extraTime * math.min(1, w[2] + w[4])
		end
		if #readers == 2 then
			for _, r in riders do
				local o = riders[3 - r.id]
				if extraTime(r) > extraTime(o) + 1e-9 then
					local a = bestResponse(r, o, o.aim, o.tAim)
					if a ~= r.aim then
						r.aim, r.tAim = a, sim.readTime
					end
				end
			end
		end

		-- Build the fighters.
		local arena: Contact.Arena = { street = street, openLists = 1, siege = 1 }
		local bs = if #newBoard == 5 then Tricks.status({}, newBoard) else nil
		if bs then
			local bc = bs.eval.category
			if bc == Cards.STRAIGHT or bc == Cards.STRAIGHT_FLUSH then
				arena.openLists = spec.openLists
			elseif bc == Cards.FULL_HOUSE then
				arena.siege = spec.siege
			end
		end
		local F: { Contact.Fighter } = {}
		local shots = {}
		for _, r in riders do
			local h = hOf(r, r.tAim)
			local firing = firingRung[r.id] > 0 and not clashed
			local pts = points(r, newBoard, h, firingRung[r.id] > 0, cfg)
			local explode = nil
			local trick = nil
			local ward = 0
			if firing then
				local st = r.status
				local shot = Tricks.shot(st, r.hole, newBoard, r.aim, h, cfg, hasReveal)
				shots[r.id] = shot
				local key = Tricks.KEY[st.ownRung]
				if st.ownRung == 2 or st.ownRung == 5 then
					local E = if cfg.switches.flushHit == "F2" then sim.flushExplodeF2 else sim.flushExplode
					explode = { suit = st.eval.flushSuit :: number, E = E }
				end
				trick = {
					rung = st.ownRung,
					key = key,
					hit = shot.hit,
					numeric = st.ownRung == 2 and cfg.switches.flushHit == "F2",
					suit = st.eval.flushSuit,
					fortressGap = if st.ownRung == 3 then 2 * math.floor(rng() * 8) else nil,
				}
				ward = sim.ward[key]
			end
			local S, cut = statsAt(pts, r.aim, cfg, explode)
			F[r.id] = {
				aim = r.aim,
				h = h,
				S = S,
				buffer = cut,
				battered = math.max(r.battered, r.batteredHand),
				trick = trick,
				ward = ward,
			}
		end
		for _, r in riders do
			if fires[r.id] then
				local o = riders[3 - r.id]
				table.insert(tricks, {
					rider = r.id,
					rung = r.status.ownRung,
					key = Tricks.KEY[r.status.ownRung],
					how = fires[r.id] :: string,
					designed = if shots[r.id] then shots[r.id].designed else false,
					oppRung = if firingRung[o.id] > 0 then firingRung[o.id] else o.status.rung,
					pass = pass,
					clashed = clashed,
					won = nil,
				})
			end
		end

		-- Contact.
		local s12 = Contact.strike(F[1], F[2], arena, cfg)
		local s21 = Contact.strike(F[2], F[1], arena, cfg)
		local before = { riders[1].posture, riders[2].posture }
		if pass == 4 then
			rec.beforeFinal = before
		end
		local byStrike = { [1] = s21, [2] = s12 } -- the strike each rider receives
		local own = { [1] = s12, [2] = s21 } -- the strike each rider makes
		-- riverHit: on Pass 4 each hand strikes with its river category; charge with chargeBonus = hit:
		-- the same on the charge.
		local blows = (pass == 4 and mode == "riverHit") or (charge and proto.chargeBonus == "hit")
		local afterDial = { 0, 0 }
		-- The turn cushion (proto.turnCushion): the turn's hand holds a rider in below 0 on Pass 3.
		local function floorOf(r: Rider): number
			if pass ~= 3 then
				return 0
			end
			return -proto.turnCushion * spec.showdownBonus * r.status.eval.category
		end
		local knockdownPass = pass == 4 and cfg.switches.riverRule == "knockdown"
		-- Posture in half hearts (0075): damage lands as whole half hearts, to the nearest; the heal
		-- rounds up, so every heal shows (♥, 0070). switches.posture = "exact" turns rounding off.
		local atContact, healed = { 0, 0 }, { 0, 0 } -- the reading model's cues: Posture after contact, the heal
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
		for _, r in riders do
			local o = riders[3 - r.id]
			local taken, made = byStrike[r.id], own[r.id]
			local before = r.posture
			local p = r.posture - pips(taken.dmg) - pips(made.reflect)
			if taken.cleanBlock then
				p = math.min(r.maxPosture, p + pips(spec.cleanBlockRestore))
			end
			-- ♥ Unbroken: Posture can't fall below 1 this pass, and after contact it heals back
			-- everything the pass took (0053, 0072; a higher trick's rule wins).
			local myTrick = F[r.id].trick
			local oRung = if F[3 - r.id].trick then (F[3 - r.id].trick :: any).rung else 0
			local unbroken = myTrick ~= nil and myTrick.key == "flush" and myTrick.suit == 3 and oRung < myTrick.rung
			if unbroken then
				p = math.max(p, 1)
			end
			atContact[r.id] = p
			-- Step 7, after contact (§4): a rider unhorsed on Passes 1–3 is down before any heal.
			if knockdownPass or p > floorOf(r) then
				if unbroken then
					p = math.max(p, math.min(r.maxPosture, before))
				else
					local lost = before - p
					if lost > 0 then
						local share = sim.healBase + sim.healPerPoint * points(r, newBoard, 0, false, cfg)[3]
						p = math.min(r.maxPosture, p + healPips(lost * math.min(1, share)))
					end
				end
			end
			afterDial[r.id] = p
			healed[r.id] = p - atContact[r.id]
			-- riverVsTrick = warded: a rider firing a trick (unclashed) takes no hand blow.
			if blows and not (proto.riverVsTrick == "warded" and F[r.id].trick ~= nil) then
				p -= pips(handBlow(o.status.eval.category, own[o.id]))
			end
			r.posture = p
			-- Battered (0068): this contact used it up; an aimed ♣ hit that got through applies it anew.
			r.battered = 0
			local theirs = byStrike[r.id]
			if theirs.through > 0 then
				local wClub = Dial.lean(o.aim, sim.halfStepShare)[1]
				if wClub > 0 then
					r.battered = sim.battered * wClub
				end
				local oTrick = F[o.id].trick
				if oTrick and oTrick.key == "flush" and oTrick.suit == 1 then
					r.batteredHand = sim.battered -- Shattering Blow: Battered for the rest of the hand
				end
			end
		end
		if pass == 4 and afterDial[1] > 0 and afterDial[2] > 0 then
			rec.afterFinal = afterDial
		end
		local down1, down2 = riders[1].posture <= floorOf(riders[1]), riders[2].posture <= floorOf(riders[2])
		-- Pass 4's contact unhorses no one; the knockdown after it decides (0053).
		if pass == 4 and cfg.switches.riverRule == "knockdown" then
			rec.lanced = { down1, down2 }
			break
		elseif down1 or down2 then
			local w
			if down1 and down2 then
				w = if before[1] > before[2] then 1 elseif before[2] > before[1] then 2 else 0
			else
				w = if down1 then 2 else 1
			end
			finish(w, "unhorse", pass)
			break
		end
		if trace then
			(rec.after :: { { number } })[pass] = { riders[1].posture, riders[2].posture }
			if pass == 2 then
				rec.flopCategory = { riders[1].status.eval.category, riders[2].status.eval.category }
			end
		end
		-- The reading model's cues after contact: both Posture changes and the ♥ heal (0093). A pass
		-- where a trick fired (or clashed) teaches nothing numeric: its hit isn't the cards' stats.
		if readOn and pass <= 3 and not fires[1] and not fires[2] then
			for _, r in riders do
				local o = riders[3 - r.id]
				local b = beliefs[r.id]
				if b == nil then
					continue
				end
				Read.contact(b, ctx :: Read.Ctx, {
					n = SHOWN[pass],
					me = F[r.id],
					oAim = F[o.id].aim,
					oH = F[o.id].h,
					oBattered = F[o.id].battered,
					oSpent = o.spent,
					arena = arena,
					myBefore = before[r.id],
					oBefore = before[o.id],
					myMax = r.maxPosture,
					oMax = o.maxPosture,
					myNet = atContact[r.id] - before[r.id],
					oNet = atContact[o.id] - before[o.id],
					oHeal = healed[o.id],
				})
			end
			if info then
				for _, b in beliefs do
					info["H.pass" .. pass] = (info["H.pass" .. pass] or 0) + Read.entropy(b)
					info["truth.pass" .. pass] = (info["truth.pass" .. pass] or 0) + Read.truthShare(b)
					info["obs.pass" .. pass] = (info["obs.pass" .. pass] or 0) + 1
				end
			end
		end
	end
	if info and readOn then
		for _, b in beliefs do
			info["skipped"] = (info["skipped"] or 0) + b.skipped
			info["beliefs"] = (info["beliefs"] or 0) + 1
		end
	end

	-- The river hands, for the record and the showdown.
	local e = {}
	for i, r in riders do
		r.status = Tricks.status(r.hole, board)
		e[i] = r.status.eval
		rec.category[i] = e[i].category
		rec.value[i] = e[i].value
		rec.riverRung[i] = r.status.rung
		rec.posture[i] = r.posture
		rec.drawnOut[i] = r.drawnOut
		rec.heldAbove[i] = r.heldAbove
	end
	-- Showdown knockdown (§2 win condition 3, §4 *Tracks*, 0050, 0053): after Pass 4's contact each
	-- rider's hand bonus is added to their Posture, even Posture the lance took below 0, and the
	-- lower rider falls; an exact tie goes to the poker hands (§2 win condition 4), then a split.
	-- The prototypes (switches.showdown, SHOWDOWN.md) change what is compared: mult multiplies
	-- Posture by the steps; riverHit and charge have already dealt the hand's blows (or the bonus)
	-- and compare Posture alone, unless riverKnockdown = bonus.
	if rec.finish == "showdown" then
		local s = {}
		for i, r in riders do
			local c = e[i].category
			local p = r.posture -- below 0 counts (0053)
			if mode == "bonus" or (mode == "riverHit" and proto.riverKnockdown == "bonus") then
				s[i] = p + handBonus(c)
			elseif mode == "mult" then
				s[i] = p * (1 + proto.mult * c)
			else
				s[i] = p
			end
		end
		local w = 0
		if s[1] ~= s[2] then
			w = if s[1] > s[2] then 1 else 2
		elseif e[1].value ~= e[2].value then
			w = if e[1].value > e[2].value then 1 else 2
		end
		finish(w, "showdown", if mode == "charge" then 5 else 4)
	end
	for _, t in tricks do
		t.won = rec.winner == t.rider
	end
	rec.contributed = { riders[1].contributed, riders[2].contributed }
	-- Units: the winner takes the loser's contribution (Ante included); a split returns both.
	if rec.winner ~= 0 then
		local loser = riders[3 - rec.winner]
		rec.units[rec.winner] = loser.contributed
		rec.units[3 - rec.winner] = -loser.contributed
	end
	return rec
end

-- The betting rider's odds (Odds): a calibration run of sim.oddsHands average-vs-average hands under
-- the default script, which never Yields, so every spot is scored on the hand ridden to its end.
-- Its own RNG (sim.oddsSeed) leaves the main run's stream alone. Hand.play builds it on first use
-- and keeps it on the config table as cfg._odds.
function Hand.calibrate(cfg: any): Odds.Table
	local c = table.clone(cfg)
	c.switches = table.clone(cfg.switches)
	c.switches.betting = "script"
	c._odds = nil
	c.reading = table.clone(cfg.reading)
	c.reading.aim, c.reading.betting = "off", "off" -- experience, not reading: the script's own odds
	local st = cfg.sim.oddsSeed % 2147483647
	local function rng(): number
		st = (st * 16807) % 2147483647
		return (st - 1) / 2147483646
	end
	local spots = {}
	local avg = cfg.riders.average
	for i = 1, cfg.sim.oddsHands do
		local r = Hand.play(c, rng, avg, avg, (i % 2) + 1, { spots = true })
		for _, s in r.spots :: { { number } } do
			local who = s[2]
			local won = if r.winner == who then 1 elseif r.winner == 0 then 0.5 else 0
			table.insert(spots, { s[1], s[3], s[4], won, s[5] })
		end
	end
	return Odds.build(spots)
end

-- Exposed for tests.
Hand._statsAt = statsAt
Hand._honestAim = honestAim

return Hand
