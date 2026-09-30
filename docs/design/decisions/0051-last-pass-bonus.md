---
id: 0051
title: Pass 4 carries a ×1.3 last-pass damage bonus
date: 2026-09-30
decided-by: trey (chat, sim review session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

In the sim about 3 in 4 hands ended at the showdown knockdown rather than with a lance. Trey:
"let's start implementing a modest last-round damage bonus." The sim swept an extra multiplier on
Pass 4 damage from ×1.0 to ×2.0 (PR #9, `--report final`).

## Decision

Trey: "1.3".

- Pass 4 carries a last-pass bonus of ×1.3, on top of its ×1.25 street multiplier.

## Consequences

- §2 *Sequence*, the §4 sanity checks and the §11 parameter table updated.
- In the sim, with the river on the final pass (0049), unhorses on the final pass rise from about
  21% to 27.5% of hands, and a rider with a clear lead (20+ Posture) going into Pass 4 still wins
  about 81% of the time, against 84% without the bonus.
