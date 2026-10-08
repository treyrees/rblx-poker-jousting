# Sim results: one hand

Oct 7, 2026. GAME_SPEC through decision 0076. Since the last run:

- **Posture counts in half hearts (0075).**
  - 1 Posture is a half heart, and every rider has 32 (16 hearts).
  - Every value measured in Posture is ÷2.5: Weak / Normal / Crit 2 / 4 / 12, the hand bonus 8 per
    step, the clean block restore 1. The same goes for the sim values: armor, piercing, the ♥
    buffer, the straight meter, and trick hits and wards.
  - A hit's damage rounds to the nearest half heart as it lands, and the ♥ heal rounds up.
  - A showdown level on half hearts goes to the kickers.
- Spur and momentum are deferred to v2 (0076); nothing in the sim changes for it.

Runs use seed 20260930 and 100k hands per run; a sweep row is 200k hands (a mirror run plus a
skilled-vs-novice run on seed 20260931). The sim is `tools/sim.luau` over `sim/`, and every value it
uses is in `sim/Config.luau`. Earlier reports, through 0074 in exact Posture, are in this file's git
history.

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

## The mechanics' starting values

All are "set by the sim" (§11), so they are starting values, not proposals for GAME_SPEC. They were
tuned so that defense isn't weaker than offense (0074), then rescaled to half hearts (0075). Values
in Posture are in half hearts.

| Value | Start | What it means |
| --- | --- | --- |
| `battered` | 0.4 | Battered: +40% damage taken, × the striker's ♣ lean weight (full at Up, half on Up-Out and Up-In) |
| `healBase`, `healPerPoint` | 0.1, 0.02 | After contact, heal 10% + 2% per unleaned ♥ point of the damage taken, rounded up to a half heart: about 22% with 6 ♥ points |
| `heartBuffer` | 0.6 | Buffer per leaned ♥ point |
| `armorPerPoint` | 0.6 | Armor per ♦ card point, on top of 0057's value conversion (`armorRate` 0.1 × S♦). A cardless rider keeps the same Guard; without this a ♦ card point was worth a tenth of a ♣ point |
| `armorZone` | Guard 1, thin 0.5, sliver 0.2 | Thick, thin and sliver armor (were 1 / 0.2 / 0.05). With a thinner sliver, crits ignored armor and ♦ stayed under 48% at any rate |
| `critRelief`, `guardRelief` | 0.03 | Per ♠ (♦) card point, the share of the hold multiplier's shortfall restored on a Crit (on Guard armor). A cardless rider gets none, so holding still beats a late switch (0052) |
| `extraTime` | 0.15 s | Extra time past the lock at a full lean into ♠ or ♦. In the sim: when both riders read, the one with more moves last |
| Straight meter | `2.2 · 2^cards · (1 + 0.1·(top − 5))` | Each card held doubles the hit. A full wheel deals 70, enough to clear full Posture with the thicker defense (§6); an ace-high deals 67 at four cards and 134 at five; one or two cards deal 4–17 |

## Headline metrics against the targets

Average vs average, at the defaults, unless noted.

| Target (source) | Result | Met? |
| --- | --- | --- |
| Defense isn't weaker; suits about even (0074) | Hole card of the suit wins: ♣ 49.9%, ♠ 49.1%, ♥ 48.2%, ♦ 48.0% | Yes |
| Turn 10–15%, flop about 1.5–2% (0054; guides, not targets, per 0074) | Flop 1.5%, turn 9.0%, river 89.5% | About |
| Numeric hands order correctly (§11) | Better river category wins 77.3% / 91.4% / 95.2% at gaps 1 / 2 / 3 | Yes |
| Skill flip 55–65% (pillar 2, 0054) | Skilled beats novice with the worse category 64.7%; skilled vs average 37.1% | Yes |
| Numeric gap ×1.0–1.45 after the lean, λ ≤ 1 (0062) | Unchanged (card points only): medians ×1.09 / 1.17 / 1.23 at λ = 1 | Yes |
| A trick above, played to design, wins at least 95% on every path (0064) | Unleashed 97.7% (n 1,862), answering 100% (n 11), auto-fired 100% (n 7,111). Every trick is at 95% or more | Yes |
| A higher trick nearly always beats a lower one (0044) | 99.2% (n 251) | Yes |
| Holding is the straight's power (0073) | Unleashed straights: held 95.0%, not held 91.4% | Yes |

### Tricks fired while above, by path and design

From a scratch count over the baseline run (100k hands): tricks fired while above the opponent, not
clashed.

| Path | Played to design | Not to design |
| --- | --- | --- |
| Unleash | 97.7% (n 1,862): flush 96.2%, full house 99.6%, quads 100%, straight 95.0% | 91.4% (n 1,656): straight 91.4%, flush 90.5% |
| Answer | 100% (n 11) | 100% (n 2) |
| Auto-fire on Pass 4 | 100% (n 7,111) | 99.2% (n 4,587) |

Other metrics:

- **Held, then drawn out:** 7.8% (n = 3,242).
- **Unhorse vs showdown:** 10.5% : 89.5%.
- **Showdown:** the rider ahead on Posture after Pass 4's contact (and its heal) wins 85.5%; the
  better poker hand wins 74.4%.
- **Level on half hearts:** 2.3% of showdowns. The kickers decide 2.2%, and 0.1% split (scratch
  count, 100k hands).
- **Reads:** 71.6% of reads switch late rather than stay on the held aim.

## Half hearts against exact Posture (0075)

The defaults against the same run in exact Posture (`switches.posture=exact`), 100k hands.

| | Exact Posture | Half hearts, heal rounds up |
| --- | --- | --- |
| Skill flip | 66.1% | 64.7% |
| Better category wins, gap 1 / 2 / 3 | 76.2 / 90.2 / 96.1% | 77.3 / 91.4 / 95.2% |
| Flop / turn endings | 1.5 / 9.5% | 1.5 / 9.0% |
| Suits ♣ / ♠ / ♥ / ♦ | 49.9 / 48.7 / 48.5 / 48.7% | 49.9 / 49.1 / 48.2 / 48.0% |

Rounding moves the game less than any tuning row below. Rounding the heal to the nearest half
heart instead would hide 46% of heals (21.7% at quarter hearts, 60.7% at whole hearts); rounding it
up hides none.

### Can one hit identify a hand? (§3, §7)

From a scratch count over 100k hands, Passes 1–3 (a Pass 4 hit can't be used: no bet follows it).
The defender is a perfect observer. They list every hole pair they can't rule out, and work out the
hit each one would deal from the public aim, hold, tier and their own armor. A hit **pins** a
category when every pair that gives the same displayed hit is in that category. It **names the
hand** when only one pair fits.

| Display | Pocket pair pinned, Pass 1 | Trips pinned, Pass 2 / 3 | Names the hand, worst case |
| --- | --- | --- | --- |
| 0.4 half hearts (exact to 1 old Posture) | 5.9% | 18.5 / 24.2% | 4.6% (pocket pairs, Pass 1) |
| **1 half heart** | 4.6% | 14.0 / 21.0% | 1.8% (pocket pairs, Pass 1) |
| 2 half hearts | 4.1% | 11.8 / 19.3% | 0.9% (trips) |

- Pairs and two pair are pinned on under 2.5% of their hits at half hearts, and high card almost
  never.
- Trips stay pinned on about 1 hit in 5 at any display: the ×3 multiplier puts the top of the hit
  range out of reach of every other numeric hand. 0075 keeps this on purpose (§7).
- Board weight barely moves it: at ¼, trips are pinned 18.6 / 25.6% of the time at whole old
  Posture.
- The observer treats every hole pair as equally likely. Honest riders lean toward their cards, so
  a real reader would learn somewhat more.

## What each suit and rank is worth now

From a scratch count: 200k hands, average riders, seat 1's hole cards. A hole card's win rate when
it is of that suit (seat 1 wins 48.9% overall).

| | ♣ | ♠ | ♥ | ♦ |
| --- | --- | --- | --- | --- |
| Now (half hearts) | 49.9% | 49.1% | 48.2% | 48.0% |
| Exact Posture (0074) | 49.9% | 48.7% | 48.5% | 48.7% |
| At the first starting values for 0067–0070 | 52.6% | 52.0% | 47.4% | 46.3% |
| Before 0067 | 51.1% | 50.1% | 53.1% | 45.7% |

- **The suits are within 1.9 points** (0074; 1.4 in exact Posture). Rounding the heal up gives every
  rider a minimum heal, which slightly blunts ♥'s per-point share.
- **Ranks climb smoothly** (at the first starting values for 0067–0070): 46% for a 2 to 51% for J
  through A.

## Sensitivity

Each row changes one thing from the defaults. Values in Posture are in half hearts. Column key:

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
| **defaults** | 0.12 | 0.0 / 1.5 / 9.0 / 0.0 | 77.3 | 91.4 | 95.2 | 64.7 | 99.5 | 97.2 | 99.2 | 7.8 |
| exact Posture (0075: half hearts) | 0.12 | 0.0 / 1.5 / 9.5 / 0.0 | 76.2 | 90.2 | 96.1 | 66.1 | 99.5 | 97.3 | 99.6 | 8.2 |
| battered 0 (0068 off) | 0.08 | 0.0 / 0.7 / 6.5 / 0.0 | 79.2 | 92.2 | 98.3 | 61.8 | 99.6 | 97.5 | 99.7 | 9.0 |
| battered 0.6 | 0.14 | 0.0 / 2.3 / 10.0 / 0.0 | 76.9 | 89.2 | 96.6 | 65.4 | 99.3 | 96.9 | 99.6 | 7.7 |
| heal off (0070) | 0.17 | 0.0 / 2.3 / 12.5 / 0.0 | 74.2 | 86.5 | 94.6 | 69.8 | 99.3 | 97.1 | 100 | 7.7 |
| heal 4% per ♥ point | 0.11 | 0.0 / 1.4 / 8.8 / 0.0 | 79.0 | 92.4 | 97.7 | 61.4 | 99.5 | 97.1 | 99.6 | 7.8 |
| ♥ buffer 0.2 | 0.12 | 0.0 / 1.5 / 9.3 / 0.0 | 76.4 | 90.1 | 96.0 | 66.8 | 99.5 | 97.1 | 99.6 | 7.5 |
| ♦ per-point armor 0 | 0.14 | 0.0 / 1.8 / 10.3 / 0.0 | 77.7 | 90.0 | 96.2 | 64.9 | 99.4 | 97.1 | 99.2 | 8.1 |
| armor zones thin 0.2, sliver 0.05 | 0.14 | 0.0 / 1.9 / 10.4 / 0.0 | 76.8 | 89.6 | 95.3 | 65.5 | 99.5 | 96.9 | 98.8 | 8.1 |
| crit and guard relief 0 (0069 off) | 0.10 | 0.0 / 1.2 / 7.8 / 0.0 | 78.6 | 92.0 | 97.6 | 60.5 | 99.7 | 97.4 | 99.7 | 7.7 |
| crit and guard relief 0.06 | 0.15 | 0.0 / 2.1 / 10.9 / 0.0 | 76.4 | 89.4 | 95.9 | 68.0 | 99.3 | 96.6 | 99.6 | 7.5 |
| extraTime 0 (0069 last move off) | 0.12 | 0.0 / 1.5 / 9.0 / 0.0 | 77.7 | 91.6 | 96.0 | 65.4 | 99.5 | 97.4 | 99.3 | 7.6 |
| straight x = 1.5 (same full wheel) | 0.13 | 0.0 / 1.7 / 9.6 / 0.0 | 77.6 | 91.1 | 96.1 | 65.0 | 99.5 | 98.5 | 99.6 | 7.9 |
| straight rank adds nothing | 0.11 | 0.0 / 1.4 / 8.7 / 0.0 | 77.6 | 91.2 | 96.2 | 64.7 | 99.5 | 95.9 | 98.9 | 8.1 |
| trick hits and wards ×0.5 | 0.11 | 0.0 / 1.4 / 8.5 / 0.0 | 77.5 | 90.7 | 96.3 | 64.8 | 99.5 | 94.2 | 99.3 | 8.4 |
| showdown bonus 4 (0050, 0075: 8) | 0.12 | 0.0 / 1.5 / 9.0 / 0.0 | 68.6 | 80.5 | 88.9 | 78.0 | 99.5 | 95.0 | 98.8 | 7.8 |
| showdown bonus 10 | 0.12 | 0.0 / 1.5 / 9.0 / 0.0 | 80.9 | 93.9 | 95.9 | 57.9 | 99.5 | 97.6 | 99.6 | 7.8 |
| showdown bonus 12 | 0.12 | 0.0 / 1.5 / 9.0 / 0.0 | 84.2 | 95.8 | 96.3 | 51.0 | 99.5 | 97.7 | 100 | 7.8 |
| Posture start 34 (0075: 32) | 0.09 | 0.0 / 1.0 / 7.6 / 0.0 | 77.7 | 91.7 | 97.4 | 64.0 | 99.7 | 97.4 | 98.9 | 8.8 |
| Pass 1 ×0.75 (0054: 1.0) | 0.10 | 0.0 / 0.9 / 7.9 / 0.0 | 78.7 | 92.5 | 97.9 | 61.6 | 99.6 | 97.1 | 99.3 | 8.3 |
| Pass 3 ×1.25 (0054: 1.0) | 0.18 | 0.0 / 1.4 / 13.8 / 0.0 | 75.9 | 89.2 | 94.9 | 66.6 | 99.1 | 97.2 | 99.2 | 7.5 |
| holdFloor 0.2 (0052: 0.25) | 0.11 | 0.0 / 1.4 / 8.6 / 0.0 | 78.3 | 91.8 | 97.0 | 61.4 | 99.6 | 97.5 | 99.7 | 7.8 |
| holdFloor 0.4 | 0.16 | 0.0 / 2.0 / 11.6 / 0.0 | 75.0 | 88.2 | 96.9 | 72.8 | 99.2 | 96.5 | 99.3 | 7.1 |
| holdFloor 0.6 | 0.25 | 0.0 / 3.5 / 16.5 / 0.0 | 71.4 | 84.2 | 91.9 | 80.1 | 98.5 | 95.9 | 100 | 7.4 |
| lean λ = 0 | 0.07 | 0.0 / 0.6 / 5.6 / 0.0 | 78.2 | 92.3 | 98.4 | 65.5 | 99.7 | 97.8 | 99.7 | 8.1 |
| lean λ = 0.5 | 0.09 | 0.0 / 0.8 / 7.4 / 0.0 | 77.8 | 91.3 | 97.0 | 64.4 | 99.6 | 97.7 | 98.9 | 8.4 |
| lean λ = 2 | 0.19 | 0.0 / 3.9 / 11.8 / 0.0 | 76.7 | 88.7 | 96.8 | 63.4 | 99.1 | 96.7 | 98.6 | 7.8 |
| board weight 0.25 (§11: 0.5) | 0.10 | 0.0 / 1.2 / 8.0 / 0.0 | 77.6 | 91.6 | 97.7 | 63.0 | 99.7 | 97.3 | 98.9 | 7.6 |
| armor rate 0.06 | 0.13 | 0.0 / 1.7 / 9.7 / 0.0 | 77.5 | 91.3 | 96.7 | 63.3 | 99.4 | 97.5 | 99.6 | 8.1 |
| armor rate 0.16 | 0.10 | 0.0 / 1.2 / 8.2 / 0.0 | 77.4 | 90.6 | 97.1 | 64.0 | 99.6 | 97.1 | 99.3 | 7.4 |
| slowmo = wall (0061: excluded) | 0.13 | 0.0 / 1.8 / 9.7 / 0.0 | 76.8 | 90.6 | 96.3 | 62.4 | 99.4 | 96.9 | 99.3 | 7.0 |
| slowmo = game | 0.12 | 0.0 / 1.6 / 9.4 / 0.0 | 77.2 | 91.3 | 95.5 | 63.3 | 99.4 | 97.3 | 99.3 | 8.2 |
| statBasis = points (0057: value) | 0.13 | 0.0 / 1.6 / 9.7 / 0.0 | 78.4 | 91.9 | 97.4 | 62.2 | 99.4 | 97.3 | 98.9 | 8.1 |
| flushHit = F2 (0059: F1) | 0.11 | 0.0 / 1.4 / 8.7 / 0.0 | 77.6 | 90.8 | 96.5 | 64.4 | 99.1 | 97.3 | 98.0 | 7.7 |
| meterThreshold = strict (0060: reachable) | 0.12 | 0.0 / 1.5 / 9.0 / 0.0 | 77.4 | 91.4 | 95.2 | 64.7 | 99.6 | 97.4 | 99.2 | 7.9 |
| turn cushion ½ (not adopted) | 0.09 | 0.0 / 1.4 / 6.6 / 0.0 | 78.3 | 92.2 | 97.9 | 64.0 | 100 | 97.7 | 99.4 | 8.6 |
| before 0053–0054 (Posture 40, 0.5 / 0.75 / 1.0 / 1.625, unhorse on P4) | 0.34 | 0.0 / 0.3 / 2.4 / 22.7 | 78.0 | 90.5 | 97.6 | 59.9 | 96.6 | 91.2 | 100 | 8.4 |

**What moves the results, most to least:**

1. **The showdown bonus (8)** still decides the most: it lands in nearly 90% of hands. The flip is
   78%, 65%, 58% and 51% at 4, 8, 10 and 12 per step.
2. **The hold floor and the relief** both price late switches. The floor at 0.4 puts the flip at
   73%; relief at 0.06 per point puts it at 68%.
3. **The heal:** off, turn endings rise to 12.5% and the flip to 70%. A larger heal favors the
   better hand, because it blunts the reads that skill lands.
4. **Battered** sets how often hands end early: turn endings are 6.5% without it and 10.0% at 0.6.
5. **The lean λ** is unchanged in effect: λ = 2 more than doubles flop endings and pushes the gap's
   tail past ×1.45.
6. **Barely moving:** half hearts against exact Posture, extra time, the meter's base, armor rate,
   board weight and the settled switches. Extra time moves little because the sim's only use for
   it is who moves last when both riders read.

### The hold floor (0052)

From `--report floor`, 100k hands per run. The holder never reads and holds from the first moment;
the flicker always reads and never holds. Steady and fidget are the average rider with hold
discipline 1 and 0 (both read 30%).

| Floor | Holder vs flicker | Steady vs fidget | Mirror reads that switch |
| --- | --- | --- | --- |
| 0.2 | 26.1% | 63.8% | 68.4% |
| **0.25** | **21.7%** | **62.3%** | **71.5%** |
| 0.3 | 17.9% | 61.2% | 73.6% |
| 0.4 | 12.9% | 59.2% | 75.2% |
| 0.6 | 7.0% | 56.0% | 75.5% |

- Holding still pays: the steady rider beats the fidgety one 62% of the time.
- The pure holder does worse (21.7%). The flicker always reads, and the ♠/♦ relief and Battered
  both reward the hit that a read lands. The holder is extreme: it never reacts at all.

### The numeric gap (§4)

From `--report gap`: 100k river deals with no trick, taking each rider's most-loaded stat. It
depends on card points and the lean only, so half hearts leave it unchanged.

| λ | Mean multiplier: HC / pair / 2P / trips | Better over worse, median, gap 1 / 2 / 3 | Worse category loads more |
| --- | --- | --- | --- |
| 0 | 1.21 / 1.27 / 1.32 / 1.36 | 1.06 / 1.10 / 1.14 | 22% / 11% / 9% |
| 0.5 | 1.32 / 1.40 / 1.49 / 1.54 | 1.07 / 1.14 / 1.18 | 22% / 11% / 7% |
| 1 | 1.43 / 1.54 / 1.65 / 1.71 | 1.09 / 1.17 / 1.23 | 22% / 11% / 6% |
| 2 | 1.64 / 1.81 / 1.97 / 2.07 | 1.12 / 1.22 / 1.31 | 22% / 11% / 6% |

## Questions for Trey

Nothing here is applied.

1. **Board weight ¼ vs ½:** still a small effect.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** Each reading rider estimates the
  opponent's stats from the board plus an average hole card. There is no reading model of tells:
  colors, the hold meter and hit sizes carry no value in play. The hit-size count above is a
  separate scratch count with a perfect observer.
- **Extra time past the lock is modelled as "moves last in a double read".** A real rider with
  extra time would also react to single reads.
- **Betting never Yields.** Units won therefore track the win rate.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
