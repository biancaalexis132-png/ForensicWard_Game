# Copilot / Claude — CP-001 v2 integration handoff

**Owner approvals:** Longitudinal recurring postgame clinical cases with optional new referrals; hybrid shifts; CP-001 specifically focuses on established historical schizophrenia with potentially co-occurring mood/anxiety symptoms and recovery across five encounters. Do not convert this into permission to implement diagnostic, safety, legal or medication rules.

**Source:** This v2 package is based on `docs/design/continuing_practice/CP001_Jordan_Vale_v1` authored previously. Preserve v1 and compare versioned changes. No original existing campaign patient or Elias Ward case is modified.

**Preflight:** Read `AGENTS.md`, `CLAUDE.md`, current handoffs, PR #34, case v1, existing patient schema, `PatientManager`, `SaveManager`, EHR and Chapter 5 ending proposals. Verify identifiers and avoid ownership collisions with Naomi 3D/Hospital Life branches.

**Required steps:** (1) documentation-only PR to review v2 and clinical gaps; (2) approved case-content schema and immutable references; (3) shared v3→v4 migration proposal coordinated with protagonist, finale and postgame; (4) deterministic test-first case lifecycle; (5) only after clinical review, voiced playable dialogue; (6) accessible fallback and performance validation.

**Tests:** v1/v2/v3 migration fixtures; endings A/B/C and all profiles; optional acceptance and repeat visits; replay and idempotence; source provenance and consent; save/load per encounter; respect unresolved tasks; no orders without approved content; no automatic recovery score; case remains ongoing after completed five-encounter arc.

**Mandatory handoff:** Before substantive coding, after every milestone and before usage/context limits, commit and push verified work with updates to `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, and other required documents. Never merge automatically. Report branch, commit SHA, tests, PR and exact next task.
