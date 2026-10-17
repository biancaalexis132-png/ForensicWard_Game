# AI progress tracker

Permanent checklist across sessions (`CLAUDE.md` continuity protocol §3). Each item lists related paths · dependencies · validation · next action. Move items between sections; do not delete finished ones. Detailed per-system status stays in `docs/PROJECT_STATUS.md`.

_Last updated: 2026-10-17 · Codex protagonist foundation continuation._

## Completed

- **Session handoff system** · `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md` · deps: `CLAUDE.md` protocol (PR #25) · validation: merged in PR #28 · next: keep current every session.
- **Character and Ward Zero visual production review** · `docs/design/VISUAL_PRODUCTION_REVIEW.md`; inputs `assets/creative_references/Visual_References/**` · deps: PR #24, #25 (merged) · validation: merged in PR #28; recommendations still proposals; current main baseline QA passed · next: owner approval.

## In progress

- **Protagonist customization proposal / reconciliation** · `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, status/handoff docs · deps: owner handoff; F1/F2 already merged · validation: baseline full QA passed on `fb07887` · next: owner review of plan, no creator implementation yet.
- **Independent save-compatibility regression coverage** · new `scripts/tests/test_save_compatibility.gd` · deps: existing public SaveManager contracts · validation: development full QA running · next: complete checks and push a draft-review branch.

## Pending (not started, waiting on approval)

- **Approve character canon sheets and decisions D1–D9** · review §2 and "Open decisions" · deps: owner · next: owner comments on the draft PR or in the thread.
- **V1: mark ensemble and concept boards superseded** · `assets/creative_references/Visual_References/{Individual_Characters,Concept_Boards}/` · deps: D8 · next: small docs PR.
- **V2: `docs/design/CHARACTER_VISUAL_CANON.md`** · deps: D1–D3 · next: write from review §2.
- **V3: neutral mannequin stand-in replacing the capsule** · `scenes/props/Character.tscn` · deps: approval · validation: `test_world.gd` · next: keep node paths and collision.
- **V4–V8: Ward Zero kit, props, rooms W1–W8, trim sheets, playable zone** · `tools/blender/build_stage6_*.py`, `assets/exports/wardzero/**` (proposed) · deps: approval, the environment thread's Stage 6 PR, F2 zones · next: review that PR first.
- **V9: first anomaly `anom_clock_offset`** · deps: F3 anomaly model · validation: determinism test plus a test that clinical state cannot trigger it.
- **V10: first character model (Bennett)** · deps: approved canon and regenerated references.
- **Ward Zero audio pass** (room tones, phenomenon signature, re-cue `w0_knocking_heard`) · `audio/cues.json` · deps: audio workstream.
- **Performance budget and low preset** · deps: owner's Mac for profiling.

## Blocked

- **Environment Stage 6 (Ward Zero)** · environment thread · blocked on owner approval of plans; this review feeds it.
- **Rahman content and voice direction** · `data/staff.json`, `audio/voice_profiles.json` · blocked on D1 (F0 C4).

## Verified corrections / coordination

F0 PR #20, F1 #21, F2 #26 and review #28 are merged on `fb07887`; stale historical handoff text remains as history. Current PR list and hosted CI cannot be verified because GitHub API access returns Forbidden. Preserve historical audio/Stage 6 workstream ownership until verified. The owner’s current protagonist decisions are recorded in GDD amendments; visual D1–D9 and full F3 remain undecided. Private v1.1 package is not available in this environment.
