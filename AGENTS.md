# AGENTS.md: shared rules for every AI agent

This file is the single source of rules for **all** agents working on The Forensic Ward: Claude Code, OpenAI Codex and any other assistant. `CLAUDE.md` only points here. If you find a rule elsewhere that contradicts this file, stop, follow the stricter rule, and record the conflict in `docs/AI_HANDOFF.md` for the owner to settle.

Agents alternate on this project, usually when one service reaches its usage limit. You are not required to finish a task before you hand it over. You **are** required to leave the repository in a state the next agent can resume exactly, from GitHub alone.

## 1. Read before you work

Every session, before editing anything:

1. `git fetch origin --prune` and list remote branches (`git branch -r`) and open pull requests.
2. Read, in this order:
   - `AGENTS.md` (this file)
   - `docs/PROJECT_STATUS.md`: what is completed, active, blocked and untested
   - `docs/AI_HANDOFF.md`: the latest handoff entry and the active workstream table
   - the pull request(s) for the branch you will touch, including review comments
3. Compare the handoff entry with GitHub. The branch tip SHA in the entry must exist on `origin`. If the branch has moved past it, read `git log <recorded-sha>..origin/<branch>` to see what the other agent committed since. If it is behind or missing, treat the entry as stale and say so in your next handoff entry.
4. Continue from the latest **verified** commit on GitHub. Never assume work described in a chat, a summary or a local folder exists unless you can see the commit.

Project design sources, which the rules below do not replace:

- `docs/design/The_Forensic_Ward_Master_GDD_v0.1.docx` (locked design) and `docs/design/Claude_Engineering_Handoff_v0.1.md` (engineering contract). These live on `claude/sprint-01-foundation` until PR #1 merges.
- `docs/TESTING.md` (QA runner and CI), `docs/PHARMACOLOGY_ENGINE.md`, `docs/AUDIO_MANIFEST.md`, `docs/clinical_review_log.md` (on the foundation branch).

## 2. Engine and code conventions

- **Godot 4.7 stable, standard build (not .NET).** `project.godot` declares `config/features=PackedStringArray("4.7", "Forward Plus")`. CI and `tests/qa/run.py` refuse any other version. Change the engine version only in one deliberate PR that updates `project.godot`, CI and the runner together.
- **Language:** GDScript only. Use static typing (`var x: int`, typed function signatures and returns) as the existing code does. Tabs for indentation, `snake_case` for functions and variables, `PascalCase` for classes, nodes and scene files, `UPPER_SNAKE_CASE` for constants.
- **Renderer:** Forward+ is the target (Metal on Apple Silicon). Do not rely on features that only work in Forward+ without a fallback. Screenshots from a headless or Compatibility-renderer container are not evidence of how it looks on the Mac.
- **Platform:** macOS first, keyboard and mouse. Core gameplay runs offline with no paid inference or network services.
- **Architecture** (GDD §15 and the engineering handoff):
  - Systems communicate through `EventBus` signals and never call each other's internals.
  - Authored content (clinical, story, dialogue) is JSON in `data/`, validated at load, read-only at runtime. Never hard-code it.
  - Clinical rules and narrative triggers are separate. A clinical rule never unlocks a story clue directly; story systems subscribe to events.
  - Every piece of mutable state is saved and reloaded; repeated events are de-duplicated by event id.
  - Same seed and same inputs give the same state.
- **Two project layouts currently coexist.** `main` uses `autoload/`, `systems/` and `tests/`; `claude/sprint-01-foundation` (PR #1) moved to `scripts/autoload/`, `scripts/tests/` and staged the pharmacology engine. Work in the layout of the branch you are on and do not invent a third. Merging PR #1 needs the integration plan in `docs/PROJECT_STATUS.md`; until it is agreed, do not move or rename files between the two layouts.
- Keep `.uid` files that Godot generates next to scripts and commit them with the script. Never commit `.godot/`, `.import/`, `/build/`, `/export/` or local virtual environments (see `.gitignore`).
- No pseudocode or stubs in files described as runnable. A placeholder must say it is one, in the code and in the handoff.

## 3. Branches, commits and pull requests

- **`main` is the stable integration branch.** Only the project owner merges into it. Agents never push to `main`, never merge pull requests, and never enable auto-merge.
- One workstream per branch. Prefix with the agent that created it:
  - `claude/<workstream>` or `codex/<workstream>`, for example `claude/audio-production`, `claude/environment-production`, `codex/sprint-01-tests`.
  - Workstreams in use: gameplay, environments, audio, clinical systems, QA, docs/tooling.
- **Handing work to the other agent:** prefer a new continuation branch from the last pushed checkpoint, named `<agent>/<workstream>-cont-<n>` (for example `codex/audio-production-cont-1` based on the tip of `claude/audio-production`). Open its PR against the original branch, or against `main` if the original has merged. You may commit directly on the other agent's branch only when its latest handoff entry says it is free to continue there.
- **Never force-push, rebase, amend or otherwise rewrite commits another agent or person pushed.** `git push --force-with-lease` is allowed only on a branch you created whose history nobody else has built on. Prefer `git merge origin/main` over rebasing a shared branch.
- Never silently discard someone else's change. If you must revert, use `git revert` and explain why in the commit message and the handoff.
- **Shared files:** do not edit a file another active workstream has claimed in `docs/AI_HANDOFF.md` (Active workstreams table) unless that table records an agreed integration plan. `project.godot`, `autoload/EventBus.gd`, `scenes/main/Main.*`, `.github/workflows/*`, `tests/qa/run.py` and `README.md` are high-conflict files: keep edits small and mention them in your handoff.
- Commit early at coherent checkpoints, with an imperative subject line (`Add secure door SFX`). Label unfinished work in the subject: `WIP: Add EHR view (record list only, no filters)`. A WIP commit must still import in Godot without parse errors, or the handoff must say exactly which file is broken and why.
- Pull requests: open as **draft**, target `main` unless stated otherwise, describe what changed, how it was tested and what remains. Mark ready only when the test commands below pass on the PR's head commit. Review and test changes before anyone merges them.

## 4. Tests

Run the tests for the branch you are on before every handoff and every PR, and record the exact result (command, commit SHA, pass/fail counts) in `docs/AI_HANDOFF.md`.

On `main` and branches based on it (CI runs this on every PR to `main`):

```sh
python3 tests/qa/run.py --godot /path/to/Godot      # or GODOT=/path/to/Godot python3 tests/qa/run.py
```

On macOS the Godot path is `/Applications/Godot.app/Contents/MacOS/Godot`. In a Linux container, download `Godot_v4.7-stable_linux.x86_64.zip` from the official 4.7-stable release and verify it against `SHA512-SUMS.txt`, as `.github/workflows/godot-validation.yml` does.

On `claude/sprint-01-foundation` (PR #1, which predates the CI runner):

```sh
godot --headless --path . --editor --import
godot --headless --path . res://scripts/tests/TestRunner.tscn        # exit code 0 = all passed
```

Rules:

- Never skip, disable or delete a test to get green. `docs/TESTING.md` lists intended `SKIP`s; replace them with real tests when the real code exists, never with substitute implementations.
- Distinguish **executed** results from **static inspection**. Say "not run" when you could not run something.
- Headless checks do not validate lighting, animation, input feel, audio mix or clinical correctness. Those stay "untested on Mac" in `docs/PROJECT_STATUS.md` until the owner confirms them.
- A CI result counts only after you see the hosted run on GitHub.

## 5. Asset standards

- **Provenance for every asset.** Record source, tool and settings or seed, licence, and review status. Audio uses `audio/manifest.json`, which regenerates `docs/AUDIO_MANIFEST.md` via `tools/audio/build_manifest.py`; `tests/qa/test_audio_manifest.py` checks it. Never edit the generated markdown by hand. Environment and art assets need an equivalent manifest on their branch.
- **Licences:** use only original work, procedural generation, or tools and models whose licence permits commercial use, and record the licence. No third-party samples, textures or models without a verified licence. No voices cloned from real people. No proprietary textbook text in any distributable asset (GDD §8).
- **Formats:** Godot imports `.glb` for 3D (keep the `.blend` source committed next to it, or say where it lives), `.ogg` for in-game audio, `.png` for textures. Line endings are LF (`.gitattributes`).
- **Large files:** audio masters (`audio/masters/**`), AI-generated score (`audio/music_ai/**/*.ogg`) and `*.flac` go through Git LFS. Run `git lfs install` before committing them. Ask before adding a new LFS pattern for large art files so CI checkout stays in sync.
- **Local-only dependencies** never get committed and must be listed in the handoff: model weights (`tools/audio/models/`, Kokoro ONNX), ACE-Step checkouts, Stable Audio, `.venv-*`, Blender installs, anything needing a GPU or the owner's Mac. Generation tools must be reproducible from the scripts and pinned requirements (`tools/audio/requirements.txt`).
- Greybox and placeholder assets must be labelled as such in their name or manifest entry.

## 6. Clinical governance

The executive producer is a psychiatrist and approves every clinical rule. The game is a fictional simulator, not patient-care software.

- Every clinical rule needs an `id`, `source`, review date, clinician approval, confidence and test examples (GDD §8). Rules carry `review_status` (clinical rules) and content carries `clinical_review_status` (dialogue, observations); only `APPROVED` may apply as medical logic.
- Unapproved rules (`PENDING_PSYCHIATRIST_REVIEW` and similar) never run in a build presented as medically validated (`forensic_ward/clinical/build_mode="validated"`, defined on the foundation branch). In `prototype` mode they may apply only their `non_medical_effects`, and each application emits `clinical_review_flagged`. `ClinicalRules` never applies `medical_effects` of an unapproved rule.
- Never invent doses, thresholds or clinical facts. Never copy textbook passages; write original summaries with the source cited.
- Never quietly turn a story clue into a psychosis symptom, or the reverse. Source facts and the physician's belief stay separate: observations keep author, timestamp, provenance, reliability and `verified`.
- Record each approval or pending item in `docs/clinical_review_log.md` with date, location, decision and reviewer. An agent may never mark anything approved on its own judgement; only the owner's explicit approval counts, and the log says where it was given.
- All patient data is fictional.

## 7. Handoff protocol

### Before you stop, or when you are near a usage limit

Do these in order. If you run out of room, the earlier steps matter most.

1. Save every file. Export any generated assets (`.glb`, `.ogg`) your scripts produce, or say in the handoff that they are not exported.
2. Run the tests in section 4 and note the exact output counts.
3. Commit unfinished but coherent work to the active feature branch, labelled `WIP:` where needed, and `git push -u origin <branch>`.
4. Confirm the push: `git ls-remote origin <branch>` must print the SHA you are about to record.
5. Add a new entry at the top of the log in `docs/AI_HANDOFF.md` using its template, and update the Active workstreams table. Update `docs/PROJECT_STATUS.md` if a system changed state. Commit and push those doc changes too, then put the final SHA in your summary to the owner.
6. Never describe uncommitted or unpushed local changes as available on GitHub. If something exists only on a local machine or in a container that will be discarded, say exactly that and where.

The entry must let the next agent resume without asking anyone: branch, verified commit, files modified, unfinished functions and what they still need, known errors with their messages, test results, dependencies that remote agents cannot reach, and numbered next steps with file paths. Never write only "continue development".

### When you resume after the other agent

1. Do section 1 in full.
2. Confirm which of the other agent's changes are committed, which are in open PRs and which have merged (`git log`, `git branch -r --contains <sha>`, the PR list).
3. Run the tests on the commit you are starting from and compare with the recorded results. Report any difference before building on it.
4. Continue from that commit, ideally on a continuation branch (section 3). Do not overwrite or revert the other agent's work without recording why.

## 8. Tool-specific notes

- **Claude Code** reads `CLAUDE.md`, which points here. Cloud sessions run in a disposable container: anything not pushed is lost.
- **Codex** reads `AGENTS.md` directly. Codex's PR review can be requested with the comment in `docs/TESTING.md`; it must not merge.
- Agent-specific instructions go in that agent's own file and may only add detail. They may not loosen any rule here.

## 9. Continuous checkpoints — Codex and Claude (owner instruction, 2026-10-17)

These requirements apply equally to **OpenAI Codex and Claude Code**, including future sessions. They supplement every rule above and the continuity protocol in `CLAUDE.md`; they do not replace existing instructions.

- Update `docs/AI_SESSION_HANDOFF.md` and `docs/AI_PROGRESS_TRACKER.md` immediately on starting/resuming a session, after every meaningful implementation milestone or major test/failure, before a large task or PR update, at any context/usage warning, and before stopping. Update verified status in `docs/PROJECT_STATUS.md` and append a new `docs/AI_HANDOFF.md` entry when checkpointing; never rewrite its historical entries.
- Never finish more than one substantial implementation task without a handoff update. Checkpoint regularly even when no usage warning is visible. A recoverable handoff takes precedence over new work when capacity is uncertain.
- Record the current objective and exact stopping point, branch and latest verified remote SHA, related PRs/owners, changed and uncommitted files, executed versus pending/failed tests, outstanding clinical/creative approvals, missing resources, blockers, and the next exact command or implementation step. Do not label untested work complete.
- Commit and push coherent checkpoints on a dedicated feature branch; verify the remote SHA with `git ls-remote` before claiming GitHub persistence. Never push main, auto-merge, rewrite someone else's commits, or include credentials/temporary/macOS metadata. If push fails, preserve local work and provide the complete handoff in the final response.
- At a context/usage warning, stop starting tasks, save work, update the handoff, commit/push if possible, verify it and provide a continuation summary. Before voluntarily ending, use the **CODEX SESSION HANDOFF** fields requested by the owner: workstream, last milestone, branch/verified SHA, PR, files, tests passed/failing, approvals, blockers, exact next task, handoff location and push verification. The same underlying information is required for Claude.
