---
id: 0070
title: ♥ Posture is health: a buffer when aimed, a heal after every contact, and everyone starts at 80
date: 2026-09-30
decided-by: trey (chat, stats and broadway design pass, 2026-09-30 to 2026-10-01)
supersedes: []
superseded-by: null
---

## Context

0067: "posture increases health, aiming gives health before contact, but heals after contact
always." Under 0010, starting Posture grew with ♥, so the bar at Pass 1 showed a rider's exact ♥
points, against pillar 4.

## Decision

Trey chose:

- **The heal is a share of the damage taken** on that contact, growing with ♥: "Share of damage
  taken".
- **Everyone starts at 80 Posture.** ♥ raises max Posture, so a rider can heal above 80, but it
  doesn't raise the start. Your ♥ shows only once you heal.
- **Aimed:** health before contact, a buffer that absorbs that contact's damage first. (0038's ♥
  lean already acted at contact; this restates it as a buffer.)

## Consequences

- §4 *The four stats* and *Tracks and showdown* are rewritten. Max Posture still uses unleaned ♥
  points (0038).
- The heal share and the buffer per leaned point are sim values (§11).
- Contact order, confirmed by Trey on Oct 1: armor, then Battered's +x%, then the ♥ buffer, then
  Posture damage; after contact the heal, then a new Battered. On Passes 1–3 a rider at 0 is
  unhorsed before the heal: "Unhorsed first".
