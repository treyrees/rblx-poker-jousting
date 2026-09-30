--!strict
-- Dial.luau — the standard dial (GAME_SPEC §3) and the stat compass (§4 *Stances*).
--
-- Aim positions are 0..15 in half steps along the sweep, Up = 0:
--   0 Up · 2 Up-Out · 4 Out · 6 Out-Down · 8 Down · 10 Down-In · 12 In · 14 In-Up
-- Odd positions are the half steps between. Neutral is nil.

local Dial = {}

Dial.POSITIONS = 16
Dial.NAME = {
	[0] = "Up",
	[2] = "Up-Out",
	[4] = "Out",
	[6] = "Out-Down",
	[8] = "Down",
	[10] = "Down-In",
	[12] = "In",
	[14] = "In-Up",
}

-- Compass homes (§4 *The stat compass*): stat index → aim position.
Dial.HOME = { 0, 4, 8, 12 } -- ♣ Up, ♠ Out, ♥ Down, ♦ In
Dial.CARDINALS = { 0, 4, 8, 12 }

local SECTOR = { E = "exposure", O = "ordinary", G = "guard" }

-- Sector at `k` half steps from the defender's aim along the sweep (§3 *Sectors*).
function Dial.sector(k: number, spec: any): string
	local ch = string.sub(spec.layout, k + 1, k + 1)
	return SECTOR[ch]
end

local TIER = { exposure = "crit", ordinary = "normal", guard = "block" }

-- The tier of a strike from `aim` into a defender at `defAim` (§4 contact resolution step 1).
-- Neutral striker: Weak. Neutral defender: no Guard, every hit Normal (§3 *Neutral*).
function Dial.tier(aim: number?, defAim: number?, spec: any): (string, number?)
	if aim == nil then
		return "weak", nil
	end
	if defAim == nil then
		return "normal", nil
	end
	local k = (aim - defAim) % 16
	return TIER[Dial.sector(k, spec)], k
end

-- §3 *Rows by offset*: offset = your aim − theirs. Returns (your strike, theirs).
function Dial.row(offset: number, spec: any): (string, string)
	local k = offset % 16
	return TIER[Dial.sector(k, spec)], TIER[Dial.sector((16 - k) % 16, spec)]
end

-- Lean weights per stat at an aim (§4 *Stances*): a cardinal leans fully into its stat, a diagonal
-- shares evenly between its two, a half step shares mostly toward the nearer cardinal. The total
-- is 1 at every aim; Neutral leans into nothing.
function Dial.lean(aim: number?, share: number): { number }
	local w = { 0, 0, 0, 0 }
	if aim == nil then
		return w
	end
	local m = aim % 4
	local cardinal = aim // 4 -- 0..3, the cardinal at or just behind this aim along the sweep
	local here = cardinal + 1
	local next = (cardinal + 1) % 4 + 1
	if m == 0 then
		w[here] = 1
	elseif m == 2 then
		w[here], w[next] = 0.5, 0.5
	elseif m == 1 then
		w[here], w[next] = share, 1 - share
	else -- m == 3: nearer the next cardinal
		w[here], w[next] = 1 - share, share
	end
	return w
end

-- The flush's home factor (§6 *Flush by suit*): full at its home, half on the diagonals beside it,
-- half steps sharing the tilt as on the compass, nothing elsewhere. That is exactly the suit's lean
-- weight at the aim.
function Dial.homeFactor(aim: number?, suit: number, share: number): number
	return Dial.lean(aim, share)[suit]
end

return Dial
