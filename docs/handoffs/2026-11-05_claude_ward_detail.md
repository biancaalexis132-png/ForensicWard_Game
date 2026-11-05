# Ward detail (set dressing) — Claude Code, 2026-11-05

Roadmap point 5 (environmental detail). Branch `claude/ward-detail` from `main`.

This note lives here, not in the shared handoff docs, because draft PR #149 (lighting baseline) is the one open PR that edits those. When #149 merges, the next PR copies this summary into `AI_HANDOFF.md`, `AI_SESSION_HANDOFF.md`, `AI_PROGRESS_TRACKER.md` and `PROJECT_STATUS.md`.

## What changed
- `data/set_dressing.json` and `scripts/world/SetDressing.gd`: cosmetic props placed in a zone after it is built (`AuthoredWorld.build_zone`). There is no interaction, wording or save state, and nothing goes on the floor.
- Clinical corridor: a hand-gel dispenser beside each of the six doors, an AED cabinet (west wall, between the office and nursing station doors), a notice board with blank notes (west wall, opposite the interview room), an intercom speaker by the entry, and two ceiling camera domes.
- Placements avoid the nursing-station and patient-room observation windows. The wall face is about x ±1.45 to ±1.5.
- Captures were made with #149's `CaptureAtmosphere` tool plus a local `--view=x,z,yaw_deg` option, which is not in this PR (it would conflict with #149).

## Tests
- `test_set_dressing` (2): data valid; every prop placed, off the floor, inside the wing, clear of doors, not interactive; no state change.
- Full game suite: 475 passed, 0 failed, no ERROR lines.

## Next
More rooms (nursing station, office), then the historic wing. Bi to look on the Mac.
