---
id: 0106
title: After contact the hit lands, then the heal, then the post-pass reveal
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§7: after each contact, show both aims, hold meters and the tiers landed. 0093: the ♥ heal shows
as its own beat after the hit. Neither says how long the beats run or in what order. Put to Trey:
hit, heal, then reveal, about 3 s; everything at once for 2 s; or hit, reveal, heal last.

## Decision

At contact both hits land on the bars at once, in half hearts. 0.6 s later the heal fills back as
its own beat, with a clean block's half heart the same way. 1.2 s after contact the post-pass
reveal opens over the cards for 2 s. Then the next bet.

## Consequences

- About 3.2 s between contact and the next bet. All three times are config
  (`src/shared/Slice.luau`).
