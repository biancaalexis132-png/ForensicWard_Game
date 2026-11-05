# Final build approvals and QA: Claude Code handoff, 2026-10-21

Requested by Bi. One draft pull request to `main`, `claude/final-build-approvals`, based on `1a498dc` (Codex's final build). Bi merged Codex's PR #111 into `main` at `3c725e9` (2026-10-21 00:35 UTC, same tree as `1a498dc`), so this PR applies cleanly on its own. Nothing was merged by the agent and no Codex branch was pushed to.

## What changed

Bi's approvals on 2026-10-21 (00:25 and 00:26, recorded word for word in `docs/clinical_review_log.md`):

- Prologue `cs_ch01_prologue`: now `mode` campaign, `approved` true, trigger `new_game`. New Game goes title, prologue, gameplay.
- Milestone `ms_ch1_first_assessment`: `approved` true.
- Elias's voiced questions and narrated responses, the return wording, and the order catalog wording: marked approved.
- Title screen and background, and the Stage 7 environment art: manifest status `OWNER_APPROVED_2026-10-21`.
- Jordan (CP-001): all 12 `clinical_review_status` values now `APPROVED`, so the case is playable. Jordan stays the same Chapter 1 patient. Bi did not pick pronouns; the shipped case text uses none, and the log records they/them as the default from the decision card. If Bi wants he/him, change only the review log row.
- `TitleScreen.new_game()` announces New Game before closing, so the screen goes straight to the prologue; `close()` and `_exit_tree()` collect in-flight threaded preloads.
- Tests updated for the new defaults (`test_presentation`, `test_title_screen`, `test_milestones`, `test_profile_practice`, `tests/qa/test_cutscenes.py`). Tests that stop at a prologue now stop its music before exit, so Godot reports no resources still in use.

## Validation

- Full headless QA, Linux, Godot 4.7 stable, on runtime commit `88460d6`: all executed checks passed in 684 s, game 348/0, audio 1622/0, QA 19/0/0, GLB 171/0, Chapter 1 sequence done at 62.0 s, no ERROR lines.
- Full headless QA on the base `1a498dc`: all executed checks passed in 744 s, game 348/0, audio 1622/0, QA 19/0/0, GLB 171/0, Chapter 1 sequence done, no ERROR lines.
- Bi's MacBook Air (M1, 8 GB, macOS 26.0, Godot 4.7.2 Metal), fresh clone at `~/Developer/forensicward-final` of `1a498dc` through Remote Control; nothing was written to the SSK drive. `tools/qa/mac_acceptance.py` exited 0: QA 19, GLB 171, game 348/0, audio 1622/0, Chapter 1 sequence done. Idle title screen: peak footprint 976 MB, max RSS 426 MB, p95 frame 24–38 ms, first frame 5.3 s (window likely in the background, so not a gameplay frame-rate figure).

## Not done

- Mac visual and controls pass: `screencapture` failed without Screen Recording permission and no input could be sent without Accessibility. Bi grants both to the Claude app in System Settings, Privacy & Security; then rerun on this branch's commit.
- Listening: needs Bi's ears (`docs/presentation_review.html`, then the prologue in game).
- The Mac has not run `88460d6` yet, only `1a498dc`.

## Notes for follow-up

- The Mac log has 52 warnings "chapter title cutscene already playing, static_gn ignored" (Chapter 2: 29, Chapter 3: 20, Chapter 4: 3) and 3 "no voice clip for ch1_b2_bennett_001". Neither fails a test; both are worth a look.

## Resume here

1. `git fetch origin --prune`; read the newest `docs/AI_HANDOFF.md` entry.
2. After Bi grants the two permissions, start Remote Control on the Mac, clone fresh into `~/Developer/` (never run git on the SSK drive), check out `claude/final-build-approvals`, import, and follow `docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md`.
3. Record PASS, FAIL or NOT TESTED per item, with the exact commit.

## Mac second pass, after Screen Recording was granted (2026-10-21, still on `1a498dc`)

- Cast capture on Metal, exit 0: all seven cast members load their real models (Bennett v07, Voss, Rahman, Hale, Elias, Mara, facilities tech v01 drafts); no DEV ERROR capsules. Files in `work/mac-acceptance/cast_metal/` on the Mac (not committed).
- 107 s in the clinical wing, exit 0, no ERROR lines: peak footprint 926 MB, peak RSS 341 MB; unpaused p95 frame interval median 24.9 ms (worst 31.2 ms), paused 19.6 ms; worst single frame 361 ms.
- Seen: the "New objective" banner covers the character name label; the current objective shows twice (checklist top left and "Objective:" line bottom left); small dark marks at Elias's shoulder seams.
- NOT TESTED: input-driven items (title buttons, dialogue, EHR Orders, objective-complete banner, pause, journal, map, save/load, floor round trips). Input injection through osascript was not permitted. Options for Bi: play `docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md` §2 by hand, or grant osascript Accessibility so the Mac session can drive the game.

## Mac third pass (2026-10-21, `1a498dc`)

- Title screen captured as a window-only image: Chapter 1 artwork, title and hospital name, New Game, Customize new psychiatrist, Continue (disabled, no save), Settings, Quit, "Ready." and the fiction disclaimer all readable. Thin dark strip at the left and right edges of the artwork. Launch and quit exit 0, no ERROR lines, peak footprint 918 MB.
- Clicks and key presses were refused by the Mac session's safety check, so the input-driven items stay NOT TESTED. The remaining controls pass is for Bi to play by hand (`docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md` §2), together with the listening check.
