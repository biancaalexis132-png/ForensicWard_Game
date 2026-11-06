# Historic wing dressing — Codex, 2026-11-06

Continues the environment pass in draft PR #153 on `codex/clinical-room-detail`.
The owner said “continue”; this authorizes production work, not visual approval.
All ten new clinical/historic placements remain `PENDING_OWNER_VISUAL_REVIEW`.

## Verified starting point

- Branch head `5033d533e4c8e0f889f97512784abd5ac848411b` is on GitHub. Its only change
  after recorded review `e162361` is the final documentation commit.
- Main remains `5199b50`; #153 is open and has no review comments or reviews.
- Hosted validation on `5033d53` passed in 16m27s:
  https://github.com/biancaalexis132-png/ForensicWard_Game/actions/runs/42278410813
- Resumed local baseline: `FW_TEST_FILTER=set_dressing` with the standard
  `scripts/tests/TestRunner.tscn`, official Godot 4.7, isolated XDG data directory:
  **2 passed / 0 failed**, matching the recorded focused baseline. The already
  completed full local baseline and now-verified hosted run were not repeated.

## Change

Five new static placements in `zone_historic_sublevel`:

| ID | Asset | Position (Godot metres) | Front |
|---|---|---|---|
| historic_fuse_entry | PROP_Panel_Fuse_Historic | -1.394, 1.35, -20.7 | East |
| historic_fuse_lift | PROP_Panel_Fuse_Historic | -1.394, 1.35, -42.5 | East |
| historic_vent_east | PROP_Vent_Grille_Wall | 1.394, 2.4, -27.2 | West |
| historic_vent_west | PROP_Vent_Grille_Wall | -1.394, 2.4, -35.5 | East |
| historic_office_board | PROP_NoticeBoard | -1.607, 1.7, -24.8 | West |

The notice sheets have no text. The fuse panels and vents have no interaction,
state, light, sound or collision. Existing authored fuse-board clues, doors,
windows, floor debris, anomalies and clinical content are unchanged. Nothing is
placed on the floor. Fuse-board conduits end below the 3 m ceiling.

The existing `SetDressing.attach` path remains unchanged: new props are created
only when the zone is built, then freed with its root. The new lifecycle test
checks no early load/reveal, contained meshes below the ceiling, door clearance,
absence of interactions/collisions, unchanged non-zone save providers, unchanged
current-floor map, idempotent builds, unloading and rebuilding without duplicates.
Zone save caches legitimately gain default door snapshots when geometry loads;
only that cache is excluded from the progression/care equality comparison.

The existing capture tool gains `--zone=<id>` and `--reverse`. Zone selection
validates the zone ID, stops streaming and unloads the starting floor before
building the selected review floor. This is a standalone tooling path; campaign
access gates do not change. Reverse mirrors the camera position and yaw so the
other wall can be reviewed.

## Provenance

Reused assets retain records in `assets/asset_manifest/asset_manifest.json`.
The fuse panel is original procedural geometry in `tools/blender/fw_assets.py`
(`prop_panel_fuse_historic`) and `assets/blender/historic/FW_Props_Historic.blend`.
The grille and board use that same source library's `prop_vent_grille` and
`prop_noticeboard`, exported from `assets/blender/clinical/FW_Props_Clinical.blend`.
The board already appears in the original historic set. No new third-party
content, licence, geometry export or LFS pattern is introduced.

Review captures are original Godot 4.7 engine renders, 960×540, Compatibility,
Linux Xorg dummy / Mesa llvmpipe, Dummy audio. They are placement evidence,
not Mac or Forward+ acceptance. Capture manifests record content checkpoints,
commands/settings and SHA-256 hashes.

## Validation and continuation

Runtime checkpoint: `59ae7f9` (pushed and verified). Focused placement tests:
**3 passed / 0 failed**, including the new historical-floor lifecycle test.
Full standard QA on that checkpoint: exit 0, gameplay **484/0**, smoke **19/0/0**, GLB **211/0**, audio **1760/0**, all Python checks pass, pharmacology zero failures and Chapter 1 sequence **62.1 s**. Exact command/results are in the newest `docs/AI_HANDOFF.md` entry. Existing clinical-room runtime is unchanged.

Before/after and reverse views are published in `docs/environment_review/historic_detail/`; the reverse clinical-office view is in `docs/environment_review/clinical_room_detail/`.

Next: owner reviews both floors on Mac. Continue room-by-room cosmetic polish after review while
preserving the existing gated historical story objects. No Mac export or SSK
transfer was performed.
