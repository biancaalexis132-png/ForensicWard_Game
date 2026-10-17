# AGENTS.md: shared rules for every AI agent (Claude Code, OpenAI Codex, others)

The Forensic Ward is a 3D psychological thriller and forensic psychiatry simulator in **Godot 4.7** (Forward+). Several AI agents take turns developing it. When one agent runs out of usage, it hands over to another. These rules let any agent resume exactly where the previous one stopped.

**Read first, every session:** this file, then [`docs/PROJECT_STATUS.md`](docs/PROJECT_STATUS.md), [`docs/AI_HANDOFF.md`](docs/AI_HANDOFF.md), and any open pull requests. The project decisions recorded in `README.md`, `docs/` and the design handoff on the foundation branch (`docs/design/`) still apply. This file does not override them; it only adds the coordination rules.

## 1. Resuming work

1. `git fetch origin --prune`. List branches and open PRs.
2. Read `docs/AI_HANDOFF.md`. Confirm that the branch and commit it names exist on the remote (`git branch -r --contains <sha>`). If the handoff mentions anything that is not on GitHub, treat it as missing.
3. Check what the other agent committed or merged since then (`git log --oneline <handoff-sha>..origin/<branch>`, and `git log origin/main`).
4. Continue from the latest verified remote state. Never overwrite or silently discard another agent's work. If two lines of work conflict, stop and describe the conflict in the handoff or PR instead of choosing one.
5. Run the test suite (section 5) before you change anything, so you know which failures were already there.

## 2. Handing off (before ending a session or when approaching a usage limit)

1. Save everything. Commit coherent work-in-progress to the active feature branch, with a commit message prefixed `WIP:` if it is unfinished.
2. Run the tests and record the exact results, with pass/fail counts, in `docs/AI_HANDOFF.md`.
3. Push. Write the exact branch and commit SHA in the handoff. **Never describe uncommitted or unpushed changes as available on GitHub.**
4. Record any unfinished functions, known errors, and the next steps as concrete commands, file paths and acceptance checks. "Continue development" is not an acceptable next step.
5. List any local-only files, model weights, credentials or machines that remote agents cannot access (for example, ACE-Step weights on the Mac).
6. Update `docs/PROJECT_STATUS.md` if any system's status changed.

## 3. Branches and pull requests

- `main` is the stable integration branch. Nobody commits to it directly, and agents never merge into it automatically. The human owner reviews and merges.
- Each workstream has its own branch: gameplay, environments, audio, clinical, QA. Name it `<agent>/<workstream>-<topic>`, for example `claude/audio-production` or `codex/clinical-ehr`. If the harness assigns a branch name, use it and record it in the handoff.
- When taking over from another agent, prefer a **continuation branch** created from the latest pushed checkpoint, for example `codex/audio-production-cont`. Open a PR from it or into the original branch.
- Never force-push, rebase or amend commits another agent has already pushed. Merge commits are fine.
- If a branch's PR has already been merged, start follow-up work from the latest `main` as a new change, and open a new PR for it.
- Do not have two agents editing the same file in parallel without an agreed integration plan. Check the ownership table in `docs/PROJECT_STATUS.md` and record any claim there.
- Every PR needs: a summary, the tests that were run with their results, any known limitations, and links to the handoff.

## 4. Godot 4.7 and code conventions

- Use the Godot **4.7 stable** standard build. Engine version and CI move together (`.github/workflows/godot-validation.yml`, `tests/qa/run.py`).
- GDScript is statically typed (`var x: int`, `func f() -> void`). Indent with tabs. Every script starts with a `##` doc header explaining its role. Match the style of the surrounding code.
- Systems communicate **only through `EventBus` signals**. Signal names are in the past tense ("something happened"), and payloads are plain types or Dictionaries.
- Persistent facts live in `GameState`. Game rules live in `systems/`. Autoloads are registered in `project.godot`.
- Clinical and story content is data (JSON under `data/`), never hard-coded. IDs are stable and never reused for different content.
- Commit Godot `.import` and `.uid` files. Never commit `.godot/`.
- Python tools use only the standard library when they run in CI. Generator tools can have dependencies, but those must be pinned in a `requirements.txt` beside them.

## 5. Tests (run before every push)

```sh
python3 tests/qa/run.py --godot /Applications/Godot.app/Contents/MacOS/Godot   # Mac
python3 tests/qa/run.py --godot /path/to/Godot_v4.7-stable_linux.x86_64      # Linux
```

The runner fails on non-zero exit codes, on `ERROR:`/`SCRIPT ERROR:`/`FAIL` lines, and when a completion marker is missing. It covers JSON content, the audio manifest, the music pipeline (against a mock server), the pharmacology scenarios, the QA scene, the boot smoke test, the audio tests and the Chapter 1 audio sequence. When you add a scene, add an explicit smoke test for it. Never skip, disable or weaken a test to get green. See `docs/TESTING.md`.

## 6. Asset standards

- **Formats:** OGG Vorbis at 48 kHz for game audio. Store masters as WAV or FLAC under `audio/masters/` (Git LFS). Keep source art and Blender files under their own workstream folders.
- **Naming:** `amb_*`, `sfx_*`, `mus_*`, `mus_ai_*`. Dialogue clips are named `<line_id>.ogg`, using the stable IDs from `data/narrative`.
- **Manifest:** every audio file has an entry in `audio/manifest.json` (or, for AI music, `audio/music_ai/manifest.json`). The entry records the file, IDs, source or generation method with seed and settings, license, location, duration, integration status and review status. Regenerate the manifests with the tools; do not hand-edit measured fields.
- **Git LFS:** `.gitattributes` routes large binaries through LFS. Small OGG effects and dialogue clips stay in plain Git.
- **Licenses:** only use assets whose license allows game distribution. Never clone a real person's voice without written permission. Any AI-generated asset must keep its prompt, seed, model and version.
- **Honesty:** never claim an asset was generated, tested or approved unless the file exists and the check actually ran. Listening approval is recorded by a human.
- Do not modify Blender environment assets, or another workstream's assets, from an unrelated branch.

## 7. Clinical governance

- The executive producer is a psychiatrist and approves all clinical rules. Clinical content stays `clinical_review_status: "PENDING"` until approved. Builds presented as medically validated must not activate PENDING rules.
- Never invent clinical doses, prescribing rules or textbook passages. Never copy copyrighted reference text.
- Patients are fictional, with no real PII.
- Story anomalies (Ward Zero) must be triggered by explicit narrative events. They must never be presented as automatic signs of psychiatric illness, and the bleed or Objectivity state alone must not start anomaly audio or visuals.
- Do not use audio-only clues or effect-only clues. Every clue needs an equivalent transcript or corroborating route. Accessibility toggles must work independently.
- Keep objective evidence canonical. Distortion effects are reversible and must never corrupt dosage or lab values.

## 8. Commits

Write commit messages in the imperative mood, with a short summary line and a body explaining why. Keep each commit focused on one logical change. Follow any attribution trailer that your agent's harness requires.
