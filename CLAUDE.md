# CLAUDE.md

**Read `AGENTS.md` first and follow it.** It holds every shared rule for this project: Godot 4.7 conventions, branch policy, tests, asset standards, clinical governance and the handoff protocol. Claude and Codex follow the same file, so do not copy rules here. If anything below seems to conflict with `AGENTS.md`, `AGENTS.md` wins; record the conflict in `docs/AI_HANDOFF.md`.

At the start of every session, after `git fetch origin --prune`, read `docs/PROJECT_STATUS.md` and the newest entry in `docs/AI_HANDOFF.md`.

## Claude Code specifics

These add detail only; they do not change any rule in `AGENTS.md`.

- Cloud sessions run in a disposable container. Anything not pushed to GitHub is lost when the session ends, so follow `AGENTS.md` §7 before you stop, and push at every coherent checkpoint.
- Branches you create start with `claude/`. Open pull requests as drafts and leave merging to the owner.
- To run the tests in a Linux container, download Godot 4.7 stable for Linux and verify its SHA-512 the same way `.github/workflows/godot-validation.yml` does, then run the commands in `AGENTS.md` §4.
- Several Claude sessions may run at once on different workstreams. Check the Active workstreams table in `docs/AI_HANDOFF.md` before editing a file another session has claimed.

---

# ASHCROFT SESSION CONTINUITY PROTOCOL

This protocol is mandatory for all Claude Code sessions working on
The Forensic Ward / Ashcroft State Forensic Hospital.

## 1. Start-of-session requirements

Before beginning substantial work:

1. Read this CLAUDE.md file.
2. Read docs/AI_SESSION_HANDOFF.md if it exists.
3. Read docs/AI_PROGRESS_TRACKER.md if it exists.
4. Inspect the current Git branch, commit, working tree, and relevant PRs.
5. Verify the handoff against the actual repository state.
6. Identify the next unfinished task and outstanding approvals.

If either continuity document is missing, create it.

## 2. Persistent session handoff

Maintain docs/AI_SESSION_HANDOFF.md with:

- Current objective
- Active branch, latest commit, and relevant PRs
- Completed work and findings
- Current progress and exact stopping point
- Remaining tasks and their priority
- Technical decisions and dependencies
- Files created or modified
- Tests performed and results
- Failures and blockers
- Pending user approvals
- Exact next steps for a new Claude session
- Creative and clinical constraints
- Last updated timestamp

## 3. Progress tracking

Maintain docs/AI_PROGRESS_TRACKER.md.

Track completed, in-progress, blocked, and pending tasks.

For each task, record its dependencies, relevant paths,
validation status, and next action.

## 4. Mandatory checkpoint frequency

Update the handoff:

- At the beginning of each development session
- After every major task or milestone
- Before large or context-intensive operations
- After significant tests or failures
- Before opening a pull request
- Whenever a context or usage warning appears
- Before voluntarily ending the session

If the remaining context is visible and approximately 25-30%
remains, immediately prioritize updating the handoff.

If usage or context availability cannot be determined,
checkpoint after each major milestone.

Do not wait until the usage limit is reached.

## 5. Safe Git practices

- Work on appropriately scoped feature branches.
- Do not automatically merge PRs.
- Do not overwrite unrelated work.
- Do not commit secrets or temporary files.
- Exclude macOS AppleDouble files beginning with ._
- Preserve existing Godot systems and approved clinical content.
- Commit coherent, reviewed progress at safe checkpoints.
- Never claim that a GitHub push succeeded unless verified.
- Document uncommitted changes before ending a session.

## 6. Required session-ending report

Before ending, provide:

SESSION HANDOFF

- Last completed task:
- Current branch and commit:
- Files created or modified:
- Tests passed:
- Tests failing:
- Pull request status:
- Pending approvals:
- Next exact task:
- Handoff file location:
- GitHub push status:

If GitHub is unavailable, include the complete handoff
in the final response.

## 7. Project-specific boundaries

Hospital: Ashcroft State Forensic Hospital.

Genre: Realistic forensic psychiatry simulation with a
genuine supernatural psychological-thriller mystery.

Ward Zero: Genuine supernatural temporal and spatial anomalies,
introduced gradually.

Never use psychiatric symptoms as proof of supernatural phenomena.

Maintain the five-chapter narrative architecture.

Prioritize shared technical foundations and reusable systems.

Target hardware: Apple Silicon MacBook Air, 8 GB unified memory.

Do not enable unapproved clinical treatment effects.

## 8. Continuity priority

When session capacity appears limited, stop beginning new
implementation tasks and prioritize writing a usable handoff.

A session is not complete until its work can be resumed
from the repository and the continuity documents.

