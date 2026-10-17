# AI session handoff (living document)

This is the **current-session** handoff: it is rewritten throughout a session so a new Claude session can resume mid-task. It complements, and never replaces, the append-only log in `docs/AI_HANDOFF.md` (AGENTS.md §7) and the system table in `docs/PROJECT_STATUS.md`. If this file and those disagree, those win; record the conflict here.

**Start of every session:** read `CLAUDE.md` → `AGENTS.md` → this file → `docs/AI_PROGRESS_TRACKER.md` → `docs/PROJECT_STATUS.md` → `docs/AI_HANDOFF.md`, then `git fetch origin --prune`, list open PRs, compare with this file, and resume the first unfinished item in "Next actions".

## 12. Latest handoff timestamp

2026-10-17 21:30 UTC · Claude Code · visual direction review session (character review done)

## 1. Current objective

Art-direction and asset review (no implementation): compare the character reference package and the Ward Zero reference boards in `assets/creative_references/Visual_References/` against the approved canon (GDD, character/clinical data, dialogue) and the existing Godot/Blender assets, then deliver a written visual production review and implementation proposal for the owner's approval. Nothing is merged; no character models or scenes are replaced.

## 2. Repository state

- Branch: `claude/visual-direction-review` (new, from `main` at `e533e8b`, "Merge pull request #24 … assets/ashcroft-creative-references")
- Draft PR: not yet opened
- Other active work (do not touch): PR #21 `claude/f1-campaign-contract` (F1/F2 architecture thread); music integration thread (from `assets/ashcroft-creative-references`); environment thread holding Stage 6 (Ward Zero) pending plan approval.
- Working tree: this file and `docs/AI_PROGRESS_TRACKER.md` only.

## 3. Completed work

- Session started, repository cloned, branch created, handoff files created (commit `2e9dfca`).
- Canon sources located: GDD v0.1 §5/§12 (`docs/design/*.docx`), design bible v1.1 + package `03_CLINICAL_PATIENTS_AND_RULES.md`, `09_SUPERNATURAL…` (project upload zip `/mnt/project-files/uploads/hearth/451cb4fc-e48e-46c2-8359-778bcc4e55ed`, NOT in the repo), `data/staff.json`, `data/patients.json`, `audio/voice_profiles.json`, `docs/F0_FOUNDATION_AUDIT.md` C4/C5.
- Character package reviewed (6 sheets, ensemble board, guide PDF, README). Key findings: Bennett portrait does not match written casting; Voss looks too young, wrong jacket; Hale in tactical vest (violates guardrail); Rahman role conflict pre-exists in canon (pharmacist vs psychiatrist, C4); Elias and Mara portraits dishevelled, contradicting the clinical record ("appearance neat" / "clean"); ensemble board mislabels roles/ages and codes both patients as "Ward Zero" and otherworldly (must be rejected).

## 4. Current progress

Stopped at: character review done; next is Ward Zero boards.

## 5. Remaining tasks (priority order)

1. Review character package (6 PNGs, guide PDF, README) vs canon data.
2. Review Ward Zero boards (4 PNGs + README).
3. Inventory existing scenes / `.blend` / `.glb` / pipeline docs.
4. Write `docs/design/VISUAL_PRODUCTION_REVIEW.md` (8 deliverables).
5. Open draft PR, never merge.

## 6. Technical decisions

- Review docs only; no code, scene, model or data changes.
- Canon sources outrank generated imagery (owner instruction).

## 7. Files modified

- `docs/AI_SESSION_HANDOFF.md` (new): this file.
- `docs/AI_PROGRESS_TRACKER.md` (new): progress checklist.

## 8. Tests and validation

- None run yet. Documentation-only branch; Godot QA (`python3 tests/qa/run.py`) not required for docs but will be noted as "not run".

## 9. Blockers

- None.

## 10. Next actions

1. View the four `Ward_Zero/*.png` boards and the two `Concept_Boards/*.png`.

## 11. Creative constraints (standing)

- Ashcroft State Forensic Hospital is a functioning, modern, humane, professionally maintained forensic psychiatric hospital. Not an abandoned asylum.
- Ward Zero is an older decommissioned section beneath the hospital with a genuine supernatural phenomenon (temporal and spatial distortion). Early anomalies are subtle and open to more than one interpretation.
- Psychiatric symptoms are never evidence of the supernatural; story clues and symptoms stay separate (AGENTS.md §6).
- Approved character bible and clinical records are authoritative over generated reference art. Do not invent psychiatric histories.
- Five-chapter architecture (F0 audit) is fixed.
- Target hardware: 8 GB Apple Silicon MacBook Air, Godot 4.7 Forward+ (Metal).
