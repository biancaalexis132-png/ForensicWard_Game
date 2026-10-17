# Environment production: stage report

Pipeline, conventions and validation: see [`ENVIRONMENT_PIPELINE.md`](ENVIRONMENT_PIPELINE.md). Per-asset details: [`assets/asset_manifest/asset_manifest.md`](../assets/asset_manifest/asset_manifest.md).

| Stage | Scope | Status |
|---|---|---|
| 1 Modular architecture | Walls, openings, windows, floors, ceilings, corridor slices and junctions, doors | **Done (v1, untextured)** |
| 2 Opening-chapter environments | Corridor, office, Interview Room A, nursing station, 2 patient rooms (plus records archive) | **Done (v1, untextured)** |
| 3 Clinical and cinematic props | EHR terminal, clinical furniture, fixtures, interview camera markers, medication, ward-bed, linen and emergency equipment | **Done (v1, untextured).** 36 props and interview cameras. The nursing station now carries the medication cart (with sharps bin), resuscitation trolley, AED cabinet and hand-gel dispenser; the other Stage 3 props are library-only until the rooms that need them exist. |
| 4 Security, admin and research wings | Security corridor, visitor screening, credentialing, records, medical director's office, conference room, secure interview suite, security control, surveillance, maintenance access, restricted lift lobby; research reception, research and restricted corridors, physician offices, data analysis, records archive, protocol office, assessment and observation rooms, lab support, sample storage | **Done (v1, untextured).** 4a: 13 props, 11 rooms. 4b: 8 props, 12 rooms on the research level the restricted lift serves. |
| 5 Historic substructure | | Not started (the W0-B historic service door exists) |
| 6 Ward Zero canonical layout and anomaly states | | Not started. The state mechanism exists: `state_group` extras plus `WorldStateManager` on the gameplay branch. |
| 7 Apartment, parking, exterior | | Not started |
| 8 Polish | Textures/UVs, LODs, lightmap UV2, trim sheets | Not started |

## Stage 3 deliverables

| Deliverable | Location |
|---|---|
| Editable source | `assets/blender/clinical/FW_Props_Clinical_Stage3.blend` |
| Generator | `tools/blender/build_stage3_props.py` (builders in `tools/blender/fw_assets.py`, `STAGE3_PROP_BUILDERS`) |
| Godot exports | `assets/exports/clinical/props/` (10 new, 36 in total) |
| Render | `assets/renders/stage3/props_stage3.png` |
| Godot validation | 68/68 assets pass `tools/godot/validate_glb_imports.gd` in Godot 4.7 |

| Asset | Notes |
|---|---|
| `PROP_Cart_Medication` | Locking 6-drawer cart, key lock, push handles, MAR clip-board, castors |
| `PROP_Bed_Hospital_Adjustable` | Profiling bed with split side rails and castors. Medical bay only: it is not anti-ligature (the ward bed is `PROP_Bed_AntiLigature`) |
| `PROP_Trolley_Linen` | Lidded linen skip on castors |
| `PROP_Cart_Crash_Resus` | Resuscitation trolley with defibrillator (separate UV'd screen), CPR board, side oxygen cylinder, seal tag |
| `PROP_Cabinet_AED_Wall` | Glazed wall cabinet with AED and sign; wall-mounted, no collision |
| `PROP_Cylinder_Oxygen_Trolley` | Cylinder with white shoulder, valve and gauge on a two-wheel trolley. No markings are claimed |
| `PROP_Monitor_VitalSigns_Stand` | Observations monitor on a 5-star stand (separate UV'd screen), basket and cuff |
| `PROP_Bin_Sharps` | Counter-top sharps container with a blank label |
| `PROP_Dispenser_HandGel` | Wall dispenser; wall-mounted, no collision |
| `PROP_Wheelchair` | Transit wheelchair |

All ten are staff-only or supervised-area items, recorded as such in the manifest. Shapes are generic and not modelled on any manufacturer's product.

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
- **`ENV_NursingStation`.** Counter desk with EHR terminal, phone, charts, filing, notice board and clock, plus the charge nurse's marker facing the counter. Stage 3 equipment: locking medication cart with a sharps bin on the west wall, resuscitation trolley, wall AED cabinet and hand-gel dispenser on the south wall, all clear of the inward door swing.
- **`ENV_RecordsArchive`.** Archive shelving with record boxes, reading desk and the 1968 roster document.
- **`ENV_PatientRoom_01` / `_02`.** Anti-ligature plinth bed and open wardrobe, tamper-resistant light, exterior window, solid ceiling. No CCTV in bedrooms (privacy).

## Stage 4a deliverables (security and admin wing)

| Deliverable | Location |
|---|---|
| Prop source | `assets/blender/security/FW_Props_Security.blend` |
| Prop exports (13) | `assets/exports/security/props/*.glb` |
| Wing source | `assets/blender/security/FW_SecurityAdminWing.blend` |
| Room exports (11) | `assets/exports/security/env/*.glb` |
| Renders | `assets/renders/stage4/` (props sheet, six room shots, plan) |
| Build script | `tools/blender/build_stage4_security_admin.py` (`--fast` skips renders) |

- **Layout.** The wing shares the Chapter 1 frame and starts at y = 20, directly north of the clinical corridor. A 20 m concrete security corridor (x ±1.5, y 20–40) has a double-door interlock at y = 32 and a secure door into the restricted lift lobby (y 40–44).
- **West side, south to north:** visitor screening (walk-through detector, belongings lockers, waiting seats, visitor entrance on the west wall), credentialing (badge printer, access-control terminal), records office, medical director's office (Dr. Voss marker, window), conference room.
- **East side, south to north:** secure interview suite (the clinician's seat is nearer the exit, enforced by an assert), security control (console, 3x2 video wall, key cabinet, reinforced window onto the corridor, Hale marker), surveillance monitoring, maintenance access (electrical panel, pipes, a service hatch hinting at Stage 5).
- Every door has a badge reader and a room sign. Each room has camera markers, collision and light markers; the security rooms use cooler light.

## Stage 4b deliverables (research wing)

| Deliverable | Location |
|---|---|
| Prop source | `assets/blender/research/FW_Props_Research.blend` |
| Prop exports (8) | `assets/exports/research/props/*.glb` |
| Wing source | `assets/blender/research/FW_ResearchWing.blend` |
| Room exports (12) | `assets/exports/research/env/*.glb` |
| Renders | `assets/renders/stage4/research_*.png`, `props_research.png` |
| Build script | `tools/blender/build_stage4_research.py` (`--fast` skips renders) |

- **Where it is.** The research wing is its own level, the one the restricted lift serves. It uses the same x/y as the Chapter 1 frame with its floor at z = 0, so its lift doors stand directly above the security wing's (x 0, y 44; asserted in the script). Load it as a separate level. If both levels ever share one scene, raise every research `ENV_*` by the same floor height.
- **Layout.** Reception and the lift landing (y 40–44) open south into a 12 m research corridor. West side: physician offices A and B, data analysis office. East side: clinical assessment room, observation and monitoring room (one-way window into the assessment room), lab support. A badge-and-PIN door at y = 28 leads to an 8 m restricted corridor that dead-ends at y = 20. Off it are the research records archive, the unsigned protocol office and secure sample storage.
- **Tone.** It reads as a clean, legitimate research unit. The unease comes only from small details, each tagged `story_tag: research_inconsistency` with a `godot_hint`: the protocol office has no sign and the heaviest lock; whiteboards were wiped in a hurry; one archive bay was emptied; office B was cleared out; one freezer has a second padlock and no label; the observation room seats more observers than one assessment needs; a second camera is aimed at the assessment chair. The hints describe what the player sees, never a clinical fact, and the protocol binder is marked `clinical_review_status: PENDING`.

## Design assumptions (labelled, pending creative review)

- The corridor is 2.8 m clear and ceilings are 3.0 m throughout.
- Interview Room A's observation window opens onto the main corridor. The fixture dialogue mentions an orderly closing an observation window, so the shutter is placed on the observer side.
- Interview and patient-room doors swing outward (anti-barricade). Office and staff doors swing inward.
- W0-B is placed as a historic service door at the south end of the clinical corridor, as a Chapter 1 story hook. Ward Zero itself (Stage 6) lies beneath.
- Room numbering, signage text and staff positions are provisional.
- Stage 4a: the wing's position north of the clinical corridor, the room adjacencies and the Voss and Hale marker positions are assumptions; the GDD names the rooms but not a floor plan.
- Stage 4b: putting the research wing on the lift's upper level, its room layout, the receptionist marker and every storytelling detail are assumptions for creative review. No research staff are named in the GDD, so no named character markers are placed.

## Known issues and unfinished work

- **No textures or UVs yet** (flat PBR colours). Only the EHR screen and sign faces have UVs. Lightmap UV2 is not generated; use Godot's import option or wait for Stage 8.
- **No characters.** Gameplay uses capsule stand-ins.
- **Stage 3 props placed so far:** only the nursing station. The hospital bed, linen skip, oxygen trolley, observations monitor and wheelchair wait for the medical bay and clinic room (later stages).
- **One-way glass in Cycles previews looks mirrored from both sides**, because Cycles renders back faces. Godot culls back faces by default, so the observer side should see through. This has not been checked in Godot yet (assessment room window and Interview Room A).
- **Door leaves get static collision only.** Gameplay animates the leaf node, and the collider follows.
- **Exterior windows show a preview backdrop in renders only.** Godot needs an exterior or skybox solution (Stage 7).
- **Preview renders use Cycles on CPU with denoising.** Lighting in Godot comes from the `LIGHTMARK_*` markers and is tuned separately.
- **Blender MCP was not available in the production session.** Assets were generated headless with Blender 5.0.1's Python module, which produces identical `.blend` and `.glb` files. The `.blend` files need Blender 5.0+ to open.
