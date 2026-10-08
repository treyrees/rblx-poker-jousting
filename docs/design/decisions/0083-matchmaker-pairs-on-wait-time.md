---
id: 0083
title: The matchmaker pairs kept hands on wait time alone, blind to hole cards
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§2 *The yard*: "Matchmaking happens behind the scenes, among riders who kept their hands." It
didn't say what the matchmaker pairs riders on. Trey's framing of the economy asked "what happens
when you don't fold preflop, and why bother matchmaking that player-hand."

The options put to Trey:

- **Wait time only:** "With one stake, it pairs the riders who have waited longest, and nothing
  else. It never sees hole cards: matching on hand strength would be a hidden tell (pillar 4),
  because who you get matched with would say something about your cards."
- **Wait time and a skill rating**, still blind to the cards: closer jousts and a gentler start
  for beginners; longer waits in a thin yard, and the rating needs a design of its own.
- **Leave open** for the queue design.

## Decision

Trey chose **wait time only**.

- The matchmaker pairs riders who kept their hands by how long they have waited, and on nothing
  else. It never sees hole cards.

## Consequences

- §2 *The yard* says so. With one stake (0082) there is nothing else to match on.
- Anyone who keeps a hand meets the kept field as it is: the yard's kept share (0079) is the only
  thing that shapes who meets whom.
- It was offered as §2 text, not as an invariant; AGENTS.md's invariants are Trey's to write.
- Nothing in the sim changes: its yard model pairs kept hands at random, which is what wait time
  alone gives when hands don't affect waiting.
