# CLAUDE.md

Claude Code follows the shared multi-agent rules in **[AGENTS.md](AGENTS.md)**. They cover how to resume and hand off work, branch and PR policy, Godot 4.7 conventions, test commands, asset standards and clinical governance. If anything here appears to conflict with AGENTS.md, AGENTS.md wins.

At the start of every session, read `AGENTS.md`, `docs/PROJECT_STATUS.md` and `docs/AI_HANDOFF.md`, and check the open pull requests. Before you stop, update `docs/AI_HANDOFF.md` as section 2 of AGENTS.md describes.

Claude-specific notes (these add to AGENTS.md and do not change it):

- If the session harness assigns a development branch, work and push there, and record the branch name in the handoff.
- Cloud sessions cannot reach Hugging Face or ModelScope, and have no GPU. Anything that needs model weights downloaded from those sites, such as ACE-Step, must be prepared as scripts and run on the owner's Mac. See `docs/MUSIC_AI_MAC_GUIDE.md`.
