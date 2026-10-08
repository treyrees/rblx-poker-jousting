--!strict
-- Odds.luau — what the betting rider believes its chance to win is (switches.betting = "bands").
--
-- A rider can see its own hole cards, the board so far and both Posture bars (§2, §7). The odds are
-- the sim's own record of how often a rider in that spot has won the hand, ridden to the end: a
-- calibration run of the default script (which never Yields) tallies wins by spot. That is a
-- player who knows the game's odds from experience, not one who reads the opponent: the odds never
-- condition on the opponent's bets or on who kept their hand in the yard.
--
-- A spot is the bet (1–4), a hand key and a Posture-lead bucket:
--   Bets 1–2 (hole cards only): the starting-hand class, 1..169 (Cards.class).
--   Bets 3–4 (the flop or the turn known): the category of the rider's best five so far (0–8), the
--   board's own category (0 none, 1 pair, 2 two pair, 3 trips or more) and a draw flag (four to a
--   flush or to a straight, using a hole card): 1..72.
-- The lead acts on the log-odds, the same shift for every hand key at that bet, so a sparse key still
-- gets a sensible estimate.

local Cards = require("./Cards")

local Odds = {}

export type Table = {
	base: { { [number]: number } }, -- per bet: hand key → win share (shrunk toward the bet's mean)
	lead: { { [number]: number } }, -- per bet: lead bucket → log-odds shift
	mean: { number }, -- per bet: overall win share
}

local PRIOR = 20 -- pseudo-hands at the bet's mean, so a rare key isn't read off a handful of hands

-- Posture lead (own − opponent, in half hearts) → bucket 1..7; 4 is level.
function Odds.bucket(lead: number): number
	if lead <= -12 then
		return 1
	elseif lead <= -5 then
		return 2
	elseif lead < 0 then
		return 3
	elseif lead == 0 then
		return 4
	elseif lead < 5 then
		return 5
	elseif lead < 12 then
		return 6
	end
	return 7
end

-- The board's own repeated ranks: 0 none, 1 a pair, 2 two pair, 3 trips or more.
local function boardCategory(known: { number }): number
	local count = table.create(15, 0)
	local pairs, trips = 0, false
	for _, c in known do
		local r = c // 4 + 2
		count[r] += 1
		if count[r] == 2 then
			pairs += 1
		elseif count[r] == 3 then
			trips = true
		end
	end
	if trips then
		return 3
	end
	return math.min(pairs, 2)
end

-- Four to a flush or four ranks inside a five-rank window, with a hole card in it and no made trick.
local function drawing(hole: { number }, known: { number }): boolean
	local suits = { 0, 0, 0, 0 }
	local holeSuit = { false, false, false, false }
	local ranks = table.create(15, false)
	local holeRank = table.create(15, false)
	local function add(c: number, isHole: boolean)
		local r, s = c // 4 + 2, c % 4 + 1
		suits[s] += 1
		ranks[r] = true
		if r == 14 then
			ranks[1] = true
		end
		if isHole then
			holeSuit[s] = true
			holeRank[r] = true
			if r == 14 then
				holeRank[1] = true
			end
		end
	end
	for _, c in hole do
		add(c, true)
	end
	for _, c in known do
		add(c, false)
	end
	for s = 1, 4 do
		if suits[s] == 4 and holeSuit[s] then
			return true
		end
	end
	for low = 1, 10 do
		local n, mine = 0, false
		for r = low, low + 4 do
			if ranks[r] then
				n += 1
				if holeRank[r] then
					mine = true
				end
			end
		end
		if n == 4 and mine then
			return true
		end
	end
	return false
end

-- The hand key at a bet (see the header).
function Odds.key(bet: number, hole: { number }, known: { number }): number
	if bet <= 2 or #known < 3 then
		return Cards.class(hole)
	end
	local all = table.clone(hole)
	for _, c in known do
		table.insert(all, c)
	end
	local own = Cards.evaluate(all).category
	local draw = if own < Cards.STRAIGHT and drawing(hole, known) then 1 else 0
	return own * 8 + boardCategory(known) * 2 + draw + 1
end

local function logit(p: number): number
	p = math.clamp(p, 1e-4, 1 - 1e-4)
	return math.log(p / (1 - p))
end

-- Builds the table from tallied spots: {bet, key, bucket, won} with won 1, 0.5 (split) or 0.
function Odds.build(spots: { { number } }): Table
	local n: { { [number]: number } } = { {}, {}, {}, {} }
	local w: { { [number]: number } } = { {}, {}, {}, {} }
	local bn: { { [number]: number } } = { {}, {}, {}, {} }
	local bw: { { [number]: number } } = { {}, {}, {}, {} }
	local tn, tw = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }
	for _, s in spots do
		local b, k, l, won = s[1], s[2], s[3], s[4]
		n[b][k] = (n[b][k] or 0) + 1
		w[b][k] = (w[b][k] or 0) + won
		bn[b][l] = (bn[b][l] or 0) + 1
		bw[b][l] = (bw[b][l] or 0) + won
		tn[b] += 1
		tw[b] += won
	end
	local t: Table = { base = { {}, {}, {}, {} }, lead = { {}, {}, {}, {} }, mean = { 0.5, 0.5, 0.5, 0.5 } }
	for b = 1, 4 do
		local m = if tn[b] > 0 then tw[b] / tn[b] else 0.5
		t.mean[b] = m
		for k, cnt in n[b] do
			t.base[b][k] = (w[b][k] + PRIOR * m) / (cnt + PRIOR)
		end
		for l, cnt in bn[b] do
			local p = (bw[b][l] + PRIOR * m) / (cnt + PRIOR)
			t.lead[b][l] = logit(p) - logit(m)
		end
	end
	return t
end

-- The rider's estimated chance to win from this spot, 0..1.
function Odds.estimate(t: Table, bet: number, key: number, bucket: number): number
	local p = t.base[bet][key] or t.mean[bet]
	local x = logit(p) + (t.lead[bet][bucket] or 0)
	return 1 / (1 + math.exp(-x))
end

Odds._drawing = drawing
Odds._boardCategory = boardCategory

return Odds
