---
id: 0034
title: Every revealed card adds its rank value to its suit's stat; board cards count for less
date: 2026-09-29
decided-by: trey (chat, card values session, 2026-09-29)
supersedes: []
superseded-by: null
---

## Context

Trey: "i also want to design the numeric values of cards in terms of numeric stat gain to the
players, which is strong/direct for a players hole cards and halved each for community cards.
example: 8 of clubs means this much raw damage, jack of spades means this much armor, etc. that
way we can have numbers to add to/scale"

§4 gave stats through a Power curve by hand category, split among the made cards' suits (absent
suits 15%), as `S_suit = 20 + P · share`. Only made cards counted. The session asked whether
per-card values should replace that model, layer on it, or feed it; which cards count; the rank
curve; and whether each suit gets its own table or one table converts per stat.

## Decision

- The example's suit: Trey: "youre right. i should have said 'jack of diamonds means this much
  armor'." The four stats stay as 0010 has them.
- Replace. Trey: "no need to invest in current artifacts. redesign cleanly from the top". The
  Power curve, the suit split and the absent-suit floor are removed.
- Every revealed card counts. Trey: "my mental model is every revealed card. perhaps we skew
  things more or less towards hole cards; probably more." Hole cards count in full, board cards
  at a board weight that starts at half and that the sim tries lower. Both riders get the
  board's points.
- Rank curve: compressed linear, 2 = 1 point up to A = 3 (`1 + (r − 2) / 6`). The target from
  §4 stays: about ×1.0 to ×1.45 on a hit across the numeric range, now read as the gap between
  the two riders.
- Units: one table of card points, and one rate per stat that turns points into its effect.
  `S_suit = 20 + points`, base 20 the cardless floor. ♣ keeps scaling hits by `S_♣ / 20`, so each
  ♣ point is +5% on a hit; the ♥, ♦ and ♠ rates are sim values.

## Consequences

- §4 *Power by hand category* and *Suit split* are replaced by *Card values*; *Stat value* is
  rewritten. §1 Status and the §11 parameter table follow; the absent-suit floor row is removed.
- Kickers now add points. They still break exact ties at showdown (§2).
- The board raises both riders alike, so the gap between riders comes from hole cards and hand
  multipliers (0035).
- A pocket pair is always two suits, while suited hole cards stack one stat. In the session's
  deal test, A♣K♣ loaded ♣ about as much as AA. This fits pillar 5 and 0011's "numeric play
  teaches the tricks"; the sim watches it against pillar 2.
- §10's favorite-card buff still names Power and the suit split. It is v2 and left for Trey.
