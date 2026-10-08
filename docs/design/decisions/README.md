# Decisions

The record of design calls Trey has made that change or clarify [GAME_SPEC](../GAME_SPEC.md). The
process is in [WORKFLOW.md](../WORKFLOW.md), *Recording decisions*.

One file per decision, `NNNN-kebab-title.md`, numbered from `0001`:

```markdown
---
id: 0001
title: <the decision, in one line>
date: YYYY-MM-DD
decided-by: trey (<where: PR link, chat, date>)
supersedes: []
superseded-by: null
---

## Context
## Decision
## Consequences
```

Add a row below in the same commit. Check the latest `main` for the next free id first.

| id | title | date |
|----|-------|------|
| [0001](0001-game-spec-is-canonical.md) | GAME_SPEC is the canonical design; the PDF is history | 2026-09-26 |
| [0002](0002-tricks-climb-a-ladder.md) | Tricks are trump cards on a ladder, not "not auto-wins" | 2026-09-26 |
| [0003](0003-suits-are-stats-and-axes.md) | Suits are stats and axes; the four stats themselves are open | 2026-09-26 |
| [0004](0004-learnability-and-spectacle.md) | Learnability and spectacle are named as important | 2026-09-26 |
| [0005](0005-betting-alternates-one-hand-matches.md) | Betting alternates from the button; a match stays one hand | 2026-09-26 |
| [0006](0006-the-yard-and-prefolding.md) | Hand selection happens in the yard; results are graded in units | 2026-09-26 |
| [0007](0007-standard-dial-six-outcomes.md) | The standard dial carries all six outcomes, in half-step resolution | 2026-09-26 |
| [0008](0008-dial-input-timing-and-tells.md) | Dial input, hold, aim lock and public tells are clarified | 2026-09-26 |
| [0009](0009-seat-renamed-posture.md) | Seat is renamed Posture | 2026-09-26 |
| [0010](0010-the-four-stats.md) | The four stats are ♥ Posture, ♦ Armor, ♣ raw damage and ♠ crits | 2026-09-26 |
| [0011](0011-stats-reprice-tricks-rewrite.md) | Stats change what rows are worth; tricks change which rows exist | 2026-09-26 |
| [0012](0012-all-stats-act-aim-leans.md) | All four stats act all the time; aim leans into the stats it points at | 2026-09-26 |
| [0013](0013-pillar-5-reworded.md) | Pillar 5 reads "Suits are stats" | 2026-09-26 |
| [0014](0014-showdown-knockdown.md) | Score is removed; hand strength forces a knockdown at showdown | 2026-09-26 |
| [0015](0015-spade-charge.md) | ♠ non-crits build a hidden charge that the next crit spends | 2026-09-26 |
| [0016](0016-stat-compass.md) | The stat compass puts the black suits side by side; the lean total is fixed | 2026-09-27 |
| [0017](0017-pillar-1-reworded.md) | Pillar 1 lets hand strength force the showdown knockdown | 2026-09-26 |
| [0018](0018-unleash-above-wins-the-hand.md) | An unleashed trick above the opponent is built to win the hand on its pass | 2026-09-27 |
| [0019](0019-ladder-rungs-level-tricks-clash.md) | The ladder's rungs are trick categories; level tricks clash and the pass is numeric | 2026-09-27 |
| [0020](0020-cross-rung-tricks-both-apply.md) | Tricks on different rungs both apply; a contradiction goes to the higher trick | 2026-09-27 |
| [0021](0021-held-tricks-answer-unleashes.md) | A held trick answers an unleash from its own rung or below | 2026-09-27 |
| [0022](0022-held-posture-floor-removed.md) | The held-trick Posture floor is removed | 2026-09-27 |
| [0023](0023-unleash-announced.md) | Declaring an unleash announces its rung | 2026-09-27 |
| [0024](0024-held-and-unleash-rules-kept.md) | Ownership, riding as the sub-hand, passives, once per hand and auto-fire are kept | 2026-09-27 |
| [0025](0025-victory-through-the-joust.md) | Victory always comes through the joust; no rule declares it | 2026-09-27 |
| [0026](0026-trick-hit-sized-to-unhorse.md) | A trick's hit is sized to unhorse from full Posture on any pass | 2026-09-29 |
| [0027](0027-trick-ward.md) | A ward lets a higher trick beat a lower one through the numbers | 2026-09-29 |
| [0028](0028-trick-effects-draft.md) | Trick effects are rebuilt on the new dial as a starting draft | 2026-09-29 |
| [0029](0029-defensive-flushes-close-the-out.md) | The defensive flushes close the out | 2026-09-27 |
| [0030](0030-armor-sliver-on-exposure.md) | The exposure carries a sliver of armor, so ♠ piercing always has value | 2026-09-29 |
| [0031](0031-tricks-played-to-design.md) | A trick's hit unhorses when the trick is played to its design | 2026-09-29 |
| [0032](0032-straight-meter.md) | A straight's hit grows with a meter through its five cards | 2026-09-29 |
| [0033](0033-straight-flush-inherits-conditions.md) | The straight flush inherits both conditions, sized as strong as it needs | 2026-09-29 |
| [0034](0034-card-values.md) | Every revealed card adds its rank value to its suit's stat; board cards count for less | 2026-09-29 |
| [0035](0035-hands-multiply-card-values.md) | Poker hands multiply the points of the cards that make them | 2026-09-29 |
| [0036](0036-broadway-rank-value-on-top.md) | Broadway cards carry their rank value on top of their effects | 2026-09-29 |
| [0037](0037-lean-multiplies-card-points.md) | Aim lean multiplies what your cards give a stat; a stat meter shows it as you rotate | 2026-09-29 |
| [0038](0038-heart-lean-at-contact.md) | A ♥ lean acts at contact, cutting the Posture damage you take; max Posture ignores the lean | 2026-09-29 |
| [0039](0039-faces-stay-on-the-curve.md) | Face cards stay on the linear rank curve; their effects make them strong | 2026-09-29 |
| [0040](0040-board-made-arena-effects.md) | Board-made arena effects drop Score and the flush's stat bonus; arena multipliers are numeric only | 2026-09-29 |
| [0041](0041-board-trick-rung.md) | Riders playing the board's trick stand on its rung but can't unleash it | 2026-09-29 |
| [0042](0042-trick-lost-to-the-board.md) | A held trick the board plays over is lost; your hand is your current best five cards | 2026-09-29 |
| [0043](0043-trick-tuning-rows.md) | The §11 trick rows follow the rebuilt tricks | 2026-09-29 |
| [0044](0044-trick-win-targets.md) | The trick win-rate question becomes the sim's trick targets | 2026-09-29 |
| [0045](0045-gilded-mirror.md) | The ♦ flush is renamed Gilded Mirror | 2026-09-29 |
| [0046](0046-charge-clauses-dropped.md) | The Charge drops "can't be Blocked" and its widened exposure; the meter is its cost | 2026-09-30 |
| [0047](0047-straight-draws-hold.md) | The spec says outright that a straight draw pays for holding from the start of the charge | 2026-09-30 |
| [0048](0048-held-straight-passive-grows-with-hold.md) | A held straight's passive grows with hold on each pass | 2026-09-30 |
| [0049](0049-river-on-the-final-pass.md) | The river flips on the final pass; Pass 1 rides on hole cards | 2026-09-30 |
| [0050](0050-showdown-hand-bonus.md) | The showdown adds a hand bonus to Posture, and the lower rider falls | 2026-09-30 |
| [0051](0051-last-pass-bonus.md) | Pass 4 carries a ×1.3 last-pass damage bonus | 2026-09-30 |
| [0052](0052-hold-floor-0-25.md) | The hold floor is 0.25, so holding can beat a last-instant switch | 2026-09-30 |
| [0053](0053-the-river-always-goes-to-the-knockdown.md) | The river always goes to the knockdown, and Posture below 0 counts | 2026-09-30 |
| [0054](0054-hand-shape-and-damage-retune.md) | Posture 80, flat early street multipliers, and no last-pass bonus | 2026-09-30 |
| [0055](0055-twin-favor-stops-a-trick-hit.md) | Twin Favor stops a trick's hit too | 2026-09-30 |
| [0056](0056-aa-edge-is-half-step-5.md) | AA Champion's edge notch is the half step just past the exposure's far edge | 2026-09-30 |
| [0057](0057-armor-and-pierce-convert-stat-value.md) | ♦ armor and ♠ piercing convert the stat value, 20 + points | 2026-09-30 |
| [0058](0058-block-uses-the-normal-base.md) | A Block uses the Normal base | 2026-09-30 |
| [0059](0059-flush-hit-scaled-by-home.md) | A flush has its own hit, full at home, half beside it, none elsewhere | 2026-09-30 |
| [0060](0060-straight-meter-counts-from-first-commit.md) | The straight's meter fills against the earliest possible commit | 2026-09-30 |
| [0061](0061-slow-motion-does-not-count-toward-hold.md) | Slow motion doesn't count toward the hold fraction | 2026-09-30 |
| [0062](0062-numeric-gap-after-the-lean.md) | The numeric gap target is measured after the aim lean | 2026-09-30 |
| [0063](0063-agents-md-points-to-the-pillars.md) | AGENTS.md points to GAME_SPEC §1 for the pillars instead of copying them | 2026-09-30 |
| [0064](0064-trick-above-wins-95.md) | "Overwhelmingly" is 95% | 2026-09-30 |
| [0065](0065-unhorse-is-a-hard-zero.md) | The unhorse stays a hard 0; no teeter roll | 2026-09-30 |
| [0066](0066-pass-length-is-a-playtest-question.md) | The pass stays 8 s; a playtest decides whether it's long enough | 2026-09-30 |
| [0067](0067-the-four-stats-redefined.md) | The four stats are Strength, Accuracy, Armor and Posture; each acts always and more when aimed | 2026-09-30 |
| [0068](0068-aimed-strength-batters.md) | An aimed ♣ hit leaves the target Battered, taking more damage through their next contact | 2026-09-30 |
| [0069](0069-easier-crits-and-blocks.md) | Accuracy and Armor make crits and blocks easier, through hold and extra time | 2026-09-30 |
| [0070](0070-posture-health-buffer-heal.md) | ♥ Posture is a buffer when aimed and a heal after every contact; everyone has 80 Posture | 2026-09-30 |
| [0071](0071-broadway-effects-removed.md) | Broadway cards have no effects; they are the top of the rank curve | 2026-10-01 |
| [0072](0072-flushes-are-the-stat-at-its-limit.md) | Each flush is its suit's stat at its limit | 2026-10-01 |
| [0073](0073-the-straight-charges-straight.md) | The straight's power comes from charging straight without changing aim | 2026-10-01 |
| [0074](0074-defense-is-not-weaker.md) | Defense isn't weaker than offense; the four suits are roughly even in value | 2026-10-02 |
| [0075](0075-posture-counts-in-half-hearts.md) | Posture counts in half hearts; a trips-sized hit may say "trips" | 2026-10-07 |
| [0076](0076-spur-and-momentum-deferred-to-v2.md) | Spur and momentum are deferred to v2 | 2026-10-07 |
| [0077](0077-the-fixed-limit-is-the-wager-limit.md) | The fixed limit is the wager limit; no pot cap in v1 | 2026-10-08 |

Next free id: **0078**.
