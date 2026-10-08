--!strict
-- Wheel.luau — the aim wheel on screen: the Magnet wheel's input and rendering. Borrowed from
-- rblx-joust-tourney, branch claude/ring-spin-ui-feel-xpatk4, src/client/WheelInput.client.luau
-- (construction, input capture and the render loop), changed to the standard dial (GAME_SPEC §3):
--   * 16 spring notches, one per aim position, with the 8 directions labeled and ticks between
--     (0104);
--   * Up at the top and the sweep clockwise, so Out is on the right and In on the left (0105);
--   * the ring shows the opponent's sectors projected onto it, so the needle reads directly as the
--     tier you would land (§3 *Layout*): red where you would crit, blue their Guard; the opponent's
--     aim is marked. Neutral opponent: no Guard, every hit Normal (§3 *Neutral*);
--   * tap the hub for Neutral.
-- The wheel reports its position; Main decides whether to send it (the client sends input only).

local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Shared = ReplicatedStorage:WaitForChild("Shared")
local WheelPhysics = require(Shared:WaitForChild("WheelPhysics"))
local WheelConstants = require(Shared:WaitForChild("WheelConstants"))
local Slice = require(Shared:WaitForChild("Slice"))
local Rules = ReplicatedStorage:WaitForChild("Rules")
local Dial = require(Rules:WaitForChild("Dial"))

local N = WheelConstants.POSITIONS
local DEG = 360 / N
local SIGN = if Slice.wheel.clockwise then 1 else -1

local COLOR = {
	ground = Color3.fromHex("201a11"),
	line = Color3.fromHex("3a3226"),
	dim = Color3.fromHex("9a8d72"),
	gold = Color3.fromHex("d9a441"),
	exposure = Color3.fromHex("b8452f"), -- you would crit
	guard = Color3.fromHex("6f94a9"), -- their Guard: a Block
	normal = Color3.fromHex("4a4134"),
}

local LAYOUT = {
	TRACK_RADIUS = 0.40,
	BAND_FRACTION = 0.115,
	LABEL_RADIUS = 0.485,
	HUB_SIZE = 0.21,
	CHIP = 0.06,
	DOT = 0.020,
	TICK = 0.012,
	DOT_ACTIVE = 0.034,
}

local Wheel = {}

export type WheelUI = {
	frame: Frame,
	position: () -> number?,
	reset: () -> (),
	setEnabled: (boolean) -> (),
	setOpponentAim: (number?) -> (),
}

local function round(inst: GuiObject)
	local corner = Instance.new("UICorner")
	corner.CornerRadius = UDim.new(1, 0)
	corner.Parent = inst
end

-- Aim position (continuous) → scale position in the wheel square.
local function onCircle(p: number, radius: number): UDim2
	local a = math.rad(SIGN * p * DEG)
	return UDim2.fromScale(0.5 + math.sin(a) * radius, 0.5 - math.cos(a) * radius)
end

-- `onPosition` fires whenever the wheel's position (0..15 or nil for Neutral) changes.
function Wheel.new(parent: GuiObject, cfg: any, onPosition: (number?) -> ()): WheelUI
	local wheel = WheelPhysics.new()
	local enabled = false
	local oppAim: number? = nil

	local frame = Instance.new("Frame")
	frame.Name = "Wheel"
	frame.AnchorPoint = Vector2.new(0.5, 0.5)
	frame.Position = UDim2.fromScale(0.5, 0.5)
	frame.Size = UDim2.fromScale(1, 1)
	frame.BackgroundTransparency = 1
	frame.Parent = parent
	local aspect = Instance.new("UIAspectRatioConstraint")
	aspect.AspectRatio = 1
	aspect.AspectType = Enum.AspectType.FitWithinMaxSize
	aspect.Parent = frame

	local track = Instance.new("Frame")
	track.Name = "Track"
	track.AnchorPoint = Vector2.new(0.5, 0.5)
	track.Position = UDim2.fromScale(0.5, 0.5)
	track.Size = UDim2.fromScale(LAYOUT.TRACK_RADIUS * 2, LAYOUT.TRACK_RADIUS * 2)
	track.BackgroundTransparency = 1
	track.ZIndex = 1
	track.Parent = frame
	round(track)
	local trackStroke = Instance.new("UIStroke")
	trackStroke.Color = COLOR.ground
	trackStroke.Transparency = 0.15
	trackStroke.Parent = track

	-- The opponent's sectors, projected: one chip per aim position, fixed in screen space.
	local chips: { Frame } = {}
	for k = 0, N - 1 do
		local chip = Instance.new("Frame")
		chip.Name = "Chip" .. k
		chip.AnchorPoint = Vector2.new(0.5, 0.5)
		chip.Position = onCircle(k, LAYOUT.TRACK_RADIUS)
		chip.Size = UDim2.fromScale(LAYOUT.CHIP, LAYOUT.CHIP)
		chip.BackgroundColor3 = COLOR.normal
		chip.BackgroundTransparency = 0.3
		chip.ZIndex = 2
		chip.Parent = frame
		round(chip)
		chips[k + 1] = chip
	end

	-- The opponent's aim, marked on your ring.
	local oppMark = Instance.new("Frame")
	oppMark.Name = "OpponentAim"
	oppMark.AnchorPoint = Vector2.new(0.5, 0.5)
	oppMark.Size = UDim2.fromScale(LAYOUT.CHIP * 1.7, LAYOUT.CHIP * 1.7)
	oppMark.BackgroundTransparency = 1
	oppMark.Visible = false
	oppMark.ZIndex = 3
	oppMark.Parent = frame
	round(oppMark)
	local oppStroke = Instance.new("UIStroke")
	oppStroke.Color = Color3.fromHex("f2ead8")
	oppStroke.Thickness = 2
	oppStroke.Parent = oppMark

	-- Dots: the 8 directions labeled, ticks at the half steps between.
	local dots: { Frame } = {}
	for k = 0, N - 1 do
		local labeled = k % Slice.wheel.labelEvery == 0
		local dot = Instance.new("Frame")
		dot.Name = "Dot" .. k
		dot.AnchorPoint = Vector2.new(0.5, 0.5)
		dot.Position = onCircle(k, LAYOUT.TRACK_RADIUS)
		local d = if labeled then LAYOUT.DOT else LAYOUT.TICK
		dot.Size = UDim2.fromScale(d, d)
		dot.BackgroundColor3 = COLOR.dim
		dot.BackgroundTransparency = 0.4
		dot.ZIndex = 4
		dot.Parent = frame
		round(dot)
		dots[k + 1] = dot
		if labeled then
			local label = Instance.new("TextLabel")
			label.Name = "Label" .. k
			label.AnchorPoint = Vector2.new(0.5, 0.5)
			label.Position = onCircle(k, LAYOUT.LABEL_RADIUS)
			label.Size = UDim2.fromScale(0.22, 0.05)
			label.BackgroundTransparency = 1
			label.Font = Enum.Font.Gotham
			label.Text = Dial.NAME[k] or ""
			label.TextColor3 = COLOR.dim
			label.TextScaled = true
			label.ZIndex = 4
			label.Parent = frame
		end
	end

	-- The needle.
	local needleGroup = Instance.new("Frame")
	needleGroup.Name = "Needle"
	needleGroup.AnchorPoint = Vector2.new(0.5, 0.5)
	needleGroup.Position = UDim2.fromScale(0.5, 0.5)
	needleGroup.Size = UDim2.fromScale(1, 1)
	needleGroup.BackgroundTransparency = 1
	needleGroup.ZIndex = 5
	needleGroup.Parent = frame
	local bar = Instance.new("Frame")
	bar.Name = "Bar"
	bar.AnchorPoint = Vector2.new(0.5, 0)
	bar.Position = UDim2.fromScale(0.5, 0.145)
	bar.Size = UDim2.fromScale(0.02, 0.29)
	bar.BackgroundColor3 = COLOR.gold
	bar.ZIndex = 5
	bar.Parent = needleGroup
	round(bar)
	local tip = Instance.new("Frame")
	tip.Name = "Tip"
	tip.AnchorPoint = Vector2.new(0.5, 0.5)
	tip.Position = onCircle(0, LAYOUT.TRACK_RADIUS)
	tip.Size = UDim2.fromScale(0.035, 0.035)
	tip.BackgroundColor3 = COLOR.gold
	tip.ZIndex = 5
	tip.Parent = needleGroup
	round(tip)

	-- The hub: Neutral.
	local hub = Instance.new("TextButton")
	hub.Name = "Hub"
	hub.AnchorPoint = Vector2.new(0.5, 0.5)
	hub.Position = UDim2.fromScale(0.5, 0.5)
	hub.Size = UDim2.fromScale(LAYOUT.HUB_SIZE, LAYOUT.HUB_SIZE)
	hub.BackgroundColor3 = COLOR.ground
	hub.Font = Enum.Font.Gotham
	hub.Text = "Neutral"
	hub.TextColor3 = COLOR.gold
	hub.TextScaled = true
	hub.AutoButtonColor = false
	hub.ZIndex = 6
	hub.Parent = frame
	round(hub)
	local hubPad = Instance.new("UIPadding")
	hubPad.PaddingLeft = UDim.new(0.15, 0)
	hubPad.PaddingRight = UDim.new(0.15, 0)
	hubPad.PaddingTop = UDim.new(0.3, 0)
	hubPad.PaddingBottom = UDim.new(0.3, 0)
	hubPad.Parent = hub
	local hubStroke = Instance.new("UIStroke")
	hubStroke.Color = COLOR.gold
	hubStroke.Transparency = 0.2
	hubStroke.Parent = hub

	-- The input surface, under everything decorative.
	local catcher = Instance.new("TextButton")
	catcher.Name = "Catcher"
	catcher.AnchorPoint = Vector2.new(0.5, 0.5)
	catcher.Position = UDim2.fromScale(0.5, 0.5)
	catcher.Size = UDim2.fromScale(1, 1)
	catcher.BackgroundTransparency = 1
	catcher.Text = ""
	catcher.ZIndex = 0
	catcher.Parent = frame

	local function relayout()
		trackStroke.Thickness = frame.AbsoluteSize.X * LAYOUT.BAND_FRACTION
	end
	frame:GetPropertyChangedSignal("AbsoluteSize"):Connect(relayout)
	relayout()

	local tickSound = Instance.new("Sound")
	tickSound.Name = "NotchTick"
	tickSound.SoundId = "rbxasset://sounds/snap.mp3"
	tickSound.Volume = 0.3
	tickSound.Parent = frame

	-- ── input ─────────────────────────────────────────────────────────────────────────────────
	local function pointerNotch(position: Vector2): number
		local center = frame.AbsolutePosition + frame.AbsoluteSize / 2
		local d = position - center
		local screen = math.atan2(d.X, -d.Y) / math.rad(DEG)
		return (SIGN * screen) % N
	end

	local activeInput: InputObject? = nil

	catcher.InputBegan:Connect(function(input: InputObject)
		if not enabled then
			return
		end
		if input.UserInputType ~= Enum.UserInputType.MouseButton1 and input.UserInputType ~= Enum.UserInputType.Touch then
			return
		end
		if activeInput then
			return
		end
		activeInput = input
		wheel:beginDrag(pointerNotch(Vector2.new(input.Position.X, input.Position.Y)), os.clock())
	end)

	UserInputService.InputChanged:Connect(function(input: InputObject)
		local a = activeInput
		if a == nil or not wheel.dragging then
			return
		end
		if a.UserInputType == Enum.UserInputType.Touch then
			if input ~= a then
				return
			end
		elseif input.UserInputType ~= Enum.UserInputType.MouseMovement then
			return
		end
		wheel:drag(pointerNotch(Vector2.new(input.Position.X, input.Position.Y)), os.clock())
	end)

	UserInputService.InputEnded:Connect(function(input: InputObject)
		local a = activeInput
		if a == nil then
			return
		end
		if input ~= a and input.UserInputType ~= a.UserInputType then
			return
		end
		activeInput = nil
		wheel:endDrag()
	end)

	hub.Activated:Connect(function()
		if enabled then
			activeInput = nil
			wheel:setNeutral()
		end
	end)

	-- ── render ────────────────────────────────────────────────────────────────────────────────
	local function paintChips()
		for k = 0, N - 1 do
			local tier = Dial.tier(k, oppAim, cfg.spec)
			local chip = chips[k + 1]
			chip.BackgroundColor3 = if tier == "crit" then COLOR.exposure elseif tier == "block" then COLOR.guard else COLOR.normal
			chip.BackgroundTransparency = if tier == "normal" then 0.6 else 0.15
		end
		if oppAim ~= nil then
			oppMark.Position = onCircle(oppAim, LAYOUT.TRACK_RADIUS)
			oppMark.Visible = true
		else
			oppMark.Visible = false
		end
	end
	paintChips()

	local last: number? = nil
	local rng = Random.new()
	RunService.RenderStepped:Connect(function(dt: number)
		wheel:step(dt)
		local neutral = wheel.neutral
		needleGroup.Rotation = SIGN * wheel:displayTheta() * DEG
		needleGroup.Visible = not neutral
		local pos = wheel:position()
		if pos ~= last then
			last = pos
			if pos ~= nil then
				tickSound.PlaybackSpeed = 1.4 + rng:NextNumber(-0.1, 0.1)
				tickSound:Play()
			end
			onPosition(pos)
		end
		for k = 0, N - 1 do
			local dot = dots[k + 1]
			local active = pos == k
			local base = if k % Slice.wheel.labelEvery == 0 then LAYOUT.DOT else LAYOUT.TICK
			local d = if active then LAYOUT.DOT_ACTIVE else base
			dot.Size = UDim2.fromScale(d, d)
			dot.BackgroundColor3 = if active then COLOR.gold else COLOR.dim
			dot.BackgroundTransparency = if active then 0 else 0.4
		end
		hubStroke.Color = if neutral then COLOR.gold else COLOR.line
		hub.TextColor3 = if neutral then COLOR.gold else COLOR.dim
	end)

	return {
		frame = frame,
		position = function(): number?
			return wheel:position()
		end,
		reset = function()
			activeInput = nil
			wheel:setNeutral()
		end,
		setEnabled = function(on: boolean)
			enabled = on
			if not on and wheel.dragging then
				activeInput = nil
				wheel:endDrag()
			end
			trackStroke.Transparency = if on then 0.15 else 0.6
		end,
		setOpponentAim = function(aim: number?)
			oppAim = aim
			paintChips()
		end,
	}
end

return Wheel
