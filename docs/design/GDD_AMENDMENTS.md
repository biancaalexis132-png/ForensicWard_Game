# GDD amendments

Owner decisions that change `The_Forensic_Ward_Master_GDD_v0.1.docx`. The locked `.docx` is not edited; where it and this page disagree, this page wins. Each entry says where the owner gave the decision.

| Date | Decision | Replaces in GDD v0.1 | Given in |
|---|---|---|---|
| 2026-10-17 | The hospital is **Ashcroft State Forensic Hospital**. Use it in signage, menus and narrative. Data: `data/campaign.json` `institution.name`. | GDD names no hospital ("a secluded high-security state forensic hospital") | Project thread "F0 Foundation Audit", owner message with the v1.1 handoff package |
| 2026-10-17 | Ward Zero contains a **genuine supernatural phenomenon**. Early chapters keep uncertainty and clinical realism. Psychiatric symptoms are never evidence of it. Precise mechanism still to be approved. | §1–2 "selected anomalies remain ambiguous" | Same message |
| 2026-10-17 | **Reusable technical foundations for all five chapters come first**, before intensive Chapter 1 polish. Architecture: `docs/F0_FOUNDATION_AUDIT.md`. | §13–14 build order (vertical slice first) | Same message; F0 approved by the owner in the same thread ("continue" after merging PR #20) |
| 2026-10-18 | **Dr Leila Rahman is a Consultant Psychiatrist**, not a clinical pharmacist. **Marcus Hale's on-screen title is Security Director**, in professional security attire with no tactical armour. **Mara Ellis is introduced in Chapter 2.** Visual decisions: `docs/design/CHARACTER_VISUAL_CANON.md`. | §5 "Dr Leila Rahman, clinical pharmacist"; §12 beat 4 second patient | Project chat, owner message of 2026-10-18 18:05 UTC |

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

The owner resolved visual-review D1–D3 on 2026-10-18 (row above) but not D4–D9, Psychosomatic Bleed C6 or pharmacology clue-gate C7. Do not infer these approvals from the protagonist decisions. Fixed psychiatrist role does not settle exact voiced title wording. Proposed implementation: [PROTAGONIST_CUSTOMIZATION_PLAN.md](PROTAGONIST_CUSTOMIZATION_PLAN.md).
