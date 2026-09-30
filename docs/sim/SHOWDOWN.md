# The showdown problem

Sep 30, 2026. GAME_SPEC through decision 0052. A brief for Trey: it frames the problem, lays out
solution families, prototypes the strongest ones in the sim and recommends one. **Nothing here is
applied**, and none of it changes GAME_SPEC. The prototypes live behind `switches.showdown` in
`sim/Config.luau`, off by default; the current rules stay the default.

Numbers come from `tools/sim.luau`, 100k hands per run, seed 20260930: `--report showdown` for the
current rule and `--report proto` for the prototypes. "Flip" is how often a skilled rider beats a
novice in a numeric hand while holding the worse category (pillar 2). "Gap 1" is how often the
better category wins a numeric mirror hand at a gap of one step.

## How it works now

If no one is unhorsed after Pass 4, a knockdown is forced (§2 win condition 3, §4, 0014, 0050):

1. Each rider gets a hand bonus: 20 Posture per category step above high card.
2. The rider lower on Posture after the bonus falls, even above 0.
3. An exact tie goes to kickers, then a split.

## What the sim sees

Average vs average at the defaults, unless noted.

| Measure | Result |
| --- | --- |
| Hands that end at the showdown | 70% |
| Posture when the knockdown is forced | mean 57; the rider who falls has about 43 on average |
| Posture gap at the showdown | under 10: 25%, 10–20: 22%, 20–40: 28%, 40+: 25% |
| Category gap at the showdown | same category: 46%, one step: 46%, two or more: 9% |
| Showdowns where the bonus overturns the Posture leader | 13% (9% of all hands) |
| Showdowns where the Posture leader holds the worse hand | 24%; the cards win 53% of those |
| The standing projected at the river reveal (Posture + bonus, before Pass 4's contact) holds | 69% when the margin is under 20; 90% at 20 or more |

The bonus size, everything else at the defaults:

| Bonus per step | Posture leader wins the showdown | Cards win when leader and better hand differ | Gap 1 | Flip |
| --- | --- | --- | --- | --- |
| 0 (reference only) | 100% | 0% | 56% | 81% |
| 10 | 93% | 30% | 66% | 70% |
| **20 (0050)** | **87%** | **53%** | **74%** | **57%** |
| 30 | 83% | 68% | 80% | 45% |

## The problem, restated

Three things are bundled under "the showdown problem", and they need different fixes.

1. **A budget problem.** Four passes deal about half a Posture bar. A hand *can't* end by the
   lance most of the time, so the rule that ends it does most of the ending: 7 hands in 10, with
   the faller still at about 43 Posture. This is the §11 numbers (Posture start, street
   multipliers, the last-pass bonus), not the showdown rule.
2. **A shape problem.** The cards' showdown weight is an addition to a bar, in Posture units that
   never scale with anything else. So one number (20) sets the whole skill-vs-cards balance, and
   any change to damage elsewhere (0051, 0052) moves that balance without touching the number.
   The weight also has no body on screen: it is the only thing in the game that changes Posture
   without a lance.
3. **An information problem.** The deciding number appears after the last contact. The rider it
   overturns never saw it coming and had nothing to aim at. That is problem 6 in the old framing,
   and it is separable from 1 and 2: the same rule, shown five seconds earlier, plays differently.

Four pushbacks on the old framing:

- **The bonus being coarse (old problem 4) is a feature Trey chose.** "20, simple" (0050), and
  "riders in the same category get the same bonus, so Posture decides between them". The 46% of
  showdowns between riders in the same category are the showdowns the joust decides outright,
  which is pillar 2 working. A rank-within-category bonus would take those away and reopen
  0050's option C. Not proposed.
- **Family 4's tell cost was overstated.** The brief said a category-sized Pass 4 hit "runs into
  ambiguous tells". But the river lands on the final pass (0049), there is no bet after it, and
  the hand ends at Pass 4's contact. Nothing learned from the size of a Pass 4 hit can be used.
  The §11 question on hit size is about Passes 1–3. Family 4 is cleaner than the brief said.
- **70% is a ceiling, not the game.** The sim's riders never Yield. Real players fold to raises
  and the hands that reach the showdown are the ones both riders chose to ride out. 0051 also
  shows Trey's own dial on this: he asked for a *modest* last-round bonus, not a rout, so the
  target is probably "about half", not "rare".
- **The feel is half presentation.** §8 already sizes the fall to the gap ("a stagger and fall for
  a middling one"). Two of the candidates below change nothing in the rule and everything in how
  it lands.

### What the knockdown is for

Hold'em needs a showdown whenever nobody folds. The knockdown has three jobs: end the hand, let
the cards act (pillar 1), and be legible to a beginner. The current rule does all three, but as a
subtraction at the end. Every candidate below is a way of giving the cards' showdown weight a
body: a strike, a charge, or a bar the riders can see and aim at.

Other games with a hidden-information timeout point the same way. Fighting games decide a time-out
on the life bars, and it feels fair because the bars were visible all along and the rider behind
knew they had to attack. Auto-battlers (Teamfight Tactics) turn what's left standing into damage,
so the loser of a board fight is hit by the winner's survivors: the outcome has a body. Poker's
own showdown is the climax of the hand because the cards flip one at a time and everyone already
knows what each card would mean. In all three, the deciding number is either visible before the
end or arrives as a blow. Here it is neither.

## Constraints on any fix

- **Pillar 1:** "Hand strength acts through the riders' stats and, at showdown, forces the
  knockdown alongside Posture." Any fix that takes hand strength out of the knockdown needs Trey to
  reword the pillar. Each candidate below says whether it does.
- **0025:** the joust produces the result; no rule declares it.
- **0050:** Trey chose a fixed bonus per category over "the better hand wins unless far behind"
  and over "Posture plus every card's points". Those two are not reopened here.
- **Ambiguous tells:** nothing leaks the exact hand before the hand ends.
- **§6:** Siege (the full house's numeric side) says "the hand leans on the showdown knockdown".
  Board tricks and clashed tricks reach the showdown too.
- **Pillar 3:** a rider above the opponent who unleashes should still win virtually always. Every
  prototype reports the trick rates.
- **Learnability:** a beginner should be able to read who is winning. **Spectacle** and match
  length on Roblox, where a pass is 8 s, both count.

## Candidates

Each entry gives what a player sees, which pillars and constraints it fits or strains, its costs,
and how the sim tests it. Families 1–6 are from the first version of this brief; A–D are new.

### 1. Tune the bonus

Pick a number between 10 and 30. It trades gap 1 against the flip along the table above. Nothing
else changes. Config only, already swept.

### 2. Fewer showdowns: let the joust finish more hands

Make the four passes deal more of a rider's Posture. The levers are §11 values: Posture start, the
street multipliers, and the last-pass bonus.

- **In play:** more hands end with a rider knocked off, and the showdown becomes the close-call
  ending. Every hit matters more.
- **Fits** everything as written; it is tuning.
- **Cost:** tricks fired on Pass 4 win less, because the numeric rider's out (unhorse the trick
  rider on the same contact, §6) widens as every hit grows. Posture 70 also starts to end hands on
  Pass 3, before the river. The showdown rule itself is unchanged, just asked less often.
- **Sim:** config, in the table below.

### 3. The final charge: make the showdown a joust

If no one falls after Pass 4, the hole cards turn face up, each rider's hand bonus lands on their
bar, and the riders make one more charge. Whoever is unhorsed in it loses; if no one is, the lower
Posture falls.

- **In play:** "Nobody fell? Cards up. One last charge." Both riders can see exactly what they
  need. The rider behind after the bonus has to land a big one; the rider ahead can guard. The
  ending is a lance, with everything on the table.
- **Fits** pillar 1 (the bonus forces the standing; the charge and then Posture finish it), 0025,
  spectacle. No tell problem: the cards are up because the hand is over bar the charge.
- **Cost:** about 8 s more on every hand that reaches it, which is 7 in 10 today. And the sim says
  the charge mostly confirms the standing: at Pass 4's multiplier it unhorses someone in 19% of
  charges and changes the winner in 17%. It is a new pass type to design and present, with no
  card reveal and no bet, and the fifth pass changes which pass a held trick can fire on if it is
  ever allowed to hold past Pass 4.
- **Sim:** `switches.showdown = charge`, with the charge's multiplier, whether the bonus lands
  before it, and whether readers see the cards, as `proto.charge*`.

### 4. The river carries the hand: the hand strikes on Pass 4

Drop the end-of-hand bonus or shrink it. On Pass 4, when the lances meet, each rider's hand strikes
too: a blow of N Posture per category step, scaled by the tier the rider's own lance landed (bigger
on a crit, smaller into a Guard). If no one falls, the lower Posture falls.

- **In play:** the river is where good cards hit hard, and only if you land. "Your pair rides
  with your lance." A pair that crits the exposure is a haymaker; a pair blocked into a Guard is a
  tap. The fall comes from the lance, and the knockdown just reads the bars.
- **Fits** 0025 and pillar 2 (the dial gates the cards). Pillar 1's "at showdown, forces the
  knockdown alongside Posture" is strained if the knockdown after the blows is Posture alone: hand
  strength then acts *on the showdown pass* through the strike, not at the knockdown. §2 already
  names Pass 4 "(showdown)", so the reading exists, but it is Trey's rewording to make. The hybrid
  below avoids it.
- **Tricks:** a numeric rider's blow can now take a trick rider down on the same contact, and the
  rider with more Posture before the pass wins (§2 win condition 2). That widens the numeric out
  and costs designed tricks 3–5 points. A ward reading fixes it: a rider firing a trick takes no
  hand blow, since the trick's hit *is* their hand strength. Simmed both ways.
- **Cost:** a second thing to explain about Pass 4 (the blow and its tier scaling). Siege's "the
  hand leans on the showdown knockdown" needs a decision: do the blows go through Siege's ×0.5?
  The sim leaves them outside it.
- **Sim:** `switches.showdown = riverHit`, with `proto.riverPerStep`, `proto.riverTier`,
  `proto.riverVsTrick` (lands or warded) and `proto.riverKnockdown` (Posture alone, or the bonus).

### 5. A showdown bet

A betting round after Pass 4's contact and before the reveal. Both riders see the bars, their own
hand and the board. A rider well ahead on Posture decides whether their lead beats the other hand's
possible bonus; a rider behind with a pair can raise. Beginner-ignorable, like all betting.

- **Changes** what the pot is worth, not who falls. It addresses the information problem, since
  the moment before the reveal becomes a read, and it is poker.
- **Cost:** 5 s or more on every showdown hand; 0049 chose no bet after the river, so this reopens
  it. **Not sim-able as is:** the sim's riders never Yield, so it can't value a bet.
- It composes with any of the others and can come later.

### 6. Reshape the bonus: multiply instead of add

Posture × (1 + m per step) instead of Posture + 20 per step.

- **In play:** good cards amplify how well you jousted. A battered rider gains little from a pair.
- **Sim result:** it is the same rule with a different number. m = 0.5 sits where 20 sits today and
  m = 0.2 where 10 does, with the same 70% showdown share, and it is harder to explain on screen.
  Not recommended on its own.

### A. Cards up at the river (new): show the standing at the reveal, apply it after contact

Keep the rule exactly as it is, and show it five seconds earlier. When the river flips at 3.0 s of
Pass 4, each rider's hand bonus appears on the bars ("PAIR +20", "TWO PAIR +40") and the standing is
drawn: who falls if nobody is unhorsed at contact, and by how much. The bonus is still applied
after contact.

- **In play:** the last five seconds of the hand are fought in the open. "You're 15 behind. Land a
  crit or you fall." The rider ahead guards; the rider behind must attack. A kid can read the bars
  and knows exactly what to do. The reveal keeps its beat, because the fall is still sized to the
  gap and the standing can still be overturned by the contact.
- **What it costs in secrets:** the category is shown at the river instead of after contact. That
  is not the exact hand (a pair of aces and a pair of sevens both read "PAIR"), and nothing after
  the river can use it: no bet follows (0049) and the hand ends at contact. But it is more than a
  partial tell, and it pre-announces a trick that would auto-fire ("STRAIGHT +80" at 3.0 s); the
  §6 rule that a held trick shows only at contact would need to say so. Trey's call.
- **Fits** pillar 1 verbatim, 0025, learnability, spectacle. Costs no time and no new pass.
- **Sim:** the reader model can't act on a shown standing, so the sim can only say how often the
  standing shown at the river is overturned by Pass 4's contact: 31% of the time at a margin
  under 20, 10% at 20 or more (under the current rule). That is the share of "cards up" showdowns
  where the last exchange is still live.

### B. The reveal blow (new, presentation only): the bonus lands as a hit

Numerically the current rule, shown as a strike. At the showdown, cards up, and the better hand
*strikes* the other rider for the difference in bonuses ("TWO PAIR beats PAIR: 20"), with the fall
sized to what's left. Posture + 20 for me against Posture + 40 for you is the same comparison as
me taking a 20 blow from you.

- **In play:** the cards do something a lance does. It replaces "a number appears on my bar" with
  "their hand hit me", which is the poker reveal as a joust beat. It uses the setup/counter system
  as is.
- **Fits** everything; it changes no outcome. It needs the §8 *Showdown* paragraph reworded (the
  bonus "pours into" the bar today).
- **Sim:** nothing to measure. It is listed because the feel problem is half presentation, and
  because family 4 is this idea made real: the blow lands at contact and can unhorse.

### C. The hybrid: the hand strikes on the river, and still counts at the knockdown

Family 4 with a smaller knockdown bonus kept: on Pass 4 the hand strikes with the lance (N per step
by tier), and if nobody falls, each hand's bonus (M per step) lands and the lower Posture falls.
One idea, "your hand strikes", twice: once through the lance, once flat at the end.

- **In play:** as family 4, but a hand that gets blocked on the river still counts for something
  at the end, and a trick that failed to unhorse still carries its weight to the knockdown.
- **Fits** pillar 1 verbatim: hand strength still forces the knockdown alongside Posture. 0025.
  With the ward reading, tricks keep their rates.
- **Cost:** two per-step numbers instead of one. If they are the same number, it reads as "your
  hand is worth N a step; it strikes on the river, and lands again at the end if nobody fell".
- **Sim:** `riverHit` with `proto.riverKnockdown = bonus`.

### D. Rejected, and why

- **Hand strength as visible Posture from the street it's made** (a pair on the flop adds 20 to
  your bar then and there). Beginner-readable, but it leaks the category on every street. Breaks
  ambiguous tells.
- **The reveal blow before Pass 4's contact** (the hand strikes at the river reveal, at 3.0 s).
  A rider at 30 Posture facing trips is unhorsed by a card comparison before any lance. 0025.
- **The better hand takes part of the pot.** Splitting a pot by hand strength while the joust
  picks the faller is a card comparison paying out. Pillar 1 says a bare comparison only breaks
  exact ties.
- **Snowball damage** (hits grow as Posture drops) to force more unhorses. It ends hands, but by
  punishing the rider already behind, and it makes the early passes matter less, not more.

## Prototype results

`lune run tools/sim.luau --report proto`, 100k hands per run, seed 20260930. Columns:

- **sd:** hands ending at the forced knockdown.
- **KO P3 / P4 / P5:** unhorses by pass (Pass 1 is 0.0% everywhere, Pass 2 0.7%).
- **gap 1 / 2 / 3:** the better category wins a numeric mirror hand at that gap.
- **flip:** the skilled rider beats the novice with the worse category.
- **above/design, above/off:** tricks fired above the opponent, played to design or not.
- **over:** the hand's showdown effect (bonus, blows, the charge) overturns the rider ahead on
  Posture after Pass 4's dial exchange.
- **proj close / clear:** the rider ahead on the standing projected at the river reveal wins, at a
  margin under 20 / of 20 or more. 100 minus this is how live the last exchange is under
  candidate A.
- **charge KO / flip:** the fifth contact unhorses someone / changes the winner, as a share of
  charges.
- **passes:** mean passes per hand (match length).

### The current rule and its tuning (families 1, 2, 6)

| Config | sd | KO P3 / P4 | gap 1 / 2 / 3 | flip | above/design | above/off | over | proj close / clear | passes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| **bonus 20 (0050)** | **70.3%** | 3.1 / 25.8 | 74.2 / 86.4 / 92.5 | 56.8% | 96.8% | 92.2% | 12.9% | 68.8 / 90.2 | 3.95 |
| bonus 20, Posture start 70 | 49.1% | 8.3 / 41.9 | 71.0 / 81.2 / 82.7 | 60.6% | 92.2% | 84.6% | 15.5% | 68.8 / 88.5 | 3.90 |
| bonus 20, last-pass bonus 2.0 | 53.3% | 3.1 / 42.9 | 69.4 / 79.7 / 86.5 | 63.1% | 93.0% | 85.3% | 13.5% | 65.2 / 84.8 | 3.95 |
| bonus 10, last-pass bonus 2.0 | 53.3% | 3.1 / 42.9 | 62.9 / 72.8 / 80.6 | 73.8% | 93.0% | 83.6% | 7.7% | 66.0 / 85.1 | 3.95 |
| mult 0.2 | 70.3% | 3.1 / 25.8 | 65.1 / 75.7 / 82.5 | 70.1% | 96.8% | 90.3% | 6.8% | 66.8 / 87.4 | 3.95 |
| mult 0.35 | 70.3% | 3.1 / 25.8 | 69.7 / 80.1 / 86.9 | 63.1% | 96.8% | 91.0% | 9.8% | 65.5 / 86.9 | 3.95 |
| mult 0.5 | 70.3% | 3.1 / 25.8 | 72.6 / 82.7 / 89.2 | 57.7% | 96.8% | 91.3% | 11.6% | 64.2 / 86.5 | 3.95 |

- **Family 2 buys showdowns with tricks.** Posture 70 or a ×2.0 last pass halves the showdown
  share, and costs auto-fired tricks 4–8 points, because every numeric hit that lands on a trick
  rider on Pass 4 is bigger. Posture 70 also ends 8% of hands on Pass 3, before the river.
- **The multiplicative bonus is the additive one in disguise.** Same 70%, same trade-off curve.

### The hand strikes on the river (family 4 and the hybrid C)

Tier factors 1.5 on a crit, 1 on a Normal, ¼ into a Guard or from Neutral, unless noted. "Warded"
means a rider firing a trick takes no hand blow.

| Config | sd | KO P3 / P4 | gap 1 / 2 / 3 | flip | above/design | above/off | over | proj close / clear |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| riverHit 10, Posture alone decides | 58.6% | 3.1 / 37.5 | 62.8 / 71.0 / 80.4 | 75.3% | 94.3% | 83.9% | 9.3% | 64.5 / 81.6 |
| riverHit 15 | 52.0% | 3.1 / 44.1 | 64.6 / 73.2 / 84.1 | 72.4% | 93.2% | 81.6% | 12.2% | 64.4 / 80.3 |
| riverHit 20 | 45.4% | 3.1 / 50.7 | 65.8 / 74.4 / 86.1 | 70.2% | 91.9% | 79.7% | 14.4% | 64.7 / 79.7 |
| riverHit 30 | 35.2% | 3.1 / 60.9 | 67.4 / 76.3 / 88.4 | 66.3% | 90.4% | 77.2% | 17.5% | 66.0 / 79.5 |
| riverHit 20, tiers 2 / 1 / 0 | 39.5% | 3.1 / 56.6 | 63.0 / 69.9 / 81.2 | 73.0% | 91.2% | 78.5% | 15.0% | 65.0 / 77.1 |
| riverHit 20, flat (the reveal blow) | 51.4% | 3.1 / 44.7 | 73.8 / 86.4 / 93.7 | 57.4% | 91.9% | 81.6% | 13.5% | 66.3 / 85.9 |
| riverHit 20, Posture start 70 | 23.7% | 8.3 / 67.3 | 63.5 / 71.0 / 79.5 | 73.6% | 87.7% | 72.8% | 16.6% | 69.7 / 84.9 |
| riverHit 10, warded | 58.6% | 3.1 / 37.5 | 62.8 / 71.0 / 80.4 | 75.3% | 96.8% | 87.6% | 9.3% | 64.1 / 81.0 |
| riverHit 15, warded | 52.0% | 3.1 / 44.1 | 64.6 / 73.2 / 84.1 | 72.4% | 96.8% | 87.7% | 12.2% | 63.8 / 79.5 |
| riverHit 20, warded | 45.4% | 3.1 / 50.7 | 65.8 / 74.4 / 86.1 | 70.2% | 96.8% | 87.8% | 14.4% | 63.8 / 78.7 |
| riverHit 20 + bonus 10 at the knockdown | 45.4% | 3.1 / 50.7 | 71.0 / 81.6 / 92.4 | 61.1% | 92.0% | 82.3% | 17.0% | 64.5 / 85.6 |
| riverHit 10 + bonus 10 | 58.6% | 3.1 / 37.5 | 69.8 / 81.0 / 91.0 | 64.6% | 94.3% | 86.8% | 13.2% | 65.3 / 87.3 |
| riverHit 10, warded + bonus 10 | 58.6% | 3.1 / 37.5 | 69.8 / 81.0 / 91.0 | 64.6% | 96.8% | 90.8% | 13.3% | 65.5 / 87.5 |
| riverHit 15, warded + bonus 10 | 52.0% | 3.1 / 44.1 | 70.6 / 81.6 / 92.2 | 62.7% | 96.8% | 90.8% | 15.4% | 65.1 / 86.6 |
| **riverHit 15, warded + bonus 15** | **52.0%** | 3.1 / 44.1 | **73.3 / 84.7 / 93.7** | **57.5%** | **96.8%** | **91.6%** | 16.8% | 64.7 / 87.5 |
| riverHit 15, warded + bonus 20 | 52.0% | 3.1 / 44.1 | 75.7 / 87.1 / 95.5 | 52.8% | 96.8% | 92.1% | 18.4% | 64.1 / 88.1 |
| riverHit 20, warded + bonus 10 | 45.4% | 3.1 / 50.7 | 71.0 / 81.6 / 92.4 | 61.1% | 96.8% | 90.8% | 17.0% | 64.9 / 86.0 |
| riverHit 20, warded, flat + bonus 10 | 51.4% | 3.1 / 44.7 | 79.1 / 91.0 / 96.3 | 46.0% | 96.8% | 90.9% | 17.0% | 68.7 / 91.9 |

What the river-hit rows show:

1. **The blow ends hands without the trade family 2 makes.** At 15 per step the showdown share
   is 52%, the same as a ×2.0 last pass, but it comes from the cards rather than from every hit,
   and with the ward reading designed tricks stay at exactly their current 96.8%.
2. **The tier scaling is the skill.** The flat blow (a 20 blow whatever you land) reproduces the
   current balance exactly (gap 1 73.8%, flip 57.4%), just with the fall coming from a hit. Scaled
   by tier, the same 20 gives gap 1 65.8% and flip 70.2%: the cards count when you land them.
3. **Posture alone at the knockdown drops the cards too far** (gap 1 63–66%, under the 66% of
   bonus 10) and strips a failed trick of its weight: a flush fired off its home wins 56% of the
   time instead of 91%. Keeping a small knockdown bonus fixes both, which is the hybrid.
4. **The hybrid at 15 + 15 keeps today's balance with half the showdowns.** Gap 1 73.3% and flip
   57.5% are the 0050 numbers (74.2% and 56.8%); the showdown share is 52% instead of 70%;
   designed tricks stay at 96.8% and off-design tricks at 91.6% (92.2% today); the last exchange
   overturns a close standing 35% of the time. The hand's effect overturns the after-Pass-4
   Posture leader in 17% of showdowns, against 13% today. 15 + 10 tilts the same shape toward
   skill (gap 1 70.6%, flip 62.7%) and 15 + 20 toward the cards (75.7%, 52.8%): the knockdown
   bonus is the balance knob, and the blow is the ending knob.
5. **Where the blow's Posture goes.** A pair on a Normal is 15, on a crit 22; trips on a crit is
   67. That is the size of a good Pass 4 crit (§4's check gives 71), so the cards on the river hit
   like a well-read lance, no more.

### The final charge (family 3)

The bonus lands on the bars before the charge, and the cards are up, unless noted. The charge's
multiplier is Pass 4's (×1.625) unless noted.

| Config | sd | KO P4 / P5 | gap 1 / 2 / 3 | flip | above/design | above/off | over | charge KO / flip | passes |
| --- | --- | --- | --- | --- | --- | --- | --- | --- | --- |
| charge, bonus up, cards up | 57.4% | 25.6 / 13.1 | 70.1 / 82.3 / 89.5 | 66.7% | 96.4% | 92.2% | 24.4% | 18.6 / 17.4 | 4.66 |
| charge, bonus up, cards down | 57.1% | 25.6 / 13.4 | 70.1 / 82.3 / 89.5 | 66.6% | 96.4% | 92.2% | 24.4% | 19.0 / 17.3 | 4.66 |
| charge, bonus up, ×2.5 | 44.1% | 25.6 / 26.4 | 68.2 / 79.2 / 85.7 | 68.7% | 96.4% | 91.9% | 27.4% | 37.5 / 21.0 | 4.66 |
| charge, no bonus, cards up | 44.9% | 25.6 / 25.7 | 55.5 / 60.0 / 66.5 | 83.7% | 96.4% | 88.1% | 18.4% | 36.4 / 18.4 | 4.66 |
| charge, hand blows on the charge (20) | 23.4% | 25.6 / 47.1 | 62.2 / 69.7 / 81.5 | 77.3% | 96.4% | 90.0% | 21.8% | 66.8 / 21.8 | 4.66 |
| charge, hand blows on the charge (10) | 32.7% | 25.6 / 37.9 | 60.0 / 66.8 / 77.2 | 80.1% | 96.4% | 89.8% | 21.5% | 53.7 / 21.5 | 4.66 |
| charge, bonus up, Posture start 70 | 33.5% | 41.8 / 15.6 | 67.3 / 77.6 / 84.0 | 68.8% | 92.0% | 84.5% | 28.2% | 31.8 / 19.3 | 4.39 |

What the charge rows show:

1. **The fifth pass mostly confirms the standing.** With the bonus on the bars, the charge changes
   the winner in 17% of charges (12% of all hands) and unhorses someone in 19%. Seven hands in
   ten pay 8 s for it. At ×2.5 it unhorses in 38% and flips 21%.
2. **Tricks are safe** (96.4% / 92.2%): the charge comes after every trick has fired.
3. **Cards up makes no difference in the sim**, because its reader only ever does one late switch.
   In the real game, exact stats for one exchange are worth more than that.
4. **Without the bonus the cards vanish** (gap 1 55.5%): the stats alone can't carry pillar 1.
   Blows on the charge (family 4 moved to a fifth pass) end hands but at 18% more match length.

The charge with the bonus up and cards up is candidate A with an extra pass. The sim's numbers for
"how live is the last exchange" are close to the same for both (the standing at the river is
overturned 31% / 10% by Pass 4's contact; the standing before the charge is overturned 17% by the
charge). A costs nothing; 3 costs a pass.

## Recommendation

**The hybrid C, warded, with candidate A as its presentation**: the hand strikes on the river with
the lance, scaled by the tier landed; if nobody falls, a smaller bonus lands and the lower rider
falls; and the standing is shown at the river reveal so the last five seconds are fought in the
open. Starting numbers: one number, 15 per step, for both the blow (×1.5 crit, ×1 Normal, ×¼ Guard
or Neutral) and the knockdown bonus; a firing trick takes no blow. That reads as "your hand is
worth 15 a step: it strikes with your lance on the river, and lands again at the end if nobody
fell".

Why this one:

- It fixes all three problems at once. The budget: half as many showdowns (52%), and the extra
  damage comes from the cards, not from inflating every hit. The shape: most of the cards' weight
  now lands in damage units, through the dial, so the balance moves with the rest of the game
  instead of sitting in one Posture number. The information: the rider behind at the river knows
  it, has a target, and the blow that beats them is a lance.
- It keeps pillar 1's words. Hand strength acts through the stats, strikes on the showdown pass,
  and still forces the knockdown alongside Posture. 0025 holds: the fall comes from contact in 48%
  of hands and from Posture plus a bonus in the rest, as now.
- It keeps the balance Trey set in 0050 (gap 1 73%, flip 58%) while halving the showdowns, and
  the balance knob (the knockdown bonus) is separate from the ending knob (the blow).
- Tricks are untouched when warded: 96.8% designed, 91.6% off design, 98–100% across rungs.
- It costs no time and no new pass type. It costs one more sentence in the Pass 4 explanation.
- Beginners: the bars show the standing at the river; a kid sees "I'm behind, I need to land a
  crit". A bad hand is still a handicap, not a fold (flip 58%, as today).

Runner-up: **the final charge (family 3), bonus up and cards up, at ×2.5.** It is the only design
where the ending is literally a joust, tricks are untouched, and it needs no pillar wording. It
costs 8 s on about half of hands, and the sim says the pass changes the winner about one time in
five. Take it if the spectacle of a declared last charge is worth the length; the hybrid gives most
of the same play inside Pass 4.

Fallback available today, config only: **last-pass bonus ×2.0 with candidate A.** Showdowns 53%,
but tricks pay 4–7 points and the balance drifts toward skill (flip 63%) without any card-driven
reason.

Not recommended: the bonus size alone (family 1), the multiplicative bonus (6), Posture start 70
(the Pass 3 knockouts cut the river), and river blows with Posture alone at the knockdown (the
cards drop too far and a failed trick is stranded).

### What Trey would decide

1. **The target.** Is about half of hands ending at the knockdown right? The sim's riders never
   Yield, so the real share will be lower than any number here.
2. **The shape.** Does the hand strike on the river (C), or stay a bonus at the end (A alone, or
   A with family 2)?
3. **Cards up at the river.** Show the standing at 3.0 s of Pass 4, or keep the reveal for after
   contact? This also decides whether an auto-firing trick is pre-announced at the river.
4. **The ward reading.** Does a rider firing a trick take a hand blow? Recommended: no.
5. **The numbers**, as §11 rows, "Proposed, needs sim": blow per step, tier factors, knockdown
   bonus per step. 15 / (1.5, 1, ¼) / 15 are starting values; 15 + 10 and 15 + 20 in the table
   show the knockdown bonus moving the balance without moving the showdown share.
6. **Siege.** Do the hand's blows go through Siege's ×0.5, and what does "the hand leans on the
   showdown knockdown" mean once the hand also strikes?
7. **The runner-up's questions**, if he takes the charge instead: the charge's multiplier, whether
   a bet precedes it, and what a held trick may do with a fifth pass.

### GAME_SPEC wording the recommendation touches (not edited here)

- **§1 pillar 1:** unchanged. (Pure family 4, with Posture alone at the knockdown, would need
  "forces the knockdown alongside Posture" reworded.)
- **§1 Status:** "Contact resolution, Posture and the showdown knockdown" stays "Proposed, needs sim".
- **§2 *Sequence*:** the Pass 4 row ("river reveals mid-charge; unused tricks auto-fire; then the
  showdown") gains the hand's blow at contact. **Win condition 3:** the bonus size and the blow.
- **§3 *Public vs hidden*** and **§7 *Post-pass reveal*:** if the standing is shown at the river,
  the category is public from the river reveal, and the hole cards still only at hand end.
- **§4 *Contact resolution*:** a step for the hand's blow on Pass 4 (after step 6). **§4 *Tracks
  and showdown*:** the blow, the smaller bonus, the fall.
- **§6 *The ward*:** a rider firing a trick takes no hand blow. ***Unleash rules*:** whether an
  auto-firing trick shows at the river reveal. ***Board-made tricks*:** Siege's clause.
- **§8 timeline and *Showdown*:** the standing shown at 3.0 s on Pass 4; the blow at 8.0 s; the
  §8 *Showdown* paragraph ("pours into their Posture bar") becomes the blow and the smaller bonus.
- **§11 parameter table:** "Showdown hand bonus" becomes three rows (blow per step, tier factors,
  knockdown bonus per step).

## Limits of these numbers

- **The riders never Yield**, so every showdown share is a ceiling and betting is unvalued.
- **The reader model is one late switch at 7.4 s** against an estimate of the opponent's stats. It
  can't respond to a shown standing, so candidate A is measured only by how often the standing
  is overturned, not by what riders do about it. Real reads are likely stronger, which makes
  every "the last exchange is live" number an underestimate.
- **Trick rates come from thousands of straights and flushes but tens of straight flushes.**
- **Every prototype value is a starting value.** The tier factors in particular were picked, not
  swept, beyond the two rows above (flat, and 2 / 1 / 0).
