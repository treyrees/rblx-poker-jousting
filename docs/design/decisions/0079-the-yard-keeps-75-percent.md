---
id: 0079
title: The yard keeps 75% of dealt hands; the prefold price is set to hold it
date: 2026-10-08
decided-by: trey (chat, prefold cost session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

Hold'em keeps VPIP healthy with dead money: the blinds are forced, rotate and sit in the pot, so a
marginal hand has odds to play. The yard (§2) has none. Both riders chose to keep their hands, so
the kept field is top-heavy, and a modest hand is measured against that field, not the deck. If
prefolding is cheap, the yard tightens until premiums meet premiums, and pillar 2 ("Play every
hand") dies in the yard before any joust. The prefold price is the one lever against that.

Trey's framing: "The equivalent stat to VPIP must be active enough to keep the game interesting,
while not forcing bad hands into a lose-lose decision compared to getting raked by the house for not
playing. A healthy game has a healthy distribution of prefolds, modest hands winning some upsets
through all the game's mechanisms, and strong hands flexing big power fantasy and big wins."

The options put to Trey, for the share of dealt hands riders keep:

- **75%:** heads-up hold'em territory. Prefolding is a real choice about one deal in four, the
  folded quarter is the hands that lose most, and modest hands are still the bottom third of the
  field rather than its floor. Roughly every offsuit hand below Jack-high folds, plus K2o, K3o and
  32s.
- **90%:** only offsuit trash folds (32o–74o, 82o–93o), and you meet almost the whole deck.
- **60%:** most offsuit hands without an Ace, a King or connectors fold.
- **See the price curve first.**

## Decision

Trey chose **75%**.

- The prefold price is set so riders keep about 75% of the hands they are dealt. The sim finds the
  price.

## Consequences

- §2 *The yard* says so, and §11's parameter table gains the kept share (75%) and the prefold
  price ("set by the sim to hold the kept share"). The sim has `spec.keptShare = 0.75` and a yard
  report (`--report yard`) that finds the equilibrium: each starting hand's EV against the kept
  field, a fold's value with the price paid again on every redeal, and the price at which the
  marginal hand is indifferent.
- What 75% looks like (2M hands per betting reading; docs/sim/RESULTS.md, *The yard*):
  - **Free folding unravels the yard.** At a price of 0, every betting reading keeps under 5% of
    hands: each fold tightens the field, and the next-worst hand falls below even.
  - **The price for 75% scales with what a weak hand loses by playing**, and so with pot sizes.
    Under carry (0078) it is 0.18 units with today's script betting (pots mostly the Ante), 0.30 to
    0.40 with the betting rider Yielding at .35 or .25, and 0.73 with a rider that never Yields.
    The starting value is 0.40 (`sim.prefoldPrice`).
  - **Diversity holds.** Kept hands are 7.8% pairs, 29.4% suited and 62.8% offsuit (5.9 / 23.5 /
    70.6% of all deals); 139 of 169 classes are kept at least in part. Both river hands are modest
    (high card or a pair) in 42% of kept matches (43% with no prefolds), and 81% of kept matches are
    between numeric hands (82%).
- What the sim can't say: whether folding at that price feels fair, and whether players will see the
  odds the way the sim's riders do. A playtest decides both.
