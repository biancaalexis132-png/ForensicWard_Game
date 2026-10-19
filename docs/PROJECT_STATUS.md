# Project status

**Owner approvals and content gaps (Claude Code, 2026-10-19; draft PR, not merged):** `claude/owner-approvals-content-gaps` code `04fdb8c`. Bi approved all cast models and the narrative review, and chose "Approve all" for the catatonia rule, Elias dialogue, Mara record and Chapter 2 work items. Chapters 1–5 are no longer provisional. Content gaps filled: Chapter 2's closing personal message and fade-out, and Chapter 4's optional Mara follow-up (Scene 04, wording pending clinical review) and personal call (Scene 06). New `next_interaction` story option. Full QA passed: game 293/0, GLB 168/0, audio 412/0. Chapter 3's optional Mara follow-up was not built because it has no screenplay lines. Mac not run. See `docs/handoffs/2026-10-19_claude_approvals_content_gaps.md`.

**Nursing-station counter usability (Codex, 2026-10-19):** following the owner’s merge of cast PR #98, Naomi can now be approached through a designated public counter talk point in all five chapters, as well as from inside the station. Her existing story event and access grants are preserved; the physical barrier remains. Regression results and branch are in the newest `docs/AI_HANDOFF.md` entry; review screenshot/tool and details in `docs/CAMPAIGN_CAST_INTEGRATION.md`. No approved illustration, voice or GLB bytes changed. Existing model appearance/Mac acceptance and provisional campaign review remain pending. Changes stay on `codex/nursing-counter-interaction` for owner review; no automatic merge.

**Campaign 3D cast integration (Codex, 2026-10-19; draft PR #98):** owner explicitly requested integration after narration. The seven existing animated cast models now load in normal gameplay across Chapters 1–5 through `data/character_visuals.json`; preview arguments are optional overrides. Facing and whole-actor placement are corrected, hidden alternate characters stop inherited rig processing, and save/story/clinical state is unchanged. Five focused tests pass, including physical player-ray/input progression; full local game suite **285/0**. Seven real in-engine portraits plus two seated side views are included, with software-renderer limitations documented. No GLB or approved cutscene illustration bytes changed. Model likeness/quality remains pending owner visual acceptance and Mac performance review. See `docs/CAMPAIGN_CAST_INTEGRATION.md`; Audio **412/0**, local Chapter 1 sequence complete, and hosted standard validation passed on `515cced048d48b1dcf0ab1b6d342f6fd3c1fa5ba`: https://github.com/biancaalexis132-png/ForensicWard_Game/actions/runs/39321295781 . Exact results are in the latest handoff. No automatic merge.

**Narrated recap delivery (Codex, 2026-10-19; PR #96 merged into main):** owner approved the 18-second local Piper LJ Speech replacement voice/pacing sample with “yes”. All 38 recordings, measured subtitles/SRTs, five chapter scripts, three Chapter 5 ending narrations, provenance and an offline panel listening page are included. The existing CutsceneDirector/AudioDirector and chapter-completion flow are preserved. Asset gate: 38/38 voices, 36 unchanged approved illustration hashes, 0 errors. Recording/code checkpoint `8ebcf4cc949b37d5d49d41d6230d46d34f96933c`: local full gameplay 280/0 and shipped voice smoke 38/0; hosted standard validation succeeded, gameplay 280/0, audio 412/0, Chapter 1 sequence complete. Local standard game cap 150 seconds and separate audio cap 120 seconds timed out; hosted complete results are documented in `docs/narration/TEST_RESULTS.md`. ElevenLabs blockers are superseded; no ElevenLabs recording is shipped. Start with `START_HERE_NARRATION.md`; placement guide `docs/NARRATED_CUTSCENES.md`. This is a Godot source-project delivery. At the narration checkpoint, normal gameplay still used placeholders; the newer cast-integration entry above supersedes that limitation. Model visual acceptance, provisional campaign acceptance, Mac visuals/performance and full artistic mix review remain pending. PR #96 was merged externally into main at `fe1a4bd1308c35d96d9150c2dbc941b89c040fc9`; the agent did not merge it. Hosted validation passed on the merged main commit: https://github.com/biancaalexis132-png/ForensicWard_Game/actions/runs/39316498592 .

**Narration audit / approval checkpoint (Codex, 2026-10-19; draft PR #95):** fetched main `2779875` includes approved 36-panel chapter-close recaps and playable campaign logic for Chapters 1–5 (2–5 provisional). Several historical unmerged/planned rows below are stale. Chapter 1 voice audition generated; owner voice/pacing/writing approval pending. Narration runtime and realistic cast integration remain incomplete; normal gameplay still uses character placeholders. All art hashes preserved. See `docs/narration_review/REVIEW_AND_PLAYBACK_GUIDE.md` and `TEST_RESULTS.md`. No automatic merge.

**Static graphic-novel chapter recaps (Claude Code, 2026-10-19; not merged):** `claude/static-graphic-novel-cutscenes` runtime `bac05fe`. Owner-approved Static Graphic-Novel Cutscenes Final v1 art (36 panels, byte-identical) plays through CutsceneDirector as `cs_ch01..05_static_gn`, a recap when each chapter is completed (owner's placement choice). Static panels, existing music, no dialogue, no character animation. Title cards and the Ch1 pilot unchanged. Full QA passed: game 266/0. Mac not run. See `docs/CUTSCENES.md` and `docs/handoffs/2026-10-19_claude_static_graphic_novel.md`.

**Cast draft models (Claude Code, 2026-10-19; not merged):** `claude/cast-models` runtime `5316d36`. Voss, Hale, Rahman, the facilities technician, Elias and Mara (seated) built from the MPFB bases with Naomi's rig, the ten shared clips and her 32 face morphs; review-only preview `--character-preview=<id>` (`v01_draft`). Full QA passed: game 251/0, GLB 168/0. Not approved; hair is a painted shell, clothes are offset shells, Mac unmeasured. See `docs/handoffs/2026-10-19_claude_cast_models.md`.

**Naomi v07 (Claude Code, 2026-10-19; merged in PR #84):** `claude/naomi-v07-refine` runtime `2707a37e3387cfcea253882f8fbead9eaf9e8773`. v06_mpfb with straight trouser hems, rounder shoes, no wavy rim on closed lids and a lash line that follows the lid; same rig, 10 clips, 32 morphs. Gestures cast a moving shadow from the nearest light. Preview default v07. Full QA passed: game 234/0, GLB 162/0. Not approved; Mac frame time and look unmeasured. See `docs/handoffs/2026-10-19_claude_naomi_v07.md`.
**Chapter 3 Scenes 01-02 notice and briefing (Claude Code, 2026-10-19; merged to main):** runtime `4c1bb95df4dc22781005a335222398a3e836b845`. Chapter 3 marked playable (campaign) with new story_chapter3.json/world_chapter3.json. Chapter 2 next_chapter ch3; a story choice that completes a chapter now offers 'Return for the next day shift' (ChapterDirector), and NS_Clock is Chapter 2's sign-out so completed saves can continue. Bennett's inspection notice: coverage, audit summary and clinical scope all required (leaving uncovered is refuse Mac not run.

**Chapter 3 Scenes 03-04 descent and first Ward Zero entry (Claude Code, 2026-10-19; merged to main):** runtime `2151b58662236e548d507a853eb1c400d42fd5fc`. zone_ward_zero built (7 Stage 6 environments, bounds x -6.7..6.7, z -9.5..10.2 on the sublevel) and conn_w0_threshold (fade, required access access_w0_threshold) from SC_BrickInfill to the threshold (return point W0T_Radiator). Hale's team pass grants access_ward_entry + access_maintenance; the screenplay's service elevator is staged as the Facilities hatch and stair because the restricted lift's  Mac not run.

**Chapter 3 Scenes 05-08 alcove, route check and safe return (Claude Code, 2026-10-19; merged to main):** runtime `aee2b95bd353bf60b649e3485be5eadd497880f4`. Data only. Alcove at W0C_Radiator_0 (compare plans / request survey / preserve discrepancy; 'the alcove has moved' feedback-only). Route concern and holding point at W0C_ClockA ('we've come round in a loop' and splitting up refused; flags ch3_route_paused = inspection_paused_for_route_check, ch3_ambiguity_recorded). Safe return through the threshold, stair and ward entry; Hale's 'return the team p Mac not run.

**Chapter 3 Scenes 09-14 debrief to closing photograph (Claude Code, 2026-10-19; merged to main):** runtime `095fef19331e8b72891d0027f2b7346274712b3c`. Data only. Hale debrief (repeat-corridor and merged-account refused; 'We shouldn't call that a physical loop.'), Bennett back-to-care, Facilities survey proposal at the office workstation (repeat entry refused), measurements at the Records worksheet (unresolved, protocol, restriction all required; 'longer than built' refused), Voss report (averaging refused), closing notice (photograph as proof re Mac not run.

**Chapter 4 Scenes 01-03 and 05 official record (Claude Code, 2026-10-19; merged to main):** runtime `e17fa49fb6b9665ac8f15d43990188620ba3a048`. Chapter 4 marked playable; story_chapter3 next_chapter ch4. New staff_rahman (Dr Leila Rahman, Consultant Psychiatrist, owner-confirmed role 2026-10-18) at the office desk; Hale at Interview Room A's door. Voss meeting (combined case refused; transparent / restrictions / outside expertise), summary correction at the office workstation (mapping error and anomalous geometry refused; contradiction wi Mac not run.

**Chapter 4 Scenes 07-08 (Claude Code, 2026-10-19; merged to main):** runtime `daca017`. Hale test pass and Corridor_CCTV_5 check (repeatability open), pass returned; Voss disagreement, holding safety notification refused. TestRunner now fails runs on unloadable test files (verified with a deliberately broken file: 252 passed, 1 failed). Mac not run.

**Chapter 4 Scenes 09-10 (Claude Code, 2026-10-19; merged to main):** runtime `ec4d3d4`. Owner approved the bounded loop. Hale's controlled inspection (team pass, ops contact refused-shortcut) returns to the Ward Zero corridor; panel 17 logged on separate sheets at W0C_Radiator_0, seen again at W0C_ClockA; keep-walking refused; any of compare/stop/analyst sets observed_repetition_unverified and fires a new safe_return beat action (fades out through conn_w0_threshold only while in zone Mac not run.

**Chapter 5 finale (Claude Code, 2026-10-19; merged to main):** runtime `e545408`. ch5 playable (ch4 next_chapter=ch5). Scenes 01-07 and 09-10 built: return inspection with team pass, two-state door preserved (opening refused), records review (single culprit refused), analyst report (supernatural mechanism refused), Bennett care escalation (waiting refused), four-source test (double counting refused), decision with three endings (delaying report refused), ending epilogue, rounds Mac not run.

**Chapter 5 Scene 08 (Mara) (Claude Code, 2026-10-19; merged to main):** runtime `1fdaa90`. Owner: 'i agree with the patiient content that is approved'. Mara replaces Elias in Interview Room A after the decision; approaching her opens the story scene (Character._approach_patient skips the interview when ChapterDirector.has_open_interaction). Suggesting the records explain her health is refused; two answers (answer first or listen first) use only screenplay lines. Epilogues now follow Mar Mac not run.

**Campaign finish (Claude Code, 2026-10-19; not merged):** runtime `3f50abe`. Owner chose 'Campaign finish'. New optional story key campaign_end (schema + validator: last chapter only; line conditions checked). After Chapter 5's final choice the panel shows Bennett's line then 'What the record shows' with the lines that apply (ending, Ch4 unverified repetition, source count, Mara, care). The three ending tests play Chapters 1-5 and check the summary. Owner: Mac check left n Mac not run.

**Chapter 2-5 title cutscenes (review-only) (Claude Code, 2026-10-19; not merged):** runtime `1b83671`. Owner said continue after campaign finish; next card option. Four review-only title cards (cs_ch02..05_title): 3 panels/20 s each, chapter title caption from campaign.json, no dialogue, environment plates painted by paint_panels.py (no character likeness; no early Ward Zero or loop reveal). approved false, manual_preview only; placement at chapter openings needs owner approval. Independent of PR # Mac not run.

**Title cards play at chapter openings (Claude Code, 2026-10-19; not merged):** runtime `#91`. Bi approved the Chapter 2-5 title cards and their placement; they are now mode campaign, trigger chapter_start, approved true, and Main opens each one when its chapter starts (Esc skips). The Chapter 1 pilot stays review-only. Mac not run.

**Title screen (Claude Code, 2026-10-19; not merged):** runtime `pending`. Title screen at boot (Continue from the pause menu's save slot, New Game, Quit). Shown only when Main is the running scene in a window; tests, headless QA and preview arguments skip it. Writes no game state. Not visually checked here (no screenshot rendered in the container). Mac not run.

**Chapter 2 Scene 10 closing beat (Claude Code, 2026-10-19; not merged):** runtime `1bb194df802b68591f9e7ab8a7939754e91bd8e3`. Chapter 2 now completes after Bennett's end-of-shift exchange; report states what the records cannot reconstruct. W0-B locked; Chapter 3 not started. Full QA passed: game 235/0. Mac not run.

**Chapter 2 Scene 09 wrong-day file (Claude Code, 2026-10-19; not merged):** runtime `1481c7ea32b8a5cb553d50529afd387e382f5898`. Export date conflict placed in the incident record, not Mara's note; one handling chosen; originals unchanged. Full QA passed: game 233/0. Mac not run.

**Chapter 2 Scene 08 escorted lobby inspection (Claude Code, 2026-10-19; not merged):** runtime `4669c7c387107584e6429cf79cb035194fcec0b5`. Scene-only ward-entry pass; lobby doors closed then ajar after an unwatched interval; pass returned; lift, lobby, hatch and W0-B stay locked. Full QA passed: game 229/0. Mac not run.

**Chapter 2 Scene 07 witness (Claude Code, 2026-10-19; not merged):** runtime `3a919c972c4cbac795dd72844567516dae68a04f`. Technician's recollection recorded as reported; no evidence or anomaly. Full QA passed: game224/0. Mac not run.

**Chapter 2 Scene 06 Hale (Claude Code, 2026-10-18; not merged):** runtime `ffd5730f9d6182d26f104f9d340fad566587fdb8`. Hale scopes the restricted-designation question and grants one permitted follow-up; no access or inspection. Full QA passed: game220/0. Mac not run.

**Chapter 2 Scene 05 analyst (Claude Code, 2026-10-18; PR #72, not merged):** runtime `0d298cfa7a557eeab11a0b265e203116012fe0ad`. Untested candidate explanations and one next check; discrepancy stays open. Full QA passed: game216/0. Mac not run.

**Chapter 2 Scene 03 Mara Ellis (Claude Code, 2026-10-18; not merged, PR #71):** owner-approved ("i approve scene 3"). Runtime `09e4a8cb45981dd0959c7dc6058b62bc870e0d58`: Mara interview through the existing dialogue system, EHR note, separate Records referral; Elias steps out of Interview Room A meanwhile. Dialogue APPROVED; patient record pending review. No diagnosis, medication, treatment or evidence. Full QA passed: game212/0, GLB161/0, audio336/0, QA19/0/0. Mac not run.

**Chapter 2 Scene 04 Voss review (Claude Code, 2026-10-18; not merged):** `claude/chapter2-voss-review` runtime `4796ca10fc6e070b1f119e1d2416af7104204780`, stacked on PR #70. Voss conversation records factual scope, missing permissions and an authorized follow-up through the existing staff actor; unsupported claims give feedback only. Source request, credential audit and W0-B restriction stay pending; no clinical finding, access, Mara content, Ward Zero entry or supernatural reveal. Full QA passed: game207/0, GLB161/0, audio336/0, QA19/0/0, Python6+4+5+3, pharmacology0 failures, boot and Chapter1 sequence. Narrative review and Chapter 2 Scenes 03, 05–10 remain. See `docs/handoffs/2026-10-18_claude_chapter2_voss_review.md`; Mac not run.

**Chapter 2 source-review continuation (2026-10-18; not merged):** `codex/chapter2-records-review` runtime `122304d460126f6645c9ce6afd63395e8e52ec32` adds six source-question/memo/handoff steps to owner-merged PR #69. Missing clock/order/lineage/custody questions stay explicit; unsupported inferences give feedback without progress. Two follow-up emphases preserve all outstanding questions. Existing clinical records and evidence remain separate; no raw export receipt, new patient finding, Mara interview, restricted access or supernatural conclusion is invented. Full QA passes: game203/0, GLB161/0, audio336/0, QA19/0/0, Python6+4+5+3, pharmacology0 failures, boot and Chapter1 sequence. Narrative review and the rest of Chapter2 remain pending. See `docs/handoffs/2026-10-18_codex_chapter2_records.md`; Mac/hosted CI not observed.

**Chapter 2 first playable opening (Codex, 2026-10-18; not merged):**
`codex/chapter2-opening` runtime `d4fead70db995b21d2de921d222d51eccd75ac72` implements explicit Chapter1→next-morning continuation, Naomi handoff, outstanding clinical-work ownership, unresolved records comparison, authorized source request and return acknowledgment in the real clinical wing. Saves rebuild the correct chapter wiring and retain prior state. This is the first opening slice, not complete Chapter2. Proposed text remains review-pending; no new patient findings, Mara interview, WardZero entry or supernatural reveal. Full QA passed: game196/0, GLB161/0, audio336/0, QA19/0/0, Python6+4+5+3, pharmacology0 failures, boot and Chapter1 sequence. Main PRs #67/#68 integrated. See `docs/handoffs/2026-10-18_codex_chapter2_opening.md`; Mac and hosted CI not observed here.

**PR #68 integration correction:** main `d262d92` (owner-merged viseme PR #67) is integrated on `codex/chapter1-zone-continuity` at `49d68bdfbcbf43c47352dd7cb8c0507cad453377`. Both documentation histories preserved; GitHub reports mergeable. Combined full QA passes: game189/0, GLB161/0, audio336/0, boot and Chapter1 sequence. Prior 179/0 is the historical pre-integration count. PR #68 remains draft and unmerged.

**Chapter 1 continuity (2026-10-18, draft PR #68):** location story conditions now follow actual zone transitions and existing zone save state. Full QA passed on `e13fb0cec0b501d566fec090b8c14aac55766254`: game179/0, GLB161/0, audio336/0, boot and Chapter1 sequence passed. Two new regressions reproduced the missing-location bug before fixing it. No campaign text, clinical facts, access gates or Naomi assets changed. Not merged; see `docs/handoffs/2026-10-18_codex_chapter1_zone_continuity.md`.

**Owner animation decision (2026-10-18):** "continue i approve of the animations so far".
Animations shown so far are approved. New dialogue-viseme work, full model
geometry/likeness, cutscene use and Mac performance are separate pending gates.
`codex/dialogue-viseme-integration` adds a deterministic text-based approximation
through the existing face/audio event lifecycle; see its dedicated handoff.

What each game system's state is, and where the evidence lives. Agents update this file whenever a system changes state (see `AGENTS.md` §7). Commit SHAs are what was on GitHub when the row was last checked. Anything not on GitHub is not listed as done.

**Naomi v06 correction (Codex, 2026-10-18):** fetched main `0c104b2` includes merged PRs #61–#63. Independent payload/Godot audit on pushed `codex/naomi-v06-validation` `3621ae1` finds plain v06 has ten stable morphs and **no visemes**, while v06_mpfb has all 32 expected morphs. Both have ten clips and valid exported weights. Runtime still drives mouth_open; preview has no v06 selector. Matching Blender source checks and all v06 Mac visual/performance checks remain unverified. Technical readiness and owner approval are not reached. See `docs/handoffs/2026-10-18_codex_naomi_v06_validation.md`; historical rows below are superseded for this candidate.

**Source-validation continuation:** pushed implementation `0d6e369` resolves the Blender-version obstacle using official bpy 5.2.2 / Python 3.13. PR #64 merged the earlier audit at `c09eb35`; the new source audit continues separately on `codex/naomi-v06-validation-cont-1`. Both originals open; ten packed textures decode per source, ten actions each have sampled pose motion and finite evaluated geometry; hashes unchanged. Four Blender integration regressions pass. Source body/hair weights need export normalization (GLBs are normalized). Source stills show significant wavy closed-lid rims and jagged hems; Mac checks, runtime viseme playback, explicit candidate preview and owner approval remain outstanding. See `docs/handoffs/naomi_v06_source_review/`.

**Last GitHub state verified:** 2026-10-18 14:15 UTC against `origin/main` `a202caf` (PR #45 merged). PR #44 (F3) then merged at `fec5933`. Open: draft PR #46 (Naomi review-only preview). Naomi v02 is viewable in game only with `-- --character-preview=staff_bennett`; it is not approved.

Earlier snapshot: verified against fetched `origin/main` `7e5bd2a1aad3b6189996c4b706ef6e42d4715ae7`. PR #43 (Ward Zero Stage 6) and PR #42 (optional character visual slot/fallback) are merged; PR #44 and Naomi draft PR #45 are open. Naomi v01 remains unapproved and not integrated. Versioned v02 candidate assets are generated on `biancaalexis132-png-naomi-model-refinement`, merged with this latest main; v02 is structurally valid but still fails visual review and is not ready for runtime integration.

Status meanings:

- **Completed:** merged to `main`, tests pass on `main`.
- **Done, not merged:** finished on a branch with an open PR; the owner has not merged it.
- **Active:** someone is working on it now; see `docs/AI_HANDOFF.md` for the branch and owner.
- **Blocked:** cannot proceed until the named thing happens.
- **Planned:** not started.
- **Untested:** exists, but the listed checks have not been executed.

Architecture and plan for all five chapters: `docs/F0_FOUNDATION_AUDIT.md` (approved by the owner on 2026-10-17). Owner decisions that amend the GDD: `docs/design/GDD_AMENDMENTS.md`. Id rules: `docs/ID_REGISTRY.md`.

## Pull requests

| PR | Branch | State |
|---|---|---|
| (new) | `claude/naomi-v05-refinement` | Draft, Naomi v05 brows, skin, blink, gaze, shoes and hems; preview default v05; not approved |
| #59 | `claude/cutscene-director` | Merged at `092ab64` (review-only CutsceneDirector and 7-panel Chapter 1 graphic-novel pilot; not approved, off in the campaign) |
| #53 | `claude/naomi-animation-v04` | Draft, Naomi v04 animation, face controls and the cast animation standard; preview default v04; supersedes #51; not approved |
| #51 | `claude/naomi-local-build` | Draft, Mac validation build `v04_local`; folded into `claude/naomi-animation-v04` |
| #49 | `claude/naomi-v03` | Merged (Naomi v03, development baseline only) |
| #48 | `claude/rahman-voice-profile-role` | Merged at `0fd2bc1` (Rahman voice direction: Consultant Psychiatrist) |
| #47 | `claude/naomi-preview-facing` | Merged at `c9655c7` (preview Naomi faces the counter) |
| #46 | `claude/naomi-review-preview` | Draft, review-only switch to view Naomi v02 at the nursing station |
| #45 | `biancaalexis132-png-naomi-model-refinement` | Merged at `a202caf` (Naomi v02 candidate; fails visual QA, not approved) |
| #44 | `claude/f3-anomaly-model` | Merged at `fec5933` (F3 anomaly model, flag off) |
| #43 | `claude/environment-stage-6` | Merged at `7e5bd2a` (Ward Zero rooms and anomaly states) |
| #42 | `biancaalexis132-png-cig-1-character-integration` | Merged at `de5cbfc` (optional character visual slot/fallback) |
| #41 | `docs/character-integration-gate-v1` | Merged at `8281b06` (CIG proposal and GLB preflight validator) |
| #40 | `docs/hale-mara-character-v1` | Merged at `64c3a2a` (Hale/Mara production specifications) |
| #38 | `biancaalexis132-png-jordan-vale-v2-review` | Merged at `cf62677` |
| #39 | `docs/character-production-batch-v1` | Merged at `3887b66` (Elias and Rahman production specifications; approval gates remain) |
| #37 | `biancaalexis132-png-naomi-character-pipeline` | Merged at `47a68f4` (Naomi base milestone; owner review/refinement remain) |
| #36 | `docs/jordan-vale-v2` | Merged at `03f1585` (Jordan Vale CP-001 v2 authoring package; clinical approval remains pending) |
| #35 | `biancaalexis132-png-naomi-chapter1-acting` | Merged at `21205c3` |
| #34 | `docs/complete-campaign-v1` | Merged at `a075d73` |
| #28 | `claude/visual-direction-review` | Merged at `fb07887`; review recommendations still need approval |
| #26 | `claude/f2-zones` | Merged at `9558c77` (zones and transitions) |
| #25, #24, #23 | `assets/ashcroft-creative-references` | Merged (continuity protocol / reference integration) |
| #22 | `assets/ashcroft-creative-references` | Merged (soundtrack and visual references) |
| #21 | `claude/f1-campaign-contract` | Merged (F1 campaign contract, save v2) |
| #20 | `claude/f0-foundation-audit` | Merged (F0 audit and architecture) |
| #19 | `claude/environment-stage-5` | Merged (Stage 5 historic substructure) |
| #18 | `claude/audio-production` | Merged (original soundtrack) |
| #17 | `claude/environment-stage-4b` | Merged (research wing) |
| #16 | `claude/remove-macos-metadata` | Closed, not merged (duplicate of #15) |
| #15 | `claude/remove-appledouble-metadata` | Merged (AppleDouble repair) |
| #14 | `claude/environment-stage-4` | Merged (security and admin wing) |
| #13 | `claude/nursing-station-props` | Merged |
| #12 | `claude/environment-stage-3` | Merged |
| #11 | `claude/integration-sprints-1-3` | Merged (Sprints 1–3, Blender Stages 1–2) |
| #10, #9 | `claude/sprint-03-evidence-shift`, `claude/sprint-02-ehr-interview` | Merged into the integration branch |
| #8, #7, #6, #1 | integration, chapter 1, environment, sprint 1 branches | Closed, superseded by #11 |
| #5, #4, #3, #2 | audio, handoff system, adaptive audio, Codex QA | Merged |

Remote branches may remain after merge. Branch existence alone does not prove active ownership. At this verification, PR #38 is the open review PR; historical soundtrack PR #27 and Stage 6 environment work must be checked before overlapping changes.

## Systems

| System | Status | Where | Evidence | Untested / caveats |
|---|---|---|---|---|
| Godot 4.7 project config | Completed | `main` | `project.godot`, features `4.7`, Forward+ | Forward+ on the owner's Mac not confirmed |
| EventBus and 14 autoloads (Settings, SaveManager, ContentRegistry, TimeManager, PatientManager, ClinicalRules, DialogueManager, EvidenceManager, TrustManager, WorldStateManager, GameState, PharmacologyEngine, AudioDirector) | Completed | `main` | TestRunner, TestQA | `GameState` is a compatibility layer (F0 C10) |
| Headless QA runner and CI | Completed | `main` | `tests/qa/run.py`, `.github/workflows/godot-validation.yml`; green on `33b2e8c` | |
| JSON content schemas and validator | Completed | `main` | `test_content.gd` | |
| Campaign contract: `data/campaign.json`, per-chapter story/world files, several dialogue files, id prefixes and cross-chapter uniqueness | Completed | `main` (PR #21) | `test_campaign.gd`, `test_content.gd` | Chapters 2–5 are `planned`; their stories exist only as test fixtures |
| Chapter-scoped story state (ChapterDirector) and save version 2 with v1 migration | Completed | `main` (PR #21) | `test_campaign.gd` (real v1 save captured from `main`) | |
| First-person controller, HUD, info panel, pause menu, accessibility toggles | Completed | `main` | `test_world.gd`, `test_state.gd` | Input feel, mouse recapture untested on Mac |
| Dialogue intent matcher and cinematic interview | Completed | `main` | `test_dialogue.gd`, `test_sprint2.gd` | Elias dialogue `clinical_review_status: PENDING` |
| EHR (census, summary, observations with provenance, notes, orders, audit) | Completed | `main` | `test_sprint2.gd` | No MAR/medication tab; observations have no polarity (unknown vs negative) yet |
| `ClinicalRules` governance (validated / prototype) | Completed | `main` | validated mode refuses pending rules (tested) | Both rules pending review |
| Pharmacology engine | Completed (clinically approved) | `main` | `TestPharmacology` | Not wired to the EHR; its clue gates conflict with the separation rule (F0 C7, owner decision pending) |
| Evidence board, clues, hypotheses | Completed | `main` | `test_sprint3.gd` | Clues carry `source_class` and `claim_state` on `claude/f3-anomaly-model` (F3) |
| Chapter 1 story director, sign-out, Bennett trust, after-hours W0-B beat | Completed | `main` | `test_sprint3.gd` | Beat 4 (second patient) not authored; staff lines are placeholders |
| Playable Chapter 1 wing (AuthoredWorld) | Completed | `main` | `test_world.gd`; 7 environments loaded at once | F2 is merged; built as the clinical-wing zone |
| Environment art Stages 1–3 (+ nursing station props) | Completed | `main` | `.glb` validation | Untextured |
| Environment Stage 4a security/admin, 4b research | Completed | `main` (PR #14, #17) | `.glb` validation | Reachable as zones on `main` (locked in Chapter 1); no characters or props wired |
| Environment Stage 5 historic substructure | Completed | `main` (PR #19) | 138/138 `.glb` import in Godot 4.7 | Reachable through the service hatch on `main` (locked in Chapter 1); the stair is a use-to-climb point, not walkable |
| Adaptive audio engine, Chapter 1 audio, original soundtrack | Completed | `main` (PR #3, #5, #18) | TestAudio 271 passed | Owner listening APPROVED for all 11 soundtrack tracks on 2026-10-18; PRIVATE / PERSONAL / NONCOMMERCIAL. Commercial licensing NOT VERIFIED / NOT REQUIRED FOR CURRENT SCOPE; review rights before public release. Other audio listening and runtime mix checks remain separate; see `docs/AUDIO.md`. |
| Hospital name in game data | Completed | `main` (PR #21) | `data/campaign.json` `institution.name` | Not shown on any screen yet; signage textures come with Stage 8 |
| Zones and transitions (F2): `data/zones.json`, `ZoneDirector`, save version 3 with v2 migration | Completed | `main` (PR #26) | `test_zones.gd` (15 tests: seamless ward entry, 10 lift round trips with flat memory, door state across unload/save/load, arrivals on a floor, real v2 save from `main`) | Worker-thread streaming is off in headless runs (Godot's dummy renderer is not thread-safe), so it is untested until run on the Mac; arrival points are placeholders; security and research use the corridor ambience |
| Naomi Chapter 1 acting-cue presentation | Completed on `main` (PR #35 merged) | `scripts/acting/NaomiActingController.gd`, `CharacterActingAdapter.gd`; wired only to `staff_bennett` | Merged PR #35; prior branch evidence: cue validator 5/5, TestRunner 122/0, TestAudio 336/0 | Real-model animation/face/gesture feel remains untested on Mac; separate Naomi model pipeline is a different workstream |
| Optional WardCharacter 3D visual slot and placeholder fallback | Completed on `main` (PR #42 merged at `de5cbfc`) | `scripts/world/Character.gd`, `scenes/props/Character.tscn`, `scripts/tests/test_character_visual.gd` | Historical Godot 4.7 TestRunner 127/0 covered fallback, scene attachment, dialogue, save/load and zone rebuild; GLB import validator 139/139 | No approved character model is attached; owner Mac render/performance review is untested |
| Continuing Practice / CP-001 Jordan v2 | Planned (authoring package merged by #36; design review on this branch) | `docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/` | `REVIEW.md` | No case schema, validator, loader, lifecycle or clinical rules; all case details remain pending review; current SaveManager is v3 |
| Naomi 3D character base and builder | Base merged (PR #37 at `47a68f4`); v02 candidate merged (PR #45 at `a202caf`), not approved | `tools/blender/characters/`, Naomi v02 Blender/GLB/renders and asset manifests | Blender 5.2.2 validator: 53 joints, 32,281 triangles, 3 embedded textures, 4 renders; CIG preflight: 15 meshes, 69 nodes, 1 skin, 0 animations; Godot 4.7 import validator 154/154; TestRunner 127/0 | v02 close render shows facial features but full-body views still read as one continuous lower garment with angular garment/skin boundaries; QA checklist fails. Owner appearance review, further procedural refinement, animation, LOD, runtime integration and target-device performance remain pending |
| Naomi in-game review preview | Completed on `main` (PR #46, facing in #47) | `scripts/world/CharacterVisualPreview.gd`, `scripts/tests/test_character_preview.gd`, `docs/design/characters/Naomi_Bennett_Character_Production_v1/NAOMI_INGAME_REVIEW.md` | TestRunner 131/0 and full QA exit 0 in a Linux container; in-game captures on software OpenGL | Off by default. Untested on Mac; no frame-time measurement. v02 fails appearance review in game too (hair strips, trousers, T-pose) |
| Naomi v03 visual-development candidate | Done, not merged (draft PR); not approved | `tools/blender/characters/build_naomi_v03.py`, `assets/exports/characters/Naomi_Bennett_v03.glb`, `NAOMI_V03_NOTES.md` | Blender 5.2.2 build, 44,692 triangles, 1 skin, 0 animations; Godot 4.7 import and in-game captures on software OpenGL | Far more realistic than v02 at counter distance; still no animation, facial shapes, groomed hair, simulated cloth or pore-level skin. Untested on Mac |
| Naomi v04 animation and face controls | Done, not merged (draft PR); not approved | `tools/character_animation/`, `scripts/world/{CharacterAnimationRig,CharacterFaceRig}.gd`, `assets/exports/characters/Naomi_Bennett_v04.glb` | Blender 5.2.2 build (10 clips, 10 morphs, 44,812 triangles); TestRunner 155/0; in-game captures on software OpenGL | Untested on Mac; no frame-time measurement. Skin still glossy, shoe/hem lumps remain, no gaze or lip sync |
| Naomi v05 refinement | Done, not merged (draft PR); not approved | `tools/character_animation/build_animated_character.py`, `scripts/world/CharacterGazeRig.gd`, `assets/exports/characters/Naomi_Bennett_v05.glb` | Blender 5.2.2 build (49,034 triangles); TestRunner 160/0; in-game captures on software OpenGL | Untested on Mac; static shadow fix for the v04 draw-call jump not yet measured |
| Elias and Rahman character production specifications | Merged as design package (PR #39 at `3887b66`) | `docs/design/characters/Elias_Ward_Character_Production_v1/`, `docs/design/characters/Rahman_Character_Production_v1/` | Production docs and review gates | Does not constitute clinical or canon approval, nor runtime integration |
| Anomaly evidence model and clinical/supernatural separation (F3): `data/anomalies.json`, `AnomalyLedger`, validator separation rules, clue `source_class` and `claim_state` | Done, not merged | `claude/f3-anomaly-model` | `test_anomaly.gd` (15 tests: flag off changes nothing, ledger on/off/removed give identical game state, Chapter 1 capped at reported, save/load without re-firing, no clinical signal connected, objectivity never reveals the anomaly, testimony never counts, validator rules) | Flag `forensic_ward/narrative/anomaly_enabled` ships off; Psychosomatic Bleed is presentation only (owner, 2026-10-17); pharmacology clue gates on PT-001 and PT-002 are reported at boot as known exceptions until F0 C7 is decided |
| Mara Ellis, Chapters 2–5 content, title screen | Planned | | v1.1 handoff | Clinical and narrative approval needed first |
| Environment Stage 6 Ward Zero (7 props, 7 rooms, swappable anomaly states) | Completed on `main` in PR #43 at `7e5bd2a` | `tools/blender/build_stage6_ward_zero.py`, `assets/exports/wardzero/**` | Godot 4.7 import validator now checks 154 assets with 0 failures on the Naomi refinement merge | Not wired into gameplay; anomaly states provisional pending owner review |
| Graphic-novel cutscenes: CutsceneDirector, registry, Chapter 1 pilot (7 panels, 52 s) | Done, not merged (draft PR); review-only, not approved | `scripts/cutscene/`, `data/cutscenes/`, `assets/cutscenes/`, `docs/CUTSCENES.md` | `test_cutscene.gd` (17), `tests/qa/test_cutscenes.py` | Mac Forward+ look, M1 frame time/memory and music mix not checked; no campaign trigger |
| Exterior (Stage 7), textures (Stage 8) | Planned | | `docs/ENVIRONMENT_STAGES.md` | |

## Blocked

| Item | Blocked on | Who can unblock |
|---|---|---|
| Clinical rules `clinical_rule_catatonia_escalation_v1`, `clinical_rule_medical_review_request_v1` as medical logic | Psychiatrist review | Owner |
| Elias Ward dialogue and EHR action wording | Psychiatrist review | Owner |
| Chapter 1 story lines in `data/story_chapter1.json` | Narrative and clinical review | Owner |
| Pharmacology clue gates (F0 C7), Psychosomatic Bleed (C6), Concordance thread (C2), player title (C3), staff roles (C4) | Owner decisions listed in F0 §9 | Owner |
| AI music (ACE-Step, Stable Audio) | The owner's Mac or a GPU, and a licence check | Owner |

## Untested on hardware

Headless checks do not cover these. They stay here until the owner confirms them on the Mac:

- Forward+ / Metal rendering, lighting and frame rate
- Input feel, mouse capture after Cmd + Tab
- Zone transitions: fade smoothness, hitch when a zone streams in, frame time and memory before and after (turn on the `perf_log` setting; it writes `user://perf_log.csv`)
- Audio mix, spatial audio, listening review of every asset
- Naomi base likeness, hair silhouette, scrub fit/deformation and acting quality; the 30 FPS / p95 33.3 ms budget has not been measured in the Chapter 1 scene
- Accessibility toggles in play (reduce motion, flicker off)
- Clinical correctness of anything marked pending

## Naomi Chapter 1 acting-cue workstream (merged in PR #35)

- The additive, model-independent presentation controller uses the source cue package at `docs/design/characters/Naomi_Acting_Cues_v1/`; it does not alter dialogue wording, IDs, story progression, clinical review status, gameplay, or save schema.
- PR #35 merged to `main` at `21205c3`; its adapter remains capability-driven and does not require MPFB bones.
- Focused validation: cue validator 5 IDs/voice mappings; TestRunner 122/0; TestAudio 336/0. The repository runner stops in music generation because local FFmpeg lacks `libvorbis` (music pipeline 1 passed/2 failed); subsequent suites were run directly on the merged Naomi model branch and passed. CI is not observed.
- The adapter is capability-driven and the current placeholder requires no clips, facial blend shapes, or named bones. Realistic-model playback/visual review remains for the owner on Mac. Do not modify the active Naomi model-builder branch from this workstream.

## Naomi 3D character base (merged base milestone; v02 refinement candidate)

- PR #37 merged to `main` at `47a68f4`; PR #42 later merged optional visual/fallback groundwork at `de5cbfc`. The procedural refinement branch is `biancaalexis132-png-naomi-model-refinement`, based on current main `7e5bd2a` and locally merged to `9a36b37`.
- Builder, configuration, validator and exact Mac commands live in `tools/blender/characters/`. v01 remains unchanged for comparison; v02 source/GLB and four renders are in the versioned paths documented in `assets/asset_manifest/naomi_character_manifest_v02.json`.
- Exact MPFB2 v2.0.18 inputs, CC0-1.0 asset-license evidence, GPL-3.0-or-later tool-code notice, female macro weights, output sizes and limitations are in the v02 manifest. No Mixamo or non-MPFB external assets were used. No gameplay, dialogue, clinical or save changes were made.
- v02 passes the Blender 5.2.2 validator: 53 joints, 32,281 triangles (45,000 budget), three embedded textures and four renders. CIG preflight reports 15 meshes, 69 nodes, one skin, zero animation clips, 11 materials and three textures. Godot 4.7 imported the branch merge and validated 154 assets with zero failures; TestRunner passed 127/0. Full `tests/qa/run.py` is blocked by two music-preview tests failing with local FFmpeg `Unknown encoder 'libvorbis'`.
- Repeated same-config builds produce byte-identical GLB and normalized render PNGs; Blender `.blend` container bytes may differ from internal serialization. Visual inspection shows facial details in the close view, but the full-body outfit still reads as one continuous lower garment and has angular garment/skin boundaries. The visual QA checklist fails; v02 is not ready for runtime integration. No photorealism claim is made.
- Owner appearance review, further procedural garment/mesh improvement, animation clips, LOD, Chapter 1 integration and target-device performance remain pending. Keep `staff_bennett`, dialogue and clinical review unchanged; do not attach v02 to the merged optional visual slot. Do not integrate CP-001 screenplay content with Naomi before its separate identity/canon and clinical gates clear.

## Codex continuation: protagonist specification and save QA

- Approved requirements: fixed psychiatrist role, customizable background/appearance, moderate personal life, emergent personality. Recorded in `docs/design/GDD_AMENDMENTS.md` from the owner’s current handoff.
- Proposed engineering plan: `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`; creator/provider/v4 migration are **not implemented** and require owner review.
- Baseline on `fb07887`: Python 6+3+3 passed; pharmacology 0 failures; QA 19 passed/0 failed/0 skipped; GLB 138/138; TestRunner 112/0; boot OK; audio 271/0; Chapter 1 sequence complete; runner exit 0. Headless Linux only; hosted CI not observed.
- Independent regression suite complete on feature branch `codex/protagonist-foundation-cont-1` at `01739ff`: four new tests; full runner exit 0, TestRunner 116/0 and all other baseline checks unchanged. No runtime/save schema/clinical/visual change. Not merged; PR creation blocked by API proxy denial. See session handoff.
- Missing source dependency: private v1.1 bible package is not accessible here or committed. Available GDD, engineering contract, PDF character guide and reference READMEs were inspected. No replacement canon is invented.
