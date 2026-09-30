--!strict
-- Contact.spec.luau — contact resolution (GAME_SPEC §4), with the §5 and §6 rules that act at contact.

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Contact = require("../sim/Contact")

local function fighter(o: any): Contact.Fighter
	return {
		aim = o.aim,
		h = o.h or 1,
		S = o.S or { 20, 20, 20, 20 },
		heartCut = o.cut or 0,
		critBase = o.critBase or 30,
		aa = o.aa or false,
		kk = o.kk or false,
		charge = o.charge or 0,
		trick = o.trick,
		ward = o.ward or 0,
	}
end

local function arena(street: number): Contact.Arena
	return { street = street, openLists = 1, siege = 1 }
end

kit.describe("Contact: §4 sanity checks (lean off, no armor, no piercing)", function()
	local cfg = Config.defaults()
	cfg.sim.armorRate = 0
	cfg.sim.pierceRate = 0
	kit.it("Pass 1 Normal, high card, half hold: 10 × 1.0 × 0.7 × 0.5 = 3.5", function()
		local s = Contact.strike(fighter({ aim = 9, h = 0.5 }), fighter({ aim = 0 }), arena(0.5), cfg)
		kit.expectEqual(s.tier, "normal")
		kit.expectNear(s.dmg, 3.5)
	end)
	kit.it("Pass 3 Crit, trips-loaded ♣ (×1.45), full hold: about 43", function()
		local s = Contact.strike(fighter({ aim = 1, S = { 29, 20, 20, 20 } }), fighter({ aim = 0 }), arena(1.0), cfg)
		kit.expectEqual(s.tier, "crit")
		kit.expectNear(s.dmg, 43.5)
	end)
	kit.it("Pass 4 Crit with the same, with the last-pass bonus: about 71", function()
		local street = cfg.spec.street[4] * cfg.spec.finalPassBonus
		local s = Contact.strike(fighter({ aim = 1, S = { 29, 20, 20, 20 } }), fighter({ aim = 0 }), arena(street), cfg)
		kit.expectNear(s.dmg, 30 * 1.45 * 1.25 * 1.3)
	end)
end)

kit.describe("Contact: steps 4–6", function()
	local cfg = Config.defaults()
	kit.it("a Block nothing gets through is a clean block", function()
		-- A switched late (h = 0): 10 × 0.4 × 0.5 = 2 into Guard armor 0.25 × 20 = 5, less 1 pierce.
		local s = Contact.strike(fighter({ aim = 8, h = 0 }), fighter({ aim = 0 }), arena(0.5), cfg)
		kit.expectEqual(s.tier, "block")
		kit.expectEqual(s.dmg, 0)
		kit.expectTrue(s.cleanBlock)
	end)
	kit.it("Guard armor scales with the defender's hold", function()
		local held = Contact.strike(fighter({ aim = 8 }), fighter({ aim = 0, h = 1 }), arena(1), cfg)
		local flicked = Contact.strike(fighter({ aim = 8 }), fighter({ aim = 0, h = 0 }), arena(1), cfg)
		kit.expectTrue(flicked.dmg > held.dmg)
	end)
	kit.it("Normal and Block build ♠ charge; a Crit spends it at this pass's street", function()
		local n = Contact.strike(fighter({ aim = 9 }), fighter({ aim = 0 }), arena(0.5), cfg)
		kit.expectNear(n.chargeGain, cfg.sim.chargeRate)
		kit.expectFalse(n.chargeSpent)
		local plain = Contact.strike(fighter({ aim = 1 }), fighter({ aim = 0 }), arena(1.25), cfg)
		local charged = Contact.strike(fighter({ aim = 1, charge = 6 }), fighter({ aim = 0 }), arena(1.25), cfg)
		kit.expectTrue(charged.chargeSpent)
		kit.expectNear(charged.dmg - plain.dmg, 6 * 1.25)
	end)
	kit.it("♠ pierces armor on every hit, crits included", function()
		local lo = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0, S = { 20, 20, 20, 60 } }), arena(1), cfg)
		local hi = Contact.strike(fighter({ aim = 7, S = { 20, 40, 20, 20 } }), fighter({ aim = 0, S = { 20, 20, 20, 60 } }), arena(1), cfg)
		kit.expectTrue(hi.dmg > lo.dmg)
	end)
	kit.it("a ♥ lean cuts the Posture damage taken", function()
		local a = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0 }), arena(1), cfg)
		local b = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0, cut = 2 }), arena(1), cfg)
		kit.expectNear(a.dmg - b.dmg, 2)
	end)
	kit.it("KK halves what gets through the Guard", function()
		local a = Contact.strike(fighter({ aim = 8, S = { 60, 20, 20, 20 } }), fighter({ aim = 0 }), arena(1), cfg)
		local b = Contact.strike(fighter({ aim = 8, S = { 60, 20, 20, 20 } }), fighter({ aim = 0, kk = true }), arena(1), cfg)
		kit.expectTrue(a.dmg > 0)
		kit.expectNear(b.dmg, a.dmg / 2)
	end)
	kit.it("AA's edge notch turns a Normal one half step past the exposure into a Crit (C2 = one)", function()
		kit.expectEqual(Contact.strike(fighter({ aim = 5, aa = true }), fighter({ aim = 0 }), arena(1), cfg).tier, "crit")
		kit.expectEqual(Contact.strike(fighter({ aim = 6, aa = true }), fighter({ aim = 0 }), arena(1), cfg).tier, "normal")
	end)
end)

kit.describe("Contact: §6 unleash-pass rules", function()
	local cfg = Config.defaults()
	kit.it("Four Lances parry a lower strike: it deals nothing", function()
		local q = fighter({ aim = 0, trick = { rung = 4, key = "quads", hit = 20000, numeric = false } })
		local s = Contact.strike(fighter({ aim = 1, S = { 60, 20, 20, 20 } }), q, arena(1.25), cfg)
		kit.expectTrue(s.parried)
		kit.expectEqual(s.dmg, 0)
	end)
	kit.it("Fortress: every position is Guard but the gap direction, where a hit is a Crit", function()
		local fh = fighter({ aim = 0, trick = { rung = 3, key = "fullHouse", hit = 13000, numeric = false, fortressGap = 6 } })
		kit.expectEqual(Contact.strike(fighter({ aim = 6 }), fh, arena(1), cfg).tier, "crit")
		kit.expectEqual(Contact.strike(fighter({ aim = 7 }), fh, arena(1), cfg).tier, "crit")
		kit.expectEqual(Contact.strike(fighter({ aim = 1 }), fh, arena(1), cfg).tier, "block")
	end)
	kit.it("the straight flush has no exposure", function()
		local sf = fighter({ aim = 0, trick = { rung = 5, key = "straightFlush", hit = 1, numeric = false } })
		kit.expectEqual(Contact.strike(fighter({ aim = 1 }), sf, arena(1), cfg).tier, "normal")
	end)
	kit.it("a lower trick's hit can't get through a higher ward; the ward ignores numeric hits", function()
		local straight = fighter({ aim = 7, trick = { rung = 1, key = "straight", hit = 3000, numeric = false } })
		local warded = fighter({ aim = 0, ward = 6000 })
		kit.expectEqual(Contact.strike(straight, warded, arena(1.25), cfg).dmg, 0)
		local numeric = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0 }), arena(1), cfg)
		local numericWarded = Contact.strike(fighter({ aim = 7 }), warded, arena(1), cfg)
		kit.expectEqual(numericWarded.dmg, numeric.dmg)
	end)
	kit.it("Gilded Mirror armors the whole dial and reflects what it stops", function()
		local mirror = fighter({ aim = 0, trick = { rung = 2, key = "flush", hit = 600, numeric = false, suit = 4 } })
		local open = Contact.strike(fighter({ aim = 1 }), fighter({ aim = 0 }), arena(1), cfg)
		local s = Contact.strike(fighter({ aim = 1 }), mirror, arena(1), cfg)
		kit.expectTrue(s.dmg < open.dmg)
		kit.expectTrue(s.reflect > 0)
	end)
end)
