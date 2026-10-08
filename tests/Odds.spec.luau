--!strict
-- Odds.spec.luau — the betting rider's odds (switches.betting = "bands"): spots, keys and the table.

local kit = require("./lib/testkit")
local Cards = require("../sim/Cards")
local Odds = require("../sim/Odds")

local L = Cards.list

kit.describe("Odds", function()
	kit.it("Posture lead buckets: level is 4, a 6-pip lead is 6, a 12-pip deficit is 1", function()
		kit.expectEqual(Odds.bucket(0), 4)
		kit.expectEqual(Odds.bucket(-1), 3)
		kit.expectEqual(Odds.bucket(-5), 2)
		kit.expectEqual(Odds.bucket(-12), 1)
		kit.expectEqual(Odds.bucket(4), 5)
		kit.expectEqual(Odds.bucket(6), 6)
		kit.expectEqual(Odds.bucket(30), 7)
	end)
	kit.it("Bets 1–2 key on the starting-hand class; Bets 3–4 on the made hand, the board and draws", function()
		kit.expectEqual(Odds.key(1, L("Ah Kh"), {}), Cards.class(L("Ah Kh")))
		kit.expectEqual(Odds.key(2, L("Ah Kh"), {}), Cards.class(L("Ah Kh")))
		-- A flush draw on the flop: high card, unpaired board, drawing.
		kit.expectEqual(Odds.key(3, L("Ah Kh"), L("2h 7h 9c")), 0 * 8 + 0 * 2 + 1 + 1)
		-- A pair on a paired board: two pair, board pair, no draw.
		kit.expectEqual(Odds.key(3, L("Ah 3c"), L("As 7d 7c")), 2 * 8 + 1 * 2 + 0 + 1)
		-- A made straight is no longer a draw.
		kit.expectEqual(Odds.key(4, L("5h 6c"), L("7s 8d 9c Kh")), Cards.STRAIGHT * 8 + 0 + 0 + 1)
	end)
	kit.it("draws need a hole card: four to a straight on the board alone isn't the rider's draw", function()
		kit.expectTrue(Odds._drawing(L("9h 2c"), L("5s 6d 7c Kh")))
		kit.expectFalse(Odds._drawing(L("Ah 2c"), L("5s 6d 7c 8h")))
		kit.expectTrue(Odds._drawing(L("Ah 2c"), L("3s 4d Kc 9h")))
	end)
	kit.it("the table shrinks a rare key toward the bet's mean and shifts by the lead", function()
		local spots = {}
		for _ = 1, 1000 do
			table.insert(spots, { 1, 10, 4, 0.5 })
		end
		table.insert(spots, { 1, 20, 4, 1 })
		for _ = 1, 200 do
			table.insert(spots, { 2, 10, 7, 1 })
			table.insert(spots, { 2, 10, 1, 0 })
		end
		local t = Odds.build(spots)
		local rare = Odds.estimate(t, 1, 20, 4)
		kit.expectTrue(rare > 0.5 and rare < 0.55, "one win shouldn't read as a sure thing")
		kit.expectNear(Odds.estimate(t, 1, 10, 4), 0.5, 0.01)
		kit.expectTrue(Odds.estimate(t, 2, 10, 7) > 0.9)
		kit.expectTrue(Odds.estimate(t, 2, 10, 1) < 0.1)
		kit.expectNear(Odds.estimate(t, 1, 99, 4), t.mean[1], 1e-9)
	end)
end)
