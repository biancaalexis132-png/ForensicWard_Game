# Individual character reference regeneration

**Authorized reference correction; not 3D production approval.** D1–D3 are approved in the owner decision record. Written requirements come from `CHARACTER_VISUAL_CANON.md` and the original guide, with Rahman’s Consultant Psychiatrist title overriding its old label. Unspecified facial details remain provisional; no absent bible content is invented.

## Exact source artwork and correction briefs

All source paths below are under `assets/creative_references/Visual_References/Individual_Characters/`. Preserve every original PNG. Ages read from generated faces are visual impressions, not verified biological facts.

| Source portrait | Observed mismatch | Replacement specification |
|---|---|---|
| `naomi_bennett_reference.png` | Existing face/hair does not reliably communicate the written Black woman/natural-hair casting; attire differs from navy scrubs | Black woman clearly early 40s, practical natural textured hair, navy scrub top/trousers, comfortable work shoes and generic ID; warm competent authority; no ominous styling |
| `evelyn_voss_reference.png` | Appears too young; face resembles Bennett concept; brown jacket/turtleneck differs from guide | Distinct original mature woman early 50s; tailored charcoal/navy professional jacket, neat hair, modest jewelry and administrative ID; neutral lighting, no villain coding |
| `marcus_hale_reference.png` | Tactical vest conflicts with professional hospital styling | Man mid 40s, practical grooming; charcoal institutional uniform, ordinary radio/badge, restrained belt; no armor, tactical gloves, weapons, restraints or psychiatric authority |
| `leila_rahman_reference.png` | Wrong title (Staff Psychiatrist), youthful appearance | South Asian woman late 30s, title **Consultant Psychiatrist**, business casual or appropriate clinic coat, ID and notebook; warm rigorous professional, not pharmacist/researcher |
| `elias_ward_reference.png` | Matted/disheveled hair, sweat/dark circles and hard stare suggest horror styling | Man 29; clean ordinary grooming and comfortable clean inpatient-appropriate clothes/shoes; restrained neutral acting; no gown/bare-feet trope, symbolism, paranormal traits or inferred diagnosis |
| `mara_ellis_reference.png` | Wet/disheveled hair, youthful face and lack of practical cardigan | Woman 37; clean tidy hair, everyday clothes/cardigan and practical shoes, modest ordinary fatigue; attentive/guarded without horror styling; no toys/nightgown/paranormal coding |

The ensemble and both `Concept_Boards/ashcroft_concept_board_*.png` remain unsuitable for production authority. Their mislabels, actor references and asylum tropes are not prompts for replacement characters. D8 remains a separate unresolved handling decision; no old artwork is deleted.

## Consistent per-character deliverables

Each character gets one coherent candidate sheet containing full-body front, three-quarter, profile and back views at consistent scale, with a neutral A-pose; five close facial expression studies; and wardrobe/hair/footwear/allowed prop details. Use a light neutral studio backdrop, consistent camera/lens, even lighting, no vignette, mood scene or horror grading. Keep identity, garment seams and proportions consistent across views. Label name, approved title and candidate status; do not include readable patient/staff identifying data beyond the fictional character name.

These are generated concept candidates, not verified orthographic drawings or riggable meshes. Before modeling, a human artist must reconcile view inconsistencies, check anatomy and approve a technical A-pose/scale sheet. Generated clothing folds and facial proportions must not be copied blindly into production.

### Bennett

Identity: Black woman, early 40s. Practical natural textured hairstyle; consistent navy scrubs, ordinary shoes/ID. Expressions: neutral, attentive, concerned, reassuring, firm. Clinical anchor through ordinary competence, not a sinister nurse trope. Exact original face/hair variant remains a candidate, not a new biographical decision.

### Voss

Identity: woman early 50s; unspecified ethnicity remains unspecified in canon. Mature, distinct original face, neat hair; tailored charcoal/navy jacket, administrative ID and understated jewelry. Expressions: composed, skeptical, diplomatic, fatigued, reluctantly candid. No caricature of institutional villainy. Do not reuse Bennett’s generated face.

### Hale

Identity: man mid 40s; practical grooming. Uniform, radio and security role badge, no militarized styling. Expressions: professional neutral, questioning, concerned, resolute, attentive (the fifth is a non-narrative acting study, not a new personality rule). An exact skin tone/facial design chosen for a candidate does not settle unspecified casting. No restraint equipment or clinical authority invented through costume.

### Rahman

Identity: South Asian woman late 30s; title Consultant Psychiatrist. Professional business casual or appropriate clinic coat, ID/notebook; consistent hair/glasses only as candidate choices. Expressions: warm, analytical, concerned, assertive, encouraging. Do not invent nationality, faith, subspecialty responsibilities or personal relationships. Existing stock voice remains unchanged.

### Elias

Identity: adult man 29, ordinary human patient. Clean tidy hair, clean comfortable inpatient-appropriate clothes/footwear. Acting studies: neutral rest, mild attention, listening, looking aside, slight acknowledgement; these are presentation candidates only. No diagnostic pose, catatonia animation, posturing or clinical action is approved by a reference sheet. Any future clinical movement must be reviewed separately.

### Mara

Identity: adult woman 37, clean everyday clothes/cardigan and simple practical items; slight fatigue without disarray. Expressions: attentive, guarded, exhausted, reflective, cautiously hopeful. Never infer credibility from her face or make her supernatural. Voice (D6), clinical dossier, permitted patient property and narrative involvement remain separate approvals; do not add story props by assumption.

## Provenance and review

Generation prompts, tool/settings, source and output hashes, candidate file paths and visual observations are recorded in the candidate folder manifest. Original source art is preserved; new sheets use original generated faces without actor likeness references. The generator’s model ID and seed are not exposed and must not be invented. Account/provider terms and final asset clearance remain owner review items; a new sheet is not an approved commercial release or clinical depiction.

A sheet passes reference review only after written identity/title/age/wardrobe checks, coherent views, original-likeness review, respectful patient presentation and technical redraw/scale verification. Generated candidates can meet the brief broadly while still needing correction. Do not silently promote them to canon or swap them into `Character.tscn`.

## Phased production plan

| Phase | Work | Gate / check |
|---|---|---|
| C1 | Record D1–D3, reconcile clear metadata and list contradictions | Owner decision source preserved; no clinical/ID/voice changes |
| C2 | Corrected original reference candidates and these briefs | Owner selects faces/wardrobe variants; inspect all views; preserve old images and provenance |
| C3 | Artist-clean technical turnarounds and shared scale/rig plan | Resolve unknown facial details and any guide ambiguities; verify licence/pipeline; no speculative canon |
| C4 | One character prototype, suggested Bennett, on a separate asset branch | Preserve scene node paths/collision; import, LOD/material/rig budget and Mac memory/render review; model approval required |
| C5 | Remaining approved models/animations in small PRs | Per-character import/world tests; clinical review of any patient movement; no new medical logic |
| C6 | Scene integration and selective voice/lip-sync polish | Existing casting/line IDs retained unless separately approved; text equivalents and accessibility; Mac listening/performance |

Target remains an 8 GB Apple Silicon MacBook Air. Reuse F2 zone loading and shared materials/rigs, avoid loading the full hospital for previews, and profile rather than declaring proposed triangle/texture budgets achieved. Stage 6, lighting, audio cue assignment and the opening implementation remain their own coordinated workstreams.
