# Character animation toolkit (inspection and export utilities)

The single animation workflow for every character is `tools/character_animation/build_animated_character.py`, with `clip_library.json`, one profile per character in `profiles/`, and the rules in `CHARACTER_ANIMATION_STANDARD.md`. This folder keeps the read-only and export utilities that the workflow and the Mac runs use alongside it.

## Tools
- `tools/inspect_blender_rig.py`: read-only inventory of armatures, bound meshes, shape keys and bone names. Run it first on any new character to fill in its profile's role-to-bone map.
- `tools/inspect_glb.py`: read-only GLB inspector. It reports animation channels and morph target names, and with `--require-clip` it fails when a clip is missing or has no channels.
- `tools/export_animated_glb.py`: verified on the owner's Mac (Blender 5.2.2, PR #51). It re-exports an already animated .blend to a new GLB with one glTF animation per action. Use it after hand-editing clips in Blender. The builder exports on its own, with sampling plus optimisation, so each clip still carries only the bones it animates.
- `configs/staff_bennett_v03_mapping.json` and `reports/Naomi_Bennett_v03_rig_inventory.json`: the bone mapping and rig inventory recorded on the Mac. `profiles/staff_bennett.json` must agree with them, and `tests/test_bennett_mapping.py` checks this.

`create_animation_actions.py` was removed. It wrote rotations in each bone's local axes, which depend on the rig's bone roll. The builder writes clips in the character's own frame (flex, turn, tilt, raise, swing), so the same clip library fits every rig. To rebuild the Mac validation asset `Naomi_Bennett_v04_local`, check out commit `0ebb3d6` and follow `LOCAL_MAC_RUN.md`.

## Usage
```bash
B=/Applications/Blender.app/Contents/MacOS/Blender
$B -b assets/blender/characters/Naomi_Bennett_v03.blend -P tools/character_animation/ForensicWard_Animation_Pipeline_v03/tools/inspect_blender_rig.py -- --out /tmp/naomi_rig_report.json
$B --background --python-exit-code 1 --python tools/character_animation/build_animated_character.py -- --profile tools/character_animation/profiles/staff_bennett.json
python3 tools/character_animation/ForensicWard_Animation_Pipeline_v03/tools/inspect_glb.py assets/exports/characters/Naomi_Bennett_v04.glb --require-clip idle_neutral --require-clip idle_breathing --require-clip listen_neutral --require-clip stand_conversational
(cd tools/character_animation/ForensicWard_Animation_Pipeline_v03 && python3 -m unittest discover -s tests -v)
```

## Fixed: idle fallback in `CharacterActingAdapter._apply_body`
When a rig lacked a requested clip, the adapter found the player that had `idle_neutral` but then asked it to play the missing clip, so the rig froze. It now plays `idle_neutral`. `scripts/tests/test_naomi_acting.gd::test_adapter_falls_back_to_idle_neutral_for_a_missing_clip` covers this.
