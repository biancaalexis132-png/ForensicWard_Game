# Naomi Blender character builder

This reproducible base-model build is pinned to Blender 5.2.2 LTS and MPFB2
2.0.18. Install and enable MPFB2 in Blender's Extensions preferences before
running it; the builder checks both versions and stops rather than using an
untested API. It does not download assets or embed MPFB code.

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
`assets/asset_manifest/naomi_character_manifest.json`.

The result is an automated, rigged base for review—not a finished realistic
Naomi. Facial likeness, pulled-back twist silhouette, scrub seams and
deformation need manual visual review. It has no performance clips or Chapter 1
scene integration.
