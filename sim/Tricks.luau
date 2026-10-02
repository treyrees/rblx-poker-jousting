--!strict
-- Tricks.luau — the trick ladder, ownership, the straight's meter and trick hit sizes
-- (GAME_SPEC §6; decisions 0019, 0031–0033, 0041, 0042).

local Cards = require("./Cards")
local Dial = require("./Dial")
local Timeline = require("./Timeline")

local Tricks = {}

-- Rungs, low to high (§6 *The trick ladder*). 0 is below the ladder (a numeric hand).
Tricks.KEY = { "straight", "flush", "fullHouse", "quads", "straightFlush" }

function Tricks.rungOf(category: number): number
	return if category >= Cards.STRAIGHT then category - 3 else 0
end

export type Status = {
	eval: Cards.Eval, -- best five of hole + board
	owns: boolean, -- a trick with at least one hole card in it (§6 *Ownership*)
	ownRung: number, -- rung of the owned trick, 0 if none
	boardRung: number, -- rung of the board's own trick (river only), 0 if none
	rung: number, -- where the rider stands: own trick, else the board's
}

-- Ownership (§6 *Ownership*, 0041, 0042). A rider owns a trick when their best five beats the
-- board's best five: then at least one hole card is in it. Equal means they play the board, and a
-- held trick a later board trick plays over is no longer theirs (0042). An improvement within the
-- board's rung is owned but level, so an unleash clashes with the board's answer (0041).
function Tricks.status(hole: { number }, board: { number }): Status
	local all = table.clone(hole)
	for _, c in board do
		table.insert(all, c)
	end
	local e = if #all >= 5 then Cards.evaluate(all) else { value = 0, category = 0 } :: any
	local boardRung, boardValue = 0, -1
	if #board == 5 then
		local eb = Cards.evaluate(board)
		boardRung, boardValue = Tricks.rungOf(eb.category), eb.value
	end
	local rung = Tricks.rungOf(e.category)
	local owns = rung > 0 and e.value > boardValue
	return {
		eval = e,
		owns = owns,
		ownRung = if owns then rung else 0,
		boardRung = boardRung,
		rung = if owns then rung else boardRung,
	}
end

-- The suit of a straight's top card (the held straight's passive, §6 table). A hole card of that
-- rank first, since hole cards count in full.
function Tricks.topSuit(hole: { number }, board: { number }, top: number): number
	local r = if top == 5 then 5 else top
	for _, c in hole do
		if Cards.rank(c) == r then
			return Cards.suit(c)
		end
	end
	for _, c in board do
		if Cards.rank(c) == r then
			return Cards.suit(c)
		end
	end
	return Cards.CLUB
end

-- The straight's meter (§6, 0032): cards unlocked, low to high, one per fifth of the run-up.
-- switches.meterThreshold (SANITY_CHECK c4):
--   strict     card k at h ≥ k/5; the fifth needs h = 1, which no rider leaving Neutral reaches
--   reachable  h measured against the earliest possible commit, so committing at once unlocks five
function Tricks.meterCards(h: number, cfg: any, hasReveal: boolean): number
	local x = h
	if cfg.switches.meterThreshold == "reachable" then
		local hMax = Timeline.hold(cfg.sim.earliestCommit, cfg, hasReveal)
		x = math.min(1, h / hMax)
	elseif cfg.switches.meterThreshold ~= "strict" then
		error("unknown meterThreshold " .. cfg.switches.meterThreshold)
	end
	return math.clamp(math.floor(x * 5 + 1e-9), 0, 5)
end

-- The meter's y: the value of the highest card unlocked. The wheel's cards are A(1),2,3,4,5.
function Tricks.meterY(top: number, cards: number): number
	return top - 5 + cards
end

function Tricks.straightHit(top: number, cards: number, cfg: any): number
	-- 0073: the power is in the hold. Each card unlocked multiplies the hit by x; the straight's rank
	-- adds a little on top (a higher straight unhorses a card sooner, §6).
	local sim = cfg.sim
	if cards <= 0 then
		return 0
	end
	return sim.straightK * sim.straightX ^ cards * (1 + sim.straightRank * (top - 5))
end

export type Shot = { hit: number, designed: boolean, suit: number? }

-- A trick's hit on the pass it fires, before the street multiplier (§6 *Trick effects on the
-- unleash pass*). Flat per rung: stats, tier base and the hold multiplier don't scale it; the
-- straight's meter replaces hold. `designed` is 0031's "played to its design".
function Tricks.shot(status: Status, hole: { number }, board: { number }, aim: number?, h: number, cfg: any, hasReveal: boolean): Shot
	local e = status.eval
	local rung = status.ownRung
	local share = cfg.sim.halfStepShare
	if rung == 1 then
		local n = Tricks.meterCards(h, cfg, hasReveal)
		return { hit = Tricks.straightHit(e.straightTop :: number, n, cfg), designed = n == 5 }
	elseif rung == 2 then
		local suit = e.flushSuit :: number
		local f = Dial.homeFactor(aim, suit, share)
		local hit = if cfg.switches.flushHit == "F1" then cfg.sim.hit.flush * f else 0
		return { hit = hit, designed = f == 1, suit = suit }
	elseif rung == 3 then
		return { hit = cfg.sim.hit.fullHouse, designed = true }
	elseif rung == 4 then
		return { hit = cfg.sim.hit.quads, designed = true }
	elseif rung == 5 then
		local suit = e.flushSuit :: number
		local n = Tricks.meterCards(h, cfg, hasReveal)
		local top = e.straightTop :: number
		local f = Dial.homeFactor(aim, suit, share)
		local meter = if n == 0 then 0 else cfg.sim.straightX ^ (Tricks.meterY(top, n) - top)
		return { hit = cfg.sim.hit.straightFlush * meter * f, designed = n == 5 and f == 1, suit = suit }
	end
	error("no trick to fire")
end

return Tricks
