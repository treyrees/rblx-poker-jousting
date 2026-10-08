---
id: 0078
title: Prefold payments ride with the rider as carry, into their next match's pot
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

§11 asked what prefolding in the yard costs. The first part of that is where a prefold payment
goes. Trey's framing: "there must be the ability to fold preflop, with some cost that does the same
job as the blinds and rakes you passively."

The options put to Trey:

- **Purse:** the yard accumulates prefold payments, and the next match's winner collects them with
  the pot. This keeps currency in the players' economy and feeds the win side (big wins for strong
  hands and skilled riders) without raising the 13-unit loss cap. It is more gambling-shaped, so it
  is flagged for the Roblox policy question.
- **Sink:** the house takes it, like an entry fee. Simplest and least gambling-shaped; it drains the
  economy on every fold.
- **Split** between the two.

The yard math, shared with the options: with k the kept share, a sink fold really costs c/k (a
rider keeps paying until they keep a hand), and a purse fold costs c, but the purse pays winners
2c(1 − k)/k a match. At an equal price the two hold nearly the same kept share. The price sets the
kept share; the destination decides where the money goes. A purse doesn't favor marginal hands: they
win under half their matches, so on average it moves money from them to strong hands and skilled
riders.

Trey: "Purse works conceptually, but with many players in a lobby, what does 'next' mean, if not
just a lottery into who gets the purse? im with you conceptually, execution needs mapped to how
players actually queue and match, no fault you don't know details yet."

The routes then put to him:

- **Carry:** "Your own prefold payments ride with you into your next match's pot as dead money, and
  that match's winner takes both riders' carry. There is no 'next' to define and no lottery: every
  unit in a pot came from one of the two riders in it, as with hold'em's blinds. It works with any
  queue. It shows how often each rider folded, which is their habit, not their current hand."
- **Even slices:** the yard (one server) pools payments, and every match starting there takes the
  same small share of the pool.
- **Leave open** until the queue and matchmaking flow is designed.

## Decision

Trey chose **carry**.

- A prefold's units ride with the rider as their carry. The carry goes into the pot of the rider's
  next match, and that match's winner takes both riders' carry.
- The purse is the concept; carry is how it reaches a match.

## Consequences

- §2 *The yard* says so, and §2 *Betting rules* says the carry sits in the pot on top of the
  fixed limit's 1 to 13 units: it was paid in the yard. §1 Status gains a row for the prefold cost.
- §11's Roblox policy question gains carry: prefold money that a match's winner takes.
- **Carry needs about twice the price of a sink or a pooled purse to hold the same kept share.** A
  rider who folds puts the payment into their own next pot, and wins it back when they win that
  match, which on average is half the time. So a fold costs about c/2 instead of c, and only the
  opponent's carry is dead money a keeper can win. At 75% kept the sim puts carry's price at 0.40
  units, against 0.20 for the pooled purse and 0.19 for the sink (2M hands, betting rider at its
  profile bands; docs/sim/RESULTS.md, *The yard*).
- The more a rider carries, the more a fold is worth to them: the carry rides with their next hand,
  which wins half its matches on average, while the marginal hand wins about 45%. A rider carrying
  one fold's price (0.40) values the marginal hand about 0.02 units lower. The sim's yard prices a
  rider carrying nothing.
- The sim models carry at its average: every kept match's pot holds 2c(1 − k)/k of carry on top of
  the bets (`switches.prefold = "carry"`, `--report yard`). The pooled purse and the sink stay as
  readings to compare.
- A rider who leaves the yard keeps their carry for their next match (0085), and in a split each
  rider's carry rides on to their next match (0086).
