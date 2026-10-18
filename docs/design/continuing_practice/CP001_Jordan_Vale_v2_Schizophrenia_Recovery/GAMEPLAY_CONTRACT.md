# CP-001 — Godot / data / QA implementation contract

**Proposal; not executable clinical content.** Adapt to verified repository APIs and naming contracts before implementation. Current baseline at planning: SaveManager v3; PatientManager append-only notes/audit; clinical rules have pending approvals; protagonist profile, Chapter 5 and postgame persistence are coordinated proposals.

## Lifecycle
`available → accepted → encounter_1 → encounter_2 → encounter_3 → encounter_4 → encounter_5 → followup_cycle_complete`.
Support `on_hold`, `handoff_pending`, `handoff_acknowledged` without allowing a pending task to disappear; after the fifth encounter the recurring patient remains in longitudinal care, but this authored story arc is complete. Never make elapsed-time progression override a safety concern or current unfinished assessment. Numbered encounters may span any number of chosen shifts, not forced consecutive days.

## State separation
- Authored case: immutable metadata + source catalog + reviewed scripted encounters.
- Mutable case: acceptance, completed encounter IDs, action event ledger, follow-up task IDs, handoff status, note IDs, source references, preference callbacks.
- PatientManager retains exclusive ownership of patient observations, assessment and signed notes.
- Narrative ending provider owns A/B/C selection; case state reads but never modifies it.
- Protagonist provider owns background; clinical competence and case access independent of background/relationship/trust.
- Do not increment SaveManager from v3 independently; coordinate one reviewed v3→v4 migration with finale, protagonist and Continuing Practice.

## Suggested event names (reserve after collision audit)
`cp001_case_accepted`, `cp001_s1_interview_done`, `cp001_s1_note_signed`, ... `cp001_s5_interview_done`, `cp001_s5_note_signed`, `cp001_handoff_ack`, `cp001_cycle_complete`. Every commit should be idempotent and bound to patient and encounter.

## UI
Worklist clearly marks case clinical-review status. Source chips: `PATIENT_REPORTED`, `STAFF_REPORTED`, `DIRECT_OBSERVATION`, `CHART_RECORD`, `UNAVAILABLE`. Handoff panel: concern/task, responsible role, communication status, acknowledged event, next review point. Avoid misleading "verified" badges for merely copied notes.

## Explicit non-features in v1
No drug choice mini-game, automatic medication administration, diagnoses scored as right/wrong, coercive action, forensic court decision, discharge, loss of patient agency, paranormal interpretation of symptoms, procedural patient-generation by LLM, or new locked-room access.

## Deterministic tests required
1. All five encounters reachable across A/B/C endings and protagonist variants.
2. Case is optional and cannot block ordinary free-roam or unrelated cases.
3. Duplicate accepted/encounter/signed events produce no duplicate progress.
4. Save/load in each encounter retains clinical notes, patient identity, pending follow-ups and ending state.
5. v1/v2/v3 legacy save fixtures remain readable after approved migration; no forced character creator.
6. Patient-reported vs staff vs direct observation and chart source distinction is preserved.
7. An absent medication reconciliation cannot generate a medication list, result or adverse effect.
8. Optional collateral requires consent; absent consent yields no private disclosure.
9. A note does not imply a spoken handoff; acknowledgment does not imply clinical resolution.
10. Unfinished accepted tasks must be completed or appropriately handed off with accountable owner before shift close.
11. Restart/replay isolates state and never overwrites an existing completed campaign.
12. No Ward Zero evidence modifies patient state or this case's eligibility.
13. Missing voice/model/animation falls back to accessible text/placeholder, and scene unload cleans audio/controllers.
14. Accessibility and 8GB Mac performance evaluated locally; Godot 4.7 end-to-end tests required.

## Integration phases
CP-001A: contract validation and tests only. CP-001B: case lifecycle after consolidated state approval. CP-001C: reviewed dossier, dialogue, assessment presentation. CP-001D: handoff, save-load, QA and voice/character performance. Each separate PR; no automatic merge.
