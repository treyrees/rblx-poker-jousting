# AGENTS.md — Poker Jousting

Roblox 1v1 game where a Texas hold'em hand is played as four jousting passes. Cards buff the riders;
a radial aim dial decides who lands the hit.

**The design is [docs/design/GAME_SPEC.md](docs/design/GAME_SPEC.md).** Start every task there and
check every change against it. This file points at it and sets the rules for working to it; how a
change moves through the repo is in [docs/design/WORKFLOW.md](docs/design/WORKFLOW.md).

## Design pillars

Verbatim from GAME_SPEC §1. These are Trey's words: apply them, don't reword, extend or add to them.

- **Poker structure, physical resolution.** Hole cards, board, streets and betting are hold'em.
  Outcomes come from the joust. Hand strength acts through the riders' stats and, at showdown,
  forces the knockdown alongside Posture. A bare card comparison only breaks exact ties.
- **Play every hand.** Numeric hands (high card through trips) are modest stat edges. Skill on the
  dial decides most numeric matchups, so a bad hand is a handicap, not a fold.
- **Tricks are trump cards.** Straight and above are tricks, ranked on a trick ladder. As the
  ladder climbs, tricks bring unique mechanics and/or explosively scaled numbers. A rider above the
  opponent on the ladder who unleashes their trick, rather than holding it, has a virtually
  guaranteed win condition.
- **Ambiguous tells.** The dial and the rider leak partial information about hole cards. Nothing
  leaks the exact hand.
- **Suits are stats.** Each suit is a stat, and all four act all the time. Aim leans into the
  stats it points at. Aim is public; whether your cards back the lean is the secret.

Also important: **learnability** (for example, betting is beginner-ignorable, §2) and
**spectacle** (for example, the setup/counter animation system, §8).

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
the §9 *Take* table lists (for example the Magnet wheel physics from the
`claude/ring-spin-ui-feel-xpatk4` branch, and the headless Lune sim and test harness), or ones Trey names. Take the code or mechanism, not
Turbo Jousting's invariants, ADRs, vocabulary, conventions or design reasoning. Every PR that
borrows names the source repo, branch and file.

## Commands

The headless sim (`sim/`, `tools/sim.luau`) and its tests run under [Lune](https://github.com/lune-org/lune)
0.10.5, the version rblx-joust-tourney pins. It's a single binary from the release zip
(`lune-0.10.5-linux-x86_64.zip`). Run everything from the repo root.

- Tests: `lune run tests/run.luau`. Set `TESTKIT_QUIET=1` to print only failures.
- Sim, baseline report (100k hands): `lune run tools/sim.luau`.
- Other reports: `--report sweeps|matchups|floor|gap|final|showdown`.
- Override one config value: `--set path=value`, for example `--set sim.lean=2`.
- Quick check that it runs: `--smoke`.

All sim values live in `sim/Config.luau`. What the sim found is in
[docs/sim/RESULTS.md](docs/sim/RESULTS.md).

## Next step

GAME_SPEC §11: "a headless sim of one hand, using the parameters below as config."
