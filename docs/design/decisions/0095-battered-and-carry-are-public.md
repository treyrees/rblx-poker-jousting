---
id: 0095
title: Battered and each rider's carry are public
date: 2026-10-08
decided-by: trey (chat, reading-model session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

Listing what the opposite rider can see turned up two things GAME_SPEC didn't place in §3's *Public
vs hidden*: whether a rider is Battered (§4), and the carry each rider brings into the pot (§2, 0078),
which shows how much they prefolded in the yard. Trey: "i think they should!?"

## Decision

- Battered is public: both riders and spectators see that a rider is Battered.
- Each rider's carry is public: the pot shows what each rider brought in from the yard.

## Consequences

- §3 *Public vs hidden* lists both.
- The sim's reader already treated Battered as known. The one-hand sim doesn't model carry inside a
  match, so carry tells the reader nothing there; a reader that learns from the yard is future work.
