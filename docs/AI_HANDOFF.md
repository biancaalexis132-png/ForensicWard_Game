# AI handoff

This is where one agent tells the next exactly what it did and where to resume. Rules for writing and reading it are in `AGENTS.md` §7. Newest entry first; never edit or delete an older entry, add a correction in a new one.

A file cannot contain the SHA of the commit that adds it. So each entry records the **latest verified commit** it describes (the last commit whose contents and tests the entry vouches for). The commit that adds the entry sits on top of it; find it with `git ls-remote origin <branch>`. If the branch tip has more than that one doc commit on top of the recorded SHA, someone pushed after the entry was written: read `git log <recorded-sha>..origin/<branch>` before you trust it.

## Active workstreams

One row per branch that someone is working on. Claim the folders or files you will edit, so two agents never change the same file in parallel without a plan. Remove your row when the branch merges or is abandoned.

| Workstream | Branch | Agent / session | Latest verified commit | Claimed files | State |
|---|---|---|---|---|---|
| Sprint 1 integration | `claude/integrate-sprint-01` (draft PR) | Claude | `8ca85bce79f08f19ce75e00c33502a4e4af14146` | `project.godot`, `scripts/autoload/EventBus.gd`, `scripts/autoload/GameState.gd`, `scenes/main/Main.*`, `scripts/main/Main.gd`, `tests/qa/run.py`, `tests/qa/TestQA.gd`, `docs/TESTING.md` | Awaiting owner review and merge |
| Sprint 1 foundation | `claude/sprint-01-foundation` (PR #1) | Claude | `f626aad7be1c9a443762a5b2cd3591601c1b14bc` | Superseded by the integration PR | Close after the integration PR merges |
| Environment art | `claude/environment-production` (PR #6) | Claude | `e321b4a7f8d60f8b4400ea668959c25ac6b122e0` | `tools/blender/**`, `tools/godot/validate_glb_imports.gd`, `assets/blender/**`, `assets/exports/**`, `assets/asset_manifest/**`, `assets/renders/**`, `docs/ENVIRONMENT_*.md` | Stages 1–2 done; Stages 3–8 next |
| Chapter 1 playable | `claude/chapter1-playable` (PR #7) | Claude | `60ed74fe882385535425f2038add243f93cc4b9e` | `scripts/world/**`, `scripts/autoload/WorldStateManager.gd`, `data/world_chapter1.json`, `scenes/world/Chapter1Ward.tscn`, `scripts/tests/test_world.gd`, `docs/CHAPTER1_PLAYABLE.md` | Integration branch merged in; awaiting review |
| Sprint 2 EHR and interview | `claude/sprint-02-ehr-interview` (PR #9, draft, base `claude/chapter1-playable`) | Claude | see newest log entry | `scripts/ui/{EHRScreen,InterviewScreen,UIStyle}.gd`, `scenes/ui/{EHRScreen,InterviewScreen}.tscn`, `scripts/tests/test_sprint2.gd`, Sprint 2 edits to managers and data | Awaiting review |
| Audio production | `claude/audio-production` | Claude (separate session) | none pushed yet | `audio/**`, `tools/audio/**`, `systems/audio/**`, `scenes/audio/**`, `tests/audio/**`, `docs/AUDIO*.md` | Active, not on GitHub yet |

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
