---
id: 0007
title: The standard dial carries all six outcomes, in half-step resolution
date: 2026-09-26
decided-by: trey (chat, §3 review session, 2026-09-26)
supersedes: []
superseded-by: null
---

## Context

The v1 dial (3-notch exposure, 1-notch Guard, 8 notches) produced only four of the six
pairings of crit, normal and block: CN, NN, CC and BB. The Guard could never win a one-sided
exchange (no NB), and no read landed a crit and a block at once (no CB). On 8 positions a dial
can carry at most five of the six, because the same position and the opposite position always
give mutual outcomes. Half-step resolution (16 positions) carries all six.

## Decision

- Keep all six outcomes. Trey: "KEEP ALL SIX. All interesting outcomes with CB."
- Aim resolves in half steps between the 8 directions, and sector widths are painted in the
  same half steps. Trey: "16 is false complexity. its just how wide the dial was decided to
  be painted ... the dial will be presented as 'snappy' granular, not as literal as 16 hard
  notches."
- The outcome table, as the baseline when both riders aim at random: CN 37.5%, NB 25%, CB
  12.5%, NN 12.5%, CC 6.25%, BB 6.25%.
- The same aim gives CC (crossed lances); opposite aims give BB (the clash).
- The standard layout, in half steps from your aim along the sweep: exposure 0–4, ordinary
  5–7, Guard 8, ordinary 9, Guard 10–12, ordinary 13–15. Sectors need not be contiguous.
- CB stays because Guard armor scales with hold (0010): a CB taken by a last-instant switch
  blocks weakly.
- One input still sets strike, exposure and Guard.

## Consequences

- §3 gains *Outcome table* and a rows-by-offset table; *Layout* and *Sectors* are rewritten.
- The §11 rows "Exposure / Guard / ordinary: 3 / 1 / 4 notches" and "Block leak factor"
  predate this layout. They are left as they are until Trey updates them.
- Notch counts in §5 (AA edge notch), §6 (Straight exposure, Fortress gap) and §10 (dial
  parameters) are revisited in those sections' reviews.
