---
id: 0056
title: AA Champion's edge notch is the half step just past the exposure's far edge
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: 0071
---

## Context

AA Champion: "your Normal hits on the exposure's edge notch also count as Crit". "Notch" is
8-direction language; the dial resolves in 16 half steps (0007), with exposure at 0–4 from the
target's aim. The sim read it three ways (`switches.aaEdge`, SANITY_CHECK C2): half step 5 (one),
5 and 15 (both edges), or 5 and 6 (a full direction).

A targeted count, 100k hands with seat 1 dealt AA (seed 20260930): AA wins 73.9% (one), 75.0%
(direction), 79.4% (both) against average riders; 75.7 / 75.8 / 80.6% skilled against skilled.

## Decision

Trey chose "one": half step 5, the first ordinary half step past the exposure's far edge.

## Consequences

- §5 AA row says so. AA's crit share of positions goes from 5 of 16 to 6 of 16; the NB row at
  offset 5 becomes a CB row for AA.
- `switches.aaEdge = one`, already the sim default.
