---
id: 0049
title: The river flips on the final pass; Pass 1 rides on hole cards
date: 2026-09-30
decided-by: trey (chat, sim review session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

§2 put the flop, turn and river on Passes 1–3 and made Pass 4 a full-information showdown pass
with no reveal. Trey's model of the hand was different: "I thought the final round would always
be the reveal of the final card, the river ... the last pass is the river, which gets entered
with 2 holes + 4 community." Four passes and three reveals mean one pass has no card; the review
asked which one.

## Decision

Trey: "First pass (river on final)".

- Pass 1 rides on hole cards alone, with no reveal.
- The flop, turn and river reveal mid-charge on Passes 2, 3 and 4.
- Bet 4 is made on the turn. The river lands on the final charge, and the showdown follows
  Pass 4's contact.

## Consequences

- §2 *Sequence* and intro, §6 (the earliest a trick can fire is Pass 2; unleash timing; board
  tricks from the river's reveal; the frequency text names passes) and §8 (Pass 1 has no reveal;
  Pass 4 carries the river and the showdown) are rewritten.
- There is no betting round after the river, unlike hold'em.
- In the sim (PR #9, `proposed.passOrder`), knockouts gather on the final pass, most tricks fire
  there by auto-fire, held tricks are drawn out more often (3.8% → 9.5%), and straights completed
  on the river rarely reach a full meter (38% → 15% of straights). Hand ordering, skill and the
  hold floor barely move.
