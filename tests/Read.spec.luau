--!strict
-- Read.spec.luau — the reading model (sim/Read.luau; 0089–0093): its fast per-pair evaluation
-- matches the sim's own, its updates keep the opponent's true hand, and it is off by default.

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Cards = require("../sim/Cards")
local Tricks = require("../sim/Tricks")
local Odds = require("../sim/Odds")
local Hand = require("../sim/Hand")
local Read = require("../sim/Read")

local L = Cards.list

local function rngFrom(seed: number): () -> number
	local st = seed
	return function(): number
		st = (st * 16807) % 2147483647
		return (st - 1) / 2147483646
	end
end

kit.describe("Read", function()
	kit.it("per-pair evaluation matches Cards.evaluate, Tricks.status and Odds' draw flag", function()
		local rng = rngFrom(11)
		for _ = 1, 3000 do
			local d = Cards.shuffled(rng)
			for _, n in { 3, 4, 5 } do
				local board = { d[3], d[4], d[5], d[6], d[7] }
				local known = table.move(board, 1, n, 1, {})
				local cat, top, fs, draw = Read._evaluate(d[1], d[2], board, n)
				local all = { d[1], d[2], table.unpack(known) }
				local e = Cards.evaluate(all)
				kit.expectEqual(cat, e.category)
				kit.expectEqual(top, e.straightTop or 0)
				kit.expectEqual(fs, e.flushSuit or 0)
				kit.expectEqual(draw, Odds._drawing({ d[1], d[2] }, known))
			end
		end
	end)
	kit.it("per-pair points match Cards.points, made cards and board weight included", function()
		local cfg = Config.defaults()
		local rng = rngFrom(12)
		for _ = 1, 3000 do
			local d = Cards.shuffled(rng)
			for _, n in { 0, 3, 4, 5 } do
				local board = { d[3], d[4], d[5], d[6], d[7] }
				local pts = Cards.points({ d[1], d[2] }, table.move(board, 1, n, 1, {}), cfg.spec)
				local q1, q2, q3, q4 = Read._points(d[1], d[2], board, n, cfg.spec)
				kit.expectNear(q1, pts[1])
				kit.expectNear(q2, pts[2])
				kit.expectNear(q3, pts[3])
				kit.expectNear(q4, pts[4])
			end
		end
		-- A rigged case: trips with a fourth of the rank on the board multiply only three (hole first).
		local board = L("9c 9d 2s 5h 7c")
		local pts = Cards.points(L("9s 9h"), board, cfg.spec)
		local q1, q2, q3, q4 = Read._points(Cards.parse("9s"), Cards.parse("9h"), board, 5, cfg.spec)
		kit.expectNear(q1 + q2 + q3 + q4, pts[1] + pts[2] + pts[3] + pts[4])
	end)
	kit.it("a street's ownership matches Tricks.status, a board trick included", function()
		local cfg = Config.defaults()
		local board = L("5c 6c 7c 8d 9h") -- the board's own straight
		local ctx = Read.newHand(cfg, board)
		local st = Read.street(ctx, 5)
		for k = 1, Read.NP do
			if st.live[k] then
				local a, b = Read.pairCards(k)
				kit.expectEqual(st.own[k], Tricks.status({ a, b }, board).ownRung)
			end
		end
	end)
	kit.it("color at full skill keeps only the pairs with the shown colors; at skill 0 it moves nothing", function()
		local full = Read.newBelief(L("2c 3c"), 1)
		Read.color(full, 2)
		local none = Read.newBelief(L("2c 3c"), 0)
		Read.color(none, 2)
		for k = 1, Read.NP do
			local a, b = Read.pairCards(k)
			local red = Read.redCount({ a, b })
			if full.w[k] > 0 then
				kit.expectEqual(red, 2)
			end
			local mine = a == Cards.parse("2c") or a == Cards.parse("3c") or b == Cards.parse("2c") or b == Cards.parse("3c")
			kit.expectEqual(none.w[k] > 0, not mine)
		end
		-- Two red cards: C(26, 2) = 325 pairs.
		local live = 0
		for k = 1, Read.NP do
			if full.w[k] > 0 then
				live += 1
			end
		end
		kit.expectEqual(live, 325)
	end)
	kit.it("an honest all-club stance at Up raises the weight of club-heavy pairs", function()
		local cfg = Config.defaults()
		local ctx = Read.newHand(cfg, L("2d 3h 4s 9d Th"))
		local b = Read.newBelief(L("2s 3s"), 1)
		Read.stance(b, ctx, { pass = 1, a0 = 0, early = false, a1 = 0, prevN = 0, newN = 0, spent = false }, cfg.riders.average)
		local clubs = b.w[Read.pairIndex(Cards.parse("Ac"), Cards.parse("Kc"))]
		local hearts = b.w[Read.pairIndex(Cards.parse("Ah"), Cards.parse("Kh"))]
		kit.expectTrue(clubs > 5 * hearts)
		kit.expectTrue(hearts > 0) -- a dishonest rider picks any aim
	end)
	kit.it("readers at full skill never rule out the opponent's true hand (the script replays exactly)", function()
		local cfg = Config.defaults()
		cfg.reading.aim = "belief"
		local p = table.clone(cfg.riders.average)
		p.readSkill = 1
		local rng = rngFrom(21)
		local info = {}
		for i = 1, 300 do
			Hand.play(cfg, rng, p, p, (i % 2) + 1, { info = info })
		end
		kit.expectEqual(info.skipped or 0, 0)
		kit.expectTrue((info["truth.pass1"] or 0) > 0)
		-- Hit size teaches more than nothing: the true pair's share grows pass by pass.
		local t1 = info["truth.pass1"] / info["obs.pass1"]
		local t3 = info["truth.pass3"] / info["obs.pass3"]
		kit.expectTrue(t3 > t1)
	end)
	kit.it("off by default: a hand plays the same with or without the reading model's options", function()
		local cfg = Config.defaults()
		kit.expectEqual(cfg.reading.aim, "off")
		kit.expectEqual(cfg.reading.betting, "off")
		local a, b = rngFrom(31), rngFrom(31)
		for i = 1, 300 do
			local x = Hand.play(cfg, a, cfg.riders.average, cfg.riders.average, (i % 2) + 1)
			local info = {}
			local y = Hand.play(cfg, b, cfg.riders.average, cfg.riders.average, (i % 2) + 1, { trace = true, info = info })
			kit.expectEqual(x.winner, y.winner)
			kit.expectEqual(x.pass, y.pass)
			kit.expectEqual(x.posture[1], y.posture[1])
			kit.expectEqual(next(info), nil)
		end
	end)
	kit.it("a systematic sample draws only pairs the belief holds, and the same ones every time", function()
		local b = Read.newBelief(L("2c 3c"), 1)
		Read.color(b, 0)
		local s1 = Read.sample(b, 16)
		local s2 = Read.sample(b, 16)
		kit.expectEqual(#s1, 16)
		for i, k in s1 do
			kit.expectTrue(b.w[k] > 0)
			kit.expectEqual(k, s2[i])
		end
	end)
	kit.it("paired odds lean on the two keys' own odds until a pairing has hands of its own", function()
		local spots = {}
		for _ = 1, 100 do
			table.insert(spots, { 1, 10, 4, 1, 20 })
			table.insert(spots, { 1, 20, 4, 0, 10 })
		end
		table.insert(spots, { 1, 30, 4, 0.5, 40 })
		local t = Odds.build(spots)
		kit.expectTrue(Odds.paired(t, 1, 10, 20) > 0.9)
		-- No hands of 10 against 30: the prior sets 10's odds against 30's.
		local p = Odds.paired(t, 1, 10, 30)
		kit.expectTrue(p > 0.5 and p < 1)
		-- A belief all on key 20 gives the paired odds, before any lead shift.
		local e = Odds.estimateBelief(t, 1, 10, { [20] = 1 }, 4)
		kit.expectTrue(e > 0.85)
	end)
end)
