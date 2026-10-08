---
id: 0087
title: The Posture bar's main value is information; its health lead is meaningful but not decisive
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

With the betting rider in the sim (PR #17), a rider that Yields on its odds ended 55% of hands with
a Yield, mostly after the flop: the rider behind on public Posture folds to a raise. The Yield
between passes has been in §2 since 0005; the sim's riders had simply never used it.

Trey's concern: "If the value the poker side of the game brings goes much more out the window as
soon as one person's posture is lower than the other, I think that's unhealthy ... I want to make
sure that the first pass results in interesting information that both players can play around,
while rewarding the appropriate results of the first pass (higher numbers and better play deserve
more damage!). But not trivializing the poker of it all after the flop." He set aside a comeback
mechanic: "the poker of it all should stay solid", with the design space being "get revenge by
aiming better on the joust wheel next pass."

## Decision

Trey: "a simple way to explain this: our display of a posture/health bar is a little game design
sleight of hand that makes the players think they are progressing towards a victory when much of
the value is INFORMATION rather than raw HEALTH ADVANTAGE (although the health advantage will be
non trivial / meaningful so it doesnt feel pointless). that balance is the key to the games
success."

- The Posture bar's main value is the information it carries about the hand and the riders. Its
  health lead must be meaningful, never pointless, but not decisive: the cards still decide hands
  after the flop, and a rider behind can win back through better aim.

## Consequences

- §7 states it. It is a target the sim checks, as 0064's 95% is.
- Baseline (scratch count, 200k hands, average vs average, ridden out): after Pass 1 nearly every
  rider is within 11 half hearts, and a lead moves a coin flip to about 40/60. After the flop,
  within those leads, the cards swing the odds by 30–37 points (behind with good cards: 61%),
  against 25–30 for the lead. A lead of 12+ half hearts after two passes (8% of riders each side)
  wins 81–93% whatever the cards. Skilled vs novice, a skilled rider who loses Pass 1 still wins
  66–72%.
- The sim measures only the health half. Its riders read nothing, so the information half is worth
  zero to them; §11's reading model ("v2 of the sim") is the step that prices it.
- No rule changes.
