---
id: 0032
title: A straight's hit grows with a meter through its five cards
date: 2026-09-29
decided-by: trey (chat, §6 review session, 2026-09-29)
supersedes: []
superseded-by: null
---

## Context

Trey asked that a straight "make its money by heavily amplifying the buildup of staying
still", with higher straights doing this much better.

## Decision

Trey: "a meter should progress through the 5 straight cards ticking each one incrementally
upwards as unlocked, and the final bonus is something like x^y where x is static and y is the
value of the card, conceptually where by holding down for longer on linear timer, you get
stronger and stronger value for how long you held it down towards the end. conceptual, you can
massage the math as you need."

- On the unleash pass, a meter steps through the straight's five cards, low to high, as the
  rider holds one aim: one card per fifth of the run-up (h ≥ 1/5 … 5/5). Changing aim resets it.
- The hit grows as x^y: x a fixed base, y the value of the highest card unlocked. Most of the
  power arrives toward the end of the hold, and higher straights build bigger.
- The meter replaces the hold multiplier for the trick's hit. x and the mapping to hit size are
  sim values.

## Consequences

- §6 gains *The straight's meter*.
- Hold counts from the start of the charge. On the pass a straight completes (reveal at 3.0 s)
  the rider must already have been holding; on later passes they know from the first second.
  How slow motion counts toward h (a §11 open question) now matters for straights.
- The rest of the Charge row (can't be Blocked, exposure widened one direction) is unchanged;
  the review proposed dropping both, which Trey has not decided.
- A flush's ward (0027) must stop an ace-high straight at full meter; a sim limit.
