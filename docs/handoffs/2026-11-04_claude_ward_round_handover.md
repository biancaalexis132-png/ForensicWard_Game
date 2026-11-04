# Handoff: ward round in the day shift handover (Claude Code, 2026-11-04)

- Branch: `claude/ward-round-handover`, stacked on `claude/ward-round-check-ins` (#124). Draft PR; do not merge until the stack is reviewed.
- What changed:
  - `WardRounds.handover_lines(chapter_id)`: a "Ward round" section listing this chapter's patients (plan accepted with best debrief and grade, or no accepted plan yet) and earlier patients you checked in on. No clinical wording.
  - `ChapterDirector._hand_over`: adds that section after the shift summary (four lines; no trust changes).
  - Test: `test_ward_rounds.gd` gains `test_day_handover_lists_the_ward_round`.
- Next: Bi plays a day handover on the Mac.
- Full QA passed: game 411/0, audio 1720/0, QA 19/0/0, GLB 199/0, Chapter 1 sequence done, exit 0. Not tested on the Mac.
