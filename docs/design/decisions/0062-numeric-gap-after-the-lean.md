---
id: 0062
title: The numeric gap target is measured after the aim lean
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

§4 says the gap between two riders' numeric hands is about ×1.0 to ×1.45 on a hit. That line
(0034, 0035) predates the aim lean (0037) (SANITY_CHECK c6). Sim gap report, 100k river deals,
better-over-worse median at category gaps 1 / 2 / 3: λ = 0 1.06 / 1.10 / 1.14; λ = 1 1.09 / 1.17 /
1.23. On a ♣-only stance the 90th percentile is ×1.21, ×1.40 and ×1.57 at λ = 0, 1 and 2.

## Decision

Trey chose "after the lean": the ×1.0–1.45 gap is what a leaned hit deals.

## Consequences

- §4 *Poker hands multiply* says the gap is with the lean applied. It holds for λ ≤ 1, so the
  lean multiplier (a sim value) stays at 1 or below.
- The §4 damage checks leave out the lean, armor and piercing; §4 says so.
