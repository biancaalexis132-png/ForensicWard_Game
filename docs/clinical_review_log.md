# Clinical review log

Every clinical rule or model that affects gameplay needs a recorded review by the executive producer (psychiatrist) before it is used as approved medical logic (GDD §8, §17).

| Date | Item | Location | Decision | Reviewer | Notes |
|---|---|---|---|---|---|
| 2026-10-17 | Pharmacology exposure model v0 (CYP phenotype, FDA-class inhibition/induction, smoking CYP1A2 induction, inflammation, renal/lithium clearance, additive QTc, side-effect channels, 20-drug database) | `staging/pharmacology/` | **Approved** | Executive producer | Approved in chat. Integration into `ClinicalRules` is scheduled for Sprint 2; each rule will then get its id, source, review date and test examples per GDD §8. |
| (pending) | `clinical_rule_catatonia_escalation_v1` | `data/clinical_rules.json` | Pending | | Runs in prototype mode only, and applies only its non-medical effect `mark_assessment_started`. |
| (pending) | Elias Ward dialogue | `data/dialogue.json` | Pending | | `clinical_review_status: PENDING`. A placeholder `assessment` state was added; see `docs/SPRINT_01.md`. |

| (pending) | Elias first-evaluation screenplay summary: EHR preparation, interview attempts, examination, MSE/formulation and safety documentation | `docs/design/ELIAS_EVALUATION_DRAFT_COMPARISON.md` | **Pending; no clinical activation** | | Owner confirmed full screenplay is in ChatGPT, not supplied/committed yet; standalone text will follow. Existing patient/dialogue/rule review flags remain pending. Creative direction and D1–D3 approvals do not approve this clinical material. |

| 2026-10-17 | Mara Ellis Chapter2 recurring introduction / clinical encounter | `docs/design/CHAPTER2_MARA_IMPLEMENTATION_CROSSWALK.md` | **Placement approved only; patient-facing medical logic pending** | Owner (placement instruction in session) | Preserve prior dossier/risk/collateral; no new findings, diagnoses, orders, treatment responses or discrepancy explanation. Full clinical source/encounter requires review. |
