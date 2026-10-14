---
name: beer-game-elixir
description: Use when playing Beer Game Elixir in browsers.
version: 0.2.0
author: Leon Felipe Cordero (LeonFelipeCordero), Hermes Agent
license: MIT
platforms: [linux]
metadata:
  hermes:
    tags: [games, browsers, supply-chain, multi-agent]
    related_skills: []
---
# Beer Game Elixir

Run three isolated browser players and a non-coaching observer for a shared 15-minute experiment. Preserve the recorded buffered inventory policy; do not describe automated clicks as fresh model deliberations. The supervisor targets Linux; the browser helper executes inside Hermes `browser_exec`.

## When to Use
- Play this application with retailer, wholesaler, factory and observer agents.
- Reproduce the control policy behind the accompanying session reports.
- Do not use this skill to modify the application or create unrestricted agent copies.

## Prerequisites
- A running game and a fresh board created through its browser UI.
- Authenticated Hermes CLI with browser_exec enabled and sufficient unattended tool permissions.
- Python 3, a Chromium-family executable, and a local Linux graphical session.
- Four available loopback CDP ports and a new private run directory outside the repository.
- Read [README.md](README.md) before launching; it documents the approval gate and cleanup.

## How to Run
Use `terminal` from the repository root, replacing the example board, executable and output directory:

```python
terminal(
    command="python skills/beer-game-elixir/scripts/run_supervisor.py http://localhost:4000/board/123 ~/beer-game-runs/new-run --chromium chromium",
    background=True, notify=True, persist_on_release=True,
)
```

Use `--ozone-platform x11` on X11; the recorded runs used Wayland. Do not start a full game just to test packaging. The supervisor explicitly launches headed browsers and does not need to change global browser settings.

## Procedure
1. Inspect `config/config.exs`, delivery controls, and current role state. Complete only when scheduler intervals and game behavior are verified.
2. Create a fresh board in the browser; record its actual numeric ID. Never reuse another run's occupied board.
3. Launch the supervisor in a new directory. It starts four browser processes and writes `browsers-ready.json` but waits before starting workers.
4. Verify all four windows are visible. Read the exact readiness file, then create `launch-approved` in that run directory using `write_file`. This gate times out after 180 seconds; do not approve invisibly launched browsers.
5. Each worker reads this packaged skill and executes `scripts/browser_player.py` inside browser_exec. It uses a unique run/role session name and its own BU_CDP_URL. Three roles join the game; the observer stays on the selection lobby.
6. All four ready files establish one shared 900-second window. Agents execute 45-second batches, selecting buffer/smoothing from only their own observations. Players cannot read one another's logs or communicate; observer cannot coach.
7. At the deadline, capture final state and a uniquely named screenshot, navigate to about:blank, and verify disconnect. Supervisor closes dedicated browsers and stops remaining workers. Keep board/player records intact; never use Quit Game for normal cleanup.
8. Read back run artifacts and reconcile unique delivered quantities against stock before claiming completion. Distinguish configured production from actual production, and public decision explanations from inferred motives.

## Game Rules and Policy
- Three roles only: retailer orders from wholesaler, wholesaler from factory.
- The verified version schedules ordering permission, CPU demand at every role, and factory production every 30 seconds. The supervisor writes these values to mechanics.json. Adapt it if source changes; never assume textbook retailer-only demand.
- Deliver whole orders only when eligible stock exists; prefer the oldest fulfillable pending order. Verify DELIVERED after clicking the real UI control.
- Quantity edits use the native input setter plus bubbling input/change events and value readback, then submit the actual form. Never use this route for passwords or secrets.
- The helper estimates demand from newly observed outgoing-order bursts. Retailer/wholesaler request buffered demand plus pending obligations minus stock and estimated supply in transit. Factory configures buffered demand plus uncovered pending demand. The existing stock is not subtracted from the base factory production term; preserve this choice when reproducing the reports.
- Source may cap histories at ten orders. Retain a union of observed IDs; disappearance is not evidence of delivery. Initial backlog fields are not independently measured pending demand.

## Pitfalls
- Each player must have one connected game page. Extra sockets can duplicate CPU demand or factory production.
- Blank-status rows with Deliver or Not enough stock actions are pending unless the same ID is already confirmed delivered. Favor delivered evidence over stale duplicates.
- Role identity checks are case-insensitive. Modern inventory uses `.inventory-values dd`; the helper also supports the older three-table layout.
- After transport failure, inspect role and URL. Try same-session recovery at most twice; if cookies are gone and the board is full, preserve records and report failure rather than replacing a player or injecting state.
- A sandbox's localhost is not the host's localhost. This supervisor uses local processes, not OS-isolated sandboxes.
- Unique screenshots avoid shared temporary-path overwrites; structured state remains the numerical evidence.
- Profiles, Chromium user data and worker transcripts can contain private material. Keep run artifacts outside git and do not publish raw credentials or private model reasoning.
- Do not accelerate game clocks, call server internals to play, or infer a victory/finished flag from the timed stop.

## Verification
Use `terminal(command="python -m unittest discover -s skills/beer-game-elixir/tests -v")` for offline tests and the README's safe CLI preflight. Verify four final/disconnected records and the common window; independently check browser shutdown and quantity balances. Compare recorded stockouts, pending orders and safety choices with the two linked reports, without inventing observations between snapshots.
