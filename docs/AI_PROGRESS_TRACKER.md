# AI progress tracker

Updated 2026-10-17 · current status is authoritative above the preserved earlier checklist.

| Workstream | Current status | Evidence / next step |
|---|---|---|
| Ch2 institutional / Ch3 inspection spec | Draft PR32; proposal and full QA complete | Summary comparison, deterministic safe-return/evidence/replay design; revised scripts confirmed not in Git; no runtime effects |
| Naomi character production | Proposal PR31 owner-merged into screenplay base | Verified58ea107; proposal complete, modeling approval pending; no overlapping asset/runtime edits |
| Earlier Naomi QA finding | Audio333/1; gameplay131/0; current audio334/0 | Existing fixed1.6s cinematic-resume assertion failed; reduced public-API probe passes1015ms; root cause unconfirmed, no test patch; current full inspection QA passed exit0 |
| Bennett-first production proposal | PR31 merged to screenplay base; proposal complete | 138 GLBs zero skin/animation/morph; Blender5.0 sources vs local4.3.2; ten-deliverable Naomi plan, no modeling |
| Ch3 first WardZero entry | Owner approved placement/access | Canon amendment recorded; formal Security/Facilities inspection only; proposed dialogue/navigation effects not approved |
| Mara Ch2 placement | Placement and agency canon recorded; crosswalk complete | Preserve age37, prior records work, disputed mood label, insomnia/fatigue/anxiety/checking, Dana collateral, Lillian Oct12/14 1988 conflict; no clinical activation |
| Five-chapter screenplay PR #30 | Review in progress | 11 files reviewed; chapter audit and owner decisions in FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md; hashes match; full QA passed exit0, 131 gameplay/334 audio; no activation |
| P0 campaign reconciliation/save regression | Merged by owner PR #29 | Main `dd247be`; baseline/save contracts retained |
| PR #27 soundtrack conflicts | Resolved, pushed, merged by owner | Original branch verified `412b501`; main merge `6d2dd2d`; bounded audio assertion fixed; audio 334/0 |
| P1 pure catalog/creation-draft validation | Complete for review | `codex/protagonist-schema-p1` verified `74715227bf5581b09a3b2746870082576fffe71f`; 15 new tests, 131/0 |
| D1–D3 canon and role metadata | Documented approved | Canon/decision record/review addendum; Rahman direction-only correction; no clinical activation |
| Six regenerated references | Completed as review candidates | Four views/five expressions each; hashes/prompts/provenance verified; owner/artist production review pending |
| Mara clinical/investigative independence | Owner approved narrative constraints | Declined disclosure/limited rapport retain independent mandatory evidence; care/recovery independent of mystery; clinical content pending |
| Chapter 1 opening alignment | Proposal complete | Hospital-drama direction recorded; early unease trigger confirmed; no chapter runtime change |
| Elias screenplay summary review | Full source reviewed | PR30 supplies source; audit maps detailed scene gaps; clinical approval pending |
| Both-agent continuous checkpoints | Permanent documentation prepared | AGENTS §9 / CLAUDE; preserve existing instructions, verify feature pushes |
| Final combined QA | **Passed, exit 0** | Python 6+3+3, pharmacology 0 failures, QA 19/0/0, GLB 138/138, TestRunner 131/0, audio 334/0, full Chapter 1 playback |
| P2 persistence/creator/content | Not implemented | Separate bounded scope; preserve save v3 until reviewed migration |
| D4–D9, Mac/clinical/art review | Pending | No implicit approval; missing approved v1.1 bible remains external; screenplay now present |

Exact branches/checkpoints/files/commands/blockers/resume steps: `AI_SESSION_HANDOFF.md`. API access restored; PR32 is the current inspection draft. PR31 owner-merged to screenplay base, not main; no merge by agent.

## Earlier checklist and milestone record (preserved history)


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

- **Protagonist customization proposal / reconciliation** · `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, status/handoff docs · deps: owner handoff; F1/F2 already merged · validation: baseline full QA passed on `fb07887` · next: P1 authorized by owner “continue”; later phases remain separate scopes.
- **Independent save-compatibility regression coverage** · new `scripts/tests/test_save_compatibility.gd` · deps: existing public SaveManager contracts · validation: full QA exit 0, TestRunner 116/0; pushed `01739ff` · next: create draft PR after GitHub API network access is applied.

## Pending (not started, waiting on approval)

- **Remaining visual decisions D4–D9 and final production sheets** · review §2 and "Open decisions" · deps: owner · next: owner comments on the draft PR or in the thread.
- **V1: mark ensemble and concept boards superseded** · `assets/creative_references/Visual_References/{Individual_Characters,Concept_Boards}/` · deps: D8 · next: small docs PR.
- **V2: `docs/design/CHARACTER_VISUAL_CANON.md`** · D1–D3 approved by owner 2026-10-17 · current specification written; reference candidates and final face/technical review remain.
- **V3: neutral mannequin stand-in replacing the capsule** · `scenes/props/Character.tscn` · deps: approval · validation: `test_world.gd` · next: keep node paths and collision.
- **V4–V8: Ward Zero kit, props, rooms W1–W8, trim sheets, playable zone** · `tools/blender/build_stage6_*.py`, `assets/exports/wardzero/**` (proposed) · deps: approval, the environment thread's Stage 6 PR, F2 zones · next: review that PR first.
- **V9: first anomaly `anom_clock_offset`** · deps: F3 anomaly model · validation: determinism test plus a test that clinical state cannot trigger it.
- **V10: first character model (Bennett)** · deps: approved canon and regenerated references.
- **Ward Zero audio pass** (room tones, phenomenon signature, re-cue `w0_knocking_heard`) · `audio/cues.json` · deps: audio workstream.
- **Performance budget and low preset** · deps: owner's Mac for profiling.

## Blocked

- **Environment Stage 6 (Ward Zero)** · environment thread · blocked on owner approval of plans; this review feeds it.
- **Rahman future content** · D1 resolved: Consultant Psychiatrist; voice direction label corrected, existing casting retained. Full responsibilities/dialogue await the accessible approved bible and specific content review; no speculative staff entry.

## Verified corrections / coordination

F0 PR #20, F1 #21, F2 #26 and review #28 are merged on `fb07887`; stale historical handoff text remains as history. Current PR list and hosted CI cannot be verified because GitHub API access returns Forbidden. Preserve historical audio/Stage 6 workstream ownership until verified. The owner’s current protagonist decisions are recorded in GDD amendments; D1–D3 were subsequently approved in this session; D4–D9 and full F3 remain undecided. Private v1.1 package is not available in this environment.

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

## Canon/proposal checkpoint

D1–D3 source record and authoritative specification are written, exact contradictory files/corrections mapped, and individual regeneration briefs supplied. Only Rahman’s profession in voice direction changes; no IDs/voice cast/clinical logic changes. Opening alignment and Elias summary comparison are written without overwriting chapter content. Full screenplay remains off-repository/pending clinical review; standalone text will arrive later. Candidate images/provenance and full combined QA are still pending finalization.

## Main integration checkpoint

Owner merged PR #27 at `6d2dd2d`; merged into the active feature branch. Previous pre-#27 run hit the diagnosed old audio timer (270/1) after 131/0 gameplay; merged bounded cleanup fix is now included. Full combined QA rerunning, not yet complete. Canon/opening/Elias documentation through `80ac668` is verified pushed. Candidate corrections and manifest remain in progress.

## Reference candidates completed

Six corrected candidate sheets, full prompts and provenance/hash manifest are packaged and inspected. Original artwork preserved; no 3D/model/clinical approval implied. Candidate owner selection, technical redraw and D4–D9 remain pending. Image generation/corrections are complete; final combined QA and exact final push checkpoint remain.
