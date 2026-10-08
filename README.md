# Poker Jousting

A Roblox 1v1 game where a Texas hold'em hand is played as four jousting passes. Cards buff the
riders; a radial aim dial decides who lands the hit. Every bet is a commitment to ride into the next
card.

- **Design:** [docs/design/GAME_SPEC.md](docs/design/GAME_SPEC.md), the central design point.
- **Agent rules:** [AGENTS.md](AGENTS.md).
- **Workflow:** [docs/design/WORKFLOW.md](docs/design/WORKFLOW.md).
- **Decisions:** [docs/design/decisions/](docs/design/decisions/README.md).

The headless sim of one hand (GAME_SPEC §11) is in `sim/` and `tools/sim.luau`, with its tests in
`tests/`; what it found is in [docs/sim/RESULTS.md](docs/sim/RESULTS.md).

## The playable slice

The first playable slice (decision 0097): one numeric hand against a scripted bot, hand after hand,
with betting and a cue log. No tricks, no yard. The hand's rules are the sim's own modules: Rojo
maps `sim/` into the place as `ReplicatedStorage.Rules`, so the game and the sim share one copy
(0098).

| Folder | In the place | What it is |
| --- | --- | --- |
| `sim/` | `ReplicatedStorage.Rules` | The rules and every value (`sim/Config.luau`) |
| `src/shared/` | `ReplicatedStorage.Shared` | The wheel's physics, the slice's own values (`Slice.luau`), the remotes |
| `src/server/` | `ServerScriptService` | The hand, server-authoritative; the bot; the cue log |
| `src/client/` | `StarterPlayer.StarterPlayerScripts` | The wheel and the screen; sends input only |

### Opening the slice in Studio

You need [Rojo](https://rojo.space) 7.4.4 (the version in `tools/toolchain.env`) and its Studio
plugin.

1. From the repo root, build a place file and open it in Studio:

   ```sh
   rojo build default.project.json -o PokerJousting.rbxl
   ```

   Or start a new Baseplate in Studio and sync live: run `rojo serve` from the repo root, then
   press *Connect* in the Rojo plugin.
2. Press *Play*. A hand starts as soon as you join. Your opponent is the house rider.
3. The bot's betting odds are calibrated in the background when the server starts, which takes a
   minute or two. Output prints "Odds calibrated" when it is done; until then the bot bets with the
   sim's script.

### Playing a hand

- **Bets:** before each pass, Stay, Raise or Yield over the wheel. You have 5 s; a timeout Stays.
  Yield is offered only when you face a raise.
- **The pass:** 8 s from the charge to contact. Drag the wheel to aim, flick it to spin past
  positions, tap the hub for Neutral. The ring shows where your strike would land on the
  opponent: red is a crit, blue is their Guard. On Passes 2–4 the next card lands at 3.0 s and
  slow motion runs to 4.5 s; aim locks at 7.7 s.
- **After contact:** the hits land on both bars, then the ♥ heal, then the post-pass reveal.
- **The hand ends** on an unhorse, a Yield or the showdown after Pass 4. The next hand starts a few
  seconds later.

### The cue log

Every hand prints one JSON line to Output, starting `CUELOG `. Its fields are documented at the top
of `src/server/CueLog.luau`. In a published place it is also written to the `PokerJoustingCueLog`
DataStore under the hand id (0101).

## Commands

Run from the repo root with [Lune](https://github.com/lune-org/lune) 0.10.5:

```sh
lune run tests/run.luau     # the sim's tests and the wheel's
lune run tools/sim.luau     # the sim's baseline report
```

More in [AGENTS.md](AGENTS.md#commands).
