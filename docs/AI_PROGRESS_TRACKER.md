# AI progress tracker

Permanent checklist across sessions (`CLAUDE.md` continuity protocol §3). Each item lists related paths · dependencies · validation · next action. Move items between sections; do not delete finished ones. Detailed per-system status stays in `docs/PROJECT_STATUS.md`.

_Last updated: 2026-10-17 · Codex protagonist foundation continuation._

## Completed

- **Session handoff system** · `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md` · deps: `CLAUDE.md` protocol (PR #25) · validation: merged in PR #28 · next: keep current every session.
- **Character and Ward Zero visual production review** · `docs/design/VISUAL_PRODUCTION_REVIEW.md`; inputs `assets/creative_references/Visual_References/**` · deps: PR #24, #25 (merged) · validation: merged in PR #28; recommendations still proposals; current main baseline QA passed · next: owner approval.

## Completed this continuation (awaiting review, not merged)

- **Protagonist customization proposal / reconciliation** · `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, status/handoff docs · deps: owner handoff; F1/F2 already merged · validation: baseline full QA passed on `fb07887` · next: P1 authorized by owner “continue”; later phases remain separate scopes.
- **Independent save-compatibility regression coverage** · new `scripts/tests/test_save_compatibility.gd` · deps: existing public SaveManager contracts · validation: full QA exit 0, TestRunner 116/0; pushed `01739ff` · next: create draft PR after GitHub API network access is applied.

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

## Continuation stopping point

Implementation and proposal are pushed; no unexplained QA failures. Draft PR creation is blocked by API CONNECT 403. Prepared PR body is local at `/workspace/protagonist-foundation-pr.md`; full report/resume steps are in `AI_SESSION_HANDOFF.md`. P1 is authorized and implemented on its feature branch; later phases remain separate scopes. No creator or save-version change has been made.

## P1 continuation, 2026-10-17

- **Completed in feature branch:** pure protagonist catalog/creation-draft schema and validation, synthetic fixtures, 15 new tests. Import passed; TestRunner 131 passed / 0 failed. No shipped choices, gameplay hooks or save version change. Paths: `scripts/protagonist/`, `scripts/tests/test_protagonist.gd`, `docs/design/PROTAGONIST_INPUT_CONTRACT.md`.
- **PR #27 conflicts resolved:** original soundtrack branch fast-forward pushed and verified at `412b5010c8ccd8ba0e19e983b4346b5d90482d34`; no agent merge. Full audio validation 334/0 and combined gameplay tests 116/0.
- **Upcoming authorized work:** owner’s pasted character decision approves D1–D3; canon/metadata and regeneration documentation/candidates follow separately. New Chapter 1 opening direction requires comparison/proposal only, preserving current scenes/data/dialogue. D4–D9 remain unresolved.

## Immediate continuity checkpoint — owner instruction, 2026-10-17

- **Completed/pushed:** PR #27 conflict resolution at `412b501`; P1 pure validation at `16b9761`, import/TestRunner 131/0.
- **In progress:** full combined QA (log `/tmp/forensic-p1-canon-final-qa.log`); D1–D3 canon/metadata documentation; corrected six character reference candidates/provenance; opening alignment and Elias screenplay-summary comparison. No clinical or Chapter 1 implementation activated.
- **New permanent rule:** `AGENTS.md` §9 and explicit both-agent continuity scope in `CLAUDE.md`; shared checkpoint frequency applies to Codex and Claude.
- **Pending:** image correction/inspection, final manifest, final QA completion and verified feature pushes. Full Elias script will be supplied standalone later; line review is deferred, not blocked on an unknown Git location. D4–D9 and clinical material remain unapproved. Exact resume steps and local/remote file distinction are in `AI_SESSION_HANDOFF.md`.
