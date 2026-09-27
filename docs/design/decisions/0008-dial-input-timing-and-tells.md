---
id: 0008
title: Dial input, hold, aim lock and public tells are clarified
date: 2026-09-26
decided-by: trey (chat, §3 review session, 2026-09-26)
supersedes: []
superseded-by: null
---

## Context

The §3 review found gaps and ambiguities: "clockwise" was undefined once riders' screens
mirror, the run-up for the hold fraction was undefined, the spec gave no way back to
Neutral, the aim lock's stated purpose overclaimed, and the borrowed wheel's branch name was
wrong. Trey, on the review's recommendations: "Everything else is as presented."

## Decision

- The sweep runs in label order (Up → Up-Out → Out → … → In-Up), the same for both riders,
  however each screen mirrors the ring.
- Your ring shows the opponent's sectors projected onto it.
- The run-up for the hold fraction is the whole charge, from its start to aim lock. How
  slow-motion time counts is open.
- The flick concern's open question states its threshold: a last-instant switch onto a held
  aim wins when the floor is above what the holder deals back divided by what the switch
  deals (Normal/Crit = 1/3 on a CN row).
- Tap the hub for Neutral. The aim lock is described by what it does (server-side resolution,
  the animation can start), not as ending ping wars.
- Aim timing is public. A hit's size shows the attacker's stat after contact; whether one hit
  can identify a rank at display precision is open.
- Neutral's Weak strike has no axis; which offense stat it uses is open.
- The Magnet wheel is on branch `claude/ring-spin-ui-feel-xpatk4`, files
  `src/shared/WheelPhysics.luau` and `Constants.WHEEL`.

## Consequences

- §3, §9, §11 and AGENTS.md updated. The §11 values are unchanged.
