# Project status

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Last verified:** 2026-10-17 15:40 UTC by Claude Code, against `origin` after `git fetch --prune`.

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
| `main` | `8e64eaf` | Integration branch | Includes PR #2 (QA runner, CI) and PR #3 (adaptive audio). CI green on this commit. |
| `claude/sprint-01-foundation` | `f626aad` | PR #1 open, not merged | Sprint 1 foundation. Based on `06046ea`; has diverged from `main` (see Integration risks). |
| `codex/sprint-01-tests` | `d1d7479` | PR #2 merged 2026-10-17 | Codex QA runner and CI. |
| `claude/quirky-ptolemy-6j16b7` | `c58efc9` | PR #3 merged 2026-10-17 | Adaptive audio engine and Chapter 1 audio milestone. |
| `claude/ai-handoff-system` | see PR | Draft PR | This handoff system (`AGENTS.md`, `CLAUDE.md`, these docs). |

Not yet on GitHub at the time of checking: `claude/audio-production` and `claude/environment-production`. Sessions are working toward them; nothing on them is available until they are pushed.

## Systems

| System | Status | Branch | Evidence | Untested / caveats |
|---|---|---|---|---|
| Godot 4.7 project config | Completed | `main` | `project.godot`, features `4.7`, Forward+ | Forward+ on the owner's Mac not confirmed for current `main` |
| EventBus, GameState autoloads | Completed | `main` | `autoload/`; QA suite 16 passed | Replaced by the manager set on PR #1 |
| Pharmacology engine (CYP/renal PK, QTc, alerts) | Completed (clinically approved) | `main`; staged copy on PR #1 | `TestPharmacology` 0 failures; approval in `docs/clinical_review_log.md` (foundation branch) | Must be re-expressed as governed rules in `ClinicalRules` (Sprint 2) |
| Headless QA runner and CI | Completed | `main` | `tests/qa/run.py`, `.github/workflows/godot-validation.yml`; CI run on `8e64eaf` passed | Does not run PR #1's `scripts/tests/` suites |
| Adaptive audio engine (`AudioDirector`) | Completed | `main` | `TestAudio` 92 passed; Ch1 sequence completes | All assets `pending_listening_review`; mix untested on Mac |
| Chapter 1 audio milestone (ambience, door, pager, intercom, Bennett exchange, unease transition) | Completed | `main` | `audio/manifest.json`, `docs/AUDIO_MANIFEST.md` | Listening review by owner pending |
| Full audio production (all voices, score, more ambience) | Active | `claude/audio-production` (not pushed yet) | none on GitHub yet | Stable Audio and ACE-Step need the owner's Mac |
| Manager autoloads (Settings, SaveManager, ContentRegistry, TimeManager, PatientManager, ClinicalRules, DialogueManager, EvidenceManager, TrustManager) | Done, not merged | `claude/sprint-01-foundation` | 43/43 tests pass | Conflicts with `main` |
| JSON content schemas and validator | Done, not merged | `claude/sprint-01-foundation` | Content tests in `scripts/tests/test_content.gd` | |
| First-person controller | Done, not merged | `claude/sprint-01-foundation` | `test_world.gd` movement and wall tests | Input feel and mouse recapture untested on Mac |
| Greybox hospital (corridor, office, interview room, records archive), doors, terminals, clue pickups | Done, not merged | `claude/sprint-01-foundation` | `test_world.gd` | Visuals checked only in Compatibility renderer |
| HUD, info panel, pause menu, save/load, accessibility toggles | Done, not merged | `claude/sprint-01-foundation` | `test_state.gd` | Manual Mac checklist in `docs/SPRINT_01.md` not done |
| Dialogue intent matcher | Done, not merged | `claude/sprint-01-foundation` | `test_dialogue.gd` | Elias dialogue `clinical_review_status: PENDING` |
| Environment art (Blender to `.glb`, stage 1 build) | Active | `claude/environment-production` (not pushed yet) | none on GitHub yet | Headless Blender only; no Blender MCP |
| EHR patient record view | Planned | | Sprint 2 | |
| Cinematic interview UI, observation capture | Planned | | Sprint 2 | |
| `ClinicalRules` with pharmacology integration | Planned | | Sprint 2 | Needs per-rule approval records |
| Evidence board, shift time, nurse trust, Ward Zero clue | Planned | | Sprint 3 | |
| Investigation system, five-act story | Planned | | | |

## Blocked

| Item | Blocked on | Who can unblock |
|---|---|---|
| Merging PR #1 into `main` | Integration plan below; PR #1 has no CI run because it predates the workflow | Owner decides the plan; one agent executes it |
| Clinical rule `clinical_rule_catatonia_escalation_v1` as medical logic | Psychiatrist review | Owner |
| Elias Ward dialogue content | Psychiatrist review | Owner |
| AI music (ACE-Step, Stable Audio) | Needs the owner's Mac or a GPU and a licence check | Owner |

## Integration risks

**PR #1 against current `main`.** Checked with `git merge-tree origin/main origin/claude/sprint-01-foundation` on 2026-10-17:

- Text conflicts: `project.godot` (both branches rewrote the autoload list) and `autoload/EventBus.gd` (deleted on PR #1, extended on `main` for audio).
- Semantic conflicts with no text conflict: PR #1 removes `autoload/GameState.gd`, moves `systems/pharmacology/` to `staging/`, and replaces `scenes/main/Main`. `main`'s QA runner, `TestPharmacology`, `TestQA` and `AudioDirector` depend on those paths.

Proposed plan, which the owner should confirm before anyone starts: one agent, on a new branch `claude/integrate-sprint-01` from `main`, merges `claude/sprint-01-foundation`, keeps the `scripts/` layout from PR #1, ports `AudioDirector` signals onto the new `EventBus`, adds PR #1's `TestRunner` to `tests/qa/run.py`, and keeps all three suites green. Audio and environment branches should not edit `project.godot` or `EventBus.gd` until that lands.

## Untested on hardware

Headless checks do not cover these. They stay here until the owner confirms them on the Mac:

- Forward+ / Metal rendering, lighting and frame rate
- Input feel, mouse capture after Cmd + Tab
- Audio mix, spatial audio, listening review of every asset
- Accessibility toggles in play (reduce motion, flicker off)
- Clinical correctness of anything marked pending
