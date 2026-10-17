# F0: Foundation audit and five-chapter architecture

**Status:** proposal for owner review. Nothing in this document is implemented by the PR that adds it, and no code, data, scene or asset changes with it.
**Audited:** `main` at `d21cff70475cb763e775ec48a07c8b924bab9194` ("Merge pull request #18 from biancaalexis132-png/claude/audio-production"), after `git fetch origin --prune`, on 2026-10-17 around 20:20 UTC.
**Inputs:** `ForensicWard_Claude_Final_Handoff_v1_1.zip` (files `00` to `09` and the v1.1 design bible), the owner's three decisions of 2026-10-17, `AGENTS.md`, `docs/*.md`, `docs/design/*`, every script under `scripts/`, `systems/`, `tools/godot/`, every file under `data/`, `audio/cues.json`, the asset manifest, the open pull requests and the CI history.

Owner decisions this audit builds on (2026-10-17):

1. The hospital is **Ashcroft State Forensic Hospital**.
2. Ward Zero contains a **genuine supernatural phenomenon**. Early chapters keep uncertainty and clinical realism; psychiatric symptoms are never evidence of it.
3. **Reusable technical foundations for all five chapters come first**, before intensive Chapter 1 polish.

Gate: the owner reviews this architecture before any major structural change. F1 to F3 below start only after that review.

---

## 1. Repository state at audit time

### Pull requests

| PR | Branch | State | Notes |
|---|---|---|---|
| #19 | `claude/environment-stage-5` | Open, draft at audit time; **merged 20:20 UTC** (`292f1cf`), merged into this branch | Stage 5 historic substructure (13 props, 13 sublevel spaces). Built by another session right now. This audit does not touch that branch. CI run 39066043198 was in progress at audit time. |
| #18 | `claude/audio-production` | **Merged** 19:44 UTC | Soundtrack integration. It was described as open in the brief; GitHub shows it merged into `main` at `d21cff7`. |
| #17 | `claude/environment-stage-4b` | Merged | Research wing |
| #16 | `claude/remove-macos-metadata` | Closed, not merged | Duplicate of #15 |
| #15 | `claude/remove-appledouble-metadata` | Merged | AppleDouble repair |
| #14, #13, #12, #11, #10, #9, #5, #4, #3, #2 | various | Merged | #11 carried Sprints 1–3 and the Blender Stages 1–2 to `main` |
| #8, #7, #6, #1 | various | Closed (superseded by #11) | |

### CI

`validate` (`.github/workflows/godot-validation.yml`) is green on `main` at `d21cff7` (run 39063775032) and at `cccbe09` and `66a274f`. The last red runs were on `782f642` ("will music i think"), caused by 583 tracked AppleDouble files.

### AppleDouble metadata

| Check | Result |
|---|---|
| Tracked `._*` files on `main` | **0** (`git ls-files` filtered for `._`) |
| Tracked `.DS_Store` | 0 |
| `.gitignore` | Ignores `._*`, `.DS_Store`, `.AppleDouble`, `.Spotlight-V100`, `.Trashes`, `.fseventsd`, `__MACOSX/` and similar |
| Python content QA (`tests/qa/test_json.py`, `test_audio_manifest.py`) | Skips `._*` and `__MACOSX`, and fails if any macOS metadata becomes tracked |
| `AudioDirector._load_narrative` | Skips `._*` since `ab613f1` |
| `tools/godot/validate_glb_imports.gd` `_find_glbs` | **Does not skip `._*`.** On the exFAT SSD an untracked `._ENV_Foo.glb` ends in `.glb` and would be loaded and reported as a failure. Not visible in CI (the files are never committed), only on the owner's Mac. Fix proposed in F1. |
| `ContentRegistry` | Unaffected: it opens a fixed list of file names and never lists folders |

The repository side is repaired. The remaining exposure is local: the working copy lives on an exFAT volume, so macOS keeps writing `._*` files. `dot_clean -m .` or an APFS working copy (the handoff's recommendation) is the owner's call; no agent should touch the SSD.

### Test baseline on `d21cff7`

Full `tests/qa/run.py` with Godot 4.7 stable (Linux, SHA-512 verified) exits 0 on `d21cff7`. Counts are in section 11.

---

## 2. Implemented-versus-planned inventory

Columns follow the master prompt: **On main** (merged and tested), **On main, incomplete**, **Open PR**, **Draft new** (designed in the v1.1 package, nothing in code), **Needs clinical approval** (cannot become medical logic until the owner approves it in `docs/clinical_review_log.md`).

| Feature | Status | Evidence on `main` | Gap against the five-chapter plan |
|---|---|---|---|
| Godot 4.7 project, Forward+, 14 autoloads | On main | `project.godot` | none |
| EventBus domain events | On main | `scripts/autoload/EventBus.gd` (≈50 signals) | No zone or anomaly signals yet |
| Content loading and validation | On main, incomplete | `ContentRegistry.gd`, `ContentSchemas.gd`, `ContentValidator.gd` | Fixed `MANIFEST` of nine files, two of them hard-wired to Chapter 1 (`world_chapter1.json`, `story_chapter1.json`). One dialogue file for one patient (`_dialogues = {dialogue["patient_id"]: ...}`). No chapter index, no ID-prefix check, no cross-chapter uniqueness check |
| Save system | On main, incomplete | `SaveManager.gd`: providers, SHA-256 checksum, atomic write, seeded RNG streams, `SAVE_VERSION = 1` | No migrations exist. `load_game` runs migrations **before** comparing the checksum, so the first migration that changes state will fail every old save unless it also recomputes the checksum. No chapter or zone state |
| Time, shifts, scheduled events | On main | `TimeManager.gd` | none for F1–F3 |
| Patient run state with provenance and idempotent event ids | On main | `PatientManager.gd` | Observations are ids plus `source`/`timestamp`/`text`. No `polarity` (`present` / `absent` / `unable_to_assess` / `not_assessed`), so "unknown is not negative" is not representable yet |
| Elias Ward (`pt_elias_ward`) | On main; **needs clinical approval** | `data/patients.json`, `data/dialogue.json` (2 states), `clinical_review_status: PENDING_PSYCHIATRIST_REVIEW` | Proposed vitals, labs, nursing timeline and BFCSI items in `03_CLINICAL…` are draft |
| Mara Ellis (`pt_mara_ellis`) | Draft new; **needs clinical approval** | none | GDD beat 4 "second patient" is unimplemented (`story_chapter1.json` notes) |
| Chapter 2–5 patients (Reyes, Park, Bell, Vale, Monroe, Chen) | Draft new; **needs clinical approval** | none | |
| Interview: authored states, intent matcher, cinematic UI | On main | `DialogueManager.gd`, `IntentMatcher.gd`, `InterviewScreen.gd` | Single-patient dialogue loading (see content row) |
| EHR: census, summary, observations, notes, orders, audit | On main, incomplete | `EHRScreen.gd` | No MAR/medication tab; no amendment trail UI |
| Clinical rule governance (validated / prototype modes) | On main | `ClinicalRules.gd`; validated mode refuses pending rules (tested) | none |
| `clinical_rule_catatonia_escalation_v1`, `clinical_rule_medical_review_request_v1` | On main; **needs clinical approval** | `data/clinical_rules.json`, `medical_effects: []` | |
| Pharmacology engine (CYP, renal, QTc, 20 drugs) | On main (approved in the review log) | `systems/pharmacology/*`, `tests/TestPharmacology.gd` | Not wired to the EHR. Its `clue_gates` unlock narrative clues from symptom levels; see conflict C7 |
| Evidence: clues, provenance, links, hypotheses, verifications | On main, incomplete | `EvidenceManager.gd`, `EvidenceBoard.gd`, `data/clues.json` (3 clues, 1 hypothesis) | Hypothesis statuses are `unresolved/supported/refuted`. The package's claim states (`reported`, `verified`, `corroborated`, `disputed`, `unresolved`) and a source class per clue do not exist |
| Staff trust (respect / trust / suspicion) and access grants | On main | `TrustManager.gd`, `data/staff.json` | Access grants are separate from affinity, as the package requires. Staff roles and titles differ from the package (conflict C4) |
| Chapter 1 story director (objectives, beats, staff lines, sign-out) | On main, incomplete | `ChapterDirector.gd`, `StoryLogic.gd`, `story_chapter1.json` | One chapter only; state is saved under the single `chapter` provider. Staff lines are placeholders. Beat 4 missing |
| Environment state groups (shutters, W0-B seal, future anomaly variants) | On main | `WorldStateManager.gd` | Reusable as is for Ward Zero states |
| Playable world | On main, incomplete | `AuthoredWorld.gd`, `Chapter1Ward.tscn`, `world_chapter1.json` | Loads all seven clinical-wing `.glb` files at once into one scene. No zones, transitions or unloading |
| Blender environments, Stages 1–4b | On main | 112 `.glb` in `assets/exports/**`, manifest `assets/asset_manifest/asset_manifest.json`, all import in Godot 4.7 | Untextured. Security/admin (4a) and research (4b) wings are **not wired into gameplay** |
| Stage 5 historic substructure | Open PR #19 | 26 more `.glb` (138 total on that branch) | No level scene, no hatch, stair or lift transition |
| Stage 6 Ward Zero, Stage 7 exterior/apartment, Stage 8 textures/LOD | Draft new | none | |
| Adaptive audio engine, buses, ducking, reduce-startling-audio | On main | `systems/audio/AudioDirector.gd`, `audio/cues.json`, `TestAudio` | Already refuses to react to objectivity/bleed (comment at `AudioDirector.gd:19`) |
| Owner soundtrack (5 tracks) and music contexts | On main (PR #18) | `assets/audio/music/*.ogg`, `mus_*` cues | No title screen, cinematic, emotional beat or credits fires the contexts yet. Listening review and licence record pending |
| Kokoro voice pipeline, Chapter 1 lines | On main | `tools/audio/`, `audio/voice/ch1/`, `data/narrative/chapter1.json` | Mara voice not chosen; protagonist voice options not built |
| Anomaly audio (`w0_*` events, `historical_wing` and `ward_zero` locations) | On main | `audio/cues.json` | Nothing fires them; good starting point for F3 |
| Settings and accessibility toggles | On main | `Settings.gd` | Needs persistence of protagonist identity (not a setting) |
| Psychosomatic Bleed / objectivity meter | On main, unused | `GameState.objectivity`, `bleed_stage`; only tests change it | See conflict C6 |
| Protagonist creator (name, pronouns, appearance, voice, background) | Draft new | none | Player is addressed as "the new attending" in three files |
| Title screen, chapter select, credits | Draft new | none | |
| Hospital name in game | Draft new (approved) | The name appears nowhere in code, data or audio | |
| Zone streaming and transitions | Draft new | none | |
| Clinical/supernatural event separation | Partly on main | Rule "clinical rules never unlock story" in `AGENTS.md` §2, `ClinicalRules.gd`, `StoryLogic.gd`; audio ignores bleed | No anomaly model, no validator rule, and one existing exception (C7) |
| Headless QA and CI | On main | `tests/qa/run.py`, `godot-validation.yml` | none |

---

## 3. Contradictions, ID collisions and discrepancies

None of these are fixed by F0. Each names who decides.

| # | Discrepancy | Where | Proposal | Decides |
|---|---|---|---|---|
| C1 | **Ward Zero's nature.** GDD v0.1 (locked): "selected anomalies remain ambiguous". Owner decision of 2026-10-17: a genuine supernatural phenomenon. | `docs/design/The_Forensic_Ward_Master_GDD_v0.1.docx` §1–2 | The owner decision supersedes. Record a GDD amendment note in `docs/design/` (F1) rather than editing the locked `.docx`. | Owner (already decided; record only) |
| C2 | **Act structure.** GDD: Orientation, The Missing, Concordance, Ward Zero, Final Assessment, with the Concordance Protocol research thread. v1.1: The Admission, The Missing Hours, Beneath the Hospital, The Official Record, Beyond the Lines; Concordance is not mentioned. | GDD §4 vs `02_CHAPTERS_1_TO_5.md` | Use the v1.1 chapter ids `ch1`…`ch5` in code with titles in data, so renaming costs nothing. Ask whether the Concordance research thread survives; the research wing (Stage 4b) was built for it. | Owner |
| C3 | **Player title.** GDD: "newly graduated attending". v1.1: "credentialed treating staff psychiatrist". Data says "the new attending". | `data/staff.json:18`, `data/narrative/chapter1.json:18`, `audio/voice_profiles.json:17`, `audio/manifest.json` | Keep the line ids. If the wording changes, author new line ids and regenerate audio, as the voice rules require. "Attending" and "staff psychiatrist" can both be true; the owner chooses the on-screen title. | Owner |
| C4 | **Staff roles.** GDD: Hale security director, Mercer senior psychiatrist, Rahman clinical pharmacist, Price maintenance supervisor. v1.1: Hale security chief, Mercer independent forensic evaluator, Rahman psychiatric consultant, Price facilities supervisor. Five new staff in v1.1. | `data/staff.json`, GDD §5, `01_MASTER…` | Roles are data; no code depends on them. Reserve `staff_mercer`, `staff_rahman`, `staff_price`, `staff_torres`, `staff_brooks`, `staff_kim`, `staff_cross`, `staff_okafor` in F1's ID registry without content. | Owner (narrative) |
| C5 | **Beat 4.** GDD: "second stable patient hints at a missing clinician". v1.1: Mara Ellis, records dispute over aunt Lillian. | GDD §12, `story_chapter1.json` notes | Mara is the default per the package; it stays draft until clinical and narrative review. Out of scope for F1–F3. | Owner |
| C6 | **Psychosomatic Bleed.** GDD §11 specifies a horror/strain layer; `GameState` stores `objectivity` and `bleed_stage`. Under decision 2, a strain meter that drives distortion near Ward Zero would invite the reading "the doctor is unwell, so the anomaly is in their head", which is the reduction decision 2 rules out. | `GameState.gd`, `Settings.visual_effects` | Keep the meter as **presentation only**: it may tint the screen or audio within accessibility toggles, but it can never trigger, reveal, hide or count toward anomaly evidence, and anomaly events never change it. F3 enforces this in a test. Ask whether Bleed stays in the design at all. | Owner |
| C7 | **Pharmacology clue gates.** `PT-001.json` and `PT-002.json` unlock narrative clues (`pt001_trial_memory`, `pt002_ward_b_testimony`) when simulated symptom levels fall. That is treatment response unlocking story, which `AGENTS.md` §2 and Foundation D forbid, and the second clue makes a depressed patient's recovery the key to Ward Zero testimony. Today only `tests/TestPharmacology.gd` uses them; no gameplay path admits these patients. | `systems/pharmacology/PharmacologyEngine.gd:657`, `data/patients/PT-00*.json` | Do not change the approved engine in F1–F3. F3 adds a validator that reports any clinical data that names a clue or anomaly, which will flag these two as known exceptions. The owner then chooses: remove the gates, or move the decision into the story layer (story subscribes to a clinical event and decides on its own conditions). | Owner (clinical + narrative) |
| C8 | **Two patient id schemes.** `pt_elias_ward` (content, lower-case ids enforced by `ContentSchemas`) and `PT-001` / `PT-002` (pharmacology placeholders, upper case, separate loader). | `data/patients.json`, `data/patients/` | Not a collision today. When Mara or later patients get pharmacology, bridge by a `pharmacology_profile` field on the `pt_*` record instead of a second patient id. | Engineering (F1 records it) |
| C9 | **"Ward B" vs W0-B.** `pt002_ward_b_testimony` | `PT-002.json` | Resolve with C7. | Owner |
| C10 | **Two clue stores and two flag stores.** `GameState.unlocked_clues` / `clue_unlocked` (used only by pharmacology) and `EvidenceManager` / `clue_acquired` (used by gameplay). `GameState.flags` and `ChapterDirector._flags`. | autoloads | Canonical: `EvidenceManager` for clues, `ChapterDirector` (per chapter) for story flags. Leave `GameState` as the compatibility layer it already declares itself to be; no new caller uses it. Documented in F1, not removed. | Engineering |
| C11 | **Audio folders.** `audio/` holds engine-generated ambience, SFX, voice and one transition cue. `assets/audio/music/` holds the owner's five tracks, referenced from `audio/cues.json` by path. Not a duplication: two sources, one cue map. `music_main_theme.m4a` (3.6 MB) is an unused original that Godot cannot import. | `docs/AUDIO.md`, `audio/cues.json` | Keep both folders; write the convention into `docs/AUDIO.md` (owned by the audio workstream). Exclude `*.m4a` from export presets when exports exist, or move originals outside the project with the owner's consent. Never re-encode the `.ogg` files. | Owner (whether the `.m4a` stays) |
| C12 | **Level frames.** Clinical wing and security/admin wing share one ground frame (`Door_WardEntry` at (0, 20) is the boundary). The research level and the Stage 5 sublevel reuse the same x/y with their floor at z = 0, so they overlap the ground floor if loaded in the same scene. | `docs/ENVIRONMENT_STAGES.md`, `build_stage4_*.py`, PR #19 | Zones carry a `level` and are never co-resident across levels. See section 6. | Engineering |
| C13 | **Hospital name absent.** | everywhere | F1 adds `institution.name = "Ashcroft State Forensic Hospital"` to the campaign file; UI reads it from there. Signage textures in Blender come later (Stage 8) through the environment workstream. | Done by decision; F1 implements |
| C14 | **`docs/PROJECT_STATUS.md` is stale.** It still lists Sprints 1–3, PR #1, #6, #7, #8 as open and `claude/audio-production` as missing, although #11 and #18 merged. | `docs/PROJECT_STATUS.md` | Not edited by F0, because PR #19 edits neighbouring rows and would conflict. F1 rewrites the branch table and the Sprint rows from GitHub after #19 has merged. | Engineering (F1) |

**ID collisions:** none. A scan of every `id` in `data/**/*.json` and `audio/cues.json` found 74 distinct ids and no duplicates. Package ids that would duplicate existing meaning are flagged instead of added: the package's `obs_elias_*` set overlaps the existing `obs_mutism` and `obs_posturing`, which must be kept; `ch1_b6_intercom_001`, `obj_meet_bennett`, `obj_see_elias`, `obj_document`, `obj_act`, `obj_compare_records`, `obj_sign_out`, `obj_w0b`, `obj_end`, `beat_b2_handover`, `beat_b6_intercom`, `beat_b6_unease`, `clue_transfer`, `clue_roster`, `clue_access`, `hyp_identity_reuse` all exist and stay.

---

## 4. Proposed five-chapter shared architecture

The existing architecture already matches the handoff's intent: autoload managers that talk only through `EventBus`, authored JSON validated at boot, run state in save providers, closed condition/action vocabularies, and a governance layer around clinical rules. The proposal **extends** it along three axes (chapters, zones, anomaly evidence) and adds one guard (separation), without new parallel managers except where a responsibility has no owner today.

```
                       data/campaign.json  (institution, chapters ch1..ch5, zone file, flags)
                                 │
                     ContentRegistry  ── loads global files + each chapter's files
                     ContentValidator ── schemas, cross-refs, id prefixes, separation rules
                                 │  (read-only content)
   ┌───────────────┬─────────────┼──────────────┬──────────────────┬───────────────┐
 Clinical layer   Interview     Story layer      World layer        Anomaly layer (new, F3)
 PatientManager   Dialogue-     ChapterDirector  ZoneDirector (F2)  AnomalyLedger
 ClinicalRules    Manager       (per chapter)    AuthoredWorld      episodes, readings,
 Pharmacology     IntentMatcher StoryLogic       WorldStateManager  evidence threshold
   │                │             │                │                  │
   └────────────────┴──────── EventBus (facts, past tense) ──────────┴──────────┘
                                 │
       EvidenceManager (clues, provenance, source class, claim state)  TrustManager
                                 │
             SaveManager (versioned, migrated, one provider per manager)
                                 │
               AudioDirector (cues by event, location = zone audio key)
```

Rules that hold across all five chapters:

1. **One content contract.** Every chapter is a folder of the same file types, registered in `data/campaign.json`. Chapter 1 keeps its current file names; the campaign file points at them. Chapters 2–5 exist in tests as small fixtures only, so no late-game text ships in player-facing data before it is approved.
2. **Stable, namespaced ids.** Prefixes `pt_`, `staff_`, `obs_`, `clue_`, `hyp_`, `obj_`, `beat_`, `zone_`, `conn_`, `anom_`, `chN_` are validated. Ids are unique across all chapters. A chapter is a field (`"chapter": "ch2"`), not an id rewrite, so every existing id survives.
3. **Chapter-scoped story state.** `ChapterDirector` keeps flags, fired beats and pending beats per chapter id, so finishing Chapter 1 and starting Chapter 2 never re-fires a Chapter 1 beat, and Chapter 5 can read what happened in Chapter 1 (missed clue recovery routes).
4. **Save version 2.** Adds `campaign` (current chapter, completed chapters), per-chapter story state, and `zones` (current zone, per-zone persistent object state). A tested v1→v2 migration moves today's `chapter` state under `ch1`.
5. **Zones, not one world.** A zone is a set of environment `.glb` files on one level with arrival markers. Only the current zone and its same-level neighbours are resident (section 6).
6. **Three separate event families** on `EventBus`: clinical (exists), story (exists), anomaly (new). Validator rules forbid cross-wiring (section 7).
7. **Patients persist across chapters.** Patient definitions are global, not per chapter; a chapter lists which patients are on the census. Elias and Mara can return in Chapter 5 with their saved state.
8. **Governance stays where it is.** `ClinicalRules` remains the only path to medical effects; nothing in F1–F3 adds a medical effect, an approved rule, or clinical content.

---

## 5. Existing systems to reuse rather than rebuild

| Need from the package | Reuse | Change needed (smallest) |
|---|---|---|
| Content registry with validation | `ContentRegistry`, `ContentSchemas`, `ContentValidator` | Read the campaign file; accept several dialogue files and per-chapter story/world files; add id-prefix, uniqueness and separation checks |
| Persistable event and decision architecture | `EventBus`, `SaveManager` providers, `PatientManager` event-id ledger, `ChapterDirector` fired/pending lists, `TimeManager.schedule` | Chapter keying in `ChapterDirector`; migrations in `SaveManager` with the checksum fix |
| Story triggers | `StoryLogic` closed vocabulary | Add conditions `chapter`, `zone_visited`, `in_zone`; add action `start_chapter`. No free-form scripting |
| World states for Ward Zero and anomalies | `WorldStateManager` + glTF `state_group` extras (already used by the W0-B seal and the Stage 5 brick infill) | none |
| Level building from Blender exports | `AuthoredWorld` (doors, interactables, characters, lights, state nodes) | Build from a zone definition instead of the whole world file; one instance per resident zone |
| Doors and access | `ImportedDoor`, `TrustManager.has_access`, `required_access` extras on Stage 4 doors | Doors that are zone connections ask `ZoneDirector` to transition |
| Evidence and provenance | `EvidenceManager` (acquisition method, verifications), `EvidenceBoard` | Add `source_class` and claim state; anomaly readings become clues of class `instrument` or `physical` |
| Audio per place and event | `AudioDirector.set_location`, `narrative_event_fired`, `w0_*` events, `historical_wing` and `ward_zero` locations | Zones name their audio location; `AudioZoneTracker` stays for rooms inside a zone |
| Accessibility | `Settings` (reduce motion, flash, distortion, subtitles, text scale), audio reduce-startling | Anomaly presentation honours the same toggles |
| QA | `tests/qa/run.py`, `TestRunner` (`scripts/tests/test_*.gd`), CI | New `test_campaign.gd`, `test_zones.gd`, `test_anomaly.gd` picked up automatically |

Nothing in this list is rewritten. The largest single change is `AuthoredWorld` taking a zone instead of a world, and its current behaviour stays reachable as "Chapter 1 clinical wing zone".

---

## 6. World zones and memory-efficient loading

### Zone map (from the built environments)

| Zone id (proposed) | Level | Built | Environments | Audio location |
|---|---|---|---|---|
| `zone_clinical_wing` | ground | Stage 2–3, on main | 7 clinical `ENV_*` | `corridor`, `nursing_station` (room zones inside) |
| `zone_security_admin` | ground | Stage 4a, on main | 11 security `ENV_*` | new `security_wing` (exists as a gap) |
| `zone_research_level` | research | Stage 4b, on main | 12 research `ENV_*` | new `research_wing` |
| `zone_historic_sublevel` | sublevel | Stage 5, PR #19 | 13 historic `ENV_*` | `historical_wing` (exists) |
| `zone_ward_zero` | sublevel | Stage 6, not started | — | `ward_zero` (exists) |
| `zone_exterior`, `zone_apartment` | exterior | Stage 7, not started | — | — |
| `zone_medical_bay`, `zone_dayroom`, therapy, visitor | ground | not started | placeholders | — |

### Connections

| Connection | Kind | Transition | Access |
|---|---|---|---|
| clinical wing ↔ security/admin via `door_ward_entry` (0, 20) | door, same level and frame | **Seamless**: both zones may be resident; the neighbour is preloaded when the player nears the door | role access id (to be named), never trust |
| security/admin ↔ research via `door_restricted_lift` (0, 44) | lift, different level | **Fade** (short lift cinematic, skippable) | `access_restricted_lift` (already on the Stage 4a door extras) |
| security/admin ↔ historic sublevel via `MA_ServiceHatch` and stair | hatch and stair, different level | **Fade** plus a climb interaction (the stair is ~60°, noted in PR #19) | supervised/authorised entry per chapter (Chapter 3 with Price) |
| historic sublevel ↔ Ward Zero via sealed corridor | world state `sealed_corridor_end` | Fade | story state only |
| clinical wing → W0-B door (0, 0) | door | stays sealed in Chapter 1 | — |

### Loading model

- **Resident set:** the current zone plus same-level neighbours flagged `preload_neighbour`. Never two levels at once, which also removes the overlapping-frame problem (C12).
- **Streaming:** `ResourceLoader.load_threaded_request` for the target zone's `.glb` scenes when the player enters a connection trigger volume; the transition waits on `load_threaded_get_status`, so a slow disk shows the fade a little longer instead of hitching.
- **Swap:** fade out → pause `TimeManager` (reason `zone_transition`) → instance the new zone through `AuthoredWorld` → place the player at the connection's arrival marker → free the old zone (`queue_free`) and drop its scene references → fade in → pop the pause.
- **State across unloads:** today `Main` saves doors from the live `persistent_world` group, so a door in an unloaded zone would lose its state. `ZoneDirector` keeps `zone_id -> {persist_id -> state}` for every zone ever visited and feeds it back when a zone is instanced. Saved as the `zones` provider.
- **Budgets for the 8 GB Apple Silicon Mac:** measured, not promised. Hooks record `Performance.MEMORY_STATIC`, `RENDER_VIDEO_MEM_USED`, `RENDER_TOTAL_OBJECTS_IN_FRAME` and frame time before and after each transition, written to `user://perf_log.csv` when a debug setting is on. Targets to check on the Mac: stable 30 FPS, aspiration 60 in light scenes, no growth in static memory after repeated round trips. Headless CI can check the growth, not the frame rate.
- **Quality presets** (later than F2): shadows on/off for `LIGHTMARK_*` lights, light count cap per zone, and a Compatibility-renderer fallback, measured on the Mac.

---

## 7. Separating clinical events from supernatural events

### The rule, in one sentence

The anomaly is a property of **places, instruments and time**, observed and corroborated through **non-clinical sources**; patients' symptoms, diagnoses, scores, medication and rapport, and the physician's own strain, can neither cause it, reveal it, nor count as evidence for it, and anomaly events can never change clinical state.

### Data model (F3)

- `data/anomalies.json` (Chapter 1 entries only until later chapters are approved):
  - **episode** `anom_*`: `zone_id`, `chapter`, `when` (StoryLogic conditions restricted to time, shift, day, zone, flag, world state and evidence), `manifestations` (closed vocabulary: `world_state`, `audio_event`, `device_log`), `readings` it produces.
  - **reading**: a clue (`clue_*`) with `source_class` one of `instrument`, `document`, `physical`, `access_log`, `staff_testimony`, `patient_report`. `patient_report` and `staff_testimony` are recorded and shown, but **never count** toward the anomaly threshold.
  - **threshold ladder** per the package (09): `none` → `reported` → `inconsistent_records` (Ch2) → `instrumented` → `corroborated` (Ch3, at least two independent non-testimony source classes) → `accepted`. The ladder is computed from evidence, never set by dialogue.
- Clues gain `source_class` and a claim state (`reported`, `verified`, `corroborated`, `disputed`, `refuted`, `unresolved`). Existing clues get defaults so their behaviour does not change.

### Enforcement

1. **Validator rules** (fail the content load):
   - an anomaly `when` may not reference a patient, observation, clinical action, note, rapport, trust axis, objectivity or bleed;
   - clinical files (`patients.json`, `clinical_rules.json`, `dialogue*.json`) may not name an `anom_*` id or an anomaly reading clue;
   - a story beat may not grant a clinical effect (already true of `StoryLogic`).
   - The pharmacology `clue_gates` (C7) are reported as known exceptions, not silently allowed.
2. **Runtime tests** (`test_anomaly.gd`):
   - fire every clinical action, observation and note event for Elias: the anomaly ledger is unchanged;
   - fire every Chapter 1 anomaly episode: `PatientManager.to_save_data()` is byte-identical before and after;
   - drive objectivity from 100 to 0: no episode fires and the ladder does not move;
   - a patient report about W0-B is recorded with `source_class: patient_report` and the ladder stays at `none`.
3. **Feature flag:** `forensic_ward/narrative/anomaly_enabled`, default `false`, beside the existing `forensic_ward/clinical/build_mode`. With it off, episodes are validated but never scheduled, so Chapter 1 plays exactly as today.
4. **Ambiguity by chapter:** Chapter 1 content may only use manifestations with a plausible mundane reading (intercom, credential log, a mechanical sound), and the validator caps Chapter 1 readings at `reported`. Later caps follow the 09 ladder.

### What stays clinical

Symptoms, MSE findings, diagnoses, risk and capacity remain in `PatientManager` with provenance, under `ClinicalRules` governance, whatever the anomaly does. A patient who reports hearing something in W0-B is assessed clinically like any other report, and the report is neither confirmed nor dismissed by the anomaly system.

---

## 8. The first three implementation PRs

Each is a draft PR from `main` (after PR #19 merges, or merging `main` in if it lands mid-PR), runs `tests/qa/run.py` green, adds a handoff entry, and waits for owner review. None touches `assets/**`, `tools/blender/**`, `audio/**` assets, clinical content or the pharmacology engine.

### F1: Campaign content contract and save version 2

**Scope**
- `data/campaign.json`: institution (`Ashcroft State Forensic Hospital`), chapters `ch1`–`ch5` (ch1 playable, ch2–ch5 `planned`), file lists, reserved staff and patient ids (no content).
- `ContentRegistry` / `ContentSchemas` / `ContentValidator`: load through the campaign file; multiple dialogue files keyed by `patient_id`; id-prefix and global uniqueness checks; per-chapter `story` and `world` files (Chapter 1 keeps its current names).
- `ChapterDirector`: state keyed by chapter; `StoryLogic` gains `chapter` condition and `start_chapter` action.
- `SaveManager`: `SAVE_VERSION = 2`, verify the checksum **before** migrating (or recompute after), `_migrate_from_1` wraps the old `chapter` state under `ch1`; `campaign` provider.
- Test fixtures for ch2–ch5 under `scripts/tests/fixtures/campaign/` (one objective, one beat, one clue each; placeholder text only).
- Hygiene: `validate_glb_imports.gd` skips `._*`; one shared helper for "is macOS metadata".
- Docs: rewrite `docs/PROJECT_STATUS.md` from GitHub (C14); GDD amendment note for C1; ID registry table in `docs/`.

**Depends on:** owner review of F0. PR #19 merged first is preferred (both touch `docs/PROJECT_STATUS.md` and `docs/AI_HANDOFF.md`).
**High-conflict files touched:** `scripts/autoload/EventBus.gd` (one or two signals), `tests/qa/run.py` only if a new suite needs registering (TestRunner discovers `test_*.gd` itself, so probably not).

**Acceptance tests**
1. `tests/qa/run.py` green; existing TestRunner, TestQA, TestAudio, GLB counts unchanged or higher.
2. Content: all five fixture chapters load and validate; a duplicate id across two chapters fails with a message naming both files; an id without a known prefix fails; existing Chapter 1 ids all still resolve.
3. Save: a committed v1 save fixture (captured from today's `main`) loads into v2 with identical Chapter 1 objectives, fired beats and pending beats; the intercom beat does not fire twice after load; a tampered v2 save still fails its checksum.
4. Chapter flow: completing ch1 fixture and starting ch2 fixture keeps ch1 state readable and never re-fires ch1 beats; save/load between the two chapters round-trips.
5. Determinism: same seed and inputs give the same `capture_state()` across the chapter transition.
6. No player-facing text from chapters 2–5 in `res://data`.
7. Planted `._*.glb` and `._*.json` files are ignored by every loader.

### F2: Zone manifest and two-zone transition prototype

**Scope**
- `data/zones.json`: zones and connections from section 6, with `built` / `placeholder` status.
- `ZoneDirector` (a node under `Main`, saved as the `zones` provider): threaded loading, fade transition, arrival markers, per-zone persistent object state, time pause during transitions.
- `AuthoredWorld` builds one zone; `Chapter1Ward.tscn` becomes the clinical-wing zone with identical behaviour.
- Prototype connection: `zone_clinical_wing` ↔ `zone_security_admin` through `door_ward_entry`, gated by a role access id. The door stays locked in Chapter 1 story data, so play is unchanged unless a debug setting or test opens it.
- Performance logging hooks (debug setting, off by default).

**Depends on:** F1 (zone ids, `zone_` prefix, save v2 `zones` state). Environment workstream for any new arrival markers in the `.blend` files; until then, arrival transforms are given in `zones.json` and labelled as placeholders.
**High-conflict files touched:** `scenes/main/Main.tscn`, `scripts/main/Main.gd` (the world provider moves door state into `ZoneDirector`).

**Acceptance tests**
1. `run.py` green, GLB validation unchanged.
2. Chapter 1 regression: every existing `test_world.gd`, `test_sprint2.gd`, `test_sprint3.gd` case passes with the world built as a zone.
3. Transition: walk-through (scripted) clinical → security → clinical ten times: the player lands on the arrival marker each time, the old zone's nodes are freed, and `Performance.MEMORY_STATIC` after the tenth round trip is within a set tolerance of the first.
4. A door opened in the security wing is still open after leaving, unloading, saving, loading and returning.
5. A locked connection does not transition and shows its locked message; raising trust with any staff member does not open it.
6. Saving mid-zone and loading restores the zone, position and time; loading never replays a transition.
7. Manual on the Mac (owner): transition smoothness, frame time before and after, audio location change. Reported as "untested on Mac" until done.

### F3: Anomaly evidence model and event separation (flag off)

**Scope**
- `AnomalyLedger` autoload (or an `EvidenceManager` extension if review prefers fewer autoloads), `data/anomalies.json` with Chapter 1 episodes that mirror what already happens (intercom, inactive credential, `ch1_w0b_unease`), capped at `reported`.
- `source_class` and claim state on clues, defaults for existing clues.
- EventBus signals `anomaly_episode_observed`, `anomaly_threshold_changed`.
- Validator separation rules and the C7 known-exception report.
- Feature flag `forensic_ward/narrative/anomaly_enabled = false`.

**Depends on:** F1 (ids, chapter field), F2 for zone-scoped episodes (episodes can name `zone_clinical_wing` before F2 merges, but zone-conditioned firing is tested after).
**Does not:** write Chapter 2–5 anomaly canon, change any clinical file, change `GameState` objectivity behaviour, or enable the flag.

**Acceptance tests**
1. `run.py` green.
2. The four separation tests in section 7 pass.
3. With the flag off, a full Chapter 1 scripted run produces the same `capture_state()` as before F3, apart from the new empty `anomaly` provider.
4. With the flag on in a test, the Chapter 1 episodes fire once each, survive save/load without re-firing, and the ladder stays at `reported`.
5. Validator: an anomaly condition naming `pt_elias_ward` or `obs_mutism` fails; a clinical rule naming an `anom_*` id fails; the PT-001/PT-002 gates are listed as known exceptions.

### Later (unchanged from the package order, after F1–F3)

Elias provenance and polarity (`unknown` ≠ negative); Mara and two-patient sign-out; archival documents; protagonist creator and identity persistence; title screen and credits so the soundtrack contexts fire; Chapter 1 staging and polish; then Chapters 2–5 module by module.

---

## 9. Approvals the owner still holds

| Item | Needed before |
|---|---|
| This architecture (F0) | F1 starts |
| C2: keep or drop the Concordance research thread; final chapter titles | Chapter 2–3 content |
| C3: on-screen player title | Any new voiced line addressing the player |
| C4: staff roles and the five new staff | Their first line of content |
| C6: does Psychosomatic Bleed stay, as presentation only | F3 merge (F3 tests assume "presentation only") |
| C7: pharmacology clue gates, remove or move to story | Any gameplay path that admits PT-001/PT-002 |
| C11: keep or move `music_main_theme.m4a` | First export build |
| Precise supernatural mechanism (09 "temporal echo" proposal) | Any anomaly content beyond Chapter 1's `reported` level |
| Mara Ellis canon and every clinical value in `03_CLINICAL…` | Mara PR |
| Each clinical rule with a medical effect | That rule's activation |
| Soundtrack authorship and licence record | Sharing any build |

---

## 10. Owner-facing summary of what does not change

- No working system is rewritten in F1–F3. Chapter 1 plays the same after each PR; the tests prove it.
- No clinical treatment effect is enabled. `medical_effects` stay empty; no rule's `review_status` changes.
- No pull request is merged by an agent.
- PR #19 (Stage 5) and the environment workstream's files are not touched.

---

## 11. Checks run for this audit

| Check | Command | Result |
|---|---|---|
| Branches and PRs | `git fetch origin --prune`, `gh api repos/.../pulls?state=all` | As in section 1 |
| CI history | `gh api repos/.../actions/runs` | Green on `d21cff7` (run 39063775032) |
| Tracked macOS metadata | `git ls-files \| grep '/\._\|^\._'` | 0 files |
| Id scan | Python over `data/**/*.json`, `audio/cues.json` | 74 ids, 0 duplicates |
| Full QA on `d21cff7` | `GODOT=<Godot 4.7-stable linux, SHA-512 verified> python3 tests/qa/run.py` Exit 0. Python content 6/6, audio manifest 3/3, music pipeline 3/3; TestPharmacology 0 failures; TestQA 19 passed / 0 failed / 0 skipped; GLB validation 112/112; TestRunner 80 passed / 0 failed; TestAudio 271 passed / 0 failed; "All executed checks passed" |

Not run: anything on the Mac (Forward+, frame rate, audio listening), Blender rebuilds (no Blender in this container; nothing in F0 changes assets).
