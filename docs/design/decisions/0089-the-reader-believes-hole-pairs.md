---
id: 0089
title: The sim's reader keeps a belief over the opponent's hole pair, updated by every card cue
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§11 *Sim plan* step 4: "v2 of the sim: a reading model, so color and held-trick tells get a value."
0087 says the Posture bar's main value is information, but the sim's riders read nothing: a read
estimates the opponent as the board plus an average hole card, and the betting rider bets on its own
odds. So every §7 cue was worth zero in the sim.

Put to Trey: what a reader models, and from which cues. The options were a belief over hole pairs
updated by every card cue, the two hard filters first (color and hit size), or a coarser belief over
stat loads.

## Decision

Trey chose the recommended option: "Hole pairs, all card cues".

- A reader keeps a belief over the opponent's possible hole pairs. It updates it from color, stance,
  the timing of the first exit from Neutral (which carries the trick-to-design lock), hit size both
  ways with clean blocks included, the ♥ heal (0093) and an announced unleash.
- The likelihoods come from replaying the sim's own rider script for each pair, with the opponent
  assumed to ride as a stated profile.

## Consequences

- `sim/Read.luau`; configured under `reading` in `sim/Config.luau`, off by default.
- The hold meter and the first exit carry card information only through a trick played to its
  design, because the script sets hold by the rider, not the hand. The sim reports that rather than
  inventing a link between hand strength and hold.
- A sim decision, not a rule: GAME_SPEC is unchanged.
