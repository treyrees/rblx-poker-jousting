# AGENTS.md — Poker Jousting

Roblox 1v1 game where a Texas hold'em hand is played as four jousting passes. Cards buff the riders;
a radial aim dial decides who lands the hit.

**The design is [docs/design/GAME_SPEC.md](docs/design/GAME_SPEC.md).** Start every task there and
check every change against it. This file points at it and sets the rules for working to it; how a
change moves through the repo is in [docs/design/WORKFLOW.md](docs/design/WORKFLOW.md).

## Design pillars

The pillars are in [GAME_SPEC §1](docs/design/GAME_SPEC.md#design-pillars). They are Trey's
words: apply them, don't reword, extend or add to them. (0063)

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
- Other reports: `--report sweeps|matchups|floor|gap|showdown|proto|bets|yard`. `--only text` runs
  the sweep, proto, bets or yard rows whose label contains it; `--shard i/n` runs every n-th row.
  The yard report wants `--hands 2000000`: it tallies by starting-hand class pair.
- Override one config value: `--set path=value`, for example `--set sim.lean=2`.
- Quick check that it runs: `--smoke`.

All sim values live in `sim/Config.luau`. What the sim found is in
[docs/sim/RESULTS.md](docs/sim/RESULTS.md).

## Next step

GAME_SPEC §11: "a headless sim of one hand, using the parameters below as config."
