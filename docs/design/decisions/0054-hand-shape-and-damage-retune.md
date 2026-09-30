---
id: 0054
title: Posture 80, flat early street multipliers, and no last-pass bonus
date: 2026-09-30
decided-by: trey (chat, showdown review session, 2026-09-30)
supersedes: [0051]
superseded-by: null
---

## Context

Trey set the target as the shape of a hand, not the share of showdowns: "a typical game is five
community cards", with "Pass 1 0 cards, Pass 2 flop, pass 3 turn, pass 4 river" and no pass after
the river, so "most games end on the river, but some on the turn, and some rarer still on the
flop." Targets: "Turn about 10-15%, flop around 3-5%". Balance: the skill flip (a skilled rider
beating a novice with the worse numeric hand) "55-65% is appropriate."

The sim found the flop target reachable only if Pass 2 hits harder than Pass 3. Offered (a) a flop
share of about 1.5–2% with the build toward the river kept, (b) Pass 2 above Pass 3, or (c) a new
mechanic for flop endings, Trey chose "a".

0051's last-pass bonus existed "so more hands end with a real unhorse on the river". Under 0053 no
one is unhorsed on Pass 4's contact, so it only tilted the balance toward skill.

## Decision

Trey: "yes to 2 and 3", on these §11 values and on the trick cost below.

- Posture start: 80.
- Street multipliers: 1.0 / 1.0 / 1.0 / 1.25.
- The last-pass bonus is removed (supersedes 0051).
- The showdown hand bonus stays 20 per step.
- Unleashed tricks above the opponent winning about 96%, down from 99%, is accepted for now.

## Consequences

- §2 *Sequence*, the §4 sanity checks, the §4 charge note and the §11 parameter table updated.
- The sim, 100k hands per run (seed 20260930, the flip at `--p1 skilled --p2 novice --seed
  20260931`), with 0053: flop 1.6%, turn 11.4%, river 87%; gap 1 73.8%; flip 60.4%; unleashed
  tricks above 95.8%, auto-fired tricks above 99.7%. Before 0053 and this: flop 0.7%, turn 3.1%;
  gap 1 74.2%; flip 56.8%; unleashed 99.3%, auto-fired 93.7%.
- The trick cost comes from more damage before the river: a rider who unleashes on the turn can be
  lanced down on that contact. If it needs to come back, the fix belongs to the tricks, not to
  these numbers.
- The trick hits and wards (sim values) were sized at Posture 100 and Pass 2 ×0.75, so they still
  clear their §6 targets at 80 and ×1.0.
- The sim's riders never Yield, so every share here is before betting.
