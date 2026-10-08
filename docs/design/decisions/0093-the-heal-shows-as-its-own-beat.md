---
id: 0093
title: The ♥ buffer nets into the hit; the ♥ heal after contact shows as its own beat
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

To model the hit-size cue, the sim needed to know what an opponent sees of ♥. §4 step 7 says the
heal "rounds up to a whole half heart so every heal shows", but §7's cue table didn't list it, and
GAME_SPEC didn't say whether the bar shows the heal apart from the hit or only the net change.

Trey: "Isn't there during-hit and post-hit healing? Net change for during-hit, separate beat for post
hit? Confirm this makes sense." Confirmed: the ♥ buffer (§4 *Stances*, contact step 6) acts at
contact, and the heal (step 7) comes after it. He chose to record it as a decision and add the heal
to §7's cue table.

## Decision

- The ♥ buffer nets into the hit: the bar shows one change at contact, the hit after armor, Battered
  and the buffer (a clean block's restore lands there too).
- The ♥ heal after contact shows as its own beat. Its size is a public cue: it suggests the rider's ♥
  card points, and it is ambiguous because every rider heals a base share and the heal rounds up to a
  half heart.

## Consequences

- §7 *What each read targets* gains a ♥ heal row; §4 step 7 says the heal shows as its own beat.
- The sim's reader updates on the heal as its own cue (`reading.heal = "beat"`); "net" is kept for
  comparison.
