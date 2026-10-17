# Project status

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Last verified:** 2026-10-17 by Claude Code (integration session), against `origin` after `git fetch --prune`.

Status meanings:

- **Completed:** merged to `main`, tests pass on `main`.
- **Done, not merged:** finished on a branch with an open PR; the owner has not merged it.
- **Active:** someone is working on it now; see `docs/AI_HANDOFF.md` for the branch and owner.
- **Blocked:** cannot proceed until the named thing happens.
- **Planned:** not started.
- **Untested:** exists, but the listed checks have not been executed.

## Branches on GitHub

| Branch | Tip | State | Notes |
|---|---|---|---|
| `main` | `91ad354` | Integration branch | Includes PR #2 (QA runner, CI), PR #3 (adaptive audio) and PR #4 (handoff system). |
| `claude/integrate-sprint-01` | see `docs/AI_HANDOFF.md` | Draft PR open, not merged | `main` + PR #1 reconciled; every `run.py` suite green locally. Supersedes merging PR #1 directly. |
| `claude/sprint-01-foundation` | `f626aad` | PR #1 open, not merged | Sprint 1 foundation. Merge the integration PR instead; PR #1 can then be closed. |
| `claude/environment-production` | `e321b4a` | PR #6 open, not merged | Blender sources, `.glb` exports, manifest, renders (Stages 1–2). Adds files only; no conflicts with `main`. |
| `claude/chapter1-playable` | see `docs/AI_HANDOFF.md` | PR #7 draft, not merged | Playable Chapter 1 in the Blender-built wing; contains PR #8 and PR #6. Merge order: #8, #6, #7. |
| `claude/sprint-02-ehr-interview` | see `docs/AI_HANDOFF.md` | PR #9 draft, stacked on #7 | Sprint 2: EHR, cinematic interview, observation capture, notes, clinical actions. |
| `claude/sprint-03-evidence-shift` | see `docs/AI_HANDOFF.md` | Draft PR, stacked on #9 | Sprint 3: story director, evidence board, shift sign-out, Bennett trust, after-hours W0-B beat. |
| `claude/quirky-ptolemy-6j16b7` | `a99782e` | PR #5 closed | Audio sound set / ACE-Step pipeline. |
| `codex/sprint-01-tests` | `d1d7479` | PR #2 merged | Codex QA runner and CI. |

Not on GitHub at the time of checking: `claude/audio-production`.

## Systems

| System | Status | Branch | Evidence | Untested / caveats |
|---|---|---|---|---|
| Godot 4.7 project config | Completed | `main` | `project.godot`, features `4.7`, Forward+ | Forward+ on the owner's Mac not confirmed for current `main` |
| EventBus, GameState autoloads | Done, not merged (integration) | `claude/integrate-sprint-01` | `scripts/autoload/`; QA suite 19 passed, 0 skipped | GameState is now a compatibility layer whose clock is TimeManager's |
| Pharmacology engine (CYP/renal PK, QTc, alerts) | Completed (clinically approved) | `main`; kept in place by the integration branch | `TestPharmacology` 0 failures; approval in `docs/clinical_review_log.md` (foundation branch) | Must be re-expressed as governed rules in `ClinicalRules` (Sprint 2) |
| Headless QA runner and CI | Completed; extended on integration branch | `main` | `tests/qa/run.py`, `.github/workflows/godot-validation.yml` | Integration branch adds `scripts/tests/TestRunner.tscn` and requires `skipped=0` |
| Adaptive audio engine (`AudioDirector`) | Completed | `main` | `TestAudio` 92 passed; Ch1 sequence completes | All assets `pending_listening_review`; mix untested on Mac |
| Chapter 1 audio milestone (ambience, door, pager, intercom, Bennett exchange, unease transition) | Completed | `main` | `audio/manifest.json`, `docs/AUDIO_MANIFEST.md` | Listening review by owner pending |
| Full audio production (all voices, score, more ambience) | Active | `claude/audio-production` (not pushed yet) | none on GitHub yet | Stable Audio and ACE-Step need the owner's Mac |
| Manager autoloads (Settings, SaveManager, ContentRegistry, TimeManager, PatientManager, ClinicalRules, DialogueManager, EvidenceManager, TrustManager) | Done, not merged | `claude/integrate-sprint-01` | 43/43 TestRunner tests pass inside `run.py` | |
| JSON content schemas and validator | Done, not merged | `claude/sprint-01-foundation` | Content tests in `scripts/tests/test_content.gd` | |
| First-person controller | Done, not merged | `claude/sprint-01-foundation` | `test_world.gd` movement and wall tests | Input feel and mouse recapture untested on Mac |
| Greybox hospital (corridor, office, interview room, records archive), doors, terminals, clue pickups | Done, not merged | `claude/sprint-01-foundation` | `test_world.gd` | Visuals checked only in Compatibility renderer |
| HUD, info panel, pause menu, save/load, accessibility toggles | Done, not merged | `claude/sprint-01-foundation` | `test_state.gd` | Manual Mac checklist in `docs/SPRINT_01.md` not done |
| Dialogue intent matcher | Done, not merged | `claude/sprint-01-foundation` | `test_dialogue.gd` | Elias dialogue `clinical_review_status: PENDING` |
| Environment art (Blender to `.glb`, Stages 1–2) | Done, not merged | `claude/environment-production` (PR #6) | 58/58 assets import in Godot 4.7 (`tools/godot/validate_glb_imports.gd`); `docs/ENVIRONMENT_STAGES.md` | Untextured; headless Blender only, no Blender MCP |
| Playable Chapter 1 wing (AuthoredWorld, imported doors and props, world states) | Done, not merged | `claude/chapter1-playable` (PR #7) | 46/46 TestRunner tests and 58/58 glb imports inside `run.py` | |
| EHR (census, summary, observations with provenance, structured notes, orders, audit) | Done, not merged | `claude/sprint-02-ehr-interview` (PR #9) | `scripts/tests/test_sprint2.gd`; screenshots in Compatibility renderer | No MAR/medication tab yet; Mac input untested |
| Cinematic interview UI, observation capture | Done, not merged | `claude/sprint-02-ehr-interview` (PR #9) | `test_sprint2.gd` (cameras, typed/structured questions, fallback) | Close-up/reverse shots unused until character models exist |
| `ClinicalRules` actions from the EHR (non-medical placeholder outcomes) | Done, not merged | PR #9 | Validated mode refuses pending rules (tested) | Both rules PENDING review |
| Pharmacology in the EHR (MAR, orders through governed rules) | Planned | | Sprint 3+ | Needs per-rule approval records |
| Evidence board (pin, link, argue, player hypotheses, provenance) | Done, not merged | `claude/sprint-03-evidence-shift` | `scripts/tests/test_sprint3.gd`; screenshot | |
| Chapter 1 story director (objectives, beats, staff lines), shift sign-out, Bennett trust, after-hours W0-B beat | Done, not merged | `claude/sprint-03-evidence-shift` | `test_sprint3.gd` (handover trust, intercom, chart entry, chapter end, save/load of pending beats) | GDD beat 4 (second patient) not authored; staff lines are placeholders |
| HUD objective and subtitles; room ambience zones | Done, not merged | `claude/sprint-03-evidence-shift` | `test_sprint3.gd` | Ambience heard only with a display (headless tracks only); mix untested on Mac |
| Acts II–V, more patients, Ward Zero (environment Stage 6) | Planned | | | Story content needs the narrative bible |

## Blocked

| Item | Blocked on | Who can unblock |
|---|---|---|
| Sprint 1 on `main` | Owner review and merge of the integration draft PR | Owner |
| Clinical rule `clinical_rule_catatonia_escalation_v1` as medical logic | Psychiatrist review | Owner |
| Elias Ward dialogue content, including the `records_observations` links and EHR action wording added in Sprint 2 | Psychiatrist review | Owner |
| Clinical rule `clinical_rule_medical_review_request_v1` | Psychiatrist review | Owner |
| Chapter 1 story lines in `data/story_chapter1.json` (Bennett lines, disputed transfer wording) | Narrative and clinical review | Owner |
| AI music (ACE-Step, Stable Audio) | Needs the owner's Mac or a GPU and a licence check | Owner |

## Integration risks

The PR #1 conflicts (`project.godot`, `EventBus.gd`, the removed `GameState`, the staged pharmacology, the replaced `Main`) are resolved on `claude/integrate-sprint-01`; see the newest `docs/AI_HANDOFF.md` entry. Merging PR #1 by itself would still break `main`'s runner, so merge the integration PR instead.

## Untested on hardware

Headless checks do not cover these. They stay here until the owner confirms them on the Mac:

- Forward+ / Metal rendering, lighting and frame rate
- Input feel, mouse capture after Cmd + Tab
- Audio mix, spatial audio, listening review of every asset
- Accessibility toggles in play (reduce motion, flicker off)
- Clinical correctness of anything marked pending
