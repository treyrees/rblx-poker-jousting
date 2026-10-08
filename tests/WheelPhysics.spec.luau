--!strict
-- WheelPhysics.spec.luau — pins the wheel's feel model. Borrowed from rblx-joust-tourney, branch
-- claude/ring-spin-ui-feel-xpatk4, tests/WheelPhysics.spec.luau, with the tourney's direction words
-- replaced by GAME_SPEC §3's aim positions: Neutral is the default, the state is always one of the
-- 16 positions or Neutral, a release settles exactly onto a position, a lift-off below the flick
-- gate snaps back, and a flick rolls over positions before the spring catches it.

local kit = require("./lib/testkit")
local WheelConstants = require("../src/shared/WheelConstants")
local WheelPhysics = require("../src/shared/WheelPhysics")
local Dial = require("../sim/Dial")

local W = WheelConstants.MAGNET

local function settle(wheel): number
	for frame = 1, 1200 do
		wheel:step(1 / 60)
		if wheel.omega == 0 and wheel.theta == math.round(wheel.theta) then
			return frame
		end
	end
	error("wheel did not settle within 1200 frames (omega=" .. wheel.omega .. ", theta=" .. wheel.theta .. ")")
end

kit.describe("WheelPhysics", function()
	kit.it("has one notch per aim position of the standard dial (§3)", function()
		kit.expectEqual(WheelConstants.POSITIONS, Dial.POSITIONS)
	end)
	kit.it("starts in Neutral and leaves it on the first touch", function()
		local wheel = WheelPhysics.new()
		kit.expectEqual(wheel.neutral, true)
		kit.expectEqual(wheel:position(), nil)
		wheel:beginDrag(2.3, 0)
		kit.expectEqual(wheel.neutral, false)
		kit.expectNear(wheel.theta, 2.3)
		kit.expectEqual(wheel:position(), 2)
	end)
	kit.it("the hub returns the wheel to Neutral", function()
		local wheel = WheelPhysics.new()
		wheel:beginDrag(5, 0)
		wheel:endDrag()
		wheel:setNeutral()
		kit.expectEqual(wheel:position(), nil)
		kit.expectEqual(wheel.theta, 0)
	end)
	kit.it("a slow lift-off settles exactly onto the nearest position", function()
		local wheel = WheelPhysics.new()
		wheel:beginDrag(3.0, 0)
		wheel:drag(3.2, 0.5) -- far too slow to be a flick
		wheel:endDrag()
		kit.expectEqual(wheel.omega, 0)
		settle(wheel)
		kit.expectEqual(wheel.theta, 3)
		kit.expectEqual(wheel:position(), 3)
	end)
	kit.it("a flick rolls over positions, then the spring catches it on one", function()
		local wheel = WheelPhysics.new()
		wheel:beginDrag(0, 0)
		local t = 0
		for i = 1, 6 do
			t += 0.012
			wheel:drag(i * 0.5, t) -- about 40 notches a second
		end
		wheel:endDrag()
		kit.expectTrue(math.abs(wheel.omega) > W.FLICK_MIN, "a fast release should spin")
		local start = wheel.theta
		settle(wheel)
		kit.expectTrue(wheel.theta - start >= 1, "the flick should pass at least one position")
		kit.expectEqual(wheel.theta, math.round(wheel.theta))
	end)
	kit.it("the state is always a whole position, wrapping around the sweep", function()
		local wheel = WheelPhysics.new()
		wheel:beginDrag(15.6, 0)
		kit.expectEqual(wheel:position(), 0)
		wheel:drag(0.1, 1.0)
		wheel:endDrag()
		settle(wheel)
		kit.expectEqual(wheel:position(), 0)
	end)
end)
