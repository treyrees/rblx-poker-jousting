---
id: 0092
title: The bar's information is reported as 0087's table plus a reader, with bits per cue
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

0087 recorded the health half of the Posture bar's balance. Put to Trey: how to measure the
information half against it. The options were 0087's table re-run with a reader, two win-rate swings
per skill, or a per-cue ablation.

## Decision

Trey chose the recommended option: "0087's table, plus a reader".

- Re-run 0087's baseline (Pass 1 lead against win rate; after the flop, the cards' swing against the
  lead's; a lead of 12+ after two passes; skilled vs novice) with reading off, aim reads, betting
  reads and both, at several read skills.
- Headline: the win rate a reader gains over an otherwise identical non-reader, next to the swing the
  Posture lead gives.
- Alongside: the bits a reader learns per pass and per cue, so a cue's content shows even where no
  decision can use it, plus Yield rate and units per hand.

## Consequences

- `lune run tools/sim.luau --report info`; results in docs/sim/RESULTS.md, *What the bar's information
  is worth*.
