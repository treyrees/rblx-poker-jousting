# Poker Jousting — Current-State Design

Sep 22, 2026 · @Trey Rees

> The canonical design for Poker Jousting. It began as a transcription of the design PDF of the
> same name; since Sep 26, 2026 this doc is the source and the PDF is history. Top-level sections
> are numbered so they can be cited ("GAME_SPEC §3"). The design changes only when Trey changes
> it, and each change is recorded in [decisions/](decisions/README.md) (see
> [WORKFLOW.md](WORKFLOW.md)).

## 1. Overview

Poker Jousting is a Roblox 1v1 game where a Texas hold'em hand is played as four jousting
passes. Cards buff the riders; a radial aim dial decides who lands the hit. Every bet is a
commitment to ride into the next card.

### Design pillars

- **Poker structure, physical resolution.** Hole cards, board, streets and betting are
  hold'em. Outcomes come from the joust. Hand strength acts through the riders' stats and, at
  showdown, forces the knockdown alongside Posture. A bare card comparison only breaks exact
  ties.
- **Play every hand.** Numeric hands (high card through trips) are modest stat edges. Skill
  on the dial decides most numeric matchups, so a bad hand is a handicap, not a fold.
- **Tricks are trump cards.** Straight and above are tricks, ranked on a trick ladder. As the
  ladder climbs, tricks bring unique mechanics and/or explosively scaled numbers. A rider above
  the opponent on the ladder who unleashes their trick, rather than holding it, has a virtually
  guaranteed win condition.
- **Ambiguous tells.** The dial and the rider leak partial information about hole cards.
  Nothing leaks the exact hand.
- **Suits are stats.** Each suit is a stat, and all four act all the time. Aim leans into the
  stats it points at. Aim is public; whether your cards back the lean is the secret.

Also important: **learnability** (for example, betting is beginner-ignorable, §2) and
**spectacle** (for example, the setup/counter animation system, §8).

### Status

| Area | Section | State |
| --- | --- | --- |
| Hand structure: deck, deal, streets, win conditions | §2 | Settled |
| The yard: deal, prefold, matchmaking | §2 | Settled in shape |
| Preflop redraw for a price | §11 | Open |
| Betting | §2 | Settled |
| Standard dial: layout, outcome table, sectors, Neutral, held aim, aim lock | §3 | Settled for v1, numbers tunable |
| Suits as stats; all four act, aim leans into the stats it points at | §4 | Settled |
| Aim lean: the stat compass; a lean multiplies card points | §4 | Settled for v1, numbers tunable |
| Stat meter: your own stats, live as you rotate | §4 | Settled in shape |
| The four stats: what they are and what they do | §4 | Settled in shape |
| Card values, board weight and hand multipliers | §4 | Proposed, needs sim |
| Contact resolution, Posture and the showdown knockdown | §4 | Proposed, needs sim |
| Broadway effects | §5 | Proposed, needs sim |
| Tricks: ladder, ownership, held and unleash rules, trick vs trick | §6 | Settled in shape |
| Trick effects on the unleash pass | §6 | Proposed, needs sim |
| Board-made tricks | §6 | Proposed, needs sim |
| Information design | §7 | Settled |
| Pass timeline | §8 | Proposed, needs sim |
| Presentation: arena reveals, setup/counter animation | §8 | Settled in shape |
| What we take from rblx-joust-tourney | §9 | Settled |
| Classes and alternate dials | §10 | Deferred to v2 |
| Economy: currency, wager limits, monetization | §11 | Open |
| Tuning parameters | §11 | Proposed, needs sim |

## 2. Hand structure and betting

One hand is one match: four bets and four passes. A match's result is the units won or lost. Cards reveal mid-charge, so each bet is
made before the card it rides into, as in hold'em where you call and then see the card.

### The yard

Riders wait in the yard, circling. Each rider is dealt hole cards in the yard, before being
matched.

- A rider who doesn't want their hand prefolds it, for a cost, and is dealt a new one.
- A rider who keeps their hand steps forward and meets their match. Matchmaking happens behind
  the scenes, among riders who kept their hands. Then the Ante and Bet 1.
- Prefolding is the preflop fold. Hand selection happens in the yard, so a match stays one hand.

### Deck and deal

- One standard 52-card deck per hand, no jokers.
- Each rider gets 2 private hole cards.
- 5 community cards: flop (3), turn (1), river (1).
- Hand strength is always the best 5 of the rider's 7 available cards (standard hold'em
  evaluation).

### Sequence

| Step | What happens | Stats used at contact |
| --- | --- | --- |
| Ante | Both riders post 1 unit | n/a |
| Bet 1 | Stay / Raise / Yield on hole cards only | n/a |
| Pass 1 | Charge; flop reveals mid-charge | Hole + flop |
| Bet 2 | Stay / Raise / Yield | n/a |
| Pass 2 | Charge; turn reveals mid-charge | Hole + flop + turn |
| Bet 3 | Stay / Raise / Yield | n/a |
| Pass 3 | Charge; river reveals mid-charge | All 7 cards |
| Bet 4 | Stay / Raise / Yield | n/a |
| Pass 4 (showdown) | Charge with full information; unused tricks auto-fire | All 7 cards |

Street multipliers apply to all Posture damage in that pass: Pass 1 = 0.5,
Pass 2 = 0.75, Pass 3 = 1.0, Pass 4 = 1.25. Early passes rarely unhorse; the hand builds
toward the river.

### Win conditions

1. A rider whose Posture reaches 0 is unhorsed. The other rider wins the pot immediately.
2. If both riders are unhorsed on the same contact, the rider with more Posture before the
   pass wins; if equal, split.
3. If no one is unhorsed after Pass 4, a knockdown is forced at showdown. Hand strength
   forces it, and Posture still counts (§4).
4. Showdown tie: compare poker hands with kickers. Still tied: split the pot.
5. A rider who Yields forfeits the pot.

### Betting rules (v1)

- Fixed limit. Raise size is 1 unit before Passes 1 and 2, 2 units before Passes 3 and 4.
- Betting alternates, as in hold'em, until a bet is agreed. Then the pass begins and the
  joust is simultaneous.
- The rider on the button acts first in every betting round. The button passes each hand.
- Actions: Stay (check when there is no raise to face, call when there is), Raise, Yield.
- One re-raise cap per betting round.
- Each action has a 5 s timer. Timeout defaults to Stay. This keeps the game
  beginner-ignorable: a player who never touches betting still plays every hand.
- Players can only Yield between passes. Every revealed card is ridden into.

## 3. The standard dial (v1)

Every rider uses the same dial in v1. One input, the aim, sets offense and defense
together: where you strike decides where you are exposed and where your Guard sits.

### Layout

- 8 directions: 4 cardinals (Up, Out, Down, In, self-relative) and 4 diagonals between them.
- Aim resolves in half steps between directions: 16 aim positions. Sector widths are painted
  in the same half steps. The dial presents as snappy and granular with 8 labeled
  directions, not as 16 hard notches.
- Plus Neutral, the default state at the start of every pass.
- Aim snaps to aim positions. The needle may animate smoothly; the state is always one of
  the 16 aim positions or Neutral.
- The sweep runs in label order, Up → Up-Out → Out → Out-Down → Down → Down-In → In →
  In-Up, the same for both riders. A rider's screen may mirror the ring (for example so In
  faces the opponent); the sweep stays in label order.
- Your ring shows the opponent's sectors projected onto it, so your needle reads directly as
  the tier you would land.
- Input: a circular touch wheel (drag to aim, flick to spin past positions, tap the hub for
  Neutral). Port the Magnet wheel from rblx-joust-tourney, branch
  `claude/ring-spin-ui-feel-xpatk4`: `src/shared/WheelPhysics.luau`, with the Magnet preset
  in `Constants.WHEEL` (`src/shared/Constants.luau`).

### Outcome table

Each exchange pairs where your strike lands on the opponent's sectors with where theirs
lands on yours. All six combinations are possible.

| Combination | What it is | Share |
| --- | --- | --- |
| CN: one rider crits, the other lands Normal | The clean read | 37.5% |
| NB: one rider lands Normal, the other hits their Guard | The defensive read | 25% |
| CB: one rider crits and blocks the other's strike | The perfect read | 12.5% |
| NN: both land Normal | The plain trade | 12.5% |
| CC: both crit | Crossed lances | 6.25% |
| BB: both hit a Guard | The clash | 6.25% |

Shares are the baseline when both riders aim at random, and each one-sided share splits
evenly between the riders. One-sided rows (CN, NB, CB) are 75% and mutual rows 25%. In real
time aim is public and the last mover picks the row, so the shares price the stats and hold
(below) prices the last move.

### Sectors (derived from aim, automatic)

Positions count in half steps from your aim, along the sweep.

| Positions from your aim | Sector | A hit there resolves as |
| --- | --- | --- |
| 0–4 (your aim through 2 directions on) | Exposure | Crit |
| 5–7 | Ordinary | Normal |
| 8 (opposite your aim) | Guard | Block: a hit into your Guard armor (§4) |
| 9 | Ordinary | Normal |
| 10–12 | Guard | Block |
| 13–15 | Ordinary | Normal |

In all: exposure 2.5 directions, Guard 2 directions in two parts, ordinary 3.5 directions.

**Rows by offset.** Offset is your aim position minus the opponent's, in half steps along
the sweep.

| Offset | Your strike lands | Theirs lands |
| --- | --- | --- |
| 0 (same aim) | Crit | Crit |
| 1–3 | Crit | Normal |
| 4 (a right angle ahead) | Crit | Block |
| 5–6 | Normal | Block |
| 7 | Normal | Normal |
| 8 (opposite) | Block | Block |
| 9 | Normal | Normal |
| 10–11 | Block | Normal |
| 12 | Block | Crit |
| 13–15 | Normal | Crit |

The layout is chiral: ahead of the opponent's aim along the sweep is good for you, behind is
good for them. Rows grade by distance: crits close, the perfect read at a right angle, the
defensive read beyond it, the clash opposite.

A CB row lands a crit and blocks at once. Guard armor scales with hold (§4), so a CB taken
by a last-instant switch blocks weakly and plays about like a CN; a CB read early and held
is the perfect read.

### Neutral

- Neutral aim at contact: a weak center strike (base 4), cannot crit.
- Neutral has no Guard. Every incoming hit on a neutral rider resolves as Normal.
- Neutral is where the run-up starts, so the first frame leaks nothing. When a rider first
  leaves Neutral is itself a tell.
- Neutral leans into no stat.

### Held aim (the windup)

- Hold fraction h = the fraction of the run-up, from the start of the charge to aim lock,
  that the final aim position was held (0 to 1). Changing aim position resets h for the new
  position. How slow-motion time counts is open (§11).
- Strike power and Guard armor both scale by the hold multiplier: `0.4 + 0.6 × h`.
- The hold meter is public. Holding is the value bet; a late switch is the bluff, and it costs
  power. This is a price, not a lock: players commit by degrees, which keeps bluffing a dial
  instead of a yes/no.
- The 0.4 floor is a placeholder. Because aim is public, a last-instant switch onto a held
  aim wins the exchange when the floor is above what the holder deals back divided by what
  the switch deals: Normal/Crit = 1/3 on a CN row, lower on a CB row. Turbo Jousting's sim
  found a floor can collapse half-held aims toward last-instant flicks; the sim sweeps it
  (§11).

### Aim lock

Aim locks 0.3 s before contact. After lock, no input changes the outcome, so resolution is
server-side and the setup/counter animation can start. The lock doesn't remove latency: the
last inputs before it are blind to the opponent, and a rider with higher ping has to commit
about one ping earlier.

### Public vs hidden

| Public | Hidden |
| --- | --- |
| Aim position, and so all sectors | Hole cards |
| Aim timing: when each rider moved | Whether your cards back your aim's lean |
| Hold meter | Whether you hold a trick |
| Posture | Your hand's exact suit mix |
| Board cards and arena effects | True colors behind a jack |
| Lance and shield colors (see Information design) | |

A hit's size is public, so after contact it shows the attacker's stat on that hit. Whether
one hit can identify a hand's rank at display precision is open (§11).

## 4. Suits, stats and stances

Each suit is one stat: two offense and two defense. In each pair, one stat is raw and linear
and the other is circumstantial.

### The four stats

| | Raw, linear | Circumstantial |
| --- | --- | --- |
| Offense | ♣ Knockoff | ♠ Pierce |
| Defense | ♥ Sturdiness | ♦ Armor |

- **♥ Sturdiness is Posture.** Max and starting Posture grow with ♥. When a reveal raises ♥,
  you gain the difference. When a reveal lowers it, your max drops but your current Posture
  isn't taken away.
- **♦ Armor** is a flat reduction per hit, mapped onto your dial: thick on your Guard, thin on
  your ordinary positions, a sliver on your exposure. A Block is a hit into thick armor.
  Guard armor scales with hold. Its value depends on how damage arrives: it erases a grind
  of small hits and barely dents the crit that finds your exposure.
- **♣ Knockoff** is raw damage: it scales your hits linearly.
- **♠ Pierce** is the crit stat. It pierces armor on every hit and pays later, through
  crits: your non-crit hits build a hidden charge that your next crit spends (contact
  resolution, step 4).

### Stances

All four stats act all the time. Aim leans into the stats it points at: the stats your aim
points toward have more impact on the exchange. So an exchange depends on two things: the
distance between the two aims, which picks the row (§3), and each aim's absolute position,
which picks the stats it leans into.

**The stat compass.** Each stat has a home direction. The black suits sit next to each other
and so do the red suits, so a diagonal can lean all offense or all defense.

| Aim | Leans into | Reads as |
| --- | --- | --- |
| Up | ♣ Knockoff | Raw hit |
| Out | ♠ Pierce | Crit hunter |
| Down | ♥ Sturdiness | Posture |
| In | ♦ Armor | Armor |
| Up-Out | ♣ ♠ | All offense |
| Down-In | ♥ ♦ | All defense |
| Up-In | ♣ ♦ | Raw hit, armored |
| Out-Down | ♠ ♥ | Crit hunter who can take hits |

A cardinal leans into one stat and a diagonal into two. The total lean is the same at every
aim, so a diagonal shares it evenly between its two stats: being on a diagonal is never worth
more in itself. A half step shares it too, mostly toward the nearer cardinal. Neutral leans
into no stat.

A lean multiplies the card points (*Card values*) of the stats it points at. It amplifies what
your cards give: a lean into a stat with no points adds nothing, and high cards of a suit reward
aiming at its home. ♥ takes its lean at contact: max Posture uses your ♥ points without the
lean, and a lean into ♥ cuts the Posture damage you take on that hit. How much a lean
multiplies, how much a leaned ♥ point cuts, and the half-step share are sim values (§11).

**The stat meter.** The rider sees a meter of their four stats with the current lean applied,
live as they rotate, so they can see which aims their cards back. The meter is the rider's own:
whether your cards back your aim's lean is hidden (§3), so the opponent and spectators never
see it (§7).

Color pairing: black suits (♣ ♠) are offense, red suits (♥ ♦) are defense.

### Card values

Every revealed card adds points to its suit's stat. r = rank, 2 = 2 up to A = 14.

- **Rank value:** `1 + (r − 2) / 6` points. 2 = 1, 8 = 2, J = 2.5, A = 3. J, Q, K and A stay
  on this curve and carry it on top of their §5 effect.
- **Hole or board:** your hole cards count in full. Board cards count at the board weight (half
  to start), for both riders.
- Every revealed card counts, kickers included. Kickers also break exact ties at showdown (§2).

In your hole cards, 8♣ is 2 points of ♣ (+10% on your hits) and J♦ is 2.5 points of ♦ armor.
On the board, each is worth half that to both riders.

### Poker hands multiply

The cards that make a pair, two pair or trips multiply their points: pair ×2, two pair ×2,
trips ×3. Each card keeps its own hole or board weight, so a board pair is multiplied for both
riders at board weight. A held trick rides as its sub-hand (§6).

The curve is compressed on purpose: the gap between the two riders' numeric hands is worth
about ×1.0 to ×1.45 on a hit. The board raises both riders alike, so the gap comes from hole
cards and hand multipliers. A clean read (normal vs crit, or block vs hit) swings more than
trips vs high card.

### Stat value

```
S_suit = 20 + points_suit
```

`points_suit` is the sum of that suit's card points, with the aim lean applied (*Stances*; ♥
takes its lean at contact instead). Base
20 is the "cardless jouster" floor. Each stat turns its value into its effect at its own rate:
♣ scales your hits by `S_♣ / 20` (contact resolution, step 3), so each ♣ point is +5% on a hit.
The ♥ rate (Posture per point), ♦ rate (armor per point) and ♠ rates (piercing and charge) are
sim values (§11).

### Contact resolution (A strikes B; both directions resolve simultaneously)

1. Find the tier: look up A's aim position on B's sectors (§3). Guard = Block, exposure =
   Crit, ordinary = Normal. A in Neutral = Weak.
2. Base values: Weak 4, Normal 10, Crit 30.
3. Hit output, scaled by ♣:
   ```
   Out = Base · (S_♣,A / 20) · (0.4 + 0.6·h_A) · Street · Mods
   ```
   S_♣,A includes A's aim lean (*Stat value*), as do ♠ and ♦ below.
4. ♠ Pierce:
   - On every hit, A's ♠ pierces B's armor.
   - On a Normal or Block, the hit adds to A's charge.
   - On a Crit, A's ♠ scales the crit, and the crit spends all of A's charge as a bonus. A
     crossed-lances crit (CC) spends it too.
   - Charge lasts the whole hand, so charge built on cheap early passes pays at later street
     multipliers. The outcomes that build it are public; the amount is hidden.
5. Armor: B's ♦ armor at the sector hit, less A's piercing, is subtracted from the output:
   thick on the Guard (scaled by B's hold multiplier), thin on ordinary positions, a sliver on
   the exposure. A Block that nothing gets through is a clean block: B restores 3 Posture.
6. B's ♥ lean cut (*Stances*) is subtracted, and the rest is Posture damage to B.

### Tracks and showdown

- **Posture:** starts at 100 plus the ♥ bonus. Reaches 0 = unhorsed. Heals only from clean
  blocks, queen effects and ♥ gains on a reveal, capped at max Posture.
- **Showdown:** if no one is unhorsed after Pass 4, a knockdown is forced. Hand strength
  forces it, and Posture still counts: the rider who is weaker on hand strength and Posture
  together is knocked down. How hand strength converts, and how much it weighs against
  Posture, is open (§11).

### Sanity checks (to confirm in sim)

- Pass 1 normal hit, high card, half hold: about 10 × 1.0 × 0.7 × 0.5 = 3.5 Posture. Early
  knockouts are near impossible.
- Pass 3 crit, trips-loaded ♣, full hold: about 30 × 1.45 × 1.0 × 1.0 = 43 Posture. Two such
  reads unhorse.
- Pass 4 crit with the same: about 54 Posture.

## 5. Broadway cards

J, Q, K and A carry an effect just for being in your hand, on top of their rank and suit. Only
hole cards grant the full effect. A face card on the board applies a half-strength version to
both riders and appears in the arena.

### Single effects

| Card | In your hole cards | On the board (both riders) |
| --- | --- | --- |
| J | That card's displayed color is randomized each hand | All lance and shield colors show gray this hand |
| Q | Restore 6 Posture at the start of Passes 2, 3 and 4 | Restore 3 |
| K | Opponent's aim locks 0.15 s earlier (felt, not shown) | Both riders lock 0.08 s earlier |
| A | Your Crit base rises from 30 to 35 | Both riders' Crit base +2 |

### Pocket pairs of face cards (bespoke, replace the doubled single effect)

| Pair | Name | Effect |
| --- | --- | --- |
| JJ | Masquerade | Both colors randomized, and your public hold meter displays with a 0.5 s lag |
| QQ | Twin Favor | Restore 10 per pass; the first unhorse this hand is negated and Posture is set to 20 |
| KK | High Court | Opponent's aim locks 0.3 s earlier, and what gets through your Guard armor from them is halved |
| AA | Champion | Crit base 40, and your Normal hits on the exposure's edge notch also count as Crit |

### Rules

- Mixed face cards (AK, KQ, etc.) get both single effects. No suited bonus in v1.
- A face card that pairs with the board (you hold K, board shows K) gets only the
  numeric pair or trips. No extra effect.
- Multiple board face cards stack linearly.
- Board queen, king and ace effects apply from the pass their card is revealed on.

Sim note: J effects are information effects. A sim with no reading model values them at
zero. Expect jacks to look like dead cards until the sim has readers.

## 6. Tricks

Straight and above are tricks. A trick changes the dial's rules for the one pass it is
unleashed on. Tricks are trump cards: an unleashed trick above the opponent on the trick
ladder is built to unhorse them on that pass, so it wins the hand. The win always comes
through the joust; no rule declares it.

Frequency, from a deal sim: a rider owns a trick (see *Ownership*) by the river in about 10%
of hands (straight 4.4%, flush 2.9%, full house 2.5%, quads 0.15%, straight flush 0.02%). Of
those tricks, about 63% first appear on the river, 29% on the turn and 8% on the flop. About
18% of hands have an owned trick on at least one side, and about 2% on both; three quarters
of those are the same category. The board alone makes a trick in about 0.8% of hands. These
are rates for random deals; prefolding in the yard shifts them.

### The trick ladder

- The rungs are the trick categories, low to high: straight, flush, full house, quads,
  straight flush. The royal flush is the top straight flush, with its own presentation. Every
  numeric hand is below the ladder.
- Your rung is the category of the trick you own with the cards revealed so far, held or
  unleashed, or of the board's trick you play (*Ownership*). A rider on a higher rung is above
  the opponent. Riders on the same rung are level, whatever their ranks within it.
- Unleashing above the opponent ends the hand on that pass, before they can draw level or
  above, for the pot bet so far. Holding builds the pot and hides the trick, at the risk of
  the opponent drawing level or above, and of being worn down while riding as the sub-hand.

### Ownership

- A trick is yours only if at least one of your hole cards is part of it.
- Your hand is always your current best five cards. A held trick that a later board trick
  plays over, so that none of your hole cards is in your best five, is no longer yours.
- When the board alone makes a trick, both riders stand on its rung. A rider playing the
  board's trick can't unleash it, and it doesn't fire on Pass 4. If the opponent unleashes a
  trick on that rung, the board's trick answers and they clash (*Trick vs trick*).
- Only hole cards that lift a rider to a higher rung put them above. An improvement within the
  rung (a higher straight, a higher flush card, a better full house, a quads kicker) is level:
  the stronger hand counts at the showdown knockdown (§4).
- The board's arena effect (*Board-made tricks*) is on whenever the board alone makes a trick,
  whether or not a rider improves on it.

### Held behavior (completed but not unleashed)

- Rides as its best non-trick sub-hand for stats (a full house rides as trips, a straight with
  no pair rides as high card).
- Adds a small held passive, sized to look like a good numeric hand.
- No Posture floor: a rider holding a trick can be unhorsed like any other.
- Answers an unleash from its own rung or below (see *Trick vs trick*).

### Unleash rules

- Declared during the decision window after a card reveal (or any time in the Pass 4 run-
  up). Once per hand.
- Declaring announces the trick's rung to both riders ("Straight unleashed"). A flush also
  shows its suit. The trick's cards stay hidden until contact. A held trick that answers
  is not announced; it shows at contact.
- Any trick not unleashed by Pass 4 fires automatically on Pass 4.
- Unleashing reveals the trick in the post-pass reveal.

### Trick effects on the unleash pass

A starting draft, to be tuned in the sim.

- **The hit.** An unleashed trick's hit is sized to unhorse the opponent from full Posture on
  any pass, Pass 1 included, when the trick is played to its design: a straight held (*The
  straight's meter*), a flush aimed at its suit's home (*Flush by suit*). Full house and quads
  are unconditional. Hit sizes are sim values. Armor is a flat reduction per hit (§4),
  so a hit that size gets through any sector, a Block included.
- **The out.** What a trick changes on the dial sets its out: the narrow way a numeric rider
  can still survive, by unhorsing the trick rider on the same contact while ahead on Posture
  before the pass (§2, win condition 2). The out narrows as the ladder climbs.
- **The ward.** Unleashing or answering also wards the rider: armor that counts against trick
  hits only, never numeric ones. Trick hits grow explosively up the ladder. Each rung's ward
  stops the hits of every rung below it, but not its own rung's or higher. So across rungs a
  higher trick's hit breaks the lower ward, and a lower trick's hit can't get through the
  higher one. The straight, the bottom rung, needs none. Ward sizes are sim values.
- **The joust decides.** No rule declares a winner. A trick above the opponent wins
  overwhelmingly because the numbers make it so.

| Trick | Held passive | On the dial when unleashed | Out left to a numeric rider |
| --- | --- | --- | --- |
| Straight: The Charge | +3 to the top card's suit stat, growing with hold: 0 at the start of each pass, the full +3 at full hold | Your hit grows with the straight's meter (below). | Widest: normal exposure, and the rider can't move without resetting the meter |
| Flush: Suit Ascendant | +4 to the flush suit's stat | The flush suit's stat explodes (see *Flush by suit*) | ♣ and ♠: normal exposure. ♥ and ♦: none |
| Full house: Fortress | +4 ♥ and +4 ♦ | Your Guard covers every position but one gap direction, picked secretly at declaration. A hit on the gap is a Crit. | Only a crit through the gap: 1 in 8 at random |
| Quads: Four Lances | +4 to all four stats | Your strike lands on all four cardinals of their dial. Any five positions of exposure hold a cardinal, so one lance always crits. The lances parry their strike: it deals nothing. | None |
| Straight flush | Straight + flush passives | The Charge and Suit Ascendant, with no exposure this pass. It inherits both conditions: its hit grows with the meter and with the lean toward its suit's home, and fully played it is the strongest hit on the ladder. | None |
| Royal flush | Same as straight flush | Same as straight flush, with its own presentation | None |

### The straight's meter

A straight makes its money by holding still. On the unleash pass, a meter steps through the
straight's five cards, low to high, as the rider holds one aim: one card per fifth of the
run-up (hold fraction h ≥ 1/5, 2/5, … 5/5, §3). Changing aim resets it with h.

- The hit grows as x^y, where x is a fixed base and y is the value of the highest card
  unlocked. Held on a linear timer, each card is worth more than the last, and most of the
  power arrives toward the end of the hold.
- A higher straight's cards are higher, so it builds bigger and reaches an unhorsing hit
  sooner.
- The meter replaces the hold multiplier (0.4 + 0.6 × h) for the trick's hit. The base x, and
  how y maps to hit size, are sim values.
- A rider drawing to a straight who wants to unleash on the pass it lands must hold from the
  start of the charge: the meter counts hold from then, and the card lands at 3.0 s (§8).

### Flush by suit (what "Suit Ascendant" does per suit)

The suit's stat explodes at full strength when aimed at its compass home (§4 *Stances*) and at
half on the two diagonals beside it. Aimed anywhere else, the flush adds nothing beyond its
base stat; half steps share the tilt as on the compass. The suit is announced on declaration
(*Unleash rules*).

| Suit | Name | Home | Effect |
| --- | --- | --- | --- |
| ♣ | Shattering Blow | Up | Your hit's raw damage lands in full, even into a Block |
| ♠ | Needle | Out | Every hit you land is a Crit that pierces all armor, and it spends your charge |
| ♥ | Unbroken | Down | You can't be unhorsed this pass |
| ♦ | Gilded Mirror | In | Your armor covers your whole dial, exposure included, and what it stops reflects back at the striker |

### Trick vs trick

- A held trick answers an unleash from its own rung or below: it fires automatically on the
  same pass, however late the unleash is declared. The answer is its unleash for the hand. A
  held trick below the unleash doesn't answer; it rides as its sub-hand.
- Level tricks clash. Two tricks on the same rung, both unleashed or one answering the other,
  cancel for that pass, and it resolves as numeric. Both are spent. The edge between level
  tricks comes from poker and play: who reached the rung first and unleashed while above,
  the stronger hand at the showdown knockdown (§4), and the dial on the numeric passes.
- Tricks on different rungs both apply, and the dial resolves them. Each trick is designed
  to beat the tricks below it on the dial. Where two tricks' rules contradict outright, the
  higher trick's rule wins that contradiction; everything else still applies.

### Board-made tricks (arena effects, both riders, all passes after the reveal)

| Board makes | Arena effect |
| --- | --- |
| Straight | Open Lists: numeric Posture damage ×1.5 |
| Flush | An arena moment in the suit's colors, with no stat bonus: the board's cards already count for both riders (§4 *Card values*) |
| Full house | Siege: numeric output ×0.5; the hand leans on the showdown knockdown |
| Quads | An arena moment, with no rule of its own: kickers settle a showdown tie as usual (§2) |
| Straight flush | Board flush + Open Lists |

The arena multipliers scale numeric hits only; a trick's hit keeps its size. The ×1.5 and ×0.5
are placeholders; their numbers come later.

### Presentation

- Scale follows rank: a flush always looks bigger than a straight, a full house bigger than
  both.
- Unleash contact uses the setup/counter system (see Pass timeline and presentation).
- An optional style input during the unleash (a timed flourish) affects only cosmetics.

## 7. Information design

Every visible cue should narrow the opponent's range without identifying the hand.
Design rule: each tell must have at least two plausible causes.

### Color leak

- The lance shows one hole card's color and the shield shows the other's. Assignment is
  random per hand, so the lance/shield position leaks no rank.
- Red = defensive suit (♥ ♦), black = offensive suit (♣ ♠). Colors reveal offense/defense
  lean, never the axis.
- Colors sharpen as the board develops. Red-red with a three-red flop is a visible flush
  threat.
- A jack in the hole shows a random color, not a blank. A hidden or neutral color would
  itself reveal the jack.

### What each read targets

| Cue | Public source | What it suggests | Why it's ambiguous |
| --- | --- | --- | --- |
| Stance (aim lean) | Aim position | Which stats the rider's cards load | Could be a bluff stance or a pure sector read |
| Hold meter | Hold fraction | Confidence in the current aim | Late switches cost power but are legal |
| Lance/shield color | Hole card colors | Offense vs defense lean | Axis hidden; jack randomizes |
| Clean blocks | Block outcome | Thick Guard armor (♦) | Could be hold, not cards |
| First exit from Neutral | Timing | Eagerness or confidence | Could be habit |

**Core read loop.** Aim is public, so everyone sees the stance. The secret is whether the
stance is loaded. If you think the opponent's Guard is soft, strike into it and get through the armor. If
you think it's real, go for their exposure instead. This replaces the hidden Shield from
Turbo Jousting.

**Post-pass reveal.** After each contact, show both aims, hold meters, the tiers landed, and
any unleashed trick. Hole cards are revealed only at hand end (unhorse, showdown, or a
yield where the winner chooses to show).

**Spectators** see exactly what the opponent sees, never hole cards before reveal. This rules
out a TV-poker hole-card cam, which would let a friend on the rail relay information.

## 8. Pass timeline and presentation

A pass lasts about 8 s from the start of the charge to contact. The card reveal lands mid-
charge with a brief slow-motion beat, then riders decide and commit before contact.

| Time (s) | Beat | Notes |
| --- | --- | --- |
| 0.0 | Charge begins, both riders in Neutral | Stats are the previous street's |
| 0.0–3.0 | Approach; riders may aim and start holding | Hole-card tells (colors, first exit from Neutral) show here |
| 3.0 | Card reveal: arena changes, UI shows the card | New stats apply now, not at contact |
| 3.0–4.5 | Slow motion (about 0.4× speed) | UI evaluates the new hand instantly ("Flush ♥ ready") and flags board threats |
| 4.5–7.7 | Decision window: re-aim, hold, unleash | Hold fraction counts only real time at full speed |
| 7.7 | Aim lock | No input after this |
| 8.0 | Contact and resolution | Setup/counter animation, then post-pass reveal |

Pass 4 has no card reveal. Its full 8 s is approach and decision, and unused tricks auto-fire.

**Arena reveals.** Each revealed card changes the environment: suit sets the sky and
lighting color (hearts and diamonds red-toned, clubs and spades dark-toned), face cards
add their emblem (queen banners, king standards). Board-made tricks and board face
cards get their own arena state for the rest of the hand.

### Setup/counter animation system

- The loser's animation plays first as a near-success (the setup), then the winner's
  animation interrupts it (the counter).
- Every hand type gets two segments: a setup (used when it loses) and a counter (used
  when it wins). N hand types need 2N animations, not N² pairings.
- Standardize the interrupt frame and rider positions so any setup can cut into any
  counter.
- Offensive counters overtake the attack (the Charge, Shattering Blow, Needle).
  Defensive counters absorb and retaliate (Fortress, Unbroken, Gilded Mirror).
- Numeric setups are data-driven: a vertical-stance loser swings for the unhorse, a
  horizontal-stance loser goes for the pierce.
- A held trick countering an unleashed trick is the biggest moment in the game and gets
  the largest presentation budget.
- Clash beat for level tricks: both lances shatter.
- Trick resolutions run 3 to 5 s maximum. After first viewing, tap to speed up.

## 9. Reference: what we take from rblx-joust-tourney

Turbo Jousting (repo) is a parts bin, not a rulebook. Its invariants do not bind this game;
we take mechanics and code that fit the poker spirit.

| Take | Source | Use here |
| --- | --- | --- |
| 8-notch dial with Neutral and hard snapping | GAME_SPEC §3, ADR 0006 | The standard dial, at half-step resolution |
| Polarization: exposure at the strike, Guard opposite | GAME_SPEC §3 | Sectors |
| Chiral 3-notch exposure | ADR 0006 | Chirality: the standard dial sweeps in label order; its layout is §3's own |
| Held-aim proration with a public meter | ADR 0001, 0008 | The windup, as a price not a lock |
| Aim lock before the tick | GAME_SPEC §3 | 0.3 s lock |
| Magnet wheel feel (drag, flick, detents) | `claude/ring-spin-ui-feel-xpatk4` branch, `src/shared/WheelPhysics.luau` and `Constants.WHEEL` | Dial input |
| Simultaneous one-tick resolution | CLAUDE.md invariant 3 | Contact resolution |
| Post-pass reveal | GAME_SPEC §8 | After each contact |
| Ghosts as habit tables, never recordings | ADR 0013, `diegetic-lobby-design` branch | Add betting, yield and unleash habits conditioned on the ghost's own hand-strength band |
| House riders (labeled scripted personalities) | ADR 0013 | Need betting personalities too |
| Tilt-yard lobby, rail spectating, rematch default | ADR 0012, 0014, 0015 | Loop and lobby |
| Rail sees only what the opponent sees | CLAUDE.md invariant 11 | No hole-card cam |
| Headless Lune sim and test harness | `tools/sim.luau`, tests | Starting point for this game's sim |

| Drop or change | Why |
| --- | --- |
| Hidden Shield | Replaced by hole cards; the secret is now whether your stance is loaded |
| Supershield | Its job (hard Guard) is now ♦ Armor and hold |
| Balance teeter roll | Replaced by deterministic Posture. Could return as an option (see Open questions) |
| Breaking and the mortal ladder | Deferred; not needed for v1 |
| Spur and momentum | Deferred; hold is the only run-up currency in v1 |
| One duel to unhorse | A hand is 4 passes; a forced knockdown at showdown decides if no one falls |
| "Never a wager" (ADR 0015) | Betting is core here, within limits (see Open questions) |
| Reads always beat rarity | Replaced by the trick vs read arms race |

## 10. v2: classes and dials

Deferred. v1 ships the standard dial for everyone. In v2, a rider picks a favorite rank before
play; that rank sets their class, which gives them one of 13 dials and a small buff whenever
they hold that rank.

Class is public. The dial shape is visible, like character select in a fighting game. This gives
matchup charts and a readable meta. Hidden information stays in the cards.

### Favorite-card buff (hole cards only)

- Holding your favorite rank as a hole card happens about 15% of hands, so opponents
  know you might have it.
- Effect: the card counts one rank higher for Power and double weight in the suit split.
  Face-card classes also upgrade their face effect one step toward the pocket-pair
  version.
- Your rank on the board: a small public buff and an arena moment ("that's their card").
  About 45% of hands show at least one of a given rank somewhere in 7 cards.

**Dial parameters.** All 13 dials vary a shared set so they stay balanceable:

- Guard width (1 to 2 directions)
- Exposure length (2 to 4 directions)
- Chirality (clockwise or counterclockwise sweep)
- Hold rate (how fast the hold fraction fills)

### Proposed families

| Ranks | Class | Dial tilt |
| --- | --- | --- |
| 2–5 | Turtles | Wide Guard, short exposure, small crits |
| 6–9 | Brawlers | Balanced, varied hold rates |
| 10 | The Standard | The v1 dial |
| J | Trickster | Public hold meter displays slightly off from the true hold |
| Q | Warden | Clean blocks restore more Posture |
| K | Commander | Opponent's aim locks earlier |
| A | Champion | Narrow Guard, long exposure, big crits |

Odd and even ranks set chirality, so neighboring ranks feel like mirror pairs. That is about
five families plus mirroring: a tuning load the sim can cover.

Open question for v2: 13 ranks give 13 classes; if ace-low (1) and ace-high (14) are meant as
separate picks, that makes 14.

## 11. Open questions, tuning and next steps

The next step is a headless sim of one hand, using the parameters below as config. It
answers whether numeric hands order correctly, how often skill flips close matchups, and
whether a trick above the opponent wins overwhelmingly.

### Open questions

- Do tricks meet their targets? A trick above the opponent, played to its design, wins
  overwhelmingly (the number is Trey's, not yet set). A higher trick nearly always beats a
  lower one across rungs. The sim reports how often a held trick is drawn out, and splits
  trick win rates by whether the trick was played to its design.
- Should the unhorse be a visible-odds roll at low Posture (the Turbo Jousting teeter)
  instead of a hard 0?
- Is the 0.4 hold floor collapsing half-holds toward last-instant flicks? A switch onto a
  held aim wins when the floor is above what the holder deals back divided by what the
  switch deals: Normal/Crit = 1/3 on a CN row, lower on a CB row (§3).
- Is an 8 s pass long enough to read the reveal, decide, and react to a hold?
- Prefold cost: what does prefolding in the yard cost (units, time, or both)?
- Preflop redraw for a price: a second hand-selection tool alongside the prefold. What can be
  redrawn, and what does it cost?
- Wager limits: cap the pot (for example 3× ante) so a loss stays cheap?
- Roblox policy on simulated gambling and maturity labels. Stake only earned currency,
  never purchasable currency, until checked.
- Ghost betting: which public and private inputs a ghost's betting habits condition on.
- Should spur and momentum return as a second run-up currency?
- Showdown knockdown: how hand strength converts, and how much it weighs against Posture.
- How slow-motion time counts toward the hold fraction (§3, §8).
- A hit's size is public: can one hit identify a hand's rank at display precision?

### Tuning parameters (sim config)

| Parameter | v1 value |
| --- | --- |
| Posture start | 100 |
| Base: Weak / Normal / Crit | 4 / 10 / 30 |
| Stat base (cardless floor) | 20 |
| Card value by rank r | 1 + (r − 2) / 6 points: 2 = 1, 8 = 2, A = 3 |
| Board card weight | ½ of a hole card; the sim tries lower |
| Hand multipliers on made cards: pair / two pair / trips | ×2 / ×2 / ×3 |
| Stat rates per point | ♣ +5% on a hit (S_♣ / 20); ♥ Posture, ♥ lean damage cut, ♦ armor, ♠ piercing and charge set by the sim |
| Hold multiplier | 0.4 + 0.6 × h |
| Street multipliers (Passes 1–4) | 0.5 / 0.75 / 1.0 / 1.25 |
| Clean block restore | 3 Posture |
| Aim lock before contact | 0.3 s |
| Pass length | 8 s |
| Standard dial layout (half steps from aim) | Exposure 0–4, ordinary 5–7, Guard 8, ordinary 9, Guard 10–12, ordinary 13–15 |
| ♦ armor: Guard / ordinary / exposure | Thick / thin / sliver; values set by the sim |
| ♠ charge per non-crit hit, and piercing | Set by the sim |
| Aim lean: multiplier on card points, and the half-step share | Set by the sim |
| Showdown: hand strength weight against Posture | Set by the sim |
| Queen restore (hole / board) | 6 / 3 per pass |
| King lock penalty (hole / board) | 0.15 / 0.08 s |
| Ace crit base (hole / board bonus) | 35 / +2 |
| Trick hit, per rung | Set by the sim: unhorses from full Posture when played to its design |
| Trick ward, per rung | Set by the sim |
| Straight meter: base x, and how y maps to hit size | Set by the sim |
| Flush: suit stat explosion (full at home, half on the diagonals beside it) | Set by the sim |
| Full house: Guard coverage | 7 of 8 directions |
| Held passive sizes | +3 to +4 card points (§4); the sim checks them. The straight's grows with hold; its curve is set by the sim |
| Raise size (Passes 1–2 / 3–4) | 1 / 2 units |
| Betting action timer | 5 s |

### Sim plan

1. Deal random heads-up hands and evaluate each street.
2. Scripted riders with parameters: read accuracy (chance to pick the best aim position vs the
   opponent's sectors), hold discipline, stance honesty (lean toward your loaded stats),
   aggression (raise and unleash timing).
3. Metrics: win rate by hand-category gap; knockout rate by pass; how often skill flips a
   numeric matchup; unleashed-trick win rate by trick; unhorse vs showdown finish ratio.
4. v2 of the sim: a reading model, so jack, color and held-trick tells get a value.
