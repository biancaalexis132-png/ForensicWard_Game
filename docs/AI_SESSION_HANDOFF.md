# AI session handoff

## Naomi 3D character base — Copilot, 2026-10-18

- **Last updated:** 2026-10-18 00:41 UTC
- **Objective:** provide an automated Blender 5.2.2 / MPFB2 2.0.18 builder and a real, editable Naomi base with exact provenance and Godot import validation; do not call the base a finished realistic character.
- **Branch / checkpoint:** `biancaalexis132-png-naomi-character-pipeline`, based on `origin/main` `29f1e3386ffe0f0907ef698859fa27c05da9b9d8`, with current `origin/main` `21205c3c71d4543a2fa4abe0d54e172ce725db01` merged. Code checkpoint `2a6ffda5e580c551b0f2f235861960e0d7662657` is pushed and `git ls-remote`-verified. No model PR yet; create a draft after the handoff commit is pushed.
- **Completed:** `tools/blender/characters/build_naomi.py` generates a rigged human, navy scrub shells, pulled-back procedural twists, skin/eye materials, a packed editable `.blend`, embedded-texture GLB, and orthographic preview views. Configuration, validator, run instructions and shared/character asset manifests are present. The final GLB has 53 joints and 42,583 triangles; Blender validation finds 15 required objects, two referenced embedded textures, and four renders. Godot 4.7 accepted the GLB and validated 139 exported assets with zero failures.
- **Licensing and dependencies:** the exact MPFB2 v2.0.18 CC0-1.0 base/rig/weights/target assets and macro weights are listed in `assets/asset_manifest/naomi_character_manifest.json`; the source commit and tag license evidence are recorded. MPFB2 code is GPL-3.0-or-later and is only a local build tool. No Mixamo or other non-MPFB external assets are used. Remote builders must install/enable MPFB2 v2.0.18 in Blender 5.2.2; it is not vendored.
- **Commands:** build with `/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/build_naomi.py`; validate with `/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/validate_naomi.py`.
- **Validation:** Blender build and validator passed. `python3 tests/qa/run.py --godot /tmp/godot-4.7-naomi/Godot.app/Contents/MacOS/Godot` passed JSON 6/6 and audio manifest 3/3, then stopped in music preview with two failures (`Unknown encoder 'libvorbis'`; one music test passed). The remaining Godot 4.7 checks were then run directly on this merged branch: import 0, QA 19/0/0, GLB validation 139/139, TestRunner 122/0, TestAudio 336/0, pharmacology 0 failures, boot OK, and Chapter 1 audio sequence completed. Hosted CI was not observed. `git diff --check` and Python AST/JSON validation passed.
- **Failures and blockers:** local FFmpeg cannot encode `libvorbis`; two unrelated music-preview tests fail in the full runner. Visual owner review, manual likeness/hair/clothing refinement, animations, LOD, Chapter 1 model integration, and target-device 30 FPS/p95 measurement are pending.
- **Next exact tasks:** 1) Owner reviews `assets/exports/characters/Naomi_Bennett_Base_v01_preview.png` and front/right/back renders. 2) Refine only to approved Naomi canon and rerun build/validator. 3) Add authored movement/acting clips as a separate milestone, then integrate through the existing `staff_bennett` character and merged model-independent acting adapter. 4) Profile the actual Chapter 1 scene on the 8 GB Mac.
- **Constraints:** no changes to dialogue, patient identity, clinical status/content, gameplay progression or saves were made. Do not link CP-001 screenplay content to Naomi; its identity/canon and clinical gates remain separate. PR #35's acting adapter is merged in `main` and does not require named bones.

## Naomi Chapter 1 acting-cue implementation — Copilot, 2026-10-18

**Objective:** implement the approved, additive performance cues for Naomi Bennett using the canonical source package, without touching the parallel Naomi model-building branch.

**Branch / checkpoint:** `biancaalexis132-png-naomi-chapter1-acting`, based on verified `origin/main` `29f1e3386ffe0f0907ef698859fa27c05da9b9d8`. Draft PR #35 to `main` is open at https://github.com/biancaalexis132-png/ForensicWard_Game/pull/35. The implementation commit `9d27aa1dd1566d3b6c4adaaffed821b189383562` and following continuity checkpoint have been pushed and verified; inspect the live branch ref for its latest documentation-only SHA. Never merge.

**Completed:** controller loads `docs/design/characters/Naomi_Acting_Cues_v1/naomi_acting_cues.json` without duplicating it; semantic cue data dispatches through `CharacterActingAdapter`, optional AnimationPlayers/blend shapes and rig adapter groups. Only `staff_bennett` is wired. Dialogue completion/interruption is surfaced by `EventBus.dialogue_line_finished`; missing voices retain subtitle behavior, stale callbacks are ignored, and loading resets transient acting state without adding a provider/schema field. Current placeholder and future rig do not depend on specific bone names. No wording, IDs, clinical statuses/content, story behavior, save format, or model-builder files changed.

**Files:** implementation in `scripts/acting/{NaomiActingController,CharacterActingAdapter}.gd` and UIDs; surgical integration in `scripts/world/Character.gd`, `scripts/autoload/EventBus.gd`, `systems/audio/AudioDirector.gd`; tests in `scripts/tests/test_naomi_acting.gd` and `tests/audio/TestAudio.gd`; docs in `docs/AUDIO.md` and the current continuity/status files.

**Validation:** cue validator passed all five IDs/voice mappings. Godot 4.7 import exited 0. `TestRunner.tscn`: 122 passed / 0 failed. `TestAudio.tscn`: 336 passed / 0 failed. `git diff --check` passed. Full `tests/qa/run.py` exited 1 in `tests/music_ai/test_generate_music.py`; JSON 6/6 and audio manifest 3/3 passed; music pipeline 1 passed / 2 failed with exact error `Unknown encoder 'libvorbis'`. Runner did not reach subsequent pharmacology/QA/GLB/Godot checks. Hosted CI not observed.

**Stop point / next actions:** PR #35 is ready for owner review; no merge. Keep model integration capability-driven. Owner/Mac review of realistic-model expression, gestures, transitions, render and mix remains outstanding. Do not touch model-builder, Blender, character asset, provenance or visual-render files. No pending user decisions block this work.

## Merge reconciliation — Codex, 2026-10-17

The owner requested resolution of conflicts in the pending GitHub push. Git inspection identified PR #27's `claude/ashcroft-soundtrack` at `412a429a6e717ea00c96d2a9b8ad1987b82c7a58` conflicting with `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125`. This continuation (`codex/ashcroft-soundtrack-conflicts-cont-1`) merges main without rewriting history. The initial merge required two add/add continuity resolutions; a subsequent merge of `origin/main` `dd247bed93fca9bb95cbf2864eae964975358c23` (PR #29) required reconciling the active-workstream table as well; both workstreams' records are retained below. Runtime/audio/data content is unchanged by the conflict resolution. Validation exposed a pre-existing timing-sensitive audio test; its cleanup assertion now waits for the actual players with a bounded deadline instead of a fixed 3.6-second timer.

Current facts override historical stopping points below: F2 PR #26 and visual-review PR #28 are merged, while visual recommendations remained proposals at the merge baseline. The owner subsequently supplied explicit D1–D3 approval in this session; canon reconciliation is proceeding on a separate workstream, with D4–D9 still unresolved. PR #27's open/review state is not API-verified because `api.github.com` is blocked (proxy CONNECT 403). The owner explicitly confirmed PR #27 in this session. Validation completed and the continuation was pushed as an ordinary fast-forward update to `claude/ashcroft-soundtrack`, verified at `f59da089582ef27a6e58fc5eecc21a48d381a876`; this docs-only checkpoint follows it. No history rewrite or merge into main. PR #29 merged the protagonist proposal/save tests into main during validation; they are preserved in this latest merge. New P1 implementation will use a separate branch.

Validation: full Godot 4.7 QA on `7feb43e` completed with exit 0: Python 6+3+3, pharmacology 0 failures, QA 19/0/0, GLB 138/138, TestRunner 112/0, boot OK, audio 334/0 and complete Chapter 1 sequence. After PR #29 added four save regression tests and docs only, TestRunner reran on the combined merge and passed 116/0; other checked executable/data files are unchanged. Final results and remote checkpoint are recorded in `docs/AI_HANDOFF.md`. Mac listening and Suno licence confirmation remain owner tasks. No owner approval is invented by resolving the docs.

## Soundtrack workstream — preserved record


Required by the Ashcroft Session Continuity Protocol in `CLAUDE.md` §2. The detailed per-branch log stays in `docs/AI_HANDOFF.md` (`AGENTS.md` §7); this file holds the current state of each active session's work so a new session can resume. One section per workstream; update your own section only.

## Ashcroft soundtrack

- **Last updated:** 2026-10-17 21:16 UTC
- **Current objective:** integrate the six Ashcroft OGGs from `assets/creative_references/Music/Ready_For_Godot/` into AudioDirector, using the master design bible for scene assignments; review the concept boards and notes.
- **Branch / PR:** `claude/ashcroft-soundtrack`, draft PR #27 to `main` (not merged; owner reviews).
- **Completed:** cues, the `hospital_ordinary` music state on a new `reception` location, contexts `patient_follow_up`, `oversight`, `ward_zero_anomaly` (event-only), `final_revelation` and `finale_motif`; a fix for play-once contexts that were cut short; manifest and provenance; `.gdignore` for reference art and the m4a sources; a separate commit moving exploration music to `records_archive` per the bible's Chapter 1 cue table; concept-board review (in the PR description).
- **Stopping point:** PR open, waiting on CI and owner review.
- **Remaining, by priority:**
  1. Owner confirms Suno licence terms and does a listening pass on the Mac.
  2. World owner adds `reception` and `records_archive` `audio_zones` rectangles in `data/zones.json`.
  3. Story data fires the new music events once those scenes exist.
- **Decisions:** tracks are referenced in place, never copied or re-encoded; levels are set per cue to about -20 LUFS; Ward Zero music starts only from explicit events.
- **Dependencies:** Godot 4.7 for tests; ffmpeg, numpy, scipy and soundfile for `tools/audio/build_manifest.py`.
- **Files modified:** see the `docs/AI_HANDOFF.md` entry dated 2026-10-17 21:40 UTC.
- **Tests:** `python3 tests/qa/run.py --godot <Godot 4.7>`: all suites pass; audio 334 passed, 0 failed.
- **Failures / blockers:** none.
- **Pending approvals:** the Suno licence. The owner approved the Chapter 1 realignment (records archive) on 2026-10-17.
- **Next steps for a new session:** read PR #27's comments and CI; act on owner feedback.
- **Creative and clinical constraints:** no music under clinical interviews or the Bennett handover; no anomaly audio in Chapter 1; never tie anomalies to patients' psychiatric symptoms.

## Visual review workstream — preserved record (PR #28 merged)


Updated 2026-10-17 · Codex · protagonist specification and save QA.

## Objective and last completed milestone

Continued the existing game without redesigning foundations. Reconciled main, delivered a phased protagonist specification, and completed four independent save-compatibility regression tests. Full development QA passed. No creator, personality system, clinical effect, visual asset, runtime or save schema change was implemented.

## Repository and remote checkpoint

- Branch: `codex/protagonist-foundation-cont-1`, based on verified `origin/main` `fb078877c59273c0856ec29f29e4ae43d3fc3125` (PR #28 merge).
- Latest verified implementation commit: `01739ff70136d191704b694fbf32d6b9e28ee26d` “Guard save rejection and optional provider compatibility”; pushed, and `git ls-remote origin refs/heads/codex/protagonist-foundation-cont-1` returned that exact SHA. A documentation-only final checkpoint follows it; resolve the final remote tip with the same command.
- Prior checkpoint `2d30785b3394d7faf5fc5826bf8a460e0a591277` contains reconciliation and proposal.
- PR: **not created**. `gh pr create --draft --base main --head codex/protagonist-foundation-cont-1 --title ... --body-file /workspace/protagonist-foundation-pr.md` failed: `Post "https://api.github.com/graphql": Forbidden`. REST listing also fails; direct API CONNECT is denied with 403. Current open PRs/reviews and hosted CI remain unverified.
- F0 #20, F1 #21, F2 #26 and visual review #28 are merged. No merge or push to main was performed.
- Historical soundtrack PR #27 (`claude/ashcroft-soundtrack`) and off-repository Stage 6 environment thread remain coordination reservations. Pull refs exist but do not establish open status. No overlap with their files.
- Working tree after import cleanup: intended changes committed; generated reference `.import` companions removed because absent at clean baseline; ignored `.godot/` retained. No pre-existing changes were present.

## Files and workstream ownership

Created `docs/REPOSITORY_RECONCILIATION.md`, `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`, `scripts/tests/test_save_compatibility.gd` and `.uid`. Updated `docs/PROJECT_STATUS.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/design/GDD_AMENDMENTS.md`, this file and append-only `docs/AI_HANDOFF.md`. These are the only changed paths versus main. Claim is complete, awaiting review; do not take audio/environment/character-model ownership from this entry.

## Technical findings and decisions

Actual runtime save version is 3 with v1→v2 chapter and v2→v3 zone migrations. ContentRegistry owns the immutable campaign catalog, not a separate `campaign` save provider (the historical F1 proposal differs). Keep the existing provider/checksum architecture. New tests prove rejected files preserve current providers, seed and successful-load events, added providers reset when absent, real legacy fixtures remain compatible, and added provider state round-trips/resets.

Owner-approved requirements are recorded in GDD amendments: fixed psychiatrist role, customizable professional/appearance background, moderate personal life, emergent personality and equal essential care/evidence/outcome access. The proposed provider, v4 migration, catalog, UI and callback design are **not approved implementation**. P1 is the next review gate.

## Validation

From `/workspace/ForensicWard_Game`:

`python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`

- Baseline on `fb07887`: exit 0; Python 6+3+3 passed; pharmacology 0 failures; QA 19/0/0; GLB 138/138; TestRunner 112/0; main boot OK; audio 271/0; complete Chapter 1 sequence.
- Development tree matching `01739ff` (only later docs changed): exit 0; same checks, TestRunner **116 passed / 0 failed**. `CH1_SEQUENCE_DONE` and `All executed checks passed` observed. New test file was unchanged between run and commit. Four new tests include five rejection variants.
- `git diff --check` passed. Test slot 99 and isolated temporary XDG directories used by the standard runner. No real saves touched.
- Initial system-Godot run failed the version gate (4.6.3); corrected by SHA-512-verified official 4.7 install. It is not an unresolved test failure.
- Expected rejection/tamper warnings occur in negative tests; Python mock-server socket ResourceWarnings are non-fatal. No unexplained failures or skipped checks.
- Local logs `/tmp/forensic-ward-qa.log` and `/tmp/forensic-ward-development-qa.log` are not GitHub artifacts. Hosted CI not observed. Mac Forward+/Metal appearance, input, listening and memory/frame time remain untested.

## Cloud setup

Godot 4.7 standard lives outside checkout at `/workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`; system `godot` is 4.6.3 and must not be used. Python/ffmpeg already available. No persistent server is needed. Installation/QA script and startup instructions were saved in the environment draft; additive custom network domain `api.github.com` was saved, preserving package-manager presets. Saving does not apply runtime changes or publish. Review/save environment settings and publish through the UI, then retry PR access using existing authentication before considering credential requirements. No token is requested.

## Blockers and owner approvals

- The private v1.1 design-bible/clinical package is unavailable here and absent from Git. Available GDD DOCX, engineering contract, character PDF, reference guides and current code/data were inspected; missing canon was not reconstructed.
- Visual D1–D9 remain open: Rahman role, Hale title, written casting, Ward Zero date/signatory, 02:17 link, Mara voice, station layout, superseded boards and committing the bible.
- F0 C2 Concordance/chapter titles, C6 Bleed, C7 pharmacology clue gates, C11 original music export and precise anomaly mechanism remain unresolved. Pending clinical content remains pending. F3 is not implemented.
- Next substantial change needs owner review of `PROTAGONIST_CUSTOMIZATION_PLAN.md`, specifically P1 catalog/schema and pure validator scope. Fixed psychiatrist role/moderate personal life/emergent personality are already approved and should not be re-asked.

## Exact next steps

1. Read AGENTS.md, CLAUDE.md, current status/progress, reconciliation, proposal and newest append-only handoff. Fetch origin and compare this branch/main; do not reset or rewrite pushed commits.
2. Once API domain access is applied, retry `gh pr list --state open`, inspect relevant reviews, then open a **draft** PR from this branch to main with the prepared description (local `/workspace/protagonist-foundation-pr.md`, or reconstruct from this handoff and committed changes). Recheck PR state before creating a duplicate. Do not merge.
3. Obtain owner approval for P1. After approval, implement only immutable option schema and pure profile validation with synthetic test fixtures; no creator UI, save version bump, personality scoring, casting changes or new clinical/narrative canon in P1.
4. For later P2, capture real v3 save before adding a provider, implement explicit v3→v4 migration and test full v1/v2/v3 compatibility. Follow the plan’s small PR sequence, maintaining clinical independence and equal mandatory access.
5. Before any environment/audio/visual task, verify the reserved external workstreams. Request the actual missing bible through the owner’s normal file workflow before relying on it. Mac checks require the owner’s hardware.
