# Pending handoff entry: Naomi local Mac build

`docs/AI_HANDOFF.md`, `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md` and `docs/PROJECT_STATUS.md` are claimed by the cloud thread on `claude/naomi-animation-v04`. Per AGENTS.md §3 this branch does not edit them. The entry below is ready to copy to the top of the `docs/AI_HANDOFF.md` log by whoever integrates the two branches.

### 2026-10-18 16:05 UTC · Claude Code (owner's Mac, Remote Control) · Naomi local animation build

- **Branch:** `claude/naomi-local-build` (based on `main` at `46888dd`, after PR #50 merged the animation toolkit)
- **Latest verified commit:** the commit that adds this file
- **Pull request:** draft, assigned to the owner
- **State:** finished; pipeline validation build, **not approved, not production-ready**

**Accomplished**
- Found Blender 5.2.2, MPFB2 (build 20261010, no asset packs installed) and Godot 4.7.2 on the Mac. Nothing installed.
- Ran the merged toolkit on `Naomi_Bennett_v03.blend`: rig inventory, bone mapping, action authoring. Added the missing GLB export step and per-clip lengths.
- Exported `assets/exports/characters/Naomi_Bennett_v04_local.glb` (v03 mesh plus `idle_neutral` 5 s, `idle_breathing` 4 s, `listen_neutral` 3 s). v01, v02 and v03 untouched.
- Clips import and play in Godot 4.7.2; captured at the nursing station using a temporary, reverted entry in `CharacterVisualPreview.gd`.

**Files modified**
- `tools/character_animation/ForensicWard_Animation_Pipeline_v03/tools/create_animation_actions.py`: optional per-clip `frames` (default 25 unchanged)
- `tools/character_animation/ForensicWard_Animation_Pipeline_v03/tools/export_animated_glb.py`: new, exports actions to a new GLB
- `tools/character_animation/ForensicWard_Animation_Pipeline_v03/configs/staff_bennett_v03_mapping.json`: new, verified bone mapping
- `tools/character_animation/ForensicWard_Animation_Pipeline_v03/reports/`: rig inventory and GLB report
- `tools/character_animation/ForensicWard_Animation_Pipeline_v03/tests/test_bennett_mapping.py`: new
- `tools/character_animation/ForensicWard_Animation_Pipeline_v03/LOCAL_MAC_RUN.md`: commands and results
- `assets/blender/characters/Naomi_Bennett_v04_local.blend`, `assets/exports/characters/Naomi_Bennett_v04_local.glb`: new
- `assets/asset_manifest/naomi_character_manifest_v04_local.json`: new provenance (`approved: false`)
- `assets/asset_manifest/asset_manifest.json`: one added entry `Naomi_Bennett_v04_local` (required by the GLB validator). The cloud v04 branch also adds one entry here; expect a trivial merge conflict.
- `docs/design/characters/Naomi_Bennett_Character_Production_v1/ingame_review_v04_local/`: four captures (`.gdignore`)

**Unfinished**
- Not added to `CharacterVisualPreview` (the cloud thread owns that file).

**Known errors**
- `tests/music_ai/test_generate_music.py` fails 2 tests on this Mac only: Homebrew ffmpeg 9.0.2 has no `libvorbis` encoder (`Unknown encoder 'libvorbis'`). Unrelated to this branch; CI's ffmpeg has it.

**Tests** (on `46888dd` plus this branch's changes, macOS, Godot 4.7.2)
- `python3 tests/qa/run.py --godot /Applications/Godot.app/Contents/MacOS/Godot`: stopped at the music test (2 failures above).
- The same runner with only the music step removed: exit 0. test_json OK, audio manifest OK, pharmacology 0 failures, QA 19/0/0, GLB validation 156 assets / 0 failures, TestRunner 147/0, boot OK, audio 336/0, Ch1 audio sequence done.
- Toolkit unit tests: 5/5 OK.
- CI: see the PR.

**Dependencies not available to remote agents**
- Owner's Mac Blender 5.2.2 and MPFB2 install. The build is reproducible in any Blender 5.2.2; MPFB was not used.

**Next steps**
1. Cloud thread: reuse `export_animated_glb.py` and the mapping, or fold their fixes into `build_animated_character.py`; then this v04_local can be dropped from preview plans.
2. To make MPFB useful locally, install its CC0 skin, eyebrow, eyelash and hair packs on the Mac, and use a rig with face bones if MPFB expressions are wanted.

**Notes for the other agent**
- `v04` belongs to the cloud thread; this build is named `v04_local` to avoid collisions.
- Do not commit editor `.import` sidecars or Godot-extracted textures (`Naomi_Bennett_v04_local_*_BaseColor.png`).
