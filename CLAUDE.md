# CLAUDE.md

**Read `AGENTS.md` first and follow it.** It holds every shared rule for this project: Godot 4.7 conventions, branch policy, tests, asset standards, clinical governance and the handoff protocol. Claude and Codex follow the same file, so do not copy rules here. If anything below seems to conflict with `AGENTS.md`, `AGENTS.md` wins; record the conflict in `docs/AI_HANDOFF.md`.

At the start of every session, after `git fetch origin --prune`, read `docs/PROJECT_STATUS.md` and the newest entry in `docs/AI_HANDOFF.md`.

## Claude Code specifics

These add detail only; they do not change any rule in `AGENTS.md`.

- Cloud sessions run in a disposable container. Anything not pushed to GitHub is lost when the session ends, so follow `AGENTS.md` §7 before you stop, and push at every coherent checkpoint.
- Branches you create start with `claude/`. Open pull requests as drafts and leave merging to the owner.
- To run the tests in a Linux container, download Godot 4.7 stable for Linux and verify its SHA-512 the same way `.github/workflows/godot-validation.yml` does, then run the commands in `AGENTS.md` §4.
- Several Claude sessions may run at once on different workstreams. Check the Active workstreams table in `docs/AI_HANDOFF.md` before editing a file another session has claimed.
