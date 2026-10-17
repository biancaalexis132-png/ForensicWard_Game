# AI handoff

This is where one agent tells the next exactly what it did and where to resume. Rules for writing and reading it are in `AGENTS.md` §7. Newest entry first; never edit or delete an older entry, add a correction in a new one.

A file cannot contain the SHA of the commit that adds it. So each entry records the **latest verified commit** it describes (the last commit whose contents and tests the entry vouches for). The commit that adds the entry sits on top of it; find it with `git ls-remote origin <branch>`. If the branch tip has more than that one doc commit on top of the recorded SHA, someone pushed after the entry was written: read `git log <recorded-sha>..origin/<branch>` before you trust it.

## Active workstreams

One row per branch that someone is working on. Claim the folders or files you will edit, so two agents never change the same file in parallel without a plan. Remove your row when the branch merges or is abandoned.

| Workstream | Branch | Agent / session | Latest verified commit | Claimed files | State |
|---|---|---|---|---|---|
| Ashcroft soundtrack | `claude/ashcroft-soundtrack` (draft PR to `main`) | Claude | `0f555939fd42fa3cd3dd7ccc2b412ad837eb6670` | `audio/cues.json`, `audio/manifest.json`, `docs/AUDIO.md`, `docs/AUDIO_MANIFEST.md`, `systems/audio/AudioDirector.gd`, `tests/audio/TestAudio.gd`, `tests/qa/test_audio_manifest.py`, `tools/audio/build_manifest.py`, `assets/creative_references/**/.gdignore` | Awaiting owner review and a listening pass |
| Foundation F2 zones | `claude/f2-zones` (draft PR to `main`) | Claude | `fb9fc52` (see entry) | `data/zones.json`, `data/world_chapter1.json`, `scenes/main/Main.tscn`, `scripts/main/Main.gd`, `scripts/world/{ZoneDirector,AuthoredWorld,AudioZoneTracker,ImportedDoor,ImportedInteractable}.gd`, `scripts/autoload/{SaveManager,ContentRegistry,EventBus,Settings}.gd` (EventBus: one signal; Settings: one key), `scripts/content/*`, `scripts/tests/test_zones.gd`, `scripts/tests/fixtures/saves/**`, `docs/{PROJECT_STATUS,ID_REGISTRY,F0_FOUNDATION_AUDIT}.md` | Awaiting owner review. F3 waits on the Psychosomatic Bleed decision |

High-conflict files that need an agreed plan before editing: `project.godot`, `scripts/autoload/EventBus.gd`, `scenes/main/Main.*`, `tests/qa/run.py`, `.github/workflows/*`, `README.md`.

## Entry template

Copy this block to the top of the log and fill every field. Write "none" rather than leaving a field out.

```markdown
### YYYY-MM-DD HH:MM UTC · <agent> · <workstream>

- **Branch:** `<branch>` (based on `<base branch>` at `<short sha>`)
- **Latest verified commit:** `<full 40-character sha>` "<subject line>"
- **Confirmed on GitHub:** `git ls-remote origin <branch>` printed `<sha>` at <time>
- **Pull request:** #<n> (draft / ready / merged) or none
- **State:** finished / unfinished but coherent / WIP that does not import (say which file)

**Accomplished**
- <what now works, with file paths>

**Files modified**
- `<path>`: <one line on the change>

**Unfinished**
- `<path>` `<function or node>`: <what it does now, what it still has to do>

**Known errors**
- <exact error text, file:line, how to reproduce> or none

**Tests** (on `<sha>`)
- `<exact command>`: <pass/fail counts, or "not run" and why>
- CI: <link to the run, or "not observed">

**Dependencies not available to remote agents**
- <model weights, local paths, GPU-only tools, Mac-only checks, secrets> or none

**Next steps**
1. <specific action, file path, expected result>
2. ...

**Notes for the other agent**
- <decisions made, things not to touch, questions waiting on the owner>
```

## Log

### 2026-10-17 21:45 UTC · Claude Code · Foundation F2 zones

- **Branch:** `claude/f2-zones` (based on `main` at `4987123`)
- **Latest verified commit:** `fb9fc525fb8cefb0f63fd08ecda4051925ef72bc` "Add zone manifest, ZoneDirector and save version 3"
- **Confirmed on GitHub:** see `git ls-remote origin claude/f2-zones`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; waiting on owner review

**Accomplished**
- `data/zones.json` (global, in `ContentRegistry.MANIFEST`): zones `zone_clinical_wing`, `zone_security_admin` (ground), `zone_research_level` (research), `zone_historic_sublevel` (sublevel), `zone_ward_zero` (placeholder); connections `conn_ward_entry` (seamless door), `conn_restricted_lift` and `conn_service_hatch` (fade). Each zone has its environments, floor-plan bounds and audio rooms, which moved here from `world_chapter1.json`.
- Chapter world files now name a `start_zone`; entries may name a `zone` (default: the start zone) and are wired when that zone is built.
- `ContentValidator`: built zones need existing environments and bounds, zones on one level must not overlap, a connection joins two zones, seamless stays on one level and names door/door zone/anchor, fade names node and arrival per end, world `start_zone` is built, `zone_`/`conn_` prefixes.
- `AuthoredWorld`: `build_zone`, `unload_zone`, `has_zone`, `get_zone_ids`, `get_zone_root`, `get_persistent_nodes`, `find_zone_node`; builds only the start zone in `_ready`; `PlayerSpawn` lives on the world, not the zone.
- `ZoneDirector` (child of `Main`, provider `zones`): current zone from bounds, streams the zone behind a connection door when the player may open it and is within 10 m (or the door is open), always keeps the zone that holds a connection door, fade transitions (time paused, input off, free everything, build target, place on arrival), per-zone door state across unloads, perf CSV behind the `perf_log` setting. `EventBus.zone_changed` added.
- `ImportedDoor.before_open` hook (connection doors build the zone behind first); doors without config read "Records Office door". `ImportedInteractable` uses a method for `game_loaded` so unloaded zones disconnect cleanly; `mesh_aabb` is static.
- `SaveManager` v3: `_migrate_from_2` moves `world.objects` to `zones.objects.zone_clinical_wing`.

**Files modified**
- See commit `fb9fc52`; new `scripts/world/ZoneDirector.gd`, `scripts/tests/test_zones.gd`, `scripts/tests/fixtures/saves/save_v2_ch1_doors_open.json` (a real v2 save captured from `main` at `4987123`: office and interview doors open, player at (-0.5, 0, -12), 09:35).

**Unfinished**
- Arrival points in `zones.json` are hand-placed (`placeholder_arrival`); the environment workstream should add `MARK_Arrival_*` markers.
- Not built: Ward Zero connection, lift stop at the historic landing (needs a floor choice), quality presets.
- Security and research use the `corridor` ambience; `audio/cues.json` has no wing ambience for them.

**Known errors**
- none. Found while testing: Godot's dummy renderer (headless) is not thread-safe for mesh creation; threaded loading there logged "unimplemented base type encountered in renderer scene cull" and leaked meshes. `ZoneDirector.stream_on_threads` is false in headless runs, so CI loads on the main thread and the threaded path is untested until the Mac check.
- Not caused by F2: PR #22 put `assets/creative_references/` (about 42 MB of music and concept boards) inside the Godot project with no `.gdignore`, so Godot imports it and an export would ship it. A one-line `.gdignore` there would stop that if the owner wants.

**Tests** (on `fb9fc52`)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0. Python 6/6, 3/3, 3/3; TestQA 19/0/0; GLB 138/138; TestRunner 112 passed / 0 failed (97 before, 15 new in `test_zones.gd`); TestAudio 271/0.
- Ten lift round trips: static memory +8 KB, object count unchanged.
- CI: not observed yet for this branch

**Dependencies not available to remote agents**
- Mac: transition feel, streaming hitch, frame time and memory with `perf_log` on.

**Next steps**
1. Owner reviews the F2 PR.
2. F3 (anomaly evidence model, flag off) after the owner decides Psychosomatic Bleed (F0 §9).

**Notes for the other agent**
- Geometry belongs to zones (`data/zones.json`); chapter world files only wire gameplay onto it. Do not add `environments` back to a world file.
- Never build two levels at once; the validator rejects overlapping zones on one level.

### 2026-10-17 21:40 UTC · Claude Code · Ashcroft soundtrack

- **Branch:** `claude/ashcroft-soundtrack` (based on `main` at `65b598d`)
- **Latest verified commit:** `0f555939fd42fa3cd3dd7ccc2b412ad837eb6670` "Move exploration music to the records archive per the bible"
- **Confirmed on GitHub:** see `git ls-remote origin claude/ashcroft-soundtrack`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; waiting on owner review

**Accomplished**
- Six Ashcroft OGGs referenced in place from `assets/creative_references/Music/Ready_For_Godot/` (no copies; the `.m4a` sources are not used). Cues `mus_waiting_room`, `mus_compassion`, `mus_procedure`, `mus_temporal_fracture`, `mus_final_revelation`, `mus_main_theme_variant2`; state `hospital_ordinary` on a new `reception` location; contexts `patient_follow_up`, `oversight`, `ward_zero_anomaly`, `final_revelation`, `finale_motif` with begin/end events. Assignments and reasons in `docs/AUDIO.md` "Ashcroft score".
- Ward Zero temporal echo is event-only (`w0_temporal_echo_begin`); tests assert no location or intensity starts it.
- `AudioDirector._apply_music_context`: a play-once context cut short no longer blocks its own finished hook next time.
- Second commit: exploration music moved from the day corridor and nursing station to a new `records_archive` location, per the bible's Chapter 1 cue table. Droppable on its own.
- `.gdignore` in `Visual_References/` and `Music/Suno_Originals/`; manifest scans `Ready_For_Godot` and records Suno provenance.

**Files modified**
- Claimed files in the Active workstreams row.

**Unfinished**
- `data/world_chapter1.json` `audio_zones`: no `reception` or `records_archive` rectangle yet (world owner, F2 zones).
- No story data fires the new events yet.

**Known errors**
- none

**Tests** (on `0f55593`)
- `python3 tests/qa/run.py --godot <Godot 4.7>`: all suites pass; audio 334 passed, 0 failed.
- CI: not observed yet.

**Dependencies not available to remote agents**
- Listening review on the Mac; Suno licence terms for all Suno-tagged tracks (owner).

**Next steps**
1. Owner: listen, confirm the Suno licence, decide whether to keep the Chapter 1 realignment commit.
2. F2 zones: add `reception` and `records_archive` `audio_zones` rectangles when those areas exist.

**Notes for the other agent**
- Concept boards and notes reviewed but not used in game: board names/roles conflict with canon, board 2 cites real actors as likeness references, Ward Zero boards use occult imagery the bible rules out. Details in the PR description.

### 2026-10-17 20:50 UTC · Claude Code · Foundation F1 campaign contract

- **Branch:** `claude/f1-campaign-contract` (based on `main` at `33b2e8c`)
- **Latest verified commit:** `fa098c944aa9f33d9810649b5689c2504a2f5ffc` "Add campaign contract, chapter-scoped story state and save version 2"
- **Confirmed on GitHub:** see `git ls-remote origin claude/f1-campaign-contract`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; waiting on owner review

**Accomplished**
- `data/campaign.json`: institution "Ashcroft State Forensic Hospital", chapters `ch1` (playable) to `ch5` (planned, no content), dialogue file list.
- `ContentRegistry` loads global files from `MANIFEST`, then the dialogue, story and world files the campaign names (document keys `dialogue:<file>`, `story:<chapter>`, `world:<chapter>`). New queries: `get_story(chapter_id)`, `get_world(chapter_id)` (both default to the start chapter), `get_campaign`, `get_institution_name`, `get_chapter_ids`, `get_chapter`, `is_chapter_playable`, static `collect_documents`.
- `ContentValidator`: id prefixes (`ContentSchemas.ID_PREFIXES`) and uniqueness across every file and chapter; campaign rules (chapter id format, playable needs a story, planned ships nothing, start chapter playable); story `chapter` must match its campaign entry; one dialogue file per patient.
- `StoryLogic`: conditions `chapter_completed`, `chapter_flag`; action `start_chapter`. `ChapterDirector` keeps state per chapter; `start_chapter()`, `get_chapter_id()`, `has_completed()`, `get_chapter_flags()`. `EventBus.chapter_started` added.
- `SaveManager` v2: checksum verified on the file as written, then migrations; `_migrate_from_1` moves the flat `chapter` state under `ch1`.
- Docs: `docs/PROJECT_STATUS.md` rewritten from GitHub; `docs/ID_REGISTRY.md`; `docs/design/GDD_AMENDMENTS.md`.

**Files modified**
- See the commit; code in `scripts/autoload/ContentRegistry.gd`, `SaveManager.gd`, `EventBus.gd`, `scripts/content/ContentSchemas.gd`, `ContentValidator.gd`, `scripts/narrative/ChapterDirector.gd`, `StoryLogic.gd`; tests `scripts/tests/test_campaign.gd` (new), `test_content.gd` (fixture helper now uses `collect_documents`).
- Fixtures: `scripts/tests/fixtures/campaign/story_ch{2..5}_fixture.json` (placeholder text, test-only), `scripts/tests/fixtures/saves/save_v1_ch1_night_pending.json` (a real v1 save captured from `main` at `33b2e8c`: Bennett handover fired, Elias note saved, night shift, intercom pending).

**Unfinished**
- Not in F1 by design: observation polarity, zones (F2), anomaly model (F3).
- Known limitation: a delayed beat still pending when a chapter ends stays pending in that chapter; it does not fire after `start_chapter`. No shipped content does this.

**Known errors**
- none. Correction to the F0 entry below: `tools/godot/validate_glb_imports.gd` does not need a `._*` skip. `DirAccess.get_files_at` leaves out hidden files; a planted `._PROBE.glb` passed 138/138 on `main` and on this branch. F0 §1 is corrected.

**Tests** (on `fa098c9`)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0. Python 6/6, 3/3, 3/3; TestQA 19/0/0; GLB 138/138; TestRunner 97 passed / 0 failed (80 before, 17 new in `test_campaign.gd`); TestAudio 271/0.
- CI: not observed yet for this branch

**Dependencies not available to remote agents**
- none

**Next steps**
1. Owner reviews the F1 PR.
2. F2 on `claude/f2-zones` per `docs/F0_FOUNDATION_AUDIT.md` §8: `data/zones.json`, `ZoneDirector`, clinical wing to security wing prototype.
3. F3 waits on the owner's Psychosomatic Bleed decision (F0 §9).

**Notes for the other agent**
- New content goes through `data/campaign.json`; do not add story or world files to `ContentRegistry.MANIFEST`.
- Reserve ids in `docs/ID_REGISTRY.md` before using them. Merged branches' rows were removed from the workstream table above.

### 2026-10-17 20:30 UTC · Claude Code · Foundation F0 audit

- **Branch:** `claude/f0-foundation-audit` (based on `main` at `d21cff7`)
- **Latest verified commit:** `06fd50ad534dc0fb4847800eaf59b7bf6b513076` "Add F0 foundation audit and five-chapter architecture proposal"
- **Confirmed on GitHub:** see `git ls-remote origin claude/f0-foundation-audit`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; docs only, waiting on owner review

**Accomplished**
- `docs/F0_FOUNDATION_AUDIT.md`: implemented-vs-planned inventory, contradictions C1–C14 (Ward Zero canon, act names, player title, staff roles, Psychosomatic Bleed, pharmacology clue gates, stale PROJECT_STATUS), id scan (74 ids, no duplicates), proposed campaign/zone/anomaly architecture, reuse table, zone loading plan, clinical vs supernatural separation rules, F1–F3 scopes with acceptance tests, open approvals.

**Files modified**
- `docs/F0_FOUNDATION_AUDIT.md`: new.
- `docs/AI_HANDOFF.md`: this entry and a workstream row.

**Unfinished**
- none. `docs/PROJECT_STATUS.md` is stale (C14) but deliberately not edited here, to avoid conflicting with PR #19; F1 rewrites it.

**Known errors**
- none. Noted for F1: `tools/godot/validate_glb_imports.gd` does not skip `._*.glb` (local Mac only); `SaveManager.load_game` compares the checksum after migrating, so the first real migration needs the order fixed.

**Tests** (on `d21cff7`, the tree this branch adds docs to)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0; Python 6/6, 3/3, 3/3; TestQA 19/0/0; GLB 112/112; TestRunner 80/0; TestAudio 271/0.
- CI: not observed yet for this branch

**Dependencies not available to remote agents**
- none for F0. Mac checks listed in the audit stay untested.

**Next steps**
1. Owner reviews `docs/F0_FOUNDATION_AUDIT.md` and answers the approvals in its section 9.
2. After approval and after PR #19 merges: F1 on a new branch `claude/f1-campaign-contract` per section 8.

**Notes for the other agent**
- This branch and PR #19 both add an entry at the top of this log; whichever merges second resolves it by keeping both entries.
- Do not start F1–F3 structural changes before the owner approves F0 in the F0 thread or PR.

### 2026-10-17 20:20 UTC · Claude Code · Environment Stage 5 historic substructure

- **Branch:** `claude/environment-stage-5` (from `main` after PR #17), then `main` at `d21cff7` merged in
- **Latest verified commit:** `e57560e` "Build Stage 5 historic substructure: 13 props, 13 sublevel rooms", plus merge `faf6f50` of `main`
- **Confirmed on GitHub:** see `git ls-remote origin claude/environment-stage-5`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- 13 historic props (`assets/exports/historic/props/`): iron bed, instrument cabinet, hydrotherapy tub, exam table, steel desk, wooden chair, card index (one drawer missing), medication shelf, knife-switch fuse panel, caged bulkhead lamp, records vault door, steep service stair, cast-iron radiator. 17 aged palette materials in `fw_lib.py`.
- 13 spaces (`assets/exports/historic/env/`) on a sublevel with the Chapter 1 x/y and floor z = 0: a 24 m historic corridor with the lift landing under (0, 44), the mechanical corridor, the sealed connecting corridor (brick infill is `state_group: sealed_corridor_end` for Stage 6), records archive, admin office, former patient rooms 1 and 2, abandoned nursing station, two observation cells, hydrotherapy treatment room, medication storage, stairwell (stair top under the Stage 4a hatch, asserted) and the records vault.
- Uneven tungsten lighting: watts vary, some `LIGHTMARK_*` carry `flicker: true`, dead lamps have no light. Hooks carry `story_tag: historic_record`; medical-looking documents are `clinical_review_status: PENDING`.
- Render review fixed a black observation shot (camera moved into the lit cell; the dark cell keeps `CAM_OB_DarkCell`) and moved the vault shelving clear of the door swing.

**Files modified**
- New: `tools/blender/build_stage5_historic.py`, `assets/blender/historic/*.blend`, exports and their `.import` files, `assets/renders/stage5/*.png`.
- `tools/blender/fw_assets.py`, `tools/blender/fw_lib.py` (Stage 5 sections), `assets/asset_manifest/asset_manifest.{json,md}`, `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- Not wired into gameplay: no level scene, no stair climb interaction, no lift or hatch transition.
- Placement, layout, the hydrotherapy fit-out and every storytelling detail are assumptions for creative review.

**Known errors**
- The service stair is about 60 degrees, too steep to walk; it needs a climb interaction. Its collider only blocks walking through it.

**Tests** (on the merged tree, before this doc commit)
- `python3 tests/qa/run.py` with Godot 4.7 (4.7.stable.official.5b4e0cb0f): exit 0. Python suites 6/6, 3/3, 3/3, TestQA 19 / 0 / 0, `.glb` validation 138/138, TestRunner 80 / 0, TestAudio 271 / 0, "All executed checks passed".
- `build_stage5_historic.py` with Blender 5.0.1 (`bpy`): "STAGE5 HISTORIC OK: 13 props, 13 environments exported".

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look in Godot).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 6 Ward Zero, opened from the sealed corridor's brick `state_group`.
3. Gameplay: the stair climb and the lift and hatch transitions.

### 2026-10-17 19:55 UTC · Claude Code · Audio: original soundtrack

- **Branch:** `claude/audio-production` (based on `claude/remove-appledouble-metadata` at `9af90fc`; `main` at `cccbe09` merged in after PR #15 and PR #17 landed)
- **Latest verified commit:** `ab613f16ecbec0e3f774090de22f56dfe9cb9607` "Skip macOS AppleDouble files when AudioDirector loads narrative data"
- **Confirmed on GitHub:** `git ls-remote origin claude/audio-production` printed `ab613f1` at 19:52 UTC; this doc commit sits on top
- **Pull request:** #18 (draft) to `main`; PR #15 has merged
- **State:** finished; waits on the owner's listening review on the Mac

**Accomplished**
- The five tracks in `assets/audio/music/` play through `AudioDirector`, unmodified: main theme for the main menu, alternate theme for a cinematic, emotional theme for emotional scenes, narrative theme for exploration, credits theme for the ending. Details and the trigger events are in `docs/AUDIO.md` → Soundtrack.

**Files modified**
- `audio/cues.json`: five `mus_*` cues (levelled to about -20 LUFS with `volume_db`), `music_states.exploration`, `music_contexts` (`main_menu`, `cinematic`, `emotional`, `ending_credits`), exploration music for corridor and nursing station by day, events `music_main_menu`, `music_cinematic`, `music_emotional_begin`/`_end`, `music_credits`.
- `systems/audio/AudioDirector.gd`: music contexts (stacked, stop/duck ambience, play-once contexts end themselves), location music that fades out in rooms without a state, `loop_crossfade` and `tail_fade` + `repeat_after` repeats, context duck added to dialogue duck, `._*` skipped in `_load_narrative`.
- `scripts/ui/PauseMenu.gd`, `scenes/ui/PauseMenu.tscn`: Audio section with Master, Music, Dialogue, Sound effects and Ambience sliders and a reduce-startling-audio toggle, all through `AudioDirector.set_setting`. Panel is 200 px taller.
- `tools/audio/build_manifest.py`, `tests/qa/test_audio_manifest.py`: manifest also covers `assets/audio/`; references through music states and contexts; contexts validated.
- `audio/manifest.json`, `docs/AUDIO_MANIFEST.md`: five soundtrack entries (regenerated). `assets/audio/music/*.ogg.import`: committed import sidecars (`loop=false`).
- `tests/audio/TestAudio.gd`, `docs/AUDIO.md`.

**Unfinished**
- none in code. Nothing fires `music_main_menu`, `music_cinematic`, `music_emotional_begin`/`_end` or `music_credits` yet: there is no title screen, cinematic or credits scene, and no story beat is marked emotional.

**Known errors**
- none

**Tests** (on `ab613f1`)
- `python3 tests/qa/run.py --godot <4.7-stable linux, SHA-512 verified>` on `21cba85`: exit 0; QA_RESULT 19 passed / 0 failed / 0 skipped; sprint tests 80 passed / 0 failed; AUDIO_RESULT 271 passed / 0 failed (211 before); GLB validation 92 assets, 0 failures; Python content 6/6, audio manifest 3/3, music pipeline OK.
- `ab613f1` only adds the `._*` skip: `godot --headless --path . res://tests/audio/TestAudio.tscn` gave 271 passed / 0 failed, also with a planted `data/narrative/._probe.json`.
- CI: `validate` run 39063043515 passed on `f191570` (before the merge of `main`)
- Headless uses the Dummy audio driver: playback, timing, fades and ducks are checked, not how anything sounds.

**Dependencies not available to remote agents**
- Listening review of the mix, the loop crossfades and the exploration level needs the owner's Mac. `build_manifest.py` needs `soundfile`, `numpy`, `scipy` (`tools/audio/requirements.txt`).

**Next steps**
1. Owner: review PR #18; play the corridor by day and check the narrative theme sits under the ambience (`mus_narrative` `volume_db` in `audio/cues.json`).
2. Owner: record the soundtrack's authorship and licence; the manifest entries say it is still to be confirmed.
3. Whoever builds the title screen, cinematics, credits or an emotional story beat: fire the matching event from the table in `docs/AUDIO.md` → Soundtrack (for example `EventBus.narrative_event_fired.emit("music_main_menu", {})`), or call `AudioDirector.start_music_context`.
4. Optional: decide whether night exploration should get music; today night is deliberately silent.

**Notes for the other agent**
- Do not re-encode or normalize files in `assets/audio/music/`; change levels with `volume_db` in `audio/cues.json`. `music_main_theme.m4a` is an unused duplicate (Godot cannot import `.m4a`).
### 2026-10-17 19:45 UTC · Claude Code · Environment Stage 4b research wing

- **Branch:** `claude/environment-stage-4b` (from `claude/environment-stage-4` at `6e2fdf6`, then `main` at `66a274f` merged in)
- **Latest verified commit:** `90315575dd91f9fe8c8fd480b63c52309ed0c1cb` "Build Stage 4b research wing: 8 props, 12 rooms on the research level", plus merge `96b0f8b` of `main`
- **Confirmed on GitHub:** see `git ls-remote origin claude/environment-stage-4b`; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- 8 research props (`assets/exports/research/props/`): reception counter, reclining assessment chair, lab bench, benchtop centrifuge, upright ultra-low freezer, dual-monitor workstation, server rack, whiteboard with wiped-marker residue.
- 12 rooms (`assets/exports/research/env/`) on the research level the restricted lift serves. It uses the same x/y as Chapter 1 with its floor at z = 0, and the lift sits at (0, 44) as below (asserted). Reception, a 12 m research corridor, a badge-and-PIN door at y = 28, and an 8 m restricted corridor. Rooms: physician offices A and B (B vacated), data analysis, records archive (one bay emptied), unsigned protocol office, clinical assessment room (one-way window into observation; clinician nearer the exit, asserted), observation and monitoring, lab support, secure sample storage (one unlabelled, double-locked freezer).
- Storytelling hooks carry `story_tag: research_inconsistency` and a `godot_hint` that describes only what the player sees. The protocol binder is `clinical_review_status: PENDING`.
- PR #14 merged at `bb4ecf7`, before the 4a facing fix (`400770b`, `6e2fdf6`). That fix reaches `main` through this branch.

**Files modified**
- New: `tools/blender/build_stage4_research.py`, `assets/blender/research/{FW_Props_Research,FW_ResearchWing}.blend`, exports and their `.import` files, `assets/renders/stage4/research_*.png`, `props_research.png`.
- `tools/blender/fw_assets.py` (Stage 4b section), `tools/blender/fw_lib.py` (8 palette materials), `assets/asset_manifest/asset_manifest.{json,md}` (112 records), `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- Not wired into gameplay: no level scene, and no lift transition between the security and research levels.
- Level placement, layout, the receptionist marker and every storytelling detail are assumptions for creative review. The GDD names no research staff, so no named markers.

**Known errors**
- Cycles previews show the one-way glass mirrored from both sides because Cycles renders back faces. Godot should cull them; not checked in Godot yet.

**Tests** (on the merged tree, before this doc commit)
- `python3 tests/qa/run.py` with Godot 4.7 (4.7.stable.official.5b4e0cb0f) after merging `main`: exit 0. Python content 6/6, audio manifest 3/3, `.glb` validation 112/112, TestRunner 80 / 0, TestQA 19 / 0 / 0, TestAudio 211 / 0, "All executed checks passed". The music `.ogg.import` files Godot generated were left uncommitted for the music workstream.
- `build_stage4_research.py` with Blender 5.0.1 (`bpy`): "STAGE4 RESEARCH OK: 8 props, 12 environments exported".

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look, one-way glass in Godot).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 5 historic asylum substructure, reached from the maintenance hatch (`MA_ServiceHatch`) and the lift's sublevels.
3. Gameplay: a lift transition between the security and research levels.

### 2026-10-17 19:30 UTC · Claude Code · CI fix: macOS AppleDouble files

- **Branch:** `claude/remove-appledouble-metadata` (based on `main` at `782f642`)
- **Latest verified commit:** `a0c00e8b97ee1d804d2ecb9484760b6f0b866483` "Remove macOS AppleDouble files and skip them in content QA"
- **Confirmed on GitHub:** `git ls-remote origin claude/remove-appledouble-metadata` printed `a0c00e8` at 19:28 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished

**Accomplished**
- `main` at `782f642` ("will music i think") tracked 583 `._*` AppleDouble files written by macOS on the exFAT SSD; `tests/qa/test_json.py` failed with `UnicodeDecodeError` on `data/patients/._PT-001.json`. All 583 untracked; every one had the AppleDouble magic and a genuine companion file, which is kept.

**Files modified**
- `.gitignore`: ignores `._*`, `.DS_Store`, `.AppleDouble`, `.Spotlight-V100`, `.Trashes`, `.fseventsd`, `__MACOSX/` and similar.
- `tests/qa/test_json.py`: `content_files()` skips `._*` and `__MACOSX`; UTF-8 reads; new tests for the skip rule and for no tracked macOS metadata.
- `tests/qa/test_audio_manifest.py`: same skip for `audio/` and `data/narrative/`.

**Unfinished**
- none

**Known errors**
- Runtime loaders that list folders (`systems/audio/AudioDirector.gd` `_load_narrative`, `tools/godot/validate_glb_imports.gd`) do not skip `._*`; on the exFAT drive untracked `._*.json` files would still reach them. Not changed here.

**Tests** (on `a0c00e8`)
- `GODOT=<4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py`: exit 0, QA_RESULT passed=19 failed=0 skipped=0, AUDIO_RESULT passed=211 failed=0, Python content 6/6 and audio 3/3 OK. Also passed with planted `._*` files in `data/patients`, `data/narrative` and `audio`.
- CI: not observed yet

**Dependencies not available to remote agents**
- none

**Next steps**
1. Owner: run `dot_clean -m .` in the project folder on the Mac (or keep the project on an APFS volume) so the files stop reappearing locally.
2. The headless import generated `.import` files for the five `assets/audio/music/*.ogg` tracks from `782f642`; they were not committed here. Commit them with the music workstream.

**Notes for the other agent**
- No PR #20 existed; the failure was on `main` itself, so the fix is on this branch per AGENTS.md §3.

### 2026-10-17 19:05 UTC · Claude Code · Stage 4a facing fix

- **Branch:** `claude/environment-stage-4` (PR #14)
- **Latest verified commit:** `400770b` "Fix facing of two terminals and the interview intercom in the security wing" (full SHA via `git log -1 400770b`)
- **State:** finished; this adds to the 18:45 entry below.

**Accomplished**
- `VS_Terminal_VisitorLog` and `MD_Terminal` now face their users, and `SI_Intercom` faces into the room. Only `ENV_VisitorScreening`, `ENV_MedicalDirectorOffice` and `ENV_SecureInterviewSuite` (plus the wing `.blend` and their renders) changed.

**Tests** (on `400770b`)
- `python3 tests/qa/run.py` with Godot 4.7: exit 0. 92/92 `.glb`, TestRunner 80/0, TestQA 19/0/0, TestAudio 211/0.

**Next steps**
- Unchanged from the 18:45 entry. Stage 4b research wing is on `claude/environment-stage-4b`, stacked on this branch.

### 2026-10-17 18:45 UTC · Claude Code · Environment Stage 4a security and admin wing

- **Branch:** `claude/environment-stage-4` (based on `main` at `6feaaa5`, which includes PR #13)
- **Latest verified commit:** `4180b3fa86a76065634587b47f7d42897f3be68b` "Build Stage 4a security and admin wing: 13 props, 11 rooms"
- **Confirmed on GitHub:** `git ls-remote origin claude/environment-stage-4` printed `4180b3f` at 18:43 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- 13 security and admin props (`assets/exports/security/props/`): security console, 3x2 video wall, key cabinet, staff lockers, walk-through detector, conference table, waiting seats, executive desk, badge printer, elevator doors (leaves `_Leaf_L/_R` with colliders), electrical panel, wall pipes, wall display.
- 11 rooms (`assets/exports/security/env/`) in the shared Chapter 1 frame, north of y = 20: security corridor with interlock doors at y = 32, visitor screening, credentialing, records office, medical director's office (Voss marker), conference room, secure interview suite (clinician seat nearer the exit, asserted), security control (Hale marker, window onto the corridor), surveillance monitoring, maintenance access (service hatch hinting at Stage 5), restricted lift lobby. Each has camera markers, collision and light markers.

**Files modified**
- New: `tools/blender/build_stage4_security_admin.py`, `assets/blender/security/{FW_Props_Security,FW_SecurityAdminWing}.blend`, the exports and their Godot `.import` files, `assets/renders/stage4/*.png`.
- `tools/blender/fw_assets.py` (Stage 4 section), `tools/blender/fw_lib.py` (10 palette materials), `tools/blender/build_stage2_chapter1.py` (`room_shell` optional `light_color`, default unchanged; Stage 2 not rebuilt).
- `assets/asset_manifest/asset_manifest.{json,md}`, `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- The floor plan and room adjacencies are assumptions (the GDD names the rooms, not a layout); labelled in `docs/ENVIRONMENT_STAGES.md`.
- The wing is not yet wired into gameplay (`data/world_chapter1.json`, `AuthoredWorld`); the clinical corridor's north end has no door into it yet.
- Stage 4b research wing not started.

**Known errors**
- none.

**Tests** (on `4180b3f`, plus this commit's doc-only changes)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f): exit 0. `.glb` validation 92/92, TestRunner 80 passed / 0 failed, TestQA 19 / 0 / 0, TestAudio 211 / 0, "All executed checks passed".
- `build_stage4_security_admin.py` with Blender 5.0.1 (`bpy`): "STAGE4 SECURITY OK: 13 props, 11 environments exported".
- CI: not observed yet; check the PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look, walking the wing in play).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 4b research wing on a new branch from `main`: reception, clinical assessment, physician offices, lab support, secure sample storage, data analysis, research records archive, observation room, restricted corridor, the undisclosed protocol office. Keep it ordinary-looking, not overtly sinister.
3. Later: connect the clinical corridor's north end to the security corridor in gameplay.
4. Still open: close PRs #1, #6, #7 and #8, which are fully contained in `main`.

### 2026-10-17 18:35 UTC · Claude Code · Nursing-station equipment

- **Branch:** `claude/nursing-station-props` (based on `main` at `6742dc8`, which includes PR #12)
- **Latest verified commit:** `de77fe92e323cc998cb500aef2b8bff520ded842` "Place Stage 3 equipment at the nursing station"
- **Confirmed on GitHub:** `git ls-remote origin claude/nursing-station-props` printed `de77fe9` at 18:33 UTC; this doc commit sits on top
- **Pull request:** PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- `ENV_NursingStation` now holds `NS_MedicationCart` and `NS_SharpsBin` (west wall), plus `NS_CrashTrolley`, `NS_AED` and `NS_HandGel` (south wall). All are clear of the inward door swing (x -2.5..-1.5, y 8.5..9.5). Room bounds and existing node names are unchanged, so `data/world_chapter1.json` interactables (`NS_Terminal_EHR`, `NS_NoticeBoard`) still resolve.

**Files modified**
- `tools/blender/build_stage2_chapter1.py`: five `place()` calls in `build_nurse_station`.
- `assets/blender/clinical/FW_Chapter1_ClinicalWing.blend`, `assets/exports/clinical/env/ENV_NursingStation.glb`, `assets/asset_manifest/asset_manifest.json` (nursing-station record: materials, triangles), `assets/renders/stage2/{nursing_station,chapter1_plan}.png`.
- The rebuild also rewrote the corridor, interview-room and archive `.glb` files byte-wise with identical structure (as the integration entry observed); those were restored to the committed versions.
- `docs/ENVIRONMENT_STAGES.md`, `docs/PROJECT_STATUS.md` (environment rows), this file.

**Unfinished**
- The new items are geometry only: none is an interactable yet (no `data/world_chapter1.json` entries).
- The existing `CAM_NS_Establishing` render does not frame the south and west walls, so the new items show only in `chapter1_plan.png`.

**Known errors**
- none.

**Tests** (on `de77fe9`, plus this commit's doc-only changes)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f): exit 0. `.glb` validation 68/68 (`ENV_NursingStation`: 23 meshes, 11 colliders), TestRunner 80 passed / 0 failed, TestQA 19 / 0 / 0, TestAudio 211, "All executed checks passed".
- `tools/blender/build_stage2_chapter1.py` with Blender 5.0.1 (`bpy`): "STAGE2 OK: 7 environments exported".
- CI: not observed yet; check the PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+ look, walking around the new trolley in play).

**Next steps**
1. Owner reviews and merges this PR.
2. Stage 4 (security, admin and research wings): new `tools/blender/build_stage4_*.py` on `claude/environment-stage-4` from `main`.
3. Optional: make `NS_MedicationCart` an interactable (locked drawer) once a medication-administration design is approved; it must not apply any clinical rule before psychiatrist review.
4. Still open: close PRs #1, #6, #7 and #8, which are fully contained in `main`.

### 2026-10-17 18:05 UTC · Claude Code · Environment Stage 3 props

- **Branch:** `claude/environment-stage-3` (based on `main` at `592c6af`)
- **Latest verified commit:** `5f5c51561ab139e22251bbce9869ec9a312b88a8` "Stop tracking the Blender backup FW_Modular_Kit.blend1"
- **Confirmed on GitHub:** `git ls-remote origin claude/environment-stage-3` printed `5f5c515` at 17:50 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- Environment Stage 3 is complete: 10 new library props for medication, ward beds, linen and emergency equipment (`PROP_Cart_Medication`, `PROP_Bed_Hospital_Adjustable`, `PROP_Trolley_Linen`, `PROP_Cart_Crash_Resus`, `PROP_Cabinet_AED_Wall`, `PROP_Cylinder_Oxygen_Trolley`, `PROP_Monitor_VitalSigns_Stand`, `PROP_Bin_Sharps`, `PROP_Dispenser_HandGel`, `PROP_Wheelchair`). Each has a `.blend` source, a `.glb` export, a manifest record (staff-only / supervised) and appears in a preview render.
- Removed the tracked `assets/blender/modular/FW_Modular_Kit.blend1` backup (follow-up 3 of the integration entry).

**Files modified**
- `tools/blender/fw_lib.py`: 5 palette materials (med-cart blue, sharps yellow, AED green, linen white, laundry-bag blue).
- `tools/blender/fw_assets.py`: `_castors` helper, 10 builders, `STAGE3_PROP_BUILDERS`. Existing builders unchanged.
- `tools/blender/build_stage3_props.py`: new generator writing `FW_Props_Clinical_Stage3.blend`, exports, manifest and `assets/renders/stage3/props_stage3.png`.
- `assets/exports/clinical/props/*.glb` (+ Godot `.import` files), `assets/asset_manifest/asset_manifest.{json,md}`: 10 new assets (68 total); no existing record changed.
- `docs/ENVIRONMENT_STAGES.md`, `docs/ENVIRONMENT_PIPELINE.md`, `docs/PROJECT_STATUS.md` (environment rows only), this file.

**Unfinished**
- The Stage 3 props are library assets only; none is placed in an `ENV_*` room or `scenes/world/Chapter1Ward.tscn` yet.

**Known errors**
- none.

**Tests** (on `5f5c515`, plus this commit's doc-only changes)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f, SHA-512 verified): exit 0. TestPharmacology 0 failures, TestQA 19 passed / 0 failed / 0 skipped, `.glb` validation 68/68, TestRunner 80 passed / 0 failed, TestAudio 211 passed, all Python suites OK, "All executed checks passed".
- Baseline on `main` `592c6af` before any change: same command, exit 0, 58/58 `.glb`, TestRunner 80/0, TestAudio 211.
- `tools/blender/build_stage3_props.py` with Blender 5.0.1 (`bpy`, Python 3.11): "STAGE3 PROPS OK: 10 assets exported".
- Render checked by eye in Cycles (CPU). Not evidence of the look in Forward+ on the Mac.
- CI: not observed yet; check the draft PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+/Metal look of the new props). The `bpy` virtualenv used here is local to the container and not committed.

**Next steps**
1. Owner reviews and merges the Stage 3 draft PR.
2. Place the medication cart, crash trolley, AED cabinet and hand-gel dispenser at the nursing station: extend `build_stage2_chapter1.py` (`ENV_NursingStation`), rebuild, re-run `.glb` validation and `run.py`, and check `scenes/world/Chapter1Ward.tscn` still loads.
3. Stage 4 (security, admin and research wings): new `tools/blender/build_stage4_*.py` on a new `claude/environment-stage-4` branch from `main`.
4. Still open from earlier entries: close PRs #1, #6, #7 and #8, which are fully contained in `main`.

**Notes for the other agent**
- Do not rebuild the Stage 1 `.blend` just to pick up the new palette entries; Stage 1 assets do not use them.

### 2026-10-17 17:40 UTC · Claude Code · Sprints 1–3 integration

- **Branch:** `claude/integration-sprints-1-3` (based on `claude/chapter1-playable` at `b11f58c`, with `main` at `f6efda8` merged in)
- **Latest verified commit:** `99c2eaf453e13d44932f73a7c7f30ad54a18bf3e` "Merge main (audio PR #5) into the Sprints 1-3 integration branch"
- **Confirmed on GitHub:** `git ls-remote origin claude/integration-sprints-1-3` printed `99c2eaf` at 17:25 UTC; this doc commit sits on top
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- Checked every source branch with `git merge-base --is-ancestor`: `claude/chapter1-playable` already contained PRs #1, #8, #6, #9 and #10. Only `main`'s PR #5 (audio) was missing. Merged `origin/main` into a new branch from `claude/chapter1-playable`; no cherry-picks, no rewritten history.
- Compared every file on each source branch with the integrated tree. Nothing functional is missing; see `docs/INTEGRATION_SPRINTS_1_3.md` → Functionality check.

**Files modified**
- `README.md`: merge conflict resolved (integrated layout plus `main`'s audio, music AI and agent-rules entries).
- `docs/INTEGRATION_SPRINTS_1_3.md`: new. Branch provenance, conflict resolution, per-file preservation check, full test report, open items.
- `docs/PROJECT_STATUS.md`, `docs/AI_HANDOFF.md`: this branch's rows and entry.

**Unfinished**
- none in this branch.

**Known errors**
- none. Expected warnings come only from negative tests (save tamper, note validation, locked dialogue choice).

**Tests** (on `99c2eaf`)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f, SHA-512 verified): exit 0. JSON 4 OK, audio manifest 3 OK, music AI 3 OK, TestPharmacology 0 failures (8 cases), TestQA 19 passed / 0 failed / 0 skipped, `.glb` validation 58/58, TestRunner 80 passed / 0 failed, boot OK, TestAudio 211 passed, Ch1 audio sequence done.
- Blender 5.0.1 (`bpy`, Python 3.11) re-ran `tools/blender/build_stage1_modular.py`, `build_stage1_props.py`, `build_stage2_chapter1.py` in a scratch copy: STAGE1 OK 25, PROPS OK 26, STAGE2 OK 7; rebuilt exports pass `.glb` validation 58/58. 8 rebuilt `.glb` differ byte-wise from the committed ones with identical glTF structure; committed files left unchanged.
- CI: not observed yet; check the draft PR.

**Dependencies not available to remote agents**
- Mac-only checks (Forward+/Metal rendering, input feel, audio mix). ACE-Step and Stable Audio need the owner's Mac.

**Next steps**
1. Owner reviews and merges the integration draft PR into `main`.
2. After it merges, close PRs #1, #6, #7 and #8 (all fully contained). PRs #9 and #10 are already closed.
3. Follow-up: remove the tracked `assets/blender/modular/FW_Modular_Kit.blend1` backup (now gitignored).
4. Next feature work branches from `main` after the merge, in the `scripts/` layout.

**Notes for the other agent**
- `claude/environment-production` was still at `e321b4a` when this branch was built. If that session pushes more, merge `origin/claude/environment-production` into a continuation branch from this one rather than into the old PRs.
- Do not reintroduce `autoload/`, `staging/` or `main`'s old demo `scenes/main/Main.gd`.

### 2026-10-17 · Claude Code · Sprint 3 story, evidence board, shift loop

- **Branch:** `claude/sprint-03-evidence-shift` (based on `claude/sprint-02-ehr-interview` at `0f36185`)
- **Latest verified commit:** the commit carrying this entry; `git ls-remote origin claude/sprint-03-evidence-shift`
- **Pull request:** draft, stacked on #9 (merge order #8, #6, #7, #9, then this PR)
- **State:** finished; imports and passes every suite

**Accomplished**
- The Chapter 1 slice plays from start to finish:
  1. Bennett handover (audio scene and subtitles).
  2. Interview Elias, document, act.
  3. Collect the transfer summary and roster, link them on the evidence board, argue the hypothesis.
  4. Sign out at the handover board; a documented handover earns Bennett's trust.
  5. Night shift; 15 minutes later the intercom calls W-Zero-B and the EHR logs a transfer request under an inactive credential.
  6. Read the W0-B door log; a trusted Bennett corroborates it.
  7. Sign out for the night; the end summary appears.
- None of these steps blocks progress, and every one survives save and load.

**Files modified**
- New:
  - `scripts/narrative/StoryLogic.gd`: closed condition and action vocabulary, validated.
  - `scripts/narrative/ChapterDirector.gd`.
  - `data/story_chapter1.json`.
  - `scripts/ui/EvidenceBoard.gd` and `scenes/ui/EvidenceBoard.tscn`.
  - `scripts/world/AudioZoneTracker.gd`.
  - `scripts/tests/test_sprint3.gd`.
- `scripts/main/Main.gd`:
  - evidence panel and Tab handling;
  - director and audio tracker nodes;
  - `_silence_audio` on exit;
  - graceful quit on window close (`auto_accept_quit` false while Main lives).
- `scenes/main/Main.tscn`: EvidenceBoard, ChapterDirector and AudioZoneTracker nodes.
- `scripts/ui/PauseMenu.gd`: Quit uses the same graceful path.
- `scripts/ui/HUD.gd`: objective and subtitle labels.
- `scripts/autoload/EventBus.gd`: `objective_changed`, `story_beat_fired`, `shift_signout_requested`, `chapter_completed`.
- `scripts/autoload/EvidenceManager.gd`: `get_verifications`; verifications deduped per method.
- `scripts/autoload/PatientManager.gd`: `add_chart_entry` (audit only).
- `scripts/world/{Character,ImportedInteractable}.gd`: situational staff lines; `shift_signout` type.
- Content layer and data:
  - `scripts/content/*` and `ContentRegistry.gd`: story schema and validation;
  - world `audio_zones`;
  - `data/world_chapter1.json`: handover board and audio zones.

**Unfinished**
- GDD beat 4 (second stable patient hinting at a missing clinician) needs a second authored patient.
- Only the `corridor` and `nursing_station` audio locations exist; other rooms fall back to the corridor.
- Story lines are `[Placeholder]`.

**Known errors**
- none.
- Headless runs no longer start ambience. A stream still playing at quit was reported as `ERROR: resources still in use`, which run.py treats as a failure.

**Tests** (on this branch)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0.
  - TestQA: 19/0/0.
  - GLB validation: 58 assets.
  - TestRunner: 80 passed.
  - TestAudio: 92 passed.
  - Ch1 audio sequence: done.
- CI: not observed.

**Next steps**
1. Act I completion: author a second patient (GDD beat 4) in `data/patients.json` and `data/dialogue.json` (dialogue then needs one document per patient; `ContentRegistry` indexes a single dialogue file today), plus a Voss orientation beat (beat 1).
2. Environment Stage 3/4 on `claude/environment-production`: medication room, a second interview room, security control, plus character stand-in meshes better than capsules.
3. Pharmacology in the EHR as governed rules (needs approval records per rule).

### 2026-10-17 · Claude Code · Sprint 2 EHR and interview

- **Branch:** `claude/sprint-02-ehr-interview` (based on `claude/chapter1-playable` at `7b11143`)
- **Latest verified commit:** the commit carrying this entry; `git ls-remote origin claude/sprint-02-ehr-interview`
- **Pull request:** #9 (draft, stacked on #7; merge order #8, #6, #7, #9)
- **State:** finished; imports and passes every suite

**Accomplished**
- The GDD §13 MVP loop is playable end to end in the Blender-built wing:
  1. Interview Elias with the `CAM_IR_*` cameras, using typed or structured questions.
  2. Questions record the findings with provenance.
  3. Open the EHR (terminal or J) and save a structured note.
  4. Commit a clinical action through ClinicalRules; the chart updates deterministically.
  5. Save and load.

**Files modified**
- `scripts/ui/EHRScreen.gd`, `scripts/ui/InterviewScreen.gd`, `scripts/ui/UIStyle.gd`, and both `.tscn` files: new.
- `scripts/main/Main.gd`: panel routing (info / interview / ehr); Esc closes the topmost panel; J toggles the EHR.
- `scripts/autoload/PatientManager.gd`: `save_note`/`get_notes`, `perform_action`, `action_event_id`; review flags in the audit trail.
- `scripts/autoload/DialogueManager.gd`: `records_observations`, `last_recorded_observations`, `QUESTION_MINUTES`.
- `scripts/autoload/TimeManager.gd`: `format_minutes`.
- `scripts/autoload/EventBus.gd`: `patient_note_saved`.
- `scripts/content/*` and `scripts/autoload/ContentRegistry.gd`:
  - schema for `actions` and `records_observations`;
  - reference checks;
  - `get_actions`/`get_action`.
- `data/clinical_rules.json`: two actions and one new PENDING placeholder rule.
- `data/dialogue.json`: `records_observations` on two choices.
- `scripts/world/{Character,WorldActions,ImportedInteractable,Terminal}.gd`: patients open the interview; terminals open the EHR.

**Unfinished**
- No MAR/medication tab; PharmacologyEngine is still not used in play.
- The close-up and reverse interview shots are unused (capsule stand-ins).

**Known errors**
- none. Expected warnings come from negative tests.

**Tests** (on this branch)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0.
  - TestQA: 19/0/0.
  - GLB validation: 58 assets.
  - TestRunner: 62 passed.
  - TestAudio: 92 passed.
  - Ch1 audio sequence: done.
- CI: not observed.

**Next steps**
1. Sprint 3 on a new branch from this one:
   - evidence board UI (link and pin clues, hypotheses);
   - shift sign-in/sign-out loop;
   - Bennett trust effects;
   - the after-hours W0-B intercom beat and the disputed EHR transfer entry (GDD §12 beat 6).
2. Owner: review the new authored clinical wording listed in PR #9.

### 2026-10-17 · Claude Code · Chapter 1 playable

- **Branch:** `claude/chapter1-playable` (sprint 1 + PR #6, now with `claude/integrate-sprint-01` merged in)
- **Latest verified commit:** the merge commit this entry is part of (a file cannot hold its own SHA); `git ls-remote origin claude/chapter1-playable`
- **Pull request:** #7 (draft)
- **State:** finished; imports and passes every suite

**Accomplished**
- Merged the integration branch (PR #8) so PR #7 sits on top of `main`'s QA, audio and pharmacology. Conflicts were only `.gitignore` and the autoload list in `project.godot`; both sides kept (`WorldStateManager` precedes `GameState`).
- `tests/qa/run.py` now also runs `tools/godot/validate_glb_imports.gd`.

**Tests**
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0. TestPharmacology 0 failures, TestQA 19/0/0, GLB validation 58 assets 0 failures, TestRunner 46 passed / 0 failed, boot OK, TestAudio 92 passed, Ch1 audio sequence done.
- CI: not observed.

**Next steps**
1. Owner merges PR #8, then PR #6, then PR #7 (in that order; PR #7 contains both).
2. Sprint 2 on `claude/sprint-02-ehr-interview` from this branch.

### 2026-10-17 · Claude Code · Sprint 1 integration

- **Branch:** `claude/integrate-sprint-01` (based on `main` at `91ad354`)
- **Latest verified commit:** `8ca85bce79f08f19ce75e00c33502a4e4af14146` "Merge sprint-01 foundation into main's QA, audio and pharmacology". This entry's doc commit sits on top.
- **Confirmed on GitHub:** check with `git ls-remote origin claude/integrate-sprint-01`
- **Pull request:** draft PR to `main` (opened with this push)
- **State:** finished; imports and passes every suite

**Accomplished**
- Executed the integration plan from `docs/PROJECT_STATUS.md`: PR #1 merged into `main` on its own branch, every `main` suite kept green, and the Sprint 1 suite added to the runner.

**Files modified**
- `project.godot`: Sprint 1 autoloads, then `GameState`, `PharmacologyEngine`, `AudioDirector` (in that order; GameState needs TimeManager and SaveManager).
- `scripts/autoload/EventBus.gd`: added `shift_started`/`shift_ended`, pharmacology, legacy progress and narrative/audio signals. `autoload/EventBus.gd` removed.
- `scripts/autoload/GameState.gd` (moved from `autoload/`): `day`/`shift` are getters on TimeManager; `start_shift`/`advance_shift` call `TimeManager.jump_to_shift`/`advance_to_next_shift`; saved as SaveManager provider `game_state`; `to_dict`/`from_dict`/`save_game`/`load_game` kept.
- `scripts/autoload/TimeManager.gd`: `get_shift_day`, `shift_day_for`, `advance_to_next_shift`, `jump_to_shift`; emits `shift_ended`/`shift_started` on shift boundaries.
- `scripts/autoload/Settings.gd`: volume keys removed (AudioDirector owns them).
- `scripts/main/Main.gd`: prints `[The Forensic Ward] Boot OK (content valid|INVALID)`.
- `systems/pharmacology/**`, `data/drugs`, `data/patients`, `tests/TestPharmacology.*`, `docs/PHARMACOLOGY_ENGINE.md`: kept from `main`; `staging/` removed.
- `tests/qa/TestQA.gd`: demo-HUD checks and both SKIPs replaced by checks against the real Main (content valid, player control, forward movement, interactables, door interaction reaches EventBus, shift progression through TimeManager).
- `tests/qa/run.py`: requires `skipped=0`; runs `res://scripts/tests/TestRunner.tscn` and requires `PASSED: N passed, 0 failed`.
- `docs/TESTING.md`, `docs/PROJECT_STATUS.md`, this file.

**Unfinished**
- No gameplay path calls PharmacologyEngine yet (Sprint 2 `ClinicalRules` integration).
- `claude/chapter1-playable` (PR #7) still needs this branch merged in.

**Known errors**
- none. One expected `WARNING: SaveManager: slot 99: checksum mismatch` comes from the tamper test.

**Tests** (on `8ca85bc`)
- `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64`: exit 0. JSON and audio-manifest checks OK, TestPharmacology 0 failures, TestQA 19 passed / 0 failed / 0 skipped, TestRunner 43 passed / 0 failed, boot OK, TestAudio 92 passed, Ch1 audio sequence done.
- CI: not observed yet; check the draft PR.

**Dependencies not available to remote agents**
- Mac-only checks (rendering, input feel, audio mix).

**Next steps**
1. Owner reviews and merges the integration draft PR; then close PR #1.
2. Merge this branch into `claude/chapter1-playable` and update PR #7.
3. Sprint 2 on a new branch: EHR UI, cinematic interview UI, observation capture.

**Notes for the other agent**
- Audio workstream: `AudioDirector` is unchanged; `GameState.shift` and `EventBus.shift_started` behave as before, but the clock is TimeManager's now.
- Do not reintroduce `autoload/EventBus.gd`; the one EventBus is `scripts/autoload/EventBus.gd`.

### 2026-10-17 15:40 UTC · Claude Code · Handoff system

- **Branch:** `claude/ai-handoff-system` (based on `main` at `8e64eaf`)
- **Latest verified commit:** `8e64eafb7ef7e8a68153852f97807eaee576dae4` "Merge pull request #3 from biancaalexis132-png/claude/quirky-ptolemy-6j16b7". This branch adds one documentation commit on top.
- **Confirmed on GitHub:** `git ls-remote origin` at 15:20 UTC showed `main` at `8e64eaf`, `claude/sprint-01-foundation` at `f626aad`, `codex/sprint-01-tests` at `d1d7479`, `claude/quirky-ptolemy-6j16b7` at `c58efc9`. `claude/audio-production` and `claude/environment-production` did not exist yet.
- **Pull request:** draft PR from `claude/ai-handoff-system` to `main`
- **State:** finished; documentation only, no game code changed

**Accomplished**
- Added the shared rules file, the Claude pointer, the status board and this handoff log.

**Files modified**
- `AGENTS.md`: new. Shared rules for Claude and Codex: read order, Godot 4.7 conventions, branch policy, test commands, asset standards, clinical governance, handoff protocol.
- `CLAUDE.md`: new. Points Claude Code to `AGENTS.md`; adds only Claude-specific notes.
- `docs/PROJECT_STATUS.md`: new. Every branch and system with status and evidence, blockers, PR #1 integration risks.
- `docs/AI_HANDOFF.md`: new. This file.

**Unfinished**
- none

**Known errors**
- none in this change. Separately, PR #1 conflicts with `main` (`project.godot`, `autoload/EventBus.gd`); see `docs/PROJECT_STATUS.md` → Integration risks.

**Tests**
- On `main` at `8e64eaf`: `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (4.7.stable.official.5b4e0cb0f, SHA-512 verified) passed: both JSON checks OK, TestPharmacology 0 failures, QA 16 passed / 0 failed / 2 skipped, TestAudio 92 passed, Ch1 sequence done, boot OK.
- On `claude/sprint-01-foundation` at `f626aad`: `godot --headless --path . res://scripts/tests/TestRunner.tscn` gave 43 passed, 0 failed, exit 0.
- CI: run 39043906579 on `main` at `8e64eaf` succeeded. This PR adds only Markdown; its CI run should be checked on the PR.

**Dependencies not available to remote agents**
- none for this change. For other workstreams: Kokoro model files in `tools/audio/models/` (ignored, download per `tools/audio/requirements.txt` and the audio session's notes); ACE-Step and Stable Audio need the owner's Mac; Mac rendering and input checks need the owner.

**Next steps**
1. Owner reviews and merges this PR so `AGENTS.md` is on `main` and every new branch inherits it.
2. Audio and environment sessions: at your first push, replace your row's "none pushed yet" with the full SHA, list your claimed paths, and add a log entry using the template.
3. Owner decides the PR #1 integration plan in `docs/PROJECT_STATUS.md`. Then one agent runs it on `claude/integrate-sprint-01` from `main`, and records it here.
4. After PR #1 lands, move `docs/clinical_review_log.md` and `docs/design/` references in `AGENTS.md` from "on the foundation branch" to plain paths.

**Notes for the other agent**
- No `CLAUDE.md` or `AGENTS.md` existed on any branch before this; established decisions were taken from `README.md`, `docs/TESTING.md`, `docs/SPRINT_01.md`, `docs/design/*`, `docs/clinical_review_log.md` and `staging/README.md`, which are unchanged.
- The owner merges to `main`. Do not merge, push to `main` or enable auto-merge.
