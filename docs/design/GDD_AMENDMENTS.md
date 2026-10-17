# GDD amendments

Owner decisions that change `The_Forensic_Ward_Master_GDD_v0.1.docx`. The locked `.docx` is not edited; where it and this page disagree, this page wins. Each entry says where the owner gave the decision.

| Date | Decision | Replaces in GDD v0.1 | Given in |
|---|---|---|---|
| 2026-10-17 | The hospital is **Ashcroft State Forensic Hospital**. Use it in signage, menus and narrative. Data: `data/campaign.json` `institution.name`. | GDD names no hospital ("a secluded high-security state forensic hospital") | Project thread "F0 Foundation Audit", owner message with the v1.1 handoff package |
| 2026-10-17 | Ward Zero contains a **genuine supernatural phenomenon**. Early chapters keep uncertainty and clinical realism. Psychiatric symptoms are never evidence of it. Precise mechanism still to be approved. | §1–2 "selected anomalies remain ambiguous" | Same message |
| 2026-10-17 | **Reusable technical foundations for all five chapters come first**, before intensive Chapter 1 polish. Architecture: `docs/F0_FOUNDATION_AUDIT.md`. | §13–14 build order (vertical slice first) | Same message; F0 approved by the owner in the same thread ("continue" after merging PR #20) |

Open questions that may amend the GDD later are listed in `docs/F0_FOUNDATION_AUDIT.md` §9 (act titles and the Concordance thread, player title, staff roles, Psychosomatic Bleed, pharmacology clue gates).

## Protagonist decisions confirmed in the Codex continuation handoff

Source: owner message “CONTINUE DEVELOPMENT — THE FORENSIC WARD”, sections 4–5 and 8, 2026-10-17. These are approved requirements; the implementation proposal remains subject to review.

| Decision | Supersedes / constrains |
|---|---|
| Every protagonist is a psychiatrist at Ashcroft State Forensic Hospital; background experiences do not change essential competence or clinical responsibilities | GDD §1–2 role wording is generalized; no selectable profession/class |
| Appearance, name/pronouns and feasible voice options may be customized; professional backgrounds are experiences/interests | Creator catalog and asset specifics remain proposals |
| Personal-life customization is **moderate**, with optional defining history, relationships and recurring callbacks; no mandatory trauma, romance or family plot | GDD §2 limited personal life; no full personal-life simulator |
| Personality emerges through choices; no permanent class, alignment or fixed psychological profile | Suggested dimensions are examples, not approved numerical meters |
| Background/personality/history cannot remove essential care, mandatory evidence or access to major outcomes; clinical standards are independent | Applies to dialogue, relationships, progression and testing |
| Personal history and psychiatric symptoms cannot explain away or substantiate the genuine supernatural phenomenon | Reinforces existing clinical/supernatural separation |

The owner has not resolved visual-review D1–D9, Psychosomatic Bleed C6 or pharmacology clue-gate C7. Do not infer these approvals from the protagonist decisions. Fixed psychiatrist role does not settle exact voiced title wording. Proposed implementation: [PROTAGONIST_CUSTOMIZATION_PLAN.md](PROTAGONIST_CUSTOMIZATION_PLAN.md).

## Approved character identities and casting — 2026-10-17

Source: owner-supplied “APPROVED CANON UPDATE — ASHCROFT CHARACTER IDENTITIES AND VISUAL CASTING”, preserved verbatim in [decisions/2026-10-17_CHARACTER_IDENTITIES_APPROVAL.md](decisions/2026-10-17_CHARACTER_IDENTITIES_APPROVAL.md).

| Decision | Approved value | Supersedes / boundary |
|---|---|---|
| D1 | Dr Leila Rahman is **Consultant Psychiatrist** | Supersedes “clinical pharmacist” in locked GDD §5/legacy voice direction and the provisional “Staff Psychiatrist” guide label. No voice casting, dialogue IDs or clinical logic changes. |
| D2 | Marcus Hale is **Security Director** | Standardizes provisional “security chief”/“Head of Security” labels; professional hospital presentation, no default tactical styling or psychiatric authority. |
| D3 | Written casting guide is authoritative over generated imagery | Bennett is a Black woman; Rahman is a South Asian woman; preserve other established written descriptions. Original concept faces are not production approvals; regenerate inconsistent references without stereotypes or unauthorized likenesses. |

Authoritative current specification: [CHARACTER_VISUAL_CANON.md](CHARACTER_VISUAL_CANON.md). Locked DOCX, original PDF and images are retained as historical sources; this amendment governs contradictions. D4–D9 remain unresolved. No blanket approval of the visual review or patient medical content is implied.

## Approved Chapter 1 opening direction — 2026-10-17

Source: owner message “APPROVED CREATIVE DIRECTION — CHAPTER 1 OPENING” in this session. The first 20–25 minutes should be carried by realistic psychiatric hospital drama: ordinary arrival/psychiatrist onboarding, Bennett’s orientation/morning handoff, substantial Elias evaluation (EHR, interview, MSE, formulation, documentation), a small objective documentation discrepancy with plausible administrative explanations, then a subtle older-infrastructure/service-access inconsistency. No immediate supernatural reveal, frightening patient stereotype, jump scare, apparition or persistent ominous music. Personality emerges through choices; essential competence/story access is equal across backgrounds.

This is creative direction, **not authority to overwrite existing Chapter 1** or activate clinical content. Comparison and phased proposal: `CHAPTER1_OPENING_ALIGNMENT.md`. The Elias screenplay summary remains pending clinical review; the owner confirmed its full text is off-repository in ChatGPT and will be supplied separately. Existing patient/beat IDs, provenance, clinical review flags and late-shift timing must be retained; no normal risk finding/refusal is inferred from silence, no examination finding is established without examination, and symptoms never cause supernatural events. See `ELIAS_EVALUATION_DRAFT_COMPARISON.md`.

## Approved Mara Ellis placement — 2026-10-17

Source: owner message “APPROVED STORY PLACEMENT — MARA ELLIS”. Mara (`pt_mara_ellis`, age37) is a significant recurring patient **introduced in Chapter2, The Missing Hours**, superseding proposed Chapter1 placement. Preserve prior records work, disputed historical mood label, insomnia/fatigue, anxiety/document checking, Dana collateral and conflicting October12/14,1988 records about aunt Lillian Ellis. No new clinical finding/diagnosis/order/response or explanation approved. Ch1 second patient remains unassigned; Jordan is not approved. Exact dossier/risk source must be preserved when available; medical logic remains pending. See [CHAPTER2_MARA_IMPLEMENTATION_CROSSWALK.md](CHAPTER2_MARA_IMPLEMENTATION_CROSSWALK.md).

## Approved Mara agency and investigative separation — 2026-10-17

Owner instruction “APPROVED CANON — MARA ELLIS: CLINICAL AGENCY AND INVESTIGATIVE SEPARATION” establishes autonomous motivations/goals and independent clinical care/recovery; preserve dossier/collateral/uncertainty/legal questions. Document sharing is voluntary. Specific concerns may be corroborated without endorsing all interpretations. No supernatural-witness/psychic/investigator/exposition role; no symptom/diagnosis/treatment evidence. Mandatory mystery evidence has independent authorized archive/staff/security/environment routes even if documents are declined or rapport limited. Preserve confidentiality/consent/boundaries. New dialogue and clinical content remain gated. Crosswalk above defines review/test requirements; no runtime change.

## Chapter3 entry premise reaffirmed; Ch2/3 expansions proposed — 2026-10-17

Owner confirms first actual WardZero entry in Ch3, accompanied by authorized Security and Facilities through formal inspection. New repeated-junction/control/measurement behavior and expanded institutional dialogue remain proposed, not blanket approval. Preserve Voss/Hale/Rahman professional responsibilities, Mara autonomous care, independent evidence and five-chapter architecture. Comparison and engineering requirements: [CHAPTER2_3_INSPECTION_CONTINUATION_SPEC.md](CHAPTER2_3_INSPECTION_CONTINUATION_SPEC.md). No story/runtime replacement.
## Approved Chapter3 first WardZero entry — 2026-10-17

Owner message “CHARACTER PRODUCTION AND CHAPTER3 CONTINUATION” approves Chapter3 as the **first actual entry** through a formal Security and Facilities inspection. Earlier documentary/door investigation is not entry. New supervised inspection, possible repeated junction, temporary navigation discrepancy, coordinated safe return and independent preservation are drafted material; exact dialogue and supernatural mechanics remain proposed. No clinical change or anomaly activation authorized. See `CHARACTER_PRODUCTION_NAOMI_FIRST.md` for pipeline proposal and implementation boundaries.
