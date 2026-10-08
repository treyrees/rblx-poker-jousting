---
id: 0094
title: The sim's reader also reads the opponent's bets
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

Trey asked for the full set of information available to the opposite rider. Listed against GAME_SPEC
(§2, §3 *Public vs hidden*, §7), the biggest public cue the reader skipped was the opponent's bets:
each Stay, Raise and Yield. The betting rider raises only on odds of 60% or better, so a raise says a
lot about the hand. Trey: "add it".

## Decision

- The reader updates its belief on each of the opponent's betting actions. It assumes the opponent
  bets as the assumed profile does: the betting rider on its own odds and the public Posture lead,
  or the script's strength with its noise. It allows a small chance (`reading.betFloor`) that a bet
  broke that script.

## Consequences

- A new cue, `bets`, in the reading model and its report. It is a sim decision: GAME_SPEC already
  has bets public (§2).
