# Project status

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Last verified:** 2026-10-17 20:45 UTC by Claude Code (F1 campaign contract session), against `origin` after `git fetch --prune`. `main` was at `33b2e8c` (PR #20 merged); no pull requests were open.

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
| Campaign contract: `data/campaign.json`, per-chapter story/world files, several dialogue files, id prefixes and cross-chapter uniqueness | Done, not merged | `claude/f1-campaign-contract` | `test_campaign.gd`, `test_content.gd` | Chapters 2–5 are `planned`; their stories exist only as test fixtures |
| Chapter-scoped story state (ChapterDirector) and save version 2 with v1 migration | Done, not merged | `claude/f1-campaign-contract` | `test_campaign.gd` (real v1 save captured from `main`) | |
| First-person controller, HUD, info panel, pause menu, accessibility toggles | Completed | `main` | `test_world.gd`, `test_state.gd` | Input feel, mouse recapture untested on Mac |
| Dialogue intent matcher and cinematic interview | Completed | `main` | `test_dialogue.gd`, `test_sprint2.gd` | Elias dialogue `clinical_review_status: PENDING` |
| EHR (census, summary, observations with provenance, notes, orders, audit) | Completed | `main` | `test_sprint2.gd` | No MAR/medication tab; observations have no polarity (unknown vs negative) yet |
| `ClinicalRules` governance (validated / prototype) | Completed | `main` | validated mode refuses pending rules (tested) | Both rules pending review |
| Pharmacology engine | Completed (clinically approved) | `main` | `TestPharmacology` | Not wired to the EHR; its clue gates conflict with the separation rule (F0 C7, owner decision pending) |
| Evidence board, clues, hypotheses | Completed | `main` | `test_sprint3.gd` | No source class or claim states yet (F3) |
| Chapter 1 story director, sign-out, Bennett trust, after-hours W0-B beat | Completed | `main` | `test_sprint3.gd` | Beat 4 (second patient) not authored; staff lines are placeholders |
| Playable Chapter 1 wing (AuthoredWorld) | Completed | `main` | `test_world.gd`; 7 environments loaded at once | No zones or transitions yet (F2) |
| Environment art Stages 1–3 (+ nursing station props) | Completed | `main` | `.glb` validation | Untextured |
| Environment Stage 4a security/admin, 4b research | Completed | `main` (PR #14, #17) | `.glb` validation | Not wired into gameplay |
| Environment Stage 5 historic substructure | Completed | `main` (PR #19) | 138/138 `.glb` import in Godot 4.7 | Not wired into gameplay; stair needs a climb interaction |
| Adaptive audio engine, Chapter 1 audio, original soundtrack | Completed | `main` (PR #3, #5, #18) | TestAudio 271 passed | Listening review on the Mac pending; music contexts not fired yet (no title screen or credits) |
| Hospital name in game data | Done, not merged | `claude/f1-campaign-contract` | `data/campaign.json` `institution.name` | Not shown on any screen yet; signage textures come with Stage 8 |
| Zone streaming and transitions (F2) | Planned | | F0 §6, §8 | Starts after F1 is reviewed |
| Anomaly evidence model and clinical/supernatural separation (F3) | Planned | | F0 §7, §8 | Waits on the owner's Psychosomatic Bleed decision |
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
- Audio mix, spatial audio, listening review of every asset
- Accessibility toggles in play (reduce motion, flicker off)
- Clinical correctness of anything marked pending
