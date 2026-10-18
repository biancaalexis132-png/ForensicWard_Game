# AI session handoff

Current state for the next Claude session, required by the session continuity protocol in `CLAUDE.md`. The shared agent log (Codex and Claude) stays in `docs/AI_HANDOFF.md`; task states are in `docs/AI_PROGRESS_TRACKER.md`.

**Last updated:** 2026-10-18 01:40 UTC (F3 finished, draft PR being opened)

## Current objective

F3 from `docs/F0_FOUNDATION_AUDIT.md` §7–§8: the anomaly evidence model and the rule that keeps clinical events and supernatural events apart, with the feature flag off so Chapter 1 plays as today. Implementation is finished; it waits on the owner's review.

## Branch, commit, PRs

- Branch `claude/f3-anomaly-model`, based on `main` at `9558c77` (F2 merged as PR #26). Latest verified code commit `5283735`.
- Draft PR from `claude/f3-anomaly-model` to `main`, assigned to the owner. Find it with `gh api repos/biancaalexis132-png/ForensicWard_Game/pulls?head=biancaalexis132-png:claude/f3-anomaly-model`.

## Completed work and findings

- `data/anomalies.json`: three Chapter 1 episodes, cap `reported`.
- `scripts/narrative/AnomalyLedger.gd` in `Main`; flag `forensic_ward/narrative/anomaly_enabled = false`.
- Validator separation rules, clue `source_class` and `claim_state`, StoryLogic `zone` and `world_state` conditions, two EventBus signals.
- Finding: the ledger enabled, disabled or removed gives identical game state for the same Chapter 1 run, apart from its own `anomaly` section.

## Exact stopping point

All F3 work is committed and pushed. Nothing is uncommitted. The draft PR is open and subscribed for CI and review events.

## Tests

- `TestRunner.tscn`: 127 passed, 0 failed (15 new in `test_anomaly.gd`).
- `tests/qa/run.py`: all executed checks passed.
- CI on the PR: watch the first run.

## Failures and blockers

- None in F3. Merge is the owner's call.

## Pending user approvals

- F3 PR review and merge.
- F0 §9 list: C2, C3, C4, C7 (pharmacology clue gates, reported as known exceptions at boot), C11, the precise supernatural mechanism.
- Optional: `.gdignore` for `assets/creative_references/`.

## Next steps for a new session

1. Read this file, `docs/AI_PROGRESS_TRACKER.md` and the newest `docs/AI_HANDOFF.md` entry.
2. Check the F3 PR state and CI; fix any CI failure on the branch.
3. After the owner merges F3, remove the F3 row from the Active workstreams table and start the next item in F0 §8 "Later" only when the owner asks.

## Creative and clinical constraints

- Hospital: Ashcroft State Forensic Hospital. Ward Zero holds a genuine supernatural phenomenon, introduced gradually; Chapter 1 stays ambiguous.
- Psychiatric symptoms, diagnoses, medication, rapport and the physician's strain never count as evidence of the supernatural, and anomaly events never change clinical state. Psychosomatic Bleed is presentation only (owner, 2026-10-17).
- No unapproved clinical treatment effects. Never merge PRs; never commit `._*` files.
