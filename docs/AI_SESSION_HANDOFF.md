# AI session handoff

## Claude Code Chapter 3 Scenes 01-02 notice and briefing — 2026-10-19

- `claude/chapter3-briefing` at `4c1bb95df4dc22781005a335222398a3e836b845`. Full runner exit 0: game 238/0, GLB 161/0, audio 336/0, QA 19/0/0, Python, pharmacology 0, boot, CH1 sequence. Mac not run. Next: Chapter 3 Scenes 03-04: descent and first authorized Ward Zero entry. Wire zone_ward_zero (Stage 6 env exists, zone placeholder) and the W0-B route; Hale and Facilities engineer escort; marked route only. Pending: owner narrative review (Chapters 2-3 story files provisional/PENDING); Naomi Mac/geometry gates.

## Claude Code Chapter 2 Scene 10 — 2026-10-19

- Closing beat on `claude/chapter2-missing-hours` at `1bb194df802b68591f9e7ab8a7939754e91bd8e3` (PR to main, stacked after #77). Chapter 2 is now completable end to end. Full QA exit 0, game 235/0. Mac not run. Not built: optional personal-contact message, exterior fade-out. Pending: owner narrative review of Scenes 04–10 (story file stays provisional/PENDING); Naomi Mac/geometry gates.

## Claude Code Chapter 2 Scene 09 — 2026-10-19

- Wrong-day file on `claude/chapter2-wrong-day` at `1481c7ea32b8a5cb553d50529afd387e382f5898` (PR to main, stacked after #76). Full QA exit 0, game 233/0. Mac not run. Next: Scene 10 "Missing Hours" (analyst, Bennett, optional personal message, chapter close). Naomi Mac/geometry gates still pending.

## Claude Code Chapter 2 Scene 08 — 2026-10-19

- Escorted lobby inspection on `claude/chapter2-lobby` at `4669c7c387107584e6429cf79cb035194fcec0b5` (PR to main, stacked after #75). Owner chose "Escorted pass". Full QA exit 0, game 229/0. Mac not run. Next: Scene 09 "A File for the Wrong Day", then Scene 10. Naomi Mac/geometry gates still pending.

## Claude Code Chapter 2 Scene 07 — 2026-10-19

- Witness scene on `claude/chapter2-witness` at `3a919c972c4cbac795dd72844567516dae68a04f` (PR to main, stacked after #74). Full QA exit 0, game 224/0. Next: Scene 08 lobby-only inspection.

## Claude Code Chapter 2 Scene 06 — 2026-10-19

- Hale's Door added on `claude/chapter2-hale` at `ffd5730f9d6182d26f104f9d340fad566587fdb8` (PR to main; stacked after #73). Full QA exit 0, game 220/0. Next: Scene 07 witness.

## Claude Code Chapter 2 Scene 05 — 2026-10-19

- Analyst working explanation added on `claude/chapter2-mara-intro` (PR #72 to main) at `0d298cfa7a557eeab11a0b265e203116012fe0ad`, pushed and verified. Full QA exit 0, game 216/0. Next: Scene 06 Hale's Door.

## Claude Code Chapter 2 Mara introduction — 2026-10-19 00:10 UTC

- Owner approved Scene 03 ("i approve scene 3"). Implemented on the same branch/PR #71 at `09e4a8cb45981dd0959c7dc6058b62bc870e0d58` (pushed, verified). Full QA exit 0, game 212/0. Dialogue approved; patient record pending review. Next: Scene 05. See dedicated handoff addendum.

## Claude Code Chapter 2 Voss review — 2026-10-18 23:50 UTC

- **Objective:** take over from Codex and implement CH02 Scene 04 (Voss institutional review) as a playable slice.
- **Branch / PR:** `claude/chapter2-voss-review` from verified Codex `4605568` (PR #70 untouched); runtime `4796ca10fc6e070b1f119e1d2416af7104204780` pushed and verified; draft PR targets `codex/chapter2-records-review`.
- **Completed:** three Voss steps (scope, permissions, follow-up) with feedback-only unsupported choices; four real-Main tests for both branches, interruption and post-choice save/load.
- **Tests:** full QA exit 0 on `4796ca10fc6e070b1f119e1d2416af7104204780` (game 207/0, GLB 161/0, audio 336/0, QA 19/0/0, Python 6+4+5+3, pharmacology 0, boot, CH1 sequence). Mac not run.
- **Pending approvals:** narrative review of the proposed Voss dialogue; Mara clinical content; Naomi Mac/geometry gates.
- **Next steps:** CH02 Scene 05 analyst working explanation (see dedicated handoff `docs/handoffs/2026-10-18_claude_chapter2_voss_review.md`).
- **Constraints:** no invented clinical facts or source receipts; no Ward Zero entry before Chapter 3; clinical care separate from records work.

## Codex dialogue visemes — 2026-10-18

- Owner: "continue i approve of the animations so far"; scoped approval recorded, no broader likeness/performance approval inferred.
- Branch `codex/dialogue-viseme-integration`, implementation `44b2ff5418b027868ec562d8d98569ad06d909b2` pushed and verified; integrates merged source/preview PRs #65/#66.
- Existing face rig now uses approximate text visemes with jaw fallback and lifecycle/pause support. Ten real-model regressions; full QA exit 0: TestRunner 187/0, GLBs 161/0, audio 336/0 and Chapter 1 sequence complete. Two AudioDirector timers fixed for unvoiced/gap pause. Dedicated handoff records commands, recovery checkpoint and draft link.
- Linux diagnostic MP4/still in `docs/handoffs/dialogue_viseme_diagnostic/`; target Mac review remains pending. Exact resume: `Godot --path . -s res://tools/godot/review_dialogue_visemes.gd` on the Mac, then speaking/idle frame time and gesture-shadow checks. No asset, clinical dialogue, save schema or cutscene change.
- Dedicated recovery: `docs/handoffs/2026-10-18_codex_dialogue_visemes.md`. All earlier workstream entries preserved.

## Codex explicit v06 preview — 2026-10-18

- Branch `codex/naomi-v06-review-preview`, implementation `ca8b689166e69fcb4cf97aab2d621789be04ac54` pushed and verified. Independent source validation is draft PR #65; initial audit PR #64 merged.
- Owner confirmed other sessions stopped. Added explicit v06/v06_mpfb choices in existing preview; default v05 and normal capsule preserved. No controller or asset changes.
- Dedicated handoff `docs/handoffs/2026-10-18_codex_naomi_v06_preview.md` has commands, final test outcomes and next exact tasks. Runtime dialogue visemes, significant source lid/hem corrections, Mac review and approval remain outstanding. Existing entries below preserved.

## Naomi v05 refinement — Claude Code (cloud), 2026-10-18 18:40 UTC

- **Objective:** fix v04's brows, blink gap, plastic skin, shoes and hems; add gaze; investigate the Mac's v04 draw-call jump.
- **Branch / PR:** `claude/naomi-v05-refinement`, draft PR; verified at `da3ed52`, with main merged in (PRs #55, #56, #57).
- **Completed:** see the 18:40 UTC entry in `docs/AI_HANDOFF.md`.
- **Tests:** TestRunner 160/0; toolkit 6 OK; provenance 6 OK.
- **Pending approvals:** Naomi v05 appearance; which v05 face (hand-built or MPFB) to keep.
- **Next steps:** Mac frame-time check of the static shadow copies; MPFB face bake on top of v05.
- **Constraints:** not approved or default; v01–v04 untouched; no patient movement; no Mac performance claims.

## Naomi Mac validation and v05_mpfb — Claude Code (owner's Mac), 2026-10-18 18:40 UTC

- **Objective:** validate cloud v04 on the owner's Mac, measure frame time and bake MPFB face shapes; review only.
- **Branches / PRs:** #52 (ffmpeg fallback), #54 (v04 Mac review take) and #57 (v05_mpfb) are merged. This doc update is `claude/local-mac-handoff`.
- **Completed:** the oggenc fallback; 5 CC0 MPFB packs on the Mac; v04 Mac rebuild and take; the `bake_mpfb_face_shapes.py` bake step; v05_mpfb; the frame-time probe; full QA passing on the Mac.
- **Exact stopping point:** all merged; waiting on the owner's face-shape decision.
- **Next steps:** investigate v04's 533k primitives and 828 draw calls (cloud v05 thread). Re-measure on the Mac after each Naomi version.
- **Constraints:** never run git in the SSK copy; the clean clone is `~/ForensicWard_Campaign_Publish`.

## Graphic-novel cutscenes — Claude Code (cloud), 2026-10-18 18:35 UTC

- **Objective:** reusable review-only CutsceneDirector and a seven-panel Chapter 1 pilot in the painted graphic-novel style; later chapters in order after approval.
- **Branch / PR:** `claude/cutscene-director`, draft PR #59 to `main`. Code commit `0ecf743`; `main` merged in up to `ac89efd` (PR #60).
- **Completed:** director, registry, review scene, pilot data, painted plates and their generator, review stills, `docs/CUTSCENES.md` reconciliation with both SSK packages.
- **Tests:** full `tests/qa/run.py` exit 0 (TestRunner 174/0); hosted CI green on `19969f7`.
- **Exact stopping point:** pushed, conflicts with `main` resolved; waiting on owner review of the pilot on the Mac.
- **Pending approvals:** pilot visuals and placement; staff-entry stand-in plate; music cue (`mus_waiting_room` vs `mus_main_theme_alt`); Day 1 morning vs afternoon canon; Naomi likeness.
- **Next steps:** see the 2026-10-18 18:35 UTC entry in `docs/AI_HANDOFF.md`.
- **Constraints:** cinematics off in the campaign; no invented dialogue or captions; no clinical, story or save writes; reveal boundaries (Ch3 Ward Zero entry, Ch4 S09 loop, three Ch5 endings); never Git on the SSK drive.
## Character canon reconciliation and Rahman base model — Claude Code (cloud), 2026-10-18 18:30 UTC

- **Objective:** fold the owner's 2026-10-18 18:05 UTC decisions (Rahman Consultant Psychiatrist; Hale Security Director, no tactical armour; Naomi, Voss, Elias, Mara traits; Mara from Chapter 2) into the docs, then build the next unfinished character in the visual lane: Dr Leila Rahman's base model, as a review candidate.
- **Branches / PRs:** `claude/character-canon-reconciliation` (docs PR, from `main` `e9e9171`); `claude/rahman-base-v01` (model PR, next).
- **Completed:** `docs/design/CHARACTER_VISUAL_CANON.md` (decided vs provisional); D1–D3 status in `VISUAL_PRODUCTION_REVIEW.md`; GDD amendment row; "do not model" READMEs on the concept and ensemble boards (D8 as recommended; nothing deleted).
- **Exact stopping point:** docs PR being opened; Rahman build not started. Container has `bpy` 5.2.2 and an MPFB2 v2.0.18 clone in the session scratchpad (not committed).
- **Pending approvals:** D4–D7, D9; every face, skin and casting detail not in the canon page's Decided table.
- **Next steps:** build Rahman with a new builder under `tools/blender/characters/rahman/` and a new profile `tools/character_animation/profiles/staff_rahman.json`; do **not** edit `build_animated_character.py` (Naomi v05 thread owns it) or Naomi's builders.
- **Constraints:** review candidate only; no `data/staff.json` entry; no runtime binding; no performance claims without Mac measurements.

## Owner soundtrack approval update — Codex, October 18, 2026

- **Current task:** record the owner's soundtrack decision; no animation or cutscene implementation in this scoped update. Broader takeover work remains for a separate continuation.
- **Branch / base:** `codex/soundtrack-owner-approval`, from verified `origin/main` `b5c9d3a7387af36859d9783151c8f6d9d11028dd` (PR #53 merged).
- **Decision:** owner listening approval **APPROVED** for all 11 existing soundtrack tracks, including Suno songs. Project scope **PRIVATE / PERSONAL / NONCOMMERCIAL**. Commercial licensing verification **NOT VERIFIED / NOT REQUIRED FOR CURRENT SCOPE**. Source: owner's October 18, 2026 Codex chat; authoritative audio details in `docs/AUDIO.md`.
- **Preservation:** retain every approved audio file, cue ID, timing and integration. Ask before removing, replacing or regenerating tracks. Do not call the songs legally copyright-free without independent verification or claim commercial-distribution clearance.
- **Cutscene direction:** reuse approved music wherever appropriate; propose additions only for a meaningful narrative/cinematic gap. Review licensing and distribution rights again before any public release.
- **Supersession:** this decision replaces earlier soundtrack listening/approval blockers and the attached takeover note's pending-licensing instruction for the current scope. It is the owner's scoped override of `AGENTS.md` §5's commercial-use prerequisite for these existing tracks; other assets and future distribution remain separate.
- **Next step:** use the approved soundtrack when auditing cutscene coverage; no further listening approval is needed for these 11 tracks. Naomi visual approval and unrelated work remain pending. Validation, changed files, verified checkpoint and publication status are recorded in the newest `docs/AI_HANDOFF.md` entry.

## Naomi v04 animation and cast animation standard — Claude Code (cloud), 2026-10-18 16:45 UTC

- **Objective:** give Naomi real animation and face controls on the v03 rig through one reusable pipeline for the whole cast, merged with the Mac-tested work from PR #51; review only.
- **Branch / PR:** `claude/naomi-animation-v04`, draft PR to `main` (supersedes PR #51; do not close #51 without the owner). Code verified at `afdc3d0`.
- **Completed:** builder, clip library, profile and standard in `tools/character_animation/`; v04 .blend/GLB/renders/manifest; `CharacterAnimationRig` and `CharacterFaceRig`; adapter fixes (idle fallback, expression lookup); gesture held-track fix; PR #51 folded in; in-game captures in `ingame_review_v04/`.
- **Clip names:** body `idle_neutral`, `idle_breathing`, `listen_neutral`, `stand_conversational`, `turn_from_workstation`, `return_to_workstation`; gesture `small_greeting_nod`, `small_acknowledgement_nod`, `restrained_chart_indication`, `subtle_workstation_indication`; morphs `blink`, `blink_L/R`, `mouth_open` and six restrained expressions.
- **Tests:** TestRunner 155/0 on `afdc3d0`; toolkit 6 OK; full QA recorded in the PR.
- **Exact stopping point:** pushed; waiting on owner visual review and Mac validation by the local thread.
- **Pending approvals:** Naomi v04 appearance and motion; closing PR #51.
- **Next steps:** see the 2026-10-18 16:45 UTC entry in `docs/AI_HANDOFF.md` (skin, shoe/hem, MPFB faceunits on the v02 base, gaze).
- **Constraints:** not approved or default; v01–v03 untouched; no patient symptom movement; never Git on the SSK drive; no performance claims without Mac measurements.

## Naomi v03 visual development — Claude Code, 2026-10-18 15:40 UTC

- **Objective:** make Naomi substantially more realistic in the review preview without approving her or touching v01/v02, clinical, narrative or save data.
- **Branch / PR:** `claude/naomi-v03` from `main` `0fd2bc1`; draft PR to `main`. PR #47 (counter facing) and #48 (Rahman → Consultant Psychiatrist voice direction) are merged.
- **Completed:** v03 builder, .blend, GLB, 5 renders, manifest; preview default v03; in-game captures and comparisons; `NAOMI_V03_NOTES.md` (diagnosis, remaining gaps, hybrid recommendation).
- **Exact stopping point:** committed and pushed; waiting on owner appearance review and hosted CI.
- **Pending approvals:** Naomi appearance; procedural vs hybrid route.
- **Next steps:** see the 2026-10-18 15:40 UTC entry in `docs/AI_HANDOFF.md`.
- **Constraints:** not approved, not default; never Git on the SSK drive; no performance claims without Mac measurements.

## Naomi in-game review preview — Claude Code, 2026-10-18 14:15 UTC

- **Objective:** let the owner see Naomi in the real Chapter 1 nursing station without approving or defaulting the model; record what is still missing.
- **Branch / PR:** `claude/naomi-review-preview` from `main` `a202caf`; code commit `6b6893dc3aff22e64745e7510ee3e1c8370bee81`; draft PR #46. PR #44's conflicts with `main` resolved at `1a1fb10` (docs only).
- **Completed:** review-only `--character-preview` switch, 4 tests, in-game captures, `docs/design/characters/Naomi_Bennett_Character_Production_v1/NAOMI_INGAME_REVIEW.md`.
- **Finding:** v02 fits technically (1.70 m, feet on floor, 53-joint rig, imports and attaches) but fails appearance: flat hair strips over face and chest, skirt-like trousers, jagged hems, T-pose through the desk, cartoon-scaled eyes. Bennett's marker faces into the office, so from the counter the player sees her back.
- **Tests:** `tests/qa/run.py` exit 0 on `6b6893d` (TestRunner 131/0, QA 19/0/0, GLB 154/154, audio 336/0).
- **Exact stopping point:** code and docs pushed; waiting on owner review and hosted CI for #46.
- **Pending approvals:** Naomi appearance; model direction (procedural vs artist vs licensed); Bennett's facing.
- **Next steps:** see the 2026-10-18 14:15 UTC entry in `docs/AI_HANDOFF.md`.
- **Constraints:** off by default; no story, dialogue, clinical, save or world-layout change; Ward Zero and anomaly work untouched.

## F3 anomaly evidence model — Claude Code, 2026-10-18 01:50 UTC

- **Current objective:** F3 from `docs/F0_FOUNDATION_AUDIT.md` §7–§8: the anomaly evidence model and the rule that keeps clinical and supernatural events apart, flag off so Chapter 1 plays as today. Built on the owner's answer that Psychosomatic Bleed is presentation only.
- **Branch / PR:** `claude/f3-anomaly-model`, draft PR #44 to `main` (assigned to the owner, subscribed for CI and review events). Code verified at `5283735`; `main` at `de5cbfc` merged in afterwards (docs-only conflicts in the four continuity/status files, both sides kept).
- **Completed:** `data/anomalies.json` (three Chapter 1 episodes, cap `reported`); `scripts/narrative/AnomalyLedger.gd` in `Main` (provider `anomaly`, flag `forensic_ward/narrative/anomaly_enabled = false`); validator separation rules; clue `source_class`/`claim_state`; StoryLogic `zone` and `world_state` conditions; two EventBus signals; `scripts/tests/test_anomaly.gd` (15 tests).
- **Tests:** TestRunner 127/0 and `tests/qa/run.py` all passed on `5283735`; after merging `main` at `de5cbfc`, TestRunner 142/0 and `tests/qa/run.py` exit 0 again.
- **Exact stopping point:** everything committed and pushed; waiting on hosted CI and owner review.
- **Pending approvals:** PR #44 review; F0 C2, C3, C4, C7 (pharmacology clue gates printed at boot as known exceptions), C11, the precise supernatural mechanism.
- **Next steps:** fix CI if red; after the owner merges, remove the F3 row from the Active workstreams table. Never merge.
- **Constraints:** psychiatric symptoms, diagnoses, medication, rapport and the physician's strain never count as anomaly evidence; anomaly events never change clinical state; the flag stays off; no Chapter 2–5 episodes without approval.

## Naomi procedural visual refinement — Copilot, 2026-10-18 13:31 UTC

- **Objective:** generate and validate a versioned automated Naomi visual-review candidate; preserve v01, approved design boundaries and all runtime/clinical/save/gameplay systems.
- **Branch / base / checkpoint:** `biancaalexis132-png-naomi-model-refinement`; based on `main` `7e5bd2a` after merge commit `9a36b3779bc9582e329364a86c76f94c1192529e`. Code/test checkpoint: `1eb7e948de53fcf5efa0a240a918b7b4b14ed5cc`; docs-only follow-up: `bb56860e0906182c3300f57b80b5e64e88421c02`; implementation/assets commit: `b740f8ab83733fd797be344e6e9b4eefa5a5769a`.
- **GitHub state:** `origin/main` `7e5bd2a` includes merged PR #43 (Stage 6); PR #42 is also merged. Draft PR #45 is open against `main`; hosted `validate` is in progress on the docs-updated head as of 2026-10-18 13:32 UTC. PR #44 remains open.
- **Completed:** v02 `.blend`, Godot `.glb`, four PNG renders and per-character/shared manifests were generated; v01 is unchanged. Builder uses the documented MPFB2 2.0.18 services, female macro endpoint, exact `.target.gz` source provenance, generated body/garment textures and version-specific outputs. Spherical features are created from fixed procedural vertices; generated PNG volatile metadata is removed. Repeated builds produced byte-identical GLB and renders, while `.blend` container bytes differed from Blender serialization.
- **Current visual finding / blocker:** v02 close preview shows eyes, brows, nose and mouth; however full-body renders still read as one continuous lower garment and show angular clothing/skin boundaries. The visual QA checklist therefore fails; v02 is not approved and must not be attached to `staff_bennett`. No photorealism claim is made.
- **Current files:** `tools/blender/characters/{build_naomi.py,naomi_appearance.json,validate_naomi.py,README.md,NAOMI_VISUAL_QA.md}`; v02 Blender/GLB/four render outputs; `assets/asset_manifest/{asset_manifest.json,naomi_character_manifest_v02.json}`. Merge also preserves upstream Ward Zero Stage 6 files.
- **Validation:** latest Blender 5.2.2 build and validator passed: 14 required scene objects, 53 joints, 32,281 triangles (45,000 budget), three embedded textures, four renders. CIG preflight: 15 meshes, 69 nodes, one skin, zero animations, 11 materials, three textures. After final regeneration, Godot 4.7 editor import succeeded; GLB import validator checked 154 assets with zero failures; TestRunner passed 127/0. Python compilation, JSON syntax and `git diff --check` passed. Same-config GLB and four PNG render files were byte-identical across repeat builds; native `.blend` binary was not.
- **Full-runner failure:** `python3 tests/qa/run.py --godot /tmp/forensic-ward-godot-4.7/Godot.app/Contents/MacOS/Godot` exits 1 in the music-preview tests because FFmpeg reports `Unknown encoder 'libvorbis'` for `test_generate_verify_and_approve` and `test_reference_audio_uses_approved_main_theme`. JSON passed 6/6, audio-manifest passed 3/3, music tests passed 1 and failed 2; Godot suites were then run directly and TestRunner passed 127/0.
- **Dependencies / pending approvals:** MPFB2 2.0.18 is installed locally under Blender user extensions and is not vendored. Owner appearance review, Mac-render review/performance, animation and LOD remain pending.
- **Next exact steps:** (1) keep draft PR #45 unmerged and confirm its hosted `validate` result when complete; (2) continue automated garment/mesh diagnosis only with documented, licensed inputs; do not integrate v02 while the checklist fails; (3) request owner/artist direction if procedural-only improvements cannot remove the observed silhouette/artifact defects; (4) defer animation, LOD and Mac performance until appearance approval.
- **Creative and clinical constraints:** do not infer precise face/jewelry details beyond approved canon. Keep `staff_bennett`, dialogue, clinical review, story, save and gameplay unchanged. The optional visual slot is merged, but v02 is not integrated.

## CIG-1 optional character visual slot — Copilot, 2026-10-18 01:13 UTC

- **Current objective:** prove an optional 3D visual can sit behind the existing WardCharacter interface without changing interaction, story, clinical or save behavior. Do not integrate the automated Naomi base before owner visual approval.
- **Branch / base / checkpoint:** `biancaalexis132-png-cig-1-character-integration`, based on `main` `96ef65ed40ced591f576326e21fcd60f9da9d3a7`. Implementation commit `387ceba5fc6d5abf9c564ef876c9c475825e2493` and continuity checkpoint `d5d19f5ff329220bdbedfc006f632715923e8f87` are pushed and `git ls-remote` verified. Draft PR #42 is open against `main`, last-checked head `d5d19f5`.
- **GitHub reconciliation:** current `origin/main` is `96ef65e`, later than the `47a68f4` SHA in prior handoffs. PR #38 (Jordan review), #40 (Hale/Mara package), and #41 (CIG documentation) merged after that recorded SHA. Naomi acting #35 and base #37 remain merged. No open PRs were found before preparing this CIG PR.
- **Completed:** `Character.tscn` now has `VisualRoot`. `WardCharacter` accepts an optional `PackedScene`, validates the root and renderable mesh, preserves the capsule fallback on invalid resources, and keeps the seated 0.65Y scaling on the placeholder only. The `.uid` for the new test is generated and retained. Gameplay interaction IDs, collisions, label, dialogue, story, clinical state and save schema are unchanged.
- **Tests:** official Godot 4.7 universal macOS build downloaded and SHA-512 verified; editor import exit 0; 127/0 TestRunner, 19/0/0 QA, 139/139 GLB imports, 0 Pharmacology failures, boot OK, 336/0 TestAudio, Chapter 1 audio sequence complete. CIG Python preflight tests 3/3; Naomi GLB has 1 skin and zero animations. Full repo runner exits at two music tests with `Unknown encoder 'libvorbis'`; exact details are in the AI handoff.
- **Failures/blockers:** no runtime model/animation integration yet. Naomi's main-branch base has pending visual review and no animation clips. The Mac's rendered appearance/performance review is not done. PR #42 hosted `validate` is pending on last-checked head `d5d19f5` (run 39085902026); not yet observed passed. The current handoff update will move the PR head.
- **Files changed:** `scripts/world/Character.gd`, `scenes/props/Character.tscn`, `scripts/tests/test_character_visual.gd`, its `.uid`, and continuity/status docs.
- **Next exact steps:** (1) push this PR-state handoff update and refresh hosted checks on the new head; (2) keep PR #42 draft and unmerged; (3) wait for owner visual approval and authored animation assets before integrating Naomi; (4) run visual/pose/performance review on owner hardware.
- **Creative/clinical constraints:** do not alter `data/world_chapter1.json`, existing IDs/dialogue, clinical approval, story progression, or saves; do not tie supernatural content to symptoms; do not edit Naomi builder files or report placeholder success as model acceptance.

## Jordan Vale review merge reconciliation — Copilot, 2026-10-18 00:54 UTC

**Objective:** Resolve the four continuity/status conflicts by merging latest `origin/main` into the Jordan documentation-review branch, preserving all upstream Naomi/production work and the Jordan review. Do not alter the nine Jordan source files, runtime, SaveManager, clinical rules, or clinical approval state; keep PR #38 draft and do not merge it.

**Branch / base / checkpoint:** `biancaalexis132-png-jordan-vale-v2-review`, merged with `origin/main` `47a68f40b09423b3253091e25b4715ce82447113`. Merge commit `0279db890abb05483feb6b08463d63a738b51810` is pushed and verified by `git ls-remote`. PR #38 is open and draft; GitHub reports `MERGEABLE`, with `validate` pending on this head.

**Completed:** Resolved conflicts in `docs/AI_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/AI_SESSION_HANDOFF.md`, and `docs/PROJECT_STATUS.md`. Preserved Naomi character PR #37 and Elias/Rahman production package PR #39 additions from main, and corrected current status to show #35, #36, #37, and #39 merged. Naomi refinement remains independent. The Jordan `REVIEW.md` and all nine source package files are unchanged.

**Post-push verification:** The continuity checkpoint `3f162e3caee3739137ec0cf9df93f226dc72023c` is pushed and `git ls-remote` verified the exact SHA. PR #38 remains open/draft; GitHub reports `MERGEABLE`, and `validate` is pending on this head (run 39084612239). The next continuity update will advance the head and needs a fresh CI check.

**Validation on `0279db8`:** JSON syntax parse passed; `git show --check --oneline HEAD` passed; explicit nine-file comparison against `origin/docs/jordan-vale-v2` passed. Hosted PR #38 `validate` was pending on merge commit `0279db8` (run 39084497112) and is superseded by the latest run. Full local Godot QA was not run because this is a docs-only Jordan review/merge and no Jordan runtime or schema changed.

**Next exact steps:** 1) Push the continuity checkpoint and recheck the newest PR #38 validation/mergeability state. 2) Keep the PR draft and do not merge. 3) Owner resolves the canon/source/authority questions and a qualified psychiatrist reviews case-specific content before any schema/runtime proposal. No clinical content has been approved or activated.

## Jordan Vale CP-001 v2 clinical-content and implementation review — Copilot, 2026-10-18 00:37 UTC

**Objective:** Review the nine-file Jordan Vale CP-001 v2 case package as documentation only. Identify content/provenance gaps and implementation blockers; do not change the source package, activate content/rules, modify the runtime or SaveManager, or merge.

**Branch / base / checkpoint:** `biancaalexis132-png-jordan-vale-v2-review`, based on verified `origin/main` `03f1585a62bd33db7dcfe8116b50db71f8ee171b`. Review source is `origin/docs/jordan-vale-v2` `8131b240afd77710b277f010b8b096c1a6b684d2`, merged by PR #36. Report commit `7876d53317da79b375a33ae06a2b66020928dc9b` and continuity checkpoint `16d55f64af6e2139e509b4ed9810fa462150e423` are pushed and `git ls-remote` verified. Draft PR #38 to `main` is open.

**GitHub state:** PR #36 (Jordan package), #35 (Naomi acting cues), and #34 (campaign screenplay package) are merged. Before this review PR was opened, `gh pr list --state open` returned no open PRs; the draft review PR is now open. This main state is later than the `fb07887` base cited by older handoff/status text. The PR #35 acting-cue work is merged; a separate Naomi character pipeline remains active on `biancaalexis132-png-naomi-character-pipeline` at fetched remote `2a6ffda5e580c551b0f2f235861960e0d7662657`. No Naomi model or cue files were touched; a scope note was sent to that session.

**Completed / findings:** Added `docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/REVIEW.md`. The report covers all nine source files, separates high-level owner-approved narrative direction from clinical approval, cites current canon/schema/save/ending evidence, ranks eight findings, and gives gated next steps. Main blockers: Chapter 1 still labels Jordan provisional/not canon; the referenced v1 package is absent from fetched refs/file history; the historical diagnosis source is not authored; all case dialogue/clinical content remains pending; current SaveManager is v3 and Continuing Practice has no runtime/schema/lifecycle; ending A/B/C state is still proposed; no CP validator exists. The report does not invent medical, risk, legal, or timeline facts.

**Source files:** All nine files at the reviewed source SHA remain unchanged. No patient data, clinical rules, executable content, SaveManager state, or runtime files changed.

**Review priorities and approvals:** Owner must resolve whether CP-001 is the same person as Chapter 1’s provisional Jordan and correct missing v1/source provenance. A qualified psychiatrist must review the exact clinical material, symptom prompts, consent language, and any safety/escalation scope. Owner review is separately required for legal setting, player authority, canon, and the gameplay contract. All content remains pending. No diagnosis, risk conclusion, legal status, or treatment effect is approved.

**Validation:** `python3 -m json.tool docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/case_cp001_v2.json` passed syntax parsing; this is not schema validation. Existing `ContentValidator` does not load the proposal JSON and there is no CP schema validator. `git show --check` passed on the review and continuity checkpoints; `git diff --check` passed. Hosted PR #38 `validate` check passed in 3m50s on `b79ea11d675f40aeee3420676890e4a3ba8bcd7f` (https://github.com/biancaalexis132-png/ForensicWard_Game/actions/runs/39083958547/job/117546508688). Full local Godot QA was not run because changes are documentation-only. The CI run is not clinical validation.

**Next exact steps:**
1. Push the CI-result handoff update and verify the exact branch SHA with `git ls-remote origin refs/heads/biancaalexis132-png-jordan-vale-v2-review`; confirm the PR remains draft and its current hosted check is green.
2. Owner resolves identity/source questions; psychiatrist reviews case content and completes section-specific signoff before any schema/runtime PR. Never merge.
3. Keep later work gated: documentation/canon corrections; separate case-schema/validator PR; approved consolidated v3→v4 design across CP/finale/protagonist; lifecycle tests; content activation only after approvals.

**Constraints / coordination:** Keep the supernatural and clinical domains independent; Ward Zero cannot change diagnosis, treatment, case access, or eligibility. Preserve access across endings and profiles. Naomi CP lines are proposals only and remain separate from acting/model work. Report and continuity checkpoints through `b79ea11d675f40aeee3420676890e4a3ba8bcd7f` are pushed and verified; CI-result notes are the current documentation-only follow-up and are not yet pushed.
## Naomi 3D character base — Copilot, 2026-10-18

- **Last updated:** 2026-10-18 00:43 UTC
- **Objective:** provide an automated Blender 5.2.2 / MPFB2 2.0.18 builder and a real, editable Naomi base with exact provenance and Godot import validation; do not call the base a finished realistic character.
- **Branch / checkpoint:** `biancaalexis132-png-naomi-character-pipeline`, based on `origin/main` `29f1e3386ffe0f0907ef698859fa27c05da9b9d8`, with current `origin/main` `21205c3c71d4543a2fa4abe0d54e172ce725db01` merged. Tested code checkpoint `2a6ffda5e580c551b0f2f235861960e0d7662657` and the documentation checkpoint `ff1b4059f5d728d37c24fe47762ecb7bff8948fd` are pushed and verified. Draft PR #37 is open against `main`; do not merge.
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
## Codex Naomi v06 independent validation — 2026-10-18

Dedicated additive workstream handoff: `docs/handoffs/2026-10-18_codex_naomi_v06_validation.md`.
Branch `codex/naomi-v06-validation`; implementation `3621ae1e679577c50009dc1f1837d2b5600b9e6e`
was pushed and confirmed by `git ls-remote`. Both actual GLBs audited: plain
v06 lacks 22 visemes; v06_mpfb contains them. No controller, preview, asset or
other agent's branch changed. Matching Blender and Mac review remain blocked;
see newest AI_HANDOFF entry for exact tests and PR checkpoint. Next task: source
inspection in production Blender, then coordinate explicit v06_mpfb preview
with the preview owner before Mac capture. All other entries are preserved.

### Codex source-validation continuation

Implementation `0d6e36989019a7dea4d59484b6b514ca8caafaca` pushed and verified on
the original branch; PR #64 then merged without this new increment. Source work
continues on `codex/naomi-v06-validation-cont-1` for a new draft PR. Official bpy 5.2.2 with Python 3.13 resolves
the source-opening obstacle: ten packed textures load and ten clips animate
finite geometry in each file; originals unchanged. Source test suite 4/0.
Diagnostic stills show significant lid-rim and hem defects, so readiness is
still blocked. Reports and reproducible stills: `docs/handoffs/naomi_v06_source_review/`.
Owner confirmed all other sessions stopped. Next task: version significant fixes,
then explicit MPFB preview and Mac validation. No existing asset/controller
was edited. Final tests and remote checkpoint are in the newest AI_HANDOFF entry.
