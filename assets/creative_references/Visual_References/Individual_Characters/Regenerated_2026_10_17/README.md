# Corrected character reference candidates — 2026-10-17

Six new original reference sheets implement the approved written identity/title/age/presentation direction. **They are candidates for review, not approved facial casting, technically verified orthographic sheets, clinical depictions, or 3D assets.** No game scene uses them. `.gdignore` keeps them out of Godot imports/exports.

The authoritative written specification is `docs/design/CHARACTER_VISUAL_CANON.md`; per-character briefs and production gates are `docs/design/CHARACTER_REFERENCE_REGENERATION.md`. D1–D3 are approved; D4–D9 remain unresolved. Exact unspecified facial casting and costume/insignia details require review. Mara's voice and all pending clinical material remain unapproved.

| Candidate | Correction emphasis |
|---|---|
| `naomi_bennett_candidate_v2.png` | Black woman, practical natural hair, navy scrubs and professional maturity |
| `evelyn_voss_candidate_v2.png` | Distinct mature early-50s presentation, charcoal/navy tailoring; unsupported generated height/biography removed |
| `marcus_hale_candidate_v2.png` | Security Director, ordinary institutional uniform; no tactical vest |
| `leila_rahman_candidate_v2.png` | South Asian woman; Consultant Psychiatrist title; ordinary professional clothing |
| `elias_ward_candidate_v2.png` | Clean everyday patient presentation; invented generated ID/DOB and property detail removed |
| `mara_ellis_candidate_v2.png` | Clean practical cardigan presentation; staff-like patient badge and unsupported property claim removed |

Each sheet was visually inspected for four full-body views and five expression studies. Faces, anatomy, A-pose precision, scale, apparent age and cross-view consistency still need human production review. Incidental generated text is not an authority for biography, patient capacity/risk, policies, costumes or hospital badge design. Do not infer legal capacity or clinical normality from an image caption or expression. No intentional real-person/actor likeness reference was used; production likeness/rights review remains required.

`manifest.json` records dimensions, byte counts, SHA-256, original portrait hashes, correction history and review limitations. `generation_prompts.json` preserves exact prompts/settings. Model version/seed are not exposed by the tool and are not invented. Regeneration may differ; the saved PNG hashes identify these exact outputs.

The original six project portraits remain unchanged in the parent folder as historical concepts. Initial generated passes that introduced unsupported details remain in `/workspace/generated_images` locally and are identified by hash in the manifest; they are not production references and were not committed as duplicate image assets. Corrected final candidates and their full generation prompts are recoverable from Git.
