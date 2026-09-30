# The showdown problem

Sep 30, 2026. GAME_SPEC through decision 0052. A brief for Trey: it frames the problem and lays
out solution families. **Nothing here is applied**, and none of it changes GAME_SPEC.

Numbers come from `lune run tools/sim.luau --report showdown`, 100k hands per run, seed 20260930.
"Flip" is how often a skilled rider beats a novice in a numeric hand while holding the worse
category (pillar 2). "Gap 1" is how often the better category wins a numeric mirror hand at a
gap of one step.

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

The bonus size, everything else at the defaults:

| Bonus per step | Posture leader wins the showdown | Cards win when leader and better hand differ | Gap 1 | Flip |
| --- | --- | --- | --- | --- |
| 0 (reference only) | 100% | 0% | 56% | 81% |
| 10 | 93% | 30% | 66% | 70% |
| **20 (0050)** | **87%** | **53%** | **74%** | **57%** |
| 30 | 83% | 68% | 80% | 45% |

## The problem, as a whole

1. **Most hands end without a lance.** Seven hands in ten end at the forced knockdown, and the
   rider who falls still has about 43 Posture. The joust's damage over four passes is about half a
   rider's Posture, so the showdown is the main way a hand ends, not a fallback. Pillar 1 says
   outcomes come from the joust, and §1 names spectacle. Most climaxes are a bar filling up.
2. **The bonus is most of what the cards are worth.** With no bonus, the better category wins
   only 56% at a gap of 1. The stat edges are modest by design (pillar 2), so the showdown bonus
   carries most of the cards' weight. Taking it away is not an option under pillar 1 either: the
   pillar names hand strength at the showdown.
3. **One number holds the balance between skill and cards.** Each 10 per step moves the flip by
   about 12 points: 70%, 57%, 45%. Changes elsewhere move it too. 0052 took it from 67% to 57%
   without touching the bonus. The balance can't be tuned in one place and then left alone.
4. **The bonus is coarse.** Nearly half of all showdowns (46%) are between riders in the same
   category, where it does nothing. Almost all the rest are one step apart, so in practice the
   bonus means "the better category gets +20". A pair of twos counts the same as a pair of aces.
5. **It decides the close races.** Nearly half of all showdowns (46%) are within 20 Posture, one
   step. There, the result is mostly the category comparison, not the joust.
6. **How it feels.** A rider who visibly won the joust, well ahead and far from 0, falls to a
   number that appears at the end. Done well, that is the poker reveal and a comeback moment.
   Done badly, it is "I was winning!" For kids, the difference is whether they could see it
   coming and could have played around it.

## Constraints on any fix

- **Pillar 1:** "Hand strength acts through the riders' stats and, at showdown, forces the
  knockdown alongside Posture." Any fix that takes hand strength out of the showdown needs Trey to
  reword the pillar.
- **0025:** the joust produces the result; no rule declares it.
- **0050:** Trey chose a fixed bonus per category over "the better hand wins unless far behind"
  and over "Posture plus every card's points". Those two are not reopened here.
- **Ambiguous tells:** nothing leaks the exact hand before the hand ends.
- **§6:** Siege (the full house's numeric side) says "the hand leans on the showdown knockdown".
  Board tricks and clashed tricks reach the showdown too.
- **Learnability:** a beginner should be able to read who is winning.

## Solution families

Each family works on a different part of the problem. They can be combined.

### 1. Tune the bonus (the bandaid)

Pick a number between 10 and 30. It trades gap 1 against the flip along the table above.
Problems 1, 3, 4 and 5 stay as they are. Config only.

### 2. Fewer showdowns: let the joust finish more hands

Make the four passes deal more of a rider's Posture, so more hands end with a real unhorse.
The levers are the §11 values: Posture start, the street multipliers, and the last-pass bonus.

| Change | Hands ending at the showdown | KO on Pass 3 / Pass 4 | Gap 1 | Flip |
| --- | --- | --- | --- | --- |
| Defaults | 70% | 3% / 26% | 74% | 57% |
| Posture start 70 | 49% | 8% / 42% | 71% | 61% |
| Posture start 50 | 29% | 22% / 48% | 67% | 65% |
| Last-pass bonus ×2.0 | 53% | 3% / 43% | 69% | 63% |

- **In play:** more hands end with a rider knocked off, and the showdown becomes the close-call
  ending, not the usual one. Every hit matters more.
- **Cost:** tricks fired above the opponent win less at Posture 50 (89% vs 97%), and Pass 3
  knockouts start to cut the river short. The bonus question stays, just asked less often.
- **Sim-able now** as config.

### 3. The final charge: make the showdown a joust

If no one falls after Pass 4, the hole cards turn face up, and each rider's hand bonus lands as
now. Then the riders make one more charge, and the result comes from that contact.

- **In play:** "Nobody fell? Cards up. One last charge." The better hand has an edge that everyone
  can see, and the rider behind knows exactly what they need. The dial decides the ending, with
  everything on the table. It's a spectacle beat.
- **Fits** pillar 1 (hand strength forces it, through the joust), 0025 and spectacle.
- **Open design questions:**
  - Is the bonus Posture as now, or does it act through the charge (armor, strike)?
  - Does the charge carry a multiplier?
  - What happens if no one falls again: a repeat, or Posture decides?
  - Is there a bet before it?
  - How long is the charge?
- **Cost:** about 8 s more on the hands that reach it. With family 2 that's about half of hands,
  not seven in ten. It is also a new pass type to design and present.
- **Sim-able** with new code: a fifth contact after Pass 4.

### 4. The river pass is the showdown: move hand strength into Pass 4

Drop the end-of-hand bonus. Once the river flips mid-charge on Pass 4, each rider's hand category
multiplies their Pass 4 hit or Guard. The knockdown after Pass 4 is then Posture alone.

- **In play:** the last charge is where good cards hit hard. The fall comes from the lance, and
  the showdown just reads the Posture bars, which a beginner can follow.
- **Cost:** hit size is public, so a big Pass 4 hit points at a category. That runs into
  ambiguous tells and the §11 open question on hit size. The forced knockdown also stays a
  bookkeeping step. This needs pillar 1's "at showdown" wording looked at.
- **Sim-able** with small code.

### 5. A showdown bet: make reaching the showdown a poker decision

Add a betting round after Pass 4's contact and before the reveal. Both riders can see the
Posture bars, their own hand and the board, but not the opponent's hole cards. Hold'em has a
river bet; this game doesn't yet.

- **In play:** a rider well ahead on Posture has to decide if their lead beats the other hand's
  possible bonus. A rider behind with a pair can raise. The bonus stays, but the moment before it
  becomes a read, and a Yield or a raise there is poker. It is beginner-ignorable, like all
  betting: just Stay.
- **Doesn't change** who wins the knockdown, only what the pot is worth. It addresses problem 6,
  not 1–5.
- **Not sim-able as is:** the sim's riders never Yield, so it can't value a bet.

### 6. Reshape the bonus

The bonus multiplies Posture instead of adding to it: for example, Posture × (1 + 0.2 per step).

- **In play:** good cards amplify how well you jousted. A battered rider gains little from a
  pair, and a rider who jousted well and holds the better hand is hard to catch.
- **Cost:** still one number, with the same coarse steps. It also needs to be explained on screen.
- **Sim-able** with a small code change.

## Recommendation

**2 with 3**, simulated before anything is decided.

- **Family 2** is config only. It moves the showdown from the usual ending (70%) toward about
  half of hands.
- **Family 3** is the only family where the ending is still a joust. It keeps hand strength in
  the knockdown the way pillar 1 says, and it gives the showdown a moment on screen.
- **Family 5** can come later on its own, when betting gets a model.
- **The bonus size** (family 1) is worth re-tuning only once the structure is set.

## Questions for Trey

1. Is the problem as framed here the right one? Which of 1–6 under *The problem* matter most to
   you?
2. Which families should the sim try? 2 is ready now; 3, 4 and 6 need code.
3. For 3: face-up cards before the final charge, yes or no?
