# Clinical room detail — Codex, 2026-11-06

Continuation of the room-detail next step in `2026-11-05_claude_ward_detail.md`.
Branch: `codex/clinical-room-detail`, based on verified `origin/main`
`5199b50f59c1e365188b61c9f6485efb1d878516`. GitHub had no open PRs at session start.
PRs #149–152 are merged; older shared status rows describing them as open are stale.
The recorded #149 checkpoint `df1a973` exists on origin; subsequent commits through
`5199b50` were inspected before continuing.

## Change

Five cosmetic placements in `data/set_dressing.json`, using the existing
`SetDressing.attach` path in every chapter that builds the clinical wing:

| Placement | Position (Godot x, y, z metres) | Front |
|---|---|---|
| Office acoustic panel, north wall | -4.9, 1.55, -5.9 | South |
| Office acoustic panel, east wall | -1.6, 1.65, -3.0 | West |
| Office hand-gel dispenser, inside entrance | -1.6, 1.2, -4.1 | West |
| Nursing-station high vent, west wall | -4.9, 2.6, -10.0 | East |
| Nursing-station intercom, north wall | -2.25, 2.3, -11.9 | South |

Each new entry records its room and `PENDING_OWNER_VISUAL_REVIEW`. The acoustic
panels are visual props; no simulated acoustic change is claimed. The intercom
is decorative. There are no new interactions, collision bodies, clinical content,
story triggers, or mutable state. Existing furniture, window openings and the
Voss exit route are preserved.

## Provenance and review

All four prop types already ship in the project, with their original source and
geometry records in `assets/asset_manifest/asset_manifest.json`:
`PROP_Acoustic_Panel`, `PROP_Dispenser_HandGel`, `PROP_Vent_Grille_Wall`, and
`PROP_Intercom_Speaker`. Sources: `assets/blender/clinical/FW_Props_Clinical.blend`
and procedural functions in `tools/blender/fw_assets.py`. No new third-party
content, asset export, texture, licence dependency, or LFS pattern is introduced.
Placement was checked against `build_stage2_chapter1.py`'s room/furniture layout.

Review screenshots are original in-engine captures, made with the existing
`tools/godot/CaptureAtmosphere.tscn`, Godot 4.7 stable, Linux Xorg dummy display,
Mesa llvmpipe Compatibility renderer, 1280×720, Dummy audio. Before uses main
`5199b50`; after uses the data change in this branch. These are placement review,
not Forward+/Metal or Mac acceptance. No image generation or editing is involved.

## Validation

Baseline standard runner: gameplay **483/0**, smoke **19/0/0**, GLB **211/0**.
This supersedes the older #152 handoff's 480 gameplay count after combined merges.
Final full-run results are recorded in `docs/AI_HANDOFF.md` when complete.
The existing `test_set_dressing` checks all listed placements, room membership,
door clearance, non-interactivity, and unchanged save state.

## Next

1. Owner reviews the two room views on the Mac: mounting depth, material contrast,
   access to desk/EHR, nursing counter, and the Voss exit route.
2. Continue cosmetic dressing in the historical wing using its own asset palette;
   preserve chapter/reveal gating and do not add new story evidence.
3. Existing voice-start stutter, chapter transitions and endings still need the
   hands-on Mac checks recorded in the earlier playtest handoff.

No Mac filesystem or SSK drive was available; no rebuild or transfer is claimed.
