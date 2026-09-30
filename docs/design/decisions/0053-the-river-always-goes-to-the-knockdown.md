---
id: 0053
title: The river always goes to the knockdown, and Posture below 0 counts
date: 2026-09-30
decided-by: trey (chat, showdown review session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

Under 0050, a rider taken to 0 on Pass 4's contact was unhorsed before the hand bonus counted,
and the bonus landed only when no one fell. So the cards counted in some river endings and not
others. The showdown brief (docs/sim/SHOWDOWN.md) laid out the problem and the solution families.

Asked whether it matters if the lance or the knockdown drops a rider on the river, Trey: "What's
the difference? Final round gets a bonus, result resolves."

## Decision

Trey: "change bonus to always apply in final round".

- Pass 4's contact unhorses no one. After it, each rider's hand bonus is added to their Posture
  and the rider lower on the total is knocked down. Passes 1–3 are unchanged: Posture 0 unhorses.
- **Posture below 0 counts** at the knockdown. The alternatives were counting it as 0, and using
  Posture before the pass when both riders are lanced (win condition 2's reading). Trey: "below 0,
  because it decides using the final pass".
- **Unbroken and Twin Favor.** Both were written against an unhorse on contact, which no longer
  happens on Pass 4. Trey: "Both seem like old artifacts, take the spirit of what needs
  accomplished in the fantasy/mechanics and redesign". The proposal Trey accepted ("yes to
  both"):
  - ♥ Unbroken: "Your Posture can't fall below 1 this pass." It still closes the out (0029) on
    every pass.
  - QQ Twin Favor: "Once per hand, the first time your Posture would fall to 0 or below, it is 20
    instead."
- **No extra presentation beat.** The reveal blow (SHOWDOWN.md candidate B) is not adopted. After
  Pass 4's contact the hole cards flip and the bonus pours into the bar as §8 describes. A bar the
  river's lance took past empty shows how far below 0 it went.

## Consequences

- §2 win conditions 1–3, §4 *Tracks and showdown*, §5 Twin Favor, §6 (the trick intro and
  Unbroken), §8 *Showdown* and §9 updated.
- Win condition 2 (both unhorsed on one contact) applies to Passes 1–3 only.
- Neither rewording changes what the effects did before: under 0050, Unbroken already kept its
  rider at 1 or more on Pass 4, and Twin Favor already set them to 20, before the bonus landed.
- In the sim (`switches.riverRule = knockdown`, the default), a trick held above the opponent and
  auto-fired on Pass 4 wins 99.7%, up from 93.7%: it can no longer be lanced down on the same
  contact.
- At 0054's numbers, the bonus overturns the Posture order after Pass 4's contact in about 11% of
  river endings (9% of hands). The rider who falls was already at or below 0 in 35%.
- Trey also asked about a ramp: the bonus building from the turn to the river. A visible one leaks
  the category on the turn; a hidden one (a cushion below 0 on Pass 3) is in the sim as
  `proto.turnCushion`, off. Neither is part of this decision.
