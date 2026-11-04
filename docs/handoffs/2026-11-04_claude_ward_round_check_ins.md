# Handoff: checking in on earlier patients (Claude Code, 2026-11-04)

- Branch: `claude/ward-round-check-ins`, stacked on `claude/ward-round-plan-response` (#123). Draft PR; do not merge until the stack is reviewed.
- What changed:
  - `data/ward_rounds.json`: every case has `follow_up` {review_status PENDING_PSYCHIATRIST_REVIEW, line}.
  - `WardRounds.can_follow_up` (accepted, not replaying, a later chapter has begun, has a line), `follow_up` (marks `followed_up`, returns the line), `followed_up_line`. `followed_up` is saved and validated; older saves default to false; replay keeps it.
  - `WardRoundCatalog.validate`: `plan_response` and `follow_up` share one check.
  - `WardRoundScreen`: Bedside tab shows "Check in and ask how they are getting on" (button `FollowUp`), then a "Checking in" card (`FollowUpLine`); the census adds "check in"; such a patient opens at the Bedside tab.
  - Test: `test_ward_round_conversation.gd` now 9 tests. Capture tool adds `follow_up_offer.png` and `follow_up.png`.
- Clinical: pending Bi's review (row in `docs/clinical_review_log.md`); sheet `/mnt/project-files/ward_round/check_ins_review.md`.
- Next: Bi reviews the lines.
- Bedside tab no longer shows the opening choices on an accepted case that had no conversation. Full QA passed (game 410/0, audio 1720/0, QA 19/0/0, GLB 199/0, Chapter 1 sequence done, exit 0). Not tested on the Mac.
- 2026-11-04 18:28 UTC: Bi approved the lines ("approved continue"); review_status set to APPROVED and logged.
