# Ward-round scoring, tests budget, debrief and replay (Claude Code, 2026-11-03)

Branch `claude/ward-round-scoring`, stacked on `claude/ward-round-bedside` (#116). Draft PR, not merged.

## What it does

- **Debrief score** (`scripts/clinical/WardRoundScoring.gd`), weighted as the owner's case bible says: patient safety 40%, diagnostic reasoning 25%, rapport and communication 20%, appropriate resource use 15%. Built only from each case's existing verdicts; it never decides whether a plan is accepted.
  - Safety: minus 50 per distinct unsafe item ever submitted, minus 25 per required item a submitted plan left out.
  - Reasoning: 60% share of required tests ordered before the first plan, 40% share of helpful tests ordered by acceptance; minus 15 per not-indicated item; minus 10 per extra attempt (cap 30).
  - Rapport: minus 50 per dismissive item (`rapport: "harms"` in the intervention catalog); minus 30 if the accepted plan does not explain itself to the patient (`int:explain_plan`).
  - Resources: minus 20 per not-needed test, minus 20 per test over the budget.
  - Any unsafe or dismissive submission caps the grade at "Needs work" (total at most 49). Grades: Excellent 85+, Good 70+, Satisfactory 50+.
- **Tests budget**: required + helpful tests + 2, shown on the Labs tab. Soft: going over costs points, ordering is never refused, so no case can lock.
- **Debrief tab** on the ward-round screen opens when a plan is accepted; the census shows each patient's best score.
- **Replay case**: starts an accepted patient again. The case stays accepted (chapter gate and bedside unaffected); the best score is kept. Saved with the game (`history`, `replaying`, `best`; older saves load with an empty history).
- `explain_plan` is now welcomed on every case (catalog default "acceptable"), including the approved ones where it used to show "Not needed". Logged as pending in `docs/clinical_review_log.md`.
- Fix: the Plan tab grew wider than the screen once the third wave's long choice labels arrived; chips now wrap.

## Tests

`scripts/tests/test_ward_round_scoring.gd` (7). Full QA: see `docs/AI_HANDOFF.md` entry.

## Waiting on Bi

- Say whether the weights' point deductions feel right and whether a replay should be allowed.
- Approve the explain-plan default on approved cases.

Full QA on the scoring commit (recorded in docs/AI_HANDOFF.md): game 401/0, audio 1720/0, QA 19/0/0, GLB 199/0, CH1_SEQUENCE_DONE, exit 0. Not run on the Mac.
