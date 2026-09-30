---
id: 0043
title: The §11 trick rows follow the rebuilt tricks
date: 2026-09-29
decided-by: trey (chat, §6 review session, 2026-09-29)
supersedes: []
superseded-by: null
---

## Context

The §11 trick rows (Straight ×1.5 and 4 directions, Flush axis stat ×2, Quads per-cardinal
output 50%) predated the §6 rebuild (0028, 0031–0033). The held passive sizes (+3 to +4) are now
read in card points (0034).

## Decision

Trey: "r3.4 yes".

- Removed: Straight output and exposure ×1.5 and 4 directions; Flush axis stat ×2; Quads
  per-cardinal output 50% (the parry replaces it).
- Added, set by the sim: trick hit per rung (unhorses from full Posture when played to its
  design); trick ward per rung (0027); the straight meter's base x and how y maps to hit size
  (0032); the flush's suit stat explosion.
- Kept: Full house Guard coverage 7 of 8 directions; held passives +3 to +4, now in card
  points, for the sim to check.

## Consequences

- §11 *Tuning parameters* updated. No kept value changed.
- A row for the straight's exposure (positions 0–6, from the Charge row) is carried while the
  Charge's widened exposure stands; the review has proposed dropping it.
