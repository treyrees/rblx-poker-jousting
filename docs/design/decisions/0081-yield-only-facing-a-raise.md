---
id: 0081
title: A rider can Yield only when facing a raise
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§2 *Betting rules* listed Yield as an action at every bet. A rider who Yields with no raise to
face gives up the Ante for nothing: Stay costs nothing and keeps their chance, and every unit past
the Ante is a call (0077). So an unraised Yield is never better than Stay in units; it only saves
time, and it can only happen by mistake. It came up in the prefold session because the cost of a
played hand is what the prefold price is weighed against.

The options put to Trey:

- **Facing a raise only:** "Yield appears only when there is a raise to answer ... Beginners can't
  throw away the Ante by accident, and 'every revealed card is ridden into' holds."
- **Any bet:** today's wording. A uniform action set, and an "I'm out" button that saves time but
  never units.

## Decision

Trey chose **facing a raise only**.

- Yield is offered only when there is a raise to answer. With no raise to face, the actions are
  Stay (check) and Raise.

## Consequences

- §2 *Betting rules* says so. Win condition 5 ("A rider who Yields forfeits the pot") and the
  between-passes rule are unchanged.
- The cheapest played hand is the Ante, and a rider can lose more than the Ante only by calling.
- Nothing in the sim's behavior changes: its riders already Yield only when facing a raise. A test
  holds the rule for the betting rider.
