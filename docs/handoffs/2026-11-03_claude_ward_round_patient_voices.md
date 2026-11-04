# Handoff: ward-round patients answer in their own words (Claude Code, 2026-11-03)

- Branch: `claude/ward-round-patient-voices`, stacked on `claude/ward-round-bedside-talk` (#120). Draft PR; do not merge until the stack is reviewed.
- What changed:
  - `data/ward_rounds.json`: every case has `bedside_lines` {review_status PENDING_PSYCHIATRIST_REVIEW, history, mental_state}. Lines restate only the case's own history and mental-state text in the patient's voice. A line in brackets describes a patient who cannot answer (Adeyemi, Okafor, Quinn's history).
  - `WardRounds.bedside_line(case_id, question_id)`: "First name: “line”", the bracketed text as is, or "" (the answer then falls back to the chart text). `ask_bedside` returns it; the chart still fills with the clinician's full text.
  - `WardRoundCatalog.validate_bedside_lines`: status, known question ids, non-empty lines; called for each case that has lines.
  - Tests: `test_ward_round_conversation.gd` now 7 tests.
- Clinical: pending Bi's review (row in `docs/clinical_review_log.md`). Approved cases' answer keys are unchanged.
- Next: Bi reviews the lines; revise wording from her notes.
- Tests: full QA passed (game 408/0, audio 1720/0, QA 19/0/0, GLB 199/0, Chapter 1 sequence done, exit 0). Not tested on the Mac. The capture tool timed out after the bedside screens under software rendering; only bedside_answers.png was refreshed.
