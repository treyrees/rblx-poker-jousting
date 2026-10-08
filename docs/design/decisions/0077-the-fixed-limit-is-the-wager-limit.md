---
id: 0077
title: The fixed limit is the wager limit; no pot cap in v1
date: 2026-10-08
decided-by: trey (chat, wager limits session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§11 asked: "Wager limits: cap the pot (for example 3× ante) so a loss stays cheap?" It is the root
of the economy chain: the prefold cost is priced in units, the redraw is priced against the prefold,
and ghost betting conditions on the stakes.

§2's betting is already fixed limit: Ante 1, raise sizes 1 / 1 / 2 / 2 before Passes 1–4, one
re-raise per round. The most a rider can lose in one hand is 1 + 2 + 2 + 4 + 4 = 13 units, and
only by calling every raise and re-raise. Every unit past the ante is a call; a rider who Yields to
the first raise loses exactly the ante. So the question presupposed forced losses that §2 doesn't
have: the Yield is already the loss cap, and the fixed limit is the win cap.

The options put to Trey:

- **A.** The fixed limit is the cap: 13× ante at most, no change to §2.
- **B.** A pot cap at 3× ante. A raise and re-raise on Bet 1 reaches it, so Bets 2–4 could only
  Stay or Yield; betting mostly ends preflop, against §1's "every bet is a commitment to ride into
  the next card", and the biggest win is 3 units.
- **C.** Flatter limits: raise 1 on every street, capping a hand at 9×.
- **D.** Defer it all to the Economy row until currency and the Roblox policy question are settled.

The sim (100k hands, today's defaults) could say only what a hand is worth when nobody raises. Its
scripted betting raises only on an owned trick or trips with a Posture lead and never Yields, so
96.4% of lost hands cost the ante (average vs average; 95.4% skilled vs novice), the mean loss is
1.08 units (1.10), and the worst starting hands lose about 0.2 units a hand (32o −0.23, 43o −0.21,
62o −0.19; about ±0.03 of noise) while the best pairs win about +0.6 (KK +0.61, JJ +0.58, AA +0.57).
It has no model of betting strategy, so it can't say what real pots look like under A, B or C.

## Decision

Trey chose **A**: "A."

- In v1 the fixed limit is the wager limit. There is no pot cap on top of §2's raise sizes and
  re-raise cap: a hand costs between 1 and 13 units, and every unit past the ante is a call.
- Currency-side limits stay Open on the Economy row with the Roblox question: what a unit is
  worth, session or daily stakes, and staking only earned currency.

## Consequences

- §2 *Betting rules* says that the fixed limit is the wager limit and names the 13-unit maximum.
  §1 Status gains a Settled row for wager limits, and the Economy row narrows to currency, the
  currency side of stakes, and monetization. The §11 wager-limit question closes; the currency-side
  limits join the §11 Roblox question.
- Nothing in the sim changes: `spec.raise` and `spec.ante` already carry §2, and no defaults move.
- The unit scale is fixed for the rest of the economy chain. The ante is the smallest loss a played
  hand can take, and the worst starting hands' ante-only EV is about −0.2 units; those are the
  anchors for the prefold cost (§11, next).
