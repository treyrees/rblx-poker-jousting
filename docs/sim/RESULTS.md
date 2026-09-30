# Sim results: one hand

Sep 30, 2026. GAME_SPEC through decision 0052:

- the river flips on the final pass;
- the showdown adds 20 Posture per hand-category step, and the lower rider falls;
- Pass 4 carries a ×1.3 last-pass bonus;
- the hold multiplier is 0.25 + 0.75 × h (0052; it was 0.4 + 0.6 × h).

**Stale since 0053–0054** (the river always goes to the knockdown; Posture 80; street
multipliers 1.0 / 1.0 / 1.0 / 1.25; no last-pass bonus). The numbers below are from before them
and need a rerun. The headline numbers at the new defaults are in 0054.

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
| Early passes rarely unhorse; the hand builds toward the river (§2) | Knockouts by pass: P1 0.0%, P2 0.7%, P3 3.1%, P4 25.8%. Pass 1 has no trick and no reveal. | Yes |
| Numeric hands order correctly (§11) | Better river category wins: 74.2% at a gap of 1, 86.4% at 2, 92.5% at 3 | Yes, on average |
| Skill decides most numeric matchups; a bad hand is a handicap, not a fold (pillar 2) | Skilled vs novice: skilled wins 57.4% while holding the *worse* category, and 95.5% with the better. Skilled vs average: 37.7% with the worse. | Yes, by less than at a floor of 0.4 (67.7%). See *The hold floor* below. |
| Numeric gap about ×1.0–1.45 on a hit (§4) | Medians ×1.09, ×1.17 and ×1.23 at gaps 1, 2 and 3 (λ = 1). The ♣-only tail passes 1.45 above λ = 1. See *The numeric gap* below. | Yes, for λ ≤ 1 |
| A trick above the opponent, played to design, wins overwhelmingly (pillar 3, 0044) | Unleashed above: 99.3% (n = 3,614). Answering above: 100% (n = 12). Auto-fired on Pass 4 above: 93.7% (n = 12,819). | Unleashes yes; the Pass 4 auto-fire is lower. The threshold is Trey's; not set. |
| A higher trick nearly always beats a lower one across rungs (0044) | 100% (n = 304) | Yes |
| The flush ward stops an ace-high straight at full meter; the straight flush beats the quads ward | Pinned by `tests/Tricks.spec.luau` at the starting values: hits from Pass 2 (×0.75), wards against Pass 4 (×1.625) | Yes |
| §4 damage checks (3.1 / 43 / 71) | Pinned by `tests/Contact.spec.luau` with the lean, armor and piercing off | Yes |

### Win rate by trick

Fired while above the opponent, not clashed.

| Trick | Played to design | Not to design |
| --- | --- | --- |
| Straight | 93.2% (n 1,116) | 92.2% (n 6,155) |
| Flush | 94.9% (n 4,115) | 90.6% (n 339) |
| Full house | 99.3% (n 4,382) | n/a (unconditional) |
| Quads | 99.6% (n 276) | n/a (unconditional) |
| Straight flush | 100% (n 14) | 100% (n 48) |

Other metrics:

- **Held, then drawn out:** 9.5% of riders who held a trick while above (n = 3,398).
- **Clashes:** 2,538 clashed tricks, so level tricks cancel in about 1.3–2.5% of hands.
- **Unhorse vs showdown:** 29.7% : 70.3% (ratio 0.42).
- **Numeric hands** (81.7% of all) unhorse 16.2% of the time.
- **Showdown winner:** the rider ahead on Posture before the bonus wins 87.1% of showdowns, and the
  better poker hand wins 69.4%.

What the trick numbers show:

1. **Most tricks now fire on the final pass.** 78% of tricks fire by auto-fire, because most
   tricks first appear on the river.
2. **Auto-fired tricks win less (93.7%) than tricks unleashed early (99.3%).** On the final pass
   the numeric rider's out is at its widest. They have had three passes to wear the holder down,
   and every hit lands at ×1.625.
3. **"Played to design" barely separates straights (93.2% vs 92.2%).** A straight that lands on
   the river rarely reaches a full meter: only 15% of straights fired at full meter (0051 run;
   the report doesn't print this, and the floor doesn't enter the meter). At x = 1.3
   most straights unhorse from three or four meter cards anyway. That is Decision 3.

## Sensitivity

Each row changes one thing from the defaults. Column key:

- **unh:sd:** unhorse-to-showdown ratio.
- **gap1–gap3:** better category wins, mirror.
- **flip:** the skilled rider wins with the worse category, vs a novice.
- **above/design, above/off:** tricks fired above the opponent, played to design or not.
- **cross:** the higher trick wins a cross-rung pass.
- **drawn:** held tricks drawn out.

| Config | unh:sd | KO P1 / P2 / P3 / P4 (%) | gap1 | gap2 | gap3 | flip | above/design | above/off | cross | drawn |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **defaults** | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 74.2 | 86.4 | 92.5 | 56.8 | 96.8 | 92.2 | 100 | 9.5 |
| showdown bonus 10 (0050: 20) | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 65.7 | 77.6 | 85.5 | 70.1 | 96.8 | 90.7 | 99.7 | 9.5 |
| showdown bonus 30 | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 79.9 | 91.7 | 95.1 | 44.6 | 96.8 | 92.6 | 100 | 9.5 |
| last-pass bonus 1.0 (0051: 1.3) | 0.31 | 0.0 / 0.7 / 3.1 / 19.9 | 76.5 | 89.6 | 96.3 | 53.7 | 97.9 | 95.1 | 100 | 9.5 |
| holdFloor 0.2 (0052: 0.25) | 0.42 | 0.0 / 0.8 / 3.1 / 25.5 | 74.8 | 87.1 | 93.9 | 54.3 | 96.6 | 92.1 | 99.7 | 9.6 |
| holdFloor 0.4 (was §11) | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 71.4 | 85.5 | 92.9 | 67.1 | 95.5 | 91.1 | 99.4 | 9.5 |
| holdFloor 0.6 | 0.65 | 0.0 / 0.7 / 3.5 / 35.1 | 66.9 | 80.5 | 87.6 | 78.7 | 93.3 | 88.0 | 99.7 | 8.8 |
| lean λ = 0 | 0.31 | 0.0 / 0.7 / 2.8 / 20.0 | 75.9 | 88.4 | 96.3 | 53.9 | 97.4 | 95.1 | 99.6 | 9.3 |
| lean λ = 0.5 | 0.37 | 0.0 / 0.7 / 2.9 / 23.1 | 75.2 | 87.5 | 91.9 | 55.2 | 96.7 | 93.4 | 100 | 9.4 |
| lean λ = 2 | 0.52 | 0.0 / 0.7 / 4.5 / 29.0 | 72.8 | 84.9 | 90.2 | 58.8 | 95.5 | 90.8 | 99.3 | 8.0 |
| board weight 0.25 (§11: 0.5) | 0.39 | 0.0 / 0.7 / 3.0 / 24.2 | 74.5 | 86.7 | 93.6 | 56.9 | 97.1 | 92.7 | 99.7 | 9.2 |
| armor rate 0.15 | 0.43 | 0.0 / 0.7 / 3.2 / 26.1 | 74.4 | 86.8 | 92.9 | 55.4 | 96.4 | 92.0 | 100 | 9.2 |
| armor rate 0.4 | 0.41 | 0.0 / 0.7 / 3.2 / 24.9 | 73.9 | 86.4 | 91.8 | 58.0 | 96.8 | 93.0 | 99.7 | 9.6 |
| ♥ Posture/point 2 | 0.44 | 0.0 / 0.7 / 3.3 / 26.7 | 73.6 | 86.1 | 93.1 | 57.7 | 96.4 | 91.8 | 99.7 | 9.1 |
| ♥ Posture/point 5 | 0.39 | 0.0 / 0.7 / 3.1 / 24.2 | 74.7 | 87.3 | 93.8 | 54.5 | 96.5 | 93.0 | 100 | 9.0 |
| ♠ charge 0 | 0.37 | 0.0 / 0.7 / 3.1 / 23.3 | 75.4 | 87.8 | 94.9 | 56.1 | 97.0 | 93.1 | 100 | 8.8 |
| ♠ charge 6 | 0.49 | 0.0 / 0.7 / 3.2 / 29.0 | 71.7 | 83.8 | 90.6 | 57.8 | 96.0 | 91.4 | 100 | 9.9 |
| straight x = 1.15 | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 74.2 | 86.4 | 92.5 | 56.8 | 96.8 | 92.2 | 100 | 9.5 |
| straight x = 2, wards not rescaled | 0.42 | 0.0 / 0.7 / 3.1 / 25.9 | 74.1 | 86.4 | 91.7 | 56.8 | 96.5 | 92.1 | **92.6** | 9.4 |
| trick hits and wards ×0.5 | 0.42 | 0.0 / 0.7 / 3.1 / 25.9 | 73.9 | 86.4 | 92.0 | 56.8 | 96.7 | 92.1 | 100 | 9.3 |
| slowmo = game (open) | 0.39 | 0.0 / 0.7 / 3.1 / 24.4 | 74.6 | 87.3 | 93.8 | 58.5 | 96.6 | 92.9 | 99.3 | 9.5 |
| slowmo = excluded (open) | 0.38 | 0.0 / 0.7 / 3.0 / 23.6 | 75.0 | 87.5 | 93.8 | 59.8 | 96.7 | 93.5 | 99.4 | 9.7 |
| statBasis = points (c1) | 0.43 | 0.0 / 0.7 / 3.2 / 26.2 | 74.7 | 87.0 | 93.5 | 54.8 | 96.7 | 91.9 | 100 | 9.1 |
| flushHit = F2 (c3) | 0.39 | 0.0 / 0.6 / 2.9 / 24.4 | 73.9 | 86.5 | 93.1 | 56.5 | 96.2 | 92.6 | 100 | 8.9 |
| meterThreshold = strict (c4) | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 74.2 | 86.4 | 92.5 | 56.8 | 97.2 | 92.3 | 100 | 9.5 |
| Twin Favor: trick overrides (C1) | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 74.1 | 86.4 | 92.5 | 56.7 | 96.7 | 92.4 | 100 | 9.5 |
| AA edge = both (C2) | 0.42 | 0.0 / 0.7 / 3.1 / 25.8 | 74.1 | 86.3 | 92.7 | 56.6 | 96.8 | 92.3 | 100 | 9.6 |
| AA edge = direction (C2) | 0.42 | 0.0 / 0.7 / 3.1 / 25.9 | 74.2 | 86.5 | 92.8 | 56.6 | 96.8 | 92.2 | 100 | 9.4 |

**What moves the results, most to least:**

1. **The showdown bonus (0050: 20).** It still decides about two thirds of hands.
   - At 10, 20 and 30 per step, "better category wins at gap 1" is 66%, 74% and 80%.
   - The skill flip is 70%, 57% and 45%.
   - At 20, skill stays ahead of the cards, but by less than at the old floor: a skilled rider
     beats a novice 57% of the time while holding the worse hand (67% at a floor of 0.4). At 30
     the cards win.
2. **The hold floor (0052: 0.25).** See *The hold floor* below.
3. **The last-pass bonus (0051: 1.3).** See below.
4. **The lean multiplier λ.**
   - λ = 2 raises final-pass knockouts (unh:sd 0.52) and pushes the numeric gap's tail past ×1.45.
   - λ ≤ 1 keeps the §4 gap.
5. **The trick chain.** With x = 2 and the wards left at their x = 1.3 sizes, the flush ward no
   longer stops high straights, and the higher trick wins only 92.6% across rungs. Any change to
   the meter must rescale the wards; `tests/Tricks.spec.luau` fails if it doesn't.
6. **Barely moving:** slow-motion reading, stat basis (c1), the flush hit reading (c3), meter
   threshold (c4), C1, C2, armor rate, ♥ rate, charge rate and board weight. Each moves a metric
   by at most a few points.
   - C1 and C2 are too rare to show (QQ and AA are each about 0.45% of riders).

### The hold floor (0052)

From `--report floor`, 100k hands per run. The holder never reads and holds from the first moment;
the flicker always reads and never holds. Steady and fidget are the average rider with hold
discipline 1 and 0 (both read 30%).

| Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch | Skill flip (sweeps) |
| --- | --- | --- | --- | --- |
| 0.2 | 41.0% | 70.2% | 54.4% | 54.3% |
| **0.25** | **33.2%** | **68.2%** | **62.9%** | **56.8%** |
| 0.3 | 26.6% | 66.5% | 68.3% | 59.7% |
| 0.4 (was §11) | 16.6% | 62.9% | 73.3% | 67.1% |
| 0.5 | 11.2% | 60.0% | 75.2% | n/a |
| 0.6 | 8.0% | 57.8% | 75.3% | 78.7% |

- **At 0.4 a late switch onto a held aim won every CN row**, since the floor was above ⅓ (§3). At
  0.25 it only beats a hold of under two thirds of the run-up.
- **Holding pays more.** The steady rider's edge over the fidgety one grows from 63% to 68%, and
  fewer reads switch late (63%, down from 73%).
- **Skill flips fewer numeric matchups** (57%, down from 67%), because a held stance is harder to
  read around. The sim's only reader is a late switch at 7.4 s, which a low floor taxes; a real
  reader who switches earlier and builds hold on the new aim is not modelled, so this likely
  overstates the cost.
- The 0.3 flip comes from a separate run (`--report sweeps --set spec.holdFloor=0.3`, defaults
  row), not the sweep list.
- Caveat: the holder vs flicker pair is extreme, since the holder never reacts at all.

### The last-pass bonus (0051)

From `--report final`, 100k hands per row. "Leader holds on" is how often the rider ahead going
into Pass 4 wins the hand, split by the size of their lead.

| Bonus | Knockoff on Pass 4 | Forced fall | Leader holds on, lead under 20 | Leader holds on, lead 20+ | Better hand wins, gap 1 | Skill flip |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 19.9% | 76.2% | 63.9% | 85.4% | 76.5% | 53.7% |
| 1.1 | 21.7% | 74.5% | 63.6% | 84.6% | 75.7% | 54.7% |
| 1.2 | 23.6% | 72.5% | 63.4% | 83.9% | 74.9% | 55.7% |
| **1.3** | **25.8%** | **70.3%** | **63.2%** | **83.3%** | **74.2%** | **56.8%** |
| 1.5 | 30.5% | 65.7% | 63.2% | 82.1% | 72.6% | 58.6% |
| 2.0 | 42.9% | 53.3% | 63.8% | 80.3% | 69.4% | 63.1% |

- **The bonus mostly turns forced falls into real knockoffs.** It creates few new comebacks.
- **Earned leads survive.** A clear lead (20+ Posture) going into Pass 4 still holds 83% of the
  time at ×1.3. Close races stay about as open as without the bonus.
- **Cards matter slightly less and skill slightly more** as the bonus grows. The last pass is a
  dial exchange, not a card comparison.

### The numeric gap (§4)

From `--report gap`: 100k river deals with no trick, taking each rider's most-loaded stat.

| λ | Mean multiplier: HC / pair / 2P / trips | Better over worse, median, gap 1 / 2 / 3 | Worse category loads more |
| --- | --- | --- | --- |
| 0 | 1.21 / 1.27 / 1.32 / 1.36 | 1.06 / 1.10 / 1.14 | 22% / 11% / 9% |
| 0.5 | 1.32 / 1.40 / 1.49 / 1.54 | 1.07 / 1.14 / 1.18 | 22% / 11% / 7% |
| 1 | 1.43 / 1.54 / 1.65 / 1.71 | 1.09 / 1.17 / 1.23 | 22% / 11% / 6% |
| 2 | 1.64 / 1.81 / 1.97 / 2.07 | 1.12 / 1.22 / 1.31 | 22% / 11% / 6% |

## Questions for Trey

Nothing here is applied. Decisions 1 (the showdown, the pass order and the last-pass bonus:
0049–0051) and 2 (the hold floor: 0052) are done. Still open:

1. **The skill flip after 0052.** A skilled rider now beats a novice 57% of the time while holding
   the worse category (67% before). That still meets pillar 2, with less margin. The showdown bonus
   now moves it further: 70% at 10 per step, 45% at 30. The whole showdown problem, and the
   options beyond the bonus's size, are in [SHOWDOWN.md](SHOWDOWN.md).
2. **The straight's meter: decide how much holding should matter.**
   - At x = 1.3, an unheld straight wins about as often as a held one (93.2% vs 92.2%).
   - With the river on the final pass, straights that complete there rarely reach a full meter,
     since the rider had to be holding before they knew.
   - Making the meter bind needs a steeper meter, or a y mapped to the card's place in the
     straight rather than its rank.
   - Otherwise the wards must grow by x^9 (the wheel-to-ace-high spread). See SANITY_CHECK §2.
3. **The Phase 1 gaps c1–c7** (SANITY_CHECK §3). C1 and C2 barely move the sim; c3 and c4 decide
   what "played to design" means for the flush and the straight.
4. **Set the "overwhelmingly" number (0044).** The sim gives 99.3% for an unleash above the
   opponent and 93.7% for a Pass 4 auto-fire. The auto-fire leak is the numeric out at ×1.625
   after three passes of wear.
5. **Lean multiplier: keep λ ≤ 1** so the §4 gap holds, if the gap is meant after the lean
   (SANITY_CHECK c6).
6. **Board weight ¼ vs ½:** a small effect, with slightly fewer late knockouts.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** Each reading rider estimates the
  opponent's stats from the board plus an average hole card. There is no reading model of tells:
  jacks, colors and the hold meter as a tell carry no value.
- **The K lock is modelled as "moves last in a double read".**
- **Betting never Yields.** Units won therefore track the win rate.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
