---
id: 0107
title: The bot bets after a short think and aims at its scripted times
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

In the sim, bets and aims are instant. In real time the bot acts beside a human. Put to Trey:
bets after a short think and aims at its scripted times; instant bets; or the bot always uses its
full window.

## Decision

- **Bets:** the bot acts 1.0–2.5 s into its 5 s window, at random, never instantly.
- **Aim:** the bot leaves Neutral at the sim's commit time for its profile, re-stances at the end
  of slow motion if the reveal moved its best lean, and takes its read (chance = its profile's
  read) at 7.4 s against the human's public aim and hold. The server moves its needle straight to
  the position. Its first exit from Neutral and its hold meter are public, as §3 lists.

## Consequences

- As in the sim, a bot that read and locks later than the human (0069) re-reads against the
  human's final aim once the human is locked.
- The think times are config (`src/shared/Slice.luau`).
