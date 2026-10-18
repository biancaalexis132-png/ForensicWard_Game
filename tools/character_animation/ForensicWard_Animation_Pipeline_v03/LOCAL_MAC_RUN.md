# Local Mac run: Naomi v04_local (2026-10-18)

First run of this toolkit on the owner's Mac. It produced `Naomi_Bennett_v04_local`, a pipeline validation build. The cloud thread's `Naomi_Bennett_v04` on `claude/naomi-animation-v04` is the animation candidate; this run only proves the toolkit, Blender 5.2.2 and Godot 4.7.2 work together on the Mac.

## Tools found (nothing installed or reinstalled)

| Tool | Path | Version |
|---|---|---|
| Blender | `/Applications/Blender.app/Contents/MacOS/Blender` | 5.2.2 LTS |
| MPFB2 | `~/Library/Application Support/Blender/5.2/extensions/blender_org/mpfb` | build 20261010, loads cleanly |
| Godot | `/Applications/Godot.app/Contents/MacOS/Godot` | 4.7.2.stable.official |

MPFB2 is installed but has no skin, eyebrow, eyelash or hair asset packs in its data folder, and its expressions need a face rig that v03's 53-bone game_engine rig lacks. So this run did not use MPFB.

## Commands (run from the repository root)

```sh
B=/Applications/Blender.app/Contents/MacOS/Blender
T=tools/character_animation/ForensicWard_Animation_Pipeline_v03
$B -b assets/blender/characters/Naomi_Bennett_v03.blend -P $T/tools/inspect_blender_rig.py -- --out /tmp/naomi_rig.json
$B -b assets/blender/characters/Naomi_Bennett_v03.blend -P $T/tools/create_animation_actions.py -- \
  --out assets/blender/characters/Naomi_Bennett_v04_local.blend --rig Naomi_Bennett_Rig --map $T/configs/staff_bennett_v03_mapping.json
$B -b assets/blender/characters/Naomi_Bennett_v04_local.blend -P $T/tools/export_animated_glb.py -- \
  --out assets/exports/characters/Naomi_Bennett_v04_local.glb --rig Naomi_Bennett_Rig \
  --require idle_neutral --require idle_breathing --require listen_neutral
python3 $T/tools/inspect_glb.py assets/exports/characters/Naomi_Bennett_v04_local.glb \
  --require-clip idle_neutral --require-clip idle_breathing --require-clip listen_neutral
(cd $T && python3 -m unittest discover -s tests -v)
```

Both Blender scripts refuse to overwrite their output, so delete your own previous output first when rebuilding.

## What had to change

- **Bone mapping.** `configs/staff_bennett_v03_mapping.json` fills the template with names from the rig inventory (`reports/Naomi_Bennett_v03_rig_inventory.json`): chest `spine_03`, neck `neck_01`, head `head`. Clip names follow Naomi's acting cues (`idle_neutral`, `idle_breathing`, `listen_neutral`).
- **No export step.** The toolkit stopped at a `.blend`. `tools/export_animated_glb.py` exports every action as its own glTF animation, refuses to overwrite, and fails if a required action is missing or empty. It reads curves from Blender 5's layered actions. Sampling is off, so each clip carries only the bones it animates (2 channels instead of 159).
- **Clip length.** Every clip was fixed at 25 frames (about 1 s), too fast for breathing. `create_animation_actions.py` now takes an optional per-clip `frames` value; the default stays 25.
- `tests/test_bennett_mapping.py` checks the mapping against the recorded rig.

## Results

- The GLB has 9 meshes, 1 skin with 53 joints, and 3 clips of 5 s, 4 s and 3 s. The v03 mesh and materials are unchanged.
- In Godot 4.7.2 all three clips load and move their bones (about 1°, 2° and 3° at mid-clip). Captures from the nursing station are in `docs/design/characters/Naomi_Bennett_Character_Production_v1/ingame_review_v04_local/`.
- Blender warns that some vertices have more than 4 joint influences. glTF keeps the 4 strongest, as it did for v03.
- Godot imports the clips without looping, so the acting adapter has to set loop mode.

The amplitudes are deliberately small. This is a validation set, not final acting.
