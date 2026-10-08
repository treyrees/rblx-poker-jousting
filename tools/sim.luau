--!strict
-- sim.luau — the headless one-hand sim (GAME_SPEC §11 *Sim plan*). Run from the repo root:
--
--   lune run tools/sim.luau                          -- baseline report, 100k hands per run
--   lune run tools/sim.luau --report sweeps          -- one row per sweep point (docs/sim/RESULTS.md)
--   lune run tools/sim.luau --report gap             -- numeric hit gap by category (§4)
--   lune run tools/sim.luau --report showdown        -- how the forced knockdown is decided (0050)
--   lune run tools/sim.luau --report proto           -- the showdown prototypes (docs/sim/SHOWDOWN.md)
--   lune run tools/sim.luau --report bets            -- the betting rider's bands: pots and losses
--   lune run tools/sim.luau --report yard            -- the yard: prefold price, kept share, kept range
--   lune run tools/sim.luau --set sim.lean=2 --set spec.showdownBonus=10
--   lune run tools/sim.luau --smoke                  -- 5k hands: checks it runs; rates not citable
--
-- Options: --hands N, --seed S, --shard i/n (sweeps, proto, bets and yard: run every n-th row, for
-- parallel runs), --only text (the same reports: only rows whose label contains it), --set path=value (repeatable; paths as in sim/Config.luau),
-- --p1 / --p2 rider profile for the baseline report (default average vs average).
-- Unknown arguments are an error, so a typo never prints a confident report for the wrong run.
--
-- Mechanism borrowed from rblx-joust-tourney (main, tools/sim.luau): the seeded LCG, strict
-- argument parsing and the smoke mode. The metrics and the game are this repo's.

local process = require("@lune/process")
local Config = require("../sim/Config")
local Hand = require("../sim/Hand")
local Cards = require("../sim/Cards")
local Yard = require("../sim/Yard")

-- ── args ───────────────────────────────────────────────────────────────────────────────────────
local hands, seed, report = 100000, 20260930, "baseline"
local sets: { { string } } = {}
local p1name, p2name = "average", "average"
local shard, shards = 1, 1
local only: string? = nil
do
	local args = process.args
	local i = 1
	while i <= #args do
		local a = args[i]
		if a == "--hands" then
			hands = assert(tonumber(args[i + 1]), "--hands wants a number")
			i += 2
		elseif a == "--seed" then
			seed = assert(tonumber(args[i + 1]), "--seed wants a number")
			i += 2
		elseif a == "--smoke" then
			hands = 5000
			i += 1
		elseif a == "--report" then
			report = args[i + 1]
			i += 2
		elseif a == "--p1" then
			p1name = args[i + 1]
			i += 2
		elseif a == "--p2" then
			p2name = args[i + 1]
			i += 2
		elseif a == "--shard" then
			local i1, n1 = string.match(args[i + 1] or "", "^(%d+)/(%d+)$")
			assert(i1 and n1, "--shard wants i/n")
			shard, shards = tonumber(i1) :: number, tonumber(n1) :: number
			i += 2
		elseif a == "--only" then
			only = args[i + 1]
			i += 2
		elseif a == "--set" then
			local kv = args[i + 1] or ""
			local k, v = string.match(kv, "^([^=]+)=(.+)$")
			assert(k and v, "--set wants path=value, got " .. kv)
			table.insert(sets, { k :: string, v :: string })
			i += 2
		else
			error(string.format("sim: unknown argument %q (see the usage at the top of tools/sim.luau)", a))
		end
	end
end

local function makeRng(s: number): () -> number
	local st = s % 2147483647
	if st <= 0 then
		st += 2147483646
	end
	return function(): number
		st = (st * 16807) % 2147483647
		return (st - 1) / 2147483646
	end
end

local function baseConfig(): any
	local cfg = Config.defaults()
	for _, kv in sets do
		Config.set(cfg, kv[1], kv[2])
	end
	return cfg
end

-- ── metrics ────────────────────────────────────────────────────────────────────────────────────

type Tally = { [string]: number }

local function inc(t: Tally, k: string, by: number?)
	t[k] = (t[k] or 0) + (by or 1)
end

local function pct(n: number?, d: number?): string
	if not d or d == 0 then
		return "  n/a"
	end
	return string.format("%5.1f%%", 100 * (n or 0) / d)
end

-- The showdown standing a rider would have from a Posture and a river category, under the
-- showdown reading in play (switches.showdown). Used to project the result at the river reveal:
-- "cards up at the river" (SHOWDOWN.md) shows this standing during Pass 4.
local function standing(cfg: any, posture: number, category: number): number
	local mode = cfg.switches.showdown
	local proto = cfg.proto
	if mode == "bonus" or (mode == "riverHit" and proto.riverKnockdown == "bonus") or (mode == "charge" and proto.chargeBonus == "posture") then
		return posture + cfg.spec.showdownBonus * category
	elseif mode == "mult" then
		return posture * (1 + proto.mult * category)
	end
	return posture
end

-- Plays `n` hands of p1 vs p2 and tallies every §11 metric. Seats alternate the button.
-- `yard`, if given, also tallies each hand by starting-hand class pair (--report yard).
local function run(cfg: any, prof1: any, prof2: any, n: number, s: number, yard: Yard.Tally?): Tally
	local rng = makeRng(s)
	local t: Tally = {}
	for i = 1, n do
		local r = Hand.play(cfg, rng, prof1, prof2, (i % 2) + 1)
		inc(t, "hands")
		inc(t, "finish." .. r.finish)
		-- Betting: what the loser lost, and where a Yield came.
		local loss = if r.winner ~= 0 then r.contributed[3 - r.winner] else 0
		if r.winner ~= 0 then
			inc(t, "loss.n")
			inc(t, "loss.sum", loss)
			inc(t, "loss." .. (if loss <= 1 then "1" elseif loss <= 3 then "3" elseif loss <= 7 then "7" else "13"))
		end
		if r.finish == "yield" then
			inc(t, "yield.bet" .. r.pass)
		end
		if r.contributed[1] > cfg.spec.ante or r.contributed[2] > cfg.spec.ante then
			inc(t, "raised")
		end
		inc(t, "passes", r.pass)
		local bf = r.beforeFinal
		if r.finish == "unhorse" then
			inc(t, "ko.pass" .. r.pass)
		end
		-- The joust's verdict after Pass 4's contact vs the hand's result: how often the showdown
		-- rule (bonus, mult, the charge) overturns the rider ahead on Posture.
		local af = r.afterFinal
		if af and af[1] ~= af[2] then
			inc(t, "after.n")
			if r.winner == (if af[1] > af[2] then 1 else 2) then
				inc(t, "after.leaderWins")
			end
		end
		-- Projected at the river: the rider ahead on the showdown standing before Pass 4's contact.
		if bf then
			local s1 = standing(cfg, bf[1], r.category[1])
			local s2 = standing(cfg, bf[2], r.category[2])
			if s1 ~= s2 then
				local band = if math.abs(s1 - s2) < 8 then "close" else "clear" -- 4 hearts, one category step
				inc(t, "proj." .. band)
				if r.winner == (if s1 > s2 then 1 else 2) then
					inc(t, "proj." .. band .. ".held")
				end
			end
		end
		-- The final charge (switches.showdown = charge): how often it changes the standing.
		if r.chargeStanding ~= nil then
			inc(t, "charge.n")
			if r.finish == "unhorse" and r.pass == 5 then
				inc(t, "charge.ko")
			end
			if r.chargeStanding ~= 0 then
				inc(t, "charge.standing")
				if r.winner ~= r.chargeStanding then
					inc(t, "charge.flip")
				end
			end
		end
		inc(t, "win." .. r.winner)
		inc(t, "units1", r.units[1])
		-- The last pass: does the rider ahead going into Pass 4 hold on, and by what lead?
		if bf and bf[1] ~= bf[2] then
			local lead = math.abs(bf[1] - bf[2])
			local band = if lead < 8 then "close" else "clear"
			inc(t, "final." .. band)
			if r.winner == (if bf[1] > bf[2] then 1 else 2) then
				inc(t, "final." .. band .. ".held")
			end
		end
		inc(t, "reads", r.reads)
		inc(t, "switches", r.switches)
		-- Showdown: how often the knockdown goes to the rider ahead on Posture, and to the better hand.
		if r.finish == "showdown" then
			local af2 = r.afterFinal or r.posture
			local p1, p2 = af2[1], af2[2]
			-- How close the riders are when the knockdown is forced (--report showdown).
			inc(t, "sd.postureSum", p1 + p2)
			inc(t, "sd.lowerPosture", math.min(p1, p2))
			local pg = math.abs(p1 - p2)
			inc(t, "sd.pgap." .. (if pg < 4 then "0" elseif pg < 8 then "4" elseif pg < 16 then "8" else "16"))
			inc(t, "sd.cgap." .. math.min(3, math.abs(r.category[1] - r.category[2])))
			if p1 ~= p2 and r.category[1] ~= r.category[2] then
				local leader = if p1 > p2 then 1 else 2
				if (r.category[1] > r.category[2]) ~= (leader == 1) then
					inc(t, "sd.leaderWorse")
					if r.winner ~= leader then
						inc(t, "sd.leaderWorse.cardsWin")
					end
				end
			end
			if p1 ~= p2 then
				inc(t, "sd.postureDiff")
				if r.winner == (if p1 > p2 then 1 else 2) then
					inc(t, "sd.postureLeaderWins")
				end
			end
			if r.value[1] ~= r.value[2] then
				inc(t, "sd.handDiff")
				if r.winner == (if r.value[1] > r.value[2] then 1 else 2) then
					inc(t, "sd.betterHandWins")
				end
			end
		end
		-- Numeric hands: no trick fired (unclashed) and both below the ladder at the river.
		local anyTrick = false
		for _, tr in r.tricks do
			if not tr.clashed then
				anyTrick = true
			end
		end
		local numeric = not anyTrick and r.riverRung[1] == 0 and r.riverRung[2] == 0
		if numeric then
			inc(t, "numeric")
			local c1, c2 = r.category[1], r.category[2]
			local gap = math.abs(c1 - c2)
			if gap > 0 then
				local better = if c1 > c2 then 1 else 2
				inc(t, "gap" .. gap)
				if r.winner == better then
					inc(t, "gap" .. gap .. ".better")
				elseif r.winner == 0 then
					inc(t, "gap" .. gap .. ".split")
				end
				-- Skill flip: rider 1 (the p1 profile) wins holding the worse hand.
				if better == 2 then
					inc(t, "p1worse")
					if r.winner == 1 then
						inc(t, "p1worse.win")
					end
				else
					inc(t, "p1better")
					if r.winner == 1 then
						inc(t, "p1better.win")
					end
				end
			end
			if r.winner == 1 then
				inc(t, "numeric.p1win")
			end
			inc(t, "numeric." .. r.finish)
		end
		if yard then
			Yard.add(yard, Cards.class(r.hole[1]), Cards.class(r.hole[2]), {
				units1 = r.units[1],
				win1 = if r.winner == 1 then 1 elseif r.winner == 0 then 0.5 else 0,
				loss = loss,
				category = r.category,
				numeric = numeric,
			})
		end
		-- Tricks: fired above the opponent, by trick and by whether it was played to design.
		local byPass: { [number]: { any } } = {}
		for _, tr in r.tricks do
			local rel = if tr.oppRung < tr.rung then "above" elseif tr.oppRung == tr.rung then "level" else "below"
			if tr.clashed then
				inc(t, "clash")
			else
				local k = "trick." .. tr.key .. "." .. rel .. "." .. (if tr.designed then "design" else "off")
				inc(t, k)
				if tr.won then
					inc(t, k .. ".won")
				end
				local kh = "how." .. tr.how .. "." .. rel
				inc(t, kh)
				if tr.won then
					inc(t, kh .. ".won")
				end
				byPass[tr.pass] = byPass[tr.pass] or {}
				table.insert(byPass[tr.pass], tr)
			end
		end
		-- Cross-rung: both tricks act on the same pass.
		for _, list in byPass do
			if #list == 2 and list[1].rung ~= list[2].rung then
				local hi = if list[1].rung > list[2].rung then list[1] else list[2]
				inc(t, "cross")
				inc(t, "cross." .. hi.key)
				if hi.won then
					inc(t, "cross.higherWon")
					inc(t, "cross." .. hi.key .. ".won")
				end
			end
		end
		for i2 = 1, 2 do
			if r.heldAbove[i2] then
				inc(t, "held")
				if r.drawnOut[i2] then
					inc(t, "drawnOut")
				end
			end
		end
	end
	return t
end

local TRICKS = { "straight", "flush", "fullHouse", "quads", "straightFlush" }

local function printBaseline(t: Tally, label: string)
	local n = t.hands
	print(string.format("== %s — %d hands", label, n))
	print(string.format("finish     unhorse %s  showdown %s  yield %s   (unhorse : showdown = %.2f)",
		pct(t["finish.unhorse"], n), pct(t["finish.showdown"], n), pct(t["finish.yield"], n),
		(t["finish.unhorse"] or 0) / math.max(1, t["finish.showdown"] or 0)))
	print(string.format("KO by pass P1 %s  P2 %s  P3 %s  P4 %s  P5 %s   passes/hand %.2f",
		pct(t["ko.pass1"], n), pct(t["ko.pass2"], n), pct(t["ko.pass3"], n), pct(t["ko.pass4"], n), pct(t["ko.pass5"], n),
		(t.passes or 0) / n))
	print(string.format("seat 1 wins %s  seat 2 %s  split %s   seat-1 units/hand %+.3f",
		pct(t["win.1"], n), pct(t["win.2"], n), pct(t["win.0"], n), (t.units1 or 0) / n))
	print(string.format("reads      %.2f per hand; %s of them switch late rather than stay on the held aim",
		(t.reads or 0) / n, pct(t.switches, t.reads)))
	print(string.format("showdown   Posture leader wins %s   better poker hand wins %s",
		pct(t["sd.postureLeaderWins"], t["sd.postureDiff"]), pct(t["sd.betterHandWins"], t["sd.handDiff"])))
	print(string.format("after P4   leader on Posture wins %s (n=%d) | projected at the river holds: close %s  clear %s | charge: KO %s, flips the standing %s (n=%d)",
		pct(t["after.leaderWins"], t["after.n"]), t["after.n"] or 0,
		pct(t["proj.close.held"], t["proj.close"]), pct(t["proj.clear.held"], t["proj.clear"]),
		pct(t["charge.ko"], t["charge.n"]), pct(t["charge.flip"], t["charge.standing"]), t["charge.n"] or 0))
	local nn = t.numeric or 0
	print(string.format("numeric hands %s of all; of them unhorse %s", pct(nn, n), pct(t["numeric.unhorse"], nn)))
	for g = 1, 3 do
		local d = t["gap" .. g]
		print(string.format("  category gap %d: better hand wins %s  split %s  (n=%d)",
			g, pct(t["gap" .. g .. ".better"], d), pct(t["gap" .. g .. ".split"], d), d or 0))
	end
	print(string.format("  p1 wins holding the worse category %s (n=%d); holding the better %s",
		pct(t["p1worse.win"], t.p1worse), t.p1worse or 0, pct(t["p1better.win"], t.p1better)))
	print("tricks fired, not clashed (win rate, n):")
	for _, key in TRICKS do
		local line = "  " .. key .. string.rep(" ", 14 - #key)
		for _, rel in { "above", "level", "below" } do
			for _, d in { "design", "off" } do
				local k = "trick." .. key .. "." .. rel .. "." .. d
				if t[k] then
					line ..= string.format(" %s/%s %s n=%d |", rel, d, pct(t[k .. ".won"], t[k]), t[k])
				end
			end
		end
		print(line)
	end
	for _, how in { "unleash", "answer", "autofire" } do
		local line = "  by how: " .. how
		for _, rel in { "above", "level", "below" } do
			local k = "how." .. how .. "." .. rel
			if t[k] then
				line ..= string.format("  %s %s n=%d", rel, pct(t[k .. ".won"], t[k]), t[k])
			end
		end
		print(line)
	end
	print(string.format("cross-rung passes: higher trick wins %s (n=%d); clashes %d",
		pct(t["cross.higherWon"], t.cross), t.cross or 0, t.clash or 0))
	print(string.format("held above, then drawn out: %s (n=%d)", pct(t.drawnOut, t.held), t.held or 0))
end

-- One compact row per configuration: the headline metrics against the targets.
local function aboveRate(t: Tally, design: string): (number, number)
	local won, n = 0, 0
	for _, key in TRICKS do
		local k = "trick." .. key .. ".above." .. design
		won += t[k .. ".won"] or 0
		n += t[k] or 0
	end
	return won, n
end

local ROW_HEAD = "config                                   | unh:sd | KO P1  P2   P3   P4  | gap1  gap2  gap3 | flip  | above/design above/off | cross | drawn"
local function row(label: string, t: Tally, m: Tally)
	local n = t.hands
	local w1, n1 = aboveRate(t, "design")
	local w2, n2 = aboveRate(t, "off")
	print(string.format("%-40s | %5.2f | %4.1f %4.1f %4.1f %4.1f | %s %s %s | %s | %s   %s | %s | %s",
		label,
		(t["finish.unhorse"] or 0) / math.max(1, t["finish.showdown"] or 0),
		100 * (t["ko.pass1"] or 0) / n, 100 * (t["ko.pass2"] or 0) / n,
		100 * (t["ko.pass3"] or 0) / n, 100 * (t["ko.pass4"] or 0) / n,
		pct(t["gap1.better"], t.gap1), pct(t["gap2.better"], t.gap2), pct(t["gap3.better"], t.gap3),
		pct(m["p1worse.win"], m.p1worse),
		pct(w1, n1), pct(w2, n2),
		pct(t["cross.higherWon"], t.cross), pct(t.drawnOut, t.held)))
end

-- ── reports ────────────────────────────────────────────────────────────────────────────────────

local SWEEPS: { { any } } = {
	{ "defaults", {} },
	{ "sim.lean=0", { { "sim.lean", "0" } } },
	{ "sim.lean=0.5", { { "sim.lean", "0.5" } } },
	{ "sim.lean=2", { { "sim.lean", "2" } } },
	{ "spec.boardWeight=0.25 (§11: sim tries lower)", { { "spec.boardWeight", "0.25" } } },
	{ "spec.holdFloor=0.2 (0052: 0.25)", { { "spec.holdFloor", "0.2" } } },
	{ "spec.holdFloor=0.4 (was §11)", { { "spec.holdFloor", "0.4" } } },
	{ "spec.holdFloor=0.6", { { "spec.holdFloor", "0.6" } } },
	{ "sim.armorRate=0.06", { { "sim.armorRate", "0.06" } } },
	{ "sim.armorRate=0.16", { { "sim.armorRate", "0.16" } } },
	{ "sim.battered=0 (0068 off)", { { "sim.battered", "0" } } },
	{ "sim.battered=0.6", { { "sim.battered", "0.6" } } },
	{ "heal off (0070)", { { "sim.healBase", "0" }, { "sim.healPerPoint", "0" } } },
	{ "sim.healPerPoint=0.04", { { "sim.healPerPoint", "0.04" } } },
	{ "sim.heartBuffer=0.2", { { "sim.heartBuffer", "0.2" } } },
	{ "sim.armorPerPoint=0", { { "sim.armorPerPoint", "0" } } },
	{ "armor zones thin 0.2, sliver 0.05", { { "sim.armorZone.ordinary", "0.2" }, { "sim.armorZone.exposure", "0.05" } } },
	{ "sim.critRelief=0 and guardRelief=0 (0069 off)", { { "sim.critRelief", "0" }, { "sim.guardRelief", "0" } } },
	{ "sim.critRelief=0.06 and guardRelief=0.06", { { "sim.critRelief", "0.06" }, { "sim.guardRelief", "0.06" } } },
	{ "sim.extraTime=0 (0069 last move off)", { { "sim.extraTime", "0" } } },
	{ "sim.straightX=1.5 (flatter meter, same full wheel)", { { "sim.straightX", "1.5" }, { "sim.straightK", "9.28" } } },
	{ "sim.straightRank=0 (rank adds nothing)", { { "sim.straightRank", "0" } } },
	{ "trick hits and wards ×0.5", { { "sim.straightK", "1.1" }, { "sim.hit.flush", "120" }, { "sim.hit.fullHouse", "2600" }, { "sim.hit.quads", "4000" }, { "sim.hit.straightFlush", "12000" }, { "sim.ward.flush", "1300" }, { "sim.ward.fullHouse", "1800" }, { "sim.ward.quads", "4400" }, { "sim.ward.straightFlush", "6600" } } },
	{ "spec.showdownBonus=4 (0050, 0075: 8)", { { "spec.showdownBonus", "4" } } },
	{ "spec.showdownBonus=12", { { "spec.showdownBonus", "12" } } },
	{ "spec.showdownBonus=10", { { "spec.showdownBonus", "10" } } },
	{ "spec.postureStart=34 (0075: 32)", { { "spec.postureStart", "34" } } },
	{ "spec.street.1=0.75 (0054: 1.0)", { { "spec.street.1", "0.75" } } },
	{ "spec.street.3=1.25 (0054: 1.0)", { { "spec.street.3", "1.25" } } },
	{ "proto.turnCushion=0.5 (not adopted)", { { "proto.turnCushion", "0.5" } } },
	{ "before 0053-0054 (Posture 40, 0.5/0.75/1.0/1.25, ×1.3, unhorse on P4)", { { "switches.riverRule", "unhorse" }, { "spec.postureStart", "40" }, { "spec.street.1", "0.5" }, { "spec.street.2", "0.75" }, { "spec.street.4", "1.625" } } },
	{ "switches.slowmo=game", { { "switches.slowmo", "game" } } },
	{ "switches.slowmo=wall (0061: excluded)", { { "switches.slowmo", "wall" } } },
	{ "switches.statBasis=points", { { "switches.statBasis", "points" } } },
	{ "switches.flushHit=F2", { { "switches.flushHit", "F2" } } },
	{ "switches.meterThreshold=strict", { { "switches.meterThreshold", "strict" } } },
	{ "switches.posture=exact (0075: half hearts)", { { "switches.posture", "exact" } } },
}

-- The rows of a sweep this process runs: --only filters by label, then --shard picks every n-th.
local function selectRows(rows: { { any } }): { { any } }
	local picked = {}
	for _, r in rows do
		if only == nil or string.find(r[1], only :: string, 1, true) then
			table.insert(picked, r)
		end
	end
	local out = {}
	for idx, r in picked do
		if (idx - 1) % shards == shard - 1 then
			table.insert(out, r)
		end
	end
	return out
end

local function sweepConfig(extra: { any }): any
	local cfg = baseConfig()
	for _, kv in extra do
		Config.set(cfg, kv[1], kv[2])
	end
	return cfg
end

-- The betting rider (switches.betting = "bands"): the same bands for every profile, per bet 1–4.
local function bands(raise: { number }, yield: { number }): { any }
	local out: { any } = { { "switches.betting", "bands" } }
	for _, prof in { "average", "skilled", "novice" } do
		for b = 1, 4 do
			table.insert(out, { string.format("riders.%s.raiseAt.%d", prof, b), tostring(raise[b]) })
			table.insert(out, { string.format("riders.%s.yieldAt.%d", prof, b), tostring(yield[b]) })
		end
	end
	return out
end
local function flat(x: number): { number }
	return { x, x, x, x }
end

-- One row per betting reading: the script (today) and the betting rider at several bands.
-- Raise at the first number, Yield to a raise below the second; "none" never Yields.
local BETS: { { any } } = {
	{ "script (default, today)", {} },
	{ "bands raise .55, yield none", bands(flat(0.55), flat(0)) },
	{ "bands raise .60, yield none", bands(flat(0.6), flat(0)) },
	{ "bands raise .55, yield .30", bands(flat(0.55), flat(0.3)) },
	{ "bands raise .60, yield .20", bands(flat(0.6), flat(0.2)) },
	{ "bands raise .60, yield .25 (profile default)", bands(flat(0.6), flat(0.25)) },
	{ "bands raise .65, yield .25", bands(flat(0.65), flat(0.25)) },
	{ "bands raise .60, yield .35", bands(flat(0.6), flat(0.35)) },
	{ "bands raise .60, yield .40", bands(flat(0.6), flat(0.4)) },
	{ "bands raise .65, yield .40", bands(flat(0.65), flat(0.4)) },
	{ "bands raise .70, yield .45", bands(flat(0.7), flat(0.45)) },
	{ "bands preflop calm: raise 1/1/.60/.60, yield 0/0/.35/.35", bands({ 1, 1, 0.6, 0.6 }, { 0, 0, 0.35, 0.35 }) },
}

-- The yard is measured under these betting readings (a subset of BETS).
local YARD: { { any } } = {
	{ "script (default, today)", {} },
	{ "bands raise .60, yield none", bands(flat(0.6), flat(0)) },
	{ "bands raise .60, yield .25", bands(flat(0.6), flat(0.25)) },
	{ "bands raise .60, yield .35", bands(flat(0.6), flat(0.35)) },
}

local RANKS = "AKQJT98765432"

-- The kept range as a 13×13 chart: pairs on the diagonal, suited above, offsuit below.
-- # kept, + partly kept (the margin), . folded.
local function chart(keep: { number }): { string }
	local lines = { "     " .. string.gsub(RANKS, ".", "%0 ") }
	for a = 1, 13 do
		local ra = 15 - a
		local line = "  " .. string.sub(RANKS, a, a) .. "  "
		for b = 1, 13 do
			local rb = 15 - b
			local q = keep[(ra - 2) * 13 + (rb - 2) + 1]
			line ..= (if q >= 1 - 1e-9 then "#" elseif q > 1e-9 then "+" else ".") .. " "
		end
		table.insert(lines, line)
	end
	return lines
end

local function lossLine(m: Yard.Metrics): string
	local l = m.loss
	local function sum(a: number, b: number): number
		local x = 0
		for i = a, b do
			x += l[i + 1]
		end
		return x
	end
	return string.format("loser loses 1: %s  2-3: %s  4-7: %s  8-13: %s  split %s  | mean loss %.2f",
		pct(sum(1, 1), 1), pct(sum(2, 3), 1), pct(sum(4, 7), 1), pct(sum(8, 13), 1), pct(l[1], 1), m.meanLoss)
end

local function metricsLine(m: Yard.Metrics): string
	return string.format("modest meet %s, worse category wins %s (a modest hand %s), lower-EV class wins %s, numeric %s | kept: pairs %s suited %s offsuit %s, with an ace %s, %d classes",
		pct(m.modest, 1), pct(m.upset, 1), pct(m.modestUpset, 1), pct(m.underdog, 1), pct(m.numeric, 1),
		pct(m.pairs, 1), pct(m.suited, 1), pct(m.offsuit, 1), pct(m.ace, 1), m.classes)
end

local DESTS = { "sink", "purse", "carry" }

local t0 = os.clock()
if report == "baseline" then
	local cfg = baseConfig()
	local prof1 = assert(cfg.riders[p1name], "no rider profile " .. p1name)
	local prof2 = assert(cfg.riders[p2name], "no rider profile " .. p2name)
	printBaseline(run(cfg, prof1, prof2, hands, seed), p1name .. " vs " .. p2name)
elseif report == "matchups" then
	local cfg = baseConfig()
	for _, m in { { "skilled", "novice" }, { "holder", "flicker" }, { "skilled", "average" } } do
		printBaseline(run(cfg, cfg.riders[m[1]], cfg.riders[m[2]], hands, seed), m[1] .. " vs " .. m[2])
		print("")
	end
elseif report == "sweeps" then
	print(string.format("%d hands per run; mirror = average vs average; flip = skilled (seat 1) wins with the worse category vs novice", hands))
	print(ROW_HEAD)
	for _, sw in selectRows(SWEEPS) do
		local cfg = sweepConfig(sw[2])
		local t = run(cfg, cfg.riders.average, cfg.riders.average, hands, seed)
		local m = run(cfg, cfg.riders.skilled, cfg.riders.novice, hands, seed + 1)
		row(sw[1], t, m)
	end
elseif report == "floor" then
	-- §3 / §11: is the hold floor collapsing half-holds toward last-instant flicks?
	-- holder vs flicker is the extreme; the average pair differ only in hold discipline (1 vs 0).
	print("holder: never reads, holds from the first moment; flicker: always reads, never holds")
	print("steady / fidget: the average rider with hold discipline 1 / 0 (both read 30%)")
	for _, f in { "0.2", "0.25", "0.3", "0.4", "0.5", "0.6" } do
		local cfg = baseConfig()
		Config.set(cfg, "spec.holdFloor", f)
		local t = run(cfg, cfg.riders.holder, cfg.riders.flicker, hands, seed)
		local steady, fidget = table.clone(cfg.riders.average), table.clone(cfg.riders.average)
		steady.hold, fidget.hold = 1, 0
		local u = run(cfg, steady, fidget, hands, seed + 1)
		local m = run(cfg, cfg.riders.average, cfg.riders.average, hands, seed + 2)
		print(string.format("holdFloor %s: holder wins %s vs flicker | steady wins %s vs fidget | mirror reads that switch %s",
			f, pct(t["win.1"], t.hands), pct(u["win.1"], u.hands), pct(m.switches, m.reads)))
	end
elseif report == "showdown" then
	-- §4 *Tracks and showdown* (0050): how close the riders are when the knockdown is forced, and
	-- how much of the result the hand bonus decides. Bonus 0 is a reference point, not a proposal.
	print("mirror = average vs average; flip = skilled wins a numeric hand with the worse category vs novice")
	for _, b in { "0", "4", "8", "12" } do
		local cfg = baseConfig()
		Config.set(cfg, "spec.showdownBonus", b)
		local t = run(cfg, cfg.riders.average, cfg.riders.average, hands, seed)
		local m = run(cfg, cfg.riders.skilled, cfg.riders.novice, hands, seed + 1)
		local sd = t["finish.showdown"] or 0
		print(string.format("bonus %s: showdown %s of hands | Posture there: mean %.0f, lower rider %.0f", b,
			pct(sd, t.hands), (t["sd.postureSum"] or 0) / math.max(1, sd) / 2, (t["sd.lowerPosture"] or 0) / math.max(1, sd)))
		print(string.format("  Posture gap <4 %s  4-8 %s  8-16 %s  16+ %s | category gap 0 %s  1 %s  2 %s  3+ %s",
			pct(t["sd.pgap.0"], sd), pct(t["sd.pgap.4"], sd), pct(t["sd.pgap.8"], sd), pct(t["sd.pgap.16"], sd),
			pct(t["sd.cgap.0"], sd), pct(t["sd.cgap.1"], sd), pct(t["sd.cgap.2"], sd), pct(t["sd.cgap.3"], sd)))
		print(string.format("  Posture leader wins %s | leader holds the worse hand in %s of showdowns; cards win %s of those | gap1 better wins %s | flip %s",
			pct(t["sd.postureLeaderWins"], t["sd.postureDiff"]), pct(t["sd.leaderWorse"], sd),
			pct(t["sd.leaderWorse.cardsWin"], t["sd.leaderWorse"]), pct(t["gap1.better"], t.gap1), pct(m["p1worse.win"], m.p1worse)))
		print(string.format("  projected at the river (Posture + bonus before Pass 4's contact) holds: margin <8 %s (n=%d), 8+ %s (n=%d)",
			pct(t["proj.close.held"], t["proj.close"]), t["proj.close"] or 0, pct(t["proj.clear.held"], t["proj.clear"]), t["proj.clear"] or 0))
	end
elseif report == "proto" then
	-- The showdown prototypes (docs/sim/SHOWDOWN.md): one row per reading, at 100k hands per run.
	-- "over" = the hand's showdown effect (bonus, mult, blows, charge) overturns the rider ahead on
	-- Posture after Pass 4's dial exchange (1 − after-P4 leader wins); "proj" = the rider ahead on the projected standing at the river reveal wins, close (<20)
	-- and clear (20+) margins; "flip" here is the pillar 2 skill flip as in the sweeps.
	local PROTO: { { any } } = {
		{ "bonus 8 (0050)", {} },
		{ "bonus 8, Posture start 28", { { "spec.postureStart", "28" } } },
		{ "bonus 8, Pass 4 ×2.5", { { "spec.street.4", "2.5" } } },
		{ "bonus 4, Pass 4 ×2.5", { { "spec.showdownBonus", "4" }, { "spec.street.4", "2.5" } } },
		{ "mult 0.2", { { "switches.showdown", "mult" } } },
		{ "mult 0.35", { { "switches.showdown", "mult" }, { "proto.mult", "0.35" } } },
		{ "mult 0.5", { { "switches.showdown", "mult" }, { "proto.mult", "0.5" } } },
		{ "riverHit 4, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "4" } } },
		{ "riverHit 6, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "6" } } },
		{ "riverHit 8, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" } } },
		{ "riverHit 12, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "12" } } },
		{ "riverHit 8, flat tier (the reveal blow)", { { "switches.showdown", "riverHit" }, { "proto.riverTier.crit", "1" }, { "proto.riverTier.block", "1" }, { "proto.riverTier.weak", "1" } } },
		{ "riverHit 8, tier 2/1/0", { { "switches.showdown", "riverHit" }, { "proto.riverTier.crit", "2" }, { "proto.riverTier.block", "0" }, { "proto.riverTier.weak", "0" } } },
		{ "riverHit 8 + bonus 4 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "4" } } },
		{ "riverHit 4 + bonus 4 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "4" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "4" } } },
		{ "riverHit 8, Posture start 28", { { "switches.showdown", "riverHit" }, { "spec.postureStart", "28" } } },
		{ "riverHit 4, warded", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "4" }, { "proto.riverVsTrick", "warded" } } },
		{ "riverHit 6, warded", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "6" }, { "proto.riverVsTrick", "warded" } } },
		{ "riverHit 8, warded", { { "switches.showdown", "riverHit" }, { "proto.riverVsTrick", "warded" } } },
		{ "riverHit 6, warded + bonus 4 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "6" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "4" } } },
		{ "riverHit 8, warded + bonus 4 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "4" } } },
		{ "riverHit 4, warded + bonus 4 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "4" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "4" } } },
		{ "riverHit 6, warded + bonus 6 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "6" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "6" } } },
		{ "riverHit 6, warded + bonus 8 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "6" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "8" } } },
		{ "riverHit 8 warded, flat tier + bonus 4", { { "switches.showdown", "riverHit" }, { "proto.riverVsTrick", "warded" }, { "proto.riverTier.crit", "1" }, { "proto.riverTier.block", "1" }, { "proto.riverTier.weak", "1" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "4" } } },
		{ "charge: bonus up, cards up, ×1.625", { { "switches.showdown", "charge" } } },
		{ "charge: bonus up, cards down", { { "switches.showdown", "charge" }, { "proto.chargeCardsUp", "no" } } },
		{ "charge: no bonus, cards up", { { "switches.showdown", "charge" }, { "proto.chargeBonus", "none" } } },
		{ "charge: hand blows on the charge (8)", { { "switches.showdown", "charge" }, { "proto.chargeBonus", "hit" } } },
		{ "charge: hand blows on the charge (4)", { { "switches.showdown", "charge" }, { "proto.chargeBonus", "hit" }, { "proto.riverPerStep", "4" } } },
		{ "charge: bonus up, ×2.5", { { "switches.showdown", "charge" }, { "proto.chargeStreet", "2.5" } } },
		{ "charge: bonus up, Posture start 70", { { "switches.showdown", "charge" }, { "spec.postureStart", "70" } } },
	}
	print(string.format("%d hands per run; mirror = average vs average; flip = skilled (seat 1) wins with the worse category vs novice", hands))
	print("config                                   | sd %  | KO P2  P3   P4   P5  | gap1  gap2  gap3 | flip  | above/design above/off | over  | proj close clear | charge KO flip | passes")
	for _, sw in selectRows(PROTO) do
		-- The prototypes were built against the river rule before 0053 (a rider at 0 falls on
		-- Pass 4's contact), so every row pins it. Everything else is the current defaults.
		local cfg = sweepConfig({ { "switches.riverRule", "unhorse" }, table.unpack(sw[2]) })
		local t = run(cfg, cfg.riders.average, cfg.riders.average, hands, seed)
		local m = run(cfg, cfg.riders.skilled, cfg.riders.novice, hands, seed + 1)
		local n = t.hands
		local w1, n1 = aboveRate(t, "design")
		local w2, n2 = aboveRate(t, "off")
		local over = if (t["after.n"] or 0) > 0 then string.format("%5.1f%%", 100 * (1 - (t["after.leaderWins"] or 0) / t["after.n"])) else "  n/a"
		print(string.format("%-40s | %s | %4.1f %4.1f %4.1f %4.1f | %s %s %s | %s | %s   %s | %s | %s %s | %s %s | %.2f",
			sw[1], pct(t["finish.showdown"], n),
			100 * (t["ko.pass2"] or 0) / n, 100 * (t["ko.pass3"] or 0) / n, 100 * (t["ko.pass4"] or 0) / n, 100 * (t["ko.pass5"] or 0) / n,
			pct(t["gap1.better"], t.gap1), pct(t["gap2.better"], t.gap2), pct(t["gap3.better"], t.gap3),
			pct(m["p1worse.win"], m.p1worse),
			pct(w1, n1), pct(w2, n2),
			over,
			pct(t["proj.close.held"], t["proj.close"]), pct(t["proj.clear.held"], t["proj.clear"]),
			pct(t["charge.ko"], t["charge.n"]), pct(t["charge.flip"], t["charge.standing"]),
			(t.passes or 0) / n))
	end
elseif report == "bets" then
	-- The betting rider's bands (switches.betting = "bands"): what pots and losses look like.
	print(string.format("%d hands per run; mirror = average vs average; flip = skilled (seat 1) wins with the worse category vs novice", hands))
	print("config                                                  | yield   bet1  bet2  bet3  bet4 | raised | loser loses 1    2-3    4-7    8-13 | mean | gap1  | flip  | skilled u/hand")
	for _, sw in selectRows(BETS) do
		local cfg = sweepConfig(sw[2])
		local t = run(cfg, cfg.riders.average, cfg.riders.average, hands, seed)
		local m = run(cfg, cfg.riders.skilled, cfg.riders.novice, hands, seed + 1)
		local n = t.hands
		local ln = t["loss.n"] or 0
		print(string.format("%-55s | %s %s %s %s %s | %s | %s %s %s %s | %.2f | %s | %s | %+.3f",
			sw[1], pct(t["finish.yield"], n),
			pct(t["yield.bet1"], n), pct(t["yield.bet2"], n), pct(t["yield.bet3"], n), pct(t["yield.bet4"], n),
			pct(t.raised, n),
			pct(t["loss.1"], ln), pct(t["loss.3"], ln), pct(t["loss.7"], ln), pct(t["loss.13"], ln),
			(t["loss.sum"] or 0) / math.max(1, ln),
			pct(t["gap1.better"], t.gap1), pct(m["p1worse.win"], m.p1worse), (m.units1 or 0) / m.hands))
	end
elseif report == "yard" then
	-- The yard (§2, 0078–0080): riders keep or prefold by starting-hand class; the price holds the
	-- kept share. Per betting reading: the price each share needs, the share each price holds, and
	-- the yard at the target share (spec.keptShare, 0079) under each destination (0078: carry).
	local base = baseConfig()
	local target = base.spec.keptShare
	print(string.format("%d hands per betting reading, average vs average, tallied by starting-hand class pair", hands))
	print("Prices are in units. A price is what a prefold costs; 'extra' is the prefold money in an average match's pot.")
	for _, sw in selectRows(YARD) do
		local cfg = sweepConfig(sw[2])
		local tally = Yard.newTally()
		run(cfg, cfg.riders.average, cfg.riders.average, hands, seed, tally)
		print("")
		print("== " .. sw[1])
		local all = Yard.atShare(tally, "sink", 1)
		local m0 = Yard.metrics(tally, all)
		print("everyone keeps: " .. lossLine(m0))
		print("  " .. metricsLine(m0))
		local SHARES = { 1.0, 0.95, 0.9, 0.85, 0.8, 0.75, 0.7, 0.6, 0.5 }
		local PRICES = { 0, 0.1, 0.2, 0.3, 0.5, 0.75, 1.0 }
		local caches: { [string]: { [number]: Yard.Solution } } = {}
		for _, dest in DESTS do
			caches[dest] = {}
			local line = string.format("%-5s price for share:", dest)
			for _, k in SHARES do
				local sol = Yard.atShare(tally, dest, k)
				line ..= string.format(" %d%% %s", math.floor(k * 100 + 0.5), if sol.price == math.huge then "none" else string.format("%.2f", sol.price))
			end
			print(line)
			local fwd = string.format("%-5s share at price:", dest)
			for _, c in PRICES do
				local sol = Yard.atPrice(tally, dest, c, caches[dest])
				fwd ..= string.format(" %.2f %s", c, if sol then string.format("%.1f%%", 100 * sol.share) else "<5%")
			end
			print(fwd)
		end
		local conf = Yard.atPrice(tally, base.switches.prefold, base.sim.prefoldPrice, caches[base.switches.prefold])
		print(string.format("configured: price %.2f into %s keeps %s", base.sim.prefoldPrice, base.switches.prefold,
			if conf then string.format("%.1f%%", 100 * conf.share) else "under 5%"))
		for _, dest in DESTS do
			local sol = Yard.atShare(tally, dest, target)
			local m = Yard.metrics(tally, sol)
			print(string.format("-- %s at %d%% kept: price %.3f, extra %.3f a match; a fold is worth %+.3f",
				dest, math.floor(target * 100 + 0.5), sol.price, sol.extra, sol.fold))
			-- The margin: the last classes kept and the first folded, by keep value.
			local order = {}
			for i = 1, 169 do
				table.insert(order, i)
			end
			table.sort(order, function(a, b)
				return sol.value[a] > sol.value[b]
			end)
			local at = 1
			for idx, i in order do
				if sol.keep[i] < 1 then
					at = idx
					break
				end
			end
			local edge = {}
			for idx = math.max(1, at - 3), math.min(169, at + 3) do
				local i = order[idx]
				table.insert(edge, string.format("%s%s %+.3f (win %.2f)", Cards.className(i),
					if sol.keep[i] >= 1 - 1e-9 then "" elseif sol.keep[i] > 1e-9 then string.format(" %.0f%%", 100 * sol.keep[i]) else " folded", sol.ev[i], sol.win[i]))
			end
			print("   margin: " .. table.concat(edge, ", "))
			print("   " .. lossLine(m))
			print("   " .. metricsLine(m))
			if dest == "carry" then
				for _, line in chart(sol.keep) do
					print(line)
				end
			end
		end
	end
elseif report == "gap" then
	-- §4: the gap between two riders' numeric hands on a hit, from random river deals.
	local cfg = baseConfig()
	local rng = makeRng(seed)
	for _, lean in { 0, 0.5, 1, 2 } do
		local sums, counts = { 0, 0, 0, 0 }, { 0, 0, 0, 0 }
		local ratios: { [number]: { number } } = { {}, {}, {} }
		local worse: { number } = { 0, 0, 0 }
		for _ = 1, hands do
			local d = Cards.shuffled(rng)
			local b = { d[5], d[6], d[7], d[8], d[9] }
			local m, c = {}, {}
			local skip = false
			for i = 1, 2 do
				local all = { d[2 * i - 1], d[2 * i], table.unpack(b) }
				if Cards.evaluate(all).category >= Cards.STRAIGHT then
					skip = true
				end
				local pts, sub = Cards.points({ d[2 * i - 1], d[2 * i] }, b, cfg.spec)
				m[i] = 1 + cfg.spec.clubRate * math.max(pts[1], pts[2], pts[3], pts[4]) * (1 + lean)
				c[i] = sub
			end
			if not skip then
				for i = 1, 2 do
					sums[c[i] + 1] += m[i]
					counts[c[i] + 1] += 1
				end
				local g = math.abs(c[1] - c[2])
				if g > 0 then
					local hi = if c[1] > c[2] then 1 else 2
					local ratio = m[hi] / m[3 - hi]
					table.insert(ratios[g], ratio)
					if ratio < 1 then
						worse[g] += 1
					end
				end
			end
		end
		local med = {}
		for g = 1, 3 do
			table.sort(ratios[g])
			med[g] = ratios[g][math.max(1, #ratios[g] // 2)] or 0
		end
		print(string.format("lean %.1f: loaded-stat multiplier HC %.2f pair %.2f 2P %.2f trips %.2f | better/worse median gap1 %.2f gap2 %.2f gap3 %.2f | worse loads more %s %s %s",
			lean, sums[1] / counts[1], sums[2] / counts[2], sums[3] / counts[3], sums[4] / counts[4],
			med[1], med[2], med[3], pct(worse[1], #ratios[1]), pct(worse[2], #ratios[2]), pct(worse[3], #ratios[3])))
	end
else
	error("sim: unknown --report " .. tostring(report))
end
print(string.format("(%.1fs, seed %d%s)", os.clock() - t0, seed, if hands < 100000 then ", fewer than 100k hands per run: not citable" else ""))
