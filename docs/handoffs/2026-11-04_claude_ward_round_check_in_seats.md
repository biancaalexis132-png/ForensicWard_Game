# Earlier patients wait on the ward for a check-in (Claude Code, 2026-11-04)

- Branch: `claude/ward-round-check-in-seats`, from `main` at `4faf6f6` (#129 merged). Draft PR to `main`.
- What changed:
  - `data/ward_round_bedside.json`: new `check_in` block with a chair scene (`PROP_Chair_Visitor.glb`), the chair yaw and three seats on the east corridor wall by the ward entrance (x 1.15, z −16.4 / −17.45 / −18.5).
  - `scripts/world/WardRoundBedside.gd`:
    - `check_in_case_ids()` lists patients who can be checked in and haven't been yet, oldest admission first.
    - `check_in_occupancy()` reports who is on the chairs; `occupancy()` still reports the rooms only.
    - `refresh` fills the rooms and the chairs. The chairs are always placed.
    - The validator checks the chair scene, the yaw and the seats, and seat ids must not reuse room ids.
  - Walking up to a seated patient opens the ward-round screen on their case. That screen already opens on the Bedside tab with the check-in. Once checked in (`WardRounds.follow_up`), the patient leaves and the next one sits down, with a notice.
- No new lines and no clinical change. The patients say only Bi's approved check-in lines. The staging (seat placement, chairs) is pending Bi's look.
- Tests: `test_ward_round_bedside.gd` adds three tests: chairs and check-in flow, loaded game, validation. Ward-round filter 37/0.
- Full QA on this branch: game 415/0, audio 1720/0, QA 19/0/0, GLB 199/0, CH1_SEQUENCE_DONE, exit 0.
- Capture: `CaptureWardBedside.tscn -- --chapter=ch2` now also saves `ch2_check_in_seats.png`, `ch2_check_in_close.png` and `ch2_check_in_next.png`.
- Note: after `ChapterDirector.start_chapter` the zone's staging node can leave the tree, so tests use `load_save_data` (as the existing ch2 test does) instead of holding the old node.
- Next: Bi looks at the seats; then the next story/case work on a fresh branch from `main`.
