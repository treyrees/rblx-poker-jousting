---
id: 0091
title: Read skill is one dial from 0 (learns nothing) to 1 (exact Bayes)
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

How good is a reader? The options put to Trey were one dial that scales how far each cue moves the
belief, tiers of which cues a rider attends to, or noisy perception of the cues.

## Decision

Trey chose the recommended option: "One dial, 0 to 1".

- Each rider profile gains `readSkill`. A cue's likelihood L, scaled so that its largest value is 1,
  moves a pair's weight by (1 − s) + s·L. At s = 1 the reader is a perfect Bayesian about the
  sim's riders; at s = 0 it learns nothing.
- Starting values: skilled 0.9, average 0.5, novice 0.1.
- The reader assumes the opponent rides as the average profile (`reading.assume`).

## Consequences

- Sweeping readSkill gives the curve of what the information is worth as read skill rises.
- Sim values, not §11 values: GAME_SPEC is unchanged.
