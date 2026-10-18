# Project status

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Last GitHub state verified:** 2026-10-18 14:15 UTC against `origin/main` `a202caf` (PR #45 merged). PR #44 (F3) then merged at `fec5933`. Open: draft PR #46 (Naomi review-only preview). Naomi v02 is viewable in game only with `-- --character-preview=staff_bennett`; it is not approved.

Earlier snapshot: verified against fetched `origin/main` `7e5bd2a1aad3b6189996c4b706ef6e42d4715ae7`. PR #43 (Ward Zero Stage 6) and PR #42 (optional character visual slot/fallback) are merged; PR #44 and Naomi draft PR #45 are open. Naomi v01 remains unapproved and not integrated. Versioned v02 candidate assets are generated on `biancaalexis132-png-naomi-model-refinement`, merged with this latest main; v02 is structurally valid but still fails visual review and is not ready for runtime integration.

Status meanings:

- **Completed:** merged to `main`, tests pass on `main`.
- **Done, not merged:** finished on a branch with an open PR; the owner has not merged it.
- **Active:** someone is working on it now; see `docs/AI_HANDOFF.md` for the branch and owner.
- **Blocked:** cannot proceed until the named thing happens.
- **Planned:** not started.
- **Untested:** exists, but the listed checks have not been executed.

Architecture and plan for all five chapters: `docs/F0_FOUNDATION_AUDIT.md` (approved by the owner on 2026-10-17). Owner decisions that amend the GDD: `docs/design/GDD_AMENDMENTS.md`. Id rules: `docs/ID_REGISTRY.md`.

## Pull requests

| PR | Branch | State |
|---|---|---|
| (new) | `claude/naomi-v03` | Draft, Naomi v03 visual-development candidate; preview default v03; not approved |
| #48 | `claude/rahman-voice-profile-role` | Merged at `0fd2bc1` (Rahman voice direction: Consultant Psychiatrist) |
| #47 | `claude/naomi-preview-facing` | Merged at `c9655c7` (preview Naomi faces the counter) |
| #46 | `claude/naomi-review-preview` | Draft, review-only switch to view Naomi v02 at the nursing station |
| #45 | `biancaalexis132-png-naomi-model-refinement` | Merged at `a202caf` (Naomi v02 candidate; fails visual QA, not approved) |
| #44 | `claude/f3-anomaly-model` | Merged at `fec5933` (F3 anomaly model, flag off) |
| #43 | `claude/environment-stage-6` | Merged at `7e5bd2a` (Ward Zero rooms and anomaly states) |
| #42 | `biancaalexis132-png-cig-1-character-integration` | Merged at `de5cbfc` (optional character visual slot/fallback) |
| #41 | `docs/character-integration-gate-v1` | Merged at `8281b06` (CIG proposal and GLB preflight validator) |
| #40 | `docs/hale-mara-character-v1` | Merged at `64c3a2a` (Hale/Mara production specifications) |
| #38 | `biancaalexis132-png-jordan-vale-v2-review` | Merged at `cf62677` |
| #39 | `docs/character-production-batch-v1` | Merged at `3887b66` (Elias and Rahman production specifications; approval gates remain) |
| #37 | `biancaalexis132-png-naomi-character-pipeline` | Merged at `47a68f4` (Naomi base milestone; owner review/refinement remain) |
| #36 | `docs/jordan-vale-v2` | Merged at `03f1585` (Jordan Vale CP-001 v2 authoring package; clinical approval remains pending) |
| #35 | `biancaalexis132-png-naomi-chapter1-acting` | Merged at `21205c3` |
| #34 | `docs/complete-campaign-v1` | Merged at `a075d73` |
| #28 | `claude/visual-direction-review` | Merged at `fb07887`; review recommendations still need approval |
| #26 | `claude/f2-zones` | Merged at `9558c77` (zones and transitions) |
| #25, #24, #23 | `assets/ashcroft-creative-references` | Merged (continuity protocol / reference integration) |
| #22 | `assets/ashcroft-creative-references` | Merged (soundtrack and visual references) |
| #21 | `claude/f1-campaign-contract` | Merged (F1 campaign contract, save v2) |
| #20 | `claude/f0-foundation-audit` | Merged (F0 audit and architecture) |
| #19 | `claude/environment-stage-5` | Merged (Stage 5 historic substructure) |
| #18 | `claude/audio-production` | Merged (original soundtrack) |
| #17 | `claude/environment-stage-4b` | Merged (research wing) |
| #16 | `claude/remove-macos-metadata` | Closed, not merged (duplicate of #15) |
| #15 | `claude/remove-appledouble-metadata` | Merged (AppleDouble repair) |
| #14 | `claude/environment-stage-4` | Merged (security and admin wing) |
| #13 | `claude/nursing-station-props` | Merged |
| #12 | `claude/environment-stage-3` | Merged |
| #11 | `claude/integration-sprints-1-3` | Merged (Sprints 1–3, Blender Stages 1–2) |
| #10, #9 | `claude/sprint-03-evidence-shift`, `claude/sprint-02-ehr-interview` | Merged into the integration branch |
| #8, #7, #6, #1 | integration, chapter 1, environment, sprint 1 branches | Closed, superseded by #11 |
| #5, #4, #3, #2 | audio, handoff system, adaptive audio, Codex QA | Merged |

Remote branches may remain after merge. Branch existence alone does not prove active ownership. At this verification, PR #38 is the open review PR; historical soundtrack PR #27 and Stage 6 environment work must be checked before overlapping changes.

## Systems

| System | Status | Where | Evidence | Untested / caveats |
|---|---|---|---|---|
| Godot 4.7 project config | Completed | `main` | `project.godot`, features `4.7`, Forward+ | Forward+ on the owner's Mac not confirmed |
| EventBus and 14 autoloads (Settings, SaveManager, ContentRegistry, TimeManager, PatientManager, ClinicalRules, DialogueManager, EvidenceManager, TrustManager, WorldStateManager, GameState, PharmacologyEngine, AudioDirector) | Completed | `main` | TestRunner, TestQA | `GameState` is a compatibility layer (F0 C10) |
| Headless QA runner and CI | Completed | `main` | `tests/qa/run.py`, `.github/workflows/godot-validation.yml`; green on `33b2e8c` | |
| JSON content schemas and validator | Completed | `main` | `test_content.gd` | |
| Campaign contract: `data/campaign.json`, per-chapter story/world files, several dialogue files, id prefixes and cross-chapter uniqueness | Completed | `main` (PR #21) | `test_campaign.gd`, `test_content.gd` | Chapters 2–5 are `planned`; their stories exist only as test fixtures |
| Chapter-scoped story state (ChapterDirector) and save version 2 with v1 migration | Completed | `main` (PR #21) | `test_campaign.gd` (real v1 save captured from `main`) | |
| First-person controller, HUD, info panel, pause menu, accessibility toggles | Completed | `main` | `test_world.gd`, `test_state.gd` | Input feel, mouse recapture untested on Mac |
| Dialogue intent matcher and cinematic interview | Completed | `main` | `test_dialogue.gd`, `test_sprint2.gd` | Elias dialogue `clinical_review_status: PENDING` |
| EHR (census, summary, observations with provenance, notes, orders, audit) | Completed | `main` | `test_sprint2.gd` | No MAR/medication tab; observations have no polarity (unknown vs negative) yet |
| `ClinicalRules` governance (validated / prototype) | Completed | `main` | validated mode refuses pending rules (tested) | Both rules pending review |
| Pharmacology engine | Completed (clinically approved) | `main` | `TestPharmacology` | Not wired to the EHR; its clue gates conflict with the separation rule (F0 C7, owner decision pending) |
| Evidence board, clues, hypotheses | Completed | `main` | `test_sprint3.gd` | Clues carry `source_class` and `claim_state` on `claude/f3-anomaly-model` (F3) |
| Chapter 1 story director, sign-out, Bennett trust, after-hours W0-B beat | Completed | `main` | `test_sprint3.gd` | Beat 4 (second patient) not authored; staff lines are placeholders |
| Playable Chapter 1 wing (AuthoredWorld) | Completed | `main` | `test_world.gd`; 7 environments loaded at once | F2 is merged; built as the clinical-wing zone |
| Environment art Stages 1–3 (+ nursing station props) | Completed | `main` | `.glb` validation | Untextured |
| Environment Stage 4a security/admin, 4b research | Completed | `main` (PR #14, #17) | `.glb` validation | Reachable as zones on `main` (locked in Chapter 1); no characters or props wired |
| Environment Stage 5 historic substructure | Completed | `main` (PR #19) | 138/138 `.glb` import in Godot 4.7 | Reachable through the service hatch on `main` (locked in Chapter 1); the stair is a use-to-climb point, not walkable |
| Adaptive audio engine, Chapter 1 audio, original soundtrack | Completed | `main` (PR #3, #5, #18) | TestAudio 271 passed | Listening review on the Mac pending; music contexts not fired yet (no title screen or credits) |
| Hospital name in game data | Completed | `main` (PR #21) | `data/campaign.json` `institution.name` | Not shown on any screen yet; signage textures come with Stage 8 |
| Zones and transitions (F2): `data/zones.json`, `ZoneDirector`, save version 3 with v2 migration | Completed | `main` (PR #26) | `test_zones.gd` (15 tests: seamless ward entry, 10 lift round trips with flat memory, door state across unload/save/load, arrivals on a floor, real v2 save from `main`) | Worker-thread streaming is off in headless runs (Godot's dummy renderer is not thread-safe), so it is untested until run on the Mac; arrival points are placeholders; security and research use the corridor ambience |
| Naomi Chapter 1 acting-cue presentation | Completed on `main` (PR #35 merged) | `scripts/acting/NaomiActingController.gd`, `CharacterActingAdapter.gd`; wired only to `staff_bennett` | Merged PR #35; prior branch evidence: cue validator 5/5, TestRunner 122/0, TestAudio 336/0 | Real-model animation/face/gesture feel remains untested on Mac; separate Naomi model pipeline is a different workstream |
| Optional WardCharacter 3D visual slot and placeholder fallback | Completed on `main` (PR #42 merged at `de5cbfc`) | `scripts/world/Character.gd`, `scenes/props/Character.tscn`, `scripts/tests/test_character_visual.gd` | Historical Godot 4.7 TestRunner 127/0 covered fallback, scene attachment, dialogue, save/load and zone rebuild; GLB import validator 139/139 | No approved character model is attached; owner Mac render/performance review is untested |
| Continuing Practice / CP-001 Jordan v2 | Planned (authoring package merged by #36; design review on this branch) | `docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/` | `REVIEW.md` | No case schema, validator, loader, lifecycle or clinical rules; all case details remain pending review; current SaveManager is v3 |
| Naomi 3D character base and builder | Base merged (PR #37 at `47a68f4`); v02 candidate merged (PR #45 at `a202caf`), not approved | `tools/blender/characters/`, Naomi v02 Blender/GLB/renders and asset manifests | Blender 5.2.2 validator: 53 joints, 32,281 triangles, 3 embedded textures, 4 renders; CIG preflight: 15 meshes, 69 nodes, 1 skin, 0 animations; Godot 4.7 import validator 154/154; TestRunner 127/0 | v02 close render shows facial features but full-body views still read as one continuous lower garment with angular garment/skin boundaries; QA checklist fails. Owner appearance review, further procedural refinement, animation, LOD, runtime integration and target-device performance remain pending |
| Naomi in-game review preview | Completed on `main` (PR #46, facing in #47) | `scripts/world/CharacterVisualPreview.gd`, `scripts/tests/test_character_preview.gd`, `docs/design/characters/Naomi_Bennett_Character_Production_v1/NAOMI_INGAME_REVIEW.md` | TestRunner 131/0 and full QA exit 0 in a Linux container; in-game captures on software OpenGL | Off by default. Untested on Mac; no frame-time measurement. v02 fails appearance review in game too (hair strips, trousers, T-pose) |
| Naomi v03 visual-development candidate | Done, not merged (draft PR); not approved | `tools/blender/characters/build_naomi_v03.py`, `assets/exports/characters/Naomi_Bennett_v03.glb`, `NAOMI_V03_NOTES.md` | Blender 5.2.2 build, 44,692 triangles, 1 skin, 0 animations; Godot 4.7 import and in-game captures on software OpenGL | Far more realistic than v02 at counter distance; still no animation, facial shapes, groomed hair, simulated cloth or pore-level skin. Untested on Mac |
| Elias and Rahman character production specifications | Merged as design package (PR #39 at `3887b66`) | `docs/design/characters/Elias_Ward_Character_Production_v1/`, `docs/design/characters/Rahman_Character_Production_v1/` | Production docs and review gates | Does not constitute clinical or canon approval, nor runtime integration |
| Anomaly evidence model and clinical/supernatural separation (F3): `data/anomalies.json`, `AnomalyLedger`, validator separation rules, clue `source_class` and `claim_state` | Done, not merged | `claude/f3-anomaly-model` | `test_anomaly.gd` (15 tests: flag off changes nothing, ledger on/off/removed give identical game state, Chapter 1 capped at reported, save/load without re-firing, no clinical signal connected, objectivity never reveals the anomaly, testimony never counts, validator rules) | Flag `forensic_ward/narrative/anomaly_enabled` ships off; Psychosomatic Bleed is presentation only (owner, 2026-10-17); pharmacology clue gates on PT-001 and PT-002 are reported at boot as known exceptions until F0 C7 is decided |
| Mara Ellis, Chapters 2–5 content, title screen | Planned | | v1.1 handoff | Clinical and narrative approval needed first |
| Environment Stage 6 Ward Zero (7 props, 7 rooms, swappable anomaly states) | Completed on `main` in PR #43 at `7e5bd2a` | `tools/blender/build_stage6_ward_zero.py`, `assets/exports/wardzero/**` | Godot 4.7 import validator now checks 154 assets with 0 failures on the Naomi refinement merge | Not wired into gameplay; anomaly states provisional pending owner review |
| Exterior (Stage 7), textures (Stage 8) | Planned | | `docs/ENVIRONMENT_STAGES.md` | |

## Blocked

| Item | Blocked on | Who can unblock |
|---|---|---|
| Clinical rules `clinical_rule_catatonia_escalation_v1`, `clinical_rule_medical_review_request_v1` as medical logic | Psychiatrist review | Owner |
| Elias Ward dialogue and EHR action wording | Psychiatrist review | Owner |
| Chapter 1 story lines in `data/story_chapter1.json` | Narrative and clinical review | Owner |
| Pharmacology clue gates (F0 C7), Psychosomatic Bleed (C6), Concordance thread (C2), player title (C3), staff roles (C4) | Owner decisions listed in F0 §9 | Owner |
| AI music (ACE-Step, Stable Audio) | The owner's Mac or a GPU, and a licence check | Owner |

## Untested on hardware

Headless checks do not cover these. They stay here until the owner confirms them on the Mac:

- Forward+ / Metal rendering, lighting and frame rate
- Input feel, mouse capture after Cmd + Tab
- Zone transitions: fade smoothness, hitch when a zone streams in, frame time and memory before and after (turn on the `perf_log` setting; it writes `user://perf_log.csv`)
- Audio mix, spatial audio, listening review of every asset
- Naomi base likeness, hair silhouette, scrub fit/deformation and acting quality; the 30 FPS / p95 33.3 ms budget has not been measured in the Chapter 1 scene
- Accessibility toggles in play (reduce motion, flicker off)
- Clinical correctness of anything marked pending

## Naomi Chapter 1 acting-cue workstream (merged in PR #35)

- The additive, model-independent presentation controller uses the source cue package at `docs/design/characters/Naomi_Acting_Cues_v1/`; it does not alter dialogue wording, IDs, story progression, clinical review status, gameplay, or save schema.
- PR #35 merged to `main` at `21205c3`; its adapter remains capability-driven and does not require MPFB bones.
- Focused validation: cue validator 5 IDs/voice mappings; TestRunner 122/0; TestAudio 336/0. The repository runner stops in music generation because local FFmpeg lacks `libvorbis` (music pipeline 1 passed/2 failed); subsequent suites were run directly on the merged Naomi model branch and passed. CI is not observed.
- The adapter is capability-driven and the current placeholder requires no clips, facial blend shapes, or named bones. Realistic-model playback/visual review remains for the owner on Mac. Do not modify the active Naomi model-builder branch from this workstream.

## Naomi 3D character base (merged base milestone; v02 refinement candidate)

- PR #37 merged to `main` at `47a68f4`; PR #42 later merged optional visual/fallback groundwork at `de5cbfc`. The procedural refinement branch is `biancaalexis132-png-naomi-model-refinement`, based on current main `7e5bd2a` and locally merged to `9a36b37`.
- Builder, configuration, validator and exact Mac commands live in `tools/blender/characters/`. v01 remains unchanged for comparison; v02 source/GLB and four renders are in the versioned paths documented in `assets/asset_manifest/naomi_character_manifest_v02.json`.
- Exact MPFB2 v2.0.18 inputs, CC0-1.0 asset-license evidence, GPL-3.0-or-later tool-code notice, female macro weights, output sizes and limitations are in the v02 manifest. No Mixamo or non-MPFB external assets were used. No gameplay, dialogue, clinical or save changes were made.
- v02 passes the Blender 5.2.2 validator: 53 joints, 32,281 triangles (45,000 budget), three embedded textures and four renders. CIG preflight reports 15 meshes, 69 nodes, one skin, zero animation clips, 11 materials and three textures. Godot 4.7 imported the branch merge and validated 154 assets with zero failures; TestRunner passed 127/0. Full `tests/qa/run.py` is blocked by two music-preview tests failing with local FFmpeg `Unknown encoder 'libvorbis'`.
- Repeated same-config builds produce byte-identical GLB and normalized render PNGs; Blender `.blend` container bytes may differ from internal serialization. Visual inspection shows facial details in the close view, but the full-body outfit still reads as one continuous lower garment and has angular garment/skin boundaries. The visual QA checklist fails; v02 is not ready for runtime integration. No photorealism claim is made.
- Owner appearance review, further procedural garment/mesh improvement, animation clips, LOD, Chapter 1 integration and target-device performance remain pending. Keep `staff_bennett`, dialogue and clinical review unchanged; do not attach v02 to the merged optional visual slot. Do not integrate CP-001 screenplay content with Naomi before its separate identity/canon and clinical gates clear.

## Codex continuation: protagonist specification and save QA

- Approved requirements: fixed psychiatrist role, customizable background/appearance, moderate personal life, emergent personality. Recorded in `docs/design/GDD_AMENDMENTS.md` from the owner’s current handoff.
- Proposed engineering plan: `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`; creator/provider/v4 migration are **not implemented** and require owner review.
- Baseline on `fb07887`: Python 6+3+3 passed; pharmacology 0 failures; QA 19 passed/0 failed/0 skipped; GLB 138/138; TestRunner 112/0; boot OK; audio 271/0; Chapter 1 sequence complete; runner exit 0. Headless Linux only; hosted CI not observed.
- Independent regression suite complete on feature branch `codex/protagonist-foundation-cont-1` at `01739ff`: four new tests; full runner exit 0, TestRunner 116/0 and all other baseline checks unchanged. No runtime/save schema/clinical/visual change. Not merged; PR creation blocked by API proxy denial. See session handoff.
- Missing source dependency: private v1.1 bible package is not accessible here or committed. Available GDD, engineering contract, PDF character guide and reference READMEs were inspected. No replacement canon is invented.
