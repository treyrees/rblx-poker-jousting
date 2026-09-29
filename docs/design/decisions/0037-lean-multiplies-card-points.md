---
id: 0037
title: Aim lean multiplies what your cards give a stat; a stat meter shows it as you rotate
date: 2026-09-29
decided-by: trey (chat, card values session, 2026-09-29)
supersedes: []
superseded-by: null
---

## Context

0012 and 0016 made aim lean into the stats it points at, with the buff size a sim value. With
per-card values (0034), Trey named the effect the design is after.

## Decision

Trey: "the bonus from directional suits/stats is like a multiplier towards what you have, so
good/high cards of a particular suit should be incentivized to aim that way. a dynamic visual
stat meter should show this clearly as the player rotates."

- A lean multiplies the card points of the stats it points at. A lean into a stat with no points
  adds nothing; high cards of a suit reward aiming at its home.
- A stat meter shows the rider their four stats with the current lean applied, live as they
  rotate.

## Consequences

- §4 *Stances* says the lean multiplies card points and gains *The stat meter*. The multiplier
  and the half-step share stay §11 sim values; the total lean is still the same at every aim
  (0016).
- The meter is the rider's own. §3 lists whether your cards back your aim's lean as hidden, so
  the opponent and spectators never see it (§7).
- Contact resolution reads the lean inside each stat value, not as a separate modifier.
