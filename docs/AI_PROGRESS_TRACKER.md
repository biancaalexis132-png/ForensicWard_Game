# AI progress tracker

## Naomi procedural visual refinement — Copilot, 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Improve Naomi's automated base for owner visual review without runtime integration | v02 generated on `biancaalexis132-png-naomi-model-refinement`; checkpoint `1eb7e94` pushed; draft PR #45 open, hosted validation in progress | Blender 5.2.2, MPFB2 2.0.18; owner appearance review pending | `tools/blender/characters/**`, v02 source/GLB/renders and asset manifests, continuity docs | Blender validator: 53 joints, 32,281 triangles, 3 textures, 4 renders; final Godot GLB import validator 154/154; TestRunner 127/0. Renders still fail: pants read continuous/dress-like and garment boundaries are angular. Full QA runner blocked by missing FFmpeg `libvorbis`. | Confirm hosted validation; continue procedural garment diagnosis. Keep v02 out of runtime until visual checklist passes and owner approves. |

Scope excludes `staff_bennett`, animation, gameplay, clinical content and save systems. The optional WardCharacter visual slot merged in PR #42, but Naomi is not attached. The generated v02 is an automated candidate with known visual failures, not an approved or photorealistic character.

## CIG-1 optional character visual slot — Copilot, 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Add an optional imported 3D visual with a safe placeholder fallback without changing gameplay/save/clinical contracts | Merged to `main` in PR #42 at `de5cbfc` | Naomi base remains under owner visual review; authored animations do not exist | `scripts/world/Character.gd`, `scenes/props/Character.tscn`, `scripts/tests/test_character_visual.gd` | Historical Godot 4.7 import and TestRunner 127/0; fallback, dialogue, save/load and zone rebuild covered. The current merged feature branch import validator checks 154 assets with 0 failures. | No CIG runtime work remains; do not wire Naomi until visual approval and animations are available. |

This is runtime slot/fallback groundwork, not CIG-1 model acceptance. Naomi GLB structural preflight found one skin and zero animation clips; the imported base was not attached. See the newest `docs/AI_HANDOFF.md` and `docs/AI_SESSION_HANDOFF.md` entries for the exact commands, limitations and next steps.

## Jordan Vale CP-001 v2 review — Copilot, 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Review the nine-file Jordan Vale v2 package without changing its source or activating runtime content | Merged to `main` in PR #38 at `cf62677`; review report remains documentation-only | Owner’s limited narrative direction; qualified psychiatrist review still required | `docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/REVIEW.md`; continuity docs | The historical report recorded JSON syntax and diff checks passing; no CP schema validator; clinical review remains separate | Owner resolves identity/source questions; psychiatrist reviews exact case material before schema/runtime implementation |

Review findings: Chapter 1 still labels Jordan provisional/not canon; v1 package is absent from fetched repository history; historical diagnosis source and all clinical screenplay details remain pending; safety/legal/collateral scope and provenance need review; current runtime has no CP loader/lifecycle and SaveManager remains v3. See `REVIEW.md` for source citations, severity, dispositions and implementation gates. No source files, patient data, clinical rules, runtime, or save schema changed.

Coordination (updated against current `origin/main` `7e5bd2a`): PRs #35, #37, #39, #42 and #43 are merged, as are review PR #38 and documentation PRs #40/#41. PR #44 remains open. Naomi base visual refinement and animations remain separate; CP Naomi lines remain proposals. This review changed no clinical approval or runtime behavior.

## Naomi 3D character base — Copilot, 2026-10-18 (base merged in PR #37; refinement remains)

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Build a reproducible, licensed Naomi model base and Godot GLB | Base merged in PR #37 at `47a68f4`; follow-on refinement remains separate | Blender 5.2.2 LTS, MPFB2 2.0.18; current main includes merged acting adapter and production package | `tools/blender/characters/**`, Naomi-specific Blender/GLB/renders and asset manifests | Historical base validation: Blender validator 53 joints, 42,583 triangles, 2 embedded textures, 4 renders; Godot GLB 139/139; full runner blocked by two `libvorbis` music previews | Owner review of renders; refine likeness/hair/clothing, then stage animations/integration separately |

## Elias and Rahman character production specifications — merged in PR #39

`docs/design/characters/Elias_Ward_Character_Production_v1/` and `docs/design/characters/Rahman_Character_Production_v1/` are design/production specifications merged to `main` at `3887b66` (included in `47a68f4`). They do not by themselves approve clinical content, canon, animation, or runtime integration; use their review gates before implementation.

## Naomi Chapter 1 acting cues — Copilot, 2026-10-18 (merged in PR #35)

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Add model-independent acting cue controller for the five authored Chapter 1 dialogue IDs | Merged to `main` in PR #35 at `21205c3`; owner/Mac review pending | Canonical cue package merged on `main`; no dependency on unfinished 3D model | `scripts/acting/**`, Bennett-only integration, AudioDirector lifecycle signal, focused tests | Cue validator 5 IDs/voices; TestRunner 122/0; TestAudio 336/0; the repository runner's two music-preview cases still fail for missing local FFmpeg `libvorbis` | Owner review; then request Mac performance review |

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
