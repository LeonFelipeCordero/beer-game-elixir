# AI Beer Game runner

This package contains the skill and scripts used to play the reported sessions:

| File | Purpose |
|---|---|
| `SKILL.md` | Agent rules, operating procedure, limits and verification |
| `scripts/browser_player.py` | Browser interactions, demand/stock policy, JSONL logging, shared clock and final capture |
| `scripts/run_supervisor.py` | Four visible Chromium instances, four independent Hermes workers, approval gate, deadline cleanup and aggregation |
| `tests/test_runner.py` | Offline regression tests; no agents, browsers or game records are created |

See the [outcome/policy report](../../docs/reports/ai-game-session-analysis.md) and [transcript analysis](../../docs/reports/ai-agent-transcript-analysis.md).

## Provenance

The browser helper is the final helper used for board 6, with documentation and browser-helper type annotations added. Its control policy is unchanged. The supervisor retains the run lifecycle and worker prompts used for the sessions, with machine-specific paths replaced by configurable arguments and a script-relative helper path. It now refuses nonempty output directories and derives session names from the run directory. The packaged skill consolidates the operating instructions used in those runs and makes current timing explicit instead of mixing historical scheduler versions.

This is not a new inventory-optimized strategy. In particular, the factory's base buffered-production term does not subtract current stock. Keeping that behavior allows readers to understand the inventory accumulation analyzed in the reports.

## Requirements

- Linux with a working Wayland or X11 display; default is Wayland.
- Python 3 and an installed Chromium/Chrome executable.
- Hermes CLI on PATH, authenticated with its model provider; browser_exec available.
- Unattended tool permissions sufficient for browser execution and writing summaries. The runner does not enable `--yolo` or bypass approvals. A blocked worker is reported as a failed run, not successful play.
- The game reachable by all workers. Localhost is appropriate here because the workers are local processes, not sandbox containers.

No external Python packages are needed by these scripts. They do not install Chromium, configure credentials or launch the game server.

## Safe preflight

From the repository root:

```bash
python skills/beer-game-elixir/scripts/run_supervisor.py --help
python -m unittest discover -s skills/beer-game-elixir/tests -v
```

Both commands avoid starting a real experiment. `browser_player.py` is not a standalone automation CLI: Hermes injects new_tab, js, cdp, goto_url and wait_for_load into browser_exec. Workers load it using:

```python
# Load the packaged game browser helper
from pathlib import Path
exec(Path(HELPER_PATH).read_text(), globals())
```

The supervisor tells each worker the resolved path and instructs it to read this packaged skill directly. Installing the skill into a Hermes profile is optional, not required by this runner.

## Start a 15-minute run

1. Create a **fresh board** through the game UI and note its actual URL. Do not use an occupied board. Example URLs below are placeholders, not a board to join automatically.
2. Select a new output directory **outside this repository**. It contains Chromium profiles and private logs; never commit it.
3. Launch the supervisor from the repository root, using your executable:

   ```bash
   python skills/beer-game-elixir/scripts/run_supervisor.py \
     http://localhost:4000/board/123 \
     "$HOME/beer-game-runs/new-run" \
     --chromium chromium \
     --port-base 9260 \
     --ozone-platform wayland
   ```

   `--chromium` accepts an executable path or a command on PATH. Supply `--ozone-platform x11` on X11. Four consecutive debugging ports are bound to 127.0.0.1 only; do not expose them publicly.

   When driven by Hermes, launch with terminal(background=True, notify=True, persist_on_release=True) so this explicitly requested bounded experiment survives chat cancellation and reports completion.
4. The supervisor writes `browsers-ready.json` with browser PIDs and ports. **Verify the four windows are actually visible**, then create a file named `launch-approved` inside that exact output directory. The supervisor waits up to 180 seconds for this gate; it does not equate a reachable CDP endpoint with a visible window.

   In Hermes, read the readiness file using read_file, verify window visibility with desktop/compositor tools, then use:

   ```python
   write_file(path=RUN_DIRECTORY + "/launch-approved",
              content="Four dedicated browser windows verified visible.")
   ```

5. Workers are started only after approval. Retailer, wholesaler and factory join one role each; observer stays on the lobby. Each process has its own browser endpoint and separately named harness session.
6. Four role-ready files establish `window.json`, with start and end 900 seconds apart. Agent startup time is outside that window. Global game timers can still create role demand before the common start, so demand exposure need not be perfectly identical between repetitions.
7. At the deadline, helpers capture final state, save role-specific screenshots, and disconnect. The supervisor allows up to eight seconds for final capture, then terminates its dedicated browsers. Workers have bounded wrap-up time. It preserves application records rather than using Quit Game or deleting boards.

The game-policy loop checks the shared deadline before UI mutations. Process cleanup is an independent backstop, not evidence that every agent played correctly for all 900 seconds: inspect the logs and final states before claiming that.

## Output and auditing

- `mechanics.json`: verified experiment cadence (currently 30/30 seconds).
- `window.json`: common wall-clock interval.
- `browsers-ready.json`, `browser-shutdown.json`: browser lifecycle evidence.
- `<role>.jsonl`: original states, policy choices and action verification.
- `<role>-worker.jsonl`: Hermes tool/response stream, potentially private.
- `<role>-prompt.txt`, `<role>-summary.md`: role assignments and optional summaries.
- `<role>-final.png`: unique per-role images; screenshot failure is logged separately.
- `aggregate.json`, `report.md`: deduplicated observed outcomes.
- `supervisor-error.json`: setup/execution failure, if encountered.

A normal supervisor exit is not enough on its own. Check final roles and stock, action verification, pending and unknown order IDs, the common interval, and disconnect evidence. Reconcile retailer/wholesaler stock against actual received supply and unique fulfilled quantities. Do not count configured production as realized production or sum inter-player transfers as independent sales.

The latest-ten UI history and sampled observations do not prove absence of unobserved backlog or transient shortages. Raw worker logs may contain private data; publish selected public decision evidence, not whole transcripts or browser profiles.

## Historical behavior versus reusable launcher

The reports describe two specific recorded runs; launching this package creates another experiment, not an exact replay of those decisions. Agents choose buffer/smoothing, global scheduler phase varies, and model/provider settings come from the active Hermes environment. Control those factors explicitly when doing a comparative experiment.
