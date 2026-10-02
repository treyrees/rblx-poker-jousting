# Sim results: one hand

Oct 2, 2026. GAME_SPEC through decision 0073. Since the last run:

- slow motion doesn't count toward hold (0061);
- the stats are redefined (0067–0070):
  - ♣ Strength: aimed hits Batter the target, who takes +x% damage through their next contact.
  - ♠ Accuracy and ♦ Armor: crits and blocks need less hold, and a lean into either locks later.
  - ♥ Posture: an aimed buffer and a heal after every contact; everyone has 80 Posture.
  - The ♠ charge is gone.
- broadway cards have no effects (0071);
- each flush is its stat at its limit (0072): Shattering Blow Batters for the hand, Unbroken heals
  back the pass;
- the straight's power comes from holding (0073).

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

All are "set by the sim" (§11), so they are starting values, not proposals for GAME_SPEC.

| Value | Start | What it means |
| --- | --- | --- |
| `battered` | 0.25 | Battered: +25% damage taken, × the striker's ♣ lean weight (full at Up, half on Up-Out and Up-In) |
| `healShare` | 0.15 | After contact, heal 15% × S♥/20 of the damage taken: 15% cardless, about 20% with 6 ♥ points |
| `heartBuffer` | 0.5 | Buffer per leaned ♥ point (unchanged from the old ♥ cut) |
| `critRelief`, `guardRelief` | 0.03 | Per ♠ (♦) card point, the share of the hold multiplier's shortfall restored on a Crit (on Guard armor). A cardless rider gets none, so holding still beats a late switch (0052) |
| `extraTime` | 0.15 s | Extra time past the lock at a full lean into ♠ or ♦. In the sim: when both riders read, the one with more moves last |
| Straight meter | `3.5 · 2^cards · (1 + 0.1·(top − 5))` | Each card held doubles the hit. A full wheel deals 112 (clears full Posture); an ace-high deals 106 at four cards and 213 at five; one or two cards deal 7–27 |

The relief was first built on the stat value (`S/20`), which gave a cardless rider 30% relief on
every late crit. The skill flip rose to 77.9%, against 0054's 55–65%. On card points at 0.03 it is
63.9%.

## Headline metrics against the targets

Average vs average, at the defaults, unless noted.

| Target (source) | Result | Met? |
| --- | --- | --- |
| Turn 10–15%, flop about 1.5–2% (0054) | Flop 1.0%, turn 9.8%, river 89.2% | Just under, both. See question 1 |
| Numeric hands order correctly (§11) | Better river category wins 77.4% / 90.6% / 96.0% at gaps 1 / 2 / 3 | Yes |
| Skill flip 55–65% (pillar 2, 0054) | Skilled beats novice with the worse category 63.9%; skilled vs average 39.3% | Yes |
| Numeric gap ×1.0–1.45 after the lean, λ ≤ 1 (0062) | Unchanged by this pass (card points only): medians ×1.09 / 1.17 / 1.23 at λ = 1 | Yes |
| A trick above, played to design, wins at least 95% on every path (0064) | Unleashed 97.6% (n 1,955), answering 100% (n 9), auto-fired 100% (n 7,194) | Yes. The held straight on an unleash is 94.6% (n 130), within noise |
| A higher trick nearly always beats a lower one (0044) | 99.6% (n 260) | Yes |
| Holding is the straight's power (0073) | Unleashed straights: held 94.6%, not held 87.9%. All straights fired above: 99.3% held, 95.9% not | Yes. Before the change it was 98.8% vs 98.2% |

### Tricks fired while above, by path and design

From a scratch count over the baseline run (100k hands): tricks fired while above the opponent, not
clashed.

| Path | Played to design | Not to design |
| --- | --- | --- |
| Unleash | 97.6% (n 1,955): flush 96.4%, full house 99.1%, quads 100%, straight 94.6% | 88.0% (n 1,711): straight 87.9%, flush 90.6% |
| Answer | 100% (n 9) | 100% (n 4) |
| Auto-fire on Pass 4 | 100% (n 7,194) | 98.9% (n 4,565) |

Other metrics:

- **Held, then drawn out:** 7.9% (n = 3,354).
- **Unhorse vs showdown:** 10.8% : 89.2%.
- **Showdown:** the rider ahead on Posture after Pass 4's contact (and its heal) wins 83.3%; the
  better poker hand wins 73.7%.
- **Reads:** 69.3% of reads switch late rather than stay on the held aim (63.1% before the pass).

## What each suit and rank is worth now

From a scratch count: 200k hands, average riders, seat 1's hole cards. A hole card's win rate
when it is of that suit, or of that rank (the other card random).

| | ♣ | ♠ | ♥ | ♦ |
| --- | --- | --- | --- | --- |
| One hole card of the suit | 52.6% | 52.0% | 47.4% | 46.3% |
| Both hole cards of the suit | 57.4% | 56.0% | 48.1% | 45.0% |
| Before this pass (one / both) | 51.1 / 53.9% | 50.1 / 51.9% | 53.1 / 58.3% | 45.7 / 43.1% |

- **The red suits are now both below 50%.** ♦ was already a net loss; ♥ fell from the strongest
  suit to the second weakest, because ♥ no longer adds Posture and the heal's ♥ share is small.
  These are starting values (`healShare`, `heartBuffer`, `armorRate`, `guardRelief`), not the
  design. See question 2.
- **Ranks climb smoothly,** 46% for a 2 to 51% for J through A. Before 0071 the Q stood out at 62%
  (its restore and Twin Favor) and the J sat flat at 50.6%.

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
| **defaults** | 0.12 | 0.0 / 1.0 / 9.8 / 0.0 | 77.4 | 90.6 | 96.0 | 63.9 | 99.5 | 96.0 | 99.6 | 7.9 |
| battered 0 (0068 off) | 0.09 | 0.0 / 0.6 / 7.2 / 0.0 | 78.9 | 92.4 | 97.8 | 61.9 | 99.6 | 96.4 | 99.3 | 9.1 |
| battered 0.5 | 0.16 | 0.0 / 2.2 / 11.7 / 0.0 | 75.6 | 88.8 | 94.5 | 65.8 | 99.4 | 95.9 | 99.6 | 7.6 |
| healShare 0 (0070 heal off) | 0.19 | 0.0 / 1.8 / 14.0 / 0.0 | 73.8 | 86.9 | 93.1 | 70.1 | 99.2 | 95.3 | 99.6 | 8.0 |
| healShare 0.3 | 0.08 | 0.0 / 0.7 / 6.6 / 0.0 | 82.3 | 94.7 | 98.3 | 54.9 | 99.7 | 96.5 | 100 | 8.1 |
| crit and guard relief 0 (0069 off) | 0.11 | 0.0 / 0.8 / 8.7 / 0.0 | 78.6 | 91.5 | 96.6 | 59.2 | 99.6 | 96.5 | 99.6 | 7.7 |
| crit and guard relief 0.06 | 0.16 | 0.0 / 1.6 / 12.0 / 0.0 | 75.9 | 89.0 | 96.6 | 68.5 | 99.2 | 95.6 | 98.4 | 7.5 |
| extraTime 0 (0069 last move off) | 0.12 | 0.0 / 1.0 / 9.6 / 0.0 | 77.5 | 90.8 | 96.4 | 63.8 | 99.6 | 96.1 | 99.6 | 7.6 |
| straight x = 1.5 (same full wheel) | 0.13 | 0.0 / 1.2 / 10.4 / 0.0 | 77.2 | 91.1 | 96.0 | 63.7 | 99.5 | 97.7 | 98.4 | 7.9 |
| straight rank adds nothing | 0.12 | 0.0 / 1.0 / 9.6 / 0.0 | 77.5 | 90.3 | 95.3 | 64.5 | 99.5 | 94.5 | 99.6 | 7.6 |
| trick hits and wards ×0.5 | 0.12 | 0.0 / 1.0 / 9.6 / 0.0 | 77.6 | 90.2 | 95.3 | 64.2 | 99.5 | 93.3 | 99.6 | 7.4 |
| showdown bonus 10 (0050: 20) | 0.12 | 0.0 / 1.0 / 9.8 / 0.0 | 67.9 | 79.3 | 90.4 | 78.8 | 99.5 | 91.5 | 98.8 | 7.9 |
| showdown bonus 25 | 0.12 | 0.0 / 1.0 / 9.8 / 0.0 | 81.4 | 93.6 | 97.2 | 56.1 | 99.5 | 96.4 | 99.6 | 7.9 |
| showdown bonus 30 | 0.12 | 0.0 / 1.0 / 9.8 / 0.0 | 84.9 | 95.3 | 97.2 | 49.1 | 99.5 | 96.7 | 99.6 | 7.9 |
| Posture start 85 (0054: 80) | 0.09 | 0.0 / 0.6 / 7.8 / 0.0 | 77.9 | 91.8 | 97.1 | 63.6 | 99.7 | 96.0 | 99.7 | 8.0 |
| Pass 1 ×0.75 (0054: 1.0) | 0.09 | 0.0 / 0.5 / 7.9 / 0.0 | 78.5 | 91.5 | 97.7 | 61.9 | 99.6 | 95.9 | 99.3 | 8.2 |
| Pass 3 ×1.25 (0054: 1.0) | 0.19 | 0.0 / 1.0 / 15.2 / 0.0 | 76.1 | 88.4 | 94.1 | 66.4 | 99.3 | 94.9 | 99.2 | 7.7 |
| holdFloor 0.2 (0052: 0.25) | 0.11 | 0.0 / 0.9 / 9.3 / 0.0 | 78.2 | 92.1 | 95.3 | 61.3 | 99.4 | 96.0 | 99.6 | 7.6 |
| holdFloor 0.4 | 0.15 | 0.0 / 1.4 / 12.0 / 0.0 | 75.2 | 88.9 | 95.3 | 72.0 | 99.3 | 95.4 | 98.9 | 7.2 |
| holdFloor 0.6 | 0.26 | 0.0 / 2.5 / 18.3 / 0.0 | 70.8 | 83.8 | 93.1 | 80.5 | 98.7 | 93.6 | 99.2 | 7.4 |
| lean λ = 0 | 0.06 | 0.0 / 0.4 / 4.9 / 0.0 | 79.6 | 92.9 | 98.8 | 61.6 | 99.8 | 96.8 | 100 | 8.7 |
| lean λ = 0.5 | 0.08 | 0.0 / 0.6 / 7.2 / 0.0 | 78.6 | 92.6 | 97.0 | 62.0 | 99.7 | 96.6 | 99.0 | 9.1 |
| lean λ = 2 | 0.20 | 0.0 / 3.4 / 13.5 / 0.0 | 75.4 | 87.7 | 94.7 | 67.3 | 99.1 | 94.8 | 98.3 | 7.0 |
| board weight 0.25 (§11: 0.5) | 0.10 | 0.0 / 0.7 / 8.0 / 0.0 | 78.3 | 91.6 | 97.2 | 61.5 | 99.6 | 96.3 | 99.3 | 7.9 |
| armor rate 0.15 | 0.12 | 0.0 / 1.1 / 10.0 / 0.0 | 78.3 | 91.5 | 97.0 | 61.9 | 99.5 | 96.1 | 99.3 | 7.7 |
| armor rate 0.4 | 0.11 | 0.0 / 1.0 / 9.0 / 0.0 | 76.2 | 89.6 | 95.9 | 67.2 | 99.7 | 95.7 | 99.2 | 8.0 |
| slowmo = wall (0061: excluded) | 0.14 | 0.0 / 1.4 / 10.7 / 0.0 | 77.0 | 90.0 | 95.7 | 61.7 | 99.4 | 95.4 | 98.6 | 7.6 |
| slowmo = game | 0.13 | 0.0 / 1.2 / 10.2 / 0.0 | 77.2 | 90.5 | 95.5 | 62.5 | 99.5 | 95.2 | 98.9 | 8.0 |
| statBasis = points (0057: value) | 0.13 | 0.0 / 1.1 / 10.3 / 0.0 | 78.9 | 91.5 | 97.4 | 61.3 | 99.4 | 95.9 | 99.2 | 7.6 |
| flushHit = F2 (0059: F1) | 0.12 | 0.0 / 0.9 / 9.5 / 0.0 | 77.3 | 90.5 | 95.9 | 64.0 | 99.1 | 95.7 | 96.3 | 7.8 |
| meterThreshold = strict (0060: reachable) | 0.12 | 0.0 / 1.0 / 9.7 / 0.0 | 77.5 | 90.7 | 96.4 | 63.9 | 99.5 | 96.4 | 99.6 | 7.9 |
| turn cushion ½ (not adopted) | 0.08 | 0.0 / 1.0 / 6.8 / 0.0 | 78.1 | 92.0 | 98.2 | 63.7 | 100 | 96.6 | 98.5 | 8.6 |
| before 0053–0054 (Posture 100, 0.5 / 0.75 / 1.0 / 1.625, unhorse on P4) | 0.34 | 0.0 / 0.3 / 2.0 / 23.0 | 77.5 | 89.9 | 95.2 | 61.9 | 96.3 | 90.1 | 99.3 | 8.4 |

**What moves the results, most to least:**

1. **The showdown bonus (20)** still decides the most: it lands in nearly 90% of hands. The flip is
   79%, 64%, 56% and 49% at 10, 20, 25 and 30 per step.
2. **The heal** is the new mechanic that matters most. Off, turn endings rise to 14% and the flip to
   70%; at 0.3, turn endings fall to 6.6% and the flip to 55%. A larger heal favors the better
   hand: it blunts the reads that skill lands.
3. **The hold floor and the relief** both price late switches. Relief at 0.06 per point puts the
   flip at 68.5%; the floor at 0.4 puts it at 72%.
4. **Battered** sets how often hands end early: turn endings are 7.2% without it and 11.7% at 0.5.
5. **The lean λ** is unchanged in effect: λ = 2 doubles early endings and pushes the gap's tail
   past ×1.45.
6. **Barely moving:** extra time, the meter's base, armor rate, board weight and the settled
   switches. Extra time moves little because the sim's only use for it is who moves last when both
   riders read.

### The hold floor (0052)

From `--report floor`, 100k hands per run. The holder never reads and holds from the first moment;
the flicker always reads and never holds. Steady and fidget are the average rider with hold
discipline 1 and 0 (both read 30%).

| Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch |
| --- | --- | --- | --- |
| 0.2 | 30.2% | 67.4% | 62.9% |
| **0.25** | **24.7%** | **65.7%** | **69.3%** |
| 0.3 | 20.1% | 64.1% | 73.2% |
| 0.4 | 13.5% | 61.4% | 75.1% |
| 0.6 | 7.1% | 57.4% | 75.5% |

- Holding still pays: the steady rider beats the fidgety one 66% of the time.
- The pure holder does worse than before (24.7%, from 32.8%). The flicker always reads, and the
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

1. **Turn endings are 9.8% and flop 1.0%,** just under 0054's 10–15% and about 1.5–2%. The heal
   (0070) keeps riders up. Battered at about 0.35, or a slightly smaller heal, would bring them
   back; both are sim values, so this is only a heads-up unless you want the target to move.
2. **The red suits are below 50%** (♥ 47%, ♦ 46%; suited 48% and 45%), and the black suits above
   (♣ 53%, ♠ 52%). Should the suits be roughly even in value? If so, it's a job for the sim values
   (the heal share, the buffer and armor rates). If not, defense being the weaker side is a design
   choice to state.
3. **Board weight ¼ vs ½:** still a small effect.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** Each reading rider estimates the
  opponent's stats from the board plus an average hole card. There is no reading model of tells:
  colors and the hold meter as a tell carry no value.
- **Extra time past the lock is modelled as "moves last in a double read".** A real rider with
  extra time would also react to single reads.
- **Betting never Yields.** Units won therefore track the win rate.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
