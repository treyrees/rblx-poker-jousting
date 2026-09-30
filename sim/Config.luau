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
			postureStart = 100,
			base = { weak = 4, normal = 10, crit = 30 },
			statBase = 20, -- cardless floor, S_suit = 20 + points
			rankBase = 1, -- card value 1 + (r − 2) / 6
			rankSlope = 1 / 6,
			boardWeight = 0.5, -- "½ of a hole card; the sim tries lower"
			handMult = { pair = 2, twoPair = 2, trips = 3 },
			clubRate = 1 / 20, -- ♣ scales hits by S♣ / 20
			holdFloor = 0.25, -- hold multiplier 0.25 + 0.75·h (0052; the slope is 1 − floor)
			street = { 0.5, 0.75, 1.0, 1.25 },
			finalPassBonus = 1.3, -- last-pass bonus on Pass 4, on top of its street multiplier (0051)
			showdownBonus = 20, -- showdown: Posture per step of hand category (0050)
			cleanBlockRestore = 3,
			aimLock = 0.3,
			passLength = 8.0,
			-- Standard dial, half steps from aim: E exposure, O ordinary, G Guard.
			layout = "EEEEEOOOGOGGGOOO",
			queenRestore = { hole = 6, board = 3 },
			kingLock = { hole = 0.15, board = 0.08 },
			aceCrit = { hole = 35, boardBonus = 2 },
			fortressGuardDirections = 7,
			heldPassive = { straight = 3, flush = 4, fullHouse = 4, quads = 4 },
			raise = { 1, 1, 2, 2 }, -- before Passes 1–4
			ante = 1,
			-- §5 pocket pairs
			qqRestore = 10,
			qqFloor = 20,
			kkLock = 0.3,
			kkGuardHalve = 0.5,
			aaCrit = 40,
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
			heartPosture = 3, -- Posture per unleaned ♥ point
			heartCut = 0.5, -- damage cut per leaned ♥ point (the lean's extra points)
			armorRate = 0.25, -- armor per ♦ stat unit (see switches.statBasis)
			armorZone = { guard = 1.0, ordinary = 0.2, exposure = 0.05 },
			pierceRate = 0.05, -- piercing per ♠ stat unit
			chargeRate = 3, -- charge banked per non-crit hit, × S♠ / 20
			blockBase = 10, -- SANITY_CHECK (c2): a Block reads as a Normal into thick armor
			earliestCommit = 0.3, -- the earliest a rider leaves Neutral (s)
			readTime = 7.4, -- when a read's late switch lands (s)
			-- Trick hits and wards per rung (SANITY_CHECK §2: a chain that meets §6). A hit must
			-- unhorse from the earliest pass a trick can fire on (Pass 2, ×0.75); a ward must stop
			-- lower hits on Pass 4 (×1.25 × the last-pass bonus).
			-- The straight's hit is the meter: straightK · straightX ^ y.
			straightK = 100,
			straightX = 1.3,
			hit = { flush = 600, fullHouse = 13000, quads = 20000, straightFlush = 60000 },
			ward = { straight = 0, flush = 6500, fullHouse = 9000, quads = 22000, straightFlush = 33000 },
			flushExplode = 4, -- flush suit's S × this at home (× half on the diagonals beside it)
			flushExplodeF2 = 60, -- the explosion when switches.flushHit = "F2"
		},

		-- ── RIDERS: scripted rider parameters (§11 *Sim plan* step 2), set by the sim ──────────
		--   read        chance to read on a pass: switch late to the best aim against the opponent's
		--   hold        hold discipline: 1 commits a stance at the first moment, 0 at the decision window
		--   honesty     stance honesty: chance the stance leans toward your loaded stats (else a random aim)
		--   aggression  raise tendency, and chance to unleash a trick at the first chance vs hold it
		--   design      chance to play an unleashed trick to its design (hold the straight, aim the flush home)
		--   yieldBelow  Yield when facing a raise with betting strength below this (−1: never Yield)
		riders = {
			average = { read = 0.3, hold = 0.6, honesty = 0.7, aggression = 0.5, design = 0.8, yieldBelow = -1 },
			skilled = { read = 0.7, hold = 0.9, honesty = 0.9, aggression = 0.5, design = 1.0, yieldBelow = -1 },
			novice = { read = 0.05, hold = 0.3, honesty = 0.4, aggression = 0.5, design = 0.5, yieldBelow = -1 },
			holder = { read = 0.0, hold = 1.0, honesty = 1.0, aggression = 0.5, design = 1.0, yieldBelow = -1 },
			flicker = { read = 1.0, hold = 0.0, honesty = 0.5, aggression = 0.5, design = 0.5, yieldBelow = -1 },
		},

		-- ── SWITCHES: open questions and gaps, each with 2–3 readings ─────────────────────────
		switches = {
			slowmo = "wall", -- wall | game | excluded                           (§11 open)
			statBasis = "value", -- value | points: what ♦ and ♠ convert        (c1)
			flushHit = "F1", -- F1 per-rung hit × home factor | F2 exploded stat (c3)
			meterThreshold = "reachable", -- reachable | strict                  (c4)
			twinFavorVsTrick = "negates", -- negates | trickOverrides            (C1)
			aaEdge = "one", -- one | both | direction                            (C2)
			-- How the hand ends when no one is unhorsed after Pass 4 (docs/sim/SHOWDOWN.md prototypes).
			-- "bonus" is GAME_SPEC (0050); the rest are proposals, off by default.
			--   bonus     +showdownBonus Posture per category step, the lower rider falls
			--   mult      Posture × (1 + proto.mult × steps), the lower rider falls
			--   riverHit  the hand strikes on Pass 4: proto.riverPerStep per step lands on the opponent
			--             at contact, scaled by the tier your own strike lands (proto.riverTier); then the
			--             lower rider on Posture alone falls
			--   charge    cards up and one more contact (the final charge); proto.charge* set it
			showdown = "bonus", -- bonus | mult | riverHit | charge
			-- Pass 4's contact (Trey, chat, 2026-09-30; GAME_SPEC not yet updated). "unhorse" is GAME_SPEC:
			-- a rider at 0 falls on contact and the bonus never lands. "knockdown": no one is unhorsed on
			-- Pass 4's contact; the hand's showdown effect always lands, then the lower rider falls.
			riverRule = "unhorse", -- unhorse | knockdown
			riverFloor = "below", -- knockdown: below | zero | before — under 0 counts, counts as 0, or (both lanced) Posture before Pass 4 (gap)
		},

		-- ── PROTO: values the showdown prototypes use (SHOWDOWN.md). None is a §11 value. ─────
		proto = {
			mult = 0.2, -- mult: Posture × (1 + mult × steps)
			riverPerStep = 20, -- riverHit: Posture per step, before the tier factor
			riverTier = { crit = 1.5, normal = 1.0, block = 0.25, weak = 0.25 }, -- riverHit: by the tier you land
			riverKnockdown = "posture", -- riverHit: posture | bonus — what decides if no one falls
			riverVsTrick = "lands", -- riverHit: lands | warded — a rider firing a trick takes the blow, or not
			chargeStreet = 1.625, -- charge: the fifth contact's multiplier (Pass 4's is 1.25 × 1.3)
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
