# AI session handoff (living document)

Updated2026-10-17 · Codex · Ch2/Ch3 controlled-inspection proposal.

## Current workstream and exact stopping point

`docs/design/CHAPTER2_3_INSPECTION_CONTINUATION_SPEC.md` is complete for review: summary-level Ch2 institutional/Ch3 inspection crosswalk, Ch4 reveal conflict, F2 gaps, bounded deterministic repeated-junction design, lawful safe return/recovery, independent-source logging/replay, save/performance/accessibility requirements and small PRs. GDD records only the approved Ch3 first-entry premise. No runtime/effect/clinical/script replacement.

Owner confirms expanded manuscripts exist only in ChatGPT; revised files will follow. Do not ask again for their Git path or claim line-by-line review. Mandatory evidence/care remain independent of Mara disclosure, rapport/personality, diagnosis, treatment or Bleed.

## Branches, PRs and verified remote state

- Active `codex/chapter3-inspection-spec`, initially from screenplay **0ead6cbd79710577852ab9a79522a5a61b960a46**. Latest verified inspection remote **8cff9bcfc15956cb2828b2ff783b7ebcb7c5031e** (ordinary merge preserving both documentation histories); final handoff commit follows. Get exact final tip with `git ls-remote origin refs/heads/codex/chapter3-inspection-spec`.
- Draft PR32 https://github.com/biancaalexis132-png/ForensicWard_Game/pull/32, base `codex/screenplay-continuity-review`. GitHub API works; old blocked notes are historical. No agent PR merge/main push.
- Owner merged Naomi PR31 into **screenplay branch**, not main, at **78d0d8a4aaa84f6c92aa377f0381ccabfcd4b391**; this base is merged normally into inspection branch. Source Naomi **58ea1077d76a39b7d703243732201149155a1ebf**. Shared doc conflicts resolved preserving both histories; no runtime conflicts. Proposal/implementation approval gates remain: merge is not a claim that modeling was approved.
- Main remains **052859a984d7db599282914cbc300cc8cecc887b**, owner PR30. PR27/29 also merged previously. P1 validation source **74715227bf5581b09a3b2746870082576fffe71f**, no runtime creator/provider/save bump.

## Files, ownership and completed work

Current new spec plus `GDD_AMENDMENTS.md` and four continuity/status files only. Runtime/package preservation diff from8e30681 passed. No asset/model/audio/scene/clinical/save code claimed or changed. No half-written implementation; ignored local QA caches/logs not committed.

Naomi remains a separate production workstream: `docs/design/CHARACTER_PRODUCTION_NAOMI_FIRST.md`, fully proposed workflow;138 GLBs have no skins/animations/morphs, current people capsules;2D portraits are not models. Ten environment Blender sources5.0 incompatible with installed4.3.2; internal rigs not verified. Requires approved technical reference/face/resource licensing/art support, compatible Blender, rig/morph/clip sources and actual Mac profiling. No substantial modeling started.

Mara Ch2 recurring introduction, agency and clinical-investigative independence are approved; `CHAPTER2_MARA_IMPLEMENTATION_CROSSWALK.md` preserves owner-provided anchors, complete prior clinical source still missing. D1–D3 roles/casting approved; exact clinical rules/dialogue remain pending. Previous full audit and reference provenance remain on base, not duplicated as new inspection work.

## Tests and evidence

Current standard command: `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`, log `/tmp/forensic-inspection-spec-qa.log`, session96137. Python6+3+3, pharmacology0 failures, QA19/0/0, GLB138/138, gameplay131/0, boot OK, audio334/0 so far; final Chapter1 sequence61.0s completed; **runner exit0, all executed checks passed**. Same runtime bytes from start checkpoint8e30681 through final docs; no untested runtime merge.

Earlier Naomi run audio333/1 at existing cinematic-resume fixed1.6s assertion, reduced public-API probe resumed after1015ms; no root cause established or test/audio change. Current audio pass does not erase that intermittent failure. Whitespace/runtime preservation/conflict checks passed. Hosted CI not observed; Mac/clinical correctness/new proposed inspection behavior and safe-return invariants are not implemented or tested.

## Approvals and dependencies

Approved: Ch3 first actual WardZero entry through authorized Security/Facilities inspection; Mara placement/agency/care independence; existing roles/casting and clinical-realism separation. Pending: exact revised scripts, Ch3 discrepancy vs Ch4 reveal, repeat limit/presentation and safety/re-entry policy, source facts/controls/claim independence, F3/C6/C7 decisions, durable event/save contract, D4–D9/Stage6 geometry/anchors and clinical material. EvidenceManager's method strings do not prove independence; F2 successful transitions do not yet provide failure-safe inspection rollback.

Do not turn the proposed safety/spec tests into approval of an anomaly. No narrative or clinical rule is activated. Missing private bible/dossier/Blender source dependencies must be supplied, not recreated. Correct Godot4.7 installed under `/workspace/.tools`; local Blender4.3.2 not source-ready.

## Exact next task

1. QA complete. Verify final handoff commit/push using ls-remote (no uncommitted app work). Before any new work fetch main/base and check PR32 reviews/active file claims; never reset/rewrite shared history.
2. Owner reviews spec N1–N6. Receive revised Ch2/3 files for actual line-by-line comparison; keep existing manuscripts intact until reviewed.
3. Earliest bounded future engineering PR only after N3 review: pure route-graph/safety contract validator with synthetic non-anomaly fixtures, disabled/inert integration. No approved effect implementation yet. Then production-approved non-supernatural route lab and source/replay contract separately; preserve F1/F2/save versions until bounded review.
4. Naomi separately: review production proposal P1 technical-reference/licensing route before substantial model work; don't depend on full cast production to review inspection logic. Coordinate geometry/audio/scene owners before runtime changes.
5. Maintain checkpoints each milestone, keep AI_HANDOFF append-only, feature pushes verified; owner alone merges. Include exact current SHA/test result in final report.

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
