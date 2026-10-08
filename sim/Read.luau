--!strict
-- Read.luau — the reading model (GAME_SPEC §11 *Sim plan* step 4; decisions 0089–0093).
--
-- A reader keeps a belief over the opponent's hole pair: a weight on each of the 1326 two-card
-- deals, zero for any pair that holds a card the reader can see (its own hole cards, the board so
-- far). Every public cue of §7 updates it (0089):
--
--   color    the lance and shield colors: how many of the two hole cards are red (before Pass 1)
--   stance   where the rider commits, and where it re-stances after the reveal (honesty)
--   timing   when it leaves Neutral: a trick played to its design commits at the first moment
--   hit      the net change on both Posture bars at contact: the hit each rider took, clean blocks
--            included; what the opponent dealt says their ♣ and ♠, what they took says their ♦ and
--            their ♥ buffer (0093: the buffer nets into the hit)
--   heal     the ♥ heal after contact, as its own beat (0093)
--   unleash  an announced unleash names the rung, and a flush its suit (§6 *Unleash rules*)
--   bets     each Stay, Raise and Yield: the assumed rider bets on its hand and the public Posture
--            lead, so its action narrows the hand (0094)
--
-- A cue's likelihood comes from replaying the sim's own rider script (sim/Hand.luau) for every
-- candidate pair, with the opponent assumed to ride as the profile reading.assume. So a reader at
-- full skill is a perfect Bayesian about the sim's riders; the hold meter and the first exit carry
-- card information only through a trick played to its design, because the script ties hold to the
-- rider, not the hand.
--
-- The belief itself is exact Bayes: every reader learns what the cues carry, and a cue that rules a
-- pair out drops it, which keeps the work small. An update that would leave no weight at all (the
-- opponent rode off the assumed script) is skipped.
--
-- What the belief drives (0090), and read skill (0091): reading.aim = "belief" plays a read against
-- the opponents the belief holds (a systematic sample of reading.samples pairs); reading.betting =
-- "belief" averages the betting rider's paired odds (sim/Odds.luau) over it. A rider at readSkill s
-- weighs that read by s and today's estimate (an average hole card, its own odds) by 1 − s: s = 1 is
-- a perfect Bayesian, s = 0 rides as the sim always has (Hand keeps no belief for it).

local Cards = require("./Cards")
local Dial = require("./Dial")
local Contact = require("./Contact")
local Tricks = require("./Tricks")
local Odds = require("./Odds")

local Read = {}

-- ── the 1326 hole pairs ──────────────────────────────────────────────────────────────────────

local NP = 1326
Read.NP = NP
local PA: { number } = table.create(NP, 0)
local PB: { number } = table.create(NP, 0)
local PIDX: { number } = table.create(52 * 52, 0)
local PCLASS: { number } = table.create(NP, 0)
local PRED: { number } = table.create(NP, 0) -- red hole cards, 0..2 (♥ and ♦ are red, §7)
do
	local k = 0
	for a = 0, 50 do
		for b = a + 1, 51 do
			k += 1
			PA[k], PB[k] = a, b
			PIDX[a * 52 + b + 1] = k
			PIDX[b * 52 + a + 1] = k
			PCLASS[k] = Cards.class({ a, b })
			PRED[k] = (if a % 4 >= 2 then 1 else 0) + (if b % 4 >= 2 then 1 else 0)
		end
	end
end

function Read.pairIndex(c1: number, c2: number): number
	return PIDX[c1 * 52 + c2 + 1]
end

function Read.pairCards(k: number): (number, number)
	return PA[k], PB[k]
end

Read.PCLASS = PCLASS

-- ── fast per-pair evaluation ─────────────────────────────────────────────────────────────────
-- The same answers as Cards.evaluate (category, straight top, flush suit), Cards.points and
-- Odds' draw flag, without allocating: they run for every candidate pair at every street.

local function straightTop(mask: number): number
	for top = 14, 5, -1 do
		local need = bit32.lshift(0x1F, top - 4)
		if bit32.band(mask, need) == need then
			return top
		end
	end
	return 0
end

local POP5 = table.create(32, 0)
for x = 0, 31 do
	local n = 0
	for i = 0, 4 do
		if bit32.band(x, bit32.lshift(1, i)) ~= 0 then
			n += 1
		end
	end
	POP5[x + 1] = n
end

local cnt: { number } = table.create(15, 0)
local used: { number } = table.create(15, 0)
local suitCount = { 0, 0, 0, 0 }
local suitMask = { 0, 0, 0, 0 }

-- Category (0–8), straight top (0 if none), flush suit (0 if none) and draw flag of hole (a, b)
-- with the first n board cards. Fewer than five cards in all is category 0, as Tricks.status has it.
local function evaluate(a: number, b: number, board: { number }, n: number): (number, number, number, boolean)
	for s = 1, 4 do
		suitCount[s] = 0
		suitMask[s] = 0
	end
	for r = 2, 14 do
		cnt[r] = 0
	end
	local mask, holeMask = 0, 0
	local hs1, hs2 = a % 4 + 1, b % 4 + 1
	for i = 1, n + 2 do
		local c = if i == 1 then a elseif i == 2 then b else board[i - 2]
		local r, s = c // 4 + 2, c % 4 + 1
		cnt[r] += 1
		suitCount[s] += 1
		local bit = bit32.lshift(1, r)
		if r == 14 then
			bit = bit32.bor(bit, 2)
		end
		suitMask[s] = bit32.bor(suitMask[s], bit)
		mask = bit32.bor(mask, bit)
		if i <= 2 then
			holeMask = bit32.bor(holeMask, bit)
		end
	end
	-- The draw flag (Odds' drawing): four to a flush with a hole card of the suit, or four ranks in a
	-- five-rank window with a hole rank among them.
	local draw = false
	for s = 1, 4 do
		if suitCount[s] == 4 and (hs1 == s or hs2 == s) then
			draw = true
		end
	end
	if not draw then
		for low = 1, 10 do
			local win = bit32.band(bit32.rshift(mask, low), 31)
			if POP5[win + 1] == 4 and bit32.band(bit32.rshift(holeMask, low), 31) ~= 0 then
				draw = true
				break
			end
		end
	end
	if n + 2 < 5 then
		return 0, 0, 0, draw
	end
	local flushSuit = 0
	for s = 1, 4 do
		if suitCount[s] >= 5 then
			flushSuit = s
		end
	end
	if flushSuit > 0 then
		local top = straightTop(suitMask[flushSuit])
		if top > 0 then
			return 8, top, flushSuit, draw
		end
	end
	local quads, trips, pairs = 0, 0, 0
	for r = 14, 2, -1 do
		local c = cnt[r]
		if c == 4 then
			quads += 1
		elseif c == 3 then
			trips += 1
		elseif c == 2 then
			pairs += 1
		end
	end
	if quads > 0 then
		return 7, 0, 0, draw
	end
	if trips > 0 and (trips >= 2 or pairs >= 1) then
		return 6, 0, 0, draw
	end
	if flushSuit > 0 then
		return 5, 0, flushSuit, draw
	end
	local top = straightTop(mask)
	if top > 0 then
		return 4, top, 0, draw
	end
	if trips > 0 then
		return 3, 0, 0, draw
	end
	if pairs >= 2 then
		return 2, 0, 0, draw
	end
	if pairs == 1 then
		return 1, 0, 0, draw
	end
	return 0, 0, 0, draw
end
Read._evaluate = evaluate

-- Cards.points for hole (a, b) and the first n board cards: unleaned points per suit, made cards
-- multiplied (hole cards take a made rank's multiplier first).
local function points(a: number, b: number, board: { number }, n: number, spec: any): (number, number, number, number, number)
	for r = 2, 14 do
		cnt[r] = 0
		used[r] = 0
	end
	cnt[a // 4 + 2] += 1
	cnt[b // 4 + 2] += 1
	for i = 1, n do
		cnt[board[i] // 4 + 2] += 1
	end
	local trip, p1, p2 = 0, 0, 0
	for r = 14, 2, -1 do
		local c = cnt[r]
		if c >= 3 and trip == 0 then
			trip = r
		elseif c >= 2 then
			if p1 == 0 then
				p1 = r
			elseif p2 == 0 then
				p2 = r
			end
		end
	end
	local hm = spec.handMult
	local m1, n1, m2, n2 = 1, 0, 1, 0 -- multiplier and card count for up to two made ranks
	local r1, r2 = 0, 0
	if trip > 0 then
		r1, m1, n1 = trip, hm.trips, 3
	elseif p2 > 0 then
		r1, m1, n1 = p1, hm.twoPair, 2
		r2, m2, n2 = p2, hm.twoPair, 2
	elseif p1 > 0 then
		r1, m1, n1 = p1, hm.pair, 2
	end
	local base, slope, bw = spec.rankBase, spec.rankSlope, spec.boardWeight
	local q1, q2, q3, q4 = 0, 0, 0, 0
	for i = 1, n + 2 do
		local c = if i == 1 then a elseif i == 2 then b else board[i - 2]
		local r, s = c // 4 + 2, c % 4 + 1
		local v = base + (r - 2) * slope
		if i > 2 then
			v *= bw
		end
		if r == r1 and used[r] < n1 then
			used[r] += 1
			v *= m1
		elseif r == r2 and used[r] < n2 then
			used[r] += 1
			v *= m2
		end
		if s == 1 then
			q1 += v
		elseif s == 2 then
			q2 += v
		elseif s == 3 then
			q3 += v
		else
			q4 += v
		end
	end
	local sub = if trip > 0 then 3 elseif p2 > 0 then 2 elseif p1 > 0 then 1 else 0
	return q1, q2, q3, q4, sub
end
Read._points = points

-- ── a hand's shared tables ───────────────────────────────────────────────────────────────────
-- Per street (n board cards known: 0, 3, 4, 5), for each pair that misses those cards: points,
-- category and trick ownership. Shared by both readers; a pair's entry is filled on first use.

export type Street = {
	n: number,
	live: { boolean },
	done: { boolean }, -- the pair's entry is filled (see fill)
	spec: any,
	board: { number },
	known: { number },
	boardRung: number,
	bc: number,
	q1: { number },
	q2: { number },
	q3: { number },
	q4: { number },
	sub: { number }, -- the numeric sub-hand's category (Cards.points), which the script's betting uses
	own: { number }, -- owned rung, 0 if none (§6 *Ownership*)
	fsuit: { number }, -- flush suit of an owned flush or straight flush
	tsuit: { number }, -- suit of an owned straight's top card (its held passive, §6)
	key: { number }, -- Odds' hand key at the bet after this street (Bets 3–4)
	honest: { [boolean]: { mask: { number }, size: { number } } }, -- honest stance sets, by spent
}

export type Ctx = {
	cfg: any,
	board: { number },
	streets: { [number]: Street },
	lean: { { number } }, -- lean weights per aim 0..15 (index aim + 1)
	odds: any, -- the betting rider's odds table (Odds.Table), when reading.betting = "belief"
}

function Read.newHand(cfg: any, board: { number }): Ctx
	local lean = {}
	for a = 0, 15 do
		lean[a + 1] = Dial.lean(a, cfg.sim.halfStepShare)
	end
	return { cfg = cfg, board = board, streets = {}, lean = lean, odds = nil }
end

local function boardCategory(board: { number }, n: number): number
	local c = table.create(15, 0)
	local pairs, trips = 0, false
	for i = 1, n do
		local r = board[i] // 4 + 2
		c[r] += 1
		if c[r] == 2 then
			pairs += 1
		elseif c[r] == 3 then
			trips = true
		end
	end
	if trips then
		return 3
	end
	return math.min(pairs, 2)
end

local fill: (Street, number) -> ()
function Read.street(ctx: Ctx, n: number): Street
	local st = ctx.streets[n]
	if st then
		return st
	end
	-- Hole cards alone don't depend on the board: that street is built once per run, filled for
	-- every pair, and kept on the config table (as Hand keeps cfg._odds).
	if n == 0 then
		local cfg = ctx.cfg
		local s0 = cfg._readStreet0
		if s0 == nil then
			s0 = Read.buildStreet(ctx, 0)
			for k = 1, NP do
				fill(s0, k)
			end
			cfg._readStreet0 = s0
		end
		ctx.streets[0] = s0
		return s0
	end
	st = Read.buildStreet(ctx, n)
	ctx.streets[n] = st
	return st
end

function Read.buildStreet(ctx: Ctx, n: number): Street
	local board = ctx.board
	local seen = table.create(52, false)
	for i = 1, n do
		seen[board[i] + 1] = true
	end
	local live = table.create(NP, false)
	for k = 1, NP do
		live[k] = not seen[PA[k] + 1] and not seen[PB[k] + 1]
	end
	local known = table.move(board, 1, n, 1, {})
	-- At the river the board may make a trick of its own; then ownership needs the full comparison.
	local boardRung = 0
	if n == 5 then
		boardRung = Tricks.rungOf(Cards.evaluate(known).category)
	end
	local st: Street = {
		n = n, live = live, done = table.create(NP, false), spec = ctx.cfg.spec, board = board, known = known,
		boardRung = boardRung, bc = boardCategory(board, n),
		q1 = table.create(NP, 0), q2 = table.create(NP, 0), q3 = table.create(NP, 0), q4 = table.create(NP, 0),
		sub = table.create(NP, 0),
		own = table.create(NP, 0), fsuit = table.create(NP, 0), tsuit = table.create(NP, 0), key = table.create(NP, 0),
		honest = {},
	}
	return st
end

-- Fills one pair's entry at a street, on first use: only pairs a belief still holds are ever built.
function fill(st: Street, k: number)
	st.done[k] = true
	local a, b = PA[k], PB[k]
	local board, n = st.board, st.n
	st.q1[k], st.q2[k], st.q3[k], st.q4[k], st.sub[k] = points(a, b, board, n, st.spec)
	if n == 0 then
		return -- hole cards alone: no trick, and Bets 1–2 key on the class
	end
	local cat, top, fs, draw = evaluate(a, b, board, n)
	local rung = Tricks.rungOf(cat)
	if rung > 0 and st.boardRung > 0 then
		rung = Tricks.status({ a, b }, st.known).ownRung
	end
	st.own[k] = rung
	if rung == 2 or rung == 5 then
		st.fsuit[k] = fs
	end
	if rung == 1 or rung == 5 then
		st.tsuit[k] = Tricks.topSuit({ a, b }, st.known, top)
	end
	-- Odds.key for Bets 3–4: the rider's category, the board's own pairs, the draw flag.
	if n >= 3 then
		st.key[k] = cat * 8 + st.bc * 2 + (if cat < Cards.STRAIGHT and draw then 1 else 0) + 1
	end
end

function Read.entry(st: Street, k: number)
	if not st.done[k] then
		fill(st, k)
	end
end

-- A pair's unleaned points with its held passive (§6 *Held behavior*), as Hand's points(): the
-- straight's passive grows with hold h; a spent trick has none.
local function held(st: Street, k: number, h: number, spent: boolean, spec: any): (number, number, number, number)
	if not st.done[k] then
		fill(st, k)
	end
	local p1, p2, p3, p4 = st.q1[k], st.q2[k], st.q3[k], st.q4[k]
	local rung = st.own[k]
	if rung == 0 or spent then
		return p1, p2, p3, p4
	end
	local hp = spec.heldPassive
	if rung == 1 or rung == 5 then
		local s, add = st.tsuit[k], hp.straight * h
		if s == 1 then
			p1 += add
		elseif s == 2 then
			p2 += add
		elseif s == 3 then
			p3 += add
		else
			p4 += add
		end
	end
	if rung == 2 or rung == 5 then
		local s, add = st.fsuit[k], hp.flush
		if s == 1 then
			p1 += add
		elseif s == 2 then
			p2 += add
		elseif s == 3 then
			p3 += add
		else
			p4 += add
		end
	elseif rung == 3 then
		p3 += hp.fullHouse
		p4 += hp.fullHouse
	elseif rung == 4 then
		p1 += hp.quads
		p2 += hp.quads
		p3 += hp.quads
		p4 += hp.quads
	end
	return p1, p2, p3, p4
end
Read._held = held

-- ── the belief ───────────────────────────────────────────────────────────────────────────────

export type Belief = {
	w: { number },
	live: { number }, -- the pairs with weight, ascending: every loop over the belief walks these
	n: number, -- board cards the belief has already excluded
	skill: number, -- readSkill: how far the rider's decisions trust this belief (Hand)
	skipped: number, -- updates skipped because they left no weight (the opponent rode off script)
	prune: number, -- a pair below this share of the top weight is dropped (reading.prune)
	tally: { [string]: number }?, -- bits learned per cue, when a report asks
	truth: number?, -- the opponent's true pair, for the report's tally only; never read by a rider
}

function Read.newBelief(myHole: { number }, skill: number, tally: { [string]: number }?, truth: number?, prune: number?): Belief
	local w = table.create(NP, 1)
	local m1, m2 = myHole[1], myHole[2]
	for k = 1, NP do
		local a, b = PA[k], PB[k]
		if a == m1 or a == m2 or b == m1 or b == m2 then
			w[k] = 0
		end
	end
	local live = {}
	for k = 1, NP do
		if w[k] > 0 then
			table.insert(live, k)
		end
	end
	return { w = w, live = live, n = 0, skill = skill, skipped = 0, prune = prune or 0, tally = tally, truth = truth }
end

-- Drops pairs that lost their weight from the live list.
local function relive(b: Belief)
	local w, out = b.w, {}
	for _, k in b.live do
		if w[k] > 0 then
			table.insert(out, k)
		end
	end
	b.live = out
end

local function entropy(b: Belief): number
	local w = b.w
	local sum = 0
	for _, k in b.live do
		sum += w[k]
	end
	if sum <= 0 then
		return 0
	end
	local h = 0
	for _, k in b.live do
		local x = w[k]
		if x > 0 then
			local p = x / sum
			h -= p * math.log(p, 2)
		end
	end
	return h
end
Read.entropy = entropy

-- The board cards seen so far leave the belief (the reader can see them).
function Read.see(b: Belief, board: { number }, n: number)
	for i = b.n + 1, n do
		local c = board[i]
		for o = 0, 51 do
			if o ~= c then
				b.w[PIDX[c * 52 + o + 1]] = 0
			end
		end
	end
	if n > b.n then
		relive(b)
	end
	b.n = math.max(b.n, n)
end

local L: { number } = table.create(NP, 0)
local TIME_L: { number } = table.create(NP, 0) -- scratch: stance's timing likelihoods
local AIMS_L: { number } = table.create(NP, 0)

-- Apply likelihoods L[k] (any scale) to every live pair: Bayes. `cue` names the tally row.
local function apply(b: Belief, cue: string)
	local w = b.w
	local maxL = 0
	for _, k in b.live do
		if L[k] > maxL then
			maxL = L[k]
		end
	end
	if maxL <= 0 then
		b.skipped += 1
		return
	end
	local tally = b.tally
	local prune = b.prune
	local h0 = if tally then entropy(b) else 0
	local total, wmax = 0, 0
	for _, k in b.live do
		local x = w[k] * L[k] / maxL
		total += x
		if x > wmax then
			wmax = x
		end
	end
	if total <= 0 then
		b.skipped += 1
		return
	end
	-- Normalize to a max of 1 and drop pairs too faint to matter (reading.prune).
	for _, k in b.live do
		local x = w[k] * (L[k] / maxL) / wmax
		w[k] = if x < prune then 0 else x
	end
	relive(b)
	if tally then
		tally["bits." .. cue] = (tally["bits." .. cue] or 0) + h0 - entropy(b)
		tally["n." .. cue] = (tally["n." .. cue] or 0) + 1
	end
end

-- color: the lance and shield show the opponent's two hole colors (§7 *Color leak*).
function Read.color(b: Belief, red: number)
	for _, k in b.live do
		L[k] = if PRED[k] == red then 1 else 0
	end
	apply(b, "color")
end

function Read.redCount(hole: { number }): number
	return (if hole[1] % 4 >= 2 then 1 else 0) + (if hole[2] % 4 >= 2 then 1 else 0)
end

-- The honest stance set: the aims whose lean is worth most on these points (Hand's honestAim picks
-- one of them). Returns a 16-bit mask and its size.
-- Aim a = 4·(s − 1) + m sits at cardinal s (m = 0), a half step on (m = 1), the diagonal (m = 2)
-- or the half step before the next cardinal (m = 3), as Dial.lean weighs them; `share` is
-- sim.halfStepShare.
local hv: { number } = table.create(16, 0)
local function honestSet(share: number, p1: number, p2: number, p3: number, p4: number): (number, number)
	local v = hv
	local best = -math.huge
	for s = 1, 4 do
		local here = if s == 1 then p1 elseif s == 2 then p2 elseif s == 3 then p3 else p4
		local nxt = if s == 1 then p2 elseif s == 2 then p3 elseif s == 3 then p4 else p1
		local a = 4 * (s - 1)
		local x0 = here
		local x1 = here * share + nxt * (1 - share)
		local x2 = here * 0.5 + nxt * 0.5
		local x3 = here * (1 - share) + nxt * share
		v[a + 1], v[a + 2], v[a + 3], v[a + 4] = x0, x1, x2, x3
		best = math.max(best, x0, x1, x2, x3)
	end
	local mask, size = 0, 0
	for a = 1, 16 do
		if v[a] >= best - 1e-9 then
			mask = bit32.bor(mask, bit32.lshift(1, a - 1))
			size += 1
		end
	end
	return mask, size
end
Read._honestSet = honestSet

-- The honest stance sets of every live pair at a street (passive at full hold, as Hand's stance),
-- built once per hand and shared.
-- The honest stance set of a pair at a street (passive at full hold, as Hand's stance), cached.
local function honestAt(ctx: Ctx, st: Street, spent: boolean, k: number): (number, number)
	local hs = st.honest[spent]
	if hs == nil then
		hs = { mask = table.create(NP, -1), size = table.create(NP, 0) }
		st.honest[spent] = hs
	end
	if hs.mask[k] < 0 then
		local p1, p2, p3, p4 = held(st, k, 1, spent, st.spec)
		hs.mask[k], hs.size[k] = honestSet(ctx.cfg.sim.halfStepShare, p1, p2, p3, p4)
	end
	return hs.mask[k], hs.size[k]
end

local function inMask(mask: number, aim: number): boolean
	return bit32.band(mask, bit32.lshift(1, aim)) ~= 0
end

export type StanceObs = {
	pass: number,
	a0: number, -- the aim the rider committed to at the start of the pass
	early: boolean, -- committed at the first moment (sim.earliestCommit)
	a1: number, -- its aim after the reveal's re-stance, before any read
	prevN: number, -- board cards known at the start of the charge
	newN: number, -- board cards known after this pass's reveal
	spent: boolean, -- the opponent's once-per-hand trick is already used (public)
}

-- stance and timing (§7 *What each read targets*): the likelihood of the observed commit, its time
-- and the re-stance, under the assumed profile q, replaying Hand's stance script per pair. Timing's
-- share of what the stance tells is counted apart: first the commit time alone, then the aims.
function Read.stance(b: Belief, ctx: Ctx, obs: StanceObs, q: any)
	local cfg = ctx.cfg
	local sp = Read.street(ctx, obs.prevN)
	local sn = Read.street(ctx, obs.newN)
	local reveal = obs.newN > obs.prevN
	local hq, aq, dq = q.honesty, q.aggression, q.design
	local eps = cfg.reading.timeFloor
	local planP = if obs.pass == 4 then 1 else aq
	local w = b.w
	local timeL = TIME_L
	local anyDesign = false
	for _, k in b.live do
		do
			Read.entry(sp, k)
			Read.entry(sn, k)
			local ownP = if obs.spent then 0 else sp.own[k]
			local ownN = sn.own[k]
			-- Branch weights: d = planned and played to design (aim locked, committed at once).
			local pd = if ownP == 1 or ownP == 2 or ownP == 5 then planP * dq else 0
			local pTime = if obs.early then pd * (1 - eps) + (1 - pd) * eps else pd * eps + (1 - pd) * (1 - eps)
			timeL[k] = pTime
			if pd > 0 then
				anyDesign = true
			end
			local mP, nP = honestAt(ctx, sp, obs.spent, k)
			local mN, nN = honestAt(ctx, sn, obs.spent, k)
			if sp.own[k] == 0 and ownN == 0 then
				-- No trick at either street (most pairs): honest or a random aim, and an honest rider
				-- re-stances after the reveal when its aim is no longer among the best.
				local a0, a1 = obs.a0, obs.a1
				local pa = 0
				if inMask(mP, a0) then
					local q1: number
					if reveal and not inMask(mN, a0) then
						q1 = if inMask(mN, a1) then 1 / nN else 0
					else
						q1 = if a1 == a0 then 1 else 0
					end
					pa += hq / nP * q1
				end
				if a1 == a0 then
					pa += (1 - hq) / 16
				end
				L[k] = pa
				continue
			end
			-- A trick that lands on this reveal: planned and played to design locks the aim, and a
			-- flush moves home (Hand's reveal block).
			local land = reveal and not obs.spent and ownN > 0 and sp.own[k] == 0
			local landLock = if land and (ownN == 1 or ownN == 2 or ownN == 5) then planP * dq else 0
			local landHome = if ownN == 2 or ownN == 5 then Dial.HOME[sn.fsuit[k]] else -1
			local total = 0
			-- d: 1 design branch, 0 not; honest: 1, 0.
			for d = 0, 1 do
				local pdB = if d == 1 then pd else 1 - pd
				if pdB > 0 then
					local tB = if d == 1 then (if obs.early then 1 - eps else eps) else (if obs.early then eps else 1 - eps)
					for hon = 0, 1 do
						local ph = if hon == 1 then hq else 1 - hq
						if ph > 0 then
							-- P(a0)
							local pa0: number
							if d == 1 and (ownP == 2 or ownP == 5) then
								pa0 = if obs.a0 == Dial.HOME[sp.fsuit[k]] then 1 else 0
							elseif hon == 1 then
								pa0 = if inMask(mP, obs.a0) then 1 / nP else 0
							else
								pa0 = 1 / 16
							end
							if pa0 > 0 then
								-- P(a1 | a0): the reveal's re-stance and any landing trick.
								local pa1 = 0
								if not reveal then
									pa1 = if obs.a1 == obs.a0 then 1 else 0
								else
									-- Two sub-branches: a landing trick locked (prob landLock) or not.
									for lk = 0, 1 do
										local pl = if lk == 1 then landLock else 1 - landLock
										if pl > 0 then
											local aim = obs.a0
											local lock = d == 1
											if lk == 1 then
												lock = true
												if landHome >= 0 then
													aim = landHome
												end
											end
											if ownN == 0 then
												lock = false -- a held trick lost to the board can't be played
											end
											local q1: number
											if hon == 1 and not lock and ownN ~= 1 and not inMask(mN, aim) then
												q1 = if inMask(mN, obs.a1) then 1 / nN else 0
											else
												q1 = if obs.a1 == aim then 1 else 0
											end
											pa1 += pl * q1
										end
									end
								end
								total += pdB * tB * ph * pa0 * pa1
							end
						end
					end
				end
			end
			-- The aims' likelihood given the timing, so the two tallies add to the whole.
			L[k] = if pTime > 0 then total / pTime else 0
		end
	end
	-- Timing first, then the aims given the timing. With no trick played to its design among the
	-- pairs, the timing says nothing about the cards (the script ties hold to the rider).
	if cfg.reading.cues.timing == 1 then
		if anyDesign then
			local live = b.live
			for _, k in live do
				AIMS_L[k], L[k] = L[k], timeL[k]
			end
			apply(b, "timing")
			for _, k in live do
				L[k] = AIMS_L[k]
			end
		elseif b.tally then
			local tally = b.tally :: { [string]: number }
			tally["n.timing"] = (tally["n.timing"] or 0) + 1
		end
	end
	if cfg.reading.cues.stance == 1 then
		apply(b, "stance")
	end
end

-- unleash: an announced unleash names the rung, and a flush its suit (§6 *Unleash rules*).
function Read.unleash(b: Belief, ctx: Ctx, n: number, rung: number, suit: number?)
	local st = Read.street(ctx, n)
	for _, k in b.live do
		if b.w[k] > 0 then
			Read.entry(st, k)
			L[k] = if st.own[k] == rung and (suit == nil or st.fsuit[k] == suit) then 1 else 0
		end
	end
	apply(b, "unleash")
end

export type ContactObs = {
	n: number, -- board cards known at contact
	me: Contact.Fighter, -- the reader at contact (it knows its own stats)
	oAim: number?,
	oH: number,
	oBattered: number,
	oSpent: boolean,
	arena: Contact.Arena,
	myBefore: number,
	oBefore: number,
	myMax: number,
	oMax: number,
	myNet: number, -- the reader's Posture change at contact (the hit taken, a clean block's restore)
	oNet: number, -- the opponent's
	oHeal: number, -- the opponent's ♥ heal after contact (0093: its own beat)
}

local function pips(x: number, cfg: any): number
	return if cfg.switches.posture == "pips" then math.floor(x + 0.5) else x
end

local function healPips(x: number, cfg: any): number
	if cfg.switches.posture == "pips" and cfg.switches.healRound == "up" then
		return math.ceil(x - 1e-9)
	end
	return pips(x, cfg)
end

local function near(a: number, b: number): boolean
	return math.abs(a - b) < 1e-6
end

-- hit and heal: replay the contact for every pair (§4 *Contact resolution*) and keep the pairs that
-- give the Posture changes both riders saw. With reading.heal = "net" the heal shows only inside the
-- bar's total change, not as its own beat.
function Read.contact(b: Belief, ctx: Ctx, obs: ContactObs)
	local cfg = ctx.cfg
	local spec, sim = cfg.spec, cfg.sim
	local st = Read.street(ctx, obs.n)
	local lw = if obs.oAim == nil then { 0, 0, 0, 0 } else ctx.lean[(obs.oAim :: number) + 1]
	local lam = sim.lean
	local S = { 0, 0, 0, 0 }
	local F: Contact.Fighter = { aim = obs.oAim, h = obs.oH, S = S, buffer = 0, battered = obs.oBattered, trick = nil, ward = 0 }
	local base = spec.statBase
	local restore = pips(spec.cleanBlockRestore, cfg)
	local beat = cfg.reading.heal == "beat"
	local healL = TIME_L -- scratch
	local w = b.w
	-- Aims are public, so both tiers are known before any pair is tried.
	local tierIn = Dial.tier(obs.oAim, obs.me.aim, spec)
	local tierOut = Dial.tier(obs.me.aim, obs.oAim, spec)
	for _, k in b.live do
		if w[k] > 0 then
			local p1, p2, p3, p4 = held(st, k, obs.oH, obs.oSpent, spec)
			S[1] = base + p1 * (1 + lam * lw[1])
			S[2] = base + p2 * (1 + lam * lw[2])
			S[3] = base + p3 * (1 + lam * lw[3])
			S[4] = base + p4 * (1 + lam * lw[4])
			F.buffer = sim.heartBuffer * p3 * lam * lw[3]
			local takenDmg, takenClean = Contact.plain(F, obs.me, tierIn, obs.arena, cfg)
			local dealtDmg, dealtClean = Contact.plain(obs.me, F, tierOut, obs.arena, cfg)
			local myP = obs.myBefore - pips(takenDmg, cfg)
			if takenClean then
				myP = math.min(obs.myMax, myP + restore)
			end
			local oP = obs.oBefore - pips(dealtDmg, cfg)
			if dealtClean then
				oP = math.min(obs.oMax, oP + restore)
			end
			-- The heal (Hand, step 7): a share of what the contact took, by unleaned ♥ points.
			local lost = obs.oBefore - oP
			local heal = 0
			if lost > 0 then
				local _, _, h3, _ = held(st, k, 0, obs.oSpent, spec)
				local share = sim.healBase + sim.healPerPoint * h3
				heal = math.min(obs.oMax, oP + healPips(lost * math.min(1, share), cfg)) - oP
			end
			local hitOk = near(myP - obs.myBefore, obs.myNet)
			if beat then
				L[k] = if hitOk and near(oP - obs.oBefore, obs.oNet) then 1 else 0
				healL[k] = if near(heal, obs.oHeal) then 1 else 0
			else
				L[k] = if hitOk and near(oP + heal - obs.oBefore, obs.oNet + obs.oHeal) then 1 else 0
				healL[k] = 1
			end
		end
	end
	if cfg.reading.cues.hit == 1 then
		apply(b, "hit")
	end
	if beat and cfg.reading.cues.heal == 1 then
		table.move(healL, 1, NP, 1, L)
		apply(b, "heal")
	end
end

export type BetObs = {
	round: number,
	n: number, -- board cards known at the bet
	bands: boolean, -- switches.betting = "bands"; else the script
	facing: boolean,
	canRaise: boolean, -- the round's re-raise cap not yet reached
	raised: boolean, -- the action: a Raise, else a Stay (a Yield ends the hand)
	lead: number, -- the bettor's Posture lead, own − opponent (half hearts)
	spent: boolean, -- the bettor's trick is already used
}

-- bets (0094): the likelihood of a Stay or a Raise under the assumed rider's betting. Bands: it
-- raises when its own odds (Odds, its key and the public lead) reach raiseAt, and Yields facing a
-- raise below yieldAt. Script: strength() plus its uniform noise. reading.betFloor is the chance the
-- reader allows that the bet broke the assumed script (a reading bettor weighs its own read too).
function Read.bet(b: Belief, ctx: Ctx, obs: BetObs, q: any)
	local cfg = ctx.cfg
	local st = Read.street(ctx, obs.n)
	local eps = cfg.reading.betFloor
	local round = obs.round
	local estOf: { [number]: number } = {}
	local bucket = Odds.bucket(obs.lead)
	local thr = 1 - q.aggression * 0.9
	for _, k in b.live do
		Read.entry(st, k)
		local p: number
		if obs.bands then
			local key = if obs.n < 3 then PCLASS[k] else st.key[k]
			local e = estOf[key]
			if e == nil then
				e = Odds.estimate(cfg._odds, round, key, bucket)
				estOf[key] = e
			end
			local yields = obs.facing and e < q.yieldAt[round]
			local raises = not yields and obs.canRaise and e >= q.raiseAt[round]
			p = if yields then 0 elseif raises == obs.raised then 1 else 0
		else
			local s0 = 0.12 * st.sub[k] + 0.4 * obs.lead / cfg.spec.postureStart
			if st.own[k] > 0 and not obs.spent then
				s0 += 0.5
			end
			local pYield = if obs.facing then math.clamp((q.yieldBelow - (s0 - 0.15)) / 0.3, 0, 1) else 0
			local pRaise = if obs.canRaise then math.clamp((s0 + 0.15 - thr) / 0.3, 0, 1 - pYield) else 0
			p = if obs.raised then pRaise else 1 - pYield - pRaise
		end
		L[k] = eps + (1 - eps) * p
	end
	apply(b, "bets")
end

-- ── what the belief drives ───────────────────────────────────────────────────────────────────

-- A systematic sample of m pairs from the belief (no RNG, so the hand's stream is untouched):
-- the pairs at the cumulative-weight quantiles (i − ½)/m.
function Read.sample(b: Belief, m: number): { number }
	local w = b.w
	local total = 0
	for _, k in b.live do
		total += w[k]
	end
	local out = table.create(m, 0)
	if total <= 0 then
		return {}
	end
	local acc, i = 0, 1
	for _, k in b.live do
		local x = w[k]
		if x > 0 then
			acc += x
			while i <= m and acc >= (i - 0.5) / m * total do
				out[i] = k
				i += 1
			end
		end
	end
	while i <= m do
		out[i] = out[i - 1]
		i += 1
	end
	return out
end

-- A sampled pair's unleaned points with its held passive at hold h, at the street with n board cards.
function Read.pointsOf(ctx: Ctx, n: number, k: number, h: number, spent: boolean): { number }
	local p1, p2, p3, p4 = held(Read.street(ctx, n), k, h, spent, ctx.cfg.spec)
	return { p1, p2, p3, p4 }
end

-- The belief's weight on each opponent hand key at a bet: Bets 1–2 the starting-hand class,
-- Bets 3–4 Odds' made-hand key on the board so far.
function Read.keyWeights(b: Belief, ctx: Ctx, bet: number, n: number): { [number]: number }
	local out: { [number]: number } = {}
	local w = b.w
	if bet <= 2 or n < 3 then
		for _, k in b.live do
			local x = w[k]
			if x > 0 then
				local c = PCLASS[k]
				out[c] = (out[c] or 0) + x
			end
		end
	else
		local st = Read.street(ctx, n)
		local key = st.key
		for _, k in b.live do
			local x = w[k]
			if x > 0 then
				Read.entry(st, k)
				local c = key[k]
				out[c] = (out[c] or 0) + x
			end
		end
	end
	return out
end

-- The belief's probability on the opponent's true pair (report only).
function Read.truthShare(b: Belief): number
	local t = b.truth
	if t == nil then
		return 0
	end
	local total = 0
	for _, k in b.live do
		total += b.w[k]
	end
	return if total > 0 then b.w[t] / total else 0
end

return Read
