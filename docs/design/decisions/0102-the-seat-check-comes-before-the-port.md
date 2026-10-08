---
id: 0102
title: The sim's seat asymmetry is checked, and fixed if it is a sim bug, before the hand is ported
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

In an average-vs-average mirror the sim's seat 1 won about 48.9% (docs/sim/RESULTS.md, *What the
bar's information is worth*), possibly from processing order in `sim/Hand.luau`. The slice ports
that hand's flow. Put to Trey: check it first, in the same PR; check it in its own PR after the
slice; or don't check it.

## Decision

Check it first, in the same PR as the slice: find whether the asymmetry is the rules or the
sim's processing order, fix it in `sim/Hand.luau` with a test if it is the sim, and report the
run.

## Consequences

- What the check found and what moved is in docs/sim/RESULTS.md, *Seat order*.
