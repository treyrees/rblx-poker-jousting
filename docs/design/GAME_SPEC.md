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
  hold'em. Outcomes come from the joust, not a card comparison, except as a final
  tiebreak.
- **Play every hand.** Numeric hands (high card through trips) are modest stat edges. Skill
  on the dial decides most numeric matchups, so a bad hand is a handicap, not a fold.
- **Tricks are trump cards.** Straight and above are tricks, ranked on a trick ladder. As the
  ladder climbs, tricks bring unique mechanics and/or explosively scaled numbers. A rider above
  the opponent on the ladder who unleashes their trick, rather than holding it, has a virtually
  guaranteed win condition.
- **Ambiguous tells.** The dial and the rider leak partial information about hole cards.
  Nothing leaks the exact hand.
- **Suits are stats and axes.** Each suit is a stat, and each stat lives on an axis of the
  dial. Aim is public; whether your stance is actually loaded is the secret.

Also important: **learnability** (for example, betting is beginner-ignorable, §2) and
**spectacle** (for example, the setup/counter animation system, §8).

### Status

| Area | Section | State |
| --- | --- | --- |
| Hand structure: deck, deal, streets, win conditions | §2 | Settled |
| Betting | §2 | Settled |
| Standard dial: notches, sectors, Neutral, held aim, aim lock | §3 | Settled for v1, numbers tunable |
| Suits as stats on the dial's axes | §4 | Settled |
| The four stats: what they are and what they do | §4 | Open |
| Numeric Power curve and suit split | §4 | Proposed, needs sim |
| Contact resolution, Seat and Score | §4 | Proposed, needs sim |
| Broadway effects | §5 | Proposed, needs sim |
| Tricks: ladder, ownership, held and unleash rules, effects | §6 | Open |
| Board-made tricks | §6 | Proposed, needs sim |
| Information design | §7 | Settled |
| Pass timeline | §8 | Proposed, needs sim |
| Presentation: arena reveals, setup/counter animation | §8 | Settled in shape |
| What we take from rblx-joust-tourney | §9 | Settled |
| Classes and alternate dials | §10 | Deferred to v2 |
| Economy, wager limits, monetization | §11 | Open |
| Tuning parameters | §11 | Proposed, needs sim |

## 2. Hand structure and betting

One hand is one match: four bets and four passes. Cards reveal mid-charge, so each bet is
made before the card it rides into, as in hold'em where you call and then see the card.

### Deck and deal

- One standard 52-card deck per hand, no jokers.
- Each rider gets 2 private hole cards. The hole cards replace the Turbo Jousting Shield
  entirely.
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

### Win conditions

1. A rider whose Seat reaches 0 is unhorsed. The other rider wins the pot immediately.
2. If both riders are unhorsed on the same contact, the rider with more Seat before the
   pass wins; if equal, split.
3. If no one is unhorsed after Pass 4, the higher Score wins.
4. Score tie: compare poker hands with kickers. Still tied: split the pot.
5. A rider who Yields forfeits the pot.

### Betting rules (v1)

- Fixed limit. Raise size is 1 unit before Passes 1 and 2, 2 units before Passes 3 and 4.
- Decisions are simultaneous with a short timer (5 to 8 s). If exactly one rider raises, the
  other gets a call-or-yield prompt (5 s).
- One re-raise cap per betting round.
- Timeout defaults to Stay (call). This keeps the game beginner-ignorable: a player who
  never touches betting still plays every hand.
- Players can only fold between passes. Every revealed card is ridden into.
- Street multipliers apply to all Seat damage and Score gained in that pass: Pass 1 = 0.5,
  Pass 2 = 0.75, Pass 3 = 1.0, Pass 4 = 1.25. Early passes rarely unhorse; the hand builds
  toward the river.

## 3. The standard dial (v1)

Every rider uses the same dial in v1. One input, the aim, sets offense and defense
together: you are exposed where you strike, and your Guard sits opposite.

### Layout

- 8 notches: 4 cardinals (Up, Out, Down, In, self-relative) and 4 diagonals between them.
- Plus Neutral, the default state at the start of every pass.
- Aim snaps to notches (hard snapping). The needle may animate smoothly; the state is
  always one of 9 values.
- Input: a circular touch wheel (drag to aim, flick to spin past notches). Port the Magnet
  wheel physics from the `ring-spin-ui-feel` branch.

### Sectors (derived from aim, automatic)

| Sector | Size | Position | Hit on it resolves as |
| --- | --- | --- | --- |
| Vulnerable (exposure) | 3 notches | The aim notch plus the next 2 notches clockwise | Crit |
| Defensive (Guard) | 1 notch | Directly opposite the aim notch | Block (may leak, see Suits section) |
| Negative (ordinary) | 4 notches | Everything else | Normal hit |

The exposure is chiral (it sweeps one way), so a correct read can land a crit that is not
traded back. The standard dial sweeps clockwise; v2 dials may mirror it.

### Neutral

- Neutral aim at contact: a weak center strike (base 4), cannot crit.
- Neutral has no Guard. Every incoming hit on a neutral rider resolves as Normal.
- Neutral is where the run-up starts, so the first frame leaks nothing. When a rider first
  leaves Neutral is itself a tell.

### Held aim (the windup)

- Hold fraction h = the fraction of the run-up the final aim notch was held (0 to 1).
  Changing notch resets h for the new notch.
- Strike power and Guard hardness both scale by the hold multiplier: `0.4 + 0.6 × h`.
- The hold meter is public. Holding is the value bet; a late switch is the bluff, and it costs
  power. This is a price, not a lock: players commit by degrees, which keeps bluffing a dial
  instead of a yes/no.
- The 0.4 floor is a placeholder. Turbo Jousting's sim found a floor can collapse half-held
  aims toward last-instant flicks; re-check in the sim.

### Aim lock

Aim locks 0.3 s before contact. After lock, no input changes the outcome. This prevents
ping wars.

### Public vs hidden

| Public | Hidden |
| --- | --- |
| Aim notch, and so both sectors | Hole cards |
| Hold meter | Which stance your cards actually load |
| Seat and Score | Whether you hold a trick |
| Board cards and arena effects | Your hand's exact suit mix |
| Lance and shield colors (see Information design) | True colors behind a jack |

## 4. Suits, stats and stances

Each suit is one stat, and each stat lives on one axis of the dial. Because the Guard sits
opposite the aim, aiming on an axis activates that axis's offense stat on your strike and its
defense stat on your Guard at the same time.

| Axis | Canonical aim (offense) | Guard lands on (defense) | Contest |
| --- | --- | --- | --- |
| Vertical | Up: ♣ Knockoff | Down: ♥ Sturdiness | Seat (unhorsing) |
| Horizontal | Out: ♠ Pierce | In: ♦ Armor | Score (damage) |

**Axis rule (decided for v1).** Stats apply by axis, not by single direction. Aiming Up or Down
both use the vertical stance (♣ strike, ♥ Guard). Aiming Out or In both use the horizontal
stance (♠ strike, ♦ Guard). Up vs Down is then a pure read on the opponent's sectors, not
a stat choice. Diagonals use the average of both axes and split their output 50/50 between
Seat and Score.

Color pairing: black suits (♣ ♠) are offense, red suits (♥ ♦) are defense.

### Power by hand category (numeric hands)

Only the cards that make the hand contribute ("made cards"). Kickers only break Score
ties. r = rank, 2 = 2 up to A = 14.

| Category | Power P | Range | Made cards |
| --- | --- | --- | --- |
| High card | 4 × (r_top − 7) / 7 | 0 to 4 | Top card |
| Pair | 8 + 0.5 × (r − 2) | 8 to 14 | 2 |
| Two pair | 16 + 0.5 × (r_high − 3) + 0.05 × r_low | 16 to 22 | 4 |
| Trips | 24 + 0.67 × (r − 2) | 24 to 32 | 3 |

The curve is compressed on purpose: category gaps guarantee ordering, but the whole
numeric range is worth about ×1.0 to ×1.45 on a hit. A clean read (normal vs crit, or block vs
hit) swings more than trips vs high card.

### Suit split

- Each suit absent from the made cards gets 15% of P.
- The remainder, 1 − 0.15 × (number of absent suits), is divided among present suits by
  card count.
- Examples: a pair (2 suits) splits 35 / 35 / 15 / 15. Two pair across 4 suits splits 25 each.
  Trips (3 suits) is about 28.3 each plus 15 for the missing suit.

### Stat value

```
S_suit = 20 + P · share_suit
```

Base 20 is the "cardless jouster" floor. Board-only cards contribute to both riders equally.

### Contact resolution (A strikes B; both directions resolve simultaneously)

1. Find the tier: look up A's aim notch on B's sectors. Guard = Block, Vulnerable = Crit,
   Negative = Normal. A in Neutral = Weak.
2. Base values: Weak 4, Normal 10, Crit 30.
3. Hit output:
   ```
   Out = Base · (S_off,A / 20) · (0.4 + 0.6·h_A) · Street · Mods
   ```
4. Block leak: when the tier is Block, compare offense against Guard hardness.
   ```
   Leak = max(0, S_off,A·(0.4 + 0.6·h_A) − S_def,B·(0.4 + 0.6·h_B)) · 0.5 · Street
   ```
   If Leak is 0, it is a clean block: B restores 3 Seat.
5. Route the output by axis: vertical output is Seat damage to B, horizontal output is Score
   for A, diagonal splits 50/50.

### Tracks

- **Seat:** starts at 100. Reaches 0 = unhorsed. Heals only from clean blocks and queen
  effects, capped at 100.
- **Score:** starts at 0, only goes up. Decides the hand after Pass 4 if no one is unhorsed.

### Sanity checks (to confirm in sim)

- Pass 1 normal hit, high card, half hold: about 10 × 1.0 × 0.7 × 0.5 = 3.5 Seat. Early
  knockouts are near impossible.
- Pass 3 crit, trips-loaded axis, full hold: about 30 × 1.45 × 1.0 × 1.0 = 43 Seat. Two such
  reads unhorse.
- Pass 4 crit with the same: about 54 Seat.

## 5. Broadway cards

J, Q, K and A carry an effect just for being in your hand, on top of their rank and suit. Only
hole cards grant the full effect. A face card on the board applies a half-strength version to
both riders and appears in the arena.

### Single effects

| Card | In your hole cards | On the board (both riders) |
| --- | --- | --- |
| J | That card's displayed color is randomized each hand | All lance and shield colors show gray this hand |
| Q | Restore 6 Seat at the start of Passes 2, 3 and 4 | Restore 3 |
| K | Opponent's aim locks 0.15 s earlier (felt, not shown) | Both riders lock 0.08 s earlier |
| A | Your Crit base rises from 30 to 35 | Both riders' Crit base +2 |

### Pocket pairs of face cards (bespoke, replace the doubled single effect)

| Pair | Name | Effect |
| --- | --- | --- |
| JJ | Masquerade | Both colors randomized, and your public hold meter displays with a 0.5 s lag |
| QQ | Twin Favor | Restore 10 per pass; the first unhorse this hand is negated and Seat is set to 20 |
| KK | High Court | Opponent's aim locks 0.3 s earlier, and their block leak against you is halved |
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
unleashed on. It does not win outright: every trick trades power for some predictability,
and higher tricks give more power with less counterplay, never zero.

Frequency: a player finishes with a straight or better in about 10.5% of 7-card hands
(straight 4.6%, flush 3.0%, full house 2.6%, quads 0.17%, straight flush 0.03%). About 1 in
5 hands that reach the river have a trick on at least one side.

### Ownership

- A trick is yours only if at least one of your hole cards is part of it.
- If the board alone makes the trick and neither rider improves on it, it is board-made
  (see below). Neither rider can unleash it.

### Held behavior (completed but not unleashed)

- Rides as its best non-trick sub-hand for stats (a full house rides as trips, a straight with
  no pair rides as high card).
- Adds a small held passive, sized to look like a good numeric hand.
- Seat cannot drop below 1 while holding a trick. This makes slow-playing safe from being
  unhorsed, at the cost of a tell: a weak-looking rider who won't fall. Tunable; remove if
  slow-play is too safe.

### Unleash rules

- Declared during the decision window after a card reveal (or any time in the Pass 4 run-
  up). Once per hand.
- Hidden until contact, except the flush, which reveals its suit on declaration.
- Any trick not unleashed by Pass 4 fires automatically on Pass 4.
- Unleashing reveals the trick in the post-pass reveal.

### Trick effects on the unleash pass

| Trick | Held passive | Wheel effect when unleashed | Counterplay (the read) |
| --- | --- | --- | --- |
| Straight: The Charge | +3 to the top card's suit stat | Your strike ignores Guard (a Guard hit resolves as Normal) and output ×1.5. Your exposure widens to 4 notches this pass. | Punish the wider exposure and win the damage trade |
| Flush: Suit Ascendant | +4 to the flush suit's stat | The flush suit's stat ×2 on its axis. Suit is revealed on declaration. Diagonals get half the bonus. | Opponent knows which axis you want and can Guard it. Holder can hedge on a diagonal at partial power. |
| Full house: Fortress | +4 Sturdiness and +4 Armor | Your Guard covers 7 of 8 notches. You secretly pick the one gap at declaration. A hit on the gap is a Crit. | Find the gap: 1 in 8, narrowed by tells and aim |
| Quads: Four Lances | +4 to all four stats | Your strike resolves on all 4 cardinals of the opponent's dial, each at 50% output | The Guard blocks at most one cardinal; aim so it blocks the best one |
| Straight flush | Straight + flush passives | The Charge plus Suit Ascendant, including the suit reveal | Trade race on Seat only |
| Royal flush | Same as straight flush | Same as straight flush, with its own presentation | Same |

### Flush by suit (what "Suit Ascendant" does per suit)

| Suit | Name | Effect |
| --- | --- | --- |
| ♣ | Shattering Blow | Knockoff ×2 on vertical aim: big Seat damage |
| ♠ | Needle | Pierce ×2 on horizontal aim: big Score |
| ♥ | Unbroken | Sturdiness ×2; your Guard widens to 3 notches on vertical aim, and clean blocks restore 10 |
| ♦ | Gilded Ward | Armor ×2; your Guard widens to 3 notches on horizontal aim, and blocks reflect 50% of the blocked output back as Score for you |

### Trick vs trick

- Both unleashed effects apply at once and the dial resolves them. No special rules.
- Poker rank only breaks exact ties in the outcome (for example equal Score after Pass
  4).
- Identical tricks from hole cards (both hold a 9 for the same straight) clash: both effects
  cancel for that pass and it resolves as numeric.

### Board-made tricks (arena effects, both riders, all passes after the reveal)

| Board makes | Arena effect |
| --- | --- |
| Straight | Open Lists: all Seat damage ×1.5. If the top card is 10 or higher, Score ×1.5 too. |
| Flush | That suit's stat +8 for both riders, tilting the hand toward its axis |
| Full house | Siege: all output ×0.5; the hand leans on Score and kickers |
| Quads | Score ties use hole cards only |
| Straight flush | Board flush + Open Lists |

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
| Stance (aim axis) | Aim notch | Which axis the rider's cards load | Could be a bluff stance or a pure sector read |
| Hold meter | Hold fraction | Confidence in the current aim | Late switches cost power but are legal |
| Lance/shield color | Hole card colors | Offense vs defense lean | Axis hidden; jack randomizes |
| Refusing to fall | Seat at 1 | Holding a trick | Could be queen heals or strong ♥ loading |
| Clean blocks | Block outcome | Hard Guard on that axis | Could be hold, not cards |
| First exit from Neutral | Timing | Eagerness or confidence | Could be habit |

**Core read loop.** Aim is public, so everyone sees the stance. The secret is whether the
stance is loaded. If you think the opponent's Guard is soft, strike into it for leak damage. If
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
  Defensive counters absorb and retaliate (Fortress, Unbroken, Gilded Ward).
- Numeric setups are data-driven: a vertical-stance loser swings for the unhorse, a
  horizontal-stance loser goes for the pierce.
- A held trick countering an unleashed trick is the biggest moment in the game and gets
  the largest presentation budget.
- Clash beat for identical tricks: both lances shatter.
- Trick resolutions run 3 to 5 s maximum. After first viewing, tap to speed up.

## 9. Reference: what we take from rblx-joust-tourney

Turbo Jousting (repo) is a parts bin, not a rulebook. Its invariants do not bind this game;
we take mechanics and code that fit the poker spirit.

| Take | Source | Use here |
| --- | --- | --- |
| 8-notch dial with Neutral and hard snapping | GAME_SPEC §3, ADR 0006 | The standard dial |
| Polarization: exposure at the strike, Guard opposite | GAME_SPEC §3 | Sectors |
| Chiral 3-notch exposure | ADR 0006 | Standard dial sweeps clockwise |
| Held-aim proration with a public meter | ADR 0001, 0008 | The windup, as a price not a lock |
| Aim lock before the tick | GAME_SPEC §3 | 0.3 s lock |
| Magnet wheel feel (drag, flick, detents) | `ring-spin-ui-feel` branch, `WheelPhysics.luau` | Dial input |
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
| Supershield | Its job (hard Guard) is now suit loading and hold |
| Balance teeter roll | Replaced by deterministic Seat. Could return as an option (see Open questions) |
| Breaking and the mortal ladder | Deferred; not needed for v1 |
| Spur and momentum | Deferred; hold is the only run-up currency in v1 |
| One duel to unhorse | A hand is 4 passes; Score decides if no one falls |
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

- Guard width (1 to 2 notches)
- Exposure length (2 to 4 notches)
- Chirality (clockwise or counterclockwise sweep)
- Hold rate (how fast the hold fraction fills)

### Proposed families

| Ranks | Class | Dial tilt |
| --- | --- | --- |
| 2–5 | Turtles | Wide Guard, short exposure, small crits |
| 6–9 | Brawlers | Balanced, varied hold rates |
| 10 | The Standard | The v1 dial |
| J | Trickster | Public hold meter displays slightly off from the true hold |
| Q | Warden | Clean blocks restore more Seat |
| K | Commander | Opponent's aim locks earlier |
| A | Champion | Narrow Guard, long exposure, big crits |

Odd and even ranks set chirality, so neighboring ranks feel like mirror pairs. That is about
five families plus mirroring: a tuning load the sim can cover.

Open question for v2: 13 ranks give 13 classes; if ace-low (1) and ace-high (14) are meant as
separate picks, that makes 14.

## 11. Open questions, tuning and next steps

The next step is a headless sim of one hand, using the parameters below as config. It
answers whether numeric hands order correctly, how often skill flips close matchups, and
whether tricks win often but not always.

### Open questions

- Does a hand-to-hand trick win rate land in a healthy band (target: unleashed tricks win
  about 75 to 90% of the time vs numeric hands)?
- Is the held-trick Seat floor too safe for slow-playing?
- Should the unhorse be a visible-odds roll at low Seat (the Turbo Jousting teeter)
  instead of a hard 0?
- Is the 0.4 hold floor collapsing half-holds toward last-instant flicks?
- Is an 8 s pass long enough to read the reveal, decide, and react to a hold?
- Wager limits: cap the pot (for example 3× ante) so a loss stays cheap?
- Roblox policy on simulated gambling and maturity labels. Stake only earned currency,
  never purchasable currency, until checked.
- Ghost betting: which public and private inputs a ghost's betting habits condition on.
- Should spur and momentum return as a second run-up currency?

### Tuning parameters (sim config)

| Parameter | v1 value |
| --- | --- |
| Seat start | 100 |
| Base: Weak / Normal / Crit | 4 / 10 / 30 |
| Stat base (cardless floor) | 20 |
| Absent-suit share floor | 15% |
| Hold multiplier | 0.4 + 0.6 × h |
| Street multipliers (Passes 1–4) | 0.5 / 0.75 / 1.0 / 1.25 |
| Block leak factor | 0.5 |
| Clean block restore | 3 Seat |
| Aim lock before contact | 0.3 s |
| Pass length | 8 s |
| Exposure / Guard / ordinary | 3 / 1 / 4 notches |
| Queen restore (hole / board) | 6 / 3 per pass |
| King lock penalty (hole / board) | 0.15 / 0.08 s |
| Ace crit base (hole / board bonus) | 35 / +2 |
| Straight: output, exposure | ×1.5, 4 notches |
| Flush: axis stat | ×2 |
| Full house: Guard coverage | 7 of 8 notches |
| Quads: per-cardinal output | 50% |
| Held passive sizes | +3 to +4 |
| Raise size (Passes 1–2 / 3–4) | 1 / 2 units |

### Sim plan

1. Deal random heads-up hands and evaluate each street.
2. Scripted riders with parameters: read accuracy (chance to pick the best notch vs the
   opponent's sectors), hold discipline, stance honesty (aim on your loaded axis),
   aggression (raise and unleash timing).
3. Metrics: win rate by hand-category gap; knockout rate by pass; how often skill flips a
   numeric matchup; unleashed-trick win rate by trick; Score vs Seat finish ratio.
4. v2 of the sim: a reading model, so jack, color and held-trick tells get a value.
