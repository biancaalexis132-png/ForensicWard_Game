# Project status

Last updated: 2026-10-17 by Claude Code (audio workstream). Update this file whenever a system's status changes (see `AGENTS.md` §2).

Status values: **Done** (merged to `main`, tested), **Active** (being worked on, see branch), **Blocked** (reason given), **Untested** (exists but has no executed test), **Planned**.

## Systems

| System | Status | Where | Tests | Notes |
|---|---|---|---|---|
| Project skeleton, EventBus, GameState | Done | `main`: `autoload/` | `tests/qa/TestQA.tscn` (16 assertions) | |
| PharmacologyEngine (CYP/renal PK, alerts, clue gates) | Done | `main`: `systems/pharmacology/` | `tests/TestPharmacology.tscn` (19 assertions) | Clinical review is the owner's |
| Temporary boot demo (Main) | Done | `main`: `scenes/main/` | Boot smoke test | Will be replaced by the ward level |
| Headless QA runner + CI | Done | `main`: `tests/qa/run.py`, `.github/workflows/` | Itself | CI checkout now uses `lfs: true` |
| Adaptive audio engine (AudioDirector) | Done | `main` via PR #3: `systems/audio/` | `tests/audio/TestAudio.tscn` (92 assertions) | Ducking, music states and the AI-sheet loader are on the audio branch (PR pending) |
| Chapter 1 audio milestone (corridor loop, secure door, pager, intercom, unease transition, Bennett handover) | Done (needs listening review) | `audio/`, `scenes/audio/Ch1AudioSequence.tscn` | Sequence smoke test with ordered markers | Procedural SFX are placeholder grade; TTS delivery not reviewed by ear |
| Kokoro TTS voice pipeline | Done | `tools/audio/generate_voice.py`, `audio/voice_profiles.json` | Manifest and clip checks | 9 voice profiles; only Chapter 1 lines are voiced so far |
| AI music pipeline (ACE-Step 1.5) | **Blocked: needs the owner's Mac** | `tools/music_ai/`, `docs/MUSIC_AI_MAC_GUIDE.md` | Mock-server pipeline test only | The cloud container has no GPU, and Hugging Face/ModelScope are blocked. Milestone stays open until real files exist and are approved. |
| Remaining environmental SFX (footsteps, badge reader, computer UI, elevator, distant staff, historic static, electrical, Ward Zero anomalies) | Planned | `tools/audio/synth_sfx.py` (footstep source exists) | | Next audio work |
| Sprint 1 foundation: greybox hospital, FPS controller, interactions, managers (ContentRegistry, TimeManager, PatientManager, ClinicalRules, DialogueManager, EvidenceManager, TrustManager, SaveManager, Settings), JSON schemas | **Active, unmerged** | PR #1 `claude/sprint-01-foundation` | Its own test runner (`scripts/tests/`) | Restructures the project (moves autoloads to `scripts/autoload/`, moves the pharmacology system to staging, deletes `tests/qa/`). It **conflicts with current `main`** and needs an integration plan before merging (see below). |
| EHR, interview UI, evidence board, save/load UI | Planned | (Sprint 2–3 in the design handoff) | | |
| Blender environment assets | Not in repo yet | | | Do not modify from the audio or gameplay branches |

## Untested or manually verified only

- Audible quality of every audio asset. Headless Godot uses a dummy audio driver, and every manifest entry is `pending_listening_review`.
- `tools/music_ai/*.sh` on a real Mac. Shell syntax has been checked, and `check_mac.sh` has been run on Linux, where it correctly fails the macOS checks.
- Actual ACE-Step generation, MLX backend and model download.
- GitHub-hosted CI on the audio changes. It has not been observed by an agent; check the PR's checks.

## Integration plan needed: PR #1 versus `main`

`main` has gained the QA runner (PR #2) and the audio engine (PR #3). PR #1 deletes or moves several of the same paths (`autoload/EventBus.gd`, `tests/qa/`, the pharmacology files, `README.md`, `project.godot`). Before merging PR #1:

1. Merge `main` into `claude/sprint-01-foundation`. Do not rebase it.
2. Keep one EventBus: the foundation one at `scripts/autoload/EventBus.gd`. Add the three audio signals `narrative_event_fired`, `subtitle_shown` and `subtitle_cleared` to it.
3. Keep `AudioDirector` registered in `project.godot`, and change its dependency on `GameState.shift` to `TimeManager` (`EventBus.shift_changed`).
4. Unify volume settings: either `Settings` calls `AudioDirector.set_setting`, or the audio keys move into `Settings`. Add the `SFX` bus to `default_bus_layout.tres`.
5. Decide whether `tests/qa/run.py` or `scripts/tests/TestRunner` is the canonical runner, and keep the audio and pharmacology suites in it.

## File ownership (to avoid parallel edits)

| Area | Owner workstream | Shared files: coordinate before editing |
|---|---|---|
| `audio/`, `systems/audio/`, `tools/audio/`, `tools/music_ai/`, `tests/audio/`, `tests/music_ai/`, `scenes/audio/`, `data/narrative/` (audio fields only) | Audio | `autoload/EventBus.gd` (audio signals), `project.godot` (autoload line), `tests/qa/run.py` |
| `scripts/`, `scenes/world/`, `scenes/player/`, `scenes/props/`, `scenes/ui/` | Gameplay (PR #1) | same |
| `systems/pharmacology/`, `data/patients/`, `data/drugs/` | Clinical | |
| Blender/environment art | Environments | |
