---
id: 0098
title: The game and the sim share one copy of the rules; Rojo maps sim/ into the place as-is
date: 2026-10-08
decided-by: trey (chat, playable-slice session, 2026-10-08)
supersedes: []
superseded-by: null
---

## Context

The first playable slice (0097) needs a Roblox project, and the headless sim is the rules
reference (0096). rblx-joust-tourney syncs `src/` with Rojo (`default.project.json`) and runs
its Lune tests through a Roblox-environment shim, because its modules require
`script.Parent.X`. This repo's `sim/` is plain Luau with string requires (`require("./Dial")`).
Put to Trey: map `sim/` into the place as-is; move `sim/` under `src/shared/Rules`; or rewrite
the sim to Roblox requires and port the tourney's shim.

## Decision

Rojo maps `sim/` into the place as-is, as `ReplicatedStorage.Rules`. The sim's modules keep
their string requires, which Roblox and Lune both resolve, so one copy of the rules runs in Studio
and under Lune with no shim. The game's own code is `src/shared`, `src/server` and
`src/client`. Rojo 7.4.4 and Lune 0.10.5 are pinned in `tools/toolchain.env`, the versions the
tourney pins.

## Consequences

- `tools/sim.luau`, `tests/` and AGENTS.md's commands are unchanged.
- If Studio refuses a string require in some file, the fallback is to move that file alone.
