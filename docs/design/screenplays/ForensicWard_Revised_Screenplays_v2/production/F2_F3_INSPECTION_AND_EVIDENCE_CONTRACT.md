# PROPOSED F2/F3 Contract — Ward Zero Inspection, Safe Return, Rollback, Independent Evidence
**Engineering design proposal, NOT code, NOT approved supernatural mechanics.** Requested in response to Codex comparison finding: F2 has no inspection-specific rollback contract, and current verification logs do not establish source independence.

## 1. Scene and reveal boundaries
Chapter 2: audit/log and door discrepancy, no Ward Zero entry.
Chapter 3: owner-approved first escorted Ward Zero entry, **ambiguous** route concern, regular return, nonindependent/uncertain preliminary measurements; never assert proven loop.
Chapter 4: existing major corridor-loop reveal remains in Chapter 4 Scene 09, subject to explicit owner approval of effect, F2 safety tests and independent-evidence standard.

## 2. Inspection lifecycle (proposed state machine)
`UNREQUESTED → APPROVED → PREFLIGHT_PASSED → IN_PROGRESS → PAUSED → RETURNING → RETURNED → CLOSED`.
Any unsafe or failed step goes to `ABORT_REQUESTED → ROLLBACK_PENDING → RETURNED_SAFE → CLOSED`; if an automatic rollback fails, use a noninteractive safe-location recovery scene and record the failed test (no softlock).

**Preflight gates:** signed authorization + hazard assessment, escorts/roster, communications check, verified fallback exit, clinical coverage, access-scope declaration, game save/checkpoint BEFORE transition. No separate player exploration beyond marked route.

**Stop conditions:** radio loss, missing escort, failed route reconciliation, unsafe building condition, invalid scene transition, load timeout, or player choosing to exit. Any stop disables subsequent anomaly mutation and resolves to the safe-return path.

**Postconditions:** player plus escort returned to authorized modern-zone marker; zone loader stable; interactions restored; clinical saves untouched; evidence held only if witnessed and recorded; no duplicated time events, doors or staff; checkpoint can reload. Prove both forward and abort states.

## 3. Safe-return and rollback semantics
- Capture a narrowly scoped *inspection snapshot*: loaded zone IDs, portal IDs, player position/rotation, escort IDs/positions, interactive door state, sequence step and temporary anomaly transforms.
- Keep authoritative campaign/clinical state separate; rollback only transient inspection/zone effects, not patient notes or valid source records.
- Require one known-good modern-zone spawn and a second noninteractive rescue fallback. Exit always works after one bounded attempt; no endless corridor generation.
- All transitions idempotent; retry after interruption must not duplicate evidence, increment chapter beat twice, or strand escort.
- On app crash/reload midinspection, restore to the last safe checkpoint in operational zone with a readable notice that the inspection was interrupted; don't silently claim an event was observed.
- Do not mutate original evidence when rolling back the scene. Record explicit provenance for completed observation only.

## 4. Evidence independence model
A *source* is independently acquired only if its raw capture, sensor/time authority, custody and transformation steps are described and separable. Two exports of the same event bus, two copies of one image, or separate UI views using the same serialized data **do not count** as independent corroboration.

Proposed fields: `evidence_id`, `chapter`, `scene`, `observed_at_raw`, `timezone_or_clock_source`, `observer_or_instrument`, `capture_pipeline`, `raw_asset_digest`, `chain_of_custody`, `derived_from`, `validation_method`, `scope`, `confidence`, `alternative_hypotheses`, `clinical_record_link = none`.

Evidence statuses: `reported`, `verified_source`, `corroborated_independent`, `disputed`, `unresolved`, `refuted`; require gate before promotion. Avoid misusing a single Boolean `verified` as proof of physical impossibility.

**Clinical separation:** no psychiatric symptom, diagnosis, treatment response, stress score or patient suspicion can trigger environmental anomaly or promote anomaly evidence. Mara may supply documents voluntarily, but authorized records verification is independent of her clinical assessment. Preserve privacy and role-based access.

## 5. Acceptance tests Codex should implement BEFORE effects
1. Fresh entry preflight denied for missing authorization, escort, coverage or cleared return route.
2. Normal entry/exit on 8 GB Mac target with save/load, no stuck player or escort.
3. Abort from every inspection step, including after anomaly staged; returns to safe zone within bounded steps.
4. Zone load failure, missing GLB, disconnected drive, timeout and save reload all recover without corrupting campaign/clinical state.
5. Re-enter after abort; no duplicated events, evidence or relationship changes.
6. Anomaly off / unavailable: Chapter 3 progression can complete through ordinary documentation and safe return.
7. Chapter 3 cannot set Chapter 4 major-loop reveal flag; chapter-gate regression check.
8. Two displays sourced from one event stream fail independence test; truly distinct capture pipelines with preserved raw fields can qualify only after validation.
9. All clinical-status changes remain invariant under F3 anomaly execution, failure, rollback and replay.
10. Accessibility: visual/text equivalents for audio cues, reduced-motion safe route, clear signposting and no audio-only evidence.
11. Verify no reliance on FPS-dependent timers for safety transitions; deterministic simulation tests.
12. Profile zone memory, texture use, draw calls and load stalls on Apple Silicon Mac 8 GB RAM before expanding effects.

## 6. Required PR sequence (proposed)
PR-A (docs): screenplay addenda and review labels, superseding no earlier files.
PR-B (tests/architecture): inspection lifecycle and failure-mode contract with mocked zones, no supernatural effect.
PR-C (source-provenance): separate evidence acquisition and independence validation, unit tests.
PR-D (Chapter 3): authorized entry, ambiguous observations, guaranteed safe return, reviewed dialogue.
PR-E (Chapter 4, owner-approved only): bounded major corridor loop, independent corroboration, regression/performance tests.

Before writing runtime code, Codex must cross-reference actual F2 state names and data schemas. This document invents **proposed design names**, not shipped API signatures. No automatic merge. Maintain `AGENTS.md` / `CLAUDE.md` handoffs with pushed milestones and report exact branch/SHA/PR.
