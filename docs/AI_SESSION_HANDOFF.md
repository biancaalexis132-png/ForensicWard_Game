# AI session handoff (living document)

This is the **current-session** handoff required by the Ashcroft Session Continuity Protocol in `CLAUDE.md`. It is rewritten throughout a session so a new Claude session can resume mid-task. It complements, and never replaces, the append-only log in `docs/AI_HANDOFF.md` (`AGENTS.md` §7) and the system table in `docs/PROJECT_STATUS.md`. If this file and those disagree, those win; record the conflict here.

**Start of every session:** read `CLAUDE.md` → `AGENTS.md` → this file → `docs/AI_PROGRESS_TRACKER.md` → `docs/PROJECT_STATUS.md` → newest entry of `docs/AI_HANDOFF.md`; then `git fetch origin --prune`, list open PRs, compare with this file, and resume the first unfinished item in "Next actions".

## Last updated

2026-10-17 22:05 UTC · Claude Code · visual direction review session (review delivered; draft PR opened; waiting on owner approval)

## 1. Current objective

Art-direction and asset review, no implementation: compare the character references and the Ward Zero boards in `assets/creative_references/Visual_References/` with approved canon and existing Godot/Blender assets, and deliver a visual production review and implementation proposal for owner approval. Owner instruction: no major implementation and no merges without approval.

## 2. Repository state

- Branch: `claude/visual-direction-review`, created from `main` at `e533e8b`, then `main` at `3255b17` (PR #25: CLAUDE.md continuity protocol) merged in. Find the tip with `git ls-remote origin claude/visual-direction-review`.
- Draft PR: "Visual production review: characters and Ward Zero" against `main` (see the PR list; never merge from an agent).
- Other active work, do not touch: PR #21 `claude/f1-campaign-contract` (F1/F2 architecture); music integration ("Pick up earlier game session" thread); Stage 6 Ward Zero build in progress in the environment thread ("Pick up second game session", session `cse_012g8GqbzUkQo7xX9rHgbFKz`), not yet on GitHub when last checked.
- Working tree: clean after the final push.

## 3. Completed work and findings

- Created this file and `docs/AI_PROGRESS_TRACKER.md`.
- Located canon: GDD v0.1 §5/§12 (`docs/design/*.docx`); design bible v1.1 package (project upload zip `/mnt/project-files/uploads/hearth/451cb4fc-e48e-46c2-8359-778bcc4e55ed`, **not in the repo**: files `01_MASTER_DESIGN_BIBLE.md`, `03_CLINICAL_PATIENTS_AND_RULES.md`, `05_AUDIO_VISUAL_AND_ACCESSIBILITY.md`, `09_SUPERNATURAL_AND_FOUNDATION_DECISIONS.md`); `data/staff.json`, `data/patients.json`, `audio/voice_profiles.json`, `docs/F0_FOUNDATION_AUDIT.md` (C4 staff roles, C5 Mara).
- Reviewed all 6 character sheets, the ensemble board, guide PDF and README; the 4 Ward Zero boards and README; and the 2 `Concept_Boards`.
- Inventoried 138 `.glb` (Stages 1–5), the Stage 5 historic substructure, `Character.tscn` capsule stand-ins, `AuthoredWorld.gd` marker wiring, `WorldStateManager` states, `FlickerLight`, Ward Zero audio cues.
- Wrote `docs/design/VISUAL_PRODUCTION_REVIEW.md` (all 8 deliverables plus open decisions D1–D9).
- Sent the environment thread a cross-session heads-up listing reference elements that conflict with canon (21:40 UTC), so Stage 6 does not bake them in.

Key findings: Bennett portrait does not match the written casting; Voss reads too young; Hale wears a tactical vest (violates guardrail); Rahman's role conflicts across GDD/voice data (pharmacist) and v1.1/guide (psychiatrist); Elias and Mara portraits are dishevelled, contradicting "appearance neat"/"clean"; the ensemble and concept boards mislabel roles, code patients as "Ward Zero"/otherworldly, and cite real actors (reject). Ward Zero board 02 is a good architectural reference; boards 01/03 contain blood-like stains, a restraint "electric" chair, a named patient record with a Diagnosis field, a decommission notice signed "A. Mercer, Hospital Administrator", and explanatory notes/graffiti (reject); board 04 anomaly cues are usable if staged by chapter.

## 4. Current progress

Stopped at: review delivered and draft PR open. Waiting for the owner's approval of the review and decisions D1–D9.

## 5. Remaining tasks (priority order)

1. Owner approves or amends the review (D1–D9). Nothing below starts before that.
2. On approval: open the GitHub issues in review §8, then PR V1 (superseded notes on the three boards) and V2 (`docs/design/CHARACTER_VISUAL_CANON.md`).
3. When the environment thread's Stage 6 PR opens, review it against review §3, §4, §6 instead of building V4–V6 in parallel.

## 6. Technical decisions and dependencies

- Documentation only; no code, scene, model, data or audio changes.
- Canon outranks generated imagery (owner instruction).
- The v1.1 bible is cited from the project upload; D9 proposes committing it under `docs/design/`.
- Anomaly effects depend on F2 (zones) and F3 (anomaly model) from the F0 plan.

## 7. Files created or modified

- `docs/AI_SESSION_HANDOFF.md` (new): this file.
- `docs/AI_PROGRESS_TRACKER.md` (new): progress checklist.
- `docs/design/VISUAL_PRODUCTION_REVIEW.md` (new): the review and proposal.
- Merge commit bringing `main` (`3255b17`, CLAUDE.md) into the branch; no conflicts.

## 8. Tests and validation

- Godot QA (`python3 tests/qa/run.py`): **not run**. The branch adds only Markdown; no Godot, data or asset file changed. CI on the PR is the check of record.
- Image findings are visual inspection; ages and appearance read from generated faces are inferences.

## 9. Failures and blockers

- None technical. Blocked on owner approval by design.

## 10. Pending user approvals

- The whole review (`docs/design/VISUAL_PRODUCTION_REVIEW.md`).
- D1 Rahman's role · D2 Hale's title · D3 written casting · D4 Ward Zero decommission date/signatory · D5 02:17 timestamp link · D6 Mara's voice · D7 separate Ward Zero station · D8 concept boards superseded · D9 commit the v1.1 bible.

## 11. Next actions for a new session

1. Check the draft PR for owner comments: `gh pr list --head claude/visual-direction-review` (or the GitHub MCP).
2. If approved, apply the owner's decisions to the review, then start PR V1 on a new branch from `main`.
3. If the environment thread's Stage 6 PR exists, read it and post review notes referencing review §3–§6.

## 12. Creative and clinical constraints (standing)

- Ashcroft State Forensic Hospital is a functioning, modern, humane, maintained forensic psychiatric hospital. Not an abandoned asylum.
- Ward Zero is an older decommissioned section beneath it, with a genuine supernatural temporal and spatial phenomenon, introduced subtly; early anomalies keep an ordinary explanation.
- Psychiatric symptoms are never evidence of the supernatural; story clues and symptoms stay separate (`AGENTS.md` §6). No invented psychiatric histories.
- Approved character bible and clinical records outrank generated reference art.
- Five-chapter architecture (F0) is fixed. Unapproved clinical effects stay off.
- Target: 8 GB Apple Silicon MacBook Air, Godot 4.7 Forward+ (Metal).
