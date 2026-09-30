--!strict
-- Dial.spec.luau — the standard dial (GAME_SPEC §3) and the stat compass (§4 *Stances*).

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Dial = require("../sim/Dial")

local spec = Config.defaults().spec

kit.describe("Dial: §3 Rows by offset", function()
	-- Offset = your aim − theirs. {your strike, theirs}, straight from the §3 table.
	local ROWS = {
		[0] = { "crit", "crit" },
		{ "crit", "normal" },
		{ "crit", "normal" },
		{ "crit", "normal" },
		{ "crit", "block" },
		{ "normal", "block" },
		{ "normal", "block" },
		{ "normal", "normal" },
		{ "block", "block" },
		{ "normal", "normal" },
		{ "block", "normal" },
		{ "block", "normal" },
		{ "block", "crit" },
		{ "normal", "crit" },
		{ "normal", "crit" },
		{ "normal", "crit" },
	}
	for offset = 0, 15 do
		kit.it("offset " .. offset, function()
			local mine, theirs = Dial.row(offset, spec)
			kit.expectEqual(mine, ROWS[offset][1], "your strike")
			kit.expectEqual(theirs, ROWS[offset][2], "theirs")
		end)
	end

	kit.it("row shares match the §3 outcome table (in 16ths)", function()
		local counts = {}
		for offset = 0, 15 do
			local a, b = Dial.row(offset, spec)
			local key = table.concat({ string.sub(a, 1, 1), string.sub(b, 1, 1) })
			local sorted = if key == "nc" or key == "bn" or key == "bc" then string.reverse(key) else key
			counts[sorted] = (counts[sorted] or 0) + 1
		end
		kit.expectEqual(counts.cn, 6, "CN")
		kit.expectEqual(counts.nb, 4, "NB")
		kit.expectEqual(counts.cb, 2, "CB")
		kit.expectEqual(counts.nn, 2, "NN")
		kit.expectEqual(counts.cc, 1, "CC")
		kit.expectEqual(counts.bb, 1, "BB")
	end)

	kit.it("tier looks the striker's aim up on the defender's sectors", function()
		kit.expectEqual((Dial.tier(3, 0, spec)), "crit")
		kit.expectEqual((Dial.tier(0, 8, spec)), "block")
		kit.expectEqual((Dial.tier(9, 0, spec)), "normal")
	end)

	kit.it("Neutral strikes Weak, and a Neutral defender takes every hit as Normal", function()
		kit.expectEqual((Dial.tier(nil, 0, spec)), "weak")
		kit.expectEqual((Dial.tier(0, nil, spec)), "normal")
		kit.expectEqual((Dial.tier(8, nil, spec)), "normal")
	end)
end)

kit.describe("Dial: the stat compass", function()
	local s = 0.75
	kit.it("cardinals lean into one stat: Up ♣, Out ♠, Down ♥, In ♦", function()
		kit.expectDeepEqual(Dial.lean(0, s), { 1, 0, 0, 0 })
		kit.expectDeepEqual(Dial.lean(4, s), { 0, 1, 0, 0 })
		kit.expectDeepEqual(Dial.lean(8, s), { 0, 0, 1, 0 })
		kit.expectDeepEqual(Dial.lean(12, s), { 0, 0, 0, 1 })
	end)
	kit.it("diagonals share evenly: Up-Out all offense, Down-In all defense, In-Up ♣ ♦", function()
		kit.expectDeepEqual(Dial.lean(2, s), { 0.5, 0.5, 0, 0 })
		kit.expectDeepEqual(Dial.lean(10, s), { 0, 0, 0.5, 0.5 })
		kit.expectDeepEqual(Dial.lean(14, s), { 0.5, 0, 0, 0.5 })
		kit.expectDeepEqual(Dial.lean(6, s), { 0, 0.5, 0.5, 0 })
	end)
	kit.it("half steps share mostly toward the nearer cardinal", function()
		kit.expectDeepEqual(Dial.lean(1, s), { 0.75, 0.25, 0, 0 })
		kit.expectDeepEqual(Dial.lean(3, s), { 0.25, 0.75, 0, 0 })
		kit.expectDeepEqual(Dial.lean(15, s), { 0.75, 0, 0, 0.25 })
	end)
	kit.it("the total lean is the same at every aim; Neutral leans into nothing", function()
		for a = 0, 15 do
			local w = Dial.lean(a, s)
			kit.expectNear(w[1] + w[2] + w[3] + w[4], 1, 1e-12, "aim " .. a)
		end
		kit.expectDeepEqual(Dial.lean(nil, s), { 0, 0, 0, 0 })
	end)
	kit.it("a flush's home factor: full at home, half on the diagonals beside it, 0 opposite", function()
		kit.expectEqual(Dial.homeFactor(4, 2, s), 1) -- ♠ home Out
		kit.expectEqual(Dial.homeFactor(2, 2, s), 0.5)
		kit.expectEqual(Dial.homeFactor(6, 2, s), 0.5)
		kit.expectEqual(Dial.homeFactor(12, 2, s), 0)
	end)
end)
