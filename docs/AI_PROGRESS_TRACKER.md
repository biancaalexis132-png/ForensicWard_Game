# AI progress tracker

## Merge reconciliation — Codex, 2026-10-17

The owner requested resolution of conflicts in the pending GitHub push. Git inspection identified PR #27's `claude/ashcroft-soundtrack` at `412a429a6e717ea00c96d2a9b8ad1987b82c7a58` conflicting with `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125`. This continuation (`codex/ashcroft-soundtrack-conflicts-cont-1`) merges main without rewriting history. Only the two add/add continuity conflicts require manual resolution; both workstreams' records are retained below. Runtime/audio/data content is unchanged by the conflict resolution. Validation exposed a pre-existing timing-sensitive audio test; its cleanup assertion now waits for the actual players with a bounded deadline instead of a fixed 3.6-second timer.

Current facts override historical stopping points below: F2 PR #26 and visual-review PR #28 are merged, while visual recommendations D1–D9 remain proposals. PR #27's open/review state is not API-verified because `api.github.com` is blocked (proxy CONNECT 403). The owner explicitly confirmed PR #27 in this session. After validation, this continuation will be pushed as a fast-forward update to its existing branch; no history rewrite or merge into main. The owner's ongoing P1 protagonist work is on the separate `codex/protagonist-foundation-cont-1` branch, not part of this merge.

Validation: full Godot 4.7 QA is being run on this merge; final results and remote checkpoint will be added to `docs/AI_HANDOFF.md`. Mac listening and Suno licence confirmation remain owner tasks. No owner approval is invented by resolving the docs.

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
