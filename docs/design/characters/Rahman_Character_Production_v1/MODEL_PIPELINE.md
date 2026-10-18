# Independent Blender-to-Godot character contract

## Ownership isolation
- Use separate `tools/blender/characters/rahman/` or `tools/blender/characters/build_rahman.py`; separate source `.blend`, export `.glb`, material assets and previews in Rahman-specific directories.
- Do not modify Naomi, Voss, Elias or their active builder branches. Read shared code, reuse only stable verified APIs and legally cleared assets; prefer composition over modifying generic scripts during simultaneous workstreams.
- Blender 5.2.x; Godot 4.7; 8 GB Apple Silicon target. No fixed mesh density without profiling; create texture budget and reduced-LOD option. Record actual mesh counts, material counts, texture RAM, export size, and rig compatibility.

## Required build outputs
1. Versioned editable source `.blend` and reproducible script/README; only if build succeeds.
2. `.glb` with verified body mesh, skeleton, bind pose, materials, optional facial blend shapes and armature animation tracks.
3. Neutral full-body front / three-quarter / profile + seated and standing preview renders.
4. Provenance and licensing manifest: MPFB/CC assets and texture sources verified per component, no unauthorized likeness or voice cloning.
5. Godot import/load validation, neutral pose with no mesh deformation, scale/feet/floor alignment, missing animation fallback.
6. Explicit independent `staff_rahman` binding proposal; do not wire into `data/staff.json` before story/zone scene needs and owner review.

## Technical interfaces
- Prefer model-independent animator adapters analogous to existing Bennett acting adapter without duplicating ID or using Bennett's five Chapter 1 cue IDs.
- Rig mapping should be documented and checked, not assumed from MPFB; animation retargeting and lip sync require real playback validation.
- Animation states: idle-standing, seated-chat, listen, speak, chart-review, turn, walk; no fast gesticulation by default.
- Leave core systems, clinical rules and SaveManager untouched.
