--!strict
-- Cards.luau — the deck, hold'em evaluation (GAME_SPEC §2 *Deck and deal*) and card points
-- (§4 *Card values*, *Poker hands multiply*).
--
-- A card is an integer 0..51: rank = c // 4 + 2 (2..14, A = 14), suit = c % 4 + 1.
-- Suits are indexed by stat (§4 *The four stats*): 1 ♣ Knockoff, 2 ♠ Pierce, 3 ♥ Sturdiness,
-- 4 ♦ Armor.

local Cards = {}

Cards.CLUB, Cards.SPADE, Cards.HEART, Cards.DIAMOND = 1, 2, 3, 4
Cards.GLYPH = { "♣", "♠", "♥", "♦" }

-- Hand categories, low to high. 0–3 are numeric hands; 4–8 are tricks (§6 *The trick ladder*).
Cards.HIGH_CARD, Cards.PAIR, Cards.TWO_PAIR, Cards.TRIPS = 0, 1, 2, 3
Cards.STRAIGHT, Cards.FLUSH, Cards.FULL_HOUSE, Cards.QUADS, Cards.STRAIGHT_FLUSH = 4, 5, 6, 7, 8
Cards.NAME = {
	[0] = "high card",
	"pair",
	"two pair",
	"trips",
	"straight",
	"flush",
	"full house",
	"quads",
	"straight flush",
}

function Cards.make(rank: number, suit: number): number
	return (rank - 2) * 4 + (suit - 1)
end

function Cards.rank(c: number): number
	return c // 4 + 2
end

function Cards.suit(c: number): number
	return c % 4 + 1
end

local RANK_CHARS = "23456789TJQKA"
local SUIT_CHARS = "cshd"

-- "As" → ace of spades. For tests and debugging.
function Cards.parse(s: string): number
	local r = string.find(RANK_CHARS, string.sub(s, 1, 1), 1, true)
	local su = string.find(SUIT_CHARS, string.sub(s, 2, 2), 1, true)
	assert(r and su, "bad card " .. s)
	return Cards.make(r + 1, su)
end

function Cards.list(s: string): { number }
	local out = {}
	for _, tok in string.split(s, " ") do
		if tok ~= "" then
			table.insert(out, Cards.parse(tok))
		end
	end
	return out
end

function Cards.show(c: number): string
	local r = Cards.rank(c)
	return string.sub(RANK_CHARS, r - 1, r - 1) .. Cards.GLYPH[Cards.suit(c)]
end

-- ── evaluation ─────────────────────────────────────────────────────────────────────────────────

local B = 15 -- ranks are < 15, so each tiebreak rank is one base-15 digit
local B5 = B ^ 5

local function encode(cat: number, r: { number }): number
	return cat * B5 + (r[1] or 0) * B ^ 4 + (r[2] or 0) * B ^ 3 + (r[3] or 0) * B ^ 2 + (r[4] or 0) * B + (r[5] or 0)
end

-- Highest straight top rank in a rank bitmask (bit r set for rank r; an ace also sets bit 1).
local function straightTop(mask: number): number?
	for top = 14, 5, -1 do
		local need = bit32.lshift(0x1F, top - 4)
		if bit32.band(mask, need) == need then
			return top
		end
	end
	return nil
end

export type Eval = {
	value: number, -- comparable: higher is better; equal is an exact tie (§2 win condition 4)
	category: number,
	straightTop: number?, -- straight and straight flush: top rank (5 for the wheel)
	flushSuit: number?, -- flush and straight flush
}

-- Best five of the given cards (5 to 7), standard hold'em ranking.
function Cards.evaluate(cards: { number }): Eval
	local count = table.create(15, 0)
	local suitCount = { 0, 0, 0, 0 }
	local suitMask = { 0, 0, 0, 0 }
	local mask = 0
	for _, c in cards do
		local r, s = c // 4 + 2, c % 4 + 1
		count[r] += 1
		suitCount[s] += 1
		local bit = bit32.lshift(1, r)
		if r == 14 then
			bit = bit32.bor(bit, 2)
		end
		suitMask[s] = bit32.bor(suitMask[s], bit)
		mask = bit32.bor(mask, bit)
	end
	local flushSuit: number? = nil
	for s = 1, 4 do
		if suitCount[s] >= 5 then
			flushSuit = s
		end
	end
	if flushSuit then
		local top = straightTop(suitMask[flushSuit])
		if top then
			return { value = encode(8, { top }), category = 8, straightTop = top, flushSuit = flushSuit }
		end
	end
	local quads, trips, pairs, singles = {}, {}, {}, {}
	for r = 14, 2, -1 do
		local n = count[r]
		if n == 4 then
			table.insert(quads, r)
		elseif n == 3 then
			table.insert(trips, r)
		elseif n == 2 then
			table.insert(pairs, r)
		elseif n == 1 then
			table.insert(singles, r)
		end
	end
	-- Highest rank not in `used`, from everything present.
	local function kickers(used: { [number]: boolean }, k: number): { number }
		local out = {}
		for r = 14, 2, -1 do
			if count[r] > 0 and not used[r] then
				table.insert(out, r)
				if #out == k then
					break
				end
			end
		end
		return out
	end
	if #quads > 0 then
		local q = quads[1]
		local k = kickers({ [q] = true }, 1)
		return { value = encode(7, { q, k[1] }), category = 7 }
	end
	if #trips > 0 and (#trips >= 2 or #pairs >= 1) then
		local t = trips[1]
		local p = trips[2] or 0
		if #pairs > 0 and pairs[1] > p then
			p = pairs[1]
		end
		return { value = encode(6, { t, p }), category = 6 }
	end
	if flushSuit then
		local r = {}
		for rank = 14, 2, -1 do
			if bit32.band(suitMask[flushSuit], bit32.lshift(1, rank)) ~= 0 then
				table.insert(r, rank)
				if #r == 5 then
					break
				end
			end
		end
		return { value = encode(5, r), category = 5, flushSuit = flushSuit }
	end
	local top = straightTop(mask)
	if top then
		return { value = encode(4, { top }), category = 4, straightTop = top }
	end
	if #trips > 0 then
		local t = trips[1]
		local k = kickers({ [t] = true }, 2)
		return { value = encode(3, { t, k[1], k[2] }), category = 3 }
	end
	if #pairs >= 2 then
		local a, b = pairs[1], pairs[2]
		local k = kickers({ [a] = true, [b] = true }, 1)
		return { value = encode(2, { a, b, k[1] }), category = 2 }
	end
	if #pairs == 1 then
		local p = pairs[1]
		local k = kickers({ [p] = true }, 3)
		return { value = encode(1, { p, k[1], k[2], k[3] }), category = 1 }
	end
	return { value = encode(0, kickers({}, 5)), category = 0 }
end

-- ── starting-hand classes ──────────────────────────────────────────────────────────────────────

-- The 169 starting-hand classes as a 13×13 grid (the yard's unit of choice, §2 *The yard*): pairs on
-- the diagonal, suited hands above it (row = high rank), offsuit below it (row = low rank).
-- Returns 1..169: (row − 2) · 13 + (col − 2) + 1.
function Cards.class(hole: { number }): number
	local r1, r2 = hole[1] // 4 + 2, hole[2] // 4 + 2
	if r1 < r2 then
		r1, r2 = r2, r1
	end
	local row, col = r1, r2
	if r1 ~= r2 and hole[1] % 4 ~= hole[2] % 4 then
		row, col = r2, r1
	end
	return (row - 2) * 13 + (col - 2) + 1
end

-- "AKs", "AKo", "77". The inverse of Cards.class, for reports.
function Cards.className(idx: number): string
	local row, col = (idx - 1) // 13 + 2, (idx - 1) % 13 + 2
	local hi, lo = math.max(row, col), math.min(row, col)
	local s = string.sub(RANK_CHARS, hi - 1, hi - 1) .. string.sub(RANK_CHARS, lo - 1, lo - 1)
	if row == col then
		return s
	end
	return s .. (if row > col then "s" else "o")
end

-- How many of the 1326 two-card deals fall in a class: 6 for a pair, 4 suited, 12 offsuit.
function Cards.classCombos(idx: number): number
	local row, col = (idx - 1) // 13 + 2, (idx - 1) % 13 + 2
	if row == col then
		return 6
	end
	return if row > col then 4 else 12
end

-- ── card points ────────────────────────────────────────────────────────────────────────────────

-- The numeric sub-hand's made cards (§4 *Poker hands multiply*; §6 *Held behavior*: a held trick
-- rides as its best non-trick sub-hand). Returns rank → {multiplier, how many cards of that rank
-- it applies to}, and the sub-hand category (0–3).
function Cards.subHand(cards: { number }, spec: any): ({ [number]: { number } }, number)
	local count = table.create(15, 0)
	for _, c in cards do
		count[c // 4 + 2] += 1
	end
	local tripRank, pairRanks = nil, {}
	for r = 14, 2, -1 do
		if count[r] >= 3 and tripRank == nil then
			tripRank = r
		elseif count[r] >= 2 then
			table.insert(pairRanks, r)
		end
	end
	if tripRank then
		return { [tripRank] = { spec.handMult.trips, 3 } }, 3
	end
	if #pairRanks >= 2 then
		local m = spec.handMult.twoPair
		return { [pairRanks[1]] = { m, 2 }, [pairRanks[2]] = { m, 2 } }, 2
	end
	if #pairRanks == 1 then
		return { [pairRanks[1]] = { spec.handMult.pair, 2 } }, 1
	end
	return {}, 0
end

function Cards.rankValue(r: number, spec: any): number
	return spec.rankBase + (r - 2) * spec.rankSlope
end

-- Unleaned card points per suit from every revealed card (§4 *Card values*): hole cards in full,
-- board cards at the board weight, made cards multiplied. Hole cards take a made rank's multiplier
-- first, since a quads sub-hand (trips) multiplies only three of the four.
function Cards.points(hole: { number }, board: { number }, spec: any): ({ number }, number)
	local all = table.clone(hole)
	for _, c in board do
		table.insert(all, c)
	end
	local made, sub = Cards.subHand(all, spec)
	local used = {}
	local pts = { 0, 0, 0, 0 }
	local function add(c: number, weight: number)
		local r, s = c // 4 + 2, c % 4 + 1
		local v = Cards.rankValue(r, spec) * weight
		local m = made[r]
		if m and (used[r] or 0) < m[2] then
			used[r] = (used[r] or 0) + 1
			v *= m[1]
		end
		pts[s] += v
	end
	for _, c in hole do
		add(c, 1)
	end
	for _, c in board do
		add(c, spec.boardWeight)
	end
	return pts, sub
end

-- Fisher–Yates with the sim's own RNG, so a run is reproducible from its seed.
function Cards.shuffled(rng: () -> number): { number }
	local d = table.create(52, 0)
	for i = 1, 52 do
		d[i] = i - 1
	end
	for i = 52, 2, -1 do
		local j = math.floor(rng() * i) + 1
		d[i], d[j] = d[j], d[i]
	end
	return d
end

return Cards
