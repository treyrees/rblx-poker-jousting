---
id: 0080
title: A prefold costs units and a short delay
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§11 asked: "Prefold cost: what does prefolding in the yard cost (units, time, or both)?"

The options put to Trey:

- **Units and a short delay:** "A small unit payment into the purse, which the sim prices for 75%
  kept, plus a short wait before the new hand is dealt, which a playtest sets. The delay slows
  serial folding without draining currency; the units are what the purse needs. Caveat: if the
  queue is slow anyway, the delay costs nothing."
- **Units only:** fully priced by the sim, legible, and feeds the purse. A rider with a big balance
  can fold as much as they like.
- **Time only:** no currency changes hands, so there is no purse and nothing gambling-shaped. The
  sim can't price it, and a rider who doesn't mind waiting folds freely.

## Decision

Trey chose **units and a short delay**.

- A prefold costs a unit price, which rides as carry (0078) and is set to hold the kept share
  (0079), and a short delay before the new hand is dealt.

## Consequences

- §2 *The yard* says so. §11's prefold question closes; its parameter table gains the prefold price
  (set by the sim; starting value 0.40 units, `sim.prefoldPrice`) and the prefold delay (set by a
  playtest).
- The sim prices the units only. It has no model of time, so the delay adds to the price players
  feel by an amount the sim can't measure; how long a delay players will tolerate is a playtest
  question.
