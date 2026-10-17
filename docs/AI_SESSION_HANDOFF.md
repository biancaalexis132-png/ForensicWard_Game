# AI session handoff (living document)

Updated 2026-10-17 · Codex · Five-chapter screenplay review.

## Current workstream and stopping point

All 11 PR #30 package files reviewed against main; chapter audit, detailed Elias mapping, owner decision matrix and small PR sequence completed in `docs/design/FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md`. No runtime or package modifications in this workstream. Full QA running; gameplay131/0 and boot OK, audio/sequence pending. New owner instruction: Mara is a significant recurring patient introduced in Chapter2; placement approved only, clinical logic pending. Next: record this canon amendment, reconcile Ch1 planning and write Chapter2 Mara crosswalk preserving supplied dossier facts. Audit QA audio334/0; sequence pending.

## Verified repository state

- Active branch `codex/screenplay-continuity-review`, stacked on `codex/character-canon-opening-cont-1` verified `30e13f87f64e46c152dad2034a2a8c2c3e152dc6`.
- Latest verified review remote **634c29b07b8d0c8f39ae7033bdcb856ec53b668c**; final handoff commit follows. Resolve final SHA using `git ls-remote origin refs/heads/codex/screenplay-continuity-review`.
- Main **052859a984d7db599282914cbc300cc8cecc887b**: owner-merged PR #30. Source `assets/ashcroft-creative-references` **2e3863e16d882560dde87ba3bf018c5b6a29016d**. Main merged into feature normally; no agent main push/PR merge/history rewrite.
- PR #27 conflicts resolved on authorized original branch at `412b5010c8ccd8ba0e19e983b4346b5d90482d34`, subsequently owner-merged main `6d2dd2d3ec1bebf3624a706da2f864efd711206e`. PR #29 P0 also merged.
- P1 feature remote **74715227bf5581b09a3b2746870082576fffe71f**. Pure validator/15 tests only; no provider, UI, catalog registration, personality meter or save bump. P1/canon changes are inherited dependencies, not new audit changes.
- Draft review PR attempt and open-PR inventory failed: `Post "https://api.github.com/graphql": Forbidden`. Git works. Draft body local `/workspace/screenplay-audit-pr.md`, reconstructible from audit. Target preceding canon branch; retarget only after dependencies merge. No new PR URL claimed; check owner-created PRs before duplicating. Hosted CI unobserved.

## Files and last completed milestones

This review: new `docs/design/FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md`; availability addenda in `CHAPTER1_OPENING_ALIGNMENT.md` and `ELIAS_EVALUATION_DRAFT_COMPARISON.md`; four continuity/status docs. Claims only these docs; no scene/clinical/audio/zone shared file claimed. Git diff from starting checkpoint confirms source package and runtime unchanged.

Audit identifies: early daytime unease, unexamined motor observation recording, pending-vs-completed exam note mismatch, mandatory hypothesis vs unresolved records path, sign-out bypasses, Jordan/Mara conflict, missing later clinical cases/branch graphs, unapproved corroboration/reveal protocols, four-source ambiguity and overlapping endings. Ch2–5 remain planned in campaign data. Existing F1 chapter archive, F2 streaming and v3 checksum/migrations preserved.

Earlier complete work (inherited): D1–D3 decision/canon docs and Rahman direction-only profession correction; six inspected candidate reference sheets with hashes/exact prompts (not approved models/faces/clinical animation); opening/Elias summary reviews; permanent both-agent continuity AGENTS §9/CLAUDE. Originals preserved. Detailed history remains append-only in AI_HANDOFF and Git.

## Validation and known failures

- Standard runner: `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`; `/tmp/forensic-screenplay-qa.log`, session82146. Final result pending at this checkpoint, do not claim complete yet.
- TestRunner131/0, boot OK; all ten manifest payload byte counts and SHA256 match. `git diff --check` and preservation diff passed.
- Prior combined full QA passed: Python6+3+3, pharmacology0 failures, QA19/0/0, GLB138/138, gameplay131/0, audio334/0 and full Chapter1. Prior audio cleanup failure was fixed in PR27 without changing runtime sound behavior; not hidden or skipped.
- Headless does not validate Mac Metal, input, listening, first25-minute pacing, clinical correctness or 8GB performance. Expected negative-save warnings/nonfatal Python socket ResourceWarnings may appear.

## Outstanding owner approvals and dependencies

Audit matrix C1/N1–N7: clinical Elias findings/unknowns/risk/plan/actions; exact arrival/Bennett script and late cue presentation/gate; unresolved-record completion and sign-out safety policy; second patient identity/legal facts/Mara placement; Concordance/titles/Ch2–5 arcs; anomaly evidence protocols/F3 and C6 Bleed/C7 pharmacology gates; endings/eligibility/four-source facts. D4–D9 remain open (history,02:17,Mara voice,W3,boards,missing approved v1.1 bible). Candidate visual designs need owner/artist review.

Already approved: fixed psychiatrist/equivalent competence, moderate personal life/emergent personality, hospital-first opening, D1–D3 casting/roles. Do not ask those again or infer broader clinical approval. The new proposed bible does not replace missing approved private sources. Ch2–5 clinical slots need actual authoring, not extrapolation.

GitHub API restriction blocks PR/review/CI coordination; use supported environment configuration if owner enables domain, not token requests or proxy bypass. Cloud onboarding skill catalog currently returns no skills; earlier Godot install/start/domain draft saved, publication not claimed. Correct Godot installed outside checkout; system4.6.3 rejected by runner. No private Claude assets assumed.

## Exact resume steps

1. Read AGENTS/CLAUDE/current handoff/status/latest append-only entry. `git fetch origin refs/heads/main:refs/remotes/origin/main`; verify branch tip with `git ls-remote`, status and conflicts before editing.
2. Read `docs/design/FIVE_CHAPTER_SCREENPLAY_CONTINUITY_AUDIT.md`, especially C1/N1–N7 and PR sequence. Package source is now present; do not wait for standalone Elias text again.
3. Check owner-created PRs/review comments and active file claims when API permits. Review this docs diff against preceding canon branch; keep P1/canon dependencies separate.
4. Recommended first runtime PR after N1 review: add `intercom_heard` prerequisite to existing `beat_b6_unease` plus tests for day/no cue,15min intercom, both clue orders, once-only save/reload. Decide exact stinger/shutter treatment and already-fired saves first. Never gate supernatural truth on patient findings. No F3 implementation or clinical activation authorized by this audit.
5. Continue exact clinical/script approvals in small slices from audit roadmap; keep all pending flags, existing IDs/provenance and late timing. Never mark Ch2–5 playable from manuscript alone.
6. Checkpoint each milestone and before new substantial work. Commit/push feature only, verify remote SHA; owner merges. No uncommitted application work to recover; ignored caches/local logs are not required project assets.

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
