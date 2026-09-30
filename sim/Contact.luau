--!strict
-- Contact.luau — contact resolution (GAME_SPEC §4 *Contact resolution*, steps 1–6), with the §5
-- face effects and the §6 unleash-pass rules that act at contact. Both directions resolve from the
-- same pre-contact state (simultaneous).

local Dial = require("./Dial")
local Timeline = require("./Timeline")

local Contact = {}

-- One rider at contact. Built by Hand from cards, aim and hold.
export type Fighter = {
	aim: number?,
	h: number,
	S: { number }, -- stat values S = 20 + leaned points (♥ is unleaned; its lean is heartCut)
	heartCut: number, -- §4 step 6: damage cut this hit
	critBase: number,
	aa: boolean, -- AA Champion: Normal hits on the exposure's edge notch count as Crit (C2)
	kk: boolean, -- KK High Court: what gets through your Guard armor is halved
	charge: number,
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
	chargeGain: number,
	chargeSpent: boolean,
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

-- AA's edge notch (C2), in half steps from the defender's aim.
local EDGE = {
	one = { [5] = true },
	both = { [5] = true, [15] = true },
	direction = { [5] = true, [6] = true },
}

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
		return { tier = "parried", dmg = 0, reflect = 0, cleanBlock = false, chargeGain = 0, chargeSpent = false, trickHit = aTrick ~= nil, parried = true }
	end

	-- Step 1: the tier.
	local tier, k = Dial.tier(A.aim, B.aim, spec)
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
	if tier == "normal" and A.aa and k ~= nil and EDGE[cfg.switches.aaEdge][k] then
		tier = "crit"
	end
	local needle = aTrick ~= nil and aTrick.key == "flush" and aTrick.suit == 2
	local shattering = aTrick ~= nil and aTrick.key == "flush" and aTrick.suit == 1
	if needle then
		tier = "crit" -- every hit you land is a Crit
	end

	-- Steps 2–4: output, ♠ crit scale and charge.
	local trickHit = aTrick ~= nil
	local out: number
	local chargeGain, chargeSpent = 0, false
	local Sclub, Sspade = A.S[1], A.S[2]
	if aTrick and not aTrick.numeric then
		out = aTrick.hit * arena.street
	else
		local base = if tier == "crit"
			then A.critBase
			elseif tier == "normal" then spec.base.normal
			elseif tier == "block" then sim.blockBase
			else spec.base.weak
		out = base * (Sclub * spec.clubRate) * Timeline.mult(A.h, cfg) * arena.street
		if not trickHit then
			out *= arena.siege
		end
		if tier == "crit" then
			out = out * (Sspade / spec.statBase) + A.charge * arena.street
			chargeSpent = true
		elseif tier == "normal" or tier == "block" then
			chargeGain = sim.chargeRate * Sspade / spec.statBase
		end
	end

	-- Step 5: armor, less piercing. Gilded Mirror puts Guard armor over the whole dial.
	local mirror = bRuleHolds and (bTrick :: any).key == "flush" and (bTrick :: any).suit == 4
	local zone = if mirror then "guard" else ZONE[tier]
	local armor = sim.armorRate * basis(B.S[4], cfg) * sim.armorZone[zone]
	if zone == "guard" then
		armor *= Timeline.mult(B.h, cfg)
	end
	local pierce = sim.pierceRate * basis(Sspade, cfg)
	local effArmor = math.max(0, armor - pierce)
	-- Needle pierces all armor; Shattering Blow lands in full even into a Block. Against a higher
	-- trick, its rule wins the contradiction.
	if (needle or shattering) and bRung <= aRung then
		effArmor = 0
	end
	local ward = if trickHit then B.ward else 0
	local dmg = math.max(0, out - effArmor - ward)
	local cleanBlock = tier == "block" and dmg <= 0 and not trickHit
	if B.kk and tier == "block" then
		dmg *= spec.kkGuardHalve
	end
	local reflect = if mirror then math.min(out, effArmor) else 0

	-- Step 6: ♥ lean cut, then the arena's numeric Posture multiplier.
	dmg = math.max(0, dmg - B.heartCut)
	if not trickHit then
		dmg *= arena.openLists
	end
	return {
		tier = tier,
		dmg = dmg,
		reflect = reflect,
		cleanBlock = cleanBlock,
		chargeGain = chargeGain,
		chargeSpent = chargeSpent,
		trickHit = trickHit,
		parried = false,
	}
end

return Contact
