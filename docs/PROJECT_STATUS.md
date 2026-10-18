# Project status

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Last verified:** 2026-10-18 by Copilot against `origin/main` `21205c3c71d4543a2fa4abe0d54e172ce725db01` (PR #35 merged), using fetched Git history and `gh`. Draft model PR #37 is open against `main`; hosted CI was not observed. Full local Godot 4.7 checks on the merged model branch passed except the full runner's two music-preview cases, blocked by local FFmpeg missing `libvorbis`. See [REPOSITORY_RECONCILIATION.md](REPOSITORY_RECONCILIATION.md).

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
| #37 | `biancaalexis132-png-naomi-character-pipeline` | Draft; automated Naomi base for review |
| #35 | `biancaalexis132-png-naomi-chapter1-acting` | Merged at `21205c3` (Naomi acting cues) |
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

Remote branches may remain after merge. Branch existence alone does not prove active ownership. Historical soundtrack PR #27 and Stage 6 environment work must be checked before overlapping changes.

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
| Evidence board, clues, hypotheses | Completed | `main` | `test_sprint3.gd` | No source class or claim states yet (F3) |
| Chapter 1 story director, sign-out, Bennett trust, after-hours W0-B beat | Completed | `main` | `test_sprint3.gd` | Beat 4 (second patient) not authored; staff lines are placeholders |
| Playable Chapter 1 wing (AuthoredWorld) | Completed | `main` | `test_world.gd`; 7 environments loaded at once | F2 is merged; built as the clinical-wing zone |
| Environment art Stages 1–3 (+ nursing station props) | Completed | `main` | `.glb` validation | Untextured |
| Environment Stage 4a security/admin, 4b research | Completed | `main` (PR #14, #17) | `.glb` validation | Reachable as zones on `main` (locked in Chapter 1); no characters or props wired |
| Environment Stage 5 historic substructure | Completed | `main` (PR #19) | 138/138 `.glb` import in Godot 4.7 | Reachable through the service hatch on `main` (locked in Chapter 1); the stair is a use-to-climb point, not walkable |
| Adaptive audio engine, Chapter 1 audio, original soundtrack | Completed | `main` (PR #3, #5, #18) | TestAudio 271 passed | Listening review on the Mac pending; music contexts not fired yet (no title screen or credits) |
| Hospital name in game data | Completed | `main` (PR #21) | `data/campaign.json` `institution.name` | Not shown on any screen yet; signage textures come with Stage 8 |
| Zones and transitions (F2): `data/zones.json`, `ZoneDirector`, save version 3 with v2 migration | Completed | `main` (PR #26) | `test_zones.gd` (15 tests: seamless ward entry, 10 lift round trips with flat memory, door state across unload/save/load, arrivals on a floor, real v2 save from `main`) | Worker-thread streaming is off in headless runs (Godot's dummy renderer is not thread-safe), so it is untested until run on the Mac; arrival points are placeholders; security and research use the corridor ambience |
| Naomi Chapter 1 acting-cue presentation | Completed (PR #35 merged at `21205c3`) | `scripts/acting/NaomiActingController.gd`, `CharacterActingAdapter.gd`; wired only to `staff_bennett` | Main; cue validator 5/5, TestRunner 122/0, TestAudio 336/0 | Owner/Mac review of real-model animation, face and gesture feel remains |
| Naomi 3D character base and builder | Active (draft PR #37; not merged) | `tools/blender/characters/`, `assets/blender/characters/Naomi_Bennett_Base_v01.blend`, `assets/exports/characters/Naomi_Bennett_Base_v01.glb`, both Naomi asset manifests | Tested code at `2a6ffda`; Blender validator: 53 joints / 42,583 triangles / 4 renders; Godot 4.7 GLB validator: 139/139 | Automated base only; face/hair/clothing review, animations, LOD, Chapter 1 integration and target-device performance remain |
| Anomaly evidence model and clinical/supernatural separation (F3) | Planned | | F0 §7, §8 | Waits on the owner's Psychosomatic Bleed decision |
| Mara Ellis, Chapters 2–5 content, title screen | Planned | | v1.1 handoff | Clinical and narrative approval needed first |
| Ward Zero (Stage 6), exterior (Stage 7), textures (Stage 8) | Planned | | `docs/ENVIRONMENT_STAGES.md` | |

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

## Naomi 3D character base (active branch; base milestone only)

- Branch `biancaalexis132-png-naomi-character-pipeline` is pushed through verified documentation checkpoint `ff1b4059f5d728d37c24fe47762ecb7bff8948fd`, atop tested code `2a6ffda5e580c551b0f2f235861960e0d7662657`; it includes current main `21205c3`. Draft PR #37 is open; do not merge automatically.
- Builder, configuration, validator and exact Mac commands live in `tools/blender/characters/`. Generated outputs are `assets/blender/characters/Naomi_Bennett_Base_v01.blend`, `assets/exports/characters/Naomi_Bennett_Base_v01.glb`, and four review renders. The model is an automated base, not a finished realistic Naomi; its face, pulled-back twists, clothing fit/deformation and rendered likeness still require owner/artist review.
- Exact MPFB2 v2.0.18 inputs, CC0-1.0 license evidence, GPL tool-code notice, macro weights, output sizes and limitations are in `assets/asset_manifest/naomi_character_manifest.json`; the common GLB manifest records imported dimensions and materials. No Mixamo or non-MPFB assets were used; this workstream made no gameplay, dialogue, clinical, or save changes.
- Blender 5.2.2 build/validator passed; GLB is 53 joints / 42,583 triangles with two embedded textures. Godot 4.7 import and 139/139 GLB asset checks passed; QA 19/0/0, TestRunner 122/0, TestAudio 336/0, pharmacology 0 failures, boot and Chapter 1 audio sequence passed. The full runner's only failures are two music-preview tests blocked by local FFmpeg `Unknown encoder 'libvorbis'`.
- No animations, LOD1, Chapter 1 model integration or 8 GB Mac frame-time measurement are done. Keep `staff_bennett`, dialogue and clinical review status unchanged; use the merged model-independent acting adapter without requiring named bones. Do not integrate CP-001 screenplay content with Naomi before its separate identity/canon and clinical gates clear.

## Codex continuation: protagonist specification and save QA

- Approved requirements: fixed psychiatrist role, customizable background/appearance, moderate personal life, emergent personality. Recorded in `docs/design/GDD_AMENDMENTS.md` from the owner’s current handoff.
- Proposed engineering plan: `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`; creator/provider/v4 migration are **not implemented** and require owner review.
- Baseline on `fb07887`: Python 6+3+3 passed; pharmacology 0 failures; QA 19 passed/0 failed/0 skipped; GLB 138/138; TestRunner 112/0; boot OK; audio 271/0; Chapter 1 sequence complete; runner exit 0. Headless Linux only; hosted CI not observed.
- Independent regression suite complete on feature branch `codex/protagonist-foundation-cont-1` at `01739ff`: four new tests; full runner exit 0, TestRunner 116/0 and all other baseline checks unchanged. No runtime/save schema/clinical/visual change. Not merged; PR creation blocked by API proxy denial. See session handoff.
- Missing source dependency: private v1.1 bible package is not accessible here or committed. Available GDD, engineering contract, PDF character guide and reference READMEs were inspected. No replacement canon is invented.
