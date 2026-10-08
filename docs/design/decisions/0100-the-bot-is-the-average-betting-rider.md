---
id: 0100
title: The slice's bot is the average rider, betting as the betting rider, with its profile shown
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

0097 makes the opponent the sim's scripted rider, with its profile and its betting left to ask.
Under the sim's script a rider never Yields, which would leave Yield untested in a playtest. Put
to Trey: average with the betting rider, shown; average with the script, shown; or skilled with
the betting rider, hidden.

## Decision

The bot rides the `average` profile in `sim/Config.luau`. It bets as the betting rider
(`switches.betting = "bands"`, `sim/Odds.luau`): it raises and Yields on its odds. Its nameplate
names the profile ("House rider: Average"), like the tourney's labeled house riders (§9).

## Consequences

- The odds table is calibrated when the server starts; until it is ready the bot bets with the
  script. The cue log marks which bets used the odds.
- The profile is one config value in `src/shared/Slice.luau`; the other profiles stay selectable.
