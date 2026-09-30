---
id: 0055
title: Twin Favor stops a trick's hit too
date: 2026-09-30
decided-by: trey (chat, open-questions session, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

0053 rewrote QQ Twin Favor as "once per hand, the first time your Posture would fall to 0 or
below, it is 20 instead". Nothing in the wording exempts a trick's hit, but §6 builds an unleashed
trick above the opponent to unhorse on its pass (pillar 3). The sim modelled both readings as
`switches.twinFavorVsTrick` (SANITY_CHECK C1).

A targeted count, 100k hands with seat 1 dealt QQ (average riders, seed 20260930): a trick's hit
is what first takes QQ to 0 or below in about 7.5k hands. After it, QQ goes on to win 1.7% vs
17.9% on the flop, 8.8% vs 16.6% on the turn and 0% vs 4.2% on the river (trick overrides vs
negates). A trick fired at QQ wins 96.3% vs 91.3%. In random deals this arises in about 0.04% of
hands.

## Decision

Trey: "Negates. Respects the rules of our game and is a powerful niche".

- Twin Favor stops the first fall to 0 or below whatever causes it, a trick's hit included. The
  trick is spent as usual and QQ rides on at 20.

## Consequences

- §5 Twin Favor row says so.
- `switches.twinFavorVsTrick = negates`, already the sim default.
