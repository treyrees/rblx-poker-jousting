# Sim results: one hand

Sep 30, 2026. GAME_SPEC through decision 0051 (PR #10):

- the river flips on the final pass;
- the showdown adds 20 Posture per hand-category step, and the lower rider falls;
- Pass 4 carries a ×1.3 last-pass bonus.

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
| Early passes rarely unhorse; the hand builds toward the river (§2) | Knockouts by pass: P1 0.0%, P2 0.7%, P3 3.3%, P4 27.5%. Pass 1 has no trick and no reveal. | Yes |
| Numeric hands order correctly (§11) | Better river category wins: 71.4% at a gap of 1, 85.5% at 2, 92.9% at 3 | Yes, on average |
| Skill decides most numeric matchups; a bad hand is a handicap, not a fold (pillar 2) | Skilled vs novice: skilled wins 67.7% while holding the *worse* category, and 95.2% with the better. Skilled vs average: 45.7% with the worse. | Yes |
| Numeric gap about ×1.0–1.45 on a hit (§4) | Medians ×1.09, ×1.17 and ×1.23 at gaps 1, 2 and 3 (λ = 1). The ♣-only tail passes 1.45 above λ = 1. See *The numeric gap* below. | Yes, for λ ≤ 1 |
| A trick above the opponent, played to design, wins overwhelmingly (pillar 3, 0044) | Unleashed above: 98.7% (n = 3,671). Answering above: 100% (n = 13). Auto-fired on Pass 4 above: 92.3% (n = 12,754). | Unleashes yes; the Pass 4 auto-fire is lower. The threshold is Trey's; not set. |
| A higher trick nearly always beats a lower one across rungs (0044) | 99.4% (n = 314) | Yes |
| The flush ward stops an ace-high straight at full meter; the straight flush beats the quads ward | Pinned by `tests/Tricks.spec.luau` at the starting values: hits from Pass 2 (×0.75), wards against Pass 4 (×1.625) | Yes |
| §4 damage checks (3.5 / 43 / 71) | Pinned by `tests/Contact.spec.luau` with the lean, armor and piercing off | Yes |

### Win rate by trick

Fired while above the opponent, not clashed.

| Trick | Played to design | Not to design |
| --- | --- | --- |
| Straight | 92.0% (n 1,094) | 91.1% (n 6,169) |
| Flush | 92.5% (n 4,067) | 90.6% (n 394) |
| Full house | 98.9% (n 4,361) | n/a (unconditional) |
| Quads | 100% (n 294) | n/a (unconditional) |
| Straight flush | 100% (n 12) | 100% (n 47) |

Other metrics:

- **Held, then drawn out:** 9.5% of riders who held a trick while above (n = 3,383).
- **Clashes:** 2,597 clashed tricks, so level tricks cancel in about 1.3–2.6% of hands.
- **Unhorse vs showdown:** 31.5% : 68.5% (ratio 0.46).
- **Numeric hands** (81.7% of all) unhorse 18.4% of the time.
- **Showdown winner:** the rider ahead on Posture before the bonus wins 88.0% of showdowns, and the
  better poker hand wins 67.5%.

What the trick numbers show:

1. **Most tricks now fire on the final pass.** 78% of tricks fire by auto-fire, because most
   tricks first appear on the river.
2. **Auto-fired tricks win less (92.3%) than tricks unleashed early (98.7%).** On the final pass
   the numeric rider's out is at its widest. They have had three passes to wear the holder down,
   and every hit lands at ×1.625.
3. **"Played to design" barely separates straights (92.0% vs 91.1%).** A straight that lands on
   the river rarely reaches a full meter: only 15% of straights fire at full meter. At x = 1.3
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
| **defaults** | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 71.4 | 85.5 | 92.9 | 67.1 | 95.5 | 91.1 | 99.4 | 9.5 |
| showdown bonus 10 (0050: 20) | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 63.9 | 74.5 | 81.9 | 77.9 | 95.5 | 89.4 | 99.0 | 9.5 |
| showdown bonus 30 | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 77.7 | 91.5 | 94.8 | 55.4 | 95.5 | 91.6 | 99.7 | 9.5 |
| last-pass bonus 1.0 (0051: 1.3) | 0.33 | 0.0 / 0.7 / 3.3 / 20.6 | 74.4 | 88.9 | 95.8 | 63.4 | 97.3 | 94.6 | 99.4 | 9.5 |
| holdFloor 0.2 (§11: 0.4) | 0.42 | 0.0 / 0.8 / 3.1 / 25.5 | 74.8 | 87.1 | 93.9 | 54.3 | 96.6 | 92.1 | 99.7 | 9.6 |
| holdFloor 0.6 | 0.65 | 0.0 / 0.7 / 3.5 / 35.1 | 66.9 | 80.5 | 87.6 | 78.7 | 93.3 | 88.0 | 99.7 | 8.8 |
| lean λ = 0 | 0.33 | 0.0 / 0.7 / 2.8 / 21.4 | 72.5 | 87.1 | 93.1 | 65.9 | 96.9 | 93.7 | 100 | 9.4 |
| lean λ = 0.5 | 0.40 | 0.0 / 0.7 / 3.0 / 24.6 | 72.0 | 86.3 | 94.0 | 66.4 | 96.1 | 92.2 | 99.3 | 9.0 |
| lean λ = 2 | 0.59 | 0.0 / 0.7 / 4.8 / 31.4 | 70.6 | 82.7 | 89.5 | 67.8 | 94.7 | 89.4 | 99.1 | 8.6 |
| board weight 0.25 (§11: 0.5) | 0.41 | 0.0 / 0.7 / 3.1 / 25.1 | 71.6 | 85.2 | 93.3 | 65.7 | 96.7 | 91.7 | 99.7 | 9.4 |
| armor rate 0.15 | 0.48 | 0.0 / 0.7 / 3.3 / 28.3 | 71.7 | 85.4 | 93.6 | 65.1 | 95.1 | 90.6 | 99.4 | 8.7 |
| armor rate 0.4 | 0.44 | 0.0 / 0.7 / 3.3 / 26.4 | 70.6 | 83.8 | 90.8 | 69.7 | 96.2 | 91.7 | 99.0 | 9.8 |
| ♥ Posture/point 2 | 0.49 | 0.0 / 0.7 / 3.4 / 28.9 | 70.7 | 84.1 | 93.3 | 68.4 | 95.2 | 90.6 | 99.3 | 8.9 |
| ♥ Posture/point 5 | 0.42 | 0.0 / 0.7 / 3.2 / 25.5 | 72.2 | 85.9 | 93.7 | 64.0 | 96.0 | 91.8 | 99.0 | 9.4 |
| ♠ charge 0 | 0.41 | 0.0 / 0.7 / 3.3 / 25.0 | 73.0 | 85.9 | 93.7 | 66.6 | 95.9 | 92.1 | 99.7 | 9.2 |
| ♠ charge 6 | 0.54 | 0.0 / 0.7 / 3.3 / 31.2 | 68.9 | 82.4 | 89.7 | 67.3 | 94.8 | 90.4 | 99.4 | 8.8 |
| straight x = 1.15 | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 71.4 | 85.4 | 92.8 | 67.1 | 95.5 | 91.1 | 99.4 | 9.5 |
| straight x = 2, wards not rescaled | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 71.2 | 84.6 | 93.1 | 67.1 | 95.3 | 91.1 | **90.2** | 9.3 |
| trick hits and wards ×0.5 | 0.46 | 0.0 / 0.7 / 3.4 / 27.5 | 71.3 | 84.9 | 92.9 | 67.0 | 95.5 | 91.1 | 99.4 | 9.4 |
| slowmo = game (open) | 0.44 | 0.0 / 0.7 / 3.3 / 26.5 | 71.6 | 85.9 | 92.9 | 68.3 | 95.9 | 91.3 | 99.7 | 9.9 |
| slowmo = excluded (open) | 0.42 | 0.0 / 0.7 / 3.1 / 25.9 | 71.6 | 85.7 | 93.4 | 69.4 | 96.0 | 91.9 | 99.3 | 9.6 |
| statBasis = points (c1) | 0.48 | 0.0 / 0.7 / 3.4 / 28.6 | 71.8 | 85.5 | 92.1 | 64.8 | 95.4 | 90.6 | 99.1 | 8.6 |
| flushHit = F2 (c3) | 0.43 | 0.0 / 0.6 / 3.0 / 26.4 | 70.8 | 84.8 | 94.4 | 66.9 | 95.3 | 91.3 | 99.7 | 8.8 |
| meterThreshold = strict (c4) | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 71.4 | 85.5 | 92.9 | 67.1 | 95.9 | 91.3 | 99.4 | 9.5 |
| Twin Favor: trick overrides (C1) | 0.46 | 0.0 / 0.7 / 3.3 / 27.6 | 71.3 | 85.4 | 93.1 | 67.0 | 95.6 | 91.0 | 99.4 | 9.5 |
| AA edge = both (C2) | 0.46 | 0.0 / 0.7 / 3.3 / 27.4 | 71.4 | 85.6 | 93.1 | 67.0 | 95.6 | 91.2 | 99.0 | 9.6 |
| AA edge = direction (C2) | 0.46 | 0.0 / 0.7 / 3.3 / 27.5 | 71.5 | 85.4 | 93.0 | 67.1 | 95.4 | 91.1 | 99.4 | 9.8 |

**What moves the results, most to least:**

1. **The showdown bonus (0050: 20).** It still decides about two thirds of hands.
   - At 10, 20 and 30 per step, "better category wins at gap 1" is 64%, 71% and 78%.
   - The skill flip is 78%, 67% and 55%.
   - 20 keeps skill ahead of the cards: a skilled rider still beats a novice two times in three
     while holding the worse hand.
2. **The hold floor.** At 0.4, 73.3% of reads switch late rather than stay on the held aim.

   | Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch |
   | --- | --- | --- | --- |
   | 0.2 | 41.0% | 70.2% | 54.4% |
   | 0.3 | 26.6% | 66.5% | 68.3% |
   | 0.4 | 16.6% | 62.9% | 73.3% |
   | 0.5 | 11.2% | 60.0% | 75.2% |
   | 0.6 | 8.0% | 57.8% | 75.3% |

   - A steady rider beats a fidgety one only 63% of the time.
   - This is §3's own arithmetic at work: with the floor above ⅓, a switch onto a held aim wins a
     CN row. So the sim's answer to the §11 question is **yes, 0.4 pushes toward last-instant
     flicks.**
   - Caveat: the holder vs flicker pair is extreme, since the holder never reacts at all.
3. **The last-pass bonus (0051: 1.3).** See below.
4. **The lean multiplier λ.**
   - λ = 2 raises final-pass knockouts (unh:sd 0.59) and pushes the numeric gap's tail past ×1.45.
   - λ ≤ 1 keeps the §4 gap.
5. **The trick chain.** With x = 2 and the wards left at their x = 1.3 sizes, the flush ward no
   longer stops high straights, and the higher trick wins only 90.2% across rungs. Any change to
   the meter must rescale the wards; `tests/Tricks.spec.luau` fails if it doesn't.
6. **Barely moving:** slow-motion reading, stat basis (c1), the flush hit reading (c3), meter
   threshold (c4), C1, C2, armor rate, ♥ rate, charge rate and board weight. Each moves a metric
   by at most a few points.
   - C1 and C2 are too rare to show (QQ and AA are each about 0.45% of riders).

### The last-pass bonus (0051)

From `--report final`, 100k hands per row. "Leader holds on" is how often the rider ahead going
into Pass 4 wins the hand, split by the size of their lead.

| Bonus | Knockoff on Pass 4 | Forced fall | Leader holds on, lead under 20 | Leader holds on, lead 20+ | Better hand wins, gap 1 | Skill flip |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 | 20.6% | 75.4% | 61.6% | 83.1% | 74.4% | 63.4% |
| 1.1 | 22.6% | 73.3% | 61.3% | 82.2% | 73.4% | 64.6% |
| 1.2 | 24.9% | 71.0% | 61.2% | 81.1% | 72.4% | 65.9% |
| **1.3** | **27.5%** | **68.5%** | **61.1%** | **80.3%** | **71.4%** | **67.1%** |
| 1.5 | 32.8% | 63.2% | 61.0% | 78.7% | 69.4% | 69.4% |
| 2.0 | 47.5% | 48.5% | 61.6% | 76.1% | 65.1% | 74.3% |

- **The bonus mostly turns forced falls into real knockoffs.** It creates few new comebacks.
- **Earned leads survive.** A clear lead (20+ Posture) going into Pass 4 still holds 80% of the
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

Nothing here is applied. Decision 1 (the showdown, the pass order and the last-pass bonus) is
done: 0049–0051. Still open:

1. **Hold floor: consider 0.2–0.3 (§11: 0.4).** Below ⅓, holding survives a late switch on a CN
   row, and the steady rider's edge grows from 63% to 67–70%. The cost is fewer flips of a
   numeric matchup by skill (67% → 54% at 0.2), because a held stance is harder to read around.
2. **The straight's meter: decide how much holding should matter.**
   - At x = 1.3, an unheld straight wins as often as a held one.
   - With the river on the final pass, straights that complete there rarely reach a full meter,
     since the rider had to be holding before they knew.
   - Making the meter bind needs a steeper meter, or a y mapped to the card's place in the
     straight rather than its rank.
   - Otherwise the wards must grow by x^9 (the wheel-to-ace-high spread). See SANITY_CHECK §2.
3. **The Phase 1 gaps c1–c7** (SANITY_CHECK §3). C1 and C2 barely move the sim; c3 and c4 decide
   what "played to design" means for the flush and the straight.
4. **Set the "overwhelmingly" number (0044).** The sim gives 98.7% for an unleash above the
   opponent and 92.3% for a Pass 4 auto-fire. The auto-fire leak is the numeric out at ×1.625
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
