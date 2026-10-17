# Environment production: stage report

Pipeline, conventions and validation: see [`ENVIRONMENT_PIPELINE.md`](ENVIRONMENT_PIPELINE.md). Per-asset details: [`assets/asset_manifest/asset_manifest.md`](../assets/asset_manifest/asset_manifest.md).

| Stage | Scope | Status |
|---|---|---|
| 1 Modular architecture | Walls, openings, windows, floors, ceilings, corridor slices and junctions, doors | **Done (v1, untextured)** |
| 2 Opening-chapter environments | Corridor, office, Interview Room A, nursing station, 2 patient rooms (plus records archive) | **Done (v1, untextured)** |
| 3 Clinical and cinematic props | EHR terminal, clinical furniture, fixtures, interview camera markers | **Partly done.** 26 props and interview cameras. Medication cart, beds for other units, linen and emergency equipment still to do. |
| 4 Security, admin and research wings | | Not started |
| 5 Historic substructure | | Not started (the W0-B historic service door exists) |
| 6 Ward Zero canonical layout and anomaly states | | Not started. The state mechanism exists: `state_group` extras plus `WorldStateManager` on the gameplay branch. |
| 7 Apartment, parking, exterior | | Not started |
| 8 Polish | Textures/UVs, LODs, lightmap UV2, trim sheets | Not started |

## Stage 1–2 deliverables

| Deliverable | Location |
|---|---|
| Editable sources | `assets/blender/modular/FW_Modular_Kit.blend`, `assets/blender/clinical/FW_Props_Clinical.blend`, `assets/blender/clinical/FW_Chapter1_ClinicalWing.blend` |
| Godot exports | `assets/exports/modular/` (25), `assets/exports/clinical/props/` (26), `assets/exports/clinical/env/` (7) |
| Manifest | `assets/asset_manifest/asset_manifest.json` and `.md` (58 assets) |
| Renders | `assets/renders/stage1/` (kit, doors, props), `assets/renders/stage2/` (corridor, W0-B, interview room wide and over-the-shoulder, office, nursing station, archive, patient room, plan) |
| Generators | `tools/blender/*.py` |
| Godot validation | `tools/godot/validate_glb_imports.gd`: 58/58 assets pass in Godot 4.7 |

### Chapter 1 clinical wing (shared frame; all ENV_* placed at the origin)

- **`ENV_ClinicalCorridor_20m`.** 20 m long, 2.8 m clear. PVC dado protection, closed-profile anti-ligature handrails, 500 mm suspended ceiling with LED panels and return grilles, caged clock, 2 CCTV domes, card readers, intercoms and room signs. Glazed nursing-station counter, and a one-way observation window into Interview Room A with an open/closed shutter state. Doors: 8 in total, including the ward-entry double door and the sealed W0-B historic service door with its removable seal state.
- **`ENV_InterviewRoom_A`.** Floor-fixed table, weighted moulded chairs (clinician nearest the exit, which the build script checks), duress strip, acoustic panels, tamper-resistant lights, solid ceiling and caged clock behind the patient. It carries 5 camera markers (establishing, both over-the-shoulder shots, both close-ups), seat and eye-line markers, and a standing-staff marker.
- **`ENV_PsychiatristOffice`.** Desk facing the door with the window behind, EHR workstation (UV'd screen for a live viewport), visitor chairs, filing, bookcase, certificates, half-lowered blind, transfer-summary document, and Dr Voss's marker.
- **`ENV_NursingStation`.** Counter desk with EHR terminal, phone, charts, filing, notice board and clock, plus the charge nurse's marker facing the counter.
- **`ENV_RecordsArchive`.** Archive shelving with record boxes, reading desk and the 1968 roster document.
- **`ENV_PatientRoom_01` / `_02`.** Anti-ligature plinth bed and open wardrobe, tamper-resistant light, exterior window, solid ceiling. No CCTV in bedrooms (privacy).

## Design assumptions (labelled, pending creative review)

- The corridor is 2.8 m clear and ceilings are 3.0 m throughout.
- Interview Room A's observation window opens onto the main corridor. The fixture dialogue mentions an orderly closing an observation window, so the shutter is placed on the observer side.
- Interview and patient-room doors swing outward (anti-barricade). Office and staff doors swing inward.
- W0-B is placed as a historic service door at the south end of the clinical corridor, as a Chapter 1 story hook. Ward Zero itself (Stage 6) lies beneath.
- Room numbering, signage text and staff positions are provisional.

## Known issues and unfinished work

- **No textures or UVs yet** (flat PBR colours). Only the EHR screen and sign faces have UVs. Lightmap UV2 is not generated; use Godot's import option or wait for Stage 8.
- **No characters.** Gameplay uses capsule stand-ins.
- **Door leaves get static collision only.** Gameplay animates the leaf node, and the collider follows.
- **Exterior windows show a preview backdrop in renders only.** Godot needs an exterior or skybox solution (Stage 7).
- **Preview renders use Cycles on CPU with denoising.** Lighting in Godot comes from the `LIGHTMARK_*` markers and is tuned separately.
- **Blender MCP was not available in the production session.** Assets were generated headless with Blender 5.0.1's Python module, which produces identical `.blend` and `.glb` files. The `.blend` files need Blender 5.0+ to open.
