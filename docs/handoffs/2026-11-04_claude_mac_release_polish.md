# Mac release polish: Claude Code handoff, 2026-11-04

Requested by Bi (release-finish checklist, 2026-11-04). Branch `claude/mac-release-polish` from `main` at `f031e55` (PR #128). Draft PR to `main`; nothing merged by the agent. Kept clear of the ward-round thread's files (`WardRound*`, `ward_rounds.json`, `build_cast_member.py`, patient configs).

## What changed

1. **Objective banner no longer covers name tags.** `ObjectiveTracker` banner moved from top centre (where a character's floating name sits) to the top right under the clock (`BANNER_WIDTH` 460, `BANNER_TOP` 68). HUD toasts moved from the top left (they overlapped the checklist) to the top right under the banner, right-aligned (`scenes/ui/HUD.tscn`, `HUD.show_toast`).
2. **Objective shown once.** The HUD's bottom-left "Objective:" line now shows only when the checklist setting is off (`HUD._update_objective_line`, follows `objective_checklist` live). `HUD.objective_text` still tracks the objective.
3. **Elias shoulder seams.** Cause: the sweatshirt's neckline is cut by a horizontal plane, so on the sloping shoulder tops its rim stood 1.5 to 2 cm off the skin and the shell's inside showed as dark marks. New `tools/character_animation/tuck_neckline.py` pulls the garment within 3.5 cm of the rim toward the skin (offset scaled to 0.3 at the rim, smoothstep back to the original), leaving the front of the crew untouched (moving the decimated chest made a flat patch). Applied to `assets/blender/characters/Elias_Ward_v01_draft.blend` (79 rim vertices, 104 moved, largest 21.2 mm), then the GLB re-exported with the unchanged `add_motion_clips.py` (verified first that it rebuilds the committed GLB byte for byte from the committed blend: sha `edc563d…`). New blend `27b749c…`, GLB `5ec0d37…`; motion report updated. bpy 5.2.2 module (pip), the pinned Blender version.
4. **Warnings investigated (no game change needed).**
   - "no voice clip for ch1_b2_bennett_001/003": only from `test_naomi_acting.gd` and `test_dialogue_visemes.gd`, which point the line at a missing-voice fixture on purpose. All 619 entries in `audio/voice/voice_lines.json` have their file; the exported pack plays every Chapter 1 line with its clip.
   - "cs_ch0N_title is already playing; ignoring cs_ch0N_static_gn" (52 times): only from chapter tests that finish a chapter in the same frames its title card opens (for example `test_chapter2_missing_hours`, `test_chapter3_descent`, `test_chapter3_report`). In play the title card is a modal panel and a chapter cannot complete while it is up.
5. **Standalone Mac export.**
   - `export_presets.cfg` committed (removed from `.gitignore`): presets "macOS" (universal, ad-hoc signed, `com.forensicward.game`, 1.0.0), "Linux (container smoke test)", "Linux (export QA, with tests)". Include filter covers every JSON read at run time; tests and capture tools are excluded from the player build.
   - `project.godot`: `rendering/textures/vram_compression/import_etc2_astc=true` (Godot refuses a universal/arm64 Mac export without it; pack size unchanged at 606 MB).
   - `scripts/tests/TestRunner.gd`: also finds `test_*.gd.remap`, so the suite runs from an exported pack.
   - `tools/release/export_macos.sh`: on the Mac, installs templates if missing (SHA-512 checked), exports, unpacks, verifies the signature, runs a launch check.
   - `docs/MAC_RELEASE_BUILD.md`: build steps, packaged-app test table, Developer ID/notarization note.
6. Capture tool `tools/godot/capture_objective_hud.gd` (+ `CaptureObjectiveHUD.tscn`); renders in `assets/renders/ui/mac_release_v1/`.

## Validation (Linux container, Godot 4.7 stable)

- Baseline full QA on `main` `f031e55`: all executed checks passed: game 411/0, audio 1720/0, QA 19/0/0, GLB 199/0, exit 0.
- Full QA on the branch (code commit, see AI_HANDOFF.md for the SHA): all executed checks passed: game 413/0, audio 1720/0, QA 19/0/0, GLB 199/0, Chapter 1 sequence done at 62.1 s, no ERROR lines, exit 0.
- `test_objective_feedback`: 7/0 (two new tests).
- macOS export: `The Forensic Ward.zip` 652 MB (app 777 MB). Not run (no Mac here).
- Linux release export run from its own pack: Boot OK (content valid), exit 0. Exported builds print ten "Attempt to disconnect a nonexistent connection … AnimationLibrary" errors when the cast load (`CharacterAnimationRig._prepare_players` replaces the imported library); harmless, the editor does not print them. Worth a follow-up.
- Editor binary on the exported pack: Chapter 1 sequence done at 62.0 s, every voiced line from its clip.
- Full game suite from the export-QA pack: 408 passed, 5 failed; the 5 are `test_narration.gd` tests that copy a raw OGG into `res://` (impossible in a read-only pack), so test-harness only.
- Visual: Compatibility renderer captures (llvmpipe) of the HUD at 1920×1080 and 1440×900 and of Elias in five clips. Not Mac evidence.

## Not done

- Hands-on Mac playthrough, packaged-app test and listening pass: need Bi's Mac (table in `docs/MAC_RELEASE_BUILD.md` §3).
- Environment art pass (textures, UVs, trim sheets, lighting, performance): not started in this branch.
- Larger features (medication/lab gameplay, fuller customization, Jordan's voice/model): not started, per the request.

## Resume here

1. `git fetch origin --prune`; read the newest `docs/AI_HANDOFF.md` entry.
2. Mac (Remote Control or Bi by hand): fresh clone into `~/Developer/forensicward-release`, `git checkout claude/mac-release-polish`, `tools/release/export_macos.sh`, then the table in `docs/MAC_RELEASE_BUILD.md` §3. Never run git on the SSK drive.
3. Fix what the Mac pass marks FAIL; record PASS/FAIL/NOT TESTED with the commit.
