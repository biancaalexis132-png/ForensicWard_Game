# Naomi Blender character builder

This reproducible base-model build is pinned to Blender 5.2.2 LTS and MPFB2
2.0.18. Install and enable MPFB2 in Blender's Extensions preferences before
running it; the builder checks both versions and stops rather than using an
untested API. It does not download assets or embed MPFB code.

The current configuration builds `v02`; each generated version uses distinct
`.blend`, `.glb`, render and manifest paths. Increment `character.asset_version`
before a new milestone. Do not overwrite the retained v01 outputs.

From the repository root on macOS:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/build_naomi.py
```

The build writes the editable Blender scene, a self-contained Godot GLB, and
four review renders under `assets/`. Validate the outputs and their asset
provenance with:

```sh
/Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/validate_naomi.py
```

MPFB2's bundled character assets used here are CC0-1.0; the MPFB2 code itself
is GPL-3.0-or-later and is only a local build tool. Exact input files, target
weights, output files, and review limitations are recorded in
`assets/asset_manifest/naomi_character_manifest_v02.json`. The generated
`assets/asset_manifest/asset_manifest.json` includes a separate v02 entry and
retains the v01 record.

The face-and-shoulders preview is intended to show facial features; front,
right and back views show the full silhouette. Use
`NAOMI_VISUAL_QA.md` to record visual review. v02 remains an automated candidate
pending owner appearance review—not an approved or finished realistic Naomi.
It has no animation clips, LOD, Chapter 1 scene integration, or measured
in-game performance.

The builder creates sphere details from fixed procedural vertices and strips
volatile Date/RenderTime PNG metadata. Repeated builds with the same Blender,
MPFB2 and configuration produce byte-identical GLB and render outputs; the
native `.blend` file may differ in internal serialization bytes. Current
automated renders still fail the separate trouser-silhouette and garment-artifact
visual checks, so v02 is not ready for runtime integration.
