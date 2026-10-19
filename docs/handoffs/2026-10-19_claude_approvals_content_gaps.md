# Owner approvals and content gaps (Claude Code, 2026-10-19)

- **Branch:** `claude/owner-approvals-content-gaps` from main `572bf40`. Code checkpoint `04fdb8c` (full QA passed); later commits are documentation only. Draft PR to main; do not merge automatically.
- **Owner request (Bi, project thread, 2026-10-19 21:55 UTC):** "I approve all cast models and the narrative review. I reviewed clinical items ... Create completed cast models. Improve hair and clothing. FIx small content gaps." The clinical sentence was cut off, so a card asked; Bi chose **"Approve all"** for the four listed items (Elias dialogue, Mara record, catatonia rule, Chapter 2 work).
- The cast hair/clothing work is a separate branch, `claude/cast-hair-clothing`, with its own handoff. It also records the cast visual approval in `data/character_visuals.json`. This branch does not touch cast files.

## Approvals recorded

| Item | Change |
|---|---|
| Narrative review | `provisional: false` for Chapters 1–5 in `data/campaign.json` and every `data/story_chapter*.json`; stale campaign note replaced |
| Catatonia rule | `clinical_rule_catatonia_escalation_v1` and its action `evaluate_catatonia` APPROVED. It still applies only `mark_assessment_started`. It now also applies in validated build mode. `clinical_rule_medical_review_request_v1` stays pending |
| Elias dialogue | `data/dialogue.json` APPROVED. Elias's patient record stays pending because it was not on the list |
| Mara record | `pt_mara_ellis` APPROVED |
| Chapter 2 work items | `data/story_chapter2.json` clinical_review_status APPROVED. Chapters 1 and 3–5 keep PENDING clinical status |

All are logged in `docs/clinical_review_log.md`.

## Content gaps filled

- **Chapter 2 Scene 10:**
  - Bennett's line ("Don't decide the answer first") now leads straight into the optional personal message in the same panel.
  - The message can come from a partner, a friend or family, can be the player's own reminder, or can be left for later. Sharing work detail is refused.
  - The choice is stored as `ch2_contact_*`, the player's moderate personal history.
  - "Head out" then closes the chapter over the ordinary hospital exterior, and the recap plays.
  - The message waits at `NS_NoticeBoard` if the panel is closed.
  - New objective: `obj_ch2_end_of_shift`.
- **Chapter 4 Scene 04 (optional):**
  - Mara attends a follow-up in Interview Room A from Rahman's boundary until the door check starts. Elias steps out meanwhile.
  - Uses the screenplay lines only. Claiming the review has found the wrong date is refused.
  - Flag: `ch4_mara_followup`.
  - The new wording is logged as **pending** clinical review.
- **Chapter 4 Scene 06 (optional):**
  - After the paper trail, a phone notification sends the player to the nursing station.
  - The call comes from the Chapter 2 contact. The self-reminder gets its own version, and older saves get "someone close to you".
  - The player can accept support, keep it short or set a boundary (`ch4_call_*`). Sharing inquiry detail is refused.
- **Not built:**
  - Chapter 3's optional Mara follow-up. The screenplay gives no lines for it, so it would need new clinical dialogue written and approved.

## Engine changes

- Story options accept `next_interaction`, which opens the next scene in the same panel when its conditions hold. Schema, validator and `ChapterDirector._follow_on_panel` were changed; the validator rejects unknown or self references.
- `Character` re-checks `present_when` after any story choice (deferred), so optional scenes that don't move the objective can swap who is in a room.

## Tests

- **Command:** `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (official 4.7 Linux binary, SHA-512 verified) on `04fdb8c`, exit 0.
- **Results:**
  - Gameplay 293/0.
  - GLB 168/0.
  - Audio 412/0.
  - QA 19/0/0.
  - Python 6+4+6+3, pharmacology 0 failures.
  - `CH1_SEQUENCE_DONE` at 61.8 s.
- **New and updated tests:**
  - New file `test_chapter4_optional_scenes.gd`:
    - Mara follow-up.
    - Skipped window.
    - Partner call, self-reminder and later/older-save calls.
  - `test_chapter2_missing_hours.gd` covers the message, the refusal, re-opening at the board, the fade-out and save/load resume.
  - The eight chapter tests that replay Chapter 2 pick "Leave it for now" and "Head out".
  - Rule-governance tests now exercise the still-pending medical review rule. New tests check that the approved catatonia rule applies in validated mode.
- **Not run:** Mac. Hosted CI runs on the PR.

## Next

1. Bi reviews and merges this PR and the cast PR.
2. The executive producer reviews the Chapter 4 Mara wording.
3. Decide whether to write Chapter 3's optional Mara follow-up.
4. Do a Mac playthrough, then create export presets.
