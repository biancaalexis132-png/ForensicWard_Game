# Automated QA

Use **Godot 4.7 stable (standard build)** and Python 3. No testing plugins or Python packages are required. The repository contains the Sprint 1 manager autoloads (`scripts/autoload/`), the GameState compatibility layer, PharmacologyEngine, AudioDirector, the first-person controller, the greybox hospital with doors, terminals and clue pickups, and the HUD, info panel and pause menu.

## Run on macOS

Install Python 3 from python.org if `python3 --version` is unavailable. Download Godot 4.7 stable for macOS from the official Godot release page, extract it, move `Godot.app` into `/Applications`, and open it once through Finder to complete macOS's normal application verification. Do not disable Gatekeeper.

From Terminal, using your actual clone location:

```sh
cd "$HOME/Documents/ForensicWard_Game"
python3 --version
/Applications/Godot.app/Contents/MacOS/Godot --version
python3 tests/qa/run.py --godot /Applications/Godot.app/Contents/MacOS/Godot
```

Alternatively, `GODOT=/Applications/Godot.app/Contents/MacOS/Godot python3 tests/qa/run.py` selects the same binary. Paths containing spaces work with `--godot "path/to/Godot"`.

Individual commands, from the repository root:

```sh
python3 tests/qa/test_json.py
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/TestPharmacology.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://tests/qa/TestQA.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . res://scripts/tests/TestRunner.tscn
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 60
```

Prefer the Python runner: it enforces a 120-second timeout per command, nonzero failures, completion markers, and failure on Godot script/runtime errors even if Godot exits zero. Each suite runs in a separate Godot process. Save/load tests write only to test slot 99, and the runner points Godot's user data at a temporary directory, so real saves are never touched. Godot may refresh its ignored `.godot/` resource cache. The runner requires 4.7; upgrade it and CI together when the project changes engine version.

## Executed coverage

- Four Python tests: all authored JSON syntax, drug IDs and patient references, basic patient field types/ranges, positive drug doses/half-lives and clearance fractions. Negative cases cover malformed JSON, duplicate keys, NaN/Infinity, missing/wrong IDs, wrong medication containers, unknown drugs, negative/string/boolean doses.
- Existing pharmacology suite: eight clinical scenarios, 19 assertions, including treatment response, smoking cessation, interaction buildup/washout, alerts and clue gates.
- GDScript QA scene: 19 assertions for item/event deduplication, clue pinning, objectivity clamps/bleed stages, in-memory progress round trip, shift progression through TimeManager, main-scene instantiation, content validation at boot, forward movement over physics frames, and an interaction reaching EventBus.
- Sprint 1 suite (`scripts/tests/TestRunner.tscn`): 43 tests across content validation, dialogue intent matching, state/save (including checksum tamper detection, which logs one expected `WARNING`), and world integration (movement, wall collision, the interaction ray, doors and access, clues, pause and input mode).
- Project import parses/registers scripts; the boot smoke check runs the configured main scene for 60 frames and requires its completion message.

The content validator is a deliberately partial schema for currently authored content, not a full patient schema and not proof that gameplay rejects malformed external/save data. Input tests use Godot actions and injected events; they do not establish OS input routing or mouse capture on macOS. Run each added scene through an explicit smoke test; import alone does not execute its `_ready()`.

## Pending gameplay cases

The two former `SKIP` lines (movement, world interaction) are now real checks, and the runner requires `skipped=0`. Still not covered:

| Area | Fixture and expected behavior to implement |
| --- | --- |
| Movement | Diagonal versus forward speed; jump rules once the design confirms them. |
| Invalid runtime JSON | Exercise the actual loaders with wrong root/container types on disk and verify unchanged prior state (the validator is tested in memory only). |
| Pharmacology in play | No gameplay path calls PharmacologyEngine yet; it is tested only by its own suite. |

## CI and independent reviews

`.github/workflows/godot-validation.yml` runs on PRs targeting main, pushes to main and the QA branch, and manual dispatch. It downloads Godot 4.7 from the official release, verifies SHA-512 and runs the same Python entry point. No secrets or export templates are needed. CI must be observed on GitHub before claiming its hosted run passed; local execution is separate evidence.

When Claude opens `claude/sprint-01-foundation -> main`, request review in its PR conversation if Codex GitHub Code Review is enabled:

```text
@codex review Check Godot 4 compatibility, broken scene references, input handling, collision behavior, JSON errors, and regressions. Identify concrete bugs with file and line references. Do not merge.
```

That command requests a review; this workflow does not enable the separate Codex integration or automatic reviews. Review the exact PR revision against the supplied design and run these checks on that revision. For each finding record severity, file/line, expected/actual behavior, reproduction command or steps, and whether it is **execution-confirmed** or **static-inspection only**. Keep missing coverage distinct from confirmed defects. Send fixes to Claude's existing branch/PR, rerun checks after the new commit, and review again. Do not modify gameplay files in the QA branch or auto-merge.

Finally test on Mac: lighting, animations, cinematic dialogue, input feel, and clinical correctness require human inspection. Passing headless checks does not validate those qualities.
