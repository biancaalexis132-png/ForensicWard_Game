# Map readability (Claude Code, 2026-11-05)

Roadmap point 6 (map readability) from Bi's seven-point plan, thread "Make the game more compelling". Independent of `claude/case-file` (#137); both branch from `main`.

## What changed

- **M opens and closes the map** (new `map` input action in `project.godot`, M key). It still opens from the pause menu, now labelled "Map (M)".
- **Bigger map** (1520 × 960 panel).
- **Rooms named beside the plan** with leader lines, instead of numbers and a separate list. Long corridors are named inside, along their length.
- **The room you're in** is highlighted and marked ▶.
- **Staff and story patients** appear as named dots. Ward-round patients are left off to keep the plan clear.
- **Drawn legend:** you, person, open door, locked door, EHR.
- **Text line under the map:** "You are in: …" and "On this floor: name (room), …".
- `FloorPlan.snapshot()` gains `here` and `people`, and there is a new `FloorPlan.room_at()`. The map still loads nothing and changes no state.

## Files

Changed: `scripts/ui/SpatialMap.gd` (rewritten drawing), `scripts/ui/FloorPlan.gd`, `scripts/ui/MapScreen.gd`, `scenes/ui/MapScreen.tscn`, `scripts/main/Main.gd` (M key), `scripts/ui/PauseMenu.gd` (button label), `project.godot` (one input action).
New: `scripts/tests/test_map_readability.gd`, `tools/godot/capture_map.gd`, `tools/godot/CaptureMap.tscn`.

## Next

- Objective marker on the map. It needs `CaseFile.objective_place()` from #137, so it follows once #137 merges.
- Bi checks the map on the Mac. Before/after captures are in `/mnt/project-files/map/`.
