# Handoff: each patient reacts to the bedside opening (Claude Code, 2026-11-04)

- Branch: `claude/ward-round-opening-reactions`, from `claude/playtest-fixes` at `0c15e54` (after #127). Draft PR to `main` (#128 merged the stack into `main`).
- What changed:
  - `data/ward_rounds.json`: every case has `opening_reactions` {review_status APPROVED, warm, direct, rushed}.
  - `WardRounds.open_bedside` returns the case's own reaction (formatted like other spoken lines; a line starting with a bracketed description is shown as written), falling back to the generic response.
  - `WardRoundCatalog.validate_opening_reactions`: status, known opening ids, non-empty lines.
  - Test: `test_ward_round_conversation.gd` now 10 tests.
- Clinical: approved by Bi ("approved. cont", 2026-11-04 19:31 UTC); sheet `/mnt/project-files/ward_round/opening_reactions_review.md`.
- Full QA passed: game 412/0, audio 1720/0, QA 19/0/0, GLB 199/0, Chapter 1 sequence done, exit 0. Not tested on the Mac.
