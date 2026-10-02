---
id: 0070
title: ♥ Posture is a buffer when aimed and a heal after every contact; everyone has 80 Posture
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
- **Everyone starts at 80 Posture.** As first recorded, ♥ also raised max Posture so a rider could
  heal above 80. The sim showed that could never happen: a heal is a share of what you just lost,
  so you never climb above where you were. Revised Oct 2, before merge: Trey, "i imagined the
  'active' component (aim at heart) of heart being pre-contact posture and the passive component
  being posture heal after contact. is that simple and clean and intuitive? feels like it to me.
  also with posture going back up or being bigger than it should otherwise be - that should be
  easy to hide." So ♥ has no max-health part: **80 is everyone's start and ceiling.**
- **Aimed:** health before contact, a buffer that absorbs that contact's damage first. (0038's ♥
  lean already acted at contact; this restates it as a buffer.)

## Consequences

- §4 *The four stats* and *Tracks and showdown* are rewritten. 0038's "max Posture uses unleaned
  ♥ points" lapses: max Posture no longer depends on ♥.
- The heal share and the buffer per leaned point are sim values (§11). The ♥ Posture-per-point rate
  is gone.
- Contact order, confirmed by Trey on Oct 1: armor, then Battered's +x%, then the ♥ buffer, then
  Posture damage; after contact the heal, then a new Battered. On Passes 1–3 a rider at 0 is
  unhorsed before the heal: "Unhorsed first".
