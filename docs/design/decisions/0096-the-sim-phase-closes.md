---
id: 0096
title: The sim phase closes; what the sim backs is settled for v1, the rest waits on a playtest
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

Six rows of §1's Status table read "Proposed, needs sim". The headless sim (§11) now meets every
target it was given (docs/sim/RESULTS.md, *Headline metrics against the targets*, 100k-hand runs):

- **Card values.** Suits come out even: a hole card of each suit wins 48.0–49.9%. The better river
  category wins 77.3 / 91.4 / 95.2% at a gap of 1 / 2 / 3. The numeric gap is ×1.09–1.23 after the
  lean, inside 0062's ×1.0–1.45. Board weight ¼ against ½ barely moves anything (gap 1 77.6 vs 77.3,
  skill flip 63.0 vs 64.7).
- **Contact and the showdown.** Knockouts: 0 / 1.5 / 9.0% on Passes 1–3. The skill flip is 64.7%,
  inside 55–65%. Every lever in the sweeps moves results smoothly.
- **Trick effects.** A trick above wins 97.7% unleashed and 100% answering or auto-fired (0064's
  95%). A higher trick beats a lower one 99.2%. Held straights win 95.0% against 91.4% not held
  (0073).
- **Board-made tricks** are rare (about 0.8% of hands). §6 already calls their ×1.5 and ×0.5
  placeholders.
- **The sim can't judge** the pass timeline (it has no clock; §11 already asks a playtest whether
  8 s is enough), or tuning values that depend on how players play.

Put to Trey as one recommendation for all six rows, or row by row. Trey: "Take all six".

## Decision

- **Settled for v1, numbers tunable:** card values, board weight and hand multipliers (§4);
  contact resolution, Posture and the showdown knockdown (§4); trick effects on the unleash pass
  (§6). Board weight stays ½.
- **Settled in shape; arena multipliers are placeholders:** board-made tricks (§6).
- **Proposed, needs playtest:** the pass timeline (§8).
- **Starting values, tuned in playtest:** the §11 tuning parameters. The sim's values are where a
  build starts.

## Consequences

- §1's Status table has two new labels. AGENTS.md treats both, like "Proposed, needs sim", as
  config: built, not final.
- RESULTS.md's question on board weight (¼ vs ½) is answered: ½.
- No §11 value changes. Nothing in the sim changes.
