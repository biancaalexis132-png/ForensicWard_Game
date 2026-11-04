# Cast animation standard

Every Forensic Ward character model uses these clip and face-control names, so `CharacterActingAdapter`, `CharacterAnimationRig` and the acting-cue files work with any of them. Naomi Bennett (v04, refined in v05) is the first model built to this standard. The names come from Naomi's acting cues (`docs/design/characters/Naomi_Acting_Cues_v1/naomi_acting_cues.json`), and a test (`scripts/tests/test_character_animation.gd`) keeps `clip_library.json` and the runtime lists in step.

## Body clips (imported AnimationPlayer)

| Clip | Loops | Length | Use |
|---|---|---|---|
| `idle_neutral` | yes | 8 s | Default standing idle: breathing, slight weight shift, slow head drift. Plays as soon as the model attaches, and is the adapter's fallback for any missing body clip. |
| `idle_breathing` | yes | 4 s | Breathing only, for still moments. |
| `listen_neutral` | yes | 6 s | Listening: slight lean in, head tilt. |
| `stand_conversational` | yes | 6 s | Speaking: small emphatic head movement. |
| `turn_from_workstation` | no | 1.2 s | Turns from the workstation to the player. |
| `return_to_workstation` | no | 1.2 s | Turns back to the workstation and holds. |

Body clips animate pelvis, spine, chest, clavicles and head only.

## Gesture clips (GestureAnimationPlayer)

`small_greeting_nod`, `small_acknowledgement_nod`, `restrained_chart_indication`, `subtle_workstation_indication`.

Gestures animate only the neck and arms. `CharacterAnimationRig` moves them from the imported player to a `GestureAnimationPlayer` (the name the adapter requires), so a gesture plays over any body clip without either overriding the other.

## Motion clips (clip_library_motion.json, 2026-11-03)

Added on top of the ten clips above by `add_motion_clips.py`, for the six v01 draft cast models (not Naomi). Same rotation vocabulary; leg roles `thigh_*`, `calf_*`, `foot_*` are resolved from the rig's standard bone names.

| Clip | Player | Loops | Length | Standing only | Use |
|---|---|---|---|---|---|
| `walk_neutral` | body | yes | 1.1 s | yes | Walk in place, two steps per cycle; the pelvis is keyed down each frame so the lower ankle stays on the floor. `CastRoute` moves the character. |
| `walk_arm_swing` | gesture | yes | 1.1 s | yes | Arm swing in step with the walk. Body clips never animate arms, so it runs on the gesture player. |
| `explain_open_hand` | gesture | no | 2.4 s | | Right forearm to an open-hand explaining position, one beat. |
| `explain_both_hands` | gesture | no | 2.8 s | | Both forearms lift as if framing a point. |
| `small_head_shake` | gesture | no | 1.3 s | | A mild no. Plays only when asked for, never at random. |
| `thinking_pause` | gesture | no | 3.0 s | | Head tilts and drops, right forearm lifts a little. |
| `small_shrug` | gesture | no | 1.5 s | | Uncertainty. Plays only when asked for. |
| `point_direction` | gesture | no | 2.2 s | yes | Points ahead, as when giving directions. |

Seated characters (cast config has a `seated` block: Elias, Mara) do not get the standing-only clips. None of these clips depicts a symptom.

`add_motion_clips.py` also detaches jacket and trouser panels from the forearms: garment weights had been copied from the nearest skin, and the hanging forearms sit beside the hips, so any arm gesture dragged a flap of cloth after the hand. The fix floods out from cloth hugging each forearm through forearm-weighted vertices; anything the flood does not reach takes the weights of the nearest garment vertex without forearm weight. It is applied in memory before export; the committed `.blend` is opened, never re-saved, so the GLB is reproducible from that `.blend`, this script and the library. Each run writes `reports/<id>_v01_draft_motion_report.json` with the input and output hashes and the measured step length.

```sh
python -I tools/character_animation/add_motion_clips.py --profile tools/character_animation/profiles/staff_hale_v01_draft.json   # bpy 5.2.2 module
python -I tools/character_animation/review_motion_clips.py --profile <same> --out assets/renders/characters/<Name>_v01_draft_motion_review.png
```

The script refuses a `.blend` that already has the motion clips, so run it on the committed v01 draft `.blend` only.

### In game

- `CastPerformer` (every animated cast member except Naomi, who keeps `NaomiActingController`): greeting nod on the first conversation and an acknowledgement nod after; listens (`listen_neutral`) while someone near speaks and talks (`stand_conversational`) during its own voiced lines, with talk gestures chosen from the neutral set and seeded by the line id; swaps `idle_neutral` and `idle_breathing` every 9 to 16 s; standing characters turn toward the player by up to 80° from their marker facing and turn back afterwards.
- `CastRoute`: optional `route` on a character in `data/world_chapter*.json`, points in the marker's frame (`[x, z]`, forward is `-z`) plus `pause_seconds`. The character walks out and back at `walk_step_m / 0.55 * 0.9` m/s (step length from the motion report, stored in `data/character_visuals.json`), stops while engaged or while the player is within 1.8 m, and is not saved: a loaded game puts it back at its marker. `test_cast_motion.gd` casts rays along every authored route at three heights and three lateral offsets.

## Face morph targets (on the face mesh)

| Morph | Driven by |
|---|---|
| `blink`, `blink_L`, `blink_R` | `CharacterFaceRig`: irregular blinks every 2.2–5.5 s, with an occasional double blink. At 1.0 the lids meet fully. |
| `mouth_open` | `CharacterFaceRig` while the adapter reports the character speaking (no lip sync) |
| `attentive`, `warm_subtle`, `concerned_restrained`, `professionally_serious`, `focused`, `calm_professional` | The adapter, by cue `face` name, at value 1.0. Each is authored at in-game intensity, so it stays restrained. |

`neutral` means no expression morph.

## Eye bones and gaze

Models carry one bone per eye, `eye_l` and `eye_r`, under the head (`eye_bones` in the profile), with each eyeball weighted fully to its bone. `CharacterGazeRig` turns only those bones, by at most 26° sideways and 12° up or down, toward the cue's `gaze` target:

| Directive | Target |
|---|---|
| `player` | the active camera, within 7 m and in front of her (beyond 60° to the side the eyes rest) |
| `workstation` | the nearest EHR terminal within 4 m, else down and to her right |
| `workstation_then_player` | the workstation for 1.2 s, then the player |

Small fixational movements keep a held gaze from looking frozen.

## Shadows

An animated mesh makes every shadowed light around it redraw its shadow map each frame. `CharacterAnimationRig` therefore turns shadow casting off on the skinned meshes and adds a still, shadow-only copy of each in the rest pose. The copies never blink or animate.

## Profile options for appearance

These run in the builder before the face morphs:
- `face.brows.mode: "painted"`: brows painted as individual hairs into the skin texture, so they mipmap with the skin and read as brows at counter distance. `"strips"` keeps the older alpha-strip brows.
- `skin`: roughness level, variation and cell size, specular, and an optional pore normal map (`pore_normal_strength`, off by default because it reads as grain in Godot). These are baked from a position map of the skin's UVs.
- `clothing_tidy.shoes`: replaces creased shoes with a rounded clog cut from their convex hull, and copies the skin weights back.
- `clothing_tidy.trousers`: makes each leg's hem straight, irons out the folds above it, and stretches the hem down over the shoe tops.

## Building a character to the standard

1. Copy `profiles/staff_bennett.json` to `profiles/<character_id>.json`. Set the source .blend, object names and the role-to-bone map from that rig's inventory. Run `ForensicWard_Animation_Pipeline_v03/tools/inspect_blender_rig.py` to get the inventory. Clips are written in the character's own frame (flex, turn, tilt, raise, swing), so no bone axis convention is assumed.
2. Run the builder:

   ```sh
   /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
       --python tools/character_animation/build_animated_character.py -- \
       --profile tools/character_animation/profiles/<character_id>.json
   ```

   It refuses to write over its source. It fails if a mapped bone is missing or lies outside the vertices it deforms, or if any skinned mesh is not bound to the rig. It also fails if the GLB lacks a clip's channels or a morph target. Add `--no-render` to skip the Cycles review sheets.
3. Add the GLB to `CharacterVisualPreview.CANDIDATES` and view it with `-- --character-preview=<character_id>`.

Patients' clips use these neutral names only. Movement that suggests a symptom (tremor, posturing, agitation) needs clinical review before it is authored, and is never added by this pipeline.

## Running on the Mac

The builder needs only Blender 5.2.2. It does not need MPFB2 to be enabled, because it works on a .blend that already contains the MPFB body and rig. Naomi's profile also re-runs the first steps of `tools/blender/characters/build_naomi_v03.py` to rebuild clean clothing weights, and those steps need only `assets/blender/characters/Naomi_Bennett_Base_v02.blend`. From an internal-drive clone (never Git on the SSK drive):

```sh
cd ~/ForensicWard_Campaign_Publish
git fetch origin && git switch main
/Applications/Blender.app/Contents/MacOS/Blender --version          # expect 5.2.2
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
    --python tools/character_animation/build_animated_character.py -- \
    --profile tools/character_animation/profiles/staff_bennett.json
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --character-preview=staff_bennett
```

The build writes `assets/exports/characters/Naomi_Bennett_v05.glb`, the v05 .blend, the review sheets in `assets/renders/characters/` and `tools/character_animation/reports/staff_bennett_v05_rig_report.json`. To check MPFB2 itself, run `Blender --background --python-expr "import addon_utils; print([m.__name__ for m in addon_utils.modules() if 'mpfb' in m.__name__.lower()], addon_utils.check('bl_ext.blender_org.mpfb'))"`. MPFB2 is only needed to make a new base body, or to use its CC0 skin, eyebrow and eyelash assets.
