# AI progress tracker

Permanent checklist across sessions (`CLAUDE.md` continuity protocol §3). Each item lists related paths · dependencies · validation · next action. Move items between sections; do not delete finished ones. Detailed per-system status stays in `docs/PROJECT_STATUS.md`.

_Last updated: 2026-10-17 22:05 UTC (visual direction review session)._

## Completed

- **Session handoff system** · `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md` · deps: `CLAUDE.md` protocol (PR #25) · validation: on branch `claude/visual-direction-review` · next: keep current every session.
- **Character and Ward Zero visual production review** · `docs/design/VISUAL_PRODUCTION_REVIEW.md`; inputs `assets/creative_references/Visual_References/**` · deps: PR #24, #25 (merged) · validation: draft PR open, docs only, Godot QA not run (no code changed) · next: owner approval.

## In progress

- none

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
