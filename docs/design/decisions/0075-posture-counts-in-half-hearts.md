---
id: 0075
title: Posture counts in half hearts; a trips-sized hit may say "trips"
date: 2026-10-07
decided-by: trey (chat, paused §11 questions session, 2026-10-03 to 2026-10-07)
supersedes: []
superseded-by: null
---

## Context

§11 asked whether one hit's size can identify a hand's rank at display precision. A hit's size is
public, and the striker's cards are the only hidden input to it. A rider has no other input:
no spur, speed or momentum (§9). The sim modelled a perfect observer: the defender lists every
hole pair they can't rule out and checks which ones give the same displayed hit (100k hands,
average riders, Passes 1–3; Pass 4's hit can't be used, since no bet follows it).

- At whole-Posture precision, 4.6% of pocket-pair hits on Pass 1 had only one hole pair that fit:
  they named the exact hand (pillar 4).
- Trips were certain on 18–24% of their hits on Passes 2–3. That doesn't come from precision: the
  ×3 multiplier puts the top of the hit range out of reach of every other numeric hand, so even a
  display in 10-Posture steps still showed it on about 1 hit in 5.

## Decision

Trey chose to show Posture in pips and to keep the trips leak.

- Trey: "Coarser display means we show posture in full pips - nice and intuitive, mechanically
  like zelda. rounds close results together."
- **Posture counts in pips, with visible tiebreakers.** Trey: "posture counts in pips with visible
  tiebreakers rather than tiebreaker being a hidden underneath number."
- **The pip is a half heart.** Trey: "a half heart is very visualizable, more discrete than full
  and not as squinty as quarter heart", with 16 hearts shown as a bar of 2×8. On the numbers he
  asked to "make the math easy for ourselves and 'reduce the equation'", leaving them to the sim:
  "you are the authority on the numbers."
  - 1 Posture is a half heart. Every rider has 32 (16 hearts).
  - Posture rounds only when it changes. A hit's damage (and a reflect) rounds to the nearest half
    heart as it lands; the ♥ heal rounds up, so every heal shows. Everything before that stays
    exact.
  - The showdown compares whole half hearts; riders level on half hearts go to the kickers, shown
    to both.
- **Granularity is for obfuscation, not to remove texture.** Trey: "the coarseness is to obfuscate
  identical actions, not take gameplay texture away." Rounding the heal up comes from this: at half
  hearts rounded to the nearest, 46% of heals showed nothing.
- **The trips leak stays.** Trey: "The trips leak - assuming its the 'sweet spot' of things that can
  get leaked as in strong enough to be identifiable by strength but also available early - should
  be kept in place. the fun of it should be the early 'healtbar overwhelming advantage' - you know
  i have trips, but i just hit you with a huge strike early on, thats the dynamic id like." §7
  names it as the one tell allowed a single cause.

## Consequences

- Every Posture-measured number divides by 2.5, so the design is unchanged in proportion: Posture
  80 → 32, Weak / Normal / Crit 4 / 10 / 30 → 2 / 4 / 12 (Weak rounded from 1.6), the hand bonus
  20 → 8 per step (4 hearts; 0050), the clean block restore 3 → 1 (a half heart; rounded from 1.2).
  The sim values measured in Posture scale the same way (armor, piercing, the ♥ buffer, the
  straight meter, trick hits and wards). Ratios don't change: card points, multipliers, hold,
  street multipliers, Battered and the heal share.
- At half hearts with the heal rounding up (100k hands), the game plays as before: skill flip
  64.7% (66.1% exact), better category wins 77.3 / 91.4 / 95.2% at gaps 1–3, turn endings 9.0%.
  The exact-hand leak falls to 1.8% at worst (pocket pairs on Pass 1). 2.3% of showdowns are
  level on half hearts; the kickers decide 2.2%, and 0.1% split.
- GAME_SPEC §2 rule 4, §3 *Public vs hidden*, §4 (*The four stats*, *Contact resolution*, *Tracks
  and showdown*, *Sanity checks*), §7, §8 *Showdown* and §11 change; the §11 hit-size question
  closes. §1 Status gains a Settled row for Posture in half hearts.
- The sim counts Posture in half hearts by default (`switches.posture = "pips"`,
  `switches.healRound = "up"`); `"exact"` stays for comparison.
