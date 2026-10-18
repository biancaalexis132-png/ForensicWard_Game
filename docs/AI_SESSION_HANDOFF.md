# AI session handoff

Current state for the next Claude session, required by the session continuity protocol in `CLAUDE.md`. The shared agent log (Codex and Claude) stays in `docs/AI_HANDOFF.md`; task states are in `docs/AI_PROGRESS_TRACKER.md`.

**Last updated:** 2026-10-17 21:20 UTC (session start, F3)

## Current objective

F3 from `docs/F0_FOUNDATION_AUDIT.md` §7–§8: the anomaly evidence model and the rule that keeps clinical events and supernatural events apart, with the feature flag off so Chapter 1 plays as today.

## Branch, commit, PRs

- Branch `claude/f3-anomaly-model`, based on `main` at `9558c77` (F2 merged as PR #26).
- No F3 PR yet.

## Exact stopping point

Session start: continuity docs created, implementation not begun.

## Next steps

1. `data/anomalies.json` with the three Chapter 1 episodes, capped at `reported`.
2. `source_class` and `claim_state` on clues; validator separation rules; C7 known-exception warnings.
3. `AnomalyLedger` node in `Main`, flag `forensic_ward/narrative/anomaly_enabled = false`.
4. `scripts/tests/test_anomaly.gd`, full `tests/qa/run.py`, draft PR.

## Pending user approvals

- Psychosomatic Bleed (F0 C6): asked on a decision card; F3 is built on "presentation only".
- F0 §9 list: C2, C3, C4, C7, C11, the precise supernatural mechanism.

## Creative and clinical constraints

- Hospital: Ashcroft State Forensic Hospital. Ward Zero holds a genuine supernatural phenomenon, introduced gradually; Chapter 1 stays ambiguous.
- Psychiatric symptoms, diagnoses, medication, rapport and the physician's strain never count as evidence of the supernatural, and anomaly events never change clinical state.
- No unapproved clinical treatment effects. Never merge PRs; never commit `._*` files.
