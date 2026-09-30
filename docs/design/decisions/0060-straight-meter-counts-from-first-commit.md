---
id: 0060
title: The straight's meter fills against the earliest possible commit
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

The meter unlocks card k at h ≥ k/5, so the fifth card needs h = 1. Every pass starts in Neutral
and h counts from the start of the charge, so no rider reaches it (SANITY_CHECK c4,
`switches.meterThreshold`). Sim, 100k hands: straights fired above win 98.8% / 98.2% (to design /
off) under the reachable reading and 98.3% under strict, where no straight is ever to design.

## Decision

Trey chose reachable: the meter measures hold against the earliest possible commit, so a rider who
leaves Neutral at once and holds to aim lock unlocks all five cards.

## Consequences

- §6 *The straight's meter* says so. How early the earliest commit is stays a sim value (0.3 s).
- `switches.meterThreshold = reachable`, already the sim default.
