# Sim results: one hand

Oct 2, 2026. GAME_SPEC through decision 0074. Since the last run:

- slow motion doesn't count toward hold (0061);
- the stats are redefined (0067–0070):
  - ♣ Strength: aimed hits Batter the target, who takes +x% damage through their next contact.
  - ♠ Accuracy and ♦ Armor: crits and blocks need less hold, and a lean into either locks later.
  - ♥ Posture: an aimed buffer and a heal after every contact; everyone has 80 Posture.
  - The ♠ charge is gone.
- broadway cards have no effects (0071);
- each flush is its stat at its limit (0072): Shattering Blow Batters for the hand, Unbroken heals
  back the pass;
- the straight's power comes from holding (0073);
- defense isn't weaker than offense, and the sim values are tuned to it (0074).

Runs use seed 20260930 and 100k hands per run; a sweep row is 200k hands (a mirror run plus a
skilled-vs-novice run on seed 20260931). The sim is `tools/sim.luau` over `sim/`, and every value it
uses is in `sim/Config.luau`. The earlier report, through 0054, is in this file's git history.

**Everything here is a proposal.** The numbers come from a model of the aim war, not the game.
Riders are scripted with the four §11 parameters:

- **read:** a late switch to the best aim against the opponent's public aim and hold;
- **hold discipline:** when the stance is committed;
- **stance honesty:** leaning toward your loaded stats, or a random aim;
- **aggression:** raise and unleash timing.

The riders never Yield, so every hand is ridden out (pillar 2).

| Profile | read | hold | honesty |
| --- | --- | --- | --- |
| average | 0.3 | 0.6 | 0.7 |
| skilled | 0.7 | 0.9 | 0.9 |
| novice | 0.05 | 0.3 | 0.4 |

## The new mechanics' starting values

All are "set by the sim" (§11), so they are starting values, not proposals for GAME_SPEC. They were
tuned so that defense isn't weaker than offense (0074).

| Value | Start | What it means |
| --- | --- | --- |
| `battered` | 0.4 | Battered: +40% damage taken, × the striker's ♣ lean weight (full at Up, half on Up-Out and Up-In) |
| `healBase`, `healPerPoint` | 0.1, 0.02 | After contact, heal 10% + 2% per unleaned ♥ point of the damage taken: about 22% with 6 ♥ points |
| `heartBuffer` | 1.5 | Buffer per leaned ♥ point |
| `armorPerPoint` | 1.5 | Armor per ♦ card point, on top of 0057's value conversion (`armorRate` × S♦). A cardless rider keeps the same Guard; without this a ♦ card point was worth a tenth of a ♣ point |
| `armorZone` | Guard 1, thin 0.5, sliver 0.2 | Thick, thin and sliver armor (were 1 / 0.2 / 0.05). With a thinner sliver, crits ignored armor and ♦ stayed under 48% at any rate |
| `critRelief`, `guardRelief` | 0.03 | Per ♠ (♦) card point, the share of the hold multiplier's shortfall restored on a Crit (on Guard armor). A cardless rider gets none, so holding still beats a late switch (0052) |
| `extraTime` | 0.15 s | Extra time past the lock at a full lean into ♠ or ♦. In the sim: when both riders read, the one with more moves last |
| Straight meter | `5.5 · 2^cards · (1 + 0.1·(top − 5))` | Each card held doubles the hit. A full wheel deals 176, enough to clear full Posture with the thicker defense (§6); an ace-high deals 167 at four cards and 334 at five; one or two cards deal 11–42 |

The relief was first built on the stat value (`S/20`), which gave a cardless rider 30% relief on
every late crit. That pushed the skill flip to 77.9%; on card points at 0.03 it is in the mid 60s.

## Headline metrics against the targets

Average vs average, at the defaults, unless noted.

| Target (source) | Result | Met? |
| --- | --- | --- |
| Defense isn't weaker; suits about even (0074) | Hole card of the suit wins: ♣ 49.9%, ♠ 48.7%, ♥ 48.5%, ♦ 48.7% | Yes |
| Turn 10–15%, flop about 1.5–2% (0054; guides, not targets, per 0074) | Flop 1.5%, turn 9.5%, river 89.0% | About |
| Numeric hands order correctly (§11) | Better river category wins 76.2% / 90.3% / 96.1% at gaps 1 / 2 / 3 | Yes |
| Skill flip 55–65% (pillar 2, 0054) | Skilled beats novice with the worse category 66.1%; skilled vs average 38.5% | About; a point over |
| Numeric gap ×1.0–1.45 after the lean, λ ≤ 1 (0062) | Unchanged by this pass (card points only): medians ×1.09 / 1.17 / 1.23 at λ = 1 | Yes |
| A trick above, played to design, wins at least 95% on every path (0064) | Unleashed 97.6% (n 1,844), answering 100% (n 13), auto-fired 100% (n 7,117). Every trick is at 95% or more | Yes |
| A higher trick nearly always beats a lower one (0044) | 99.6% (n 260) | Yes |
| Holding is the straight's power (0073) | Unleashed straights: held 95.2%, not held 91.9%. Before 0073's meter it was 98.8% vs 98.2% | Yes |

### Tricks fired while above, by path and design

From a scratch count over the baseline run (100k hands): tricks fired while above the opponent, not
clashed.

| Path | Played to design | Not to design |
| --- | --- | --- |
| Unleash | 97.6% (n 1,844): flush 95.7%, full house 99.8%, quads 100%, straight 95.2% | 92.1% (n 1,740): straight 91.9%, flush 96.2% |
| Answer | 100% (n 13) | 100% (n 4) |
| Auto-fire on Pass 4 | 100% (n 7,117) | 99.2% (n 4,498) |

Other metrics:

- **Held, then drawn out:** 8.2% (n = 3,332).
- **Unhorse vs showdown:** 11.0% : 89.0%.
- **Showdown:** the rider ahead on Posture after Pass 4's contact (and its heal) wins 85.4%; the
  better poker hand wins 73.5%.
- **Reads:** 71.5% of reads switch late rather than stay on the held aim (63.1% before the pass).

## What each suit and rank is worth now

From a scratch count: 200k hands, average riders, seat 1's hole cards. A hole card's win rate when
it is of that suit (seat 1 wins 49.0% overall).

| | ♣ | ♠ | ♥ | ♦ |
| --- | --- | --- | --- | --- |
| Now | 49.9% | 48.7% | 48.5% | 48.7% |
| At the first starting values | 52.6% | 52.0% | 47.4% | 46.3% |
| Before this pass | 51.1% | 50.1% | 53.1% | 45.7% |

- **The suits are now within 1.4 points** (0074). At the first starting values, ♥ had fallen from
  the strongest suit to the second weakest (it no longer adds Posture, and the heal's ♥ share was
  small), and ♦ was a net loss as it had been before the pass.
- **Ranks climb smoothly** (at the first starting values): 46% for a 2 to 51% for J through A.
  Before 0071 the Q stood out at 62% (its restore and Twin Favor) and the J sat flat at 50.6%.

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
| **defaults** | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 76.2 | 90.3 | 96.1 | 66.1 | 99.5 | 97.2 | 99.6 | 8.2 |
| battered 0 (0068 off) | 0.08 | 0.0 / 0.7 / 7.0 / 0.0 | 78.1 | 91.4 | 98.1 | 64.3 | 99.5 | 97.3 | 99.6 | 8.1 |
| battered 0.6 | 0.15 | 0.0 / 2.4 / 10.8 / 0.0 | 75.7 | 89.2 | 96.8 | 66.9 | 99.3 | 97.2 | 99.6 | 7.9 |
| heal off (0070) | 0.16 | 0.0 / 2.1 / 12.0 / 0.0 | 73.4 | 86.4 | 94.2 | 70.9 | 99.4 | 96.4 | 100 | 7.5 |
| heal 4% per ♥ point | 0.12 | 0.0 / 1.5 / 9.2 / 0.0 | 77.7 | 91.4 | 96.5 | 63.5 | 99.5 | 97.2 | 99.6 | 7.9 |
| ♥ buffer 0.5 | 0.13 | 0.0 / 1.5 / 9.9 / 0.0 | 75.7 | 89.6 | 97.1 | 67.7 | 99.5 | 97.1 | 98.9 | 7.8 |
| ♦ per-point armor 0 | 0.15 | 0.0 / 1.8 / 11.1 / 0.0 | 76.6 | 89.3 | 95.8 | 65.5 | 99.3 | 97.2 | 100 | 7.5 |
| armor zones thin 0.2, sliver 0.05 | 0.15 | 0.0 / 1.9 / 11.2 / 0.0 | 75.7 | 89.0 | 95.1 | 66.8 | 99.4 | 96.9 | 99.2 | 8.2 |
| crit and guard relief 0 (0069 off) | 0.11 | 0.0 / 1.2 / 8.3 / 0.0 | 77.2 | 91.3 | 96.6 | 62.2 | 99.7 | 97.5 | 100 | 7.8 |
| crit and guard relief 0.06 | 0.16 | 0.0 / 2.2 / 11.6 / 0.0 | 75.2 | 88.4 | 95.7 | 69.9 | 99.3 | 96.4 | 100 | 7.6 |
| extraTime 0 (0069 last move off) | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 76.6 | 90.7 | 96.3 | 66.9 | 99.5 | 97.4 | 99.3 | 7.6 |
| straight x = 1.5 (same full wheel) | 0.13 | 0.0 / 1.7 / 10.0 / 0.0 | 76.3 | 90.0 | 96.3 | 66.2 | 99.6 | 98.5 | 99.6 | 7.5 |
| straight rank adds nothing | 0.12 | 0.0 / 1.4 / 9.2 / 0.0 | 76.4 | 90.1 | 97.1 | 66.1 | 99.5 | 95.9 | 98.9 | 8.1 |
| trick hits and wards ×0.5 | 0.12 | 0.0 / 1.4 / 9.0 / 0.0 | 76.3 | 90.1 | 97.2 | 66.1 | 99.5 | 93.9 | 99.3 | 8.4 |
| showdown bonus 10 (0050: 20) | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 67.2 | 79.6 | 91.0 | 78.6 | 99.5 | 94.6 | 99.2 | 8.2 |
| showdown bonus 25 | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 79.8 | 93.2 | 96.5 | 59.0 | 99.5 | 97.6 | 99.6 | 8.2 |
| showdown bonus 30 | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 83.2 | 95.2 | 96.8 | 52.3 | 99.5 | 97.7 | 99.6 | 8.2 |
| Posture start 85 (0054: 80) | 0.10 | 0.0 / 1.0 / 8.1 / 0.0 | 76.9 | 90.9 | 96.7 | 65.4 | 99.6 | 96.7 | 99.6 | 8.3 |
| Pass 1 ×0.75 (0054: 1.0) | 0.10 | 0.0 / 0.8 / 8.3 / 0.0 | 77.4 | 91.4 | 96.0 | 63.9 | 99.6 | 97.2 | 99.7 | 8.0 |
| Pass 3 ×1.25 (0054: 1.0) | 0.19 | 0.0 / 1.5 / 14.5 / 0.0 | 75.3 | 88.4 | 95.6 | 67.8 | 98.9 | 96.9 | 99.6 | 7.6 |
| holdFloor 0.2 (0052: 0.25) | 0.12 | 0.0 / 1.4 / 9.1 / 0.0 | 77.2 | 91.3 | 97.5 | 63.7 | 99.6 | 97.4 | 100 | 7.8 |
| holdFloor 0.4 | 0.16 | 0.0 / 2.0 / 12.2 / 0.0 | 73.9 | 87.6 | 95.9 | 73.6 | 99.3 | 96.4 | 100 | 7.7 |
| holdFloor 0.6 | 0.27 | 0.0 / 3.4 / 17.8 / 0.0 | 70.4 | 83.3 | 93.1 | 81.0 | 98.7 | 95.3 | 98.8 | 7.3 |
| lean λ = 0 | 0.07 | 0.0 / 0.6 / 6.2 / 0.0 | 77.8 | 91.3 | 98.5 | 65.7 | 99.7 | 97.9 | 99.3 | 8.6 |
| lean λ = 0.5 | 0.09 | 0.0 / 0.8 / 7.8 / 0.0 | 77.2 | 91.5 | 97.3 | 65.6 | 99.6 | 97.2 | 98.3 | 8.1 |
| lean λ = 2 | 0.19 | 0.0 / 4.0 / 12.3 / 0.0 | 75.6 | 88.5 | 95.6 | 65.9 | 99.2 | 96.9 | 99.6 | 7.6 |
| board weight 0.25 (§11: 0.5) | 0.11 | 0.0 / 1.1 / 8.5 / 0.0 | 76.6 | 90.8 | 97.2 | 64.1 | 99.7 | 97.2 | 98.9 | 7.8 |
| armor rate 0.15 | 0.13 | 0.0 / 1.7 / 10.1 / 0.0 | 76.5 | 90.0 | 96.9 | 64.8 | 99.4 | 97.1 | 99.3 | 7.9 |
| armor rate 0.4 | 0.11 | 0.0 / 1.3 / 8.6 / 0.0 | 76.2 | 90.3 | 96.6 | 66.7 | 99.5 | 97.0 | 99.3 | 8.0 |
| slowmo = wall (0061: excluded) | 0.14 | 0.0 / 1.8 / 10.4 / 0.0 | 75.8 | 88.8 | 95.6 | 63.9 | 99.5 | 96.6 | 100 | 7.6 |
| slowmo = game | 0.13 | 0.0 / 1.6 / 9.9 / 0.0 | 76.1 | 90.0 | 96.1 | 65.3 | 99.4 | 96.9 | 99.3 | 8.2 |
| statBasis = points (0057: value) | 0.14 | 0.0 / 1.6 / 10.4 / 0.0 | 76.9 | 91.1 | 96.5 | 63.2 | 99.5 | 97.2 | 99.2 | 7.8 |
| flushHit = F2 (0059: F1) | 0.12 | 0.0 / 1.4 / 9.2 / 0.0 | 76.5 | 89.9 | 96.3 | 65.9 | 99.1 | 97.2 | 96.2 | 7.5 |
| meterThreshold = strict (0060: reachable) | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 76.2 | 90.3 | 96.1 | 66.1 | 99.5 | 97.6 | 99.6 | 8.2 |
| turn cushion ½ (not adopted) | 0.09 | 0.0 / 1.5 / 7.0 / 0.0 | 76.9 | 91.1 | 97.9 | 65.3 | 100 | 97.8 | 99.4 | 7.8 |
| before 0053–0054 (Posture 100, 0.5 / 0.75 / 1.0 / 1.625, unhorse on P4) | 0.36 | 0.0 / 0.4 / 2.4 / 23.5 | 76.8 | 89.8 | 96.2 | 63.0 | 96.7 | 91.0 | 99.7 | 8.3 |

**What moves the results, most to least:**

1. **The showdown bonus (20)** still decides the most: it lands in nearly 90% of hands. The flip is
   79%, 66%, 59% and 52% at 10, 20, 25 and 30 per step.
2. **The hold floor and the relief** both price late switches. The floor at 0.4 puts the flip at
   74%; relief at 0.06 per point puts it at 70%.
3. **The heal:** off, turn endings rise to 12% and the flip to 71%. A larger heal favors the better
   hand, because it blunts the reads that skill lands.
4. **Battered** sets how often hands end early: turn endings are 7.0% without it and 10.8% at 0.6.
5. **The lean λ** is unchanged in effect: λ = 2 more than doubles flop endings and pushes the gap's
   tail past ×1.45.
6. **Barely moving:** extra time, the meter's base, armor rate, board weight and the settled
   switches. Extra time moves little because the sim's only use for it is who moves last when both
   riders read.

### The hold floor (0052)

From `--report floor`, 100k hands per run. The holder never reads and holds from the first moment;
the flicker always reads and never holds. Steady and fidget are the average rider with hold
discipline 1 and 0 (both read 30%).

| Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch |
| --- | --- | --- | --- |
| 0.2 | 25.9% | 64.6% | 68.4% |
| **0.25** | **21.5%** | **63.0%** | **71.5%** |
| 0.3 | 17.6% | 61.8% | 73.4% |
| 0.4 | 12.7% | 59.8% | 75.1% |
| 0.6 | 7.0% | 56.0% | 75.4% |

- Holding still pays: the steady rider beats the fidgety one 63% of the time.
- The pure holder does worse than before (21.5%, from 32.8%). The flicker always reads, and the
  ♠/♦ relief and Battered both reward the hit that a read lands. The holder is extreme: it never
  reacts at all.

### The numeric gap (§4)

From `--report gap`: 100k river deals with no trick, taking each rider's most-loaded stat. It
depends on card points and the lean only, so the stats pass leaves it unchanged.

| λ | Mean multiplier: HC / pair / 2P / trips | Better over worse, median, gap 1 / 2 / 3 | Worse category loads more |
| --- | --- | --- | --- |
| 0 | 1.21 / 1.27 / 1.32 / 1.36 | 1.06 / 1.10 / 1.14 | 22% / 11% / 9% |
| 0.5 | 1.32 / 1.40 / 1.49 / 1.54 | 1.07 / 1.14 / 1.18 | 22% / 11% / 7% |
| 1 | 1.43 / 1.54 / 1.65 / 1.71 | 1.09 / 1.17 / 1.23 | 22% / 11% / 6% |
| 2 | 1.64 / 1.81 / 1.97 / 2.07 | 1.12 / 1.22 / 1.31 | 22% / 11% / 6% |

## Questions for Trey

Nothing here is applied.

1. **Board weight ¼ vs ½:** still a small effect.
2. **The skill flip is 66.1%,** a point over 0054's 55–65%. The ranges are guides (0074); the hold
   relief (0.03 per point) or the floor are the levers if it should come down.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** Each reading rider estimates the
  opponent's stats from the board plus an average hole card. There is no reading model of tells:
  colors and the hold meter as a tell carry no value.
- **Extra time past the lock is modelled as "moves last in a double read".** A real rider with
  extra time would also react to single reads.
- **Betting never Yields.** Units won therefore track the win rate.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
