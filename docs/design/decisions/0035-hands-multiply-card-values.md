---
id: 0035
title: Poker hands multiply the points of the cards that make them
date: 2026-09-29
decided-by: trey (chat, card values session, 2026-09-29)
supersedes: []
superseded-by: null
---

## Context

With stats as a plain sum of card points (0034), a deal test of random river hands put every
numeric category at about ×1.2 on the loaded stat: pairs, two pair and trips no longer ordered
above high card. The session offered no bonus for pairing, a multiplier on the made cards, or a
flat bonus per category.

## Decision

Trey: "b, so we can take the 'hands' found in poker and multiply accordingly."

- The cards that make a pair, two pair or trips multiply their points. Starting values: pair
  ×2, two pair ×2, trips ×3.
- Each card keeps its own hole or board weight: a board pair is multiplied for both riders at
  board weight, and a hole card that pairs the board mixes the two.

## Consequences

- In the session's deal test the categories order on average: high card ×1.22, pair ×1.27, two
  pair ×1.33, trips ×1.35 on the loaded stat. Ordering is on average, not guaranteed: a high
  suited hand can out-load a low pair. The sim checks it (§11).
- A held trick rides as its sub-hand (0024), so its sub-hand's multiplier applies: a full house
  rides as trips.
- §4 gains *Poker hands multiply*; the multipliers join §11.
