--!strict
-- Contact.luau — contact resolution (GAME_SPEC §4 *Contact resolution*, steps 1–6), with the §6
-- unleash-pass rules that act at contact. Both directions resolve from the same pre-contact state
-- (simultaneous). Step 7 (the heal and a new Battered) is after contact, in Hand.

local Dial = require("./Dial")
local Timeline = require("./Timeline")

local Contact = {}

-- One rider at contact. Built by Hand from cards, aim and hold.
export type Fighter = {
	aim: number?,
	h: number,
	S: { number }, -- stat values S = 20 + leaned points (♥ is unleaned; its lean is the buffer)
	buffer: number, -- §4 step 6: the ♥ buffer, absorbs this contact's damage first (0070)
	battered: number, -- §4 step 6: extra share of damage taken (0068), 0 if not Battered
	-- Set on the pass a trick fires (unleashed or answering) and doesn't clash:
	trick: {
		rung: number,
		key: string,
		hit: number, -- before the street multiplier
		numeric: boolean, -- flush under reading F2: the hit is the numeric strike, exploded
		suit: number?,
		fortressGap: number?, -- full house: absolute aim position of the gap direction
	}?,
	ward: number, -- §6 *The ward*: armor against trick hits only
}

export type Arena = {
	street: number,
	openLists: number, -- numeric Posture damage × (board straight), else 1
	siege: number, -- numeric output × (board full house), else 1
}

export type Strike = {
	tier: string,
	dmg: number, -- Posture damage to the defender
	reflect: number, -- Gilded Mirror: damage back to the striker
	cleanBlock: boolean,
	through: number, -- what got through armor and ward, before Battered and the buffer
	trickHit: boolean,
	parried: boolean,
}

local function basis(S: number, cfg: any): number
	local mode = cfg.switches.statBasis
	if mode == "value" then
		return S
	elseif mode == "points" then
		return S - cfg.spec.statBase
	end
	error("unknown statBasis " .. mode)
end

-- Easier crits and blocks (0069): the stat restores part of the hold multiplier's shortfall.
local function relieved(m: number, rate: number, S: number, cfg: any): number
	return m + (1 - m) * math.min(1, rate * S / cfg.spec.statBase)
end

local ZONE = { crit = "exposure", normal = "ordinary", weak = "ordinary", block = "guard" }

local function rungOf(f: Fighter): number
	return if f.trick then f.trick.rung else 0
end

-- A strikes B.
function Contact.strike(A: Fighter, B: Fighter, arena: Arena, cfg: any): Strike
	local spec, sim = cfg.spec, cfg.sim
	local aTrick, bTrick = A.trick, B.trick
	local aRung, bRung = rungOf(A), rungOf(B)
	-- Where two tricks' rules contradict, the higher trick's rule wins (§6 *Trick vs trick*).
	-- A defender's trick rule applies against a striker below it on the ladder.
	local bRuleHolds = bTrick ~= nil and aRung < bRung
	local aRuleHolds = aTrick ~= nil and aRung > bRung

	-- Four Lances: "The lances parry their strike: it deals nothing."
	if bRuleHolds and (bTrick :: any).key == "quads" then
		return { tier = "parried", dmg = 0, reflect = 0, cleanBlock = false, through = 0, trickHit = aTrick ~= nil, parried = true }
	end

	-- Step 1: the tier.
	local tier = Dial.tier(A.aim, B.aim, spec)
	if bRuleHolds and (bTrick :: any).key == "fullHouse" and A.aim ~= nil then
		-- Fortress: Guard on every position but the gap direction (2 of 16 half steps); a hit there is a Crit.
		local gap = (bTrick :: any).fortressGap
		local d = (A.aim - gap) % 16
		tier = if d <= 1 then "crit" else "block"
	elseif bRuleHolds and (bTrick :: any).key == "straightFlush" and tier == "crit" then
		tier = "normal" -- no exposure this pass
	end
	if aTrick and aTrick.key == "quads" then
		tier = "crit" -- any five positions of exposure hold a cardinal: one lance always crits
	end
	local needle = aTrick ~= nil and aTrick.key == "flush" and aTrick.suit == 2
	local shattering = aTrick ~= nil and aTrick.key == "flush" and aTrick.suit == 1
	if needle then
		tier = "crit" -- every hit you land is a Crit
	end

	-- Steps 2–4: output and the ♠ crit scale. ♠ also lets a crit reach full power with less hold.
	local trickHit = aTrick ~= nil
	local out: number
	local Sclub, Sspade = A.S[1], A.S[2]
	if aTrick and not aTrick.numeric then
		out = aTrick.hit * arena.street
	else
		local base = if tier == "crit"
			then spec.base.crit
			elseif tier == "normal" then spec.base.normal
			elseif tier == "block" then sim.blockBase
			else spec.base.weak
		local hold = Timeline.mult(A.h, cfg)
		if tier == "crit" then
			hold = relieved(hold, sim.critRelief, Sspade, cfg)
		end
		out = base * (Sclub * spec.clubRate) * hold * arena.street
		if not trickHit then
			out *= arena.siege
		end
		if tier == "crit" then
			out *= Sspade / spec.statBase
		end
	end

	-- Step 5: armor, less piercing. Gilded Mirror puts Guard armor over the whole dial.
	local mirror = bRuleHolds and (bTrick :: any).key == "flush" and (bTrick :: any).suit == 4
	local zone = if mirror then "guard" else ZONE[tier]
	local armor = sim.armorRate * basis(B.S[4], cfg) * sim.armorZone[zone]
	if zone == "guard" then
		armor *= relieved(Timeline.mult(B.h, cfg), sim.guardRelief, B.S[4], cfg)
	end
	local pierce = sim.pierceRate * basis(Sspade, cfg)
	local effArmor = math.max(0, armor - pierce)
	-- Needle pierces all armor; Shattering Blow lands in full even into a Block. Against a higher
	-- trick, its rule wins the contradiction.
	if (needle or shattering) and bRung <= aRung then
		effArmor = 0
	end
	local ward = if trickHit then B.ward else 0
	local through = math.max(0, out - effArmor - ward)
	local cleanBlock = tier == "block" and through <= 0 and not trickHit
	local reflect = if mirror then math.min(out, effArmor) else 0

	-- Step 6: Battered raises what got through; the ♥ buffer absorbs first; then the arena's
	-- numeric Posture multiplier.
	local dmg = math.max(0, through * (1 + B.battered) - B.buffer)
	if not trickHit then
		dmg *= arena.openLists
	end
	return {
		tier = tier,
		dmg = dmg,
		reflect = reflect,
		cleanBlock = cleanBlock,
		through = through,
		trickHit = trickHit,
		parried = false,
	}
end

return Contact
