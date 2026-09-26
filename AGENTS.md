# AGENTS.md — Poker Jousting

Roblox 1v1 game where a Texas hold'em hand is played as four jousting passes. Cards buff the riders;
a radial aim dial decides who lands the hit.

**The design is [docs/design/GAME_SPEC.md](docs/design/GAME_SPEC.md).** Start every task there and
check every change against it. This file points at it and sets the rules for working to it; how a
change moves through the repo is in [docs/design/WORKFLOW.md](docs/design/WORKFLOW.md).

## Design pillars

Verbatim from GAME_SPEC §1. These are Trey's words: apply them, don't reword, extend or add to them.

- **Poker structure, physical resolution.** Hole cards, board, streets and betting are hold'em.
  Outcomes come from the joust, not a card comparison, except as a final tiebreak.
- **Play every hand.** Numeric hands (high card through trips) are modest stat edges. Skill on the
  dial decides most numeric matchups, so a bad hand is a handicap, not a fold.
- **Tricks are trump cards, not auto-wins.** Straight and above change the dial's rules for one
  pass. Each trick trades power for predictability, so reads can still beat it. Trick vs read is an
  intended arms race.
- **Ambiguous tells.** The dial and the rider leak partial information about hole cards. Nothing
  leaks the exact hand.
- **Suits are stats and directions.** Each suit is a stat, and each stat lives on an axis of the
  dial. Aim is public; whether your stance is actually loaded is the secret.

## Invariants

None yet. Trey writes this list. Agents do not add, draft or infer invariants, here or anywhere
else. If you think one is missing, say so in chat or the PR and leave this section alone.

## Working to the spec

- **Build what GAME_SPEC says.** Where it is silent, ambiguous or contradicts itself, stop and ask
  Trey with the options. Don't fill the gap yourself.
- **Respect the §1 Status table.** *Settled*: build to it. *Proposed, needs sim*: build it as config,
  since it is not final. *Deferred to v2*: don't build it. *Open*: don't answer it.
- **Tuning numbers are the §11 parameter table.** Per §11 they are the sim's config: keep them in one
  place and don't change their values.
- **The §11 open questions stay open** until Trey answers them.
- **The design changes only when Trey changes it.** Agents may propose a change; they never make one
  by editing GAME_SPEC, or by building something the spec doesn't describe.
- **Use GAME_SPEC's vocabulary.**

## Borrowing from rblx-joust-tourney

GAME_SPEC §9: Turbo Jousting is "a parts bin, not a rulebook." Take practical pieces only: the ones
the §9 *Take* table lists (for example the Magnet wheel physics from the `ring-spin-ui-feel` branch,
and the headless Lune sim and test harness), or ones Trey names. Take the code or mechanism, not
Turbo Jousting's invariants, ADRs, vocabulary, conventions or design reasoning. Every PR that
borrows names the source repo, branch and file.

## Commands

None yet: there is no code in the repo.

## Next step

GAME_SPEC §11: "a headless sim of one hand, using the parameters below as config."
