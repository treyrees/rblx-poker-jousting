---
id: 0061
title: Slow motion doesn't count toward the hold fraction
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

§11 asked how the slow-motion beat after a reveal (3.0–4.5 s, 0.4×) counts toward h. §8's
decision-window row already said "Hold fraction counts only real time at full speed" (SANITY_CHECK
c5). The sim ran three readings (`switches.slowmo`): wall (every second counts), game (0.4×) and
excluded. Under excluded any re-aim during slow motion gets the same h as one at 4.5 s. Sim, 100k
hands, wall / game / excluded: skill flip 60.4 / 62.0 / 63.1%, gap-1 73.8 / 74.5 / 75.0%, turn
endings 11.4 / 10.6 / 9.9%, cross-rung 99.3 / 99.3 / 100%.

## Decision

Trey chose excluded: slow motion doesn't count toward the hold fraction. It is a beat to read the
card, not a reflex test.

## Consequences

- §3 *Held aim* says so, and the §11 open question is removed. §8 already agreed.
- `switches.slowmo = excluded` is the sim default; RESULTS.md is rerun at it.
- Turn endings fall to about 10%, the bottom of 0054's 10–15% target.
