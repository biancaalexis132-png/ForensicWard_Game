# Naomi in game: review preview and remaining work

**State (2026-10-18 16:45 UTC, Claude Code):** the preview now defaults to v04, which adds animation and face controls to v03; see "v04 in game" below. Earlier state: Naomi v02 can be viewed in the real Chapter 1 nursing station through a review-only switch. It is **not approved** and is **not** attached by default. Without the switch the game is unchanged: Bennett is the grey capsule.

## What the switch does

`scripts/world/CharacterVisualPreview.gd` reads one command-line argument after `--`:

| Argument | Result |
|---|---|
| (none) | Every character keeps its placeholder. This is how CI, tests and normal play run. |
| `--character-preview=staff_bennett` | Bennett uses the newest candidate, `assets/exports/characters/Naomi_Bennett_v04.glb` (v03 with clips and face morphs) |
| `--character-preview=staff_bennett:v04_local` | The Mac validation build from PR #51 |
| `--character-preview=staff_bennett:v03` | v03 without animation (see `NAOMI_V03_NOTES.md`) |
| `--character-preview=staff_bennett:v02` | Bennett uses v02 (`Naomi_Bennett_Base_v02.glb`) for comparison |
| `--character-preview=staff_bennett:v01` | Bennett uses the older v01 base for comparison |

The model goes through the existing `WardCharacter.set_visual_scene` slot from PR #42, so the capsule comes back if the GLB is missing or invalid. Interaction id, collision, name label, dialogue, Naomi's acting cues, story, clinical data and save files do not change; `scripts/tests/test_character_preview.gd` checks each of these, including that a full Chapter 1 save state is identical with and without the preview.

## View Naomi on the Mac

Use the internal-drive clone, never Git on the SSK drive (see `AGENTS.md`). In Terminal:

```sh
cd ~/ForensicWard_Campaign_Publish            # or any clean internal clone
git fetch origin
git status                                     # commit or stash your own changes first
git switch claude/naomi-animation-v04          # or main once it is merged
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --character-preview=staff_bennett
```

The import step creates the GLB's `.import` file and extracted textures; they are generated, so do not commit them. The Output log prints `Review preview: staff_bennett uses unapproved candidate v04`. Walk from the spawn to the nursing station. In the preview Naomi stands on the office side of the desk and faces the corridor counter, so you see her face through the counter window. Swap the last argument for `staff_bennett:v02` or `staff_bennett:v01` to compare.

From the editor instead: Project > Project Settings > Editor > Run > Main Run Args = `-- --character-preview=staff_bennett`, then press Play. That setting is written to `project.godot`; clear it before committing.

Note any frame-rate observations as owner measurements. Nothing here measures Mac performance.

## v04 in game

Captured in the Linux container on software OpenGL (lighting approximate), with clip and face states frozen so each image shows one control. Files are in `ingame_review_v04/`.

- `v03_face.png` and `v04_neutral.png`: v03 against v04 at rest. v04 adds lashes and darker stroke brows.
- `v04_blink.png`: the `blink` morph closed. In play `CharacterFaceRig` blinks every 2.2 to 5.5 s, sometimes twice.
- `v04_listen.png`: `listen_neutral` with `attentive`: slight lean and head tilt.
- `v04_speak.png`: `stand_conversational` with `warm_subtle` and `mouth_open`. In play the mouth follows a syllable rhythm while her line plays; there is no lip sync.
- `v04_concerned.png`: `concerned_restrained`.
- `v04_counter_idle.png` and `v04_counter_chart.png`: from the counter, idle and mid `restrained_chart_indication`. From here the monitor hides her right forearm, so the gesture barely shows; the Blender sheet `assets/renders/characters/Naomi_Bennett_v04_body_clips.png` shows it, with the scrub hem no longer following the hand.

`v04_face_comparison.png` puts the six face frames side by side.

Still visibly wrong: the new brows read as drawn outlines rather than hair; the blink leaves a visible gap at full value; the speaking mouth is barely visible at this distance; the skin is glossy and plastic-looking; the shoes and trouser hems are lumpy; the eyes do not track the player; a small white square sits by the left temple (already in v03). None of this is approved.

## What the in-game captures show (v02)

Captured in a Linux container with Godot 4.7 on the software (llvmpipe) OpenGL renderer, so lighting and shading are approximate. Files are in `ingame_review_v02/`.

- `ingame_v02_office_front.png`: scale and placement are right (1.70 m, feet on the floor, standing behind the desk). The face reads from the front. The arms are in the bind T-pose and pass through the desk; there is no idle pose.
- `ingame_v02_office_side.png`: from the side, flat skin-coloured strips hang in front of the face and flat navy strips hang down the chest. These are the procedural twists, rendered as broad flat cards.
- `ingame_v02_corridor_window.png`: from the corridor counter the player sees only her back, because the `MARK_Character_NurseBennett` marker faces into the office.

The Blender renders (`assets/exports/characters/Naomi_Bennett_Base_v02_*.png`) show more: the trousers read as one floor-length skirt, sleeve hems are jagged with skin showing through, a stray block sits between the feet, and the eyes and brows are cartoon-scaled.

**Verdict:** v02 is suitable for a technical fit check (scale, rig, import, interaction) and not for appearance approval. `tools/blender/characters/NAOMI_VISUAL_QA.md` items stay unticked.

## Remaining work before Naomi can be the default Bennett

Ordered by what blocks the next step. Owner or artist decisions are marked.

**Model and textures**
1. Hair: replace the flat strip cards with a compact low bun or pulled-back twists that never cross the face (fails QA items 1 and 4).
2. Trousers: two separate straight legs; no skirt silhouette (QA item 6).
3. Sleeves and hems: clean edges, no skin through the cloth, remove the stray block at the feet (QA items 7 and 8).
4. Face: realistic eye and brow scale; skin texture with tone variation instead of flat colour. Likely needs an artist pass or a licensed face/hair asset; the procedural builder has not fixed this across two versions. *Owner decision: keep procedural, or bring in an artist or a licensed asset.*
5. Owner appearance approval against `NAOMI_CHARACTER_SPEC.md`.

**Rigging**
6. The rig has 53 joints and one skin, and no AnimationPlayer. Check deformation of the scrubs at shoulders and hips once an idle pose exists.
7. Face blend shapes or bones for the acting cues (`face`, `gaze`) do not exist; the acting adapter currently has nothing to drive.

**Animation**
8. Idle standing pose (relaxed arms) so she no longer stands in a T-pose: the minimum for in-game review.
9. Breathing, listening, talking and the gesture clips named in `docs/design/characters/Naomi_Acting_Cues_v1/`, exported in the GLB or a separate animation library, wired through `CharacterActingAdapter` groups.

**Placement**
10. Done for the preview (owner decision 2026-10-18: face the counter). `CharacterVisualPreview.PLACEMENT` turns the model 180° and steps it 0.55 m back from the marker to the office side of the desk; see `ingame_review_v02/ingame_v02_counter_facing.png`. The marker itself (inside the desk, facing into the office) is unchanged, so normal play is unchanged; move the marker in world data only when Naomi becomes the default.

**Optimization (8 GB Mac)**
11. v02 is 32,281 triangles in 15 meshes and 11 materials. Merge meshes and materials where the rig allows, add a lower LOD, and cap textures at 2K.
12. Measure Chapter 1 frame time on the MacBook Air with the preview on and off. No performance figure exists yet.

**Then integrate**
13. After approval: set Bennett's model through the normal `visual_scene` path, keep the preview switch for later candidates, and add the next character (Voss or Rahman) to `CharacterVisualPreview.CANDIDATES` using the same builder.
