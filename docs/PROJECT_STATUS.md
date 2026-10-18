# Project status

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Last verified:** 2026-10-18 01:45 UTC by Claude Code (F3 anomaly session), against `origin` after `git fetch --prune`. `main` was at `9558c77` (PR #26 merged).

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
| F3 | `claude/f3-anomaly-model` | Draft, waiting on owner review (anomaly model, flag off) |
| #26 | `claude/f2-zones` | Merged (F2 zones, save v3) |
| #25 | | Merged (session continuity protocol in `CLAUDE.md`) |
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

The branches of merged and closed PRs still exist on `origin`; nobody works on them.

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
| Playable Chapter 1 wing (AuthoredWorld) | Completed | `main` | `test_world.gd`; 7 environments loaded at once | On `claude/f2-zones` it is built as the clinical-wing zone |
| Environment art Stages 1–3 (+ nursing station props) | Completed | `main` | `.glb` validation | Untextured |
| Environment Stage 4a security/admin, 4b research | Completed | `main` (PR #14, #17) | `.glb` validation | Reachable as zones on `claude/f2-zones` (locked in Chapter 1); no characters or props wired |
| Environment Stage 5 historic substructure | Completed | `main` (PR #19) | 138/138 `.glb` import in Godot 4.7 | Reachable through the service hatch on `claude/f2-zones` (locked in Chapter 1); the stair is a use-to-climb point, not walkable |
| Adaptive audio engine, Chapter 1 audio, original soundtrack | Completed | `main` (PR #3, #5, #18) | TestAudio 271 passed | Listening review on the Mac pending; music contexts not fired yet (no title screen or credits) |
| Hospital name in game data | Completed | `main` (PR #21) | `data/campaign.json` `institution.name` | Not shown on any screen yet; signage textures come with Stage 8 |
| Zones and transitions (F2): `data/zones.json`, `ZoneDirector`, save version 3 with v2 migration | Completed | `main` (PR #26) | `test_zones.gd` (15 tests: seamless ward entry, 10 lift round trips with flat memory, door state across unload/save/load, arrivals on a floor, real v2 save from `main`) | Worker-thread streaming is off in headless runs (Godot's dummy renderer is not thread-safe), so it is untested until run on the Mac; arrival points are placeholders; security and research use the corridor ambience |
| Anomaly evidence model and clinical/supernatural separation (F3): `data/anomalies.json`, `AnomalyLedger`, validator separation rules, clue `source_class` and `claim_state` | Done, not merged | `claude/f3-anomaly-model` | `test_anomaly.gd` (15 tests: flag off changes nothing, ledger on/off/removed give identical game state, Chapter 1 capped at reported, save/load without re-firing, no clinical signal connected, objectivity never reveals the anomaly, testimony never counts, validator rules) | Flag `forensic_ward/narrative/anomaly_enabled` ships off; Psychosomatic Bleed is presentation only (owner, 2026-10-17); pharmacology clue gates on PT-001 and PT-002 are reported at boot as known exceptions until F0 C7 is decided |
| Mara Ellis, Chapters 2–5 content, protagonist creator, title screen | Planned | | v1.1 handoff | Clinical and narrative approval needed first |
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
- Accessibility toggles in play (reduce motion, flicker off)
- Clinical correctness of anything marked pending
