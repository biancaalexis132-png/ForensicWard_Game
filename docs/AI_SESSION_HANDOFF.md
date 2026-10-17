# AI session handoff

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
