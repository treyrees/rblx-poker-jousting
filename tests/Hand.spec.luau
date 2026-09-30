--!strict
-- Hand.spec.luau — a whole hand runs end to end, and a seed reproduces it.

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Hand = require("../sim/Hand")

local function rngFrom(seed: number): () -> number
	local st = seed
	return function(): number
		st = (st * 16807) % 2147483647
		return (st - 1) / 2147483646
	end
end

kit.describe("Hand", function()
	local cfg = Config.defaults()
	kit.it("500 hands finish with a winner or a split and a valid finish", function()
		local rng = rngFrom(7)
		for i = 1, 500 do
			local r = Hand.play(cfg, rng, cfg.riders.average, cfg.riders.average, (i % 2) + 1)
			kit.expectTrue(r.winner == 0 or r.winner == 1 or r.winner == 2)
			kit.expectTrue(r.finish == "unhorse" or r.finish == "showdown" or r.finish == "yield")
			kit.expectTrue(r.pass >= 1 and r.pass <= 4)
			kit.expectNear(r.units[1] + r.units[2], 0)
		end
	end)
	kit.it("the same seed plays the same hands", function()
		local a, b = rngFrom(99), rngFrom(99)
		for _ = 1, 200 do
			local x = Hand.play(cfg, a, cfg.riders.skilled, cfg.riders.novice, 1)
			local y = Hand.play(cfg, b, cfg.riders.skilled, cfg.riders.novice, 1)
			kit.expectEqual(x.winner, y.winner)
			kit.expectEqual(x.pass, y.pass)
		end
	end)
	kit.it("both pass orders play whole hands (proposed.passOrder)", function()
		for _, order in { "spec", "riverLast" } do
			local c = Config.defaults()
			Config.set(c, "proposed.passOrder", order)
			local rng = rngFrom(11)
			for i = 1, 300 do
				local r = Hand.play(c, rng, c.riders.average, c.riders.average, (i % 2) + 1)
				kit.expectTrue(r.winner == 0 or r.winner == 1 or r.winner == 2)
			end
		end
	end)
	kit.it("river last: no knockoff on Pass 1 can come from a trick (no community cards yet)", function()
		local c = Config.defaults()
		Config.set(c, "proposed.passOrder", "riverLast")
		local rng = rngFrom(5)
		for _ = 1, 2000 do
			local r = Hand.play(c, rng, c.riders.average, c.riders.average, 1)
			for _, t in r.tricks do
				kit.expectTrue(t.pass >= 2, "a trick fired on Pass 1")
			end
		end
	end)
	kit.it("every switch reading runs", function()
		for key, values in {
			showdown = { "category", "points", "lexicographic" },
			slowmo = { "wall", "game", "excluded" },
			statBasis = { "value", "points" },
			flushHit = { "F1", "F2" },
			meterThreshold = { "reachable", "strict" },
			twinFavorVsTrick = { "negates", "trickOverrides" },
			aaEdge = { "one", "both", "direction" },
		} do
			for _, v in values do
				local c = Config.defaults()
				Config.set(c, "switches." .. key, v)
				local rng = rngFrom(3)
				for _ = 1, 50 do
					Hand.play(c, rng, c.riders.average, c.riders.average, 1)
				end
			end
		end
	end)
end)
