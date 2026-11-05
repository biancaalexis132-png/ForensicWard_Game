# Elias encounter redesign — Claude Code, 2026-11-05

Requested by Bi after the 2026-11-04 Mac playtest ("Flesh out the Elias encounter" thread). Branch `claude/elias-encounter` from `main` `144e609`. Draft PR to `main`; no agent merge.

## What Bi asked for

- See the psychiatrist actually do the physical exam, instead of the narrator saying Elias does nothing.
- A real, full history, with information actually drawn out.
- A mute patient needs a 1:1 sitter or another informant.
- Orders should come out of the encounter rather than an abrupt split screen.
- Background staff moving around and doing tasks so the ward looks like a hospital.

Out of scope (the "Finish game for Mac release" thread owns them): Naomi facing you, protagonist voice, Voss walking out, ward-round choices for unseen patients, theme music, Cmd-Q. Medication and lab orders in `data/order_catalog.json` / `ClinicalOrders.gd` belong to the "Player experience overhaul" thread (`claude/meds-labs-draft`); this branch does not edit those files.

## What was built

| Piece | Files |
|---|---|
| Encounter content (PENDING_PSYCHIATRIST_REVIEW): introduction, 10 history domains, 9 exam steps, 21 bedside orders with verdicts and feedback, lab result text, Bennett's antipsychotic challenge, lorazepam reassessment | `data/elias_encounter.json`; five new Elias findings in `data/patients.json` |
| Logic, save provider, review flags, scheduled labs/reassessment, story flags | `scripts/encounter/EncounterManager.gd` (new autoload, one line in `project.godot`) |
| Screen: Introduction / History / Examination / Orders / Reassessment tabs, history checklist, findings, transcript; Elias's non-responses are captions, never narrated | `scripts/ui/EncounterScreen.gd`, `scenes/ui/EncounterScreen.tscn` |
| Staging: the player's psychiatrist (profile gender, skin, hair, outfit tint) walks to Elias and performs each exam step; Elias's arm stays raised; sitter reads the packet from a clipboard; exam camera | `scripts/encounter/EncounterStage.gd`, `scripts/encounter/ExamPoseModifier.gd` (SkeletonModifier3D, analytic two-bone IK, look, lean) |
| Routing: approaching Elias opens the encounter when it is playable (prototype build); validated build keeps the approved InterviewScreen | `scripts/main/Main.gd` (one branch) |
| Six draft models via the existing cast pipeline | `tools/blender/characters/cast/{protagonist_female,protagonist_male,staff_sitter_adler,staff_bg_nurse_a,staff_bg_nurse_b,staff_bg_housekeeping}.json`, `tools/encounter/build_encounter_cast.sh`, `assets/blender|exports/characters/{Psychiatrist_Female,Psychiatrist_Male,Tom_Adler,Ward_Nurse_A,Ward_Nurse_B,Housekeeper}_v01_draft.*`, profiles, manifests, `data/character_visuals.json`, `data/staff.json` |
| Background staff: a nurse walking the corridor, a nurse checking the interview-room window, a housekeeper working down the corridor; each plays a gesture at every stop | `data/world_chapter1.json`; `AuthoredWorld.gd` (`at`/`yaw_degrees`), `CastRoute.gd` (`pause_gestures`), schema/validator |
| Split-screen milestone withdrawn (Bi's playtest) | `data/milestones.json` (`approved: false`, `withdrawn` note); `obj_act` text now names the bedside |
| Review sheet generator | `tools/encounter/build_review_sheet.py` → `/mnt/project-files/elias_encounter/elias_encounter_review.md` |
| Capture tool | `tools/godot/capture_elias_encounter.gd`, `CaptureEliasEncounter.tscn` |

Story flags for other workstreams: `elias_history_complete`, `elias_exam_complete`, `elias_orders_given`, `elias_antipsychotic_ordered`, `elias_antipsychotic_held_by_nursing`, `elias_lorazepam_response_seen`.

## Tests changed

- New `scripts/tests/test_elias_encounter.gd` (9 tests).
- `test_sprint2.gd`: three cinematic-interview tests now set the validated build, because in the prototype build Elias opens the encounter.
- `test_milestones.gd`: shipped milestones must be approved or carry `withdrawn`.
- `test_campaign_cast.gd`: 11 cast members (7 story + sitter + 3 background); background staff face their own yaw.

## Known limits

- Clinical content is all pending Bi's review (four questions at the end of the review sheet). Nothing is marked approved.
- No voice clips for the new lines: they play as timed subtitles. Generating them needs the local Kokoro setup.
- Exam poses are procedural IK over the standing clips; the psychiatrist stands (no sit clip). Ankle exam is a deep lean, not a crouch. Tuned only on Linux llvmpipe captures.
- Protagonist recolouring multiplies the built textures; extreme choices (blond, light skin) may look flat.
- Lab result text duplicates what the meds/labs thread may author in `order_catalog.json`; reconcile when that lands (point bedside items at the catalog ids through `ehr_order`).
- Not tested on the Mac.
