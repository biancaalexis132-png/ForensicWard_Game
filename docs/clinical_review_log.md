# Clinical review log

Every clinical rule or model that affects gameplay needs a recorded review by the executive producer (psychiatrist) before it is used as approved medical logic (GDD §8, §17).

| Date | Item | Location | Decision | Reviewer | Notes |
|---|---|---|---|---|---|
| 2026-10-17 | Pharmacology exposure model v0 (CYP phenotype, FDA-class inhibition/induction, smoking CYP1A2 induction, inflammation, renal/lithium clearance, additive QTc, side-effect channels, 20-drug database) | `staging/pharmacology/` | **Approved** | Executive producer | Approved in chat. Integration into `ClinicalRules` is scheduled for Sprint 2; each rule will then get its id, source, review date and test examples per GDD §8. |
| (pending) | `clinical_rule_catatonia_escalation_v1` | `data/clinical_rules.json` | Pending | | Runs in prototype mode only, and applies only its non-medical effect `mark_assessment_started`. |
| (pending) | Elias Ward dialogue | `data/dialogue.json` | Pending | | `clinical_review_status: PENDING`. A placeholder `assessment` state was added; see `docs/SPRINT_01.md`. |
