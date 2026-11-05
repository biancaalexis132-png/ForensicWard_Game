# Case file on Tab (Claude Code, 2026-11-05)

Roadmap point 2 from Bi (2026-11-04): connect objectives, journal entries and evidence so players know what they know, what is still uncertain and where to go next, without spoiling the mystery. Thread "Make the game more compelling". Point 1 (first 15 minutes, Elias) belongs to the "Flesh out the Elias encounter" thread (`claude/elias-encounter`).

## What changed

- **Tab opens the case file** (`scripts/ui/CaseFileScreen.gd`, `scenes/ui/CaseFileScreen.tscn`). Tab again or Esc closes it. Buttons lead to the evidence board and the clinical case journal.
  - Left: case notes, newest chapter first, filter All / Still open / Established / Care. Each card shows the status, the scene it came from, the note and "Your choice: …".
  - Right: **Now** (current objective and where it happens) and **Evidence** (clues collected and pinned, hypotheses with status, and the ordinary explanations still open).
- **`data/case_file.json`** lists 81 story choices (chapters 2 to 5) that become notes, each `established`, `open` or `care`. Every note's text is copied verbatim from that choice's approved response; `CaseFile.validate()` fails if it is not, so the case file never says anything new. Personal moments (calls, texts), chapter completion, pass logistics and transitions are left out.
- **`scripts/narrative/CaseFile.gd`** (static, no state, no save provider): notes are rebuilt from ChapterDirector's saved flags in authored order; the objective's place comes from the story data (the interaction whose choice completes it, the staff member to talk to, zone, EHR, evidence board, handover board).
- **Objective HUD**: the current objective has a second line with its place ("With Nurse Naomi Bennett", "At Maintenance export comparison").
- **Notices**: a choice that adds a note shows "Case file updated" or "Case file: noted as still open".
- Chapter 1 has no story choices yet, so its notes come later from the Elias thread's flags (add entries to `data/case_file.json`).

## Files

New: `data/case_file.json`, `scripts/narrative/CaseFile.gd`, `scripts/ui/CaseFileScreen.gd`, `scenes/ui/CaseFileScreen.tscn`, `scripts/tests/test_case_file.gd`, `tools/godot/capture_case_file.gd`, `tools/godot/CaptureCaseFile.tscn`.
Changed: `scripts/main/Main.gd` (Tab handling, panel route, one signal connection), `scripts/ui/ObjectiveTracker.gd` (place line), `scripts/tests/test_sprint3.gd` (Tab now opens the case file, then the board).

## Tests

See `docs/AI_HANDOFF.md` entry 2026-11-05 for the full QA result. `test_case_file` 7/0. Captures (Linux Compatibility renderer, not Mac acceptance): `/mnt/project-files/case_file/`.

## Pending

- Bi: look at the case file on the Mac; check the established/open/care marks in `data/case_file.json` read right (no new wording).
- Not tested on the Mac.
