---
id: 0090
title: The reader's belief drives both aim reads and betting, each behind its own switch
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

A belief (0089) is worth something only if a decision uses it. Today a read's best response plays
against an average hole card, and the betting rider's odds are keyed on its own hand and the Posture
lead. Put to Trey: drive aim reads, betting, or both.

Trey first answered "Aim reads only", then asked for the question again and chose the
recommendation.

## Decision

Trey: "Both, switchable".

- `reading.aim = "belief"`: a read plays its best response against opponents sampled from the belief.
  This is 0087's "revenge by aiming better on the joust wheel" channel.
- `reading.betting = "belief"`: the betting rider's odds average its paired odds (this hand against
  that one, from the same calibration run) over the belief.
- Both are off by default. The report runs each alone and both together, so the information's value
  splits into what it buys on the dial and what it buys at the bet.

## Consequences

- GAME_SPEC is unchanged; the baseline report does not move.
