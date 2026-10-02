--!strict
-- Contact.spec.luau — contact resolution (GAME_SPEC §4), with the §6 rules that act at contact.

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Contact = require("../sim/Contact")

local function fighter(o: any): Contact.Fighter
	return {
		aim = o.aim,
		h = o.h or 1,
		S = o.S or { 20, 20, 20, 20 },
		buffer = o.buffer or 0,
		battered = o.battered or 0,
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
	kit.it("Pass 1 Normal, high card, half hold: 10 × 1.0 × 0.625 × 1.0 = 6.25", function()
		local s = Contact.strike(fighter({ aim = 9, h = 0.5 }), fighter({ aim = 0 }), arena(cfg.spec.street[1]), cfg)
		kit.expectEqual(s.tier, "normal")
		kit.expectNear(s.dmg, 6.25)
	end)
	kit.it("Pass 3 Crit, trips-loaded ♣ (×1.45), full hold: about 43", function()
		local s = Contact.strike(fighter({ aim = 1, S = { 29, 20, 20, 20 } }), fighter({ aim = 0 }), arena(1.0), cfg)
		kit.expectEqual(s.tier, "crit")
		kit.expectNear(s.dmg, 43.5)
	end)
	kit.it("Pass 4 Crit with the same: about 54", function()
		local s = Contact.strike(fighter({ aim = 1, S = { 29, 20, 20, 20 } }), fighter({ aim = 0 }), arena(cfg.spec.street[4]), cfg)
		kit.expectNear(s.dmg, 30 * 1.45 * 1.25)
	end)
end)

kit.describe("Contact: steps 4–6", function()
	local cfg = Config.defaults()
	kit.it("a Block nothing gets through is a clean block", function()
		-- A switched late (h = 0): 10 × 0.25 × 0.5 = 1.25 into Guard armor 0.25 × 20 = 5, less 1 pierce.
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
	kit.it("♠ lets a late crit keep more power (0069); a Normal gets no relief", function()
		local plain = Contact.strike(fighter({ aim = 1, h = 0 }), fighter({ aim = 0 }), arena(1), cfg)
		local sharp = Contact.strike(fighter({ aim = 1, h = 0, S = { 20, 40, 20, 20 } }), fighter({ aim = 0 }), arena(1), cfg)
		-- Crit at h = 0: hold 0.25, relieved by critRelief per ♠ point of the shortfall (none when
		-- cardless); ♠ also scales the crit.
		local function crit(sp: number): number
			local hold = 0.25 + 0.75 * math.clamp(cfg.sim.critRelief * (sp - 20), 0, 1)
			return 30 * hold * sp / 20
		end
		local armorOf = cfg.sim.armorRate * 20 * cfg.sim.armorZone.exposure
		kit.expectNear(plain.dmg, crit(20) - math.max(0, armorOf - cfg.sim.pierceRate * 20))
		kit.expectNear(sharp.dmg, crit(40) - math.max(0, armorOf - cfg.sim.pierceRate * 40))
		local n = Contact.strike(fighter({ aim = 9, h = 0, S = { 20, 60, 20, 20 } }), fighter({ aim = 0 }), arena(1), cfg)
		local n0 = Contact.strike(fighter({ aim = 9, h = 0 }), fighter({ aim = 0 }), arena(1), cfg)
		kit.expectTrue(n.dmg >= n0.dmg) -- only piercing differs on a Normal
	end)
	kit.it("♦ lets a late Guard block harder (0069)", function()
		local plain = Contact.strike(fighter({ aim = 8, S = { 60, 20, 20, 20 } }), fighter({ aim = 0, h = 0 }), arena(1), cfg)
		local armored = Contact.strike(fighter({ aim = 8, S = { 60, 20, 20, 20 } }), fighter({ aim = 0, h = 0, S = { 20, 20, 20, 21 } }), arena(1), cfg)
		local relief = Contact.strike(fighter({ aim = 8, S = { 60, 20, 20, 20 } }), fighter({ aim = 0, h = 1, S = { 20, 20, 20, 21 } }), arena(1), cfg)
		kit.expectTrue(armored.dmg < plain.dmg)
		kit.expectTrue(relief.dmg < armored.dmg)
	end)
	kit.it("Battered raises what gets through by its share (0068)", function()
		local a = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0 }), arena(1), cfg)
		local b = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0, battered = 0.25 }), arena(1), cfg)
		kit.expectNear(b.dmg, a.dmg * 1.25)
		kit.expectNear(b.through, a.through)
	end)
	kit.it("♠ pierces armor on every hit, crits included", function()
		local lo = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0, S = { 20, 20, 20, 60 } }), arena(1), cfg)
		local hi = Contact.strike(fighter({ aim = 7, S = { 20, 40, 20, 20 } }), fighter({ aim = 0, S = { 20, 20, 20, 60 } }), arena(1), cfg)
		kit.expectTrue(hi.dmg > lo.dmg)
	end)
	kit.it("the ♥ buffer absorbs the Posture damage first (0070)", function()
		local a = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0 }), arena(1), cfg)
		local b = Contact.strike(fighter({ aim = 7 }), fighter({ aim = 0, buffer = 2 }), arena(1), cfg)
		kit.expectNear(a.dmg - b.dmg, 2)
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
