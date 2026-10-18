# Clinical review log

Every clinical rule or model that affects gameplay needs a recorded review by the executive producer (psychiatrist) before it is used as approved medical logic (GDD §8, §17).

| Date | Item | Location | Decision | Reviewer | Notes |
|---|---|---|---|---|---|
| 2026-10-17 | Pharmacology exposure model v0 (CYP phenotype, FDA-class inhibition/induction, smoking CYP1A2 induction, inflammation, renal/lithium clearance, additive QTc, side-effect channels, 20-drug database) | `staging/pharmacology/` | **Approved** | Executive producer | Approved in chat. Integration into `ClinicalRules` is scheduled for Sprint 2; each rule will then get its id, source, review date and test examples per GDD §8. |
| (pending) | `clinical_rule_catatonia_escalation_v1` | `data/clinical_rules.json` | Pending | | Runs in prototype mode only, and applies only its non-medical effect `mark_assessment_started`. |
| (pending) | Elias Ward dialogue | `data/dialogue.json` | Pending | | `clinical_review_status: PENDING`. A placeholder `assessment` state was added; see `docs/SPRINT_01.md`. |

| 2026-10-18 | Chapter 2 opening handoff/worklist | `data/story_chapter2.json` | **Pending; no clinical approval granted** | | Implemented under the owner's request for small Chapter 2 playable slices. Nonclinical work ownership and unresolved records request only. No new findings, diagnosis, medication logic or Mara content. Proposed dialogue remains pending narrative review; `clinical_review_status: PENDING` retained. Animation approval does not approve clinical content. |

| 2026-10-18 | Chapter 2 source-review continuation | `data/story_chapter2.json` | **Pending narrative review; no clinical approval granted** | | Source-clock/order/dependency/custody questions and unresolved follow-up only. No received record, new clinical finding, Mara history or supernatural conclusion. Clinical state remains separate and tested. |

| 2026-10-18 | Chapter 2 Scene 03, Mara Ellis introduction (interview dialogue) | `data/dialogue_mara.json`; patient record `pt_mara_ellis` in `data/patients.json` | **Approved (scene dialogue)**; patient record **pending** | Owner (executive producer) | Owner's words in the Forensics Game project thread, 2026-10-18 23:27 UTC: "i approve scene 3". Dialogue transcribes revised CH02 Scene 03 (`CH02_EXPANDED_SCENES_v2.md`), so `dialogue_mara.json` is `APPROVED`. Observation wording and the three `differential_tags` were written by the agent from that scene's documentation notes, so the patient record stays `PENDING_PSYCHIATRIST_REVIEW`. No diagnosis, medication logic, forensic opinion or treatment effect. |
