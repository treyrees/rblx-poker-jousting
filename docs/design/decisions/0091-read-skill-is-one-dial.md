---
id: 0091
title: Read skill is one dial from 0 (today's rider) to 1 (a perfect reader), weighing the read
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

How good is a reader? The options put to Trey were one dial from 0 to 1, tiers of which cues a rider
attends to, or noisy perception of the cues. He chose "One dial, 0 to 1", described then as scaling
how far each cue moves the belief.

Built that way, a reader below full skill never rules a hand out, so it kept about 1,200 candidate
hands live all hand and ran about 3× slower. Trey had also set a budget ("a robust complicated sim at
most shouldn't take longer than 10 minutes"). Put back to him: keep the dial, but let skill weigh
the read at the decision instead of each cue. Trey: "keep, save runtime!"

## Decision

- Each rider profile has `readSkill`, 0 to 1. Every reader's belief is exact (each cue applied in
  full). A rider at skill s weighs that read by s and today's estimate (an average hole card for a
  read, its own odds for a bet) by 1 − s.
- s = 1 is a perfect Bayesian about the sim's riders. s = 0 is today's rider: it keeps no belief.
- Starting values: skilled 0.9, average 0.5, novice 0.1.
- The reader assumes the opponent rides as the average profile (`reading.assume`).

## Consequences

- Sweeping readSkill gives the curve of what the information is worth as read skill rises.
- Bits learned per cue are a property of the cues, the same for every reader.
- Sim values, not §11 values: GAME_SPEC is unchanged.
