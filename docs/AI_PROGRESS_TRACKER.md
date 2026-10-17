# AI progress tracker

## Merge reconciliation — Codex, 2026-10-17

The owner requested resolution of conflicts in the pending GitHub push. Git inspection identified PR #27's `claude/ashcroft-soundtrack` at `412a429a6e717ea00c96d2a9b8ad1987b82c7a58` conflicting with `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125`. This continuation (`codex/ashcroft-soundtrack-conflicts-cont-1`) merges main without rewriting history. The initial merge required two add/add continuity resolutions; a subsequent merge of `origin/main` `dd247bed93fca9bb95cbf2864eae964975358c23` (PR #29) required reconciling the active-workstream table as well; both workstreams' records are retained below. Runtime/audio/data content is unchanged by the conflict resolution. Validation exposed a pre-existing timing-sensitive audio test; its cleanup assertion now waits for the actual players with a bounded deadline instead of a fixed 3.6-second timer.

Current facts override historical stopping points below: F2 PR #26 and visual-review PR #28 are merged, while visual recommendations remained proposals at the merge baseline. The owner subsequently supplied explicit D1–D3 approval in this session; canon reconciliation is proceeding on a separate workstream, with D4–D9 still unresolved. PR #27's open/review state is not API-verified because `api.github.com` is blocked (proxy CONNECT 403). The owner explicitly confirmed PR #27 in this session. Validation completed and the continuation was pushed as an ordinary fast-forward update to `claude/ashcroft-soundtrack`, verified at `f59da089582ef27a6e58fc5eecc21a48d381a876`; this docs-only checkpoint follows it. No history rewrite or merge into main. PR #29 merged the protagonist proposal/save tests into main during validation; they are preserved in this latest merge. New P1 implementation will use a separate branch.

Validation: full Godot 4.7 QA on `7feb43e` completed with exit 0: Python 6+3+3, pharmacology 0 failures, QA 19/0/0, GLB 138/138, TestRunner 112/0, boot OK, audio 334/0 and complete Chapter 1 sequence. After PR #29 added four save regression tests and docs only, TestRunner reran on the combined merge and passed 116/0; other checked executable/data files are unchanged. Final results and remote checkpoint are recorded in `docs/AI_HANDOFF.md`. Mac listening and Suno licence confirmation remain owner tasks. No owner approval is invented by resolving the docs.

## Soundtrack workstream — preserved record


Required by the Ashcroft Session Continuity Protocol in `CLAUDE.md` §3. One row per task; each session updates only its own rows.

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Ashcroft score integration | In review (draft PR #27) | none | `audio/cues.json`, `systems/audio/AudioDirector.gd`, `tests/audio/TestAudio.gd` | Godot suite green locally; CI pending | Owner review |
| Chapter 1 music realignment per the bible | Approved by owner, in PR #27 | none | `audio/cues.json` (`records_archive`) | Tests green | Merges with PR #27 |
| Reception and records archive audio zones | Pending | Zone geometry for those areas | `data/zones.json` `audio_zones` | not started | World owner adds the rectangles |
| Suno licence confirmation (11 tracks) | Blocked on owner | Owner's Suno plan | `audio/manifest.json` | n/a | Owner records the terms |
| Listening pass on the Mac | Pending | Owner hardware | n/a | n/a | Owner listens to each context |

## Visual review workstream — preserved record (PR #28 merged)


Permanent checklist across sessions (`CLAUDE.md` continuity protocol §3). Each item lists related paths · dependencies · validation · next action. Move items between sections; do not delete finished ones. Detailed per-system status stays in `docs/PROJECT_STATUS.md`.

_Last updated: 2026-10-17 · Codex protagonist foundation continuation._

## Completed

- **Chapter 5 finale screenplay/state-contract review** · `docs/design/screenplays/ForensicWard_Chapter5_Finale_v2/`, `docs/AI_HANDOFF.md`, `docs/AI_SESSION_HANDOFF.md` · deps: verified `origin/main` and existing F0–F3 contracts · validation: static cross-check against Chapter 4 Scene 09 and current save/evidence/campaign managers; automated Godot QA unavailable in this workspace · next: owner/clinical review of the creative draft; do not implement gates or effects before approval.
- **Session handoff system** · `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md` · deps: `CLAUDE.md` protocol (PR #25) · validation: merged in PR #28 · next: keep current every session.
- **Character and Ward Zero visual production review** · `docs/design/VISUAL_PRODUCTION_REVIEW.md`; inputs `assets/creative_references/Visual_References/**` · deps: PR #24, #25 (merged) · validation: merged in PR #28; recommendations still proposals; current main baseline QA passed · next: owner approval.

## Completed this continuation (awaiting review, not merged)

- **Protagonist customization proposal / reconciliation** · `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, status/handoff docs · deps: owner handoff; F1/F2 already merged · validation: baseline full QA passed on `fb07887` · next: owner review of plan/P1, no creator implementation yet.
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

Implementation and proposal are pushed; no unexplained QA failures. Draft PR creation is blocked by API CONNECT 403. Prepared PR body is local at `/workspace/protagonist-foundation-pr.md`; full report/resume steps are in `AI_SESSION_HANDOFF.md`. Next implementation is P1 only after owner approval. No creator or save-version change has been made.
