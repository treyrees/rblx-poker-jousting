--!strict
-- Config.luau — every number the sim uses, in one place.
--
--   SPEC      mirrors GAME_SPEC §11 *Tuning parameters* (plus the §5 and §6 values §11 points at).
--             Used as-is. A change here is a design change: Trey's call (AGENTS.md).
--   SIM_SET   values §11 says are "set by the sim". These are this sim's STARTING values, not
--             proposals for GAME_SPEC; docs/sim/SANITY_CHECK.md §1(a) says why each was picked.
--   SWITCHES  open questions (§11) and spec gaps (SANITY_CHECK §1(b), (c), C1, C2), each modelled
--             as two or three readings. The default reading is a starting point, never an answer.
--
-- Config.defaults() returns a fresh table; Config.set(cfg, "path.to.key", "value") overrides one
-- value (the CLI's --set). Nothing else in sim/ holds a tuning number.

local Config = {}

function Config.defaults()
	return {
		-- ── SPEC: GAME_SPEC §11 tuning parameters (v1 values) ─────────────────────────────────
		spec = {
			postureStart = 32, -- 16 hearts; 1 is a half heart (0075)
			base = { weak = 2, normal = 4, crit = 12 }, -- 1, 2 and 6 hearts (0075)
			statBase = 20, -- cardless floor, S_suit = 20 + points
			rankBase = 1, -- card value 1 + (r − 2) / 6
			rankSlope = 1 / 6,
			boardWeight = 0.5, -- "½ of a hole card; the sim tries lower"
			handMult = { pair = 2, twoPair = 2, trips = 3 },
			clubRate = 1 / 20, -- ♣ scales hits by S♣ / 20
			holdFloor = 0.25, -- hold multiplier 0.25 + 0.75·h (0052; the slope is 1 − floor)
			street = { 1.0, 1.0, 1.0, 1.25 }, -- 0054; 0051's last-pass bonus is removed
			showdownBonus = 8, -- showdown: Posture per step of hand category, 4 hearts (0050, 0075)
			cleanBlockRestore = 1, -- a half heart (0075)
			aimLock = 0.3,
			passLength = 8.0,
			-- Standard dial, half steps from aim: E exposure, O ordinary, G Guard.
			layout = "EEEEEOOOGOGGGOOO",
			fortressGuardDirections = 7,
			heldPassive = { straight = 3, flush = 4, fullHouse = 4, quads = 4 },
			raise = { 1, 1, 2, 2 }, -- before Passes 1–4
			ante = 1,
			keptShare = 0.75, -- the yard keeps 75% of dealt hands; the prefold price is set for it (0079)
			-- §6 board-made arena effects (0040: placeholders, not yet in §11)
			openLists = 1.5,
			siege = 0.5,
			-- §8 pass timeline (seconds from the start of the charge)
			timeline = { reveal = 3.0, slowEnd = 4.5, lock = 7.7, slowSpeed = 0.4 },
		},

		-- ── SIM_SET: §11 "set by the sim" — starting values ───────────────────────────────────
		sim = {
			lean = 1.0, -- λ: a stat leaned into at weight w counts points × (1 + λw)
			halfStepShare = 0.75, -- a half step's share to the nearer cardinal
			heartBuffer = 0.6, -- buffer per leaned ♥ point (the lean's extra points): absorbs damage first
			healBase = 0.1, -- after contact, heal this share of the damage taken (0070)...
			healPerPoint = 0.02, -- ...plus this much per unleaned ♥ point
			battered = 0.4, -- Battered: +x damage taken, × the striker's ♣ lean weight (0068)
			critRelief = 0.03, -- on a Crit, this share per ♠ point of the hold multiplier's shortfall is restored (0069)
			guardRelief = 0.03, -- the same for Guard armor, per ♦ point (0069)
			extraTime = 0.15, -- s past the aim lock at a full lean into ♠ or ♦ (0069)
			armorRate = 0.1, -- armor per ♦ stat unit (see switches.statBasis)
			armorPerPoint = 0.6, -- extra armor per ♦ card point, on top (so ♦ cards pull their weight)
			armorZone = { guard = 1.0, ordinary = 0.5, exposure = 0.2 },
			pierceRate = 0.02, -- piercing per ♠ stat unit
			blockBase = 4, -- a Block is a Normal hit into thick armor (c2, 0058)
			earliestCommit = 0.3, -- the earliest a rider leaves Neutral (s)
			readTime = 7.4, -- when a read's late switch lands (s)
			-- Trick hits and wards per rung (SANITY_CHECK §2: a chain that meets §6). A hit must
			-- unhorse from the earliest pass a trick can fire on (Pass 2); a ward must stop lower hits
			-- on Pass 4. Sized under the multipliers before 0054 (×0.75 and ×1.625), so they clear
			-- today's (×1.0 and ×1.25) with room.
			-- The straight's hit is the meter (0073: the power is in the hold):
			-- straightK · straightX ^ (cards unlocked) · (1 + straightRank · (top card − 5)).
			straightK = 2.2,
			straightX = 2,
			straightRank = 0.1,
			hit = { flush = 240, fullHouse = 5200, quads = 8000, straightFlush = 24000 },
			ward = { straight = 0, flush = 2600, fullHouse = 3600, quads = 8800, straightFlush = 13200 },
			flushExplode = 4, -- flush suit's S × this at home (× half on the diagonals beside it)
			flushExplodeF2 = 60, -- the explosion when switches.flushHit = "F2"
			-- The betting rider's odds (switches.betting = "bands", sim/Odds.luau): a calibration run
			-- of this many average-vs-average hands under the default script, on its own seed.
			oddsHands = 50000,
			oddsSeed = 20261008,
			-- The prefold's unit price (0080: units plus a short delay; the delay is a playtest's). The yard
			-- report (--report yard) finds the price that holds spec.keptShare: 0.40 is carry's price for
			-- 75% under the betting rider at its profile bands (docs/sim/RESULTS.md, *The yard*).
			prefoldPrice = 0.4,
		},

		-- ── READING: the reading model (§11 *Sim plan* step 4, sim/Read.luau; 0089–0093) ─────────
		-- Off by default, so the sim plays exactly as before. A reader keeps a belief over the
		-- opponent's hole pair, updated by every public cue of §7 (0089).
		reading = {
			aim = "off", -- off | belief: a read plays against the believed opponent, not an average card (0090)
			betting = "off", -- off | belief: the betting rider's odds average over the belief (0090)
			heal = "beat", -- beat | net: the ♥ heal shows as its own beat after contact, or only in the net change (0093)
			assume = "average", -- the rider profile a reader assumes the opponent rides as
			samples = 16, -- aim = belief: opponents sampled from the belief for a read's best response
			timeFloor = 0.05, -- chance a reader allows that a commit's timing breaks the assumed script
			-- Each cue on (1) or off (0), for the per-cue report.
			cues = { color = 1, stance = 1, timing = 1, hit = 1, heal = 1, unleash = 1 },
		},

		-- ── RIDERS: scripted rider parameters (§11 *Sim plan* step 2), set by the sim ──────────
		--   read        chance to read on a pass: switch late to the best aim against the opponent's
		--   hold        hold discipline: 1 commits a stance at the first moment, 0 at the decision window
		--   honesty     stance honesty: chance the stance leans toward your loaded stats (else a random aim)
		--   aggression  raise tendency, and chance to unleash a trick at the first chance vs hold it
		--   design      chance to play an unleashed trick to its design (hold the straight, aim the flush home)
		--   yieldBelow  Yield when facing a raise with betting strength below this (−1: never Yield)
		--   raiseAt     the betting rider (switches.betting = "bands"), per bet 1–4: raise or re-raise
		--               when the rider's odds of winning (sim/Odds.luau) are at least this
		--   yieldAt     ...and, facing a raise, Yield when they are below this (0: never Yield)
		--   readSkill   how much each cue moves the reader's belief: 1 exact Bayes, 0 learns nothing
		--               (0091). Used only when the reading model is on (reading.aim or reading.betting)
		riders = {
			average = { read = 0.3, hold = 0.6, honesty = 0.7, aggression = 0.5, design = 0.8, yieldBelow = -1, raiseAt = { 0.6, 0.6, 0.6, 0.6 }, yieldAt = { 0.25, 0.25, 0.25, 0.25 }, readSkill = 0.5 },
			skilled = { read = 0.7, hold = 0.9, honesty = 0.9, aggression = 0.5, design = 1.0, yieldBelow = -1, raiseAt = { 0.6, 0.6, 0.6, 0.6 }, yieldAt = { 0.25, 0.25, 0.25, 0.25 }, readSkill = 0.9 },
			novice = { read = 0.05, hold = 0.3, honesty = 0.4, aggression = 0.5, design = 0.5, yieldBelow = -1, raiseAt = { 0.6, 0.6, 0.6, 0.6 }, yieldAt = { 0.25, 0.25, 0.25, 0.25 }, readSkill = 0.1 },
			holder = { read = 0.0, hold = 1.0, honesty = 1.0, aggression = 0.5, design = 1.0, yieldBelow = -1, raiseAt = { 0.6, 0.6, 0.6, 0.6 }, yieldAt = { 0.25, 0.25, 0.25, 0.25 }, readSkill = 0.0 },
			flicker = { read = 1.0, hold = 0.0, honesty = 0.5, aggression = 0.5, design = 0.5, yieldBelow = -1, raiseAt = { 0.6, 0.6, 0.6, 0.6 }, yieldAt = { 0.25, 0.25, 0.25, 0.25 }, readSkill = 0.5 },
		},

		-- ── SWITCHES: open questions and gaps, each with 2–3 readings ─────────────────────────
		switches = {
			-- Answered by Trey (0057–0061): the default is GAME_SPEC; the other readings stay for comparison.
			slowmo = "excluded", -- wall | game | excluded                       (0061)
			statBasis = "value", -- value | points: what ♦ and ♠ convert        (c1, 0057)
			flushHit = "F1", -- F1 per-rung hit × home factor | F2 exploded stat (c3, 0059)
			meterThreshold = "reachable", -- reachable | strict                  (c4, 0060)
			-- How the hand ends when no one is unhorsed after Pass 4 (docs/sim/SHOWDOWN.md prototypes).
			-- "bonus" is GAME_SPEC (0050); the rest are proposals, off by default.
			--   bonus     +showdownBonus Posture per category step, the lower rider falls
			--   mult      Posture × (1 + proto.mult × steps), the lower rider falls
			--   riverHit  the hand strikes on Pass 4: proto.riverPerStep per step lands on the opponent
			--             at contact, scaled by the tier your own strike lands (proto.riverTier); then the
			--             lower rider on Posture alone falls
			--   charge    cards up and one more contact (the final charge); proto.charge* set it
			showdown = "bonus", -- bonus | mult | riverHit | charge
			-- Pass 4's contact (0053): "knockdown" is GAME_SPEC. No one is unhorsed on Pass 4's contact; the
			-- hand's showdown effect lands on Posture, even below 0, and the lower rider falls. "unhorse" is
			-- the rule before 0053 (a rider at 0 falls on contact), kept for the SHOWDOWN.md prototypes.
			riverRule = "knockdown", -- knockdown | unhorse
			-- Posture in half hearts (0075): a hit's damage (and a reflect) rounds to the nearest half heart
			-- as it lands, and the ♥ heal rounds up; the showdown compares whole half hearts, and kickers
			-- break a level result. "exact" keeps fractional Posture, for comparison.
			posture = "pips", -- pips | exact
			healRound = "up", -- up | nearest: how the ♥ heal rounds
			-- How riders bet. "script" is the betting the sim has always used: strength() raises on an
			-- owned trick or trips with a Posture lead, and riders never Yield (yieldBelow = −1), so pots
			-- are artifacts (docs/sim/RESULTS.md, *Betting*). "bands" is the betting rider: raise and
			-- Yield on its odds of winning, by the raiseAt and yieldAt bands of each rider profile.
			betting = "script", -- script | bands
			-- Where a prefold's units go (0078): "carry" rides into the rider's next match's pot, and that
			-- match's winner takes both riders' carry. "purse" (pooled, at its average) and "sink" (the
			-- house) are for comparison. Used by --report yard.
			prefold = "carry", -- carry | purse | sink
		},

		-- ── PROTO: values the showdown prototypes use (SHOWDOWN.md). None is a §11 value. ─────
		proto = {
			mult = 0.2, -- mult: Posture × (1 + mult × steps)
			riverPerStep = 8, -- riverHit: Posture per step, before the tier factor
			riverTier = { crit = 1.5, normal = 1.0, block = 0.25, weak = 0.25 }, -- riverHit: by the tier you land
			riverKnockdown = "posture", -- riverHit: posture | bonus — what decides if no one falls
			riverVsTrick = "lands", -- riverHit: lands | warded — a rider firing a trick takes the blow, or not
			chargeStreet = 1.625, -- charge: the fifth contact's multiplier (Pass 4's before 0054: 1.25 × 1.3)
			chargeBonus = "posture", -- charge: posture (bonus lands before it) | none | hit (as riverHit, on the charge)
			chargeCardsUp = "yes", -- charge: yes | no — readers see the opponent's exact stats
			-- The turn cushion (Trey's ramp idea, chat 2026-09-30): on Pass 3 a rider is unhorsed only below
			-- −(turnCushion × showdownBonus × turn category), so the cards start to count on the turn.
			-- Hidden: the bar is unchanged. 0 is off.
			turnCushion = 0,
		},
	}
end

-- Override one value by dotted path. Numbers parse as numbers, everything else stays a string.
function Config.set(cfg: any, path: string, raw: string)
	local node = cfg
	-- A numeric key indexes a list: spec.street.3 is Pass 3's street multiplier.
	local keys: { any } = string.split(path, ".")
	for i, k in keys do
		keys[i] = tonumber(k) or k
	end
	for i = 1, #keys - 1 do
		node = node[keys[i]]
		if type(node) ~= "table" then
			error(string.format("config: no table at %q in %q", keys[i], path))
		end
	end
	local last = keys[#keys]
	if node[last] == nil then
		error(string.format("config: unknown key %q", path))
	end
	local asNumber = tonumber(raw)
	if type(node[last]) == "number" then
		if asNumber == nil then
			error(string.format("config: %q wants a number, got %q", path, raw))
		end
		node[last] = asNumber
	else
		node[last] = raw
	end
end

return Config
