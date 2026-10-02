---
id: 0057
title: ♦ armor and ♠ piercing convert the stat value, 20 + points
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

§4 *Stat value* says each stat turns its value (`S = 20 + points`) into its effect; §11 wrote the
♦ rate as "armor per point". Under points alone a cardless rider has no armor: their Guard does
nothing and a Block hits like a Normal (SANITY_CHECK c1, `switches.statBasis`). Sim, 100k hands:
value gives gap-1 73.8%, skill flip 60.4%, cross-rung 99.3%; points 74.7%, 57.8%, 98.6%.

## Decision

Trey chose value: ♦ armor and ♠ piercing and charge convert `S = 20 + points`, as ♣ already does.

## Consequences

- §11's stat-rate row says the rates are per stat unit of S.
- `switches.statBasis = value`, already the sim default.
