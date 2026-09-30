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
--      aim and hold. Reads are simultaneous and blind to each other, except that a rider holding a
--      K in the hole moves last (§5: the opponent locks earlier).
-- h follows from when the final aim was set (Timeline). Contact resolves both strikes at once.

local Cards = require("./Cards")
local Dial = require("./Dial")
local Timeline = require("./Timeline")
local Tricks = require("./Tricks")
local Contact = require("./Contact")

local Hand = {}

type Profile = { read: number, hold: number, honesty: number, aggression: number, design: number, yieldBelow: number }

type Rider = {
	id: number,
	p: Profile,
	hole: { number },
	posture: number,
	maxPosture: number,
	charge: number,
	spent: boolean, -- the trick's once-per-hand unleash is used (or clashed)
	twinUsed: boolean,
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
	pass: number, -- pass the hand ended on (4 for showdown)
	category: { number }, -- river best-five category per rider
	value: { number },
	riverRung: { number },
	tricks: { TrickRecord },
	heldAbove: { boolean }, -- held a trick past a decision while above the opponent
	drawnOut: { boolean },
	units: { number },
	beforeFinal: { number }?, -- Posture just before Pass 4's contact, if the hand got there
	posture: { number },
	reads: number, -- reads taken
	switches: number, -- reads that moved the aim (a late switch rather than staying on a held aim)
}

-- ── face effects (§5) ──────────────────────────────────────────────────────────────────────────

local function countRank(cards: { number }, r: number): number
	local n = 0
	for _, c in cards do
		if Cards.rank(c) == r then
			n += 1
		end
	end
	return n
end

-- A hole face card that pairs the board gets only the numeric pair or trips (§5 *Rules*).
local function holeFace(r: Rider, board: { number }, rank: number): number
	if countRank(board, rank) > 0 then
		return 0
	end
	return countRank(r.hole, rank)
end

local function critBase(r: Rider, board: { number }, cfg: any): number
	local spec = cfg.spec
	local a = holeFace(r, board, 14)
	local base = if a == 2 then spec.aaCrit elseif a == 1 then spec.aceCrit.hole else spec.base.crit
	return base + spec.aceCrit.boardBonus * countRank(board, 14)
end

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

-- Max Posture uses unleaned ♥ points (§4 *Stances*), with the flat held passives.
local function maxPosture(r: Rider, board: { number }, cfg: any): number
	local pts = points(r, board, 0, false, cfg)
	return cfg.spec.postureStart + cfg.sim.heartPosture * pts[3]
end

-- Stat values at an aim: S = 20 + leaned points; ♥ takes its lean as a damage cut (§4).
-- `explode` is a firing flush: its suit's stat × (1 + (E − 1)·home factor) (§6 *Flush by suit*).
local function statsAt(pts: { number }, aim: number?, cfg: any, explode: { suit: number, E: number }?): ({ number }, number)
	local sim = cfg.sim
	local w = Dial.lean(aim, sim.halfStepShare)
	local S = table.create(4, 0)
	for s = 1, 4 do
		S[s] = cfg.spec.statBase + pts[s] * (1 + sim.lean * w[s])
	end
	local cut = sim.heartCut * pts[3] * sim.lean * w[3]
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

function Hand.play(cfg: any, rng: () -> number, p1: Profile, p2: Profile, button: number): Record
	local spec, sim = cfg.spec, cfg.sim
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
			charge = 0,
			spent = false,
			twinUsed = false,
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
		}
		r.maxPosture = maxPosture(r, {}, cfg)
		r.posture = r.maxPosture
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
		posture = { 0, 0 },
		reads = 0,
		switches = 0,
	}

	-- Community cards known once this pass's reveal has landed (proposed.passOrder).
	local riverLast = cfg.proposed.passOrder == "riverLast"
	if not riverLast and cfg.proposed.passOrder ~= "spec" then
		error("unknown passOrder " .. tostring(cfg.proposed.passOrder))
	end
	local SHOWN = if riverLast then { [0] = 0, 0, 3, 4, 5 } else { [0] = 0, 3, 4, 5, 5 }
	local function revealed(pass: number): { number }
		return table.move(board, 1, SHOWN[pass], 1, {})
	end

	local function finish(winner: number, how: string, pass: number)
		rec.winner, rec.finish, rec.pass = winner, how, pass
	end

	-- Betting strength: what a rider knows of their own hand and the public Posture race.
	local function strength(r: Rider, o: Rider, known: { number }): number
		local _, sub = Cards.points(r.hole, known, spec)
		local s = 0.12 * sub + (r.posture - o.posture) / 200
		if r.status.owns and not r.spent then
			s += 0.5
		end
		return s + (rng() - 0.5) * 0.3
	end

	-- One fixed-limit round (§2 *Betting rules*): the button acts first, one re-raise cap.
	-- Returns the id of a rider who Yields, if any.
	local function bet(round: number, known: { number }): number?
		local size = spec.raise[round]
		local raises, acted, i = 0, 0, button
		while true do
			local r, o = riders[i], riders[3 - i]
			local facing = r.contributed < o.contributed
			local s = strength(r, o, known)
			if facing and s < r.p.yieldBelow then
				return r.id
			end
			if raises < 2 and s > 1 - r.p.aggression * 0.9 then
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

	for pass = 1, 4 do
		-- Bet before the pass.
		local prevBoard = if pass == 1 then {} else revealed(pass - 1)
		local yielder = bet(pass, prevBoard)
		if yielder then
			finish(3 - yielder, "yield", pass)
			break
		end
		local newBoard = revealed(pass)
		local hasReveal = SHOWN[pass] > SHOWN[pass - 1]
		local street = spec.street[pass] * (if pass == 4 then cfg.proposed.finalPassBonus else 1)

		-- Start of pass: queen restores (Passes 2–4; §5), capped at max Posture.
		if pass >= 2 then
			for _, r in riders do
				local q = holeFace(r, prevBoard, 12)
				local restore = if q == 2 then spec.qqRestore elseif q == 1 then spec.queenRestore.hole else 0
				restore += spec.queenRestore.board * countRank(prevBoard, 12)
				r.posture = math.min(r.maxPosture, r.posture + restore)
			end
		end

		-- Stance, from the stats known at the start of the charge.
		for _, r in riders do
			r.plan = false
			r.lockAim = false
			local st = r.status
			if st.owns and not r.spent then
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
		end

		-- The reveal: new stats apply now (§8). ♥ gains raise Posture by the difference (§4).
		if hasReveal then
			for _, r in riders do
				local before = r.status
				r.status = Tricks.status(r.hole, newBoard)
				local newMax = maxPosture(r, newBoard, cfg)
				if newMax > r.maxPosture then
					r.posture += newMax - r.maxPosture
				end
				r.maxPosture = newMax
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
		local function bestResponse(r: Rider, o: Rider, oAim: number?, oT: number?): number?
			local myPts = points(r, newBoard, 1, false, cfg)
			local oPts = publicPoints(newBoard, cfg)
			local arena = { street = street, openLists = 1, siege = 1 }
			local oS, oCut = statsAt(oPts, oAim, cfg)
			local oF: Contact.Fighter = {
				aim = oAim, h = hOf(o, oT), S = oS, heartCut = oCut, critBase = spec.base.crit,
				aa = false, kk = false, charge = 0, trick = nil, ward = 0,
			}
			local facingUnleash = fires[o.id] == "unleash" and not clashed
			local hSwitch = hOf(r, sim.readTime)
			local best, bestV = r.aim, -math.huge
			for a = 0, 15 do
				local h = if a == r.aim then hOf(r, r.tAim) else hSwitch
				local S, cut = statsAt(myPts, a, cfg)
				local F: Contact.Fighter = {
					aim = a, h = h, S = S, heartCut = cut, critBase = critBase(r, newBoard, cfg),
					aa = false, kk = false, charge = r.charge, trick = nil, ward = 0,
				}
				local dealt = Contact.strike(F, oF, arena, cfg).dmg
				local v = dealt
				if not facingUnleash then
					v -= Contact.strike(oF, F, arena, cfg).dmg
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
		-- A hole K moves last: re-read against the opponent's final aim (§5 K, KK).
		if #readers == 2 then
			for _, r in riders do
				local o = riders[3 - r.id]
				if holeFace(r, newBoard, 13) > 0 and holeFace(o, newBoard, 13) == 0 then
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
				heartCut = cut,
				critBase = critBase(r, newBoard, cfg),
				aa = holeFace(r, newBoard, 14) == 2,
				kk = holeFace(r, newBoard, 13) == 2,
				charge = r.charge,
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
		for _, r in riders do
			local taken, made = byStrike[r.id], own[r.id]
			local p = r.posture - taken.dmg - made.reflect
			if taken.cleanBlock then
				p = math.min(r.maxPosture, p + spec.cleanBlockRestore)
			end
			-- ♥ Unbroken: can't be unhorsed this pass (a higher trick's rule wins).
			local myTrick = F[r.id].trick
			local oRung = if F[3 - r.id].trick then (F[3 - r.id].trick :: any).rung else 0
			if myTrick and myTrick.key == "flush" and myTrick.suit == 3 and oRung < myTrick.rung then
				p = math.max(p, 1)
			end
			-- QQ Twin Favor: the first unhorse this hand is negated, Posture set to 20 (C1).
			if p <= 0 and holeFace(r, newBoard, 12) == 2 and not r.twinUsed then
				local byTrick = taken.trickHit and taken.dmg > 0
				if not (byTrick and cfg.switches.twinFavorVsTrick == "trickOverrides") then
					p = spec.qqFloor
					r.twinUsed = true
				end
			end
			r.posture = p
			if made.chargeSpent then
				r.charge = 0
			end
			r.charge += made.chargeGain
		end
		local down1, down2 = riders[1].posture <= 0, riders[2].posture <= 0
		if down1 or down2 then
			local w
			if down1 and down2 then
				w = if before[1] > before[2] then 1 elseif before[2] > before[1] then 2 else 0
			else
				w = if down1 then 2 else 1
			end
			finish(w, "unhorse", pass)
			break
		end
	end

	-- Showdown knockdown (§2 win condition 3, §4 *Tracks*): an open question, three readings.
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
	if rec.finish == "showdown" then
		local mode = cfg.switches.showdown
		local s = {}
		for i, r in riders do
			if mode == "category" then
				s[i] = r.posture + sim.showdownCategoryWeight * e[i].category
			elseif mode == "points" then
				local pts = Cards.points(r.hole, board, spec)
				s[i] = r.posture + sim.showdownPointsWeight * (pts[1] + pts[2] + pts[3] + pts[4])
			elseif mode == "lexicographic" then
				s[i] = r.posture
			else
				error("unknown showdown reading " .. mode)
			end
		end
		local w = 0
		if mode == "lexicographic" and e[1].value ~= e[2].value then
			local better = if e[1].value > e[2].value then 1 else 2
			w = if s[better] + sim.showdownLexMargin >= s[3 - better] then better else 3 - better
		elseif s[1] ~= s[2] then
			w = if s[1] > s[2] then 1 else 2
		elseif e[1].value ~= e[2].value then
			w = if e[1].value > e[2].value then 1 else 2 -- §2 win condition 4
		end
		finish(w, "showdown", 4)
	end
	for _, t in tricks do
		t.won = rec.winner == t.rider
	end
	-- Units: the winner takes the loser's contribution (Ante included); a split returns both.
	if rec.winner ~= 0 then
		local loser = riders[3 - rec.winner]
		rec.units[rec.winner] = loser.contributed
		rec.units[3 - rec.winner] = -loser.contributed
	end
	return rec
end

-- Exposed for tests.
Hand._statsAt = statsAt
Hand._honestAim = honestAim

return Hand
