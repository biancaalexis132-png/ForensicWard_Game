# Diagnostic source renders — not in-game captures

Source: `assets/blender/characters/Naomi_Bennett_v06_mpfb.blend`, unchanged.
Provenance/licence inherit the existing Naomi v06 manifest; no new art, texture,
sculpting or clinical content was created. Generated with official bpy 5.2.2
LTS, CPU Cycles, 12 samples, seed 0, denoising, 512×640; renderer settings and
camera/pose instructions are in `tools/character_animation/audit_naomi_source.py`.
These stills are source diagnostics, not owner approval or evidence of Mac Metal.

Reproduce from the repo root in Blender 5.2.2:

```sh
blender -b --python-exit-code 1 --python tools/character_animation/audit_naomi_source.py -- --report work/source.json --summary --render-dir work/source-review
```

Expected exit 1: plain v06 is still missing 22 visemes. MPFB source has no
blocking structural failures. JSON summary is adjacent to these images.

Inspection:

- `source_face_neutral.png`: face with neutral shapes.
- `source_face_blink.png`: blink=1 closes the eyes but has a wavy, raised dark
  lid rim. **Significant** visual defect; natural closure acceptance unresolved.
- `source_body_neutral.png`: jagged/scalloped trouser hems above footwear.
  **Significant** garment defect. Shoes have an angular silhouette; **cosmetic**
  at this resolution, pending closer target-device review.
- `source_body_chart.png`: chart-indication action frame 30. No obvious body
  tearing in this view; this isolated pose cannot prove absence during motion.

Remaining **blocking** gates: consistent viseme candidate selection/playback;
Mac frame time, full motion/clipping/gaze/placement/shadow validation and an
in-game review video after technical readiness. No cosmetic fixes were applied.
