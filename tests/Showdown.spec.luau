--!strict
-- Showdown.spec.luau — the showdown prototypes behind switches.showdown (docs/sim/SHOWDOWN.md).
-- The default reading is GAME_SPEC's (0050); the rest are proposals and must stay off by default.

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

local function play(cfg: any, seed: number, n: number): { Hand.Record }
	local rng = rngFrom(seed)
	local out = {}
	for i = 1, n do
		table.insert(out, Hand.play(cfg, rng, cfg.riders.average, cfg.riders.average, (i % 2) + 1))
	end
	return out
end

kit.describe("Showdown prototypes (switches.showdown)", function()
	kit.it("the default reading is 0050: Posture + 20 per step decides, kickers break an exact tie", function()
		local cfg = Config.defaults()
		kit.expectEqual(cfg.switches.showdown, "bonus")
		for _, r in play(cfg, 11, 400) do
			if r.finish == "showdown" then
				kit.expectEqual(r.pass, 4)
				local s1 = r.posture[1] + cfg.spec.showdownBonus * r.category[1]
				local s2 = r.posture[2] + cfg.spec.showdownBonus * r.category[2]
				if s1 ~= s2 then
					kit.expectEqual(r.winner, if s1 > s2 then 1 else 2)
				elseif r.value[1] ~= r.value[2] then
					kit.expectEqual(r.winner, if r.value[1] > r.value[2] then 1 else 2)
				else
					kit.expectEqual(r.winner, 0)
				end
				-- afterFinal is the Posture the rule saw.
				kit.expectDeepEqual(r.afterFinal, r.posture)
			end
		end
	end)
	kit.it("every reading runs, and only the charge rides a fifth pass", function()
		for _, mode in { "bonus", "mult", "riverHit", "charge" } do
			local cfg = Config.defaults()
			Config.set(cfg, "switches.showdown", mode)
			local five = 0
			for _, r in play(cfg, 3, 300) do
				kit.expectTrue(r.winner == 0 or r.winner == 1 or r.winner == 2)
				if r.pass == 5 then
					five += 1
				end
			end
			if mode == "charge" then
				kit.expectTrue(five > 0, "the charge never rode a fifth pass")
			else
				kit.expectEqual(five, 0, mode .. " rode a fifth pass")
			end
		end
	end)
	kit.it("mult: Posture × (1 + mult × steps) decides", function()
		local cfg = Config.defaults()
		Config.set(cfg, "switches.showdown", "mult")
		for _, r in play(cfg, 5, 400) do
			if r.finish == "showdown" then
				local s1 = r.posture[1] * (1 + cfg.proto.mult * r.category[1])
				local s2 = r.posture[2] * (1 + cfg.proto.mult * r.category[2])
				if s1 ~= s2 then
					kit.expectEqual(r.winner, if s1 > s2 then 1 else 2)
				end
			end
		end
	end)
	kit.it("riverHit: the hand's blows land on Pass 4, then Posture alone decides", function()
		local cfg = Config.defaults()
		Config.set(cfg, "switches.showdown", "riverHit")
		local blown = 0
		for _, r in play(cfg, 8, 600) do
			if r.finish == "showdown" then
				-- afterFinal is Posture before the blows; posture is after. A blow only ever lowers it.
				local af = r.afterFinal
				if af then
					kit.expectTrue(r.posture[1] <= af[1] + 1e-9 and r.posture[2] <= af[2] + 1e-9)
					if r.posture[1] < af[1] or r.posture[2] < af[2] then
						blown += 1
					end
				end
				if r.posture[1] ~= r.posture[2] then
					kit.expectEqual(r.winner, if r.posture[1] > r.posture[2] then 1 else 2)
				end
			end
		end
		kit.expectTrue(blown > 0, "no hand blow ever landed")
	end)
	kit.it("riverHit: with no blow per step it is Posture alone, so the Posture leader always wins", function()
		local cfg = Config.defaults()
		Config.set(cfg, "switches.showdown", "riverHit")
		Config.set(cfg, "proto.riverPerStep", "0")
		for _, r in play(cfg, 8, 300) do
			if r.finish == "showdown" and r.posture[1] ~= r.posture[2] then
				kit.expectEqual(r.winner, if r.posture[1] > r.posture[2] then 1 else 2)
			end
		end
	end)
	kit.it("charge: the bonus lands before the charge, a fifth contact is ridden, and the lower rider falls", function()
		local cfg = Config.defaults()
		Config.set(cfg, "switches.showdown", "charge")
		local charged, koInCharge = 0, 0
		for _, r in play(cfg, 9, 600) do
			if r.pass == 5 then
				charged += 1
				kit.expectTrue(r.chargeStanding ~= nil)
				if r.finish == "unhorse" then
					koInCharge += 1
				elseif r.finish == "showdown" and r.posture[1] ~= r.posture[2] then
					kit.expectEqual(r.winner, if r.posture[1] > r.posture[2] then 1 else 2)
				end
			else
				kit.expectNil(r.chargeStanding)
			end
		end
		kit.expectTrue(charged > 0 and koInCharge > 0)
	end)
	kit.it("charge with no bonus: nothing is added before the charge", function()
		local cfg = Config.defaults()
		Config.set(cfg, "switches.showdown", "charge")
		Config.set(cfg, "proto.chargeBonus", "none")
		for _, r in play(cfg, 9, 300) do
			-- afterFinal is nil when Twin Favor or Unbroken kept a rider up through the exchange.
			if r.pass == 5 and r.afterFinal then
				local af = r.afterFinal :: { number }
				local ahead = if af[1] > af[2] then 1 elseif af[2] > af[1] then 2 else 0
				kit.expectEqual(r.chargeStanding, ahead)
			end
		end
	end)
end)
