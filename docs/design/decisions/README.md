# Decisions

The record of design calls Trey has made that change or clarify [GAME_SPEC](../GAME_SPEC.md). The
process is in [WORKFLOW.md](../WORKFLOW.md), *Recording decisions*.

One file per decision, `NNNN-kebab-title.md`, numbered from `0001`:

```markdown
---
id: 0001
title: <the decision, in one line>
date: YYYY-MM-DD
decided-by: trey (<where: PR link, chat, date>)
supersedes: []
superseded-by: null
---

## Context
## Decision
## Consequences
```

Add a row below in the same commit. Check the latest `main` for the next free id first.

| id | title | date |
|----|-------|------|
| [0001](0001-game-spec-is-canonical.md) | GAME_SPEC is the canonical design; the PDF is history | 2026-09-26 |
| [0002](0002-tricks-climb-a-ladder.md) | Tricks are trump cards on a ladder, not "not auto-wins" | 2026-09-26 |
| [0003](0003-suits-are-stats-and-axes.md) | Suits are stats and axes; the four stats themselves are open | 2026-09-26 |
| [0004](0004-learnability-and-spectacle.md) | Learnability and spectacle are named as important | 2026-09-26 |
| [0005](0005-betting-alternates-one-hand-matches.md) | Betting alternates from the button; a match stays one hand | 2026-09-26 |
| [0006](0006-the-yard-and-prefolding.md) | Hand selection happens in the yard; results are graded in units | 2026-09-26 |
| [0007](0007-standard-dial-six-outcomes.md) | The standard dial carries all six outcomes, in half-step resolution | 2026-09-26 |
| [0008](0008-dial-input-timing-and-tells.md) | Dial input, hold, aim lock and public tells are clarified | 2026-09-26 |
| [0009](0009-seat-renamed-posture.md) | Seat is renamed Posture | 2026-09-26 |
| [0010](0010-the-four-stats.md) | The four stats are ♥ Posture, ♦ Armor, ♣ raw damage and ♠ crits | 2026-09-26 |
| [0011](0011-stats-reprice-tricks-rewrite.md) | Stats change what rows are worth; tricks change which rows exist | 2026-09-26 |
| [0012](0012-all-stats-act-aim-leans.md) | All four stats act all the time; aim leans into the stats it points at | 2026-09-26 |
| [0013](0013-pillar-5-reworded.md) | Pillar 5 reads "Suits are stats" | 2026-09-26 |
| [0014](0014-showdown-knockdown.md) | Score is removed; hand strength forces a knockdown at showdown | 2026-09-26 |
| [0015](0015-spade-charge.md) | ♠ non-crits build a hidden charge that the next crit spends | 2026-09-26 |
| [0016](0016-stat-compass.md) | The stat compass puts the black suits side by side; the lean total is fixed | 2026-09-27 |
| [0017](0017-pillar-1-reworded.md) | Pillar 1 lets hand strength force the showdown knockdown | 2026-09-26 |

Next free id: **0018**.
