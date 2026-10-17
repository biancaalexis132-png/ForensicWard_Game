# AI session handoff (living document)

Updated 2026-10-17 · Codex · P1 / approved character canon / opening and Elias review.

## Screenplay audit milestone — 2026-10-17

Active branch `codex/screenplay-continuity-review`, stacked on verified `30e13f87f64e46c152dad2034a2a8c2c3e152dc6`. Owner merged PR #30: main `052859a984d7db599282914cbc300cc8cecc887b`; source `2e3863e16d882560dde87ba3bf018c5b6a29016d`. All 11 files reviewed; `docs/design/FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md` completed with chapter-by-chapter findings, detailed Elias comparison, owner decision matrix and small PR sequence. Claimed: new screenplay audit and own continuity updates only; package and application files remain unchanged. Next: finish full QA, verify docs/package preservation, push final review checkpoint; owner reviews N1 cue gate/presentation before runtime edits. Clinical flags remain pending. Prior full QA passed; package ten-payload byte counts/SHA256 all match; whitespace check passed; current TestRunner 131/0 and boot OK, audio/full sequence still running. API PR inventory remains blocked. Earlier full-screenplay-missing statements below are historical, superseded by PR #30.

## Previous objective and exact stopping point

Authorized work is complete for review: P1 pure catalog/profile validation; PR #27 conflict resolution; D1–D3 canon and minimal metadata reconciliation; six corrected character reference candidates/provenance; Chapter 1 opening alignment and Elias screenplay-summary comparison; permanent shared continuity rules. Final full QA passed. Current action is merging the synchronized P1 documentation checkpoint into this stacked branch and saving final verified remote state. No new implementation is started.

## Branches and verified remote checkpoints

- Active branch: `codex/character-canon-opening-cont-1`, stacked on **`codex/protagonist-schema-p1`**. Target a canon/docs/reference draft PR to that P1 branch to keep its scope separate; P1 targets main. Do not create a duplicate if the owner already opened one.
- Latest verified canon/reference remote checkpoint before this final merge: **`25a4dfe9a52a4a36d39ab52fdeea4de696d6a428`** “Save six corrected character reference candidates with provenance”. A final docs-only merge/checkpoint follows it; resolve its tip using `git ls-remote origin refs/heads/codex/character-canon-opening-cont-1`.
- P1 final verified remote: **`74715227bf5581b09a3b2746870082576fffe71f`**; implementation originated at `16b9761d8528f807caa8f10d76fcfeb9db7b5683`, then main sync `97580bf4a92f0ba5ebc8f7e6aea6b25854208cf8`. P1 import and both pre/post-sync TestRunner runs passed 131/0.
- Latest verified main: **`6d2dd2d3ec1bebf3624a706da2f864efd711206e`**, owner’s PR #27 merge. PR #29 previously merged P0 at `dd247be`. No agent main push or PR merge.
- Owner-confirmed PR #27: https://github.com/biancaalexis132-png/ForensicWard_Game/pull/27. Conflicts fixed and original branch ordinary fast-forward push verified at **`412b5010c8ccd8ba0e19e983b4346b5d90482d34`**, subsequently merged by owner.
- New draft PR creation is blocked: `gh pr create --draft` returned `Post https://api.github.com/graphql: Forbidden`. Enforced runtime policy lacks `api.github.com`; Git fetch/push works. A domain requirement is already saved in cloud draft, not applied. Do not request duplicate credentials or bypass proxy. New PR/review/hosted CI inventory remains unverified.

## Last completed milestones and files

### P1 — implemented, no runtime integration

`ProtagonistSchemas` / `ProtagonistValidator` (`scripts/protagonist/` + UIDs), `scripts/tests/test_protagonist.gd` + UID, synthetic fixtures under `scripts/tests/fixtures/protagonist/`, `docs/design/PROTAGONIST_INPUT_CONTRACT.md`, proposal/ID docs. Strict fixed psychiatrist role, optional selections, category-specific globally unique IDs, exact versions, Unicode/length/shape/pronoun validation; inputs and run state unchanged. No production option catalog, ContentRegistry hook, autoload/provider, creator UI, personality meter, save version or migration. Current save remains v3.

### PR #27 — conflicts resolved and merged by owner

Continuity add/add conflicts preserved both soundtrack and visual/protagonist records; append-only logs retained. Subsequent main/PR #29 merge retained all work. One existing flaky audio assertion was diagnosed: a 3.4s clip took 3.466–3.804s to free under Dummy audio. Bounded actual-player cleanup wait replaced the fixed 3.6s wait, retaining leak/object-count checks; no runtime sound behavior changed. This fix is now on main via PR #27.

### D1–D3 canon — recorded, not blanket visual/clinical approval

Owner’s exact decision record: `docs/design/decisions/2026-10-17_CHARACTER_IDENTITIES_APPROVAL.md`. Authoritative `CHARACTER_VISUAL_CANON.md`, `CHARACTER_REFERENCE_REGENERATION.md`, GDD amendments and dated addendum to `VISUAL_PRODUCTION_REVIEW.md`. Reference README marks six legacy individual portraits superseded as production references, preserving originals. `audio/voice_profiles.json` changes **only** Rahman’s direction from Clinical pharmacist to Consultant psychiatrist; voice `af_aoede`, speed/language/FX/recordings/IDs unchanged. Hale staff title already correct; no speculative Rahman staff entry/permissions/trust/intro added.

Six candidate sheets plus `.gdignore`, README, exact prompts and SHA-256/dimensions/source-hash manifest: `assets/creative_references/Visual_References/Individual_Characters/Regenerated_2026_10_17/`. Total 12,569,341 bytes. Four views/five expression studies visually inspected per sheet. Voss/Elias/Mara initial unsupported text/ID/property details corrected before packaging. Exact faces, costume/insignia details, age interpretation, technical scale/orthography/anatomy, rights and likeness remain owner/artist review. Not models, scene replacements or clinical findings. Original project portraits unchanged. Initial generated passes remain local `/workspace/generated_images` only; final candidates/prompts are recoverable from Git. Manifest identifies rejected initial output hashes; no need to recover those to continue.

### Opening and Elias — comparisons/proposals only

`docs/design/CHAPTER1_OPENING_ALIGNMENT.md` records approved hospital-drama opening and phased changes. Confirmed by isolated real-Main probe: acquiring `clue_access` can emit `ch1_w0b_unease` during day shift with zero Elias observations/notes. Proposed gating is **not implemented**. Preserve `beat_b6_intercom` day 1 + night + 15 in-game minutes, `pt_elias_ward`, beat IDs and provenance. No change to existing chapter scenes, dialogue, patient definitions, clinical rules or SaveManager.

`docs/design/ELIAS_EVALUATION_DRAFT_COMPARISON.md` maps exact existing keys, examination/MSE/risk/formulation gaps, missing assets and approval points. Owner confirmed full screenplay is in ChatGPT, not Git/PR, and will supply standalone text. Line-by-line review is deferred until supplied; current summary mapping is complete. Pending row added to `docs/clinical_review_log.md`; existing flags unchanged. No finding without exam, no mutism-as-refusal, no normal suicide-risk inference from silence, no symptom-causes-supernatural logic.

### Permanent continuity rules

`AGENTS.md` §9 and `CLAUDE.md` explicit both-agent scope supplement existing rules. Update living handoff/progress after every significant milestone/test/failure, before large work/PR, at warnings and before stopping; never finish multiple substantial tasks without a checkpoint. Verify remote SHA after coherent feature pushes. All historical append-only entries remain.

## Tests and evidence

Command from repo root: `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`.

- **Final combined QA:** exit **0**, `All executed checks passed`, tree with runtime/P1 content at `e585061111d3703318fae4655a675e1a2b9f0926`; only docs and Godot-ignored reference assets changed afterward. Python content 6/6, manifest 3/3, mock music client 3/3; pharmacology 0 failures; QA 19/0/0; GLB **138/138**; TestRunner **131/0**; main boot OK; audio **334/0**; complete Chapter 1 sequence at 63.7s. Log local `/tmp/forensic-final-merged-qa.log`.
- **Synchronized P1:** TestRunner **131/0**, exit 0, no script errors; `/tmp/forensic-p1-synced-tests.log`. Same P1 module/test bytes as final combined QA.
- **Asset integrity:** six PNG decodes, dimensions/byte counts, candidate hashes and original-source hashes verified; exact metadata diff proves only Rahman direction changes in voice profiles.
- **Opening diagnostic:** real-Main/public EvidenceManager probe confirmed the early unease trigger. Final isolated harness exit 0 without teardown errors; `/tmp/forensic-opening-probe.gd` and `.log` are local only. Reproduction logic is described in the opening proposal. Not a manual navigation/pacing check.
- `git diff --check` passed. No chapter/patient/dialogue/clinical-rule/save-manager/scene change relative to main. Expected negative-save warnings and nonfatal Python socket ResourceWarnings only.
- Earlier pre-#27 run reached gameplay 131/0 but audio 270/1 from the diagnosed old cleanup timer; superseded by merged fix and final pass, not hidden. Earlier PR #27 initial audio 333/1 likewise corrected and passed 334/0.
- Hosted CI unobserved. Mac Metal/rendering, mouse feel, listening, actual first-25-minute pacing, clinical correctness and memory/frame time are **not validated** by these checks.

## Approvals, dependencies and known blockers

Approved: D1 Rahman Consultant Psychiatrist; D2 Hale Security Director; D3 written casting authority (Bennett Black woman, Rahman South Asian woman); fixed psychiatrist protagonist, moderate personal life and emergent personality; realistic gradual opening direction; bounded P1 validation scope.

Pending: **D4–D9**, exact production faces/technical art/rights; Mara voice; full clinical screenplay and specific clinical findings/rules; F0 C2 Concordance/titles, C6 Bleed, C7 pharmacology clue gates, remaining C4 staff roles, C11 original music export and precise anomaly mechanism. No approval invented. Missing private v1.1 bible must be provided, not recreated. Stage 6/environment and soundtrack follow-ups remain their owners’ work; new geometry/cues/3D production not started.

API policy blocks PR automation; apply saved `api.github.com` setting through supported environment configuration, then retry existing auth. Godot 4.7 is installed outside checkout at the command path above; system `godot` is 4.6.3 and is rejected by the runner. No persistent service required. Installation/start instructions are saved in the environment draft; publication not claimed.

## Repository state and exact resume steps

All intended code/docs/reference assets are committed/pushed at the verified checkpoints above; the final documentation merge/checkpoint must be verified before ending. No app implementation remains half-written. Ignored `.godot` cache retained; no temporary/macOS/secret files committed. Exact current tip is obtained via `git ls-remote`; this file cannot contain its own commit SHA.

1. Read AGENTS, CLAUDE, this handoff, progress/status and newest append-only entry. `git fetch origin refs/heads/main:refs/remotes/origin/main`; compare before editing. Do not reset/rewrite existing commits.
2. Check `git status --short`, `git ls-files -u`, and `git merge-tree --write-tree HEAD origin/main`; there should be no pending conflicts after final checkpoint. Verify both feature remote SHAs with `git ls-remote`.
3. Review P1 as a small PR to main. Review canon/continuity/reference/opening docs as a stacked PR to `codex/protagonist-schema-p1` (or retarget after P1 merges). Prepared descriptions are local `/workspace/p1-protagonist-pr.md` and `/workspace/canon-opening-pr.md`; committed changes/handoff contain enough to reconstruct them. If API is still blocked, report it; do not invent a PR URL or duplicate owner-created PR.
4. Owner reviews candidate faces/wardrobe and technical cleanup, D4–D9 and opening implementation slices. Do not swap models or implement the proposed early-unease gate without the relevant reviewed change scope.
5. When standalone Elias screenplay arrives, compare its actual lines to the stable IDs/paths in `ELIAS_EVALUATION_DRAFT_COMPARISON.md`. Keep clinical flags pending until explicit item approval; update the clinical review log only with genuine owner review.
6. P2 provider/v4 migration is a future bounded task: capture a real v3 save first, preserve v1/v2/v3 compatibility and preflight atomic validation. Do not start a major persistence rewrite or derive personality classes/clinical competence from background.
7. Continue checkpointing before new substantial tasks; owner merges all PRs. End with the CODEX SESSION HANDOFF fields and verified remote SHA.

## Preserved soundtrack workstream record

The following original record is retained for its owner; historical “PR open” wording is superseded by verified owner merge #27 above. Listening/licence and zone/cue follow-ups still require their own review.

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
