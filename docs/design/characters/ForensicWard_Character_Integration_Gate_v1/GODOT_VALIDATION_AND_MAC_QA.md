# Godot and Mac acceptance checklist

## Automated acceptance gate (after actual model exists)
1. Confirm model GLB binary integrity using `tools/check_character_glb.py` (packaged).
2. Import the `.glb` in the Godot 4.7 editor; check Godot's import log for errors. Reimport is not equivalent to actually playing the game.
3. Load and instantiate the model in a small, isolated test scene before the main ward. Verify it has visible surfaces and physically plausible world scale.
4. If the builder claims a rig: audit Skeleton3D, actual deformation, skinning influence, body poses, facial controls, and animation naming. Structural JSON alone cannot verify this.
5. Swap the Chapter 1 Naomi visual behind the existing `WardCharacter` interface; preserve character_id `staff_bennett`, click/interaction prompts, door collision and current voice-line IDs.
6. Verify fallback if asset missing/corrupt, audio missing/interrupted, animation missing, save/load, pause/resume, zone transition, and scene reload.
7. Verify seated Elias separately: do not squash humanoid mesh to 0.65 height; set authored seated transform/rig pose and re-evaluate collider requirements.
8. Ensure materials are packaged and legal source attribution/license text is committed, including any MPFB/MakeHuman base asset and third-party garment/hair inputs.

## Manual Apple Silicon 8GB benchmark (owner hardware)
Record MacOS/Godot version, rendering backend, game display resolution, scene name, battery/thermal situation, and test duration. Compare baseline capsule and new model in exactly the same scene.

| Check | Baseline | With character | Acceptance |
|---|---|---|---|
| FPS median / 1% low | measure | measure | no unacceptable stutter |
| Frame-time spikes | measure | measure | no recurrent hitch |
| Memory footprint/pressure | measure | measure | no system memory pressure warning |
| Zone swap into clinical wing | measure | measure | no extended load pause |
| Dialogue start/stop | measure | measure | no crash or clipped audio |
| Lip-sync & face | N/A | visually review | no distracting clipping |
| Walk/idle/seated | N/A | visually review | no obvious distortion |

Numerical target limits require owner signoff after profiling; do not claim 60 FPS without measurement.

## Completion definition
`CIG-1` is complete only when the actual `.blend`, `.glb`, preview renders, license/provenance sheet, Godot test results and owner Mac benchmark are linked in its PR. Documentation-only packages are not model integration.
