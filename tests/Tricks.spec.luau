--!strict
-- Tricks.spec.luau — ownership (GAME_SPEC §6, 0041, 0042), the straight's meter (0032) and the
-- trick hit and ward chain the §6 targets need (SANITY_CHECK §2).

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Cards = require("../sim/Cards")
local Timeline = require("../sim/Timeline")
local Tricks = require("../sim/Tricks")

local L = Cards.list

kit.describe("Tricks: ownership", function()
	kit.it("a trick is yours only if a hole card is part of it", function()
		local st = Tricks.status(L("9c Tc"), L("6d 7h 8s"))
		kit.expectTrue(st.owns)
		kit.expectEqual(st.rung, 1)
	end)
	kit.it("a board-made trick puts both riders on its rung, owned by neither (0041)", function()
		local st = Tricks.status(L("2c 3d"), L("6d 7h 8s 9c Td"))
		kit.expectFalse(st.owns)
		kit.expectEqual(st.boardRung, 1)
		kit.expectEqual(st.rung, 1)
	end)
	kit.it("a duplicate of a board card doesn't improve it: still the board's trick", function()
		local st = Tricks.status(L("9h 2d"), L("6d 7h 8s 9c Td"))
		kit.expectFalse(st.owns)
	end)
	kit.it("improving within the board's rung is owned but level (0041)", function()
		local st = Tricks.status(L("Jc 2d"), L("6d 7h 8s 9c Td"))
		kit.expectTrue(st.owns)
		kit.expectEqual(st.ownRung, st.boardRung)
	end)
	kit.it("hole cards that lift a rider to a higher rung put them above the board", function()
		local st = Tricks.status(L("2d 3d"), L("6d 7h 8d 9d Td"))
		kit.expectTrue(st.owns)
		kit.expectEqual(st.rung, 2)
		kit.expectEqual(st.boardRung, 1)
	end)
	kit.it("a held trick the board plays over is no longer yours (0042)", function()
		local turn = Tricks.status(L("9c Tc"), L("6h 7h 8h 2h"))
		kit.expectTrue(turn.owns)
		local river = Tricks.status(L("9c Tc"), L("6h 7h 8h 2h Kh"))
		kit.expectFalse(river.owns)
		kit.expectEqual(river.rung, 2) -- on the board's flush rung
	end)
end)

kit.describe("Tricks: the straight's meter (0032)", function()
	local cfg = Config.defaults()
	kit.it("one card per fifth of the run-up (strict: h ≥ k/5)", function()
		cfg.switches.meterThreshold = "strict"
		kit.expectEqual(Tricks.meterCards(0.19, cfg, true), 0)
		kit.expectEqual(Tricks.meterCards(0.2, cfg, true), 1)
		kit.expectEqual(Tricks.meterCards(0.99, cfg, true), 4)
		kit.expectEqual(Tricks.meterCards(1, cfg, true), 5)
	end)
	kit.it("strict: no rider leaving Neutral reaches the fifth card (SANITY_CHECK c4)", function()
		cfg.switches.meterThreshold = "strict"
		local h = Timeline.hold(cfg.sim.earliestCommit, cfg, true)
		kit.expectEqual(Tricks.meterCards(h, cfg, true), 4)
	end)
	kit.it("reachable: committing at the first moment unlocks all five", function()
		cfg.switches.meterThreshold = "reachable"
		local h = Timeline.hold(cfg.sim.earliestCommit, cfg, true)
		kit.expectEqual(Tricks.meterCards(h, cfg, true), 5)
	end)
	kit.it("the hit grows as x^y: each card worth more than the last; higher straights build bigger", function()
		local prev = 0
		for n = 1, 5 do
			local hit = Tricks.straightHit(9, n, cfg)
			kit.expectTrue(hit > prev, "card " .. n)
			if n > 2 then
				kit.expectTrue(hit - prev > prev - Tricks.straightHit(9, n - 2, cfg), "growing steps")
			end
			prev = hit
		end
		kit.expectTrue(Tricks.straightHit(14, 5, cfg) > Tricks.straightHit(9, 5, cfg))
		kit.expectEqual(Tricks.meterY(5, 1), 1) -- the wheel's first card is the ace, as 1
	end)
	kit.it("changing aim resets it: a late commit unlocks little", function()
		cfg.switches.meterThreshold = "reachable"
		kit.expectEqual(Tricks.meterCards(Timeline.hold(7.4, cfg, true), cfg, true), 0)
	end)
end)

kit.describe("Tricks: the §6 targets hold at the starting values", function()
	local cfg = Config.defaults()
	local sim = cfg.sim
	-- The most one hit must clear: max Posture, Guard armor at full hold and the ♥ buffer, on a
	-- generous 16 points of ♥ and ♦ with the lean applied.
	local heart = 16
	local posture = cfg.spec.postureStart + sim.heartPosture * heart
	local S = cfg.spec.statBase + heart * (1 + sim.lean)
	local cut = sim.heartBuffer * heart * sim.lean
	local Pnum = posture + sim.armorRate * S + cut
	local Pmirror = posture + sim.armorRate * S * sim.flushExplode + cut -- a Gilded Mirror defender
	local maxHit = { Tricks.straightHit(14, 5, cfg), sim.hit.flush, sim.hit.fullHouse, sim.hit.quads, sim.hit.straightFlush }
	local minHit = { Tricks.straightHit(5, 5, cfg), sim.hit.flush, sim.hit.fullHouse, sim.hit.quads, sim.hit.straightFlush }
	local ward = { sim.ward.straight, sim.ward.flush, sim.ward.fullHouse, sim.ward.quads, sim.ward.straightFlush }
	-- The earliest pass a trick can fire on is Pass 2, the flop (0049); the hardest is Pass 4.
	local early = cfg.spec.street[2]
	local late = cfg.spec.street[4]

	kit.it("every trick played to design unhorses a numeric rider from full Posture on Pass 2", function()
		for r = 1, 5 do
			kit.expectTrue(minHit[r] * early >= Pnum, Tricks.KEY[r])
		end
	end)
	kit.it("each rung's ward stops every lower rung's hit, even on Pass 4", function()
		for r = 2, 5 do
			for q = 1, r - 1 do
				kit.expectTrue(ward[r] >= maxHit[q] * late, Tricks.KEY[r] .. " ward vs " .. Tricks.KEY[q])
			end
		end
	end)
	kit.it("each rung's hit breaks every lower ward and still unhorses, even on Pass 2", function()
		for r = 2, 5 do
			for q = 1, r - 1 do
				local P = if q == 2 then Pmirror else Pnum
				kit.expectTrue(minHit[r] * early - ward[q] >= P, Tricks.KEY[r] .. " vs " .. Tricks.KEY[q])
			end
		end
	end)
end)
