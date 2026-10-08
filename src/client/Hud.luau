--!strict
-- Hud.luau — what the player sees, laid out per 0105: the two riders' rows at the top (the
-- opponent first), the pass clock and the cards in the middle, the wheel at the bottom with the stat
-- meter and both riders' lance and shield colors beside it. Bets open over the wheel between passes;
-- the reveal, the ♥ heal and the post-pass reveal are banners over the cards (0106). UI only, no 3D
-- scene (0103).
--
-- Everything shown is public (GAME_SPEC §3 *Public vs hidden*) except the rider's own hole cards and
-- their own stat meter (§4 *The stat meter*). The opponent's hole cards show only at hand end (§7).

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Rules = ReplicatedStorage:WaitForChild("Rules")
local Cards = require(Rules:WaitForChild("Cards"))
local Dial = require(Rules:WaitForChild("Dial"))

local Hud = {}

local COLOR = {
	bg = Color3.fromHex("15120c"),
	panel = Color3.fromHex("221c13"),
	line = Color3.fromHex("3a3226"),
	text = Color3.fromHex("f2ead8"),
	dim = Color3.fromHex("9a8d72"),
	gold = Color3.fromHex("d9a441"),
	heart = Color3.fromHex("c8323c"),
	heartEmpty = Color3.fromHex("3b2a26"),
	heal = Color3.fromHex("7bc47f"),
	hit = Color3.fromHex("e2604d"),
	red = Color3.fromHex("c8323c"),
	black = Color3.fromHex("1b1b1b"),
	cardFace = Color3.fromHex("f5efe1"),
	cardBack = Color3.fromHex("4b3f2c"),
	hold = Color3.fromHex("d9a441"),
	slow = Color3.fromHex("3d4f5c"),
}

local GLYPH_COLOR = { COLOR.black, COLOR.black, COLOR.red, COLOR.red } -- ♣ ♠ ♥ ♦

-- Half hearts → "3½♥" (1 Posture is a half heart, §4 *Tracks*).
function Hud.hearts(hh: number): string
	local sign = if hh < 0 then "−" else ""
	local a = math.abs(hh)
	local whole = a // 2
	local half = a % 2 >= 1
	local body = if whole == 0 and half then "½" elseif half then tostring(whole) .. "½" else tostring(whole)
	return sign .. body .. "♥"
end

local function corner(inst: GuiObject, r: number?)
	local c = Instance.new("UICorner")
	c.CornerRadius = UDim.new(r or 0.15, 0)
	c.Parent = inst
end

local function frame(parent: Instance, name: string, x: number, y: number, w: number, h: number, color: Color3?, z: number?): Frame
	local f = Instance.new("Frame")
	f.Name = name
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = color or COLOR.panel
	f.BackgroundTransparency = if color then 0 else 1
	f.BorderSizePixel = 0
	f.ZIndex = z or 1
	f.Parent = parent
	return f
end

local function label(parent: Instance, name: string, x: number, y: number, w: number, h: number, text: string, z: number?): TextLabel
	local l = Instance.new("TextLabel")
	l.Name = name
	l.Position = UDim2.fromScale(x, y)
	l.Size = UDim2.fromScale(w, h)
	l.BackgroundTransparency = 1
	l.Font = Enum.Font.Gotham
	l.Text = text
	l.TextColor3 = COLOR.text
	l.TextScaled = true
	l.TextXAlignment = Enum.TextXAlignment.Left
	l.ZIndex = z or 2
	l.Parent = parent
	return l
end

local function button(parent: Instance, name: string, x: number, y: number, w: number, h: number, text: string, z: number): TextButton
	local b = Instance.new("TextButton")
	b.Name = name
	b.Position = UDim2.fromScale(x, y)
	b.Size = UDim2.fromScale(w, h)
	b.BackgroundColor3 = COLOR.gold
	b.Font = Enum.Font.GothamBold
	b.Text = text
	b.TextColor3 = COLOR.bg
	b.TextScaled = true
	b.ZIndex = z
	b.Parent = parent
	corner(b, 0.2)
	return b
end

-- Two rows of 8 hearts, each heart two half cells (§4: a full bar is 16 hearts in two rows of 8).
local function heartBar(parent: Instance, x: number, y: number, w: number, h: number)
	local holder = frame(parent, "Hearts", x, y, w, h)
	local halves: { Frame } = {}
	for heart = 1, 16 do
		local row = (heart - 1) // 8
		local col = (heart - 1) % 8
		for half = 0, 1 do
			local cell = frame(holder, "H" .. (2 * heart - 1 + half), col / 8 + half * 0.5 / 8 + 0.004, row * 0.5 + 0.06, 0.5 / 8 - 0.008, 0.38, COLOR.heart, 2)
			halves[2 * heart - 1 + half] = cell
		end
	end
	return function(hh: number)
		for i, cell in halves do
			cell.BackgroundColor3 = if hh >= i then COLOR.heart else COLOR.heartEmpty
		end
	end
end

local function cardSlot(parent: Instance, name: string, x: number, y: number, w: number, h: number)
	local f = Instance.new("TextLabel")
	f.Name = name
	f.Position = UDim2.fromScale(x, y)
	f.Size = UDim2.fromScale(w, h)
	f.BackgroundColor3 = COLOR.cardBack
	f.BackgroundTransparency = 0.6
	f.Font = Enum.Font.GothamBold
	f.Text = ""
	f.TextScaled = true
	f.ZIndex = 3
	f.Parent = parent
	corner(f, 0.12)
	local pad = Instance.new("UIPadding")
	pad.PaddingTop = UDim.new(0.18, 0)
	pad.PaddingBottom = UDim.new(0.18, 0)
	pad.Parent = f
	return function(card: number?, hidden: boolean?)
		if card ~= nil then
			f.BackgroundColor3 = COLOR.cardFace
			f.BackgroundTransparency = 0
			f.Text = Cards.show(card)
			f.TextColor3 = GLYPH_COLOR[Cards.suit(card)]
		elseif hidden then
			f.BackgroundColor3 = COLOR.cardBack
			f.BackgroundTransparency = 0
			f.Text = "?"
			f.TextColor3 = COLOR.dim
		else
			f.BackgroundColor3 = COLOR.cardBack
			f.BackgroundTransparency = 0.6
			f.Text = ""
		end
	end
end

export type Hud = { [string]: any }

function Hud.new(playerGui: Instance): Hud
	local gui = Instance.new("ScreenGui")
	gui.Name = "PokerJousting"
	gui.ResetOnSpawn = false
	gui.IgnoreGuiInset = true
	gui.ZIndexBehavior = Enum.ZIndexBehavior.Sibling
	gui.Parent = playerGui

	local root = frame(gui, "Root", 0, 0, 1, 1, COLOR.bg, 0)
	local hud: Hud = { gui = gui }

	-- ── the riders' rows (0105: the opponent first, then you) ─────────────────────────────────
	local rows = {}
	for i, key in { "opp", "you" } do
		local y = 0.01 + (i - 1) * 0.14
		local row = frame(root, "Row_" .. key, 0.01, y, 0.98, 0.13, COLOR.panel, 1)
		corner(row, 0.1)
		local r = {
			row = row,
			name = label(row, "Name", 0.01, 0.1, 0.17, 0.4, ""),
			units = label(row, "Units", 0.01, 0.55, 0.17, 0.3, ""),
			setHearts = heartBar(row, 0.19, 0.08, 0.34, 0.84),
			posture = label(row, "Posture", 0.54, 0.25, 0.09, 0.5, ""),
			holdBack = frame(row, "HoldBack", 0.64, 0.3, 0.14, 0.18, COLOR.line, 2),
			holdText = label(row, "HoldText", 0.64, 0.55, 0.14, 0.32, "hold —"),
			aim = label(row, "Aim", 0.79, 0.2, 0.11, 0.55, "Neutral"),
			status = label(row, "Status", 0.905, 0.1, 0.09, 0.8, ""),
		}
		r.holdFill = frame(r.holdBack, "Fill", 0, 0, 0, 1, COLOR.hold, 3)
		r.floatLabel = label(row, "Float", 0.4, -0.05, 0.25, 0.45, "", 6)
		r.floatLabel.TextXAlignment = Enum.TextXAlignment.Center
		r.floatLabel.Visible = false
		rows[key] = r
	end
	local rowOf: { [number]: any } = {}

	function hud.bindSeats(you: number)
		rowOf[you] = rows.you
		rowOf[3 - you] = rows.opp
	end
	function hud.setName(seat: number, text: string)
		rowOf[seat].name.Text = text
	end
	function hud.setPosture(seat: number, hh: number)
		local r = rowOf[seat]
		r.setHearts(math.clamp(hh, 0, 32))
		r.posture.Text = Hud.hearts(hh)
		r.posture.TextColor3 = if hh < 0 then COLOR.hit else COLOR.text
	end
	local floatSeq = { 0, 0 }
	function hud.float(seat: number, text: string, color: Color3, seconds: number)
		local r = rowOf[seat]
		floatSeq[seat] += 1
		local mine = floatSeq[seat]
		r.floatLabel.Text = text
		r.floatLabel.TextColor3 = color
		r.floatLabel.Visible = true
		task.delay(seconds, function()
			if floatSeq[seat] == mine then
				r.floatLabel.Visible = false
			end
		end)
	end
	function hud.setHold(seat: number, h: number?)
		local r = rowOf[seat]
		if h == nil then
			r.holdFill.Size = UDim2.fromScale(0, 1)
			r.holdText.Text = "hold —"
		else
			r.holdFill.Size = UDim2.fromScale(math.clamp(h, 0, 1), 1)
			r.holdText.Text = string.format("hold %d%%", math.floor(h * 100 + 0.5))
		end
	end
	function hud.setAim(seat: number, aim: number?)
		local r = rowOf[seat]
		r.aim.Text = Hud.aimName(aim)
		r.aim.TextColor3 = if aim == nil then COLOR.dim else COLOR.gold
	end
	function hud.setStatus(seat: number, text: string)
		rowOf[seat].status.Text = text
	end
	function hud.setUnits(seat: number, text: string)
		rowOf[seat].units.Text = text
	end

	-- ── the middle: the pass clock and the cards ────────────────────────────────────────────────
	local clockBack = frame(root, "Clock", 0.05, 0.295, 0.9, 0.03, COLOR.line, 1)
	corner(clockBack, 0.4)
	local clockFill = frame(clockBack, "Fill", 0, 0, 0, 1, COLOR.gold, 3)
	corner(clockFill, 0.4)
	local clockLabel = label(root, "ClockLabel", 0.05, 0.325, 0.4, 0.025, "")
	local slowBand = frame(clockBack, "Slow", 0, 0, 0, 1, COLOR.slow, 2)
	local marks: { Frame } = {}
	function hud.setTimeline(tl: any, passLength: number)
		slowBand.Position = UDim2.fromScale(tl.reveal / passLength, 0)
		slowBand.Size = UDim2.fromScale((tl.slowEnd - tl.reveal) / passLength, 1)
		for _, m in marks do
			m:Destroy()
		end
		for _, m in { { tl.reveal, "reveal" }, { tl.lock, "lock" } } do
			local tick = frame(clockBack, "Mark_" .. m[2], m[1] / passLength, -0.3, 0.004, 1.6, COLOR.text, 4)
			table.insert(marks, tick)
		end
	end
	function hud.setClock(t: number?, passLength: number, text: string)
		clockFill.Size = UDim2.fromScale(if t then math.clamp(t / passLength, 0, 1) else 0, 1)
		clockLabel.Text = text
	end
	function hud.setSlow(on: boolean)
		slowBand.BackgroundColor3 = if on then COLOR.heal else COLOR.slow
	end

	label(root, "HoleTitle", 0.03, 0.35, 0.16, 0.025, "your hand").TextColor3 = COLOR.dim
	label(root, "BoardTitle", 0.25, 0.35, 0.45, 0.025, "board").TextColor3 = COLOR.dim
	label(root, "OppHoleTitle", 0.78, 0.35, 0.16, 0.025, "their hand").TextColor3 = COLOR.dim
	local holeSlots, oppSlots, boardSlots = {}, {}, {}
	for i = 1, 2 do
		holeSlots[i] = cardSlot(root, "Hole" .. i, 0.03 + (i - 1) * 0.08, 0.38, 0.07, 0.1)
		oppSlots[i] = cardSlot(root, "OppHole" .. i, 0.78 + (i - 1) * 0.08, 0.38, 0.07, 0.1)
	end
	for i = 1, 5 do
		boardSlots[i] = cardSlot(root, "Board" .. i, 0.25 + (i - 1) * 0.09, 0.38, 0.08, 0.1)
	end
	function hud.setHole(cards: { number })
		for i = 1, 2 do
			holeSlots[i](cards[i])
		end
	end
	function hud.setOppHole(cards: { number }?)
		for i = 1, 2 do
			oppSlots[i](if cards then cards[i] else nil, true)
		end
	end
	function hud.setBoard(cards: { number })
		for i = 1, 5 do
			boardSlots[i](cards[i])
		end
	end
	local pot = label(root, "Pot", 0.25, 0.49, 0.45, 0.035, "")
	pot.TextXAlignment = Enum.TextXAlignment.Center
	function hud.setPot(text: string)
		pot.Text = text
	end

	-- Banners over the cards: the reveal, the heal beat, the post-pass reveal, the showdown.
	local banner = label(root, "Banner", 0.15, 0.36, 0.7, 0.12, "", 20)
	banner.BackgroundColor3 = COLOR.bg
	banner.BackgroundTransparency = 0.1
	banner.TextXAlignment = Enum.TextXAlignment.Center
	banner.TextWrapped = true
	banner.Visible = false
	corner(banner, 0.1)
	local bannerPad = Instance.new("UIPadding")
	bannerPad.PaddingTop = UDim.new(0.08, 0)
	bannerPad.PaddingBottom = UDim.new(0.08, 0)
	bannerPad.PaddingLeft = UDim.new(0.03, 0)
	bannerPad.PaddingRight = UDim.new(0.03, 0)
	bannerPad.Parent = banner
	local bannerSeq = 0
	function hud.banner(text: string, seconds: number)
		bannerSeq += 1
		local mine = bannerSeq
		banner.Text = text
		banner.Visible = true
		task.delay(seconds, function()
			if bannerSeq == mine then
				banner.Visible = false
			end
		end)
	end
	function hud.hideBanner()
		bannerSeq += 1
		banner.Visible = false
	end

	-- ── the bottom: stat meter and colors, the wheel, the bet log ────────────────────────────────
	local left = frame(root, "Left", 0.01, 0.55, 0.27, 0.44, COLOR.panel, 1)
	corner(left, 0.06)
	label(left, "MeterTitle", 0.05, 0.02, 0.9, 0.08, "your stats (with the lean)").TextColor3 = COLOR.dim
	local meter = {}
	local SUITS = { "♣ Strength", "♠ Accuracy", "♥ Posture", "♦ Armor" }
	for s = 1, 4 do
		meter[s] = label(left, "Stat" .. s, 0.05, 0.11 + (s - 1) * 0.1, 0.9, 0.085, SUITS[s])
	end
	-- §4 *The stat meter*: your four stats with the current lean applied, live as you rotate.
	function hud.setStats(S: { number }, buffer: number, base: number)
		for s = 1, 4 do
			local extra = if s == 3 then string.format("  buffer %.1f", buffer) else ""
			meter[s].Text = string.format("%s  %.1f%s", SUITS[s], S[s], extra)
			meter[s].TextColor3 = if S[s] > base + 1e-9 or (s == 3 and buffer > 0) then COLOR.text else COLOR.dim
		end
	end
	label(left, "ColorsTitle", 0.05, 0.56, 0.9, 0.08, "lance / shield").TextColor3 = COLOR.dim
	local colorRows = {}
	for i, key in { "opp", "you" } do
		local y = 0.66 + (i - 1) * 0.15
		local who = label(left, "Who_" .. key, 0.05, y, 0.4, 0.11, if key == "you" then "you" else "them")
		local lance = frame(left, "Lance_" .. key, 0.5, y, 0.2, 0.11, COLOR.line, 2)
		local shield = frame(left, "Shield_" .. key, 0.74, y, 0.2, 0.11, COLOR.line, 2)
		corner(lance, 0.2)
		corner(shield, 0.2)
		colorRows[key] = { who = who, lance = lance, shield = shield }
	end
	function hud.setColors(seat: number, lance: string, shield: string)
		local key = if rowOf[seat] == rows.you then "you" else "opp"
		local c = colorRows[key]
		c.lance.BackgroundColor3 = if lance == "red" then COLOR.red else COLOR.black
		c.shield.BackgroundColor3 = if shield == "red" then COLOR.red else COLOR.black
	end

	hud.wheelHolder = frame(root, "WheelHolder", 0.29, 0.54, 0.42, 0.45)

	local right = frame(root, "Right", 0.72, 0.55, 0.27, 0.44, COLOR.panel, 1)
	corner(right, 0.06)
	label(right, "Legend", 0.05, 0.02, 0.9, 0.16, "ring: red = you crit\nblue = their Guard").TextColor3 = COLOR.dim
	local logLines: { TextLabel } = {}
	for i = 1, 7 do
		logLines[i] = label(right, "Log" .. i, 0.05, 0.2 + (i - 1) * 0.11, 0.9, 0.09, "")
	end
	local log: { string } = {}
	function hud.log(text: string)
		table.insert(log, 1, text)
		if #log > #logLines then
			table.remove(log)
		end
		for i, l in logLines do
			l.Text = log[i] or ""
			l.TextColor3 = if i == 1 then COLOR.text else COLOR.dim
		end
	end
	function hud.clearLog()
		table.clear(log)
		for _, l in logLines do
			l.Text = ""
		end
	end

	-- ── the bet panel, over the wheel (§2: Stay / Raise / Yield, 5 s, timeout Stays) ─────────────
	local bet = frame(root, "Bet", 0.3, 0.6, 0.4, 0.3, COLOR.panel, 20)
	bet.BackgroundTransparency = 0.05
	corner(bet, 0.08)
	local betTitle = label(bet, "Title", 0.05, 0.05, 0.9, 0.18, "", 21)
	betTitle.TextXAlignment = Enum.TextXAlignment.Center
	local betInfo = label(bet, "Info", 0.05, 0.25, 0.9, 0.14, "", 21)
	betInfo.TextXAlignment = Enum.TextXAlignment.Center
	betInfo.TextColor3 = COLOR.dim
	local stay = button(bet, "Stay", 0.05, 0.45, 0.28, 0.28, "Stay", 21)
	local raise = button(bet, "Raise", 0.36, 0.45, 0.28, 0.28, "Raise", 21)
	local yield = button(bet, "Yield", 0.67, 0.45, 0.28, 0.28, "Yield", 21)
	local timerBack = frame(bet, "TimerBack", 0.05, 0.82, 0.9, 0.08, COLOR.line, 21)
	local timerFill = frame(timerBack, "Fill", 0, 0, 1, 1, COLOR.gold, 22)
	bet.Visible = false
	local onBet: ((string) -> ())? = nil
	local function wire(b: TextButton, action: string)
		b.Activated:Connect(function()
			if b.Active and onBet then
				local f = onBet
				onBet = nil
				f(action)
			end
		end)
	end
	wire(stay, "stay")
	wire(raise, "raise")
	wire(yield, "yield")
	local function enable(b: TextButton, on: boolean, visible: boolean)
		b.Visible = visible
		b.Active = on
		b.AutoButtonColor = on
		b.BackgroundTransparency = if on then 0 else 0.6
	end
	-- `mine`: the player acts; otherwise the panel shows the opponent thinking.
	function hud.showBet(title: string, info: string, mine: boolean, facing: boolean, canRaise: boolean, cb: (string) -> ())
		betTitle.Text = title
		betInfo.Text = info
		bet.Visible = true
		enable(stay, mine, mine)
		enable(raise, mine and canRaise, mine)
		enable(yield, mine and facing, mine and facing) -- Yield only facing a raise (0081)
		onBet = if mine then cb else nil
	end
	function hud.lockBet()
		onBet = nil
		enable(stay, false, stay.Visible)
		enable(raise, false, raise.Visible)
		enable(yield, false, yield.Visible)
	end
	function hud.setBetTimer(frac: number)
		timerFill.Size = UDim2.fromScale(math.clamp(frac, 0, 1), 1)
	end
	function hud.hideBet()
		onBet = nil
		bet.Visible = false
	end

	-- ── the hand-end card ───────────────────────────────────────────────────────────────────────
	local result = label(root, "Result", 0.2, 0.3, 0.6, 0.22, "", 30)
	result.BackgroundColor3 = COLOR.panel
	result.BackgroundTransparency = 0.02
	result.TextXAlignment = Enum.TextXAlignment.Center
	result.TextWrapped = true
	result.Font = Enum.Font.GothamBold
	result.Visible = false
	corner(result, 0.08)
	local resultPad = Instance.new("UIPadding")
	resultPad.PaddingTop = UDim.new(0.12, 0)
	resultPad.PaddingBottom = UDim.new(0.12, 0)
	resultPad.PaddingLeft = UDim.new(0.04, 0)
	resultPad.PaddingRight = UDim.new(0.04, 0)
	resultPad.Parent = result
	function hud.showResult(text: string)
		result.Text = text
		result.Visible = true
	end
	function hud.hideResult()
		result.Visible = false
	end

	return hud
end

-- An aim position's name: a direction by its name (§3), a half step as the two directions it sits
-- between ("Up | Up-Out").
function Hud.aimName(aim: number?): string
	if aim == nil then
		return "Neutral"
	end
	local n = Dial.NAME[aim]
	if n then
		return n
	end
	return (Dial.NAME[aim - 1] or "?") .. " | " .. (Dial.NAME[(aim + 1) % 16] or "?")
end

Hud.COLOR = COLOR

return Hud
