# AI session handoff (living)

Updated2026-10-17 · Codex · Revised screenplays v2 technical review.

## Current task / stopping point

Complete for review: `docs/design/REVISED_SCREENPLAYS_V2_TECHNICAL_REVIEW.md` compares all five v2 files line by line in grouped dialogue/action/requirement ranges with PR30 manuscripts, F2, current campaign/save and clinical flags. Includes all12 acceptance-test mappings and safety/source foundations-first PR sequence. Original packages and runtime unchanged. Earlier `CHAPTER2_3_INSPECTION_CONTINUATION_SPEC.md` receives a dated availability/Ch3 no-geometry correction only.

Full standard QA **passed exit0**, including gameplay131/0, audio334/0 and Chapter1 sequence62.2s. Current action: final documentation checkpoint/push verification. Owner reviews R1 bounded contract scope before any runtime implementation. No major anomaly, clinical activation or model work.

## Verified repository and PRs

- Active `codex/revised-screenplays-v2-review`; latest verified review remote **6212d14c5249f65d59ca8d772702352472a4e950** before final docs. Final tip using `git ls-remote origin refs/heads/codex/revised-screenplays-v2-review`.
- Draft PR33 https://github.com/biancaalexis132-png/ForensicWard_Game/pull/33, base `codex/screenplay-continuity-review`; verified OPEN/draft. No agent merge/main push.
- Main/source **1dbd26a96288d7947ebd6a90b151ba1f6a0fc2a6** adds five files in `docs/design/screenplays/ForensicWard_Revised_Screenplays_v2/`; requested docs/revised-screenplays-v2 branch absent, no blocker. This docs commit does not approve manuscript or implement chapters.
- Owner merged PR32 into screenplay integration **ca7488980be3dd4d065810ae2f75cc6741727906**; PR31 Naomi proposal also merged into that branch. Review branch based there and ordinary-merged main, no conflicts/history rewrite. PR31/32 are not merged into main merely because main has v2. Existing P1/canon/reference dependencies remain on integration branch.
- GitHub API works; earlier access-blocked handoff entries historical. Hosted CI not claimed without inspection. Check latest PR/base state before edits; owner may merge while work proceeds.

## Findings and files claimed

Current new review, earlier spec addendum and four continuity/status docs only. No shared runtime/source-package/asset file claimed or edited. Source/runtime preservation diff from84257e2 and whitespace/no-conflict checks passed; no uncommitted implementation.

Key findings: Ch3 explicitly continuous static return/no teleportation, Ch4 major loop gated; old Ch3/4 scenes and new service-elevator connection need explicit mapping; Mara35 dossier SI/HI summary conflicts with self-harm-only reply79, new clinical specifics/collateral need original-source review; crash pre-entry checkpoint must not erase durable valid care/evidence; SaveManager already temp-writes/renames but has no inspection interruption journal; EvidenceManager method strings don't establish independence; proposed claim/status IDs not shipped; Ch2–5 remain planned; all clinical flags pending.

## Current tests / known limitations

Command `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`, log `/tmp/forensic-revised-v2-qa.log`, session79985. Python6+3+3, pharmacology0 failures, QA19/0/0, GLB138/138, TestRunner131/0, boot OK and audio334/0; Chapter1 sequence62.2s completed; **all executed checks passed, exit0**. Runtime bytes unchanged by review/base main docs merge. New safety/recovery/source-independence tests are **proposed/unimplemented**, not executed by this runner.

Prior full inspection QA passed exit0; prior Naomi audio333/1 existing cinematic fixed1.6s timing assertion remains unresolved/intermittent, not fixed by current pass. Reduced probe passed1015ms. Mac Metal/performance/actual safety/clinical correctness and hosted CI not validated. No known introduced code failure.

## Approvals / blockers / separate workstreams

V2 now accessible; no need to ask for its location. Original complete Mara dossier/risk/collateral source still not supplied merely by draft claiming it: new35/63/78/85/92 detail remains clinical review. Exact clinical dialogue/actions/risk/legal conclusions pending; keep data flags unchanged. Already-approved Mara Ch2/agency and Ch3 authorized first entry require no repeated approval.

Open: old-scene retain/defer decisions, service-elevator/threshold/W0-B map, life-safety/roster/state/save/journal policy, rescue content independent of failed drive, claim-specific source lineage/clock controls/status vocabulary, exact Ch4 effect/reproducibility, Ch5 endings, D4–D9/F0 C2/C6/C7. R1–R6 in review states exact bounded PR gates.

Naomi remains separate production proposal `CHARACTER_PRODUCTION_NAOMI_FIRST.md`, owner-merged PR31 into integration. No substantial modeling started; awaits explicit art/technical-reference/licensing/workflow scope approval, compatible Blender5.x (local4.3.2), artist/assets/rig/face/clips and8GB Mac. Existing138 GLBs no skins/clips/morphs;2D portraits not models. No dependency on full cast production for inert inspection contracts.

## Exact next task

1. Full QA complete; verify final committed/pushed docs using ls-remote; no new task while checkpoint pending. Get exact branch tip/clean status before ending.
2. Owner reviews `REVISED_SCREENPLAYS_V2_TECHNICAL_REVIEW.md`, especially Mara35/79/source review and contract state/crash/independence decisions. Receive explicit bounded R1 approval before runtime.
3. Earliest foundation implementation after scope approval: pure inspection lifecycle/recovery graph validator/reducer with synthetic non-anomaly fixtures, inert integration. Then real F2 failure/recovery lab, source-lineage validator and journal/replay integration; major Ch4 effect only after foundations, reviewed scripts and actual Mac tests.
4. Before shared edits fetch main/base/PR33, read AGENTS/CLAUDE/current handoff, inspect active claims and coordinate environment/audio/scene owners. Preserve campaign/F2/savev3 until a reviewed migration; no model changes folded into this PR.
5. Keep append-only history and milestone handoffs, feature pushes verified, owner alone merges. No uncommitted app work to recover; local logs can disappear, persisted result summaries remain here/review.

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
