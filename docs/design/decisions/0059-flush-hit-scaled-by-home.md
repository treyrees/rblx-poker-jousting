---
id: 0059
title: A flush has its own hit, full at home, half beside it, none elsewhere
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

§6 *The hit* sizes every trick's hit to unhorse when played to design, for a flush "aimed at its
suit's home". §11 listed a hit per rung and the flush's stat explosion separately, and the ♥ and ♦
explosions can't feed a hit (SANITY_CHECK c3, `switches.flushHit`). F1: the flush has its own hit
scaled by a home factor, and the explosion powers the suit's rule. F2: the hit is the exploded
stat. Sim, 100k hands: flush above, to design vs off design, 98.8% vs 94.2% under F1 and 97.9% vs
96.9% under F2; cross-rung 99.3% vs 98.6%.

## Decision

Trey chose F1.

- The flush's hit lands in full at its suit's home, at half on the two diagonals beside it, and
  not at all elsewhere; half steps share it as on the compass.
- The explosion powers the suit's rule (Shattering Blow, Needle, Unbroken, Gilded Mirror).

## Consequences

- §6 *Flush by suit* says so. The flush's hit is one of §11's per-rung trick hits.
- `switches.flushHit = F1`, already the sim default.
