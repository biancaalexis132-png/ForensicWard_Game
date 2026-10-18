# The Forensic Ward — Character Integration Gate (CIG-1)

Status: **proposal and executable preflight validator**; NOT an integrated Godot model and NOT a successful hardware benchmark. Applies to the first finished Naomi `.glb`, then Voss, Elias, Rahman, Hale, Mara and Jordan.

## Why this milestone
`scenes/props/Character.tscn` is currently a placeholder. `scripts/world/Character.gd` expects `$Body/Mesh`, `$Body/Collision`, `$Interactable`, `$NameLabel`; for a seated character it scales the placeholder mesh and disables collision. Naomi has an independent cue adapter. Do not replace the scene wholesale: add a visual child/slot while preserving those paths and existing interaction behavior.

## Files
- `CHARACTER_INTEGRATION_CONTRACT.md`: proposed integration/rig contract, safe switching, asset budget
- `GODOT_VALIDATION_AND_MAC_QA.md`: exact review gates and Mac manual benchmark checklist
- `AGENT_HANDOFF.md`: Copilot implementation instructions with branch ownership
- `tools/check_character_glb.py`: standard-library GLB structural audit; does not replace Godot import/animation/hardware validation
- `tools/test_check_character_glb.py`: minimal unit tests

## Usage
Run from anywhere, using an actual exported `.glb` path (once it exists):

`python3 tools/check_character_glb.py /path/to/character.glb --json-out /path/to/audit.json`

Exit 0 means the GLB container is structurally readable and basic mesh presence checks passed. It does **not** mean the model is realistically shaded, skinned, has complete animations, legal provenance, or renders well in Godot.

The first character asset must be independently inspected, permitted for the game's distribution, imported in Godot 4.7 and tested on the owner's 8GB Mac before other builders adopt its rig and export conventions.
