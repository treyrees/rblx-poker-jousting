---
id: 0101
title: The cue log is one JSON record per hand, to Output and, in a live server, a DataStore
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

0097 asks the slice to log cues per hand so playtests can be compared with the sim's readers
(docs/sim/RESULTS.md, *What the bar's information is worth*). Put to Trey: JSON to Output plus a
DataStore in a live server; JSON to Output only; or a file exported from Studio.

## Decision

Each hand writes one JSON record: the deal, the colors, and per pass each rider's aim commits
with their times, first exit from Neutral, hold, the tier landed, the hit, the heal, Battered and
the clean block, then every bet with its timing, and the finish. Field names follow the reader's
cue names (§7). In Studio the record prints to Output on one line; in a published place it is also
written to a DataStore keyed by the hand id.

## Consequences

- The format is in `src/server/CueLog.luau`, versioned (`v`), so readers can tell formats apart.
