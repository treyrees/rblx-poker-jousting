---
id: 0097
title: The first playable slice is one numeric hand against a scripted bot, with betting and cue logging
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

With the sim phase closed (0096), the next step is a playable build in Roblox: it answers what the
sim can't, such as whether an 8 s pass is long enough (§11) and whether players read §7's cues.
Put to Trey: who the opponent is, and what the first slice includes beyond one numeric hand on the
dial.

## Decision

- **Opponent: a scripted bot.** The sim's scripted rider (`sim/Hand.luau`, profiles in
  `sim/Config.luau`) is ported as the opponent.
- **In the slice:** one hand, four passes on §8's timeline, the standard dial (§3) with the Magnet
  wheel (§9), numeric contact resolution and the showdown knockdown (§4), the Posture bar with the
  ♥ heal as its own beat (0093), lance and shield colors (§7), **betting** (§2: Stay / Raise / Yield
  on the 5 s timer) and **cue logging** (aims, commit times, hits and bets per hand, so playtests
  can be compared with the sim's readers).
- **Not in the slice:** tricks and unleash (§6), the yard, prefold, carry and matchmaking (§2).

## Consequences

- AGENTS.md's *Next step* points at the slice.
- How a hand that makes a trick plays in a slice without tricks is a question for the slice's
  session to put to Trey.
