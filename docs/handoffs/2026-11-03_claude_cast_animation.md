# Cast animation: walking, gestures and shared acting — Claude Code handoff, 2026-11-03

Requested by Bi on 2026-11-03: "review whats currently completed and begin whatever tasks are left including creating full fledged animated characters". Branch `claude/cast-animation`, started from `claude/playtest-fixes` (draft PR #113, unmerged) so it carries those fixes. Draft PR to `main`. Nothing merged by the agent.

## Review of the state on 2026-11-03

- `main` is `e6c5ed7` (#112 final build approvals, merged by Bi). Only open PR: #113 playtest fixes, waiting on Bi for the medication/lab orders decision, listening to the female voice and music level, the three document images, and a Mac replay.
- Characters before this branch: Naomi v07 plus six v01 draft models (Voss, Hale, Rahman, facilities technician, Elias, Mara), each with the ten standard clips (idle, breathing, listen, talk, two workstation turns, four small gestures), blinks, 32 face morphs and eye gaze. What they lacked: no walk clip and no movement in the world; only Naomi acted (the other six looped `idle_neutral` even while speaking); hair is a painted shell and clothes are stiff shells (an unfinished v02 hair/clothing tooling commit sits on `claude/cast-hair-clothing` at `39b3d7c`, not built and not in a PR).

## What this branch adds

| Area | Change | Paths |
|---|---|---|
| Clip library | 8 motion clips: `walk_neutral` (body), `walk_arm_swing`, `explain_open_hand`, `explain_both_hands`, `small_head_shake`, `thinking_pause`, `small_shrug`, `point_direction` (gesture). Standing-only clips skipped for seated Elias and Mara. | `tools/character_animation/clip_library_motion.json` |
| Builder | Builds them onto each committed v01 draft `.blend` in memory with the existing clip builder, grounds the walk (pelvis drop), detaches jacket/trouser panels from the forearms, re-exports the same GLB path. `.blend` not re-saved. Reports with hashes and step length. | `tools/character_animation/add_motion_clips.py`, `reports/*_v01_draft_motion_report.json` |
| Review sheets | Walk side view and gesture peaks (Cycles CPU, poses only). | `tools/character_animation/review_motion_clips.py`, `assets/renders/characters/*_v01_draft_motion_review.png` |
| Models | Six GLBs re-exported: staff 18 clips, patients 15 clips; 32 morphs unchanged; textures unchanged. | `assets/exports/characters/*_v01_draft.glb` |
| Acting | `CastPerformer` for every animated cast member except Naomi: greet/acknowledge nods, talk and listen clips from voiced lines, seeded neutral talk gestures, idle variety, turning to the player (standing only, up to 80°). | `scripts/world/CastPerformer.gd`, `Character.gd` |
| Walking | `CastRoute` from an optional `route` in world data: out and back with pauses, stops for conversation or a nearby player, speed from stride, not saved. Authored for the facilities technician (Ch2) and Hale at the staff door (Ch4, Ch5). Voss's office is too cramped for a clear route, so she stays put. | `scripts/world/CastRoute.gd`, `AuthoredWorld.gd`, `data/world_chapter{2,4,5}.json`, `data/character_visuals.json` (`walk_step_m`), content schema and validator |
| Rig | Loop mode and gesture-player routing for the new clips. | `scripts/world/CharacterAnimationRig.gd` |
| Tests | `test_cast_motion.gd` (10): clips per model and player, Naomi excluded, walk moves thigh and arm, talk/listen/greet, seeded gestures, idle keeps marker facing, route out/back/stops, speed, validation, every authored route clear of walls and props at 0.3/1.0/1.6 m. `test_character_animation.gd` reads both libraries. | `scripts/tests/` |
| Capture | In-world captures of Hale walking his route, Voss explaining and thinking, Elias explaining (Compatibility renderer on Xvfb/llvmpipe, not Mac). | `tools/godot/CaptureCastMotion.tscn`, `assets/renders/characters/cast_motion_v1/` |

A bug found by the full QA run and fixed: `CastPerformer` read its home facing in `_ready`, before `AuthoredWorld` turns the actor to its marker, so idle characters swung to face north. It now reads it on the first frame (test `test_idle_characters_keep_the_facing_they_are_placed_with`).

## Reproduce

```sh
python3.13 -m venv .venv-bpy && .venv-bpy/bin/pip install bpy==5.2.2      # local only, never committed
for id in staff_voss staff_hale staff_rahman staff_facilities_tech pt_elias_ward pt_mara_ellis; do
  .venv-bpy/bin/python -I tools/character_animation/add_motion_clips.py --profile tools/character_animation/profiles/${id}_v01_draft.json
done
xvfb-run -a -s "-screen 0 1280x720x24" Godot --rendering-driver opengl3 --path . res://tools/godot/CaptureCastMotion.tscn -- --output-dir=/tmp/cast_motion
```

(The input is the committed `.blend`, which this branch does not change, so the loop can be rerun as is.)

## Not done / limits

- Not looked at on the Mac: Forward+ look, frame time with walking characters, feel of the turn and walk speed.
- No foot IK: on the walk the stance foot is planted by pelvis drop only; small sliding is possible where the floor is not level.
- No lip-sync change (still the text-based viseme track).
- Hair and clothing quality unchanged; the v02 hair/clothing tooling on `claude/cast-hair-clothing` is unfinished.
- Patients: neutral seated gestures only. Anything symptom-like needs the psychiatrist's review first and was not authored.
- Talk gestures play only on voiced lines (subtitle events). Text-only panels get the greeting/acknowledgement nod and listening pose, not hand gestures.

## Waiting on Bi

1. Watch the walk and gestures in game on the Mac (talk to Voss, Hale in Chapter 4, the technician in Chapter 2).
2. Say whether Voss should get a route (would need a different marker) and whether more staff should walk.
3. #113's pending items are unchanged.

## Resume here

1. `git fetch origin --prune`; read the newest `docs/AI_HANDOFF.md` entry.
2. Changes go on `claude/cast-animation`. If #113 changes, merge `origin/claude/playtest-fixes` into this branch (never rebase).
