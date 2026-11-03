# Ward-round patients on the ward in 3D — Claude Code handoff, 2026-11-03

Requested by Bi on 2026-11-03: "continue game build focus along with building the cases, tasks, story building making the games and characters playable and interactive with as high def designing as you can". The reading chosen: the ward-round cases were chart-only, so the patients now wait on the ward as animated 3D people the player walks up to.

Branch `claude/ward-round-bedside`, from `claude/ward-rounds` (#115) with `claude/cast-animation` (#114) merged in (it needs the motion clips and `CastPerformer`). Draft PR to `claude/ward-rounds`. Nothing merged by the agent.

## What it does

- Patients whose plan is not yet accepted sit on the bed in **Room 01** and **Room 02** (clinical wing), oldest admission first. Prompt: "See Daniel Ortiz (ward round)". Approaching one opens the ward-round screen on their case; they turn and greet you (`CastPerformer`).
- When a plan is accepted the patient leaves and the next waiting patient takes the room, with a notice ("Ward round: Owen Hughes is waiting in Room 01."). Rooms are empty once every plan is accepted.
- The EHR's Ward round button still works for every case, including cases with no model yet.
- Validated build: only approved cases come to the ward (same rule as the screen).

## Models

Four Chapter 1 patient drafts built with the existing cast pipeline (`build_cast_member.py`, `build_animated_character.py`, `transfer_face_shapes.py`, `refine_character.py`, `add_motion_clips.py`), seated rest pose: Daniel Ortiz, Priya Natarajan, Owen Hughes, Lucia Morales. Each has the shared clips, 32 face morphs, blinks, gaze and the seated motion clips. Appearance is a draft choice (the chart gives only name, age and sex). `PENDING_OWNER_VISUAL_REVIEW`. No symptom movement (dystonia, akathisia) was authored; that needs clinical review first.

## Files

| Area | Paths |
|---|---|
| Staging data (rooms, case → model) | `data/ward_round_bedside.json` |
| Runtime | `scripts/world/WardRoundBedside.gd` (attached by `AuthoredWorld.build_zone`); `Character.gd` gains `Kind.WARD_ROUND` |
| Model configs and outputs | `tools/blender/characters/cast/pt_wr_*.json`, `tools/character_animation/profiles/pt_wr_*`, `reports/pt_wr_*`, `assets/blender/characters/*_v01_draft.blend`, `assets/exports/characters/{Daniel_Ortiz,Priya_Natarajan,Owen_Hughes,Lucia_Morales}_v01_draft.glb`, `assets/asset_manifest/pt_wr_*`, `data/character_visuals.json` |
| Tests | `scripts/tests/test_ward_round_bedside.gd` (6); `test_ward_rounds.gd` `_solve` made static so both use it |
| Capture | `tools/godot/CaptureWardBedside.tscn` → `assets/renders/characters/ward_bedside_v1/` |

## Not done / limits

- Not looked at on the Mac.
- Chapters 2 to 5 cases have no models yet, so they are seen through the EHR only. Adding one = a cast JSON, the five pipeline stages, a `character_visuals.json` entry and a line in `data/ward_round_bedside.json`.
- Hair is the painted scalp shell and clothes are offset shells, like the rest of the cast; Hughes's T-shirt shows a dark fold at the left collar.
- Patients do not speak; approaching opens the chart. Spoken presentations would need written, reviewed lines and voice clips.

## Resume here

1. `git fetch origin --prune`; read the newest `docs/AI_HANDOFF.md` entry.
2. Next models: Chapter 2's four (Kim, Lebel, Brennan, Kowalczyk), same steps.
