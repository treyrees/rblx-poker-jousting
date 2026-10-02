# Sanity check: is the GAME_SPEC draft simulatable?

Sep 30, 2026. Checked against `main` at 08e3ff3 (GAME_SPEC through decision 0048), then brought
up to date with Trey's calls 0049–0052: the river flips on the final pass, the showdown adds a
hand bonus to Posture, Pass 4 carries a ×1.3 last-pass bonus (PR #10), and the hold floor is 0.25.
Then 0053–0054: Pass 4 always goes to the knockdown, Posture starts at 80, the street multipliers
are 1.0 / 1.0 / 1.0 / 1.25, and the last-pass bonus is gone. §2's trick sizing and the §4
damage checks below use the new values.

> **Status, Oct 1, 2026.** Trey has answered this report's calls: c1 value (0057), c2 the Normal
> base (0058), c3 F1 (0059), c4 reachable (0060), c5 and the slow-motion switch: excluded (0061),
> c6 after the lean (0062), c7 AGENTS.md points to §1 (0063). C1 and C2 were answered (0055, 0056)
> and then made moot: broadway cards have no effects (0071). The stats were then redefined
> (0067–0070): the ♠ charge, the ♥ cut and the face-effect rows below describe the sim before
> that. The current sim values are in `sim/Config.luau`; the current results are in RESULTS.md.

This report proposes; it decides nothing. Every value below marked **sim config** lives in the
sim's config file and nowhere else. It is never written into GAME_SPEC. Every open question stays
open: the sim models each one as a switch over two or three readings and reports how much the
answer moves the results.

**Verdict: simulatable as config.** The core loop (numeric hands on the dial) needs only sim-set
values, plus one §11 open question modelled as a switch: how slow motion counts toward hold. The
other one it met, the showdown knockdown, is now answered (0050). Three gaps in §6 need a switch
too: the flush's hit, the top card of the straight's meter, and the Block base. None of them blocks
the sim. Phase 2 proceeds. The questions for Trey are at the end.

## 1. Walking one hand

The walk follows §2's *Sequence*. At each step, anything the sim needs that the spec leaves
undefined is tagged:

- **(a)** set by the sim;
- **(b)** a §11 open question the sim can't avoid;
- **(c)** a gap or contradiction.

| Step | Spec source | What the sim needs that the spec doesn't give |
| --- | --- | --- |
| Yard | §2 *The yard* | Prefold cost is open (§11). **(a)** The sim deals random hands and never prefolds, as §6's frequency note assumes ("rates for random deals"). |
| Ante, Bets 1–4 | §2 *Betting rules* | Fully specified as rules. **(a)** A betting policy per rider (aggression), and a Yield threshold. It defaults to never Yield, so every hand is played (pillar 2). |
| Stats per street | §4 *Card values*, *Poker hands multiply*, *Stat value* | Fully specified for ♣. **(a)** The ♥, ♦ and ♠ rates, the lean multiplier and the half-step share (§11 says "set by the sim"). **(c1)** Whether ♦ and ♠ convert the stat *value* `S = 20 + points` or the *points* alone. |
| Posture | §4 *Tracks*, *The four stats* | **(a)** The ♥ rate: start and max Posture = 100 + rate × unleaned ♥ points. |
| Aim, per pass | §3, §8 | The real-time aim war is abstracted into scripted riders with read accuracy, hold discipline, stance honesty and aggression (§11 *Sim plan*). **(a)** When a rider sets a stance, re-stances after the reveal, and switches on a read. **(b)** How slow motion counts toward h. |
| Tier | §3 *Rows by offset*, *Sectors* | Fully specified. The row table agrees with the sector table at all 16 offsets, and its shares match the outcome table: CN 6, NB 4, CB 2, NN 2, CC 1 and BB 1 of 16. |
| Hit output | §4 *Contact resolution* step 2–3 | **(c2)** The Block base is not listed: step 2 gives Weak, Normal and Crit only. |
| ♠, armor, ♥ cut | §4 steps 4–6 | **(a)** Charge per non-crit hit; how ♠ scales a crit; piercing; the thick, thin and sliver armor values; the ♥ lean cut per point. |
| Broadway | §5 | Fully specified except: **(a)** the timing of QQ's "restore 10 per pass", which the sim reads as the start of Passes 2–4, like Q. **C1** and **C2** are below. The K lock (0.15 s, 0.08 s and 0.3 s) has no timing model in an abstract sim. **(a)** It is read as "the K holder's opponent can't answer their last move", so the K holder wins a both-riders-read tie. |
| Tricks | §6 | Ladder, ownership, unleash, answer, clash, cross-rung and board-made rules are all specified. **(a)** The trick hit and ward per rung, the straight meter's x and y mapping, and the flush explosion (§11 lists all of them as set by the sim). **(c3)** The flush's hit (below). **(c4)** The straight meter's fifth card (below). **(a)** The Fortress gap is one direction, which is 2 of 16 positions ("1 in 8 at random"). |
| Showdown | §2 win condition 3, §4 *Tracks* | Answered by 0050: 20 Posture per hand-category step is added, and the lower rider falls. |

### (a) Set by the sim: starting values and sweeps

All of these are **sim config**, in `sim/Config.luau` under `SIM_SET`.

| Value | Start | Sweep | Why this start |
| --- | --- | --- | --- |
| Lean multiplier λ: a stat leaned into at weight w counts `points × (1 + λw)` | 1.0 | 0, 0.5, 1, 2 | ×2 at a cardinal. The gap target (§2 below) caps it near 1. |
| Half-step share (to the nearer cardinal) | 0.75 | 0.6, 0.9 | Linear between a cardinal (1/0) and a diagonal (½/½) |
| ♥ Posture per unleaned point | 3 | 2, 5 | A hole ace of ♥ is +9 Posture |
| ♥ lean cut per leaned point | 0.5 | 0, 1 | A full ♥ lean on 6 points cuts 3 per hit |
| ♦ armor per stat point | 0.25 | 0.15, 0.4 | Guard at S = 20, full hold: 5, about half a Pass 3 Normal |
| ♦ zones: Guard / ordinary / exposure | 1 / 0.2 / 0.05 | n/a | "Thick / thin / sliver" |
| ♠ piercing per stat point | 0.05 | 0, 0.1 | Cardless ♠ pierces 1 |
| ♠ charge per non-crit hit, per S♠/20 | 3 | 0, 6 | A Normal banks about a third of a Normal |
| ♠ crit scale | `S♠ / 20` | n/a | Mirrors ♣ |
| Block base | 10 (Normal) | n/a | See (c2) |
| Stat basis for ♦ and ♠ | value `S` | points | See (c1) |
| Trick hits and wards per rung | See §2 below | ×0.5, ×2 | The smallest chain that meets every §6 target |
| Straight meter | `k·x^y`, x = 1.3, y = rank of the highest card unlocked | x = 1.15, 2 | See §2 below |
| Flush explosion | ×4 on the suit's S at home, ×2 on the diagonals beside it | n/a | Only the suit's effect, under (c3) reading F1 |
| Held straight passive curve | linear in h | n/a | 0048: "0 at the start of each pass, the full +3 at full hold" |
| Trick hit scaling | Flat per rung. No ♣, tier base or hold multiplier; the straight's meter replaces hold (§6). | n/a | "Hit sizes are sim values" |
| Gilded Mirror | Guard-thick armor on all 16 positions. It reflects the armor-stopped amount. | n/a | §6 *Flush by suit* |

### (b) Open questions the sim can't avoid, modelled as switches

| Question (§11) | Switch | Readings |
| --- | --- | --- |
| How slow-motion time counts toward h | `slowmo` | `wall`: every wall-clock second counts; the run-up is 7.7 s. `game`: slow motion counts at 0.4×; the run-up is 6.8 s. `excluded`: 3.0–4.5 s doesn't count; the run-up is 6.2 s. |

The hold-floor question was a sweep (`holdFloor` 0.2–0.6). 0052 answers it: the floor is 0.25.

The unhorse-as-a-roll question is not modelled. The spec says hard 0, and the sim builds that.

### (c) Gaps and contradictions

None of these blocks the sim. Each is a switch, and each needs Trey's answer before its numbers
mean anything.

1. **(c1) ♦ and ♠ convert value or points?** §4 *Stat value* says "each stat turns its value
   into its effect at its own rate", where the value is `20 + points`. §11 says "♦ armor per
   point". Under points, a cardless rider has no armor, so the Guard does nothing and a Block
   hits like a Normal. The §3 rows would lose their meaning, so the sim starts on value.
   Switch: `statBasis`.
2. **(c2) Block base.** §4 step 2 lists Weak 4, Normal 10 and Crit 30. §3 calls a Block "a hit
   into your Guard armor", so the sim reads it as a Normal (10) into thick armor. Switch:
   `blockBase`.
3. **(c3) What is a flush's hit?** §6 *The hit* sizes every trick's hit to unhorse when played to
   design, a flush "aimed at its suit's home". §11 lists "trick hit per rung" and "flush: suit
   stat explosion" as separate values. The ♥ and ♦ explosions don't feed a hit at all: ♥ is
   Posture and a damage cut, ♦ is armor. So they can't be what makes a ♥ or ♦ flush unhorse.
   Two readings:
   - **F1** (start): the flush has a per-rung hit, scaled by its home factor (1 at home, ½ on
     the diagonals beside it, 0 elsewhere). The explosion only powers the suit's rule.
   - **F2**: the hit *is* the exploded stat. The ♣ and ♠ flushes get huge numeric hits; the ♥ and
     ♦ flushes hit like a numeric hand but can't lose.

   Switch: `flushHit`.
4. **(c4) The straight's fifth card can't be reached.** The meter unlocks card k at h ≥ k/5, so
   the fifth card needs h = 1. But every pass starts at Neutral (§3), and h counts from the start
   of the charge, so any real rider has h < 1. Two readings:
   - `strict`: never more than four cards.
   - `reachable` (start): h is measured against the earliest possible commit (0.3 s into the
     charge), so a rider who commits at once unlocks all five.

   Switch: `meterThreshold`.
5. **(c5) Is the §8 table an answer to an open question?** §8's decision-window row says "Hold
   fraction counts only real time at full speed". §3 and §11 say how slow motion counts is open.
   The sim treats it as open, per §11, and runs all three readings.
6. **(c6) The §4 damage checks leave out armor, ♠, the ♥ cut and the lean.** They still hold to
   within one point (§2 below). But "trips-loaded ♣ ×1.45" is 9 unleaned ♣ points. Once a lean
   applies, the same hand at λ = 1 is ×1.9 at Up. It is unclear whether the ×1.0–1.45 gap target
   predates the lean (0034 predates 0037). The sim reports the gap both with and without the lean.
7. **(c7) AGENTS.md's pillars are no longer verbatim.** AGENTS.md says its pillars are
   "Verbatim from GAME_SPEC §1". GAME_SPEC §1 has since reworded pillars 1, 3 and 5 (0013, 0017,
   0002). This session doesn't edit AGENTS.md's pillars; it's Trey's file.

### Known unresolved calls

| Call | In the sim |
| --- | --- |
| C1: QQ Twin Favor vs a trick's unhorse | Switch `twinFavorVsTrick`: `negates` (Twin Favor negates any first unhorse, trick included) or `trickOverrides` (a trick's unhorse ignores it) |
| C2: AA's "edge notch" on the half-step dial | Switch `aaEdge`: `one` (position 5, the first ordinary half step past the exposure), `both` (5 and 15, both edges), or `direction` (5 and 6, a full direction) |
| C3: §8 numeric setups | Presentation only. Not in the sim. |
| C4: §9 "Reads always beat rarity" row | Not a rule of this game. Not in the sim. |
| C5: §10 favorite-card buff | v2, deferred. Not built. |

Also not built: the J and JJ effects (information effects with no reading model, §5 sim note),
colors, spectators and presentation.

## 2. Target feasibility

### Numeric gap ×1.0–1.45 (§4)

This check drew 40k random river deals. It compares the two riders' best loaded-stat
multiplier, `1 + 0.05 × points × (1 + λ)` on their most-loaded suit, taking the better category
over the worse. It uses board weight ½.

| λ | Mean multiplier: HC / pair / 2P / trips | Better-over-worse median, gap 1 / 2 / 3 | Worse category loads more |
| --- | --- | --- | --- |
| 0 | 1.22 / 1.27 / 1.32 / 1.35 | 1.05 / 1.10 / 1.14 | 24% / 12% / 6% |
| 1 | 1.44 / 1.55 / 1.65 / 1.71 | 1.09 / 1.16 / 1.25 | 24% / 12% / 7% |
| 2 | 1.66 / 1.82 / 1.98 / 2.06 | 1.12 / 1.21 / 1.31 | 23% / 12% / 7% |

On a ♣-only stance (Up), the 90th-percentile gap across all deals is ×1.21 at λ = 0, ×1.40 at
λ = 1 and ×1.57 at λ = 2.

- **The target holds for λ ≤ 1.** At λ = 2 the tail passes 1.45. The λ = 0 row reproduces 0035's
  figures.
- Categories order on average, not per deal. A pair loads less than high card in about a quarter
  of pair-vs-high-card deals (0035 already notes this).
- A board weight of ¼ changes the medians by at most 0.06.

### A trick's hit unhorses from full Posture on the earliest pass when played to design

- Let **P\*** be the most one hit must clear: max Posture, plus Guard armor at full hold, plus
  the ♥ cut.
- At the starting values, P\* is about 149 (Posture 128, armor 13, cut 8). This takes a
  generous bound of 16 ♥ points, the full house passive included.
- No trick exists before the flop, which lands on Pass 2 (0049). The hit is street-scaled, so a
  Pass 2 unhorse needs `1.0 × hit ≥ P*`: a hit of about 150 or more (0054).

### Each rung's ward stops every lower rung's hit

Wards are flat and hits are street-scaled. So the binding cases are:

- a ward against the lower hit on Pass 4, at ×1.25;
- the higher hit against the lower ward on Pass 2, at ×1.0.

The minimal chain, with H for a rung's hit and W for its ward:

- Straight: `k·x^5 ≥ P*` (the wheel, at full meter).
- Flush: `W_F ≥ 1.25 · k·x^14` (it must stop the ace-high straight at full meter, per 0032), and
  `H_F ≥ P*`.
- Full house: `H_FH ≥ P* + W_F`, and `W_FH ≥ 1.25 · max(H_F, H_S)`.
- Quads: `H_Q ≥ P* + W_FH`, and `W_Q ≥ 1.25 · H_FH`.
- Straight flush: `H_SF ≥ P* + W_Q` (it beats the quads ward, per 0033).

| x | Wheel full | A-high full | x^4 (first card to fifth) | W_F | H_FH | H_Q | H_SF |
| --- | --- | --- | --- | --- | --- | --- | --- |
| 1.3 | 150 | 1.6k | ×2.9 | 2.0k | 2.1k | 2.1k | 2.8k |
| 2.0 | 150 | 76k | ×16 | 95k | 96k | 96k | 120k |

- **Every trick target can hold at once.** These are minimums. With the flatter multipliers
  (0054) each rung needs only about ×1.3 over the one below; the starting hits and wards
  (`sim/Config.luau`, sized under the old ×0.75 and ×1.625) clear them with room, and the
  explosive growth §6 asks for is a choice of size, not a requirement.
- **There is one tension, inside the straight.** 0032's "most of the power arrives toward the end
  of the hold" wants a large x: x^4 is the growth from the first card to the fifth. But y is the
  card's rank, so the wheel-to-ace-high spread is x^9, and every ward above it inflates by the
  same factor.
  - With x = 1.3, the fifth card is worth about three times the first. That's modest.
  - With x = 2, the fifth is ×16, but the ace-high straight is ×512 the wheel.
  - The spec leaves "how y maps to hit size" to the sim, so this is tunable, not blocking.
  - The sim starts at x = 1.3 and sweeps 1.15 and 2.
- **The straight flush beats the quads ward** as long as `H_SF ≥ P* + W_Q`. Its hit also needs
  both conditions met (0033): the meter and the home lean, each played in full.

### The §4 damage checks

These use armor from `S♦ = 20` at the starting rate, with the thin and sliver zones, less a
cardless rider's piercing (1).

| Check | Spec | With armor and piercing |
| --- | --- | --- |
| Pass 1 Normal, high card, half hold | 6.3 | 6.3 |
| Pass 3 Crit, trips-loaded ♣, full hold | 43 | 43.5 |
| Pass 4 Crit, the same | 54 | 54.4 |

At the starting rates, a cardless rider's piercing cancels the thin and sliver armor. They hold, but
only with the lean off; see (c6). The sim's tests pin them at λ = 0.

## 3. Verdict

**Simulatable as config.** Phase 2 builds the whole hand: the yard deal, 4 bets, 4 passes,
contact resolution, tricks, board-made tricks and the showdown. It stubs only the J and JJ
information effects, which the spec itself says need a reading model.

Questions for Trey. The sim runs every reading, so none of these blocks it.

1. (c3) Is a flush's hit its own per-rung number (F1), or the exploded stat (F2)? Under F2, what
   makes a ♥ or ♦ flush unhorse?
2. (c4) The straight's fifth card needs h = 1, which no rider can reach. Should it be `reachable`
   (h measured from the earliest commit) or a lower threshold?
3. (c1) Do ♦ armor and ♠ piercing convert the stat value (`20 + points`) or the points alone?
4. (c2) Does a Block use the Normal base (10)?
5. (c6) Is the ×1.0–1.45 numeric gap measured before or after the lean?
6. (c5) Does §8's "hold fraction counts only real time at full speed" answer the slow-motion
   question, or should it wait with §11's open question?
7. C1, C2: the sim reports both sides of each.
8. (c7) AGENTS.md's pillars have drifted from GAME_SPEC §1.
