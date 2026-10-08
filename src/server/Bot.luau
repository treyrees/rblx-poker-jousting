--!strict
-- Bot.luau — the sim's scripted rider (sim/Hand.luau, profiles in Rules.Config.riders) acting in
-- real time (0097, 0100, 0107). Numeric hands only (0099): no tricks, no unleash, no reading model.
--
-- Each pass the bot, as in Hand.play:
--   1. sets a stance at a time set by hold discipline: an honest rider leans toward its loaded
--      stats (§4 *Stances*), the rest pick a random aim;
--   2. after the reveal, an honest rider whose best lean moved re-stances at the end of slow motion;
--   3. with chance `read`, switches late (sim.readTime) to the best aim against the opponent's
--      public aim and hold at that moment, the opponent's cards taken as the public estimate
--      (an average hole card per suit, Hand.publicPoints).
-- Its bets are the betting rider's (switches.betting = "bands", Rules.Odds): raise when its odds
-- are at least raiseAt, Yield facing a raise when below yieldAt. Until the odds table is
-- calibrated it bets with the sim's script, which never Yields.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Rules = ReplicatedStorage:WaitForChild("Rules")
local Cards = require(Rules:WaitForChild("Cards"))
local Contact = require(Rules:WaitForChild("Contact"))
local Dial = require(Rules:WaitForChild("Dial"))
local Hand = require(Rules:WaitForChild("Hand"))
local Odds = require(Rules:WaitForChild("Odds"))
local Timeline = require(Rules:WaitForChild("Timeline"))

local Bot = {}

export type Plan = {
	aim: number, -- the stance
	tAim: number, -- when it is committed (s into the pass)
	honest: boolean,
}

local function pointsValue(pts: { number }, w: { number }): number
	return pts[1] * w[1] + pts[2] * w[2] + pts[3] * w[3] + pts[4] * w[4]
end

-- Step 1: the stance for a pass, from the stats known at the start of the charge.
function Bot.stance(profile: any, hole: { number }, knownBoard: { number }, cfg: any, rng: Random): Plan
	local pts = Cards.points(hole, knownBoard, cfg.spec)
	local honest = rng:NextNumber() < profile.honesty
	local function r(): number
		return rng:NextNumber()
	end
	local aim = if honest then Hand.honestAim(pts, cfg, r) else rng:NextInteger(0, Dial.POSITIONS - 1)
	local sim = cfg.sim
	local tAim = sim.earliestCommit + (1 - profile.hold) * (cfg.spec.timeline.slowEnd - sim.earliestCommit)
	return { aim = aim, tAim = tAim, honest = honest }
end

-- Step 2: after the reveal, the honest stance on the new stats, if it is worth more than the old
-- one. Returns the new aim or nil to stay.
function Bot.restance(plan: Plan, hole: { number }, newBoard: { number }, cfg: any, rng: Random): number?
	if not plan.honest then
		return nil
	end
	local pts = Cards.points(hole, newBoard, cfg.spec)
	local best = Hand.honestAim(pts, cfg, function()
		return rng:NextNumber()
	end)
	local v1 = pointsValue(pts, Dial.lean(best, cfg.sim.halfStepShare))
	local v0 = pointsValue(pts, Dial.lean(plan.aim, cfg.sim.halfStepShare))
	if v1 > v0 + 1e-9 then
		return best
	end
	return nil
end

-- Step 3: the read. The best aim against the opponent's public aim and hold, scoring each of the 16
-- positions by damage dealt minus damage taken (Hand.play's bestResponse, numeric path). The
-- opponent's cards are the public estimate; a switch lands at sim.readTime with that hold.
function Bot.read(
	hole: { number },
	newBoard: { number },
	myAim: number,
	myT: number,
	myBattered: number,
	oAim: number?,
	oT: number?,
	oBattered: number,
	pass: number,
	hasReveal: boolean,
	cfg: any
): number
	local sim = cfg.sim
	local myPts = Cards.points(hole, newBoard, cfg.spec)
	local oPts = Hand.publicPoints(newBoard, cfg)
	local oS, oCut = Hand.statsAt(oPts, oAim, cfg)
	local oF: Contact.Fighter = {
		aim = oAim,
		h = Timeline.hold(oT, cfg, hasReveal),
		S = oS,
		buffer = oCut,
		battered = oBattered,
		trick = nil,
		ward = 0,
	}
	local arena: Contact.Arena = { street = cfg.spec.street[pass], openLists = 1, siege = 1 }
	local hSwitch = Timeline.hold(sim.readTime, cfg, hasReveal)
	local best, bestV = myAim, -math.huge
	for a = 0, Dial.POSITIONS - 1 do
		local h = if a == myAim then Timeline.hold(myT, cfg, hasReveal) else hSwitch
		local S, cut = Hand.statsAt(myPts, a, cfg)
		local F: Contact.Fighter = { aim = a, h = h, S = S, buffer = cut, battered = myBattered, trick = nil, ward = 0 }
		local v = Contact.strike(F, oF, arena, cfg).dmg - Contact.strike(oF, F, arena, cfg).dmg
		if v > bestV + 1e-9 then
			best, bestV = a, v
		end
	end
	return best
end

-- The bet. `odds` is the calibrated table (Rules.Odds), or nil while it is still being built.
-- Returns "stay" | "raise" | "yield"; a Yield only facing a raise (0081), a raise only under the cap.
function Bot.bet(
	profile: any,
	odds: any,
	round: number,
	hole: { number },
	known: { number },
	myPosture: number,
	oPosture: number,
	facing: boolean,
	canRaise: boolean,
	cfg: any,
	rng: Random
): string
	local lead = myPosture - oPosture
	local raise: boolean
	if odds then
		local est = Odds.estimate(odds, round, Odds.key(round, hole, known), Odds.bucket(lead))
		if facing and est < profile.yieldAt[round] then
			return "yield"
		end
		raise = est >= profile.raiseAt[round]
	else
		-- The sim's script (Hand.play's strength()): sub-hand, the Posture race and a little noise.
		local _, sub = Cards.points(hole, known, cfg.spec)
		local s = 0.12 * sub + 0.4 * lead / cfg.spec.postureStart + (rng:NextNumber() - 0.5) * 0.3
		if facing and s < profile.yieldBelow then
			return "yield"
		end
		raise = s > 1 - profile.aggression * 0.9
	end
	return if raise and canRaise then "raise" else "stay"
end

return Bot
