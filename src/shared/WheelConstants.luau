--!strict
-- WheelConstants.luau — the aim wheel's feel. The Magnet preset, borrowed from rblx-joust-tourney,
-- branch claude/ring-spin-ui-feel-xpatk4, src/shared/Constants.luau (Constants.WHEEL), value for
-- value. Only the notch count is this game's: the standard dial's 16 aim positions (GAME_SPEC §3),
-- each a spring notch, with the 8 directions labeled (0104). The spring and damping were tuned on 8
-- notches a revolution; on 16 each notch is half the angle, which the playtest judges.

local WheelConstants = {}

-- Notches a revolution: GAME_SPEC §3's 16 aim positions (sim/Dial.luau, Dial.POSITIONS).
WheelConstants.POSITIONS = 16

WheelConstants.MAGNET = {
	-- While the finger is down, the needle is biased toward the nearest notch by this fraction:
	-- 0 is a free glide, 1 is a fully quantized click-wheel.
	DETENT = 0.45,
	-- On release the needle beds into the nearest notch under a per-notch spring potential
	-- (torque = -STIFFNESS * sin(2*pi*theta) / 2*pi) with viscous damping.
	STIFFNESS = 180,
	DAMPING = 14, -- applied while settling into a notch
	FRICTION = 3, -- applied instead of DAMPING while spinning from a flick
	-- Release speeds below FLICK_MIN (notches/second) snap straight back instead of spinning; the
	-- release speed itself is the median over the last FLICK_WINDOW seconds of drag.
	FLICK_MIN = 0.6,
	FLICK_WINDOW = 0.09,
	-- Above SPIN_OMEGA the wheel is "spinning" (FRICTION governs); below it, "settling" (DAMPING).
	SPIN_OMEGA = 0.5,
	-- Close enough to call it landed: the needle clamps exactly onto the notch.
	SETTLE_OMEGA = 0.02,
	SETTLE_DIST = 0.002,
	-- Integration guards: clamp a hitchy frame, sub-step so high stiffness stays stable.
	MAX_DT = 0.032,
	SUBSTEP = 0.004,
}

return WheelConstants
