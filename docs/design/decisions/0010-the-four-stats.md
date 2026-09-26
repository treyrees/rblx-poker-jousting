---
id: 0010
title: The four stats are ♥ Posture, ♦ Armor, ♣ raw damage and ♠ crits
date: 2026-09-26
decided-by: trey (chat, §3 review session, 2026-09-26)
supersedes: []
superseded-by: null
---

## Context

0003 left open what the four stats are and what they do. Trey: "four stats. two defensive, two
offensive. they roughly correspond to each other."

## Decision

In each pair one stat is raw and linear and the other is circumstantial.

- ♥ Sturdiness is Posture. Trey: "directly converts into posture, basically health." Max and
  starting Posture grow with ♥; a reveal that raises ♥ gains the difference; a reveal that
  lowers it drops the max but doesn't take current Posture away.
- ♦ Armor. Trey: "strong expected value, but the game is often won/lost on posture, depending
  on how it was applied." A flat reduction per hit, mapped onto the dial: thick on the Guard,
  thin on ordinary positions, none on the exposure. A Block is a hit into thick armor, which
  replaces the block leak formula. Guard armor scales with hold.
- ♣ Knockoff. Trey: "'true damage' just means 'linear/raw damage'. doesnt mean ignore armor."
- ♠ Pierce. Trey: "spade functioning as the crit stat, armor piercing stat, and pay-later stat
  feels right. what if it paid later but still via crits? ... noncrits with a spade
  incrementally buff further crits." The pay-later mechanism is Trey's proposal, still open.
- Offense stats keep following the aim's axis (♣ vertical, ♠ horizontal). Defense stats don't
  follow aim: ♥ is always on and ♦ follows the sectors.

## Consequences

- §4 gains *The four stats* and *Stances*; contact resolution step 4 becomes armor.
- §1 Status: the four stats are Settled in shape, with ♠'s pay-later open.
- Pillar 5 reads "each stat lives on an axis of the dial". ♥ and ♦ no longer do. The pillar's
  wording is Trey's to revisit; it is unchanged here.
- §5 KK ("their block leak against you is halved") names the replaced leak; revisited in the
  §5 review.
