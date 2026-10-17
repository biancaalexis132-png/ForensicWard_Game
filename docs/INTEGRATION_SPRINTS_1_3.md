# Sprints 1–3 integration report

Branch `claude/integration-sprints-1-3`, based on `main` at `f6efda8`. It replaces the open PRs #1, #6, #7 and #8 (and the already-merged-into-parent #9 and #10) with one branch that merges cleanly into `main`.

## How the branch was built

The history showed that most of the integration had already happened on `claude/chapter1-playable` (PR #7):

| Source | Tip | Already in `claude/chapter1-playable`? |
|---|---|---|
| `claude/sprint-01-foundation` (PR #1) | `f626aad` | Yes, through `claude/integrate-sprint-01` (merge `8ca85bc`) |
| `claude/integrate-sprint-01` (PR #8) | `ef11090` | Yes (merge `7b11143`) |
| `claude/environment-production` (PR #6) | `e321b4a` | Yes (merges `a34c22a`, `9573cc3`) |
| `claude/sprint-02-ehr-interview` (PR #9) | `680ad86` | Yes (merge `b11f58c`) |
| `claude/sprint-03-evidence-shift` (PR #10) | `ee14ea1` | Yes (merge `680ad86`) |
| `main` | `f6efda8` | **No**: PR #5 (ACE-Step music pipeline, dialogue ducking, environment sound set, footstep randomizer, detail ambience layer) was missing |

Each was checked with `git merge-base --is-ancestor`. So the integration branch starts at `claude/chapter1-playable` (`b11f58c`) and adds one merge of `main` (`99c2eaf`). No commit was cherry-picked or replayed, so nothing is duplicated, and no existing branch was rewritten.

## Conflicts

| File | Conflict | Resolution |
|---|---|---|
| `README.md` | Project layout: the Sprint 1 `scripts/` tree vs. `main`'s folder table with the new audio and music tools rows | Kept the integrated `scripts/` layout (the only layout on this branch) and added every `main` entry that still exists: `systems/pharmacology/`, `systems/audio/`, `audio/`, `tools/audio/`, `tools/music_ai/`, plus `assets/`, `tools/blender/`, `scenes/audio/` and `scripts/narrative/`. Kept the "Working with AI agents" section, updated now that PR #4 is merged. |

`docs/TESTING.md` and `tests/qa/run.py` merged automatically; both sides' additions are present (the music-AI test step from `main`, the TestRunner and `.glb` validation steps from the branch). `systems/audio/AudioDirector.gd` changed only on `main` and still uses `EventBus.shift_started`, `narrative_event_fired`, `subtitle_shown` and `subtitle_cleared`, which all exist on `scripts/autoload/EventBus.gd`.

## Functionality check

Every file on each source branch was compared with the integrated tree. Files absent from the integration branch, and why:

| Missing file(s) | From | Why it is safe |
|---|---|---|
| `staging/pharmacology/**`, `staging/README.md` | PR #1 | Byte-identical to the live `systems/pharmacology/*.gd`, `data/drugs/drugs.json`, `data/patients/PT-00{1,2}.json` and `tests/TestPharmacology.*` kept from `main`. PR #8 removed the staging copy on purpose. |
| `autoload/EventBus.gd`, `autoload/GameState.gd` | `main`, PR #6 base | Replaced by `scripts/autoload/EventBus.gd` and `scripts/autoload/GameState.gd` in PR #8. Every `GameState` function, variable and signal from `main` still exists. Every EventBus signal still exists except `patient_selected`, which nothing emitted or listened to. |
| `scenes/main/Main.gd` | `main` | `main`'s pharmacology demo HUD, replaced by the real game `Main` (`scripts/main/Main.gd`) in PR #8. The engine it demonstrated is still loaded as an autoload and covered by `TestPharmacology`. |
| `player/.gitkeep`, `shaders/.gitkeep`, `ui/.gitkeep` | `main` | Empty placeholders, superseded by `scripts/` and `scenes/` folders. |

Systems confirmed present and tested: clinical rules (validated vs. prototype mode), pharmacology, audio (AudioDirector, cue sheet, manifest, music AI client), evidence board, EHR, interview and dialogue, Bennett trust, save/load (including tamper detection and pending story beats), story director, shift sign-out, world states and the Blender-built Chapter 1 wing.

## Test report

Run on `99c2eaf` in a Linux container with Godot `4.7.stable.official.5b4e0cb0f` (SHA-512 verified against the official `SHA512-SUMS.txt`).

`python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: **exit 0, "All executed checks passed"**.

| Step | Result |
|---|---|
| `tests/qa/test_json.py` | 4 tests OK |
| `tests/qa/test_audio_manifest.py` | 3 tests OK |
| `tests/music_ai/test_generate_music.py` (mock ACE-Step server, ffmpeg present) | 3 tests OK |
| `--editor --import` | OK, no errors |
| `tests/TestPharmacology.tscn` | 8 cases, 20 checks, `PASSED: 0 failure(s)` |
| `tests/qa/TestQA.tscn` | `QA_RESULT passed=19 failed=0 skipped=0` |
| `tools/godot/validate_glb_imports.gd` | `GLB VALIDATION PASSED: 58 assets checked, 0 failure(s)` |
| `scripts/tests/TestRunner.tscn` | `PASSED: 80 passed, 0 failed` (content, dialogue, state, world, Sprint 2, Sprint 3 suites) |
| Boot, `--quit-after 60` | `[The Forensic Ward] Boot OK (content valid)` |
| `tests/audio/TestAudio.tscn` | `AUDIO_RESULT passed=211 failed=0` |
| `scenes/audio/Ch1AudioSequence.tscn` | every beat in order, `CH1_SEQUENCE_DONE` at 61.4 s |

Expected warnings, all from negative tests: `SaveManager: slot 99: checksum mismatch` (tamper test), `PatientManager: note cites unrecorded observation` and `unknown consideration` (note validation), `DialogueManager: choice 'assess_motor' is not available` (locked choice).

### Blender asset validation

Blender 5.0.1 (`bpy` from PyPI, Python 3.11) re-ran all three build scripts in a scratch copy, not committed:

| Script | Result |
|---|---|
| `tools/blender/build_stage1_modular.py` | `STAGE1 OK: 25 assets exported` |
| `tools/blender/build_stage1_props.py` | `PROPS OK: 26 assets exported` |
| `tools/blender/build_stage2_chapter1.py` | `STAGE2 OK: 7 environments exported` |

The rebuilt exports also passed `validate_glb_imports.gd` (58/58). 50 of the 58 rebuilt `.glb` files are byte-identical to the committed ones. The other 8 (`ENV_ClinicalCorridor_20m`, `ENV_InterviewRoom_A`, `ENV_NursingStation`, `ENV_PsychiatristOffice`, `ENV_RecordsArchive`, `PROP_Camera_Dome`, `PROP_Chair_Office`, `PROP_Terminal_EHR`) have identical glTF structure (nodes, meshes, accessors, sizes) but different binary buffers. This looks like vertex data written in a different order between runs. The committed files were left unchanged.

## Not covered and open items

- CI on GitHub: see the draft PR's check run. Local results are not CI results.
- Headless runs do not cover Forward+/Metal rendering, input feel, audio mix or clinical correctness. These stay "untested on Mac" in `docs/PROJECT_STATUS.md`.
- PharmacologyEngine is still not called from gameplay (`ClinicalRules`/EHR integration is planned). This was already true before this integration.
- Clinical rules and dialogue that were pending psychiatrist review stay pending. This integration approves nothing.
- `assets/blender/modular/FW_Modular_Kit.blend1` (a Blender backup) is tracked from before PR #6 added `*.blend1` to `.gitignore`. It was left in place and can be removed in a follow-up.
- Blender exports are not byte-reproducible (see above).
