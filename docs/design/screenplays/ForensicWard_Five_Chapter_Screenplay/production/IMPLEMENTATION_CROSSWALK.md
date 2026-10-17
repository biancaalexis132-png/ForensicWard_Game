# GitHub / Godot implementation crosswalk — inspect latest upstream before changes

## Existing files verified for screenplay grounding
- `data/campaign.json`: Ashcroft plus chapter slots and provisional titles: The Admission; The Missing Hours; Beneath the Hospital; The Official Record; Beyond the Lines. Chapters 2–5 remain marked `planned` in inspected version.
- `data/patients.json`: Elias 29, competency-restoration transfer, mutism, decreased movement, possible posturing, poor oral intake, provenance and differential. `clinical_review_status` is pending.
- `data/dialogue.json`: initial `ask_intake`, `assess_motor`, and `ask_ward_zero`, placeholder assessment return; clinical review pending.
- `data/story_chapter1.json`: meet Bennett, evaluate Elias, write note, choose action, compare records, sign out; after-hours W0-B intercom and inactive credential; preserve event and objective IDs.
- `data/narrative/chapter1.json`: audio scene `ch1_b2_bennett_handover`, intercom line `ch1_b6_intercom_001` and provisional Bennett voice lines. Keep IDs stable if editing wording; voice regeneration is a separate task.
- `data/zones.json`: F2 zone loader and placeholders; do not build all levels simultaneously.
- `docs/design/GDD_AMENDMENTS.md`, `docs/F0_FOUNDATION_AUDIT.md`, `docs/design/VISUAL_PRODUCTION_REVIEW.md`: approved foundation and visual review boundaries.

## Explicit differences requiring approval
1. The new suggested morning opening should not unilaterally change time-of-day objective logic. In the repo, Chapter 1 culminates with night shift and sign-out; map additions around preserved beat order.
2. Scene 7 Jordan Vale is PROVISIONAL. The second stable patient was not authored in the baseline repo.
3. Chapters 2–5 are entirely speculative authorial screenplay expansion. No chapter story/world/dialogue files are approved or shipped solely because they appear here.
4. Early anomaly scenes suggest `anom_clock_offset`, `anom_door_state`, etc., and must use the F3 independent anomaly system only after owner approval; psychiatric state is never an anomaly trigger.
5. Physical details of Ward Zero W3 and exact historical signatories/dates require approval; avoid fixed dates and names.
6. Existing clinical rule flags remain PENDING. Never enable validated medical decision logic from this manuscript without owner’s psychiatric review.
7. Character title corrections Rahman Consultant Psychiatrist; Hale Security Director; written guide overrides portraits. These decisions have been approved in current conversation but must be applied to GitHub through review.

## Implementation suggested sequence
A. Docs-only screenplay intake PR (this package), with provenance and review status.
B. Clinical/narrative review of Chapter 1; reconcile Elias original text with current JSON; obtain patient-2 identity and facts; preserve medical safety.
C. Story and dialogue content PR using existing event IDs, validator, approved outcomes, deterministic tests.
D. F3 anomaly model and accessible presentation, separately approved.
E. Design and clinical review for Chapters 2–5 in discrete chapter PRs. Keep chapter state planned until each is ready.
F. Run `python3 tests/qa/run.py` with Godot 4.7 and CI, verify save migrations and low-RAM performance on the actual Mac.

## Scope / continuity
No model weights or local Blender files assumed accessible. Avoid Git metadata on exFAT. Follow `AGENTS.md` and `CLAUDE.md` and maintain `docs/AI_SESSION_HANDOFF.md`, `docs/AI_PROGRESS_TRACKER.md`, `docs/AI_HANDOFF.md`, `docs/PROJECT_STATUS.md` appropriately. Never mark a remote push successful without checking it.
