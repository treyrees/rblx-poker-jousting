# Sim results: one hand

Sep 30, 2026. GAME_SPEC through decision 0054:

- the river flips on the final pass (0049);
- Pass 4's contact unhorses no one: each rider's hand bonus (20 Posture per category step) is added
  to their Posture, even below 0, and the lower rider falls (0050, 0053);
- Posture starts at 80, and the street multipliers are 1.0 / 1.0 / 1.0 / 1.25, with no last-pass
  bonus (0054);
- the hold multiplier is 0.25 + 0.75 × h (0052).

Runs use seed 20260930 and 100k hands per run; a sweep row is 200k hands (a mirror run plus a
skilled-vs-novice run). The sim is `tools/sim.luau` over `sim/`, and every value it uses is in
`sim/Config.luau`. [SANITY_CHECK.md](SANITY_CHECK.md) says which values are §11's, which the sim
set, and which open questions are modelled as switches.

**Everything here is a proposal.** The numbers come from a model of the aim war, not the game.
Riders are scripted with the four §11 parameters:

- **read:** a late switch to the best aim against the opponent's public aim and hold;
- **hold discipline:** when the stance is committed;
- **stance honesty:** leaning toward your loaded stats, or a random aim;
- **aggression:** raise and unleash timing.

The riders never Yield, so every hand is ridden out (pillar 2). The J and JJ effects and the
colors have no reading model, so jacks are worth their rank points only (§5 sim note).

The rider profiles used below:

| Profile | read | hold | honesty |
| --- | --- | --- | --- |
| average | 0.3 | 0.6 | 0.7 |
| skilled | 0.7 | 0.9 | 0.9 |
| novice | 0.05 | 0.3 | 0.4 |

## Headline metrics against the targets

Average vs average, at the defaults, unless noted.

| Target (source) | Result | Met? |
| --- | --- | --- |
| Most hands see all five cards and end on the river; some end on the turn, fewer on the flop (§2, 0054: turn 10–15%, flop about 1.5–2%) | Hands ending on Pass 1 0.0%, Pass 2 (flop) 1.6%, Pass 3 (turn) 11.4%; the river 87.0%. Pass 4 unhorses no one (0053). | Yes |
| Numeric hands order correctly (§11) | Better river category wins: 73.8% at a gap of 1, 87.4% at 2, 92.6% at 3 | Yes, on average |
| Skill decides most numeric matchups; a bad hand is a handicap, not a fold (pillar 2; 0054: skill flip 55–65%) | Skilled vs novice: skilled wins 60.2% while holding the *worse* category, and 96.9% with the better (the sweeps' flip, on seed 20260931, is 60.4%). Skilled vs average: 40.1% with the worse. | Yes, mid-range |
| Numeric gap about ×1.0–1.45 on a hit (§4) | Medians ×1.09, ×1.17 and ×1.23 at gaps 1, 2 and 3 (λ = 1). The ♣-only tail passes 1.45 above λ = 1. See *The numeric gap* below. | Yes, for λ ≤ 1 |
| A trick above the opponent, played to design, wins overwhelmingly (pillar 3, 0044) | Unleashed above: 95.8% (n = 3,682). Answering above: 100% (n = 12). Auto-fired on Pass 4 above: 99.7% (n = 11,386). | Auto-fires yes; unleashes lower, accepted for now (0054). The threshold is Trey's; not set. |
| A higher trick nearly always beats a lower one across rungs (0044) | 99.3% (n = 269) | Yes |
| The flush ward stops an ace-high straight at full meter; the straight flush beats the quads ward | Pinned by `tests/Tricks.spec.luau` at the starting values: hits from Pass 2 (×1.0), wards against Pass 4 (×1.25) | Yes |
| §4 damage checks (6.3 / 43 / 54) | Pinned by `tests/Contact.spec.luau` with the lean, armor and piercing off | Yes |

### Win rate by trick

Fired while above the opponent, not clashed.

| Trick | Played to design | Not to design |
| --- | --- | --- |
| Straight | 98.8% (n 1,113) | 98.2% (n 5,800) |
| Flush | 98.8% (n 3,687) | 94.2% (n 327) |
| Full house | 100% (n 3,871) | n/a (unconditional) |
| Quads | 100% (n 243) | n/a (unconditional) |
| Straight flush | 100% (n 11) | 100% (n 28) |

Other metrics:

- **Held, then drawn out:** 7.8% of riders who held a trick while above (n = 3,373).
- **Clashes:** 2,378 clashed tricks, so level tricks cancel in about 1.2–2.4% of hands.
- **Unhorse vs showdown:** 13.0% : 87.0% (ratio 0.15). Every showdown is a river ending.
- **Numeric hands** (81.8% of all) end by an unhorse 9.6% of the time, all on Passes 2–3.
- **Showdown winner:** the rider ahead on Posture after Pass 4's contact wins 89.3% of showdowns,
  and the better poker hand wins 73.3%.

What the trick numbers show:

1. **Most tricks fire on the final pass**, by auto-fire, because most tricks first appear on the
   river.
2. **Auto-fired tricks now win more (99.7%) than unleashed ones (95.8%).** Before 0053 it was the
   other way round (93.7% and 99.3%).
   - Pass 4 no longer unhorses on contact, so a held trick that auto-fires can't be lanced down on
     the same contact, and its bonus (80 Posture or more) lands on top.
   - An unleash happens on the flop or the turn, where Posture 80 and the flat early multipliers
     let the numeric rider lance the trick rider down on that same contact more often. Trey
     accepted this for now (0054).
3. **"Played to design" barely separates straights (98.8% vs 98.2%).** A straight that lands on
   the river rarely reaches a full meter, and at x = 1.3 most straights unhorse from three or
   four meter cards anyway. See question 2.

## Sensitivity

Each row changes one thing from the defaults. Column key:

- **unh:sd:** unhorse-to-showdown ratio.
- **KO:** hands ending by an unhorse on each pass. Pass 4 is always 0 under 0053.
- **gap1–gap3:** better category wins, mirror.
- **flip:** the skilled rider wins with the worse category, vs a novice.
- **above/design, above/off:** tricks fired above the opponent (unleashed, answered or
  auto-fired), played to design or not.
- **cross:** the higher trick wins a cross-rung pass.
- **drawn:** held tricks drawn out.

| Config | unh:sd | KO P1 / P2 / P3 / P4 (%) | gap1 | gap2 | gap3 | flip | above/design | above/off | cross | drawn |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **defaults** | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.4 | 92.6 | 60.4 | 99.3 | 98.0 | 99.3 | 7.8 |
| before 0053–0054 (Posture 100, 0.5 / 0.75 / 1.0 / 1.25 × 1.3, unhorse on Pass 4) | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 74.2 | 86.4 | 92.5 | 56.8 | 96.8 | 92.2 | 100 | 9.5 |
| Posture start 85 (0054: 80) | 0.12 | 0.0 / 1.2 / 9.5 / 0.0 | 73.6 | 87.2 | 96.1 | 60.2 | 99.3 | 98.0 | 99.7 | 7.8 |
| Pass 1 ×0.75 (0054: 1.0) | 0.11 | 0.0 / 0.9 / 9.3 / 0.0 | 75.3 | 87.8 | 94.5 | 58.0 | 99.5 | 98.1 | 99.3 | 7.0 |
| Pass 3 ×1.25 (0054: 1.0) | 0.22 | 0.0 / 1.5 / 16.4 / 0.0 | 72.3 | 84.6 | 91.9 | 61.6 | 99.0 | 96.7 | 99.6 | 7.4 |
| turn cushion ½ (not adopted) | 0.11 | 0.0 / 1.6 / 8.5 / 0.0 | 74.2 | 89.1 | 95.7 | 59.8 | 99.9 | 99.0 | 99.6 | 7.6 |
| showdown bonus 10 (0050: 20) | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 65.3 | 76.8 | 86.9 | 73.1 | 99.3 | 96.5 | 98.9 | 7.8 |
| showdown bonus 25 | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 77.3 | 90.6 | 94.6 | 54.2 | 99.4 | 98.2 | 99.6 | 7.8 |
| showdown bonus 30 | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 80.4 | 92.9 | 96.0 | 48.4 | 99.4 | 98.4 | 99.6 | 7.8 |
| holdFloor 0.2 (0052: 0.25) | 0.14 | 0.0 / 1.5 / 11.2 / 0.0 | 73.8 | 87.9 | 93.9 | 58.2 | 99.3 | 98.1 | 99.6 | 7.9 |
| holdFloor 0.4 (was §11) | 0.17 | 0.0 / 1.8 / 12.4 / 0.0 | 71.8 | 85.6 | 92.4 | 68.8 | 99.2 | 97.6 | 99.6 | 7.2 |
| holdFloor 0.6 | 0.26 | 0.0 / 2.5 / 18.2 / 0.0 | 68.8 | 81.2 | 88.2 | 80.0 | 99.0 | 96.4 | 99.3 | 7.1 |
| lean λ = 0 | 0.09 | 0.0 / 0.8 / 7.1 / 0.0 | 75.6 | 89.2 | 96.3 | 58.4 | 99.7 | 98.3 | 98.7 | 7.5 |
| lean λ = 0.5 | 0.11 | 0.0 / 1.0 / 9.3 / 0.0 | 74.7 | 87.9 | 95.8 | 58.9 | 99.5 | 98.1 | 99.3 | 8.0 |
| lean λ = 2 | 0.22 | 0.0 / 3.5 / 14.3 / 0.0 | 72.6 | 84.4 | 90.5 | 61.8 | 99.2 | 97.2 | 98.7 | 7.3 |
| board weight 0.25 (§11: 0.5) | 0.14 | 0.0 / 1.4 / 11.1 / 0.0 | 73.3 | 86.4 | 94.5 | 60.0 | 99.5 | 98.1 | 98.9 | 8.3 |
| armor rate 0.15 | 0.15 | 0.0 / 1.6 / 11.7 / 0.0 | 74.2 | 87.6 | 93.7 | 58.7 | 99.3 | 97.9 | 99.3 | 7.6 |
| armor rate 0.4 | 0.14 | 0.0 / 1.5 / 10.6 / 0.0 | 72.8 | 86.1 | 92.9 | 62.9 | 99.4 | 98.2 | 99.3 | 8.5 |
| ♥ Posture/point 2 | 0.16 | 0.0 / 1.7 / 12.2 / 0.0 | 73.3 | 86.6 | 91.8 | 61.1 | 99.4 | 98.1 | 99.3 | 7.6 |
| ♥ Posture/point 5 | 0.13 | 0.0 / 1.5 / 10.1 / 0.0 | 74.5 | 87.7 | 94.3 | 59.0 | 99.3 | 98.3 | 99.7 | 8.4 |
| ♠ charge 0 | 0.14 | 0.0 / 1.5 / 10.5 / 0.0 | 74.5 | 88.2 | 93.6 | 60.3 | 99.4 | 98.3 | 99.6 | 8.2 |
| ♠ charge 6 | 0.17 | 0.0 / 1.6 / 12.6 / 0.0 | 72.5 | 86.2 | 92.8 | 60.3 | 99.3 | 97.8 | 99.7 | 7.7 |
| straight x = 1.15 | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.4 | 92.6 | 60.4 | 99.3 | 98.0 | 99.3 | 7.8 |
| straight x = 2, wards not rescaled | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.5 | 92.5 | 60.4 | 98.9 | 97.8 | **79.8** | 7.7 |
| trick hits and wards ×0.5 | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.5 | 92.6 | 60.5 | 99.4 | 97.9 | 99.3 | 7.6 |
| slowmo = game (open) | 0.14 | 0.0 / 1.4 / 10.6 / 0.0 | 74.5 | 87.9 | 93.9 | 62.0 | 99.4 | 98.0 | 99.3 | 7.2 |
| slowmo = excluded (open) | 0.13 | 0.0 / 1.4 / 9.9 / 0.0 | 75.0 | 87.7 | 95.8 | 63.1 | 99.5 | 98.2 | 100 | 7.9 |
| statBasis = points (c1) | 0.15 | 0.0 / 1.5 / 11.8 / 0.0 | 74.7 | 87.6 | 93.3 | 57.8 | 99.4 | 97.9 | 98.6 | 7.3 |
| flushHit = F2 (c3) | 0.14 | 0.0 / 1.5 / 10.9 / 0.0 | 74.1 | 87.0 | 93.3 | 60.3 | 99.0 | 97.7 | 98.6 | 8.3 |
| meterThreshold = strict (c4) | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.4 | 92.6 | 60.4 | 99.4 | 98.1 | 99.3 | 7.8 |
| Twin Favor: trick overrides (C1) | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.6 | 92.5 | 60.4 | 99.3 | 97.9 | 99.3 | 7.9 |
| AA edge = both (C2) | 0.15 | 0.0 / 1.6 / 11.3 / 0.0 | 73.9 | 87.5 | 92.5 | 60.6 | 99.3 | 98.0 | 99.3 | 8.0 |
| AA edge = direction (C2) | 0.15 | 0.0 / 1.6 / 11.4 / 0.0 | 73.8 | 87.2 | 92.9 | 60.4 | 99.3 | 98.0 | 99.3 | 7.9 |

**What moves the results, most to least:**

1. **The showdown bonus (20).** It lands in every river ending, 87% of hands.
   - At 10, 20, 25 and 30 per step, "better category wins at gap 1" is 65%, 74%, 77% and 80%.
   - The skill flip is 73%, 60%, 54% and 48%. 0054's range of 55–65% sits between about 16 and 24.
2. **The hold floor (0052: 0.25).** At 0.4 the flip rises to 69%, and at 0.6 to 80%. See *The
   hold floor* below.
3. **Posture start and the street multipliers (0054)** set how often hands end before the river.
   - Posture 85 or Pass 1 at ×0.75 drops turn endings under 10%.
   - Pass 3 at ×1.25 raises them to 16%.
4. **The lean multiplier λ.**
   - λ = 2 raises early endings (turn 14%, flop 3.5%) and pushes the numeric gap's tail past ×1.45.
   - λ ≤ 1 keeps the §4 gap.
5. **The trick chain.** With x = 2 and the wards left at their x = 1.3 sizes, the flush ward no
   longer stops high straights, and the higher trick wins only 79.8% across rungs, down from 92.6%
   before 0054: the flatter Pass 2 and Pass 4 multipliers leave less room. Any change to the meter
   must rescale the wards; `tests/Tricks.spec.luau` fails if it doesn't.
6. **Barely moving:** slow-motion reading, stat basis (c1), the flush hit reading (c3), meter
   threshold (c4), C1, C2, armor rate, ♥ rate, charge rate and board weight. Each moves a metric
   by at most a few points.
   - C1 and C2 are too rare to show (QQ and AA are each about 0.45% of riders).

### The river rule and the retune (0053, 0054)

From the sweep's "before" row and the defaults row above.

| | Before | After |
| --- | --- | --- |
| Hands ending on the flop / turn / river | 0.7% / 3.1% / 96% | 1.6% / 11.4% / 87% |
| …of which ended by a lance on Pass 4 | 25.8% | 0 (the knockdown decides every river ending) |
| Better category wins at gap 1 | 74.2% | 73.8% |
| Skill flip | 56.8% | 60.4% |
| Tricks above, to design / off design | 96.8% / 92.2% | 99.3% / 98.0% |
| Held tricks drawn out | 9.5% | 7.8% |

- **The balance barely moved while the ending changed.** Gap 1 is within half a point; the flip
  is 3.6 points more toward skill, mid-way in Trey's 55–65%.
- **Tricks as a whole win more,** because the held trick that auto-fires on Pass 4, most of them,
  no longer gets lanced down on the same contact. Only the unleash on an earlier pass pays more
  (99.3% → 95.8%).
- **At the river,** the rider who falls was already taken to 0 or below by the lance in about 35%
  of river endings. The bonus overturns the Posture order after contact in about 11% (a scratch
  count, not a report).

### The hold floor (0052)

From `--report floor`, 100k hands per run. The holder never reads and holds from the first moment;
the flicker always reads and never holds. Steady and fidget are the average rider with hold
discipline 1 and 0 (both read 30%).

| Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch | Skill flip (sweeps) |
| --- | --- | --- | --- | --- |
| 0.2 | 41.1% | 72.1% | 54.4% | 58.2% |
| **0.25** | **32.8%** | **70.4%** | **63.2%** | **60.4%** |
| 0.3 | 26.0% | 68.7% | 69.1% | n/a |
| 0.4 (was §11) | 15.9% | 65.1% | 73.8% | 68.8% |
| 0.5 | 10.5% | 62.1% | 75.4% | n/a |
| 0.6 | 7.7% | 59.3% | 75.3% | 80.0% |

- **At 0.4 a late switch onto a held aim won every CN row**, since the floor was above ⅓ (§3). At
  0.25 it only beats a hold of under two thirds of the run-up.
- **Holding pays.** The steady rider beats the fidgety one 70% of the time at 0.25, against 65%
  at 0.4, and fewer reads switch late (63%, down from 74%).
- **Skill flips fewer numeric matchups at a lower floor** (60% at 0.25, 69% at 0.4), because a
  held stance is harder to read around. The sim's only reader is a late switch at 7.4 s, which a
  low floor taxes; a real reader who switches earlier and builds hold on the new aim is not
  modelled, so this likely overstates the cost.
- Caveat: the holder vs flicker pair is extreme, since the holder never reacts at all.

### The numeric gap (§4)

From `--report gap`: 100k river deals with no trick, taking each rider's most-loaded stat. Passes
and Posture don't enter it, so 0053–0054 leave it unchanged.

| λ | Mean multiplier: HC / pair / 2P / trips | Better over worse, median, gap 1 / 2 / 3 | Worse category loads more |
| --- | --- | --- | --- |
| 0 | 1.21 / 1.27 / 1.32 / 1.36 | 1.06 / 1.10 / 1.14 | 22% / 11% / 9% |
| 0.5 | 1.32 / 1.40 / 1.49 / 1.54 | 1.07 / 1.14 / 1.18 | 22% / 11% / 7% |
| 1 | 1.43 / 1.54 / 1.65 / 1.71 | 1.09 / 1.17 / 1.23 | 22% / 11% / 6% |
| 2 | 1.64 / 1.81 / 1.97 / 2.07 | 1.12 / 1.22 / 1.31 | 22% / 11% / 6% |

## Questions for Trey

Nothing here is applied. Decisions on the showdown, the pass order and the damage shape
(0049–0051, 0053, 0054) and on the hold floor (0052) are done. Still open:

1. **Set the "overwhelmingly" number (0044).** Unleashed above wins 95.8%, auto-fired above
   99.7%. The gap is the numeric rider lancing an unleashed trick rider down on the flop or the
   turn. 0054 accepted it for now; a fix would belong to the tricks.
2. **The straight's meter: decide how much holding should matter.**
   - At x = 1.3, an unheld straight wins about as often as a held one (98.2% vs 98.8%).
   - With the river on the final pass, straights that complete there rarely reach a full meter,
     since the rider had to be holding before they knew.
   - Making the meter bind needs a steeper meter, or a y mapped to the card's place in the
     straight rather than its rank.
   - Otherwise the wards must grow by x^9 (the wheel-to-ace-high spread), and at x = 2 the chain
     already fails (cross-rung 79.8%). See SANITY_CHECK §2.
3. **The Phase 1 gaps c1–c7** (SANITY_CHECK §3), including C1 (Twin Favor against a trick hit).
   C1 and C2 barely move the sim; c3 and c4 decide what "played to design" means for the flush
   and the straight.
4. **Lean multiplier: keep λ ≤ 1** so the §4 gap holds, if the gap is meant after the lean
   (SANITY_CHECK c6).
5. **Board weight ¼ vs ½:** a small effect.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** Each reading rider estimates the
  opponent's stats from the board plus an average hole card. There is no reading model of tells:
  jacks, colors and the hold meter as a tell carry no value.
- **The K lock is modelled as "moves last in a double read".**
- **Betting never Yields.** Units won therefore track the win rate.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
