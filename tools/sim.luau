--!strict
-- sim.luau — the headless one-hand sim (GAME_SPEC §11 *Sim plan*). Run from the repo root:
--
--   lune run tools/sim.luau                          -- baseline report, 100k hands per run
--   lune run tools/sim.luau --report sweeps          -- one row per sweep point (docs/sim/RESULTS.md)
--   lune run tools/sim.luau --report gap             -- numeric hit gap by category (§4)
--   lune run tools/sim.luau --report showdown        -- how the forced knockdown is decided (0050)
--   lune run tools/sim.luau --report proto           -- the showdown prototypes (docs/sim/SHOWDOWN.md)
--   lune run tools/sim.luau --set sim.lean=2 --set spec.showdownBonus=10
--   lune run tools/sim.luau --smoke                  -- 5k hands: checks it runs; rates not citable
--
-- Options: --hands N, --seed S, --shard i/n (sweeps and proto: run every n-th row, for parallel runs),
-- --only text (sweeps and proto: only rows whose label contains it), --set path=value (repeatable; paths as in sim/Config.luau),
-- --p1 / --p2 rider profile for the baseline report (default average vs average).
-- Unknown arguments are an error, so a typo never prints a confident report for the wrong run.
--
-- Mechanism borrowed from rblx-joust-tourney (main, tools/sim.luau): the seeded LCG, strict
-- argument parsing and the smoke mode. The metrics and the game are this repo's.

local process = require("@lune/process")
local Config = require("../sim/Config")
local Hand = require("../sim/Hand")
local Cards = require("../sim/Cards")

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
local function run(cfg: any, prof1: any, prof2: any, n: number, s: number): Tally
	local rng = makeRng(s)
	local t: Tally = {}
	for i = 1, n do
		local r = Hand.play(cfg, rng, prof1, prof2, (i % 2) + 1)
		inc(t, "hands")
		inc(t, "finish." .. r.finish)
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
				local band = if math.abs(s1 - s2) < 20 then "close" else "clear"
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
			local band = if lead < 20 then "close" else "clear"
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
			inc(t, "sd.pgap." .. (if pg < 10 then "0" elseif pg < 20 then "10" elseif pg < 40 then "20" else "40"))
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
	{ "sim.armorRate=0.15", { { "sim.armorRate", "0.15" } } },
	{ "sim.armorRate=0.4", { { "sim.armorRate", "0.4" } } },
	{ "sim.heartPosture=2", { { "sim.heartPosture", "2" } } },
	{ "sim.heartPosture=5", { { "sim.heartPosture", "5" } } },
	{ "sim.chargeRate=0", { { "sim.chargeRate", "0" } } },
	{ "sim.chargeRate=6", { { "sim.chargeRate", "6" } } },
	{ "sim.straightX=1.15", { { "sim.straightX", "1.15" }, { "sim.straightK", "180" } } },
	{ "sim.straightX=2 (wards not rescaled)", { { "sim.straightX", "2" }, { "sim.straightK", "12" } } },
	{ "trick hits and wards ×0.5", { { "sim.straightK", "50" }, { "sim.hit.flush", "300" }, { "sim.hit.fullHouse", "6500" }, { "sim.hit.quads", "10000" }, { "sim.hit.straightFlush", "30000" }, { "sim.ward.flush", "3250" }, { "sim.ward.fullHouse", "4500" }, { "sim.ward.quads", "11000" }, { "sim.ward.straightFlush", "16500" } } },
	{ "spec.showdownBonus=10 (0050: 20)", { { "spec.showdownBonus", "10" } } },
	{ "spec.showdownBonus=30", { { "spec.showdownBonus", "30" } } },
	{ "spec.showdownBonus=25", { { "spec.showdownBonus", "25" } } },
	{ "spec.postureStart=85 (0054: 80)", { { "spec.postureStart", "85" } } },
	{ "spec.street.1=0.75 (0054: 1.0)", { { "spec.street.1", "0.75" } } },
	{ "spec.street.3=1.25 (0054: 1.0)", { { "spec.street.3", "1.25" } } },
	{ "proto.turnCushion=0.5 (not adopted)", { { "proto.turnCushion", "0.5" } } },
	{ "before 0053-0054 (Posture 100, 0.5/0.75/1.0/1.25, ×1.3, unhorse on P4)", { { "switches.riverRule", "unhorse" }, { "spec.postureStart", "100" }, { "spec.street.1", "0.5" }, { "spec.street.2", "0.75" }, { "spec.street.4", "1.625" } } },
	{ "switches.slowmo=game", { { "switches.slowmo", "game" } } },
	{ "switches.slowmo=wall (0061: excluded)", { { "switches.slowmo", "wall" } } },
	{ "switches.statBasis=points", { { "switches.statBasis", "points" } } },
	{ "switches.flushHit=F2", { { "switches.flushHit", "F2" } } },
	{ "switches.meterThreshold=strict", { { "switches.meterThreshold", "strict" } } },
	{ "switches.twinFavorVsTrick=trickOverrides", { { "switches.twinFavorVsTrick", "trickOverrides" } } },
	{ "switches.aaEdge=both", { { "switches.aaEdge", "both" } } },
	{ "switches.aaEdge=direction", { { "switches.aaEdge", "direction" } } },
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
	for _, b in { "0", "10", "20", "30" } do
		local cfg = baseConfig()
		Config.set(cfg, "spec.showdownBonus", b)
		local t = run(cfg, cfg.riders.average, cfg.riders.average, hands, seed)
		local m = run(cfg, cfg.riders.skilled, cfg.riders.novice, hands, seed + 1)
		local sd = t["finish.showdown"] or 0
		print(string.format("bonus %s: showdown %s of hands | Posture there: mean %.0f, lower rider %.0f", b,
			pct(sd, t.hands), (t["sd.postureSum"] or 0) / math.max(1, sd) / 2, (t["sd.lowerPosture"] or 0) / math.max(1, sd)))
		print(string.format("  Posture gap <10 %s  10-20 %s  20-40 %s  40+ %s | category gap 0 %s  1 %s  2 %s  3+ %s",
			pct(t["sd.pgap.0"], sd), pct(t["sd.pgap.10"], sd), pct(t["sd.pgap.20"], sd), pct(t["sd.pgap.40"], sd),
			pct(t["sd.cgap.0"], sd), pct(t["sd.cgap.1"], sd), pct(t["sd.cgap.2"], sd), pct(t["sd.cgap.3"], sd)))
		print(string.format("  Posture leader wins %s | leader holds the worse hand in %s of showdowns; cards win %s of those | gap1 better wins %s | flip %s",
			pct(t["sd.postureLeaderWins"], t["sd.postureDiff"]), pct(t["sd.leaderWorse"], sd),
			pct(t["sd.leaderWorse.cardsWin"], t["sd.leaderWorse"]), pct(t["gap1.better"], t.gap1), pct(m["p1worse.win"], m.p1worse)))
		print(string.format("  projected at the river (Posture + bonus before Pass 4's contact) holds: margin <20 %s (n=%d), 20+ %s (n=%d)",
			pct(t["proj.close.held"], t["proj.close"]), t["proj.close"] or 0, pct(t["proj.clear.held"], t["proj.clear"]), t["proj.clear"] or 0))
	end
elseif report == "proto" then
	-- The showdown prototypes (docs/sim/SHOWDOWN.md): one row per reading, at 100k hands per run.
	-- "over" = the hand's showdown effect (bonus, mult, blows, charge) overturns the rider ahead on
	-- Posture after Pass 4's dial exchange (1 − after-P4 leader wins); "proj" = the rider ahead on the projected standing at the river reveal wins, close (<20)
	-- and clear (20+) margins; "flip" here is the pillar 2 skill flip as in the sweeps.
	local PROTO: { { any } } = {
		{ "bonus 20 (0050)", {} },
		{ "bonus 20, Posture start 70", { { "spec.postureStart", "70" } } },
		{ "bonus 20, Pass 4 ×2.5", { { "spec.street.4", "2.5" } } },
		{ "bonus 10, Pass 4 ×2.5", { { "spec.showdownBonus", "10" }, { "spec.street.4", "2.5" } } },
		{ "mult 0.2", { { "switches.showdown", "mult" } } },
		{ "mult 0.35", { { "switches.showdown", "mult" }, { "proto.mult", "0.35" } } },
		{ "mult 0.5", { { "switches.showdown", "mult" }, { "proto.mult", "0.5" } } },
		{ "riverHit 10, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "10" } } },
		{ "riverHit 15, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "15" } } },
		{ "riverHit 20, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" } } },
		{ "riverHit 30, tier 1.5/1/0.25", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "30" } } },
		{ "riverHit 20, flat tier (the reveal blow)", { { "switches.showdown", "riverHit" }, { "proto.riverTier.crit", "1" }, { "proto.riverTier.block", "1" }, { "proto.riverTier.weak", "1" } } },
		{ "riverHit 20, tier 2/1/0", { { "switches.showdown", "riverHit" }, { "proto.riverTier.crit", "2" }, { "proto.riverTier.block", "0" }, { "proto.riverTier.weak", "0" } } },
		{ "riverHit 20 + bonus 10 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "10" } } },
		{ "riverHit 10 + bonus 10 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "10" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "10" } } },
		{ "riverHit 20, Posture start 70", { { "switches.showdown", "riverHit" }, { "spec.postureStart", "70" } } },
		{ "riverHit 10, warded", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "10" }, { "proto.riverVsTrick", "warded" } } },
		{ "riverHit 15, warded", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "15" }, { "proto.riverVsTrick", "warded" } } },
		{ "riverHit 20, warded", { { "switches.showdown", "riverHit" }, { "proto.riverVsTrick", "warded" } } },
		{ "riverHit 15, warded + bonus 10 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "15" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "10" } } },
		{ "riverHit 20, warded + bonus 10 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "10" } } },
		{ "riverHit 10, warded + bonus 10 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "10" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "10" } } },
		{ "riverHit 15, warded + bonus 15 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "15" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "15" } } },
		{ "riverHit 15, warded + bonus 20 knockdown", { { "switches.showdown", "riverHit" }, { "proto.riverPerStep", "15" }, { "proto.riverVsTrick", "warded" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "20" } } },
		{ "riverHit 20 warded, flat tier + bonus 10", { { "switches.showdown", "riverHit" }, { "proto.riverVsTrick", "warded" }, { "proto.riverTier.crit", "1" }, { "proto.riverTier.block", "1" }, { "proto.riverTier.weak", "1" }, { "proto.riverKnockdown", "bonus" }, { "spec.showdownBonus", "10" } } },
		{ "charge: bonus up, cards up, ×1.625", { { "switches.showdown", "charge" } } },
		{ "charge: bonus up, cards down", { { "switches.showdown", "charge" }, { "proto.chargeCardsUp", "no" } } },
		{ "charge: no bonus, cards up", { { "switches.showdown", "charge" }, { "proto.chargeBonus", "none" } } },
		{ "charge: hand blows on the charge (20)", { { "switches.showdown", "charge" }, { "proto.chargeBonus", "hit" } } },
		{ "charge: hand blows on the charge (10)", { { "switches.showdown", "charge" }, { "proto.chargeBonus", "hit" }, { "proto.riverPerStep", "10" } } },
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
