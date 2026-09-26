# WORKFLOW — how a change moves through the repo

[GAME_SPEC.md](GAME_SPEC.md) is the central design point. Every change either implements it,
corrects its transcription, or goes to Trey. The rules for agents are in
[AGENTS.md](../../AGENTS.md); this doc is the process.

## Kinds of change

| The change | Who decides | What the PR does |
|---|---|---|
| Implements something GAME_SPEC specifies | Normal review | Names the GAME_SPEC sections it implements |
| Fixes a transcription error (GAME_SPEC doesn't match the design PDF) | Normal review | Fixes it and quotes the PDF |
| GAME_SPEC is silent, ambiguous or contradicts itself on something the work needs | Trey | Nothing yet: ask first, with the options and what each costs |
| Changes the design: a rule, effect, pillar, Status row or open question | Trey | Only after Trey decides: updates GAME_SPEC and records the decision |
| Changes a tuning value (§11 parameter table) | Trey | Updates the value, citing the sim run behind it once the sim exists |
| Borrows from rblx-joust-tourney | §9 *Take* table, or Trey | Names the source repo, branch and file |

When unsure which row applies, ask.

## Recording decisions

When Trey makes a call that changes or clarifies the design, it is recorded in
[decisions/](decisions/README.md) in the same PR that updates GAME_SPEC. An agent writes the entry
only to record a call Trey made, and cites where he made it (PR comment, chat, date), never to
record a call of its own. Entries are append-only. A later decision supersedes an earlier one; it
doesn't rewrite it.

## Pull requests

- **One topic per PR**: one system, one fix, or one decision.
- **Agents open PRs as drafts.** Trey merges anything that touches GAME_SPEC, AGENTS.md, this file or
  `decisions/`.
- **The description names the GAME_SPEC sections** the PR implements or changes.

## Verifying

No automated checks exist yet. GAME_SPEC §9 names the Turbo Jousting headless Lune sim and test
harness as the starting point for this game's; the checks arrive with it. Until then, re-read your
diff against GAME_SPEC and check every link you add.

## Session practice

- **One topic per session.** Open a new session for an unrelated task.
- **Enter through GAME_SPEC or a specific file.** Scope searches with a path, and read the matching
  section rather than whole files.
- **Keep command output small.** Redirect chatty output to a file and grep it; never pipe it into
  `head`, which can hang the command.
