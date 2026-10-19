# AI progress tracker

## Chapter 2 vertical slices — Claude Code (cloud), 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Scenes 01–02 opening and records review | Done, PR #69 merged; PR #70 draft (Codex) | | `data/story_chapter2.json` | Full QA on `122304d` | Owner review of PR #70 |
| Scene 03 Mara introduction | Done, draft PR #71; owner approved scene | Approval logged 2026-10-18 | `data/dialogue_mara.json`, `data/patients.json`, `scripts/tests/test_chapter2_mara.gd` | Full QA on `09e4a8c`: game 212/0 | Psychiatrist review of patient record wording |
| Scene 04 Voss institutional review | Done, draft PR (stacked on #70) | PR #70 | `data/story_chapter2.json`, `scripts/tests/test_chapter2_voss.gd` | Full QA on `4796ca10fc6e070b1f119e1d2416af7104204780`: game 207/0 | Owner review |
| Scene 05 analyst working explanation | Done, draft PR #72 | `ch2_mara_records_referred` | `data/story_chapter2.json`, `scripts/tests/test_chapter2_analyst.gd` | Full QA on `0d298cf`: game 216/0 | Owner review |
| Scene 06 Hale's Door | Done, draft PR | Scene 05 | `data/world_chapter2.json`, `data/story_chapter2.json`, `scripts/tests/test_chapter2_hale.gd` | Full QA on `ffd5730`: game 220/0 | Owner review |
| Scene 07 witness | Done, draft PR | Scene 06 | `data/staff.json`, `data/world_chapter2.json`, `scripts/tests/test_chapter2_witness.gd` | Full QA on `3a919c9`: game 224/0 | Owner review |
| Scene 08 lobby inspection | Done, draft PR | Scene 07; owner chose escorted pass | `data/story_chapter2.json`, `data/world_chapter2.json`, `TrustManager`, `AuthoredWorld`, `scripts/tests/test_chapter2_lobby.gd` | Full QA on `4669c7c`: game 229/0 | Owner review |
| Scene 09 wrong-day file | Done, draft PR | Scene 08 | `data/story_chapter2.json`, `scripts/tests/test_chapter2_wrong_day.gd` | Full QA on `1481c7e`: game 233/0 | Owner review |
| Scene 10 missing hours (chapter close) | Done, draft PR | Scene 09 | `data/story_chapter2.json`, `ChapterDirector.gd`, `scripts/tests/test_chapter2_missing_hours.gd` | Full QA on `1bb194d`: game 235/0 | Owner review; personal message and fade-out not built |
| Chapter 4 Scenes 09-10 | Done, draft PR | previous slice | see dedicated handoff | Full QA at ec4d3d4: all executed checks passed; game tests 2 | Owner review |
| Chapter 4 Scenes 07-08 | Done, draft PR | previous slice | see dedicated handoff | Full QA at daca017: all executed checks passed; game tests 2 | Owner review |
| Chapter 4 Scenes 01-03 and 05 official record | Done, draft PR | previous slice | see dedicated handoff | Full runner exit 0: game 249/0, GLB 161/0, audio 336/0, QA 1 | Owner review |
| Chapter 3 Scenes 09-14 debrief to closing photograph | Done, draft PR | previous slice | see dedicated handoff | Full runner exit 0: game 246/0, GLB 161/0, audio 336/0, QA 1 | Owner review |
| Chapter 3 Scenes 05-08 alcove, route check and safe return | Done, draft PR | previous slice | see dedicated handoff | Full runner exit 0: game 244/0, GLB 161/0, audio 336/0, QA 1 | Owner review |
| Chapter 3 Scenes 03-04 descent and first Ward Zero entry | Done, draft PR | previous slice | see dedicated handoff | Full runner exit 0: game 241/0, GLB 161/0, audio 336/0, QA 1 | Owner review |
| Chapter 3 Scenes 01-02 notice and briefing | Done, draft PR | previous slice | see dedicated handoff | Full runner exit 0: game 238/0, GLB 161/0, audio 336/0, QA 1 | Owner review |
| Mac visual/performance | Not run | Owner's Mac | | | Owner / local thread |

## Dialogue visemes — Codex, 2026-10-18

Owner approved animations shown so far. `codex/dialogue-viseme-integration`
adds approximate text-driven mouth shapes through CharacterFaceRig, with jaw
fallback and pause/skip/completion/load coverage (TestRunner 187/0, ten new tests). True phoneme
timing is unavailable. Full QA and publication checkpoint are recorded in the
dedicated `docs/handoffs/2026-10-18_codex_dialogue_visemes.md` before handoff.
Mac visual/performance review remains required; no cosmetic additions or
campaign/clinical content changes are included.

## Naomi v05 refinement — Claude Code (cloud), 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Painted brows, matte skin maps | Done, draft PR; not approved | v03 skin texture | builder `paint_skin` | Cycles close-ups, in-game captures | Owner review |
| Blink closes fully | Done | | builder `Face.lid_weights` | Cycles close-up | none |
| Clean shoes and hems | Done | | builder `tidy_shoes`, `level_hems` | Cycles close-ups | Owner review |
| Gaze (eye bones + CharacterGazeRig) | Done | v05 eye bones | `scripts/world/CharacterGazeRig.gd` | TestRunner gaze test | Owner review in game |
| v04 draw-call jump on the Mac | Fix in place, unmeasured | Mac Forward+ | `CharacterAnimationRig._use_static_shadows` | Not reproducible on OpenGL | Mac thread measures |
| Merge MPFB faceunits into v05 | Not started | Mac MPFB packs | `bake_mpfb_face_shapes.py` | | Mac thread |

## Graphic-novel cutscenes — Claude Code (cloud), 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Reusable CutsceneDirector (panels, parallax, subtitles, music context, skip/replay, restore, error recovery) | Done, draft PR | AudioDirector, EventBus, Main panels | `scripts/cutscene/`, `scenes/cutscene/` | `test_cutscene.gd` 17 pass | Owner review |
| Chapter 1 seven-panel pilot, review-only | Done, draft PR; not approved | Naomi v04 capture; stage 2/4 renders | `data/cutscenes/`, `assets/cutscenes/ch01_pilot/`, `tools/cutscenes/` | Contract test; in-engine stills | Owner watches on the Mac |
| Mac Forward+ look, M1 frame time and memory | Not started | Owner's Mac | | No measurement | Owner / local thread |
| Campaign trigger for the pilot | Blocked on owner approval | Pilot approval and placement | | | After approval |
| Chapter 2–5 sequences and ending overlays | Not started | Pilot approval | | | In chapter order after approval |

## Character canon reconciliation and Rahman base — Claude Code (cloud), 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Record owner decisions D1–D3 and Mara's chapter | Done, docs PR | Owner message 2026-10-18 18:05 UTC | `docs/design/CHARACTER_VISUAL_CANON.md`, `VISUAL_PRODUCTION_REVIEW.md`, `GDD_AMENDMENTS.md` | Docs only | Owner review |
| Mark concept and ensemble boards "do not model" (D8) | Done, docs PR | Recommended in review | `assets/creative_references/Visual_References/**/README*.md` | Docs only | Owner can reverse |
| Rahman base model review candidate | In progress | Canon page; Rahman spec; bpy 5.2.2 + MPFB2 2.0.18 | `tools/blender/characters/rahman/`, `tools/character_animation/profiles/staff_rahman.json` | not run yet | Build and open PR |
| Voss production spec and model | Not started | Rahman pipeline proven | | | After Rahman |

## Soundtrack owner decision — Codex, October 18, 2026

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Record listening approval for all 11 existing tracks | Owner APPROVED; documentation updated on `codex/soundtrack-owner-approval` | Owner decision in Codex chat | `audio/manifest.json`, `docs/AUDIO.md`, generated `docs/AUDIO_MANIFEST.md`, current handoffs | See latest `docs/AI_HANDOFF.md` entry | Reuse for suitable cutscenes; ask before removal/replacement/regeneration |
| Commercial licensing verification | NOT VERIFIED / NOT REQUIRED FOR CURRENT SCOPE | PRIVATE / PERSONAL / NONCOMMERCIAL project | `docs/AUDIO.md` | No independent rights verification claimed | Review licensing and distribution rights again before any public release |

## Naomi v04 animation and cast animation standard — Claude Code (cloud), 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Idle, breathing, listening, speaking, turns and four gestures on the v03 rig | Done, draft PR; not approved | v03 (PR #49) | `tools/character_animation/{build_animated_character.py,clip_library.json}`, v04 GLB | GLB channel check; TestRunner 155/0; captures | Owner review |
| Blink, mouth and six restrained expression morphs; lashes; brows | Done, draft PR | v03 face | `profiles/staff_bennett.json`, `scripts/world/CharacterFaceRig.gd` | Renders; TestRunner | Owner review |
| Clothing re-skin (v03 scrubs were weighted to the hands) | Done | v02 base blend | builder `transfer_weights` | Chart gesture no longer drags the hem | none |
| Adapter idle fallback, expression lookup, gesture held tracks | Done with regression tests | | `scripts/acting/CharacterActingAdapter.gd`, `scripts/world/CharacterAnimationRig.gd` | `test_character_animation.gd`, `test_naomi_acting.gd` | none |
| Fold PR #51 into one workflow | Done; #51 can close once this is reviewed | PR #51 | toolkit folder | toolkit tests 6 OK | Owner closes #51 |
| Skin plastic look; shoe and hem lumps | Not started | Mac MPFB CC0 skin (local thread) | | | Next pass |
| MPFB faceunits / visemes as morphs | Not started | v02 base (v03 lost the basemesh vertex order) | | | Local thread on the Mac |
| Gaze and lip sync | Not started | | `character_gaze_adapter` | | After review |
| Mac validation and frame time | Not started | Local thread | | No measurement | Local thread |

## Naomi v03 visual development — Claude Code, 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| Preview faces the counter | Done, merged in PR #47 | | `scripts/world/CharacterVisualPreview.gd` | TestRunner, captures | none |
| Rahman voice profile role | Done, merged in PR #48 | | `audio/voice_profiles.json` | QA | none |
| Naomi hair, trousers, top, shoes, face (v03) | Done, draft PR; not approved | v02 MPFB body | `tools/blender/characters/build_naomi_v03.py`, v03 assets | Blender build OK, 44,692 tris; Godot import; captures | Owner review |
| Hybrid realism pass (CC0 skin/brows/lashes/hair, cloth sim) | Packs installed on Mac (system assets, eyebrows01, eyelashes01); not applied | Owner decision | `~/MPFB_Packs/` on the Mac | | Owner decides |
| Naomi idle pose clip and facial shape keys | Done in v04 (clips, hand-built morphs) and v05_mpfb (MPFB faceunits plus visemes); not approved | | `tools/character_animation/**` | TestRunner 158/0; full QA on Mac | Owner picks face-shape source |
| Naomi LOD and Mac frame time | Frame time measured; LOD not started | | `tools/godot/measure_character_frame_time.gd` | M1 MBA: v04 13.7/17.7 ms, v05_mpfb 14.3/17.9 ms mean/p95; 533k primitives and 828 draw calls flagged | Investigate the draw calls; LOD after approval |

## Naomi in-game review preview — Claude Code, 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| View Naomi in the Chapter 1 nursing station without approving her | Done, draft PR #46 | v02 GLB (merged in #45); slot from #42 | `scripts/world/CharacterVisualPreview.gd`, `scripts/world/Character.gd`, `scripts/tests/test_character_preview.gd` | TestRunner 131/0, full QA exit 0 on `6b6893d`; Mac not run | Owner views on Mac |
| Naomi hair, trousers, hems, face (v03) | Not started | Owner decision on model direction | `tools/blender/characters/**` | v02 fails QA items 1, 4, 6, 7, 8 | Owner decides |
| Naomi idle pose and acting clips | Not started | Approved model | GLB animations; `scripts/acting/**` | none | After v03 |
| Naomi LOD and Mac frame time | Not started | Approved model and idle | | No measurement exists | After animation |
| Bennett facing at the nursing station | Blocked on owner | | `data/world_chapter1.json` / zone scene marker | Captures show her back from the counter | Owner decides |
| PR #44 conflicts with `main` | Done at `1a1fb10`; #44 merged at `fec5933` | | four continuity docs | QA exit 0, TestRunner 142/0 | none |

## F3 anomaly evidence model — Claude Code, 2026-10-18

| Task | State | Dependencies | Paths | Validation | Next action |
|---|---|---|---|---|---|
| F3 anomaly evidence model and clinical/supernatural separation, flag off | Draft PR #44 open, assigned to owner | F1, F2 (merged); Bleed answered: presentation only | `data/anomalies.json`, `scripts/narrative/AnomalyLedger.gd`, `scripts/content/*`, `scripts/tests/test_anomaly.gd` | TestRunner 127/0 and QA green on `5283735`; hosted CI pending | Owner review; fix CI if red |
| F3 merge | Blocked on owner review | PR #44 | | | Owner |
| Pharmacology clue gates in gameplay | Blocked on F0 C7 | Owner | `data/patients/PT-00{1,2}.json` | Reported at boot as known exceptions | Owner decides remove or move to story |
| `.gdignore` for `assets/creative_references/` (keeps 42 MB of references out of imports) | Pending owner go-ahead | | `assets/creative_references/` | | Owner |

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
