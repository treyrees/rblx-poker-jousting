# Sim results: one hand, first runs

Sep 30, 2026. Seed 20260930, 100k hands per run (200k per sweep row: a mirror run plus a
skilled-vs-novice run). The sim is `tools/sim.luau` over `sim/`, and every value it uses is in
`sim/Config.luau`. [SANITY_CHECK.md](SANITY_CHECK.md) says which values are §11's, which the sim
set, and which open questions are modelled as switches.

**Everything here is a proposal.** The sim's numbers come from a model of the aim war, not the
game. Riders are scripted with the four §11 parameters:

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

Average vs average, at the default config, unless noted.

| Target (source) | Result | Met? |
| --- | --- | --- |
| Early passes rarely unhorse; the hand builds toward the river (§2) | Knockouts by pass: P1 0.7%, P2 2.9%, P3 7.3%, P4 16.1%. Pass 1 knockouts are tricks. | Yes |
| Numeric hands order correctly (§11) | Better river category wins: 69.6% at a gap of 1, 82.6% at 2, 89.8% at 3 | Yes, on average |
| Skill decides most numeric matchups; a bad hand is a handicap, not a fold (pillar 2) | Skilled vs novice: skilled wins 71.4% while holding the *worse* category, and 96.3% with the better. Skilled vs average: 48.8% with the worse. | Yes |
| Numeric gap about ×1.0–1.45 on a hit (§4) | Medians ×1.09, ×1.17 and ×1.23 at gaps 1, 2 and 3 (λ = 1). The ♣-only tail passes 1.45 above λ = 1. See *The numeric gap* below. | Yes, for λ ≤ 1 |
| A trick above the opponent, played to design, wins overwhelmingly (pillar 3, 0044) | Unleashed above: 99.1% (n = 10,256). Answering above: 98.9%. Auto-fired on Pass 4 above: 95.1%. | Yes. The threshold is Trey's; not set. |
| A higher trick nearly always beats a lower one across rungs (0044) | 99.6% (n = 244); skilled vs novice 94.8% | Yes |
| The flush ward stops an ace-high straight at full meter; the straight flush beats the quads ward | Pinned by `tests/Tricks.spec.luau` at the starting values | Yes |
| §4 damage checks (3.5 / 43 / 54) | Pinned by `tests/Contact.spec.luau` with the lean, armor and piercing off | Yes |

### Win rate by trick

Unleashed or fired while above the opponent, not clashed.

| Trick | Played to design | Not to design |
| --- | --- | --- |
| Straight | 95.2% (n 2,807) | 97.6% (n 4,539) |
| Flush | 97.3% (n 4,168) | 92.0% (n 413); 72.4% for the novice vs skilled |
| Full house | 99.7% (n 4,333) | n/a (unconditional) |
| Quads | 100% (n 247) | n/a (unconditional) |
| Straight flush | 100% (n 13) | 100% (n 33) |

Other trick metrics:

- **Held, then drawn out:** 3.8% of riders who held a trick while above (n = 8,367).
- **Clashes:** 2,582 clashed tricks. Level tricks cancel in about 1.3–2.6% of hands.
- **Unhorse vs showdown:** 27% : 73% (ratio 0.37). Numeric hands (81.5% of all) unhorse only
  12.9% of the time. **The showdown knockdown decides most hands.**
- **Showdown winner:** the rider ahead on Posture wins 90.1% of showdowns, and the better poker
  hand wins 65.9% (category reading, w = 15).

**Two findings on tricks:**

1. **"Played to design" barely binds for the straight.**
   - At x = 1.3, most straights unhorse from three or four meter cards. So a straight the rider
     didn't hold wins as often as one they did (97.6% vs 95.2%).
   - Where design straights lose more, it's the Pass 4 auto-fire. There the out is live: the
     numeric rider has worn the holder down while they rode as the sub-hand.
2. **The flush's condition does bind.** Aimed off home, its hit is halved or zero.

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
| **defaults** | 0.37 | 0.7 / 2.9 / 7.3 / 16.1 | 69.6 | 82.6 | 89.8 | 71.2 | 97.7 | 97.1 | 99.6 | 3.8 |
| showdown = points (open) | 0.37 | same | 63.7 | 73.4 | 83.1 | 76.2 | 97.7 | 90.6 | 98.4 | 3.8 |
| showdown = lexicographic (open) | 0.37 | same | 80.4 | 82.6 | 85.2 | 57.3 | 97.7 | 95.5 | 99.6 | 3.8 |
| showdown category weight 5 | 0.37 | same | 60.5 | 69.3 | 77.7 | 81.6 | 97.7 | 93.3 | 98.4 | 3.8 |
| showdown category weight 40 | 0.37 | same | 85.6 | 95.3 | 95.2 | 41.1 | 97.7 | 98.3 | 100 | 3.8 |
| holdFloor 0.2 (§11: 0.4) | 0.35 | 0.7 / 2.9 / 7.0 / 15.4 | 72.5 | 84.0 | 93.4 | 59.2 | 98.0 | 97.5 | 98.0 | 3.2 |
| holdFloor 0.6 | 0.48 | 0.7 / 2.8 / 7.7 / 21.2 | 66.6 | 79.7 | 91.8 | 80.4 | 96.3 | 95.6 | 97.1 | 3.4 |
| lean λ = 0 | 0.26 | 0.7 / 2.8 / 6.2 / 11.1 | 70.6 | 84.2 | 92.1 | 71.1 | 98.7 | 98.0 | 98.4 | 3.5 |
| lean λ = 0.5 | 0.31 | 0.7 / 2.9 / 6.5 / 13.7 | 69.9 | 83.3 | 90.6 | 70.8 | 98.2 | 97.4 | 98.3 | 3.2 |
| lean λ = 2 | 0.49 | 0.7 / 2.9 / 9.5 / 19.8 | 69.1 | 81.3 | 91.4 | 71.0 | 96.5 | 95.7 | 98.8 | 3.7 |
| board weight 0.25 (§11: 0.5) | 0.32 | 0.7 / 2.9 / 6.7 / 13.9 | 70.0 | 83.1 | 91.3 | 69.6 | 98.2 | 96.9 | 97.4 | 3.5 |
| armor rate 0.15 | 0.38 | 0.7 / 2.9 / 7.2 / 16.5 | 70.0 | 83.0 | 89.9 | 69.3 | 97.4 | 96.9 | 98.0 | 3.8 |
| armor rate 0.4 | 0.35 | 0.7 / 2.8 / 7.1 / 15.4 | 69.0 | 81.2 | 90.3 | 73.4 | 97.8 | 96.9 | 98.3 | 3.7 |
| ♥ Posture/point 2 | 0.38 | 0.7 / 2.8 / 7.3 / 16.8 | 69.0 | 82.0 | 88.3 | 72.2 | 97.5 | 97.1 | 97.9 | 3.7 |
| ♥ Posture/point 5 | 0.34 | 0.7 / 2.8 / 7.1 / 14.9 | 70.2 | 84.2 | 90.8 | 68.0 | 98.0 | 96.6 | 97.7 | 3.7 |
| ♠ charge 0 | 0.34 | 0.7 / 2.8 / 7.1 / 14.7 | 70.8 | 82.8 | 92.9 | 71.4 | 98.0 | 97.6 | 97.9 | 3.5 |
| ♠ charge 6 | 0.41 | 0.7 / 2.8 / 7.2 / 18.3 | 68.3 | 80.6 | 90.9 | 70.5 | 97.5 | 96.5 | 99.2 | 3.4 |
| straight x = 1.15 | 0.37 | 0.7 / 2.9 / 7.2 / 16.1 | 69.6 | 82.5 | 90.0 | 71.1 | 97.8 | 97.1 | 99.6 | 3.8 |
| straight x = 2, wards not rescaled | 0.37 | 0.6 / 2.7 / 7.2 / 16.2 | 69.9 | 82.4 | 90.2 | 70.9 | 97.5 | 96.5 | **88.3** | 3.7 |
| trick hits and wards ×0.5 | 0.36 | 0.6 / 2.6 / 7.2 / 16.3 | 69.6 | 82.7 | 90.6 | 71.4 | 97.7 | 96.8 | 97.0 | 3.5 |
| slowmo = game (open) | 0.36 | 0.7 / 2.9 / 7.0 / 15.7 | 70.0 | 83.1 | 91.4 | 72.2 | 97.8 | 97.2 | 98.7 | 3.6 |
| slowmo = excluded (open) | 0.35 | 0.7 / 2.9 / 6.9 / 15.5 | 70.3 | 82.9 | 91.8 | 72.8 | 97.6 | 96.8 | 97.0 | 3.5 |
| statBasis = points (c1) | 0.38 | 0.7 / 2.9 / 7.2 / 16.6 | 70.3 | 83.3 | 90.5 | 68.9 | 97.5 | 96.9 | 98.8 | 3.9 |
| flushHit = F2 (c3) | 0.33 | 0.6 / 2.4 / 6.3 / 15.5 | 69.8 | 82.7 | 91.1 | 71.0 | 97.2 | 97.3 | 99.1 | 3.7 |
| meterThreshold = strict (c4) | 0.37 | same as defaults | 69.6 | 82.6 | 89.8 | 71.3 | 98.6 | 96.4 | 99.6 | 3.8 |
| Twin Favor: trick overrides (C1) | 0.37 | 0.7 / 2.9 / 7.3 / 16.2 | 69.6 | 82.6 | 90.0 | 71.0 | 97.8 | 97.1 | 99.6 | 3.7 |
| AA edge = both (C2) | 0.37 | 0.7 / 2.9 / 7.3 / 16.2 | 69.5 | 82.6 | 89.8 | 71.1 | 97.8 | 97.1 | 99.6 | 3.8 |
| AA edge = direction (C2) | 0.37 | 0.7 / 2.9 / 7.3 / 16.2 | 69.5 | 82.6 | 90.1 | 71.2 | 97.8 | 97.2 | 99.6 | 3.8 |

**What moves the results, most to least:**

1. **The showdown knockdown (§11 open).**
   - It decides about 73% of hands.
   - Across its readings and weights, "better category wins at gap 1" ranges from 60% to 86%, and
     the skill flip from 41% to 82%.
   - Nothing else in the table moves either metric by more than a few points. **This is the
     numeric game's main dial, and it is Trey's call.**
2. **The hold floor.** At 0.4:
   - 73.8% of reads switch late rather than stay on the held aim.
   - A rider who always flicks beats one who only holds 84.6% of the time.
   - A steady rider beats a fidgety one only 64% of the time.

   | Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch |
   | --- | --- | --- | --- |
   | 0.2 | 40.7% | 70.9% | 55.5% |
   | 0.3 | 25.4% | 67.2% | 68.4% |
   | 0.4 | 15.4% | 64.0% | 73.4% |
   | 0.5 | 10.5% | 61.0% | 75.1% |
   | 0.6 | 8.5% | 58.2% | 75.4% |

   - This is §3's own arithmetic at work: with the floor above ⅓, a switch onto a held aim wins a
     CN row. So the sim's answer to the §11 question is **yes, 0.4 pushes toward last-instant
     flicks.**
   - Caveat: the holder vs flicker pair is extreme, since the holder never reacts at all.
3. **The lean multiplier λ.**
   - λ = 2 raises Pass 3–4 knockouts (unh:sd 0.49) and pushes the numeric gap's tail past ×1.45.
   - λ ≤ 1 keeps the §4 gap.
4. **The trick chain.** With x = 2 and the wards left at their x = 1.3 sizes, the flush ward no
   longer stops high straights, and the higher trick wins only 88.3% across rungs. Any change to
   the meter must rescale the wards; `tests/Tricks.spec.luau` fails if it doesn't.
5. **Barely moving:** slow-motion reading, stat basis (c1), the flush hit reading (c3), meter
   threshold (c4), C1, C2, armor rate, ♥ rate, charge rate and board weight. Each moves a metric
   by at most a couple of points.
   - C1 and C2 are too rare to show (QQ and AA are each about 0.45% of riders).
   - The slow-motion reading matters mainly for a rider who re-stances after the reveal.

### The numeric gap (§4)

From `--report gap`: 100k river deals with no trick, taking each rider's most-loaded stat.

| λ | Mean multiplier: HC / pair / 2P / trips | Better over worse, median, gap 1 / 2 / 3 | Worse category loads more |
| --- | --- | --- | --- |
| 0 | 1.21 / 1.27 / 1.32 / 1.36 | 1.06 / 1.10 / 1.14 | 22% / 11% / 9% |
| 0.5 | 1.32 / 1.40 / 1.49 / 1.54 | 1.07 / 1.14 / 1.18 | 22% / 11% / 7% |
| 1 | 1.43 / 1.54 / 1.65 / 1.71 | 1.09 / 1.17 / 1.23 | 22% / 11% / 6% |
| 2 | 1.64 / 1.81 / 1.97 / 2.07 | 1.12 / 1.22 / 1.31 | 22% / 11% / 6% |

## Proposed: a last-pass damage bonus

Trey, in chat on Sep 30, 2026: "let's start implementing a modest last-round damage bonus". The
bonus is `proposed.finalPassBonus` in `sim/Config.luau`: an extra multiplier on all Posture damage
in Pass 4, on top of its ×1.25 street multiplier. At 1.0 it is GAME_SPEC as written. It is not in
GAME_SPEC yet.

From `--report final`, 100k hands per row. "Leader into P4 holds on" is how often the rider ahead
going into Pass 4 wins the hand, split by the size of their lead.

| Bonus | Knockoff on Pass 4 | Forced fall | Leader holds on, lead under 20 | Leader holds on, lead 20+ | Better hand wins, gap 1 | Skill flip |
| --- | --- | --- | --- | --- | --- | --- |
| 1.0 (spec) | 16.1% | 73.0% | 63.7% | 86.0% | 69.6% | 71.2% |
| 1.1 | 18.3% | 70.8% | 63.3% | 84.8% | 68.8% | 72.0% |
| 1.2 | 20.7% | 68.5% | 63.0% | 83.6% | 68.0% | 72.8% |
| 1.3 | 23.1% | 66.0% | 62.6% | 82.6% | 67.2% | 73.7% |
| 1.5 | 28.5% | 60.7% | 62.4% | 80.7% | 65.7% | 75.4% |
| 2.0 | 42.6% | 46.5% | 62.7% | 77.5% | 62.5% | 78.9% |

- **The bonus mostly turns forced falls into real knockoffs.** It creates few new comebacks. The
  rider who was going to fall anyway now falls to a lance.
- **Earned leads survive.**
  - A clear lead (20+ Posture) going into Pass 4 still holds 83–86% of the time up to ×1.2–1.3.
  - Close races stay about as open as they are now.
- **Cards matter slightly less and skill slightly more** as the bonus grows. The last pass is a
  dial exchange, not a card comparison.
- **Proposal: ×1.2–1.3.**
  - Pass 4 knockoffs rise from 16% to 21–23% of hands.
  - The clear-lead hold stays above 80%.
  - ×1.5 and above start to make "whoever reads the last pass" a bigger factor. That shows in the
    falling hold on a clear lead: 86% → 78% at ×2.

## Proposals and questions for Trey

Nothing here is applied. §11 and GAME_SPEC are unchanged.

1. **Decide the showdown knockdown (§11 open).** It decides about 73% of hands and is the most
   sensitive setting in the sim. Two readings bracket the choice:
   - `category`, w = 15: the Posture leader wins 90% of showdowns.
   - `lexicographic`: the better hand wins 84%, and the skill flip drops from 71% to 57%.
2. **Hold floor: consider 0.2–0.3 (§11: 0.4).** Below ⅓, holding survives a late switch on a CN
   row, and the steady rider's edge grows from 64% to 67–71%. The cost is fewer flips of a
   numeric matchup by skill (71% → 59% at 0.2), because a held stance is harder to read around.
3. **Lean multiplier: keep λ ≤ 1** so the §4 gap holds, if the gap is meant after the lean
   (SANITY_CHECK c6).
4. **The straight's meter: decide how much holding should matter.**
   - At x = 1.3, an unheld straight wins as often as a held one, so the meter rarely binds.
   - Making it bind needs a steeper meter, or a y mapped to the card's place in the straight
     rather than its rank.
   - Otherwise the wards must grow by x^9 (the wheel-to-ace-high spread). See SANITY_CHECK §2.
5. **Set the "overwhelmingly" number (0044).** The sim gives 95–99% above the opponent. The main
   leak is the Pass 4 auto-fire after the holder has been worn down.
6. **Board weight ¼ vs ½:** a small effect, with slightly fewer late knockouts.
7. The Phase 1 gaps c1–c7 and C1/C2 still stand (SANITY_CHECK §3). C1 and C2 barely move the
   sim; c3 and c4 decide what "played to design" means for the flush and the straight.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** Each reading rider estimates the
  opponent's stats from the board plus an average hole card. There is no reading model of tells:
  jacks, colors and the hold meter as a tell carry no value.
- **The K lock is modelled as "moves last in a double read".**
- **Betting never Yields.** Units won therefore track the win rate.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
