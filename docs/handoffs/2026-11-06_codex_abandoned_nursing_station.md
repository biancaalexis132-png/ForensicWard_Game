# Abandoned nursing station — Codex, 2026-11-06

Continuation of the explicit next room in the previous handoff, on the existing
environment branch `codex/clinical-room-detail`, draft PR #153. The owner's
“continue” authorizes this work; it does not approve the visuals or clinical content.

## Verified baseline

Main remains `5199b50`. Branch head `8a3e7ef` was verified on origin; only the
final documentation commit followed recorded review `4fff016`. PR #153 had no
reviews/comments. Hosted `validate` on `8a3e7ef` passed in **17m53s**:
https://github.com/biancaalexis132-png/ForensicWard_Game/actions/runs/42288214044 .
Local resumed `FW_TEST_FILTER=set_dressing` baseline: **3 passed / 0 failed**,
matching the preceding handoff. Full baseline results were not unnecessarily rerun.

## Change and provenance

Three additional static props in `zone_historic_sublevel`, room `Abandoned nursing station`:

| ID | Asset | Godot position (metres) | Front |
|---|---|---|---|
| historic_nursing_service_pipes | PROP_Pipes_Wall_2m | -5.894, 2.45, -37.5 | East |
| historic_nursing_vent | PROP_Vent_Grille_Wall | -1.607, 2.55, -35.5 | West |
| historic_nursing_fuse_board | PROP_Panel_Fuse_Historic | -2.6, 1.35, -34.107 | North |

All are `PENDING_OWNER_VISUAL_REVIEW`. They use existing project assets and
materials, with no new geometry, collision, light, sound or interaction.
Service pipes remain high on the staff-station wall, above the existing cabinet.
No object is placed on the floor. The census board, night-report document,
stopped clock, furniture, hatch/window and door are retained.

Existing central provenance: `assets/asset_manifest/asset_manifest.json`.
Procedural source functions in `tools/blender/fw_assets.py`:
`prop_pipes_wall`, `prop_vent_grille`, `prop_panel_fuse_historic`.
Original Blender files: `assets/blender/security/FW_Props_Security.blend`,
`assets/blender/clinical/FW_Props_Clinical.blend`, and
`assets/blender/historic/FW_Props_Historic.blend`, respectively.
The pipes already appear in the original historical mechanical corridor.
No new third-party content, licence dependency, source export or LFS pattern.

The new regression compares eight existing station objects with an independent
instance of the original GLB: local transforms and every source metadata field
must match (including night-report review status). New fixtures' actual mesh
bounds must fit wholly inside the station and not intersect those protected
objects. This includes the counter, desk, clock, census board, night report,
cabinets and radiator. Existing lifecycle checks cover door/ceiling/floor
clearance, no early floor reveal, no collisions/interactions, unchanged care and
progression, unloading and rebuilding.

## Validation

Runtime checkpoint `473ee81`, committed and pushed. Focused command:

```
FW_TEST_FILTER=set_dressing XDG_DATA_HOME=/workspace/work/nursing-detail/focused-user /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64 --headless --path . res://scripts/tests/TestRunner.tscn
```

**4 passed / 0 failed**, exit 0. `git diff --check` clean.
Full standard QA is running on this checkpoint; final results belong in the
newest `docs/AI_HANDOFF.md` entry.

## Review and next steps

Before/after and reverse screenshots use the existing capture tool, Godot 4.7,
960×540, Linux Xorg dummy / Mesa llvmpipe Compatibility, Dummy audio. They are
placement review, not Mac / Forward+ acceptance. Captures/manifests will be
published under `docs/environment_review/abandoned_nursing_station/`.

Next: finish full QA, inspect/publish all views, then owner reviews #153 on Mac,
especially fixture mounting and access to the counter/night report. New placement
changes stay in `data/set_dressing.json`; existing clinical and story approval
states remain untouched. No Mac export or SSK transfer was performed.
