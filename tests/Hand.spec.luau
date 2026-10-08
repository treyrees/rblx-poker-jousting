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
	kit.it("Pass 1 rides on hole cards: no trick can fire before the flop on Pass 2 (0049)", function()
		local c = Config.defaults()
		local rng = rngFrom(5)
		for _ = 1, 2000 do
			local r = Hand.play(c, rng, c.riders.average, c.riders.average, 1)
			for _, t in r.tricks do
				kit.expectTrue(t.pass >= 2, "a trick fired on Pass 1")
			end
		end
	end)
	kit.it("the betting rider: the cap is 13 units, and a Yield only ever answers a raise (0081)", function()
		local c = Config.defaults()
		Config.set(c, "switches.betting", "bands")
		Config.set(c, "sim.oddsHands", "2000")
		local rng = rngFrom(11)
		local p = table.clone(c.riders.average)
		p.raiseAt, p.yieldAt = { 0, 0, 0, 0 }, { 0, 0, 0, 0 } -- raise every chance, never Yield
		local raiser = table.clone(c.riders.average)
		raiser.raiseAt, raiser.yieldAt = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }
		local folder = table.clone(c.riders.average)
		folder.raiseAt, folder.yieldAt = { 2, 2, 2, 2 }, { 2, 2, 2, 2 } -- never raise, Yield to any raise
		for i = 1, 300 do
			local r = Hand.play(c, rng, p, p, (i % 2) + 1)
			kit.expectTrue(r.contributed[1] <= 13 and r.contributed[2] <= 13)
			kit.expectEqual(r.contributed[1], r.contributed[2])
			if r.finish == "showdown" then
				kit.expectEqual(r.contributed[1], 13, "every raise and re-raise called")
			end
			local y = Hand.play(c, rng, raiser, folder, (i % 2) + 1)
			kit.expectEqual(y.finish, "yield")
			kit.expectEqual(y.winner, 1)
			kit.expectTrue(y.contributed[2] < y.contributed[1], "the Yield faced a raise")
			kit.expectEqual(y.units[1], 1, "the folder loses the Ante")
		end
	end)
	kit.it("the betting rider's odds rank AA above 72o before the flop", function()
		local c = Config.defaults()
		Config.set(c, "sim.oddsHands", "4000")
		local Odds = require("../sim/Odds")
		local Cards = require("../sim/Cards")
		local t = Hand.calibrate(c)
		local aa = Odds.estimate(t, 1, Cards.class(Cards.list("Ac Ad")), 4)
		local trash = Odds.estimate(t, 1, Cards.class(Cards.list("7c 2d")), 4)
		kit.expectTrue(aa > trash + 0.15, string.format("AA %.2f vs 72o %.2f", aa, trash))
	end)
	kit.it("recording spots doesn't change the hand", function()
		local a, b = rngFrom(21), rngFrom(21)
		for _ = 1, 100 do
			local x = Hand.play(cfg, a, cfg.riders.average, cfg.riders.average, 1)
			local y = Hand.play(cfg, b, cfg.riders.average, cfg.riders.average, 1, { spots = true })
			kit.expectEqual(x.winner, y.winner)
			kit.expectEqual(x.units[1], y.units[1])
			kit.expectTrue(#(y.spots :: any) >= 2)
		end
	end)
	kit.it("every switch reading runs", function()
		for key, values in {
			slowmo = { "wall", "game", "excluded" },
			statBasis = { "value", "points" },
			flushHit = { "F1", "F2" },
			meterThreshold = { "reachable", "strict" },
			betting = { "script", "bands" },
		} do
			for _, v in values do
				local c = Config.defaults()
				Config.set(c, "sim.oddsHands", "500")
				Config.set(c, "switches." .. key, v)
				local rng = rngFrom(3)
				for _ = 1, 50 do
					Hand.play(c, rng, c.riders.average, c.riders.average, 1)
				end
			end
		end
	end)
end)
