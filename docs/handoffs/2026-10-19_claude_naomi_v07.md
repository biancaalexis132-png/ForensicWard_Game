# Naomi v07 refinement and live gesture shadows

- **Branch:** `claude/naomi-v07-refine` from `main` `bf4cbfd`. Runtime/asset commit `2707a37e3387cfcea253882f8fbead9eaf9e8773` (pushed, verified with `git ls-remote`). Draft PR to `main`.
- **Owner request (2026-10-19):** "continue to finish all necessary animation and i will chec on my mac"; on the follow-up card the owner chose "Naomi, then cast". v07 is **not approved**; the owner checks it on the Mac.

## What changed

`tools/character_animation/refine_character.py` (new, profile `profiles/staff_bennett_v07.json`) opens `Naomi_Bennett_v06_mpfb.blend` read-only and writes `Naomi_Bennett_v07.blend`/`.glb`. Rig, the ten clips and all 32 morph targets (10 stable + 22 MPFB visemes) are kept.

| Defect (from `docs/handoffs/naomi_v06_source_review/`) | Cause found | Fix in v07 |
|---|---|---|
| Wavy dark rim above the closed lid | v03's texture-painted "lash line" sits on an ellipse larger than the eye opening, i.e. on the crease. The crease skin does not move in a blink, so the line stayed above the closed lid. Confirmed by recolouring the lash geometry red: the rim did not change. | 4,125 texels in that band refilled from surrounding skin. A thin lash line is painted on the lid-margin skin under the lash roots, so it rides down with the lid. |
| Lashes vanished or spiked when closing | MPFB transfer moved each lash vertex independently. | Every lash tip follows its root's lid vertex; lid motion in `blink`, `blink_L`, `blink_R` relaxed (4 passes) for a smoother closed line. |
| Jagged, flickering trouser hems | The trousers are a thin closed shell; outer and inner walls (0.4 mm apart) crossed at the old hem. | Each leg cut at 0.17 m; outer wall extended as a straight tube to 0.085 m with a 6 mm turned-in hem; inner wall tucked 3 mm and left open inside the leg; hem edge marked sharp. |
| Boxy shoes (cosmetic) | Convex hulls from `tidy_shoes`. | 30 relax passes above the sole. |

Review sheet: `assets/renders/characters/Naomi_Bennett_v07_refine_sheet.png` (Cycles CPU, 16 samples: eyes open / half / closed / closed side, hems front / side / back).

**Draw-call jump:** on current `main`, in a Linux Vulkan software renderer (lavapipe, 640×360, `tools/godot/measure_character_frame_time.gd`): capsule 463 draw calls, still v03 496, animated v06_mpfb 503, v07 503. The Mac's 828 for v04/v05_mpfb predates the static shadow proxies; animation now adds about 7 draw calls over a still model. These counts are not Mac frame times; software-renderer milliseconds are meaningless and are not reported.

**Gesture shadows:** the static proxies froze every shadow in the rest pose. New `scripts/world/CharacterShadowSelector.gd`: skinned meshes go on render layer 19, proxies on layer 20; the nearest shadowed light (re-checked every second) includes layer 19 and excludes 20 in `shadow_caster_mask`, every other light the reverse. Gestures now cast a moving shadow from one light at the cost of that one light redrawing its shadow map each frame.

Other: `CharacterVisualPreview` gains `v07` and defaults to it (preview still off unless `--character-preview` is given); `asset_manifest.json` entry; manifest `naomi_character_manifest_v07.json`; report `tools/character_animation/reports/staff_bennett_v07_refine_report.json`.

## Tests

`python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` on `2707a37`: exit 0; game 234/0 (new `test_only_the_nearest_light_sees_the_moving_meshes`; shadow and preview tests updated for the new layers and default), GLB 162/0, audio 336/0, QA 19/0/0, boot OK, `CH1_SEQUENCE_DONE`. First run failed only because v07 was missing from `asset_manifest.json`; fixed. Mac not run.

## For the owner on the Mac

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --character-preview=staff_bennett
/Applications/Godot.app/Contents/MacOS/Godot --path . -s res://tools/godot/measure_character_frame_time.gd --resolution 1280x720 -- --version=v07
```

Look at: blinks at the counter and close up, hems and shoes, the chart gesture's shadow on the desk, and the PERF lines against the 33 ms budget.

## Reproduce

```sh
blender -b --python-exit-code 1 --python tools/character_animation/refine_character.py -- --profile tools/character_animation/profiles/staff_bennett_v07.json
```

or with the bpy 5.2.2 module (`python -c "import sys; sys.argv=['b','--','--profile',...]; import bpy; exec(open('tools/character_animation/refine_character.py').read())"`; running the file directly with the module crashes in glog initialisation).

## Still open

- Mac frame time for v07, look of the live shadow, owner visual approval.
- The MPFB closed lid still has a slight pocket below the seam in side view.
- Lip sync stays the text-based approximation (no phoneme timing).
- Next in this workstream: draft models and shared animation for the rest of the cast (Voss and Hale first), per the owner's "Naomi, then cast".
