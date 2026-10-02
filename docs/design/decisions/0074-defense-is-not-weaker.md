---
id: 0074
title: Defense isn't weaker than offense; the four suits are roughly even in value
date: 2026-10-02
decided-by: trey (chat, stats and broadway design pass, 2026-10-02)
supersedes: []
superseded-by: null
---

## Context

At the first starting values for 0067–0070, a hole card's win rate by suit was ♣ 52.6%, ♠ 52.0%,
♥ 47.4% and ♦ 46.3% (200k hands, average riders). Turn and flop endings were 9.8% and 1.0%, just
under 0054's 10–15% and about 1.5–2%.

## Decision

Trey: "tune battered up a bit but made up ranged arent too important. defense shouldnt be weaker."

- **Defense isn't weaker:** ♥ and ♦ cards are worth about as much as ♣ and ♠ cards. The sim's
  values are tuned to that, and it reports the suits' values.
- **0054's turn and flop ranges are guides, not targets.**
- Battered goes up from its first starting value.

## Consequences

- Sim values only; GAME_SPEC is unchanged. The values that moved are in RESULTS.md: Battered 0.4,
  a ♥ buffer of 1.5 per leaned point, a heal of 10% plus 2% per ♥ point, +1.5 armor per ♦ card
  point on top of 0057's value conversion, and thin and sliver armor at 0.5 and 0.2 of the Guard's.
- Thicker defense raises what a trick's hit must clear, so the straight meter's base grows to keep
  a full wheel unhorsing from full Posture (§6).
