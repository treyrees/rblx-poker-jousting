--!strict
-- WheelPhysics.luau — the aim wheel's feel, as pure math (no Roblox APIs, so it runs headless under
-- Lune). Borrowed from rblx-joust-tourney, branch claude/ring-spin-ui-feel-xpatk4,
-- src/shared/WheelPhysics.luau. Changed here: the notch count is the standard dial's 16 aim
-- positions (GAME_SPEC §3, 0104) and the televised state is an aim position 0..15 (sim/Dial.luau's
-- numbering: 0 Up, 4 Out, 8 Down, 12 In) or nil for Neutral, in place of the tourney's direction words.
--
-- Angle is measured in NOTCH UNITS: theta 2.0 means the needle sits exactly on aim position 2.
-- Continuous (unwrapped) so a flick can wind past 16; callers quantize via position().
--
-- The model (the Magnet preset in WheelConstants):
--   * dragging — the needle follows the pointer 1:1, displayed with a detent bias toward the
--     nearest notch (DETENT).
--   * release — a per-notch spring potential plus viscous damping beds the needle into a notch; a
--     fast enough release (a flick) spins over notches under FRICTION until the spring catches it.
-- Callers supply timestamps ('now') rather than the module reading a clock, so specs are
-- deterministic.

local WheelConstants = require("./WheelConstants")

local W = WheelConstants.MAGNET
local N = WheelConstants.POSITIONS
local TAU = 2 * math.pi

local WheelPhysics = {}
WheelPhysics.__index = WheelPhysics

type Sample = { v: number, t: number }

export type WheelPhysics = typeof(setmetatable(
	{} :: {
		theta: number,
		omega: number,
		neutral: boolean,
		dragging: boolean,
		_samples: { Sample },
		_prevPointer: number,
		_prevT: number,
	},
	WheelPhysics
))

function WheelPhysics.new(): WheelPhysics
	return setmetatable({
		theta = 0,
		omega = 0,
		neutral = true, -- Neutral is the default state at the start of every pass (§3)
		dragging = false,
		_samples = {} :: { Sample },
		_prevPointer = 0,
		_prevT = 0,
	}, WheelPhysics)
end

-- Shortest signed distance from `from` to `to` on the N-notch circle, applied to `from`.
local function nearestWrap(from: number, to: number): number
	return from + ((to - from + N / 2) % N - N / 2)
end

-- Engage at the pointer's notch position (absolute steering: the needle goes where you touch,
-- taking the short way around).
function WheelPhysics.beginDrag(self: WheelPhysics, pointerNotch: number, now: number)
	self.dragging = true
	self.neutral = false
	self.omega = 0
	self.theta = nearestWrap(self.theta, pointerNotch)
	self._samples = {}
	self._prevPointer = pointerNotch
	self._prevT = now
end

function WheelPhysics.drag(self: WheelPhysics, pointerNotch: number, now: number)
	if not self.dragging then
		return
	end
	local delta = (pointerNotch - self._prevPointer + N / 2) % N - N / 2
	local dt = math.max(1e-3, now - self._prevT)
	self.theta += delta
	table.insert(self._samples, { v = delta / dt, t = now })
	-- keep only the flick window
	local keep = {}
	for _, s in self._samples do
		if now - s.t < W.FLICK_WINDOW then
			table.insert(keep, s)
		end
	end
	self._samples = keep
	self._prevPointer = pointerNotch
	self._prevT = now
end

-- Release: the flick velocity is the median of the recent samples, gated by FLICK_MIN so a plain
-- lift-off snaps back rather than drifting.
function WheelPhysics.endDrag(self: WheelPhysics)
	if not self.dragging then
		return
	end
	self.dragging = false
	local vs = {}
	for _, s in self._samples do
		table.insert(vs, s.v)
	end
	table.sort(vs)
	local omega = if #vs > 0 then vs[math.floor(#vs / 2) + 1] else 0
	if math.abs(omega) < W.FLICK_MIN then
		omega = 0
	end
	self.omega = omega
end

-- Tap the hub: back to Neutral (§3 *Layout*).
function WheelPhysics.setNeutral(self: WheelPhysics)
	self.neutral = true
	self.dragging = false
	self.omega = 0
	self.theta = 0
end

-- Advance the free physics (no-op while dragging or neutral). Call once per frame.
function WheelPhysics.step(self: WheelPhysics, dt: number)
	if self.dragging or self.neutral then
		return
	end
	dt = math.min(W.MAX_DT, dt)
	local spinning = math.abs(self.omega) > W.SPIN_OMEGA
	local c = if spinning then W.FRICTION else W.DAMPING
	local steps = math.ceil(dt / W.SUBSTEP)
	local h = dt / steps
	for _ = 1, steps do
		local torque = -W.STIFFNESS * math.sin(TAU * self.theta) / TAU - c * self.omega
		self.omega += torque * h
		self.theta += self.omega * h
	end
	local nearest = math.round(self.theta)
	if math.abs(self.omega) < W.SETTLE_OMEGA and math.abs(self.theta - nearest) < W.SETTLE_DIST then
		self.theta = nearest
		self.omega = 0
	end
end

-- The smooth angle to RENDER: while dragging, the raw angle biased toward the nearest notch by the
-- detent fraction. Display only; never sent to the server.
function WheelPhysics.displayTheta(self: WheelPhysics): number
	if not self.dragging or W.DETENT == 0 then
		return self.theta
	end
	local nearest = math.round(self.theta)
	return self.theta + (nearest - self.theta) * W.DETENT
end

-- The state the game uses: the aim position 0..N-1 (GAME_SPEC §3: the state is always one of the 16
-- aim positions or Neutral), or nil in Neutral.
function WheelPhysics.position(self: WheelPhysics): number?
	if self.neutral then
		return nil
	end
	return math.round(self:displayTheta()) % N
end

return WheelPhysics
