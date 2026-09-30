---
id: 0052
title: The hold floor is 0.25, so holding can beat a last-instant switch
date: 2026-09-30
decided-by: trey (chat, sim review session, Decision 2, 2026-09-30)
supersedes: []
superseded-by: null
---

## Context

§3 made strike power and Guard armor scale by `0.4 + 0.6 × h` and called the 0.4 floor a
placeholder. §11 asked whether it collapses half-holds toward last-instant flicks.

Aim is public, so a last-instant switch onto a held aim wins a CN row when the floor is above
Normal/Crit = 1/3. At 0.4 that holds for any hold, even a full one. The sim agreed (`--report
floor`, 100k hands per run): at 0.4, 73% of reads switch late rather than stay on the held aim, a
steady rider beats a fidgety one 63% of the time, and a pure holder beats an always-flicker 17%.

Trey was offered 0.4, 0.3, 0.25 and 0.2. Lower floors make holding stronger. They also lower how
often a skilled rider beats a novice while holding the worse hand: 67% at 0.4, 60% at 0.3, 57% at
0.25 and 54% at 0.2. The sim's only model of a good reader is a late switch, which a low floor
taxes, so that cost is likely overstated.

## Decision

Trey: "C!" (option C, a floor of 0.25).

- The hold multiplier is `0.25 + 0.75 × h`.
- At equal stats, a last-instant switch onto a CN row beats a hold of under two thirds of the
  run-up; a longer hold beats the switch.

## Consequences

- §3 *Held aim*, §4 *Contact resolution* and *Sanity checks*, the §6 straight meter note and the
  §11 parameter table use the new multiplier. The §11 open question on the hold floor is
  answered and removed.
- The §4 check "Pass 1 normal hit, high card, half hold" becomes 10 × 1.0 × 0.625 × 0.5 ≈ 3.1.
- `sim/Config.luau` sets `spec.holdFloor = 0.25`; `docs/sim/RESULTS.md` is rerun at it.
