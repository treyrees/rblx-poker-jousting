# Sim results: one hand

Oct 8, 2026. GAME_SPEC through decision 0095. The reading model (0089–0095) is new; it is off by
default, so nothing above *What the bar's information is worth* moved. Before that, through 0083,
and since the run of Oct 7 (through 0076):

- **The prefold cost and the yard (0078–0083).** Prefold money rides as carry into the rider's next
  pot (0078), the yard keeps 75% of dealt hands (0079), a prefold costs units and a short delay
  (0080), Yield is offered only facing a raise (0081), v1 has one stake (0082), and the matchmaker
  pairs on wait time alone (0083). The sim gains a betting rider (*Betting*) and a yard report (*The
  yard*).
- **No default moved.** Today's scripted betting stays the default, so the hand plays exactly as on
  Oct 7. Every section from *The mechanics' starting values* through *The numeric gap* stands as run
  then, at half hearts (0075).

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

Under the default script the riders never Yield, so every hand is ridden out (pillar 2). *Betting*
below adds a betting rider that raises and Yields on its odds.

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

## Betting

### The betting rider (`switches.betting = "bands"`)

Today's script (the default) raises on an owned trick, or on trips with a Posture lead, and never
Yields. So 96.4% of lost hands cost only the Ante, and its pots are artifacts.

The betting rider bets on its odds of winning. It knows the game's odds from experience: a
calibration run of 50k average-vs-average hands under the script (its own seed, `sim.oddsSeed`)
records how often a rider in each spot went on to win the hand ridden out. A spot is:

- **Bets 1–2** (hole cards only): the starting-hand class, one of 169.
- **Bets 3–4** (the flop or the turn known): the rider's best category so far, the board's own
  pairs, and whether the rider is drawing (four to a flush or a straight, with a hole card).
- **The Posture lead**, in seven bands, which shifts the odds on every hand alike.

At each bet the rider raises (or re-raises) when its odds are at least `raiseAt`. Facing a raise,
it Yields below `yieldAt`; with no raise to face it never Yields (0081). Both are per bet and per
rider profile; every profile starts at raise .60, Yield .25. The odds never read the opponent: not
their bets, and not who kept their hand in the yard.

### Bands

From `--report bets`, 100k hands per run. Mirror = average vs average; flip = the skilled rider
wins with the worse category against a novice (100k hands, seed 20260931), and the last column is
the skilled rider's units a hand there. The same bands for every bet unless noted.

| Betting | Yield: all (Bet 1 / 2 / 3 / 4) | Hands raised | Loser loses 1 / 2–3 / 4–7 / 8–13 | Mean loss | gap1 | flip | Skilled units/hand |
| --- | --- | --- | --- | --- | --- | --- | --- |
| **script (default)** | 0% | 3.6% | 96.4 / 3.2 / 0.4 / 0.0% | 1.08 | 77.3 | 64.7 | +0.71 |
| raise .55, never Yield | 0% | 95.7% | 4.3 / 14.7 / 75.2 / 5.8% | 5.20 | 77.6 | 65.0 | +3.27 |
| raise .60, never Yield | 0% | 89.6% | 10.3 / 20.7 / 66.8 / 2.2% | 4.48 | 77.6 | 65.0 | +2.91 |
| raise .60, Yield .20 | 38.8% (0.0 / 0.5 / 10.1 / 28.2) | 90.1% | 17.3 / 35.1 / 45.7 / 2.0% | 3.57 | 75.3 | 67.5 | +1.96 |
| **raise .60, Yield .25 (profile bands)** | 55.2% (0.0 / 5.0 / 31.8 / 18.3) | 89.6% | 34.0 / 37.5 / 26.7 / 1.9% | 2.81 | 73.0 | 68.9 | +1.45 |
| raise .65, Yield .25 | 48.3% (0.0 / 4.4 / 22.9 / 21.0) | 80.6% | 44.0 / 35.6 / 19.7 / 0.7% | 2.38 | 74.4 | 67.1 | +1.24 |
| raise .55, Yield .30 | 64.9% (0.0 / 20.7 / 27.4 / 16.8) | 95.7% | 35.7 / 34.4 / 26.3 / 3.6% | 2.97 | 69.9 | 68.9 | +1.56 |
| raise .60, Yield .35 | 74.5% (0.0 / 31.9 / 26.4 / 16.2) | 89.5% | 68.3 / 19.5 / 11.1 / 1.1% | 1.90 | 67.4 | 69.2 | +1.02 |
| raise .60, Yield .40 | 82.1% (0.0 / 35.7 / 33.1 / 13.2) | 89.7% | 78.5 / 15.0 / 5.7 / 0.8% | 1.56 | 64.3 | 72.6 | +0.86 |
| raise .65, Yield .40 | 73.2% (0.0 / 30.6 / 24.6 / 18.0) | 80.5% | 83.5 / 11.6 / 4.5 / 0.4% | 1.42 | 68.2 | 69.3 | +0.78 |
| raise .70, Yield .45 | 63.2% (0.5 / 17.9 / 27.7 / 17.1) | 67.4% | 92.7 / 5.8 / 1.4 / 0.1% | 1.16 | 71.4 | 68.4 | +0.70 |
| Bets 1–2 calm: raise —/—/.60/.60, Yield —/—/.35/.35 | 67.4% (0.0 / 0.0 / 46.9 / 20.5) | 85.7% | 70.6 / 17.9 / 11.0 / 0.5% | 1.88 | 72.0 | 69.3 | +0.98 |

- **The Yield band sets the pots.** A rider that never Yields rides every raise to the end: two
  lost hands in three cost 4–7 units, and the mean loss is about 4.5. A Yield near pot odds (.25;
  a call usually needs 17–33%) brings it to 2.8, and a timid one (.40) to 1.6.
- **A rider that Yields on its odds Yields away most hands.** At .25, 55% of hands end in a Yield;
  at .35, three in four. Almost none come on Bet 1: before the flop the odds run from about 41%
  (32o) to 74% (AA) (scratch count, 1M hands), so no hand is hopeless. They come once the joust has spoken: after Pass 1 (Bet 2), and
  above all after the flop (Bet 3), when one rider is behind on Posture and the other raises.
- **Yields cost the cards' order and add to the flip.** A hand that ends in a Yield never reaches
  the showdown bonus, so the better category wins less often at gap 1 (77.3% → 73.0% at .25) and the
  skill flip rises (64.7% → 68.9%). Skill pays more in units: the skilled rider takes 1.45 units a
  hand from a novice, against 0.71 under the script.

## The yard

### The model (`--report yard`)

A rider in the yard is dealt a starting-hand class; they keep it and ride, or pay the prefold price
c and are dealt again. Every rider keeps by class alone, the same way, so the riders they meet are
the deal restricted to the kept classes (the matchmaker never sees cards, 0083). The report plays
2M average-vs-average hands under a betting reading, tallies units and wins by class pair, and
finds the equilibrium:

- each class's EV against the kept field;
- a fold's value, which pays c on every redeal until a hand is kept;
- the kept set: the top classes by keep value, the last one partly kept, re-measured against the
  field it makes until it settles;
- the price at which the marginal class is indifferent. At share k, the yard keeps the largest k
  whose price is at most c.

Where the price goes (`switches.prefold`; the formulas are in `sim/Yard.luau`):

- **sink:** the house takes it. A fold costs c/k in the long run (the redeals pay again).
- **purse** (pooled, at its average): every match's winner takes 2c(1 − k)/k. A fold costs c.
- **carry** (0078): a rider's payments ride into their own next pot. A fold costs about c/2,
  because a rider wins their own carry back when they win, which is half the time on average. Only
  the opponent's carry, c(1 − k)/k on average, is dead money a keeper can win. The price is for a
  rider carrying nothing; one carrying one fold's price values the marginal hand about 0.02 units
  lower.

### The price for 75% (0079)

2M hands per betting reading, seed 20260930.

| Betting | Mean loss, everyone keeps | Sink | Pooled purse | **Carry** |
| --- | --- | --- | --- | --- |
| script (default) | 1.08 | 0.09 | 0.09 | 0.18 |
| raise .60, Yield .35 | 1.91 | 0.15 | 0.15 | 0.30 |
| **raise .60, Yield .25 (profile bands)** | 2.81 | 0.19 | 0.20 | **0.40** |
| raise .60, never Yield | 4.48 | 0.35 | 0.36 | 0.73 |

- **Free folding unravels the yard.** At a price of 0, every reading keeps under 5% of hands: each
  fold tightens the field, and the next-worst hand falls below even against it. This is the
  adverse selection 0079 is about, measured.
- **The price scales with what a weak hand loses by playing**, so it scales with the pots. The
  marginal hands at 75% (T6o, T5o, 96o, 64o and the like) lose about 0.25 units a match against the
  kept field at the profile bands, and 0.12 under the script.
- **Sink and pooled purse need the same price; carry needs twice it**, as the model says.
- **Noise:** a second 2M-hand run (seed 20261001) gives the same carry prices (0.40 and 0.18) and
  sink and purse within 0.01. Per-class EVs carry about ±0.03 units, so which hands sit exactly at
  the margin, and the single holes in the chart below, change with the seed.

The starting value is **0.40 units** (`sim.prefoldPrice`): carry at 75% under the profile bands.

### Price and share under carry

| Betting | Price for 100 / 90 / 80 / 75 / 70 / 60 / 50% kept | Kept at price 0 / 0.1 / 0.2 / 0.3 / 0.5 / 0.75 |
| --- | --- | --- |
| script (default) | 0.41 / 0.27 / 0.20 / 0.18 / 0.16 / 0.13 / 0.11 | <5 / 41.5 / 79.0 / 93.5 / 100 / 100% |
| raise .60, Yield .35 | 0.55 / 0.38 / 0.31 / 0.30 / 0.27 / 0.23 / 0.22 | <5 / 8.0 / 43.0 / 74.5 / 99.0 / 100% |
| raise .60, Yield .25 | 0.71 / 0.51 / 0.43 / 0.40 / 0.39 / 0.34 / 0.30 | <5 / 7.0 / 27.5 / 50.5 / 88.5 / 100% |
| raise .60, never Yield | 1.60 / 1.04 / 0.78 / 0.73 / 0.63 / 0.55 / 0.45 | <5 / <5 / 14.0 / 31.5 / 56.5 / 77.5% |

The curve is steep near the price: under the profile bands, 0.30 keeps half the hands and 0.50
keeps 88.5%. A price set for one betting style holds a different share for another: at 0.40,
today's script keeps over 95% of hands, and a rider who never Yields keeps under half.

### The yard at 75%, carry, profile bands

The kept range (`#` kept, `+` partly kept, `.` folded; suited above the diagonal, offsuit below):

```
     A K Q J T 9 8 7 6 5 4 3 2
  A  # # # # # # # # # # # # #
  K  # # # # # # # # # # # # #
  Q  # # # # # # # # # # # # #
  J  # # # # # # # # # # # # #
  T  # # # # # # # # # # # # #
  9  # # # # # # # # # # # # #
  8  # # # # # # # # # # # # .
  7  # # # # # # # # # # # # #
  6  # # # # # + # # # # # # .
  5  # # # # # . # # . # # # .
  4  # # # . . . . . . . # # .
  3  # # . . # # . . . . . # .
  2  # # . . # . . . . . . . #
```

Every pair, every ace, every king and nearly every suited hand is kept. What folds:

- most offsuit hands whose low card is a 5 or lower and whose high card is a 9 or lower (65o, 54o,
  43o, 32o and the like);
- some of the weakest offsuit queens, jacks, tens and nines (Q3o, Q2o, J4o, J3o, J2o, T4o, 95o,
  92o);
- five weak suited hands: 82s, 62s, 52s, 42s and 32s.

Single keeps among them (T3o, T2o, 93o, 85o and 75o kept, 96o partly) are within the noise.

| | Everyone keeps | 75% kept |
| --- | --- | --- |
| Kept deals: pairs / suited / offsuit | 5.9 / 23.5 / 70.6% | 7.8 / 29.4 / 62.8% |
| Kept deals holding an ace | 14.9% | 19.9% |
| Classes kept, at least in part | 169 | 139 |
| Both river hands modest (high card or a pair) | 43.1% | 42.3% |
| Matches between numeric hands, no trick fired | 81.7% | 81.1% |
| The worse river category wins | 14.6% | 14.3% |
| ...holding a modest hand | 12.7% | 12.4% |
| The class with the lower EV wins | 44.0% | 44.7% |
| Loser loses 1 / 2–3 / 4–7 / 8–13 | 33.9 / 37.3 / 26.8 / 1.8% | 29.4 / 39.3 / 28.9 / 2.2% |
| Mean loss | 2.81 | 2.97 |
| Carry in an average pot | — | 0.27 |

- **Diversity holds at 75%.** The kept field gains pairs, suited hands and aces, but the matches
  look the same: modest river hands meet in 42% of them, four in five are between numeric hands,
  and the starting hand with the lower EV still wins 45%. The board makes most river hands, so
  folding a quarter of the deck barely moves what reaches the river.
- **Pots grow a little.** The kept field is stronger, so more hands are raised and called.

### What the sim can't say

- Whether folding at 0.40 units feels fair, or how long a delay (0080) players will sit through.
  The sim has no model of time.
- Whether carry reads as gambling under Roblox's policy (§11).
- How real players bet. The price follows the betting style (the curve above), and the betting
  rider is a model: it bets on its own odds and never reads the opponent.
- Players who don't fold by EV. The equilibrium assumes riders learn which hands lose; a player who
  keeps everything pays nothing and meets a slightly stronger field.

### For ghost betting (§11, next in the chain)

Ghosts (§9) need a prefold habit as well as betting habits. A ghost that keeps every hand it is
dealt would play the whole deck against a field that keeps 75%, and lose at the rate the folded
hands lose. One that keeps only strong hands would tighten the field. Either way the ghosts would
reshape the yard. Not built; noted for issue 6.

## What the bar's information is worth

0087: "The Posture bar's main value is information. Its health lead is meaningful, never pointless,
but not decisive." Until now the sim could measure only the health half, because its riders read
nothing. §11 *Sim plan* step 4's reading model now prices the information half.

### The model (`sim/Read.luau`, `reading` in `sim/Config.luau`)

- **A belief over the opponent's hole pair (0089).** It covers the 1,326 two-card deals, minus the
  cards the reader can see. Every public cue updates it by Bayes' rule:
  - **color:** the number of red hole cards (§7 *Color leak*);
  - **stance:** where the rider commits, and any re-stance after the reveal;
  - **timing:** when the rider first leaves Neutral;
  - **hit:** both bars' change at contact, clean blocks and the ♥ buffer included (0093);
  - **heal:** the ♥ heal, as its own beat (0093);
  - **unleash:** an announced unleash;
  - **bets:** each Stay and Raise (0094).

  Each likelihood replays the sim's own rider script for every candidate pair, with the opponent
  assumed to ride as the average profile. A full-skill reader never rules out the opponent's real hand
  (`tests/Read.spec.luau`).
- **What it drives (0090).** `reading.aim = "belief"`: a read's late switch plays against 8
  opponents sampled from the belief instead of an average hole card. `reading.betting = "belief"`:
  the betting rider averages paired odds (this hand against that one, from its calibration run) over
  the belief.
- **Read skill (0091).** `readSkill` *s* weighs the read by *s* and today's estimate by 1 − *s*.
  At *s* = 0 the rider rides exactly as before.
- **Battered and carry are public (0095).** The reader already treats Battered as known. The one-hand
  sim has no carry inside a match.
- **Run:** `lune run tools/sim.luau --report info --shard i/4`, four processes, 100k hands a row.
  The report took 7 min 51 s on 4 cores (longest shard 471 s). A row takes 1–7 minutes, and the 9
  rows are ordered so the shards come out even.

Mirror rows use seed 20260930 and skilled-vs-novice rows 20260931. Win rates are in %.

### What the cues carry

From a full-skill reader. Bits are what each observation takes off the belief, in update order. A
reader starts with 10.3 bits of uncertainty: about 1,200 equally likely pairs.

| Cue | Bits per observation | Notes |
| --- | --- | --- |
| Color | 1.49 | Once, before Pass 1 |
| Hit (both bars at contact) | 1.07–1.08 | Per contact, Passes 1–3 |
| Stance (commit and re-stance) | 0.52–0.60 | Per pass |
| Bets | 0.12–0.13 per action | Betting rider; 0.00 under the script, which raises only on tricks and trips |
| Heal (its own beat) | 0.06 | Per contact; it rounds up to a half heart, so it is coarse |
| Timing (first exit, hold) | 0.00 | The script ties hold to the rider, not the hand; only a trick played to its design commits at once, and that is rare |
| Unleash | about 2 | Rare: it usually ends the hand |

- After Pass 1 a full-skill reader has 6.5 bits left and puts 2.3–2.6% on the true pair. After
  Pass 3 it has 3.2–3.4 bits left and puts 19–20% on it.
- So the bar and the dial carry a lot. Most of it comes from color and the first hit, and a hit tells
  about twice what a stance does.

### Against the health baseline

0087's baseline came from a scratch count whose cuts weren't recorded. The rows here use stated cuts:

- **P1 pooled:** the win rate by Posture lead after Pass 1, pooled over behind 1–11, level and ahead
  1–11 half hearts.
- **Cards swing:** after two passes, within a lead group, the win rate ahead on the flop's category
  minus behind on it.
- **Lead swing:** within a card standing, the win rate ahead 1–11 on Posture minus behind 1–11.

The Pass 1 split reproduces 0087's 40/60. The card cut is coarser than the scratch count's, so it
swings more (43–52 points against 0087's 30–37). Compare readers with the "off" rows here, not with
0087's numbers.

A reader row puts the reader in seat 1. Seat 1 wins 48.9% (ridden out) and 49.3% (betting rider) in
the mirror with reading off, so those are the controls.

| Row (100k hands) | Seat 1 wins | Units/hand | Yield | P1 pooled behind / ahead | Cards swing | Lead swing | 12+ lead, worse cards |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Ridden out, mirror, reading off | 48.9 | −0.024 | 0% | 39.3 / 60.7 | 43–52 | 23–31 | 70.9 |
| Ridden out, reader v non-reader (aim reads, 1 v 0) | 49.2 | −0.017 | 0% | 38.8 / 60.3 | 43–51 | 23–31 | 72.1 |
| Betting rider, mirror, reading off | 49.3 | −0.021 | 55.2% | 33.7 / 66.3 | 48–57 | 29–50 | 92.2 |
| Betting rider, reader v non-reader (aim + bets, .5 v 0) | 49.5 | +0.023 | 56.4% | 33.9 / 66.0 | 48–55 | 29–48 | 92.6 |
| Betting rider, reader v non-reader (aim + bets, 1 v 0) | 49.3 | +0.110 | 58.2% | 34.0 / 65.9 | 50–57 | 29–46 | 91.9 |
| Betting rider, mirror, both read (aim + bets, 1 v 1) | 48.9 | −0.050 | 63.5% | 34.9 / 65.1 | 59–64 | 33–43 | 77.5 |
| Ridden out, skilled v novice, reading off | 81.9 | +0.705 | 0% | 68.1 / 83.4 | 28–49 | 9–29 | 86.0 |
| Betting rider, skilled v novice, reading off | 84.3 | +1.446 | 66.1% | 59.3 / 87.3 | 30–59 | 13–42 | 94.8 |
| Betting rider, skilled v novice, profile skills .9 v .1 | 83.9 | +1.466 | 70.2% | 58.5 / 86.9 | 32–74 | 13–54 | 93.5 |

**On the dial, information is worth almost nothing in the sim.** A perfect reader against a
non-reader wins 49.2% to the control's 48.9%. That's +0.3 points, while a Pass 1 lead of 1–11 half
hearts is worth about ±11. The late switch picks its row from the opponent's public aim and hold;
the opponent's stats only scale the hit, and they almost never change which row is best. So in this
model "revenge by aiming better next pass" comes from read and hold skill, not from what the bar
said. (A ridden-out skilled-vs-novice run with aim reads, cut from the report for runtime, moved the
skilled rider's win rate by under 0.3 points.)

**At the bet, information is worth money, not wins.** A perfect reader wins no more hands than a
non-reader, but takes +0.13 units a hand more (+0.110 against −0.021). At skill .5 it takes +0.04.
It Yields where it's beaten and calls where the bar misled, so the pots it wins are bigger and the
ones it loses smaller. For scale, a skilled rider takes +1.45 units a hand from a novice.

**When both riders read, the cards matter more after the flop and a big lead less.** Two
full-skill readers:

- Yield more (63.5% against 55.2%, mostly on Bets 3–4).
- The cards' swing after two passes grows from 48–57 to 59–64 points.
- The lead's swing narrows from 29–50 to 33–43.
- A 12+ half-heart lead held with worse cards on the flop wins 77.5%, not 92.2%: the rider behind
  knows when to stay in.

That is 0087's direction: "the cards still decide hands after the flop". But it comes from both
riders reading perfectly. At the profile skills (.9 v .1) the skilled rider's edge barely moves.

**The bets cue adds to that.** The same mirror without it (`--set reading.cues.bets=0`) Yields
58.4%, with the cards' swing at 56–58.

### What the model can't say

- **What a reader does with the opponent's aim habits.** "Revenge by aiming better next pass" needs
  a reader who predicts where the opponent will aim. The sim's riders aim honestly or at random and
  react only at 7.4 s, so there is no habit to learn. Information about the cards doesn't change
  which row is best.
- **Hold and first exit as card tells.** They carry 0 bits here because the script sets hold by the
  rider. If players commit early with good hands, these cues would leak, and the sim can't price
  that until the script ties hold to the hand. That would be a design question for Trey, not a
  tuning value.
- **Bluffing against readers.** Stance honesty is fixed. Riders don't change their stance to
  mislead a reader, so there is no equilibrium between reading and bluffing. The 55–64% Yield rates
  are for riders who never bluff in response.
- **Coarse odds.** The betting rider's odds key on about 72 flop hands (category, board pairs, a
  draw flag), so a sharp belief is squeezed to that grain. Finer odds might make information worth
  more at the bet.
- **One hand at a time.** No memory across hands or rematches, no shown cards, and no carry (0095)
  inside the match.
- **People.** Readers are exact Bayesians about a known script, with no clock. Real players read far
  less, and the 8 s pass (§11's playtest question) limits how much of this anyone can use.
- **Pruning.** A pair below 1/10,000 of the top weight is dropped, for speed. When a bet the floor
  allowed has pushed the true pair out, a later update can find no pair left and is skipped: 12 times
  in the both-read mirror's 200k beliefs.

## Questions for Trey

Nothing here is applied.

1. **Board weight ¼ vs ½:** still a small effect.
2. **Should the sim's riders commit earlier with better hands?** Today hold and the first exit from
   Neutral come from the rider's profile alone, so they carry no card information (*What the bar's
   information is worth*). Tying them to the hand is a model choice that would give §7's hold and
   timing tells a value. Options: leave it; commit time shifts with the rider's own odds; or both,
   as a switch.

Answered: Yields under the betting rider led to 0087 (the Posture bar is mostly information). No
rule changes; the reading model is the step that prices the information half.

## Limits of this model

- **Reads are one late switch at 7.4 s against a snapshot.** By default each reading rider
  estimates the opponent's stats from the board plus an average hole card. The reading model
  (*What the bar's information is worth*) is off by default; its own limits are listed there.
- **Extra time past the lock is modelled as "moves last in a double read".** A real rider with
  extra time would also react to single reads.
- **The default betting never Yields,** so under it units won track the win rate. The betting rider
  (*Betting*) Yields and raises on its odds of winning; it doesn't read the opponent's bets.
- **Starting values aren't tuned.** Every "set by the sim" value is a starting value. Only the
  sweeps above were run.
