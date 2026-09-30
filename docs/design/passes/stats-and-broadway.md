# Design pass: stats, broadway cards and the tricks built on them

Started Sep 30, 2026, in chat with Trey. A working record of his calls, pass by pass. Nothing here
is in GAME_SPEC yet: when the pass settles, each call becomes a decision in
[decisions/](../decisions/README.md) and GAME_SPEC is updated in the same PR (WORKFLOW.md).

Trey's framing: "Design via concept, fantasy, game and skill expression is more important than any
existing balance findings." Earlier decisions (through 0066) stay as history; this pass may
supersede them.

Scope, in Trey's order:

1. What the four suits/stats do.
2. The theme and function of the broadway cards, mapped onto the suits.
3. The effects of single broadway cards and their pairs and trips.
4. The flushes and straights built from these concepts.

## 1. The four stats (Trey's calls, Sep 30)

Trey's model: "strength increases damage, moreso when you aim … accuracy increases armor
penetration always, makes critting easier+better in ways, moreso when you aim. armor increases
armor reduction always, makes blocking easier+better in ways, moreso when you aim. posture
increases health, aiming gives health before contact, but heals after contact always."

Each offense stat mirrors a defense stat: Strength ↔ Posture (damage vs health), Accuracy ↔ Armor
(penetration vs reduction, crits vs blocks).

| Stat | Always | When you aim at it |
| --- | --- | --- |
| ♣ Strength | More damage | More damage, and the hit leaves the target taking +x% damage (below) |
| ♠ Accuracy | Armor penetration; crits need less hold to reach full power, and hit bigger | More of both, and extra time past the aim lock |
| ♦ Armor | Armor reduction; the Guard needs less hold to reach full armor, and blocks harder | More of both, and extra time past the aim lock |
| ♥ Posture | Health: max Posture grows with ♥. After every contact you heal a share of the damage that contact dealt you, growing with ♥ | Health before contact: a buffer that absorbs this contact's damage first |

Details Trey chose:

- **♣ condition (working name "Battered").** Trey: "aimed club hits inflict a '+x% damage taken'
  condition on the target … its the simplest way to get the best of both worlds of now + later".
  - Lasts through the target's next contact. A new aimed ♣ hit refreshes it; it doesn't stack.
  - Any aimed ♣ hit that deals damage applies it. A clean Block (nothing gets through) doesn't.
- **Easier crits and blocks.** Always, scaled by points: less hold needed. When aimed: extra time
  past the aim lock, sized by the lean; when both riders lean into Accuracy or Armor, the extra
  times offset. Wider zones are left to the face cards (the Ace's crit zone, possibly the King's
  Guard).
- **♠ charge dropped.** 0015's pay-later charge goes; ♣ owns "later" through its condition.
- **♥ heal** is a share of the damage taken on that contact, not a flat amount.
- **Everyone starts at 80 Posture.** ♥ raises max Posture, so you can heal above 80, but it
  doesn't raise the start. Your ♥ shows only once you heal, and a heal has more than one cause
  (pillar 4).

Stat names in Trey's words: Strength (♣), Accuracy (♠), Armor (♦), Posture (♥; also the name of
the health track).

Open: the numbers (x%, the heal share, the extra time, the hold relief) are sim values.

## 2. Broadway identities (Trey's calls, Sep 30)

Trey: "No home suits! Each broadway needs an IDENTITY but not a home. that identity can be
expressed in 4 wildly different ways - just an identity/common denominator."

- Each rank is an identity. Each of its four suits expresses it differently, through that suit's
  stat. There is no home suit and no "true face".
- Trey's brief: J needs a fresh pass, Q is support-like, K should be fun mechanically, A should lead
  to huge numbers in a fun way.
- **The Jack's signature is the Feint** (Trey chose it): leave your aim and return within a short
  window without losing hold.

## 3. Broadway effects removed (Trey's call, Sep 30)

Two drafts were rejected. The first was a 4×4 grid (one effect per rank per suit): "too many
effects added". The second was suit-blind: one effect per rank sized by count, plus a pair unlock
(the Feint, the Favor, the last word, crits ×1.5). Trey on the second: "im no longer confident
these broadway card effects are justified in the grand scheme. too much going on to make them cool
without them straight up revealing your cards".

The reason: any visible face effect is a tell with one cause (a heal at the start of a pass means
a Queen), so it can't meet §7's rule that every tell has at least two plausible causes.

Trey chose: **no broadway effects.** J, Q, K and A are the top of the rank curve and add their
rank points to their suit's stat like any card (0036, 0039).

- §5's single, pocket-pair and board effects all go: J colors, Q restore, K lock, A crit base, JJ
  Masquerade, QQ Twin Favor, KK High Court, AA Champion. That supersedes 0055 and 0056.
- Board faces keep their arena emblems (§8) as presentation only.
- Pairs and trips need no design of their own: they are the numeric multipliers (§4).
- Faces could return in v2 as the favorite-rank class buffs (§10); that is not decided here.
- Trey's earlier choice of the Feint as the Jack's signature lapses with the effects.

## 4. Tricks built on the stats: next
