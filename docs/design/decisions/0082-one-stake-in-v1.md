---
id: 0082
title: One stake in v1
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

With a prefold price (0080) and carry (0078), the unit's value matters to the yard. Stake tiers
would mean matching on stake as well as wait time, and splitting the yard into one pool per stake.

The options put to Trey:

- **One stake:** "A single unit value in earned currency for v1, with stake tiers deferred. One
  yard, so the matchmaker never splits the player pool by stake. What a unit is worth stays Open on
  the Economy row with the Roblox question."
- **Defer to Economy:** leave stakes Open with the Roblox and currency questions.
- **Tiers in v1:** several stake levels from launch; the matchmaker matches on stake, and waits
  lengthen.

## Decision

Trey chose **one stake**.

- v1 has a single unit value, staked in earned currency. Stake tiers are deferred.
- What a unit is worth, and session or daily limits, stay Open on the Economy row with the Roblox
  question (§11).

## Consequences

- §1 Status gains a row: one stake in v1, Settled for v1. §2 *The yard* says every match is
  played for the same unit.
- The matchmaker has no stake to match on (0083).
- Nothing in the sim changes: it measures everything in units.
