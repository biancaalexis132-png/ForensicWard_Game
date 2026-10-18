# Character visual canon

The single place that says what is **decided** about how the recurring cast looks, and what is still **provisional**. Builders, profiles and reviewers check this page first, then the per-character production folder in `docs/design/characters/`.

**Decided** items come from the owner's message in the project chat on 2026-10-18 18:05 UTC, which answered decisions D1–D3 of `VISUAL_PRODUCTION_REVIEW.md` and set Mara's chapter. Naomi's twists were approved earlier (see `characters/Naomi_Bennett_Character_Production_v1/NAOMI_CHARACTER_SPEC.md`). Everything else is a proposal until the owner approves it, and generated reference images are never canon.

Precedence: owner decisions on this page > `data/staff.json`, `data/patients.json` and clinical records > per-character production specs > `VISUAL_PRODUCTION_REVIEW.md` §2 proposals > generated reference art.

## Decided

| Character | Id | On-screen role | Decided appearance | Source |
|---|---|---|---|---|
| Naomi Bennett | `staff_bennett` | Charge Nurse | Black woman, early 40s; pulled-back natural twists; navy scrubs | Owner, 2026-10-18 |
| Dr Evelyn Voss | `staff_voss` | Medical Director | Woman, early 50s | Owner, 2026-10-18 |
| Marcus Hale | `staff_hale` | **Security Director** | Credible professional hospital security attire; **no tactical armour** | Owner, 2026-10-18 (D2) |
| Dr Leila Rahman | `staff_rahman` (reserved) | **Consultant Psychiatrist**, not clinical pharmacist | (none decided beyond role) | Owner, 2026-10-18 (D1); voice direction fixed in PR #48 |
| Elias Ward | `pt_elias_ward` | Patient | Man, 29 (matches `data/patients.json`) | Owner, 2026-10-18; patient record |
| Mara Ellis | `pt_mara_ellis` (reserved) | Patient, **introduced in Chapter 2** | Woman, around 37 | Owner, 2026-10-18 |

Rules that always apply (owner brief and `AGENTS.md` §6): no character's appearance encodes a diagnosis, credibility, villainy or a link to Ward Zero; patients look clean and ordinary; no real-person likeness; no occult or horror styling.

## Provisional (proposals, not canon)

Use these as the build baseline, label every model built from them as a review candidate, and do not attach one to gameplay without owner approval.

| Character | Proposal | Spec |
|---|---|---|
| Naomi Bennett | Face, skin shade, body proportions, twist size, earrings, grey scrub jacket, badge clip vs breakaway lanyard | `characters/Naomi_Bennett_Character_Production_v1/` |
| Dr Evelyn Voss | Navy or charcoal tailored suit, ivory blouse, reading glasses, neat low chignon or bob with grey, director's badge; ethnicity and face open | `VISUAL_PRODUCTION_REVIEW.md` §1–2 (no production folder yet) |
| Marcus Hale | Mid 40s; uniform shirt or blazer, badge, belt radio, keys on reel; ethnicity, face and build open | `characters/ForensicWard_Hale_Mara_Character_Pack_v1/Marcus_Hale_v1/` |
| Dr Leila Rahman | Late 30s; sage/oat blouse or cardigan, tailored trousers, optional short clinical coat, badge, notebook; shoulder-length hair tied back. The reference guide's "South Asian woman" is **not** decided | `characters/Rahman_Character_Production_v1/` |
| Elias Ward | Neat short-to-medium hair, soft grey or washed-blue sweatshirt or T-shirt, soft trousers, non-slip socks or slip-ons; no symptom movement without clinical review | `characters/Elias_Ward_Character_Production_v1/` |
| Mara Ellis | Simple top, cardigan, soft trousers, slip-on shoes, low ponytail or clip; her dossier (past work, history) still needs reconciling before implementation | `characters/ForensicWard_Hale_Mara_Character_Pack_v1/Mara_Ellis_v1/` |

## Still open

- Visual review D4–D9 (Ward Zero decommission date and signatory, the 02:17 rhyme, Mara's voice, a separate Ward Zero station, the concept boards, committing the v1.1 bible).
- Casting details not listed under Decided: faces, skin shades, ethnicities other than Naomi's.

## Reference images

`assets/creative_references/Visual_References/Individual_Characters/ensemble_initial_concept_board_UNAPPROVED.png` and `Concept_Boards/ashcroft_concept_board_{1,2}.png` mislabel names, roles and ages, tie patients to Ward Zero, and (board 2) cite real actors. They are kept for history and are not modelling references; see the README in each folder.
