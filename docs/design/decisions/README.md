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

Next free id: **0007**.
