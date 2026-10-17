# Chapter 1: playable clinical wing

`Main.tscn` now loads `scenes/world/Chapter1Ward.tscn`: the Blender-built clinical wing (`assets/exports/clinical/env/`), wired to gameplay by `data/world_chapter1.json`. The Sprint 1 greybox (`scenes/world/HospitalGreybox.tscn`) remains as a development sandbox. Nothing loads it.

## How it works

`AuthoredWorld` (`scripts/world/AuthoredWorld.gd`) instances every environment listed in the world file, then builds gameplay on top of the imported nodes:

| Imported node | Becomes |
|---|---|
| `LIGHTMARK_*` | Shadowed SpotLight3D pointing down (FlickerLight where `flicker_lights` lists it; it respects the flashing-lights accessibility setting) |
| `Door_*` (extras `category: door`) | `ImportedDoor`: hinged leaves, access lock from `required_access`, swing direction and messages from the world file, saved open/closed state |
| Nodes listed in `interactables` | `ImportedInteractable`: EHR census, clue terminal or document pickup (pickups disappear and record provenance) |
| `MARK_*` listed in `characters` | WardCharacter stand-ins (Elias is seated) |
| `spawn_marker` | `PlayerSpawn` used by Main |
| Nodes with `state_group` extras | Shown or hidden by `WorldStateManager` (saved, reversible) |

Unknown node names are collected in `AuthoredWorld.unresolved` and reported as errors. The world tests require the list to be empty.

## Walkthrough (about 5 minutes)

1. Spawn at the south end of the corridor, facing north. Behind you is the sealed **W0-B** door. The panel on the left wall beside it is the **Security Access Log** (`clue_access`).
2. **Office** (first door on the left): Dr Voss, the **EHR Workstation**, and the **Transfer Summary** on the desk (`clue_transfer`).
3. **Nursing station** (second door on the left, counter beyond it): talk to **Nurse Bennett** to get the archive badge.
4. **Records Archive** (last door on the left): take the **1968 Ward Roster** from the reading desk (`clue_roster`).
5. **Interview Room A** (third door on the right, past the observation window): Elias Ward is seated at the table.
6. **Patient rooms 01 and 02** (first and second doors on the right) are locked. The **ward entry** at the north end is out of scope for Chapter 1.
7. Press **Esc → Save**, then move away, then **Load**. Doors, clues, environment states and position are restored.

## Story hooks for later sprints

- `WorldStateManager.set_state("interviewA_observation_shutter", "closed")` closes the observation shutter (the orderly beat in the Elias interview).
- `WorldStateManager.set_state("w0b_seal", "removed")` removes the W0-B seal. Then grant `access_ward_zero` to let the door open.
