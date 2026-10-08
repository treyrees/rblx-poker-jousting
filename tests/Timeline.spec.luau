--!strict
-- Timeline.spec.luau — the hold meter's live reading (§3 *Held aim*), added for the playable slice.

local kit = require("./lib/testkit")
local Config = require("../sim/Config")
local Timeline = require("../sim/Timeline")

kit.describe("Timeline.holdAt", function()
	local cfg = Config.defaults()
	kit.it("reaches Timeline.hold at aim lock and stays there", function()
		for _, hasReveal in { false, true } do
			local lock = cfg.spec.timeline.lock
			kit.expectNear(Timeline.holdAt(2.0, lock, cfg, hasReveal), Timeline.hold(2.0, cfg, hasReveal))
			kit.expectNear(Timeline.holdAt(2.0, lock + 0.3, cfg, hasReveal), Timeline.hold(2.0, cfg, hasReveal))
		end
	end)
	kit.it("is 0 at the commit, grows with time, and Neutral holds nothing", function()
		kit.expectEqual(Timeline.holdAt(2.0, 2.0, cfg, false), 0)
		kit.expectTrue(Timeline.holdAt(2.0, 5.0, cfg, false) > Timeline.holdAt(2.0, 3.0, cfg, false))
		kit.expectEqual(Timeline.holdAt(nil, 5.0, cfg, true), 0)
	end)
	kit.it("slow motion doesn't count (0061): the meter stands still through it", function()
		local tl = cfg.spec.timeline
		kit.expectNear(Timeline.holdAt(1.0, tl.reveal, cfg, true), Timeline.holdAt(1.0, tl.slowEnd, cfg, true))
	end)
end)
