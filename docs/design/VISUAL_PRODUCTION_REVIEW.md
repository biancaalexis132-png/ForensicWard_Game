# Visual production review: characters and Ward Zero

**Status:** proposal for owner approval. Nothing here is approved canon, nothing has been implemented, and no character model, scene or environment has been changed.
**Reviewed:** 2026-10-17 by Claude Code, against `main` at `e533e8b` (PR #24 merged the creative references).
**Branch:** `claude/visual-direction-review` (draft PR, never merged by an agent).

## How to read this

Sources were ranked as the owner asked: approved design and clinical records first, generated imagery last.

1. `docs/design/GDD_AMENDMENTS.md` (owner decisions of 2026-10-17)
2. Master Design Bible v1.1 and its package files `01_MASTER_DESIGN_BIBLE.md`, `03_CLINICAL_PATIENTS_AND_RULES.md`, `05_AUDIO_VISUAL_AND_ACCESSIBILITY.md` and `09_SUPERNATURAL_AND_FOUNDATION_DECISIONS.md`. These came from the project upload; they are **not in the repository**. See open decision D9.
3. `docs/design/The_Forensic_Ward_Master_GDD_v0.1.docx` (locked; §5 characters, §12 Chapter 1 beats)
4. Game data: `data/staff.json`, `data/patients.json`, `audio/voice_profiles.json`, `data/world_chapter1.json`
5. `docs/F0_FOUNDATION_AUDIT.md` (open conflicts C1 to C14)
6. The reference package: `Ashcroft_Character_Reference_Guide.pdf`, `README_CHARACTER_ASSETS.md`, `README_WARD_ZERO_PACKAGE.md`, then the images

Each finding says whether it was **checked** against a file or is **inferred** from viewing an image. Ages and ethnicities read from a generated face are always inferred.

---

## 1. Character-by-character assessment

### Summary

| Character | Written guide vs canon | Portrait vs guide | Ensemble board | Verdict |
|---|---|---|---|---|
| Naomi Bennett | Consistent (Charge Nurse) | **Mismatch:** the guide says Black woman; the portrait appears to show a light-skinned woman | Wrong title ("Chief Nurse") and age ("early 30s") | Keep the written guide; regenerate the portrait |
| Evelyn Voss | Consistent (Medical Director) | Reads younger than early 50s; brown tweed and turtleneck, not charcoal or navy tailoring | Wrong role ("Attending Psychiatrist"), age ("late 30s") and "enigmatic" | Keep the written guide; regenerate the portrait |
| Marcus Hale | Title is "Security Director" in GDD and data, "security chief" in v1.1 | **Violates the guide's own guardrail:** tactical plate-carrier vest | Same vest, "Head of Security" | Regenerate without tactical gear |
| Leila Rahman | **Pre-existing canon conflict** (see below) | Reads around 30, not late 30s; otherwise fits | Wrong role ("Research Psychologist"), age ("late 20s") | Owner must fix her role first |
| Elias Ward | Consistent (29, Chapter 1 patient) | **Contradicts the clinical record:** sweaty and dishevelled with dark eye circles; reads mid-30s | Labelled "Patient — Ward Zero", "haunted, fractured, unstable", spiral pendant and spiral sketch, barefoot | Reject both images for modelling |
| Mara Ellis | Consistent (37, Chapter 1 patient, draft) | **Contradicts the clinical record:** dishevelled, no cardigan; reads late 20s | Labelled "Patient — Ward Zero", "otherworldly", nightgown, barefoot, teddy bear | Reject both images for modelling |

### Naomi Bennett, Charge Nurse

- **Canon (checked):** "Nurse Naomi Bennett", Charge Nurse, in GDD §5 and `data/staff.json` (`staff_bennett`). In the v1.1 bible she is practical, responsive, slightly dry, a patient-safety advocate who knows some irregular patient-movement patterns but not the whole truth. Voice `af_sarah`, "Brisk, practical, warm under pressure."
- **Guide:** Charge Nurse, early 40s, Black woman, navy scrubs, practical natural hairstyle. This agrees with canon. Canon itself sets no age or appearance; the bible says "all appearances are proposals".
- **Portrait (inferred):** appears to depict a light-skinned woman with loose dark curls. That does not match the written casting. The navy top, stethoscope and expression are right.
- **Ensemble board:** "Chief Nurse", "Early 30s", "tired". The title and age are wrong.
- **Corrections:** regenerate the portrait to the written guide. Add scrub jacket or cardigan layering for night shifts, a badge on a breakaway lanyard (ligature safety), a watch, and a pen light. Avoid a stethoscope draped as a costume signifier; a nurse on a psychiatric unit usually carries one in a pocket or uses the station's.

### Dr Evelyn Voss, Medical Director

- **Canon (checked):** Medical Director (GDD §5, `staff_voss`). In the bible she is precise, institutionally loyal, with defensible procedural explanations and concealed knowledge of earlier concerns, and "not cartoonishly malevolent". Voice `bf_emma`, en-GB, "Composed, measured, faintly formal".
- **Guide:** early 50s, tailored charcoal or navy, understated jewellery, administrative badge. Agrees with canon.
- **Portrait (inferred):** reads late 30s to mid 40s; brown tweed jacket over a black turtleneck. The turtleneck and dark styling lean "mysterious", which the guide's guardrail warns against.
- **Ensemble board:** "Attending Psychiatrist, late 30s", keywords "enigmatic", a coat silhouette. Wrong on role and age.
- **Corrections:** regenerate at early 50s with visible grey and fine lines; a navy or charcoal suit or a dress with a jacket; a blouse rather than a turtleneck; reading glasses on a chain or in hand; a medical director's badge. Her authority should come from posture and order, not shadow.

### Marcus Hale, Security Director

- **Canon (checked):** "Security Director" in GDD §5, `data/staff.json` and `voice_profiles.json` ("low, clipped, guarded"); the v1.1 bible says "clipped security chief". He knows badge logs, believes systems are verifiable, and must not grant access for friendship.
- **Guide:** mid 40s, institutional charcoal uniform, radio, badge, plausible duty belt, "avoid militarized tactical styling".
- **Portrait and ensemble (inferred):** a black tactical plate carrier with MOLLE webbing, an earpiece and a radio on the chest; the ensemble shows a "SECURITY" vest and a badge patch. This is the styling the guardrail forbids, and it reads as corrections or SWAT rather than hospital security.
- **Title:** use "Security Director" on screen. It is what the data and voice line already say. "Head of Security" and "Warden" (concept board 1) are wrong; a forensic hospital has no warden.
- **Corrections:** a charcoal or navy uniform shirt or a blazer over a polo with an embroidered hospital patch; ID; radio on the belt; keys on a retractable reel; no visible weapon, cuffs, vest or tactical gloves. Proposal: as director he wears a blazer over the uniform shirt, so he reads as a manager rather than front-line staff. Any restraint or seclusion equipment belongs to clinical staff and policy, not to his costume.

### Dr Leila Rahman

- **Canon conflict (checked, pre-existing):** three sources disagree, and this is already open as F0 conflict C4.
  - GDD v0.1 §5: "Dr Leila Rahman, clinical pharmacist".
  - `audio/voice_profiles.json`: direction "Clinical pharmacist; precise and quick".
  - v1.1 bible: "expert psychiatric consultant" with strong differential-diagnosis discipline.
  - Reference guide: "Staff Psychiatrist", with the guardrail "NOT a research psychologist: maintain psychiatrist role from character bible".
  - She is not in `data/staff.json` yet (`staff_rahman` is reserved in `docs/ID_REGISTRY.md`).
- **Recommendation:** the owner decides between "Consultant Psychiatrist" (v1.1) and "Clinical Pharmacist" (GDD). If she is a psychiatrist, "Consultant Psychiatrist" avoids a clash with the protagonist, who is the staff psychiatrist (v1.1). Whichever is chosen, `voice_profiles.json` direction needs a matching edit later. Note: the "Dr" title fits both a psychiatrist and a PharmD.
- **Portrait (inferred):** reads late 20s to early 30s; round glasses, cardigan over a green top, pendant. The warmth fits; the age should rise to late 30s.
- **Ensemble:** "Research Psychologist, late 20s". Reject.
- **Corrections:** late 30s; business casual or a short clinic coat; badge, notebook and pen. Clothing should be ordinary for a US hospital, and any cultural or religious dress is a casting choice for the owner to make, not something to add or remove by default.

### Elias Ward, Chapter 1 patient

- **Canon (checked):** `pt_elias_ward`, age 29, competency-restoration transfer; mutism, reduced movement, possible posturing, poor intake; `clinical_review_status: PENDING_PSYCHIATRIST_REVIEW`. The v1.1 draft MSE reads "appearance neat, seated". Voice `am_echo`, "Rarely speaks; quiet, slow, flat".
- **Guide:** agrees, and adds "clean, comfortable inpatient clothing without stigmatizing restraints or exaggerated disarray", "no diagnosis visually inferred".
- **Portrait (inferred):** sweat-sheened skin, matted hair, dark circles and a hard stare; reads mid 30s or older. That is exactly the "exaggerated disarray" the guide forbids, and it contradicts the record's "appearance neat".
- **Ensemble:** labelled "Patient — Ward Zero" and "Key Figure"; keywords "haunted", "fractured", "unstable", "otherworldly"; spiral sketchbook and spiral pendant; barefoot in a hospital gown. This ties a patient's illness to the supernatural, which the owner and GDD §3 forbid, and Elias is not a Ward Zero patient in canon (the W0-B link is a record discrepancy).
- **Corrections:** a clean, neutral, age-appropriate face; short or medium tidy hair; a plain T-shirt or a sweatshirt and soft trousers in hospital-issue colours, or his own clothes per unit policy; non-slip socks or slip-on shoes. Posture states (still, seated, possible posturing) are animation states that need medical review, not costume. No personal props with symbolic meaning.

### Mara Ellis, Chapter 1 patient (draft)

- **Canon (checked, draft):** `pt_mara_ellis` is not in data yet; the v1.1 dossier gives age 37, a former records specialist, MSE "clean, alert and oriented, engaged though guarded", mood "frustrated and exhausted". Her link to W0-B is a document discrepancy about her aunt Lillian's records, not a supernatural one. No voice chosen yet.
- **Guide:** agrees; cardigan, simple practical personal items, "no horror costume".
- **Portrait (inferred):** long, wet-looking hair, flushed and blotchy skin, a grey T-shirt; reads late 20s. It contradicts "clean", the age and the cardigan.
- **Ensemble:** "Patient — Ward Zero", "Mid 20s", "vulnerable, intense, otherworldly"; nightgown, barefoot, teddy bear, a dead-tree drawing. These are horror tropes and reject the guide's guardrail.
- **Corrections:** 37; tidy hair (a low ponytail or clip) with tiredness shown only lightly; her own clothes with a cardigan; a folder of photocopies or a notebook only if the unit's property policy allows it in the interview room. Credibility must not be encoded in her appearance either way.

### Other images in the folder

- `Concept_Boards/ashcroft_concept_board_1.png` and `_2.png` (not named in the brief, but in the same folder) scramble the cast: "Dr Adrian Bennett, Chief Psychiatrist", "Dr Eleanor Voss", "Warden Marcus Mercer", "Dr Lillian Price, Medical Director", "Evelyn Price, Administrator" and others. They also set the game in "1980s–1990s", use a gothic asylum exterior and a red occult circle, and list **real actors as likeness references** (for example Clive Owen, Idris Elba, Robin Wright). Real-person likenesses breach the package's own rule and `AGENTS.md` §5 licensing. **Recommendation:** mark both boards and the ensemble board `SUPERSEDED — do not model` in a short README in their folders. Do not delete them; the owner decides.
- The ensemble board's footer (gothic castle labelled Ashcroft) contradicts the approved modern hospital.

---

## 2. Proposed visual canon sheet per recurring character

These sheets become canon only after the owner approves them. Ages and appearance come from the reference guide (owner's package), since the GDD and data are silent; clinical facts come from the records.

| Field | Naomi Bennett | Evelyn Voss | Marcus Hale | Leila Rahman | Elias Ward | Mara Ellis |
|---|---|---|---|---|---|---|
| Id | `staff_bennett` | `staff_voss` | `staff_hale` | `staff_rahman` (reserved) | `pt_elias_ward` | `pt_mara_ellis` (proposed) |
| On-screen title | Charge Nurse | Medical Director | Security Director | **D1: owner decides** | Patient | Patient |
| Age | early 40s | early 50s | mid 40s | late 30s | 29 (record) | 37 (draft record) |
| Casting (proposed) | Black woman | woman, owner to choose | man, owner to choose (the portrait reads Black) | South Asian woman | man, owner to choose | woman, owner to choose |
| Height and build (proposal) | 1.68 m, sturdy, grounded | 1.70 m, upright, slim | 1.85 m, broad, still | 1.63 m, light | 1.78 m, lean | 1.66 m, average |
| Silhouette cue | scrub top with layered cardigan; quick, purposeful stride | jacket with sharp shoulders; still hands | blazer over uniform shirt; radio on belt | open coat or cardigan; notebook held to chest | loose sweatshirt; seated, contained | cardigan; folder or notebook |
| Hair | natural, practical (locs, twists or a short natural cut) | neat low chignon or bob with grey | close crop, trimmed beard optional | shoulder length, tied back on the ward | short or medium, tidy | shoulder length, low ponytail |
| Wardrobe palette | navy `#2B3A55`, cardigan heather grey | charcoal `#3A3D42`, ivory blouse | charcoal `#33363B`, navy patch | sage `#7C8B78`, oat | soft grey `#9AA0A6`, washed blue | warm taupe `#8A7B6E`, cream |
| Badge | staff ID on breakaway lanyard | director ID on clip | security ID, radio | staff ID | patient wristband (no name or diagnosis visible to camera) | patient wristband |
| Signature props | pen light, watch, shift handover sheet | reading glasses, leather folio | radio, keys on reel, tablet for badge logs | notebook, pen | none | folder of photocopies (if allowed) |
| Expressions (5) | neutral, attentive, concerned, reassuring, firm | composed, sceptical, diplomatic, fatigued, reluctantly candid | professional, questioning, concerned, resolute, guarded | warm, analytical, concerned, assertive, encouraging | neutral rest, subtle alertness, eyes tracking, eyes averted, slight response | attentive, guarded, exhausted, reflective, cautiously hopeful |
| Voice (existing) | `af_sarah` | `bf_emma` (en-GB) | `am_onyx` | `af_aoede` (direction text needs updating after D1) | `am_echo` | none yet (D6) |
| Never | ominous lighting, cold expression | villain styling, turtleneck-in-shadow | tactical vest, weapon, cuffs | lab-coat "researcher" look | sweat, grime, gown-and-bare-feet, symbolic props, supernatural markings | nightgown, bare feet, toys, horror styling |

Hex values are proposals for the material palette; final values come from the turnaround sheets.

**Protagonist:** customisable (bible v1.1). First-person hands only in Chapter 1, plus a staff badge portrait. Hands need at least five skin tones and two sleeve options (white coat, plain jacket). No canon sheet is needed beyond that.

**Deliverables per character before any modelling** (from the package README): front, three-quarter, profile and back orthographic views; neutral A-pose; five expressions; wardrobe and prop close-ups; consistent lighting and scale; written provenance and licence.

---

## 3. Ward Zero environment inventory and missing assets

### Where Ward Zero sits

- `ENV_SealedConnectingCorridor` (Stage 5) ends in a bricked-up opening "towards Ward Zero" with a `state_group` so Stage 6 can open it. Ward Zero is reached only through the historic substructure, which is itself under the security wing's maintenance hatch and the restricted lift.
- The modern hospital (Stages 1 to 4b) stays maintained and humane. Nothing in this plan touches those wings except optional signage in Stage 8.

### What the references show, and whether it fits

| Board | Panel | Fits direction? | Notes |
|---|---|---|---|
| 02 Corridors | Ward corridor, stair, service passage, patient door, utility junction, level transition | **Yes.** The strongest board | Two-tone glazed block (pale green dado, dirty white above), overhead conduit and pipe runs, fluorescent tubes, caged service passage. Use as the primary architectural reference |
| 01 Master | Corridor, nurses' station, archive, stair, time-discrepancy detail | Mostly | Remove the red, blood-like floor stains in panels 01 and 04 |
| 01 Master | Treatment room | **No** | Restraint beds captioned "built for containment, not care". Replace with an ordinary period exam room |
| 01 Master | Mood panel and sticky note | **No** | Graffiti "Observation changes people" and the note "Same night, different time, still here" tell the player the answer. They also equate psychiatric observation with change |
| 03 Records | Nurses' station, archive, dead intercoms and chart racks, filing shelves | Yes | Good environmental storytelling |
| 03 Records | Patient record "Ward Zero, No. 0473" with photo, DOB, **Diagnosis** and "Committed 09/26/1978" | **No** | Invents a psychiatric history. Replace with administrative paper only: transfer ledgers, room registers, maintenance logs, redacted or blank diagnosis fields |
| 03 Records | Decommission notice "Effective 10/16/1983, A. Mercer, Hospital Administrator" | **No** | Mercer is the independent forensic evaluator (v1.1) or senior psychiatrist (GDD); the date is not canon (D4). Stage 5 already has a closure memo with the reason left blank; keep that pattern |
| 03 Records | Observation room | Mostly | Remove the red floor stains |
| 03 Records | Treatment room with restraint chair and surgical lamp | **No** | The chair reads as an electric chair; asylum-horror trope. Stage 5 already has a hydrotherapy room, which is the historically grounded version |
| 04 Anomalies | Repeating corridor, inconsistent clocks, displaced door, reflection lag, alternate reflection, echo wheelchair | **Yes, staged by chapter** (section 6) | Clock offset (about 6 hours) is too large for an early cue with an ordinary explanation. "CAM A/B 10/15 02:17" matches the Chapter 2 opening time (02:17); D5 asks whether that is deliberate |

**Signage rule (proposal):** no sign anywhere says "Ward Zero". In canon, W0-B is a code whose meaning the player must untangle (room, transfer category, legacy account). Signs use period level and room codes: "LOWER LEVEL B", "SERVICE B", room numbers such as `B-07`. Stage 5 already uses a half-covered "W0" stencil, which is the right strength. "Morgue" signage (boards 01 and 02) is cut; it adds horror without a story purpose.

### Inventory: existing assets to reuse

| Need | Existing asset | Reuse |
|---|---|---|
| Access stair, sealed threshold | `ENV_HistoricStairwell`, `ENV_SealedConnectingCorridor`, `PROP_Stair_Service_Historic` | As is |
| Abandoned nurses' station | `ENV_AbandonedNursingStation` | As is. Do not build a second one in Ward Zero unless the story needs it (D7) |
| Records archive and vault | `ENV_PaperRecordsArchive`, `ENV_HistoricRecordsVault`, `PROP_Cabinet_Card_Index`, `PROP_Door_Vault_Records` | As is; add dressing props below |
| Treatment space | `ENV_HistoricalTreatmentRoom`, `PROP_Tub_Hydrotherapy`, `PROP_Table_Exam_Historic`, `PROP_Cabinet_Instrument_Glass` | As is |
| Observation rooms | `ENV_ClosedObservationRooms` | As is |
| Mechanical corridor | `ENV_MechanicalCorridor`, `PROP_Panel_Fuse_Historic` | As is; the template for the utility junction |
| Period furniture and fixtures | `PROP_Bed_Iron_Historic`, `PROP_Chair_Wood_Historic`, `PROP_Desk_Steel_Tanker`, `PROP_Radiator_Cast_Iron`, `PROP_Light_Bulkhead_Historic`, `PROP_Shelf_Medication_Historic` | As is in Ward Zero |
| Wheelchair (echo event) | `PROP_Wheelchair` (Stage 3, modern) | Needs a period variant |
| State switching, lights, flicker | `state_group` extras, `WorldStateManager`, `LIGHTMARK_*`, `FlickerLight` (honours `flash_effects`) | As is |

Stage 6 itself is being built now in the environment thread ("6 props and 7 rooms with swappable anomaly states", not yet on GitHub). When its PR opens, compare it against this list rather than duplicating it.

### Missing assets (to create)

Architecture (Stage 6 kit, glazed-block style from board 02):

1. `KIT_W0_Wall_GlazedBlock_2m` (two-tone, with damage variants A to C)
2. `KIT_W0_Ceiling_Services_2m` (conduit, pipe run, tube light bracket)
3. `KIT_W0_Corridor_Segment_4m` (a clean, repeatable module for the repeating-corridor state)
4. `KIT_W0_Door_Cell` (wired-glass vision panel, food hatch, number plate; open, ajar, closed states)
5. `KIT_W0_Gate_Mesh` (caged service passage)
6. `KIT_W0_FloorDrain` and a floor decal set (water staining, no red)

Props:

7. `PROP_W0_Clock_Wall_Period` (hands driven by script, so offset states need no new mesh)
8. `PROP_W0_Intercom_Panel_Dead` and `PROP_W0_ChartRack_Wall`
9. `PROP_W0_Ledger_Transfer`, `PROP_W0_Box_Records` (stack variants), `PROP_W0_Notice_Board`
10. `PROP_W0_Wheelchair_Period`, `PROP_W0_Cart_Utility`
11. `PROP_W0_Light_Tube_Fluorescent` (single and twin, with a dead-tube variant)
12. `PROP_W0_Mirror_Wall` and `PROP_W0_Puddle` (planar reflection surfaces, section 6)
13. `PROP_W0_Sign_LevelCode` set (Label3D-ready faces, like `PROP_Sign_Room_Face`)

Documents (data, not meshes; story layer, `clinical_review_status: PENDING` where medical-looking): transfer ledger pages, room register, maintenance log, a decommissioning memo with the reason blank, a time log with duplicate entries.

---

## 4. Room-by-room modelling and texturing plan

Proposed Ward Zero layout. It extends south from the Stage 5 sealed corridor on the same level frame (floor at z = 0), so it never co-resides with the ground floor (F0 C12).

| # | Space | Size (proposal) | Model | Texture and materials | Story and state hooks |
|---|---|---|---|---|---|
| W1 | Threshold (breach of the bricked opening) | 3 × 4 m | Rubble edge, temporary work lamp, contractor's barrier | Brick, concrete dust | `state_group: w0_threshold` (sealed, opened) |
| W2 | Ward corridor | 2.6 × 24 m (6 × 4 m segments) | Kit walls, ceiling services, 8 cell doors (`B-01`…`B-08`) | Glazed block trim sheet, terrazzo, metal doors | Door states; clock W2 at the far end; corridor segment 3 is the repeat module (Ch3+) |
| W3 | Ward station | 4 × 5 m | Counter with hatch, chart rack, dead intercom, desk lamp | Laminate, worn paint | Time log, wall clock; duplicate entries (Ch2) |
| W4 | Day room | 6 × 6 m | Benches, wall mirror, wire-glass windows to a lightwell | Paint, linoleum | `PROP_W0_Mirror_Wall` reflection-lag event (Ch3+) |
| W5 | Records annex (decommissioning store) | 4 × 6 m | Steel shelving, record boxes, sealed cartons | Cardboard, paper atlas | Gaps on shelves; ledger pages; memo with blank reason |
| W6 | Service passage (caged) | 2 × 12 m | Mesh gate, pipes, junction boxes | Painted steel, oxidised metal | Gate state; echo wheelchair spot A |
| W7 | Utility junction | 5 × 5 m | Pipe manifold, valve wheels, gauges, floor drain | Rust, concrete, wet decal | Hum source for audio; paired sensor mount (Ch3 instrumented observation) |
| W8 | Lower stair landing (back route up) | 3 × 4 m | Stair, handrail, level-code sign | Concrete, yellow safety paint | Puddle (alternate reflection, Ch3+); echo wheelchair spot B |

**Texturing approach (Stage 8 compatible):**

- Two shared trim sheets for all of Ward Zero, 2048 × 2048 each: `TRIM_W0_Walls` (glazed block, paint lines, dado edge, damage) and `TRIM_W0_Metal` (doors, pipes, conduit, mesh). Props use a shared 1024 atlas. Grime comes from a tiling detail texture and decals, not unique textures.
- Godot `StandardMaterial3D` with ORM packing; base colour from the palette below; roughness varies to make the floor read damp only where decals say so.
- Keep `.blend` sources and export `.glb` as `ENVIRONMENT_PIPELINE.md` describes, generated by a build script (`tools/blender/build_stage6_*.py`), with `--fast` for no renders.

**Material palette** (reference README, mapped to swatches): pale institutional green `#7E9180`, dirty white `#CFC8B6`, concrete grey `#6E7072`, oxidised metal `#5B5650`, rust brown `#6B4A35`, safety ochre `#B8962E`, shadow blue `#1E2733`, wet black `#121417`. No red anywhere in decay; red is reserved for UI warnings.

---

## 5. Lighting, materials and environmental audio

### Lighting

- **Modern Ashcroft (unchanged):** neutral 4000 K LED panels, even, humane, a little daylight through windows.
- **Historic substructure (Stage 5, unchanged):** warm 2700 K tungsten bulkheads, uneven, some dead.
- **Ward Zero:** cool 5000 K to 5500 K fluorescent tubes with a slight green cast, sparse (one working fixture in three), so the player reads space through pools of light. A practical work lamp at the threshold signals recent human entry.
- `LIGHTMARK_*` markers only; no baked lighting in Blender, as now. Use at most 2 to 3 shadow-casting lights visible at once; the rest are non-shadow omni lights with short ranges.
- `FlickerLight` stays tied to `flash_effects`. Ward Zero flicker is slow (seconds, not strobing) and never coincides with an anomaly beat, so flicker cannot be mistaken for the phenomenon.
- Fog: Godot volumetric fog off on the low preset; a cheap depth fog for the far ends of corridors.

### Materials

- Glazed block has a semi-gloss sheen; terrazzo floors are matte with damp patches near drains only (a roughness decal), not a mirror floor everywhere.
- Paper, card and fabric are matte, so documents read clearly in close-up (evidence close-ups must show real fields, per the bible).

### Environmental audio

The audio engine already has `amb_historic_intercom_static`, `amb_ward_zero`, `w0_knocking_heard`, `w0_power_surge` and `w0_pressure_shift` (checked in `audio/cues.json`). Proposals for the audio workstream, not edits in this branch:

- Room tone per space: low HVAC rumble (W2), mains hum and ticking pipes (W7), paper and dead air (W5), distant drips with a seeded schedule.
- Phenomenon signature (bible: "low mechanical hum"): one recognisable, quiet layer, a beating tone around 50 to 60 Hz plus a faint second clock tick slightly out of phase. It fires only from authored anomaly events, never from the strain or Bleed meter (F0 C6).
- **Review `w0_knocking_heard`.** Knocking implies an agent behind a door, and the bible says the phenomenon has "no intelligence, voice or intent". Suggest re-cueing it as pipe knock (thermal expansion) with a physical emitter in W7.
- Silence before and after each anomaly, a one-second dropout of room tone, is cheaper and stronger than a stinger. No jump scares; `reduce startling audio` keeps working.
- Every anomaly with an audio part needs a visual or text equivalent (GDD §11: no audio-only clues).

---

## 6. Supernatural anomaly visual-effects specification

### Rules (from `09_SUPERNATURAL…` and the owner's brief)

1. Anomalies are authored story or world-state events (`WorldStateManager` groups), never driven by a diagnosis, BFCSI score, medication, rapport, trust, objectivity or Bleed. F3 should test this.
2. Spatially bounded to the historic substructure and Ward Zero.
3. Each early cue has an ordinary explanation the player can reasonably hold.
4. Evidence is canonical: the effect may be seen, but what the player records (photo, log, sensor) is stored as data, so reload, accessibility settings and screen effects cannot change it.
5. No faces, figures, voices, writing that addresses the player, or patient-linked visions.

### Effect catalogue, staged by the bible's reveal ladder

| Id (proposed) | Effect | First chapter | How it is built | Ordinary explanation available |
|---|---|---|---|---|
| `anom_clock_offset` | Two clocks differ by 1 to 4 minutes; the time log has duplicate rows (03:12, 03:13) | Ch2 | Clock hand angle from data; log page is a document variant | Clock drift, manual logging |
| `anom_door_state` | A cell door is ajar on one visit and closed on the next, with no one there | Ch2 | Existing `state_group` (`open`, `ajar`, `closed`) | Draught, maintenance |
| `anom_object_echo` | The same period wheelchair is in W6 and W8 at the same timestamp (two camera stills, or two independent witnesses) | Ch3 | One prop, two `state_group` positions shown together; evidence stored as two documents with the same time | Two identical chairs (resolved by a serial plate) |
| `anom_reflection_lag` | The day-room mirror shows the room's state from a few seconds earlier: a cart that has moved, a door that has closed | Ch3 | Reflection probe with a delayed state, or a planar reflection camera rendering a hidden copy of the room in an earlier state | None once instrumented |
| `anom_alt_reflection` | A puddle reflects a door number that is not there (`B-07` for `B-03`) | Ch3 to Ch4 | Planar reflection of a hidden "alternate" set; low resolution, one at a time | None |
| `anom_corridor_repeat` | Walking W2 segment 3 returns you to its start with small differences (one light dead, a box moved) | Ch4 to Ch5 | Seamless teleport between two copies of segment 3 at a door frame, with a state difference; never traps the player (a second pass always exits) | None |

**Presentation limits:** no full-screen distortion, chromatic aberration or camera shake for anomalies (those belong only to the optional Bleed presentation, and must not co-occur). Reduce-motion turns the corridor repeat into a door transition with a dip to black. Every anomaly writes an evidence entry with source, timestamp and reliability, as `EvidenceManager` expects.

**Cut from the references:** handwritten notes and graffiti that explain the phenomenon, red or blood-like staining, occult symbols, patient photographs.

---

## 7. Optimisation for an 8 GB Apple Silicon MacBook Air

Unified memory is shared by the OS, Godot and the GPU, so the practical budget for the game is about 3 to 3.5 GB. Targets below are proposals to verify on the owner's Mac; nothing has been profiled.

| Area | Budget (proposal) |
|---|---|
| Zones resident | Current level plus one neighbour (F2 zone streaming); never ground floor and sublevel together |
| Textures per zone | ≤ 160 MB VRAM; trim sheets 2K, props 1K, decals 512; VRAM-compressed (Godot "VRAM Compressed", ASTC/BC on import) |
| Triangles on screen | ≤ 600 k; Ward Zero kit pieces ≤ 3 k each, props ≤ 2 k |
| Draw calls | ≤ 800; merge static dressing per room in Blender, use MultiMesh for repeated items (boxes, tubes) |
| Lights | ≤ 3 shadowed, ≤ 16 unshadowed visible; omni shadow mode "dual paraboloid" or none |
| Reflections | No SSR on low or medium; one planar reflection active at a time (anomalies only), 256 to 512 px; ReflectionProbes otherwise, update mode "once" |
| GI and post | No SDFGI; VoxelGI off on low; LightmapGI optional per zone after Stage 8 lightmap UV2; SSAO half-res on medium only; glow low |
| Characters | 15 to 25 k triangles each, one 2K body atlas plus a 1K head; max 4 on screen in Chapter 1; LOD at 6 m and 12 m |
| Wet floors | Roughness decals, not SSR; this is why the reference look of every corridor floor being a mirror is cut |
| Audio | OGG streamed for beds; short SFX as WAV only if under 1 MB |

Add a `low` graphics preset (Compatibility-friendly) and an in-game frame-time overlay for the owner's Mac test. Test Forward+ on Metal against the Compatibility renderer, as `05_AUDIO_VISUAL…` asks.

---

## 8. Proposed GitHub issues and small, testable PRs

Nothing below is opened until the owner approves. Each PR is a draft, small, and leaves existing scenes, models and clinical systems untouched.

### Issues

1. **Approve character canon sheets** (section 2; decisions D1 to D3, D6)
2. **Regenerate character references** to the written guide: Bennett, Voss, Hale (no tactical gear), Rahman age, Elias and Mara clean and age-correct (art task, owner side)
3. **Mark ensemble and concept boards superseded** (no real-person likeness references)
4. **Ward Zero layout and signage rules** (sections 3 and 4; D4, D5, D7)
5. **Anomaly effect catalogue and chapter staging** (section 6), for the F3 anomaly model
6. **Ward Zero audio pass**: room tones, phenomenon signature, re-cue `w0_knocking_heard`
7. **Performance budget and low preset** (section 7), needs the owner's Mac
8. **Character production pipeline**: tool choice and licence (MakeHuman CC0 assets or Blender sculpt), rig, export, provenance manifest

### PRs, in order

| PR | Scope | Test |
|---|---|---|
| V1 | `README.md` notes in the reference folders marking the three boards superseded; this review and the handoff docs | Docs only |
| V2 | `docs/design/CHARACTER_VISUAL_CANON.md` with the approved sheets, after issue 1 | Docs only |
| V3 | Character stand-in upgrade: replace the capsule in `Character.tscn` with a neutral, labelled greybox mannequin (head, torso, limbs, a per-character colour band) that keeps the same node paths and collision | `test_world.gd` unchanged and passing |
| V4 | Stage 6 kit (glazed block, ceiling services, cell door, mesh gate), untextured, via a build script | `validate_glb_imports.gd` |
| V5 | Ward Zero props (clock, intercom, chart rack, ledgers, boxes, period wheelchair, fluorescent tubes, signs) | Same |
| V6 | Ward Zero rooms W1 to W8 on the Stage 5 frame, with anomaly `state_group` nodes all defaulting to the normal state | GLB validation plus an assert that no anomaly state is visible by default |
| V7 | Trim sheets and materials for Ward Zero only | Import test; texture memory report |
| V8 | One playable Ward Zero zone behind the F2 zone loader with a disabled anomaly flag | Zone transition test from F2 |
| V9 | First anomaly (`anom_clock_offset`) wired through the F3 anomaly model, with an evidence record | Determinism test (same seed, same result); a test that clinical state cannot trigger it |
| V10 | First character model (Bennett), after canon and reference approval | Import, LOD and triangle-budget check |

V4 to V6 overlap with the Stage 6 work the environment thread is doing now. If its PR lands first, these become review comments and small follow-ups on it, not parallel rebuilds.

---

## Open decisions for the owner

| # | Decision | Recommendation |
|---|---|---|
| D1 | Rahman's role: Consultant Psychiatrist (v1.1) or Clinical Pharmacist (GDD) | Consultant Psychiatrist, per your note on the guide |
| D2 | Hale's on-screen title | Security Director (matches data and audio) |
| D3 | Approve the written casting in the guide (Bennett Black woman, Rahman South Asian woman; others open) | Approve the written guide; regenerate the images |
| D4 | Ward Zero decommissioning date and signatory | Leave unnamed until the Chapter 3 to 4 story is approved |
| D5 | Is 02:17 on the echo-camera stills meant to rhyme with the Chapter 2 opening time? | Yes, as a quiet link, if the story keeps 02:17 |
| D6 | Mara's voice | Choose when her dossier is approved |
| D7 | Does Ward Zero need its own station, or does it reuse Stage 5's abandoned station? | A smaller ward station (W3), different in layout and era |
| D8 | Concept boards: mark superseded or remove | Mark superseded; keep for history |
| D9 | Commit the v1.1 design bible package into `docs/design/` so agents can cite it | Yes |
