# Automated QA

Use **Godot 4.7 stable (standard build)** and Python 3. No testing plugins or Python packages are required. The repository currently contains EventBus, GameState, PharmacologyEngine, two patient records, the drug database, and a temporary Main demo. There is no player controller, corridor scene, or world interaction manager yet.

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
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --quit-after 60
```

Prefer the Python runner: it enforces a 120-second timeout per command, nonzero failures, completion markers, and failure on Godot script/runtime errors even if Godot exits zero. Each suite runs in a separate Godot process. Tests do not call save/load disk operations or overwrite player saves. Godot may refresh its ignored `.godot/` resource cache. The runner requires 4.7; upgrade it and CI together when the project changes engine version.

## Executed coverage

- Four Python tests: all authored JSON syntax, drug IDs and patient references, basic patient field types/ranges, positive drug doses/half-lives and clearance fractions. Negative cases cover malformed JSON, duplicate keys, NaN/Infinity, missing/wrong IDs, wrong medication containers, unknown drugs, negative/string/boolean doses.
- Existing pharmacology suite: eight clinical scenarios, 19 assertions, including treatment response, smoking cessation, interaction buildup/washout, alerts and clue gates.
- GDScript QA scene: 16 assertions for item/event deduplication, clue pinning, objectivity clamps/bleed stages, in-memory progress round trip, actual main-scene instantiation and HUD/patient initialization, shift progression and demo keyboard handlers.
- Project import parses/registers scripts; the boot smoke check runs the configured main scene for 60 frames and requires its completion message.

The content validator is a deliberately partial schema for currently authored content, not a full patient schema and not proof that gameplay rejects malformed external/save data. Demo input tests call the handler directly; they do not establish OS input routing, mouse capture, physics collisions or raycast behavior. Disk save/load and branching dialogue are not yet covered. Run each added scene through an explicit smoke test; import alone does not execute its `_ready()`.

## Pending gameplay cases

Two coverage gaps print `SKIP` and are excluded from pass counts. Replace these explicit skips with real tests when Claude's APIs and scenes exist; do not build substitute gameplay implementations just to get green tests.

| Area | Fixture and expected behavior to implement |
| --- | --- |
| Movement | Instantiate the real controller on a floor; apply configured forward input across physics frames; verify displacement and release-to-stop. |
| Movement | Compare diagonal and forward speeds, verify wall collision, grounded behavior, and no movement while terminal/paused mode owns input. Confirm intended speed/jump rules against the design first. |
| Interaction | Instantiate the real manager and target; verify one activation per press, range/occlusion rejection, no-target behavior, and focus loss in terminal/paused mode. |
| Interaction state | Pick up a real item twice, verify one state update/event, reload the scene and verify collected state persists without duplicated objects. |
| Invalid runtime JSON | Exercise the actual loaders with malformed syntax, wrong root/container types, unknown references and invalid values; verify documented failure and unchanged prior state. |

## CI and independent reviews

`.github/workflows/godot-validation.yml` runs on PRs targeting main, pushes to main and the QA branch, and manual dispatch. It downloads Godot 4.7 from the official release, verifies SHA-512 and runs the same Python entry point. No secrets or export templates are needed. CI must be observed on GitHub before claiming its hosted run passed; local execution is separate evidence.

When Claude opens `claude/sprint-01-foundation -> main`, request review in its PR conversation if Codex GitHub Code Review is enabled:

```text
@codex review Check Godot 4 compatibility, broken scene references, input handling, collision behavior, JSON errors, and regressions. Identify concrete bugs with file and line references. Do not merge.
```

That command requests a review; this workflow does not enable the separate Codex integration or automatic reviews. Review the exact PR revision against the supplied design and run these checks on that revision. For each finding record severity, file/line, expected/actual behavior, reproduction command or steps, and whether it is **execution-confirmed** or **static-inspection only**. Keep missing coverage distinct from confirmed defects. Send fixes to Claude's existing branch/PR, rerun checks after the new commit, and review again. Do not modify gameplay files in the QA branch or auto-merge.

Finally test on Mac: lighting, animations, cinematic dialogue, input feel, and clinical correctness require human inspection. Passing headless checks does not validate those qualities.
