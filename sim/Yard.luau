--!strict
-- Yard.luau — the yard's equilibrium (GAME_SPEC §2 *The yard*): which starting hands riders keep
-- when a prefold has a price, and the price that holds the yard at a kept share (0079: 75%).
--
-- Input is a tally of played hands by starting-hand class pair (Cards.class), with the units and
-- wins of the first class against the second. A rider is dealt a class; they keep it and ride, or
-- pay the price c, and are dealt again. Every rider keeps by class alone, the same way (a symmetric
-- equilibrium), so the riders they meet are the deal restricted to the kept classes.
--
-- Where the price goes (dest):
--   sink    the house takes it.
--   purse   a pooled purse: every match's winner takes the average inflow, P = 2c(1 − k)/k.
--   carry   0078: a rider's own prefold payments ride into their next match's pot, and its winner
--           takes both riders' carry. Each rider brings c(1 − k)/k on average. A rider's own carry is
--           already paid when they decide, so it counts only through the fold: a fold adds c to the
--           carry they'll win back if their next match goes their way.
--
-- With k the kept share, EV_i and win_i class i's units and win share against the kept field, and
-- V the value of being dealt a fresh hand, a rider keeps class i when its value beats a fold, −c + V:
--   sink    keep EV_i;                fold −c + V,  V = (Σ f q EV − (1 − k) c) / k
--   purse   keep EV_i + win_i·P;      fold −c + V,  V = (Σ f q (EV + win·P) − (1 − k) c) / k   (= 0)
--   carry   keep EV_i + win_i·c̄;      fold −c(1 − w̄) + (Σ f q (EV + win·c̄)) / k − (1 − k) c (1 − w̄) / k
--           with c̄ = c(1 − k)/k the opponent's average carry and w̄ the kept field's mean win share.
-- (The carry fold is for a rider with nothing carried yet; with x carried, keeping class i moves by
-- (win_i − w̄)·x, so a weak hand is a shade likelier to be folded the more a rider carries.)
-- The marginal class is the one partly kept; the price for a share is the c at which it is indifferent.

local Cards = require("./Cards")

local Yard = {}

local C = 169

export type Tally = {
	n: { number }, -- [(i − 1)·169 + j]: hands where a rider holding class i met class j
	units: { number }, -- units the class-i rider won (− lost)
	wins: { number }, -- wins of the class-i rider (a split counts ½)
	-- For the yard's metrics (Yard.metrics), by the same pair index:
	loss: { number }, -- [(pair − 1)·14 + b + 1]: hands whose loser lost b units (b = 0: a split)
	modest: { number }, -- both riders' river hands modest: high card or one pair
	numeric: { number }, -- both numeric at the river and no trick fired (pillar 2's matchups)
	upset: { number }, -- the worse river category wins
	modestUpset: { number }, -- ...and it is a modest hand
}

export type Played = {
	units1: number, -- units the first rider won (− lost)
	win1: number, -- 1, ½ (split) or 0
	loss: number, -- units the loser lost; 0 for a split
	category: { number }, -- each rider's river category
	numeric: boolean,
}

export type Solution = {
	dest: string,
	share: number, -- k: the share of dealt hands kept
	price: number, -- c: the prefold price (units)
	keep: { number }, -- per class: the share of its deals kept (0..1)
	ev: { number }, -- per class: units per match against the kept field
	win: { number }, -- per class: win share against the kept field
	value: { number }, -- per class: what keeping is worth (ev plus its take of the purse or carry)
	fold: number, -- what a fold is worth
	margin: number, -- the partly kept class
	extra: number, -- prefold money in an average match's pot (purse or both riders' carry)
}

function Yard.newTally(): Tally
	local function z(n: number): { number }
		return table.create(n, 0)
	end
	return {
		n = z(C * C),
		units = z(C * C),
		wins = z(C * C),
		loss = z(C * C * 14),
		modest = z(C * C),
		numeric = z(C * C),
		upset = z(C * C),
		modestUpset = z(C * C),
	}
end

-- Adds one played hand, in both orientations: class c1 (the first rider) met class c2.
function Yard.add(t: Tally, c1: number, c2: number, h: Played)
	local a, b = (c1 - 1) * C + c2, (c2 - 1) * C + c1
	t.n[a] += 1
	t.n[b] += 1
	t.units[a] += h.units1
	t.units[b] -= h.units1
	t.wins[a] += h.win1
	t.wins[b] += 1 - h.win1
	local bin = math.clamp(math.floor(h.loss + 0.5), 0, 13)
	t.loss[(a - 1) * 14 + bin + 1] += 1
	t.loss[(b - 1) * 14 + bin + 1] += 1
	local k1, k2 = h.category[1], h.category[2]
	if k1 <= Cards.PAIR and k2 <= Cards.PAIR then
		t.modest[a] += 1
		t.modest[b] += 1
	end
	if h.numeric then
		t.numeric[a] += 1
		t.numeric[b] += 1
	end
	-- An upset is the match's, so both orientations count it.
	local winnerCat = if h.win1 == 1 then k1 elseif h.win1 == 0 then k2 else nil
	if winnerCat and winnerCat < math.max(k1, k2) then
		t.upset[a] += 1
		t.upset[b] += 1
		if winnerCat <= Cards.PAIR then
			t.modestUpset[a] += 1
			t.modestUpset[b] += 1
		end
	end
end

local FREQ = table.create(C, 0)
for i = 1, C do
	FREQ[i] = Cards.classCombos(i) / 1326
end
Yard.FREQ = FREQ

-- EV and win share of every class against the field that keeps `keep`.
function Yard.field(t: Tally, keep: { number }): ({ number }, { number })
	local ev, win = table.create(C, 0), table.create(C, 0.5)
	for i = 1, C do
		local n, u, w = 0, 0, 0
		local base = (i - 1) * C
		for j = 1, C do
			local q = keep[j]
			if q > 0 then
				local idx = base + j
				n += q * t.n[idx]
				u += q * t.units[idx]
				w += q * t.wins[idx]
			end
		end
		if n > 0 then
			ev[i], win[i] = u / n, w / n
		end
	end
	return ev, win
end

-- Keep value per class and the fold value, at price c, for a field already measured.
local function values(dest: string, c: number, keep: { number }, ev: { number }, win: { number }): ({ number }, number, number)
	local k, A, B = 0, 0, 0
	for i = 1, C do
		local fq = FREQ[i] * keep[i]
		k += fq
		A += fq * ev[i]
		B += fq * win[i]
	end
	local v = table.create(C, 0)
	if dest == "sink" then
		for i = 1, C do
			v[i] = ev[i]
		end
		return v, (A - (1 - k) * c) / k - c, 0
	elseif dest == "purse" then
		local P = 2 * c * (1 - k) / k
		for i = 1, C do
			v[i] = ev[i] + win[i] * P
		end
		return v, (A + P * B - (1 - k) * c) / k - c, P
	elseif dest == "carry" then
		local cbar = c * (1 - k) / k
		local wbar = B / k
		for i = 1, C do
			v[i] = ev[i] + win[i] * cbar
		end
		local a = (A + B * cbar) / k - (1 - k) * c * (1 - wbar) / k
		return v, -c * (1 - wbar) + a, 2 * cbar
	end
	error("yard: unknown destination " .. dest)
end

-- The kept set at share k: the top classes by keep value, the last one partly kept.
local function topK(v: { number }, k: number): ({ number }, number)
	local order = table.create(C, 0)
	for i = 1, C do
		order[i] = i
	end
	table.sort(order, function(a, b)
		return v[a] > v[b]
	end)
	local keep = table.create(C, 0)
	local left, margin = k, order[1]
	for _, i in order do
		if left <= 1e-12 then
			break
		end
		local q = math.min(1, left / FREQ[i])
		keep[i] = q
		left -= q * FREQ[i]
		margin = i
	end
	return keep, margin
end

-- Solves for share k: the self-consistent kept set and the price that holds it. The price is
-- math.huge when no price holds it (the marginal hand loses more to a fold the more a fold costs).
function Yard.atShare(t: Tally, dest: string, k: number): Solution
	local keep = table.create(C, 1)
	local c = 0
	local ev, win = Yard.field(t, keep)
	local margin = 1
	for _ = 1, 30 do
		-- Rank against the current field, keep the top k, and re-measure the field they make.
		local nextKeep, m = topK((values(dest, c, keep, ev, win)), k)
		local same = true
		for i = 1, C do
			if math.abs(nextKeep[i] - keep[i]) > 1e-9 then
				same = false
				break
			end
		end
		keep, margin = nextKeep, m
		ev, win = Yard.field(t, keep)
		-- Everything is linear in c once the field is fixed: g(c) = the margin's keep value − a fold's.
		local v0, f0 = values(dest, 0, keep, ev, win)
		local v1, f1 = values(dest, 1, keep, ev, win)
		local g0, g1 = v0[margin] - f0, v1[margin] - f1
		local newC = if g1 - g0 > 1e-12 then -g0 / (g1 - g0) else math.huge
		local settled = same and math.abs(newC - c) < 1e-9
		c = newC
		if settled or c == math.huge then
			break
		end
	end
	local v, f, extra
	if c == math.huge then
		v, f, extra = values(dest, 0, keep, ev, win)
	else
		v, f, extra = values(dest, c, keep, ev, win)
	end
	return {
		dest = dest,
		share = k,
		price = c,
		keep = keep,
		ev = ev,
		win = win,
		value = v,
		fold = f,
		margin = margin,
		extra = extra,
	}
end

export type Metrics = {
	loss: { number }, -- [b + 1]: share of kept matches whose loser lost b units (b = 0: a split)
	meanLoss: number, -- units the loser loses, over decided matches
	modest: number, -- share of kept matches where both river hands are modest (high card or a pair)
	numeric: number, -- share of kept matches between numeric hands with no trick fired
	upset: number, -- share of kept matches won by the worse river category
	modestUpset: number, -- ...by a modest hand
	underdog: number, -- of matches between classes of different EV, how often the lower-EV class wins
	pairs: number, -- share of kept deals: pocket pairs, suited, offsuit, holding an ace
	suited: number,
	offsuit: number,
	ace: number,
	classes: number, -- classes kept at all
}

-- What the kept field looks like: its pots, how often modest hands meet and win, and its make-up.
function Yard.metrics(t: Tally, s: Solution): Metrics
	local keep, ev = s.keep, s.ev
	local loss = table.create(14, 0)
	local n, modest, numeric, upset, mup, dn, dw = 0, 0, 0, 0, 0, 0, 0
	for i = 1, C do
		local qi = keep[i]
		if qi > 0 then
			for j = 1, C do
				local q = qi * keep[j]
				if q > 0 then
					local idx = (i - 1) * C + j
					n += q * t.n[idx]
					modest += q * t.modest[idx]
					numeric += q * t.numeric[idx]
					upset += q * t.upset[idx]
					mup += q * t.modestUpset[idx]
					for b = 1, 14 do
						loss[b] += q * t.loss[(idx - 1) * 14 + b]
					end
					if ev[i] < ev[j] then
						dn += q * t.n[idx]
						dw += q * t.wins[idx]
					end
				end
			end
		end
	end
	local decided, lossSum = 0, 0
	for b = 1, 14 do
		loss[b] /= math.max(n, 1e-12)
		if b > 1 then
			decided += loss[b]
			lossSum += loss[b] * (b - 1)
		end
	end
	local k, pairs, suited, ace, classes = 0, 0, 0, 0, 0
	for i = 1, C do
		local f = FREQ[i] * keep[i]
		if keep[i] > 0 then
			classes += 1
		end
		k += f
		local row, col = (i - 1) // 13 + 2, (i - 1) % 13 + 2
		if row == col then
			pairs += f
		elseif row > col then
			suited += f
		end
		if row == 14 or col == 14 then
			ace += f
		end
	end
	return {
		loss = loss,
		meanLoss = lossSum / math.max(decided, 1e-12),
		modest = modest / n,
		numeric = numeric / n,
		upset = upset / n,
		modestUpset = mup / n,
		underdog = if dn > 0 then dw / dn else 0,
		pairs = pairs / k,
		suited = suited / k,
		offsuit = (k - pairs - suited) / k,
		ace = ace / k,
		classes = classes,
	}
end

-- The equilibrium at price c: unravelling from everyone keeping, riders fold the worst hands until
-- the marginal one is worth keeping. That is the largest share whose holding price is at most c
-- (shares on a 0.5% grid). Returns the solution there, or nil when even 5% needs more than c.
function Yard.atPrice(t: Tally, dest: string, c: number, cache: { [number]: Solution }?): Solution?
	for step = 200, 10, -1 do
		local k = step / 200
		local s = if cache then cache[step] else nil
		if s == nil then
			s = Yard.atShare(t, dest, k)
			if cache then
				cache[step] = s
			end
		end
		if (s :: Solution).price <= c + 1e-9 then
			return s
		end
	end
	return nil
end

return Yard
