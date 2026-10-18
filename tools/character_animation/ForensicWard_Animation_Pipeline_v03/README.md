# Naomi v03 → Reusable character animation pipeline

This is an **add-on**, not a modification to current GitHub code. Source audit: `claude/naomi-v03` on 2026-10-18.

## Tools
- `tools/inspect_blender_rig.py` — read-only inventory of real armatures, bound meshes, shape keys, and bone names.
- `tools/create_animation_actions.py` — **experimental** action authoring for an existing `.blend`, only after bone name mappings are validated. It refuses overwrite; does **not** auto-export GLB. Needs Blender 5.2 local validation.
- `tools/inspect_glb.py` — read-only GLB inspector reporting actual animation channels and morph target names.
- `configs/animation_template.json` — semantic clips but deliberately unmapped. Never run with placeholders.
- `MASTER_ANIMATION_ADDENDUM.docx` — recommended gates and Claude instructions.

## Usage
```bash
/Applications/Blender.app/Contents/MacOS/Blender -b /path/to/Naomi_Bennett_v03.blend -P tools/inspect_blender_rig.py -- --out /tmp/naomi_rig_report.json
python3 tools/inspect_glb.py /path/to/Naomi_Bennett_v03.glb
python3 -m unittest discover -s tests -v
```

Do **not** invoke `create_animation_actions.py` until real bone names are recorded. It generates an editable test `.blend`, but the developer must still validate Blender 5.2 action compatibility and glTF export on the Mac.

## Important observed Godot issue to test
`CharacterActingAdapter._apply_body` finds `idle_neutral` if a semantic clip is unavailable, but attempts to play the original missing semantic clip. Implement a regression test and safe fallback if this is reproduced on current Godot 4.7.
