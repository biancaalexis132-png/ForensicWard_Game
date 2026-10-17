# Chapter 2 Mara Ellis — approved placement and proposed implementation crosswalk

2026-10-17. Source: owner's “APPROVED STORY PLACEMENT — MARA ELLIS” instruction in this session. **Approved:** significant recurring patient, first introduced in Chapter 2, The Missing Hours. Supersedes proposed Chapter1 placement in v1.1/F0/visual canon. **Not approved:** new clinical logic, exact scene dialogue, findings, legal orders, treatments, risk mechanics or discrepancy explanation.

## Dossier preservation contract

Retain `pt_mara_ellis` (reserved, not yet a patient definition), age37, prior records work; disputed historical mood-disorder label; insomnia with fatigue, anxiety and document checking; sister Dana's collateral; conflicting **October12/14,1988** records concerning aunt **Lillian Ellis**. Preserve these as their source categories, not automatic current examination findings or diagnoses. Do not resolve which date is correct, invent what happened to Lillian, imply fraud, or make document checking evidence of psychosis or supernatural insight.

The complete previously developed clinical history, risk formulation, documentary artifacts and collateral transcript are not accessible in the repository's approved v1.1 source package. The owner has restated the anchors above; they do not supply the missing verbatim formulation, dates-of-encounter, legal status, Dana's exact statements/authority or medical observations. Preserve any supplied source when it becomes available and compare rather than reconstruct. No placeholder “normal risk,” fabricated treatment response or new diagnostic label fills that dependency.

## Proposed first encounter crosswalk (not activated)

| Scene step | Existing reusable system / stable ID | Missing source or engineering | Approval / acceptance requirement |
|---|---|---|---|
| Ch2 care introduction, potentially expanding screenplay scene03 | `data/campaign.json` ch2 planned; F1 `ChapterDirector` | Actual Ch2 story/world/dialogue module and introduction lines | Owner reviews detailed placement within Ch2; do not promote whole chapter to playable for this scene |
| Role clarification, identity and reason for meeting | DialogueManager/ContentRegistry; reserved `pt_mara_ellis` | Scope of psychiatrist role, care setting/legal status and exact patient wording | Review dialogue/jurisdiction; no inferred consent, detention or discharge powers |
| Patient's account and goals | Existing authored dialogue format | Open interviewing branches on sleep/fatigue/anxiety, record concerns and functioning; exact responses | Psychiatrist reviews patient-facing wording and what was reported vs observed; no automatic agreement/disbelief score |
| Past records work and disputed label | Patient definitions, EHR Summary/Observations | Source excerpts/date/author of historical diagnosis and patient disagreement | Preserve disputed historical status; do not confirm or remove diagnosis on narrative choice |
| Sleep, fatigue, anxiety, checking assessment | EHR and existing clinical governance | Authored history, examination/assessment limits, differential and follow-up | Pending clinical review; no invented symptom values or threshold rules |
| Dana collateral | Provenance-bearing observations/notes | Exact source text, time, authority/consent and contradictions | Keep sister report distinct from patient report/examination; don't invent reassurance or concern |
| Risk and formulation | EHR findings/considerations/plan, ClinicalRules gate | Complete prior risk formulation and reviewed encounter-specific evidence/unknowns | No silence-to-denial, default low-risk or diagnosis from draft; no medical effect while pending |
| Lillian documentary comparison | EvidenceManager, EvidenceBoard | Original Oct12 and Oct14 1988 artifacts with provenance and authorized access | Preserve both; uncertainty/ordinary explanations valid; no clinical finding or medication unlock |
| Separate clinical note and investigation note | PatientManager vs EvidenceManager; EventBus | Reviewed mapping between relevant care concern and audit reference, not copied paranormal diagnosis | No patient-symptom trigger for WardZero evidence; essential access independent of rapport/background |
| Follow-up / recurring care | F1 chapter archive, global patient state, existing handover config | Exact tasks/owner/timing and later callbacks | Review before care actions; Ch2 introduction retained through later chapter saves without replay |

Existing reservations `obj_evaluate_mara`, `clue_mara_archive_date`, `hyp_archival_code_reuse` may be reused after approval; preserve their names, reassign their **planning scope to Ch2**, and do not instantiate data or invent independent October-date clue IDs yet. No link to Elias's archived identifier is established merely because names are similar. `PT-001/002` remain separate pharmacology placeholders, not Mara.

## Chapter 1 reconciliation

Mara no longer fills Ch1 beat4. Jordan Vale remains unapproved; the new placement does not approve him. Ch1 second patient is **unassigned and not implemented**. Owner can retain a separately authored second encounter or revise/remove that planned beat; decide its missing-clinician thread independently. Existing Elias slice and sign-out census remain unchanged. Historical package/source files are preserved; GDD amendments/current canon and this crosswalk supersede their placement wording.

## Small PRs and tests

1. This documentation-only placement/crosswalk change; confirm no package/runtime edits, reserved IDs retained, pending clinical status clear.
2. Recover/reference complete prior dossier; review exact history/risk/collateral/documents and detailed Ch2 scene/branch graph. Explicit clinician sign-off per item, not blanket placement approval.
3. Author reviewed Mara patient/dialogue/document data in a bounded PR. Keep pending review gates for anything not approved; validate sources, IDs and no invented findings. Add no arbitrary legal facts.
4. Implement one approved Ch2 encounter slice using F1/F2, with provenance-aware EHR/risk limitations and independently acquired documentary evidence. Save schema/provider changes only after bounded compatibility review.
5. Separate recurring follow-up/callback slices with current clinical content approval and chapter-specific state. Coordinate audio/character/environment ownership before asset changes; D6 voice remains open.

Tests for future runtime PRs: no Ch1 Mara census/introduction, correct Ch2 first encounter and once-only resume, global patient continuity and chapter archives; no disputed label automatically current/confirmed; exact October sources preserved separately; Dana attribution/timestamps/authority retained; unknown risk not negative; pending rules no medical effects; no diagnosis/sleep/checking/rapport/medication/background gate to anomaly or essential evidence; all relevant v1/v2/v3 save fixtures/roundtrip; full Godot4.7 runner. Mac pacing/accessibility/8GB performance and clinical accuracy remain separate reviews.

Outstanding decisions: full prior source dossier and clinical approvals; Ch2 exact encounter slot and case/legal context; Ch1 beat4 retain/revise/remove; document source wording/authorization and unknowns; recurring scene placement/voice; all unrelated later arcs/F3/endings remain proposed. **Do not re-request Mara's approved Chapter2 introduction.**

## Additional approved canon — clinical agency and investigative separation

Source: owner's “APPROVED CANON — MARA ELLIS: CLINICAL AGENCY AND INVESTIGATIVE SEPARATION”, 2026-10-17. These are approved narrative constraints; new dialogue and clinical content retain their review gates.

- Mara retains her motivations, goals, autonomy, clinical history and personal agency; preserve dossier, collateral, uncertainty and legal-status questions.
- She may voluntarily share historical documents, identify inconsistencies, seek clarification and challenge assumptions. She is not a psychic, supernatural witness, secret investigator or exposition device.
- Independently verified archives, authorized staff/security systems and environmental evidence carry the WardZero investigation. A document may substantiate a particular concern without endorsing all interpretations. Symptoms, diagnoses and treatment response never substantiate paranormal activity.
- Clinical care, safety assessment and recovery opportunities remain available regardless of mystery progress. Mandatory mystery evidence remains accessible if she declines disclosure or rapport remains limited.
- Confidentiality, consent and professional boundaries apply throughout; do not infer legal status or consent from her willingness to discuss a document.

**Concrete future branch contract:** “declines sharing”, “shares selected material” and “limited rapport” must all converge on an authorized independent records/security route to mandatory evidence. Author that route and its source/access permission before implementing a document-sharing branch. Do not copy private therapy content into an audit dossier or silently transfer document custody. Clinical notes store care evidence/limitations; EvidenceManager stores independently sourced investigation facts and provenance. A shared document may have separately authorized references in each context; neither system invokes the other's medical/anomaly conclusions.

Future tests must compare mandatory-evidence reachability for all disclosure/rapport paths; no document/therapy-dependent anomaly unlock, care/recovery dependent on WardZero completion, or blanket validation of interpretations. Check voluntary withdrawal/decline handling, confidentiality and independent-source attribution. Exact clinical/risk outcomes remain unasserted pending clinical authorship/review.
