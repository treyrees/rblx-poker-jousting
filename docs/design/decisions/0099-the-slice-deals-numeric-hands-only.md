---
id: 0099
title: The slice deals numeric hands only
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

Tricks and unleash are out of the first playable slice (0097), and GAME_SPEC is silent on how a
hand that makes a straight or better plays without them (0097, *Consequences*). Put to Trey: deal
numeric hands only; play a trick as its numeric sub-hand; or stop the hand with a placeholder.

## Decision

The slice redeals, server-side, until neither rider can make a straight or better by the river.
Every hand the slice plays is one GAME_SPEC specifies in full. The redeal count goes in the cue
log.

## Consequences

- About 1 deal in 5 is thrown away: in the sim's baseline 81.7% of hands are numeric for both
  riders at the river. (The question put to Trey said about 1 in 20; that estimate was wrong.)
  Nothing in the hand's rules changes.
- This is the slice's deal, not v1's. Tricks come back with §6.
