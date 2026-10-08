--!strict
-- Yard.spec.luau — the yard's equilibrium (§2 *The yard*, 0078–0080) on a made-up tally where each
-- class has a strength and the stronger class wins by the gap.

local kit = require("./lib/testkit")
local Yard = require("../sim/Yard")

local C = 169

-- Class i has strength s_i = (i − 85) / 169: a hand wins (s_i − s_j)/2 units and 1/2 + (s_i − s_j)/2
-- of its matches against class j, met as often as the deal makes them.
local function synthetic(): Yard.Tally
	local t = Yard.newTally()
	for i = 1, C do
		for j = 1, C do
			local idx = (i - 1) * C + j
			local n = Yard.FREQ[i] * Yard.FREQ[j] * 1e6
			local d = (i - j) / C
			t.n[idx] = n
			t.units[idx] = n * d / 2
			t.wins[idx] = n * (0.5 + d / 2)
		end
	end
	return t
end

kit.describe("Yard", function()
	local t = synthetic()
	kit.it("everyone keeps above the price that makes the worst hand break even", function()
		local s = Yard.atShare(t, "sink", 1)
		local worst = 1
		kit.expectNear(s.share, 1)
		-- The worst hand loses −EV a match; at k = 1 a sink fold is worth −c, so the price is −EV.
		kit.expectNear(s.price, -s.ev[worst], 1e-6)
	end)
	kit.it("at 75% the strongest hands are kept and the marginal one is indifferent", function()
		for _, dest in { "sink", "purse", "carry" } do
			local s = Yard.atShare(t, dest, 0.75)
			kit.expectNear(s.share, 0.75)
			kit.expectNear(s.value[s.margin], s.fold, 1e-6, dest)
			local k = 0
			for i = 1, C do
				k += Yard.FREQ[i] * s.keep[i]
				if s.keep[i] > 0 and i < C then
					kit.expectTrue(s.keep[i + 1] >= 1 - 1e-9, dest .. ": the kept set is the top")
				end
			end
			kit.expectNear(k, 0.75, 1e-9)
		end
	end)
	kit.it("a sink fold costs c/k; purse money stays with the players, so a purse fold costs c", function()
		local sink = Yard.atShare(t, "sink", 0.75)
		kit.expectNear(sink.fold, -sink.price / 0.75, 1e-6)
		local purse = Yard.atShare(t, "purse", 0.75)
		kit.expectNear(purse.fold, -purse.price, 1e-6)
		kit.expectNear(purse.extra, 2 * purse.price * 0.25 / 0.75, 1e-9)
	end)
	kit.it("carry needs about twice the price: a rider wins their own carry back about half the time", function()
		local purse = Yard.atShare(t, "purse", 0.75)
		local carry = Yard.atShare(t, "carry", 0.75)
		kit.expectTrue(carry.price > 1.6 * purse.price and carry.price < 2.4 * purse.price,
			string.format("carry %.3f vs purse %.3f", carry.price, purse.price))
	end)
	kit.it("a higher price keeps more hands, and the price for a share holds that share", function()
		local cache = {}
		local lo = Yard.atPrice(t, "carry", 0.02, cache)
		local hi = Yard.atPrice(t, "carry", 0.2, cache)
		kit.expectTrue(lo ~= nil and hi ~= nil and (hi :: any).share > (lo :: any).share)
		local s = Yard.atShare(t, "carry", 0.75)
		local back = Yard.atPrice(t, "carry", s.price + 1e-6, cache)
		kit.expectNear((back :: any).share, 0.75, 1e-9)
	end)
	kit.it("metrics: the kept make-up sums to 1", function()
		local m = Yard.metrics(t, Yard.atShare(t, "carry", 0.75))
		kit.expectNear(m.pairs + m.suited + m.offsuit, 1, 1e-9)
		kit.expectTrue(m.underdog < 0.5)
	end)
end)
