# AI session handoff (living document)

Updated 2026-10-17 · Codex · protagonist foundation continuation.

## Objective and repository state

Continue existing foundations; reconcile merged state, propose protagonist customization, and add independent save-compatibility tests. No creator, personality scoring, clinical logic or visual production implementation is authorized by this proposal.

- Branch: `codex/protagonist-foundation-cont-1`, based on verified `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125` (PR #28 merge).
- F0/F1/F2 and visual review are merged. Review recommendations remain proposals.
- Git fetch and read-only remote checks work. GitHub REST and GraphQL PR listing return Forbidden; current open PRs and hosted CI are unverified. Historical handoff mentions soundtrack PR #27 and a Stage 6 environment thread; preserve their ownership until checked.
- Claimed: this document, progress/status reconciliation, append-only handoff entry, `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, new `scripts/tests/test_save_compatibility.gd` and its UID. No changes to environment/audio/visual workstream files.

## Completed milestone

Inspected repository rules, current merge history, campaign, zone/save architecture, visual review and available source guides. Installed official Godot 4.7 standard outside checkout with SHA-512 verification. System `godot` is 4.6.3 and must not be used here.

## Validation in progress

Baseline: `/workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64` via `python3 tests/qa/run.py --godot <path>`. Python 6+3+3 passed, pharmacology passed, QA 19/0/0, GLB 138/138, TestRunner 112/0, boot OK, audio 271/0. Final Chapter 1 sequence completed at 61.8s; full runner exit 0. Log: `/tmp/forensic-ward-qa.log` (local only). Baseline full-suite completion is verified.

## Remaining tasks

1. Baseline complete; development full QA running (new save tests passed: TestRunner 116/0).
2. Save reconciliation report and phased protagonist proposal; record explicit owner decisions on fixed psychiatrist role, moderate personal life, emergent personality.
3. Add bounded save-compatibility tests only; run QA.
4. Commit, push feature branch, verify remote SHA, attempt draft PR through available authentication. Record failures honestly.

## Dependencies and unresolved approvals

Private v1.1 design-bible upload is unavailable in this environment and absent from repository; do not recreate it. Mac rendering/performance/input/listening and optional Blender/audio generation tools remain unvalidated.

D1–D9 in visual review remain unresolved. F0 C2 (Concordance/titles), C6 (Bleed), C7 (pharmacology clue gates), C11 (unused original music export) and precise anomaly mechanism remain open. Protagonist professional role is fixed psychiatrist per owner handoff; on-screen title/voice wording still needs review. No pending clinical rule is activated. Stage 6, audio, models, casting and anomaly runtime are outside this workstream.

## Resume

Read AGENTS.md, CLAUDE.md, current status/progress and latest append-only handoff. Fetch origin and inspect actual PR state if access permits. Continue the first incomplete task above, preserving other workstreams. Do not merge or push main.

## Proposal and regression milestone

Reconciliation and approved protagonist requirements are recorded; proposal is complete for owner review. Four new save-contract tests passed (TestRunner now 116/0), including public on-disk rejection with unchanged providers/seed/events and provider compatibility with real v1/v2 fixtures. Full development audio checks remain running. `api.github.com` is absent from runtime allowlist and direct CONNECT is denied (403); additive domain requirement saved in environment draft. Saving does not apply networking or publish.
