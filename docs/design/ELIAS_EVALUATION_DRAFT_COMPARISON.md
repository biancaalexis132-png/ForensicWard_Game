# Elias Ward first evaluation: screenplay-summary comparison

**Draft pending owner clinical review.** Input is the owner’s 2026-10-17 screenplay-summary message, not a complete supplied screenplay file. Its required elements are EHR preparation, minimally communicative interview attempts, structured motor/medical assessment, diagnostic uncertainty, MSE documentation, immediate safety evaluation, record reconciliation and a later after-hours W0-B transfer-request mystery. The owner confirmed that the full script was drafted in ChatGPT, is not committed or in a PR, and will be provided as a standalone document. Existing GitHub content is preliminary implementation, not that screenplay. Exact new dialogue wording cannot be reviewed or approved from the summary alone; do not ask again for an already-confirmed repository location.

This document maps exact **existing** content locations and required changes. It does not replace working dialogue/rules or activate clinical logic. Maintain `pt_elias_ward`, existing narrative beat IDs, provenance, review status, and the late-shift schedule.

## Existing content and proposed deltas

| Existing location / stable key | What exists | Required draft-alignment change, pending review |
|---|---|---|
| `data/patients.json` `pt_elias_ward` | Age 29; pending clinical review; authored `obs_mutism` (nursing report, `day1_0814`) and `obs_posturing` (physician observation, `day1_pending`, “requires structured bedside examination”) | Preserve identity and sources. Separate collateral report, direct examination, uncertain interpretation and unassessed domains; do not turn authored possibilities into automatically established findings |
| `data/dialogue.json` `initial/ask_intake` | Silent response, reduced intake reported by nursing; records `obs_mutism` | Review an attempted interview and collateral/chart pathway. Silence is not refusal, dishonesty or normal safety screening. Preserve source attribution; an interview action must not relabel nursing collateral as a fully established bedside finding |
| `initial/assess_motor` → `assessment` | Says structured assessment becomes available, but already records `obs_posturing` through `records_observations` | Critical review point: make the actual reviewed examination available before committing any finding that requires it. Clarify possible versus established observation. Do not simply add more automatic findings or a diagnostic conclusion |
| `assessment/return_to_general` | Placeholder says bedside assessment is authored in Sprint 2 | Replace only after reviewed screenplay/exam content exists. Add supported interview/exam choices and safe fallback responses; preserve IDs or explicitly version new content/lines as appropriate |
| `initial/ask_ward_zero` | Immediately available; no verbal response, orderly closes observation window | Review deferral out of the first clinical encounter to satisfy approved hospital-drama opening. Do not imply mutism or motor symptoms cause supernatural events. No automatic change made here |
| `scripts/ui/EHRScreen.gd` and PatientManager | Summary, Observations, Notes, Orders, Audit; notes cite recorded finding IDs and differential tags, with free-text plan | Extend existing workflow with reviewed MSE, formulation/uncertainty, information-source and safety documentation. Do not add a parallel EHR/save store. Missing information must remain explicitly unknown/unable/not assessed, not normal or denied |
| `data/clinical_rules.json` `evaluate_catatonia` / `request_medical_review` | Pending rules; prototype nonmedical assessment/request markers; medical effects empty | Keep pending status and no new medical effect. Any examination interpretation, urgency/escalation criteria, scoring, diagnosis or treatment feedback needs explicit clinical approval and tests |
| `data/clues.json`, EvidenceManager | Transfer/roster/access facts and manual linking | Preserve acquisition/source/timestamp and contestability. The patient’s diagnosis/behavior/medications cannot validate supernatural evidence. Clarify administrative discrepancy separately from clinical formulation |
| `data/story_chapter1.json` `beat_b2_handover`, `beat_b6_intercom`, `beat_b6_unease` | Bennett handoff; day-1 night intercom + 15 in-game minutes; unease currently gated only by access clue | Preserve beat IDs and late intercom queue/offset/dedupe. Review early unease gating as documented in opening proposal; a transfer request is an audit event, never proof Elias physically moved |

`DialogueManager._apply_choice` currently records each choice’s `records_observations`; `PatientManager.record_observation` stores recorded-by/time and `verified: false`. That flag does not by itself distinguish “reported,” “possible,” “not assessed,” and “examined absent.” The F0 audit already identifies missing observation polarity. Extend this representation deliberately in a separate compatible PR rather than writing invented negatives into free text or silently changing old saves.

No normal suicide-risk, capacity, orientation or other MSE result can be inferred from a patient’s silence. No refusal should be documented without the reviewed factual basis. Retain diagnostic uncertainty; collateral/document inconsistencies and clinical findings are distinct kinds of information.

## Clinical approval matrix

| Review point | Owner must review before activation |
|---|---|
| Interview attempts and minimally communicative patient | Exact wording, opportunities to respond, attribution, respectful interpretation and fallback pathways |
| Motor and medical examination | What is actually examined, how an observation is recorded, uncertainty/limitations, and any urgency or escalation language |
| MSE and safety documentation | Field semantics, unknown/unable/not-assessed versus positive/negative findings, suicide-risk uncertainty, and permitted source-specific statements |
| Formulation / differential | Original reviewed narrative and limits; avoid treating a symptom pattern as automatic diagnosis or competency finding |
| Immediate care / medical review | Clinically appropriate escalation and rescue routes without invented thresholds, doses or new approved effects |
| Collateral / chart preparation | Source, author, timestamp, reliability and whether facts are reported or independently examined |
| Narrative reconciliation / W0-B | Inactive credential is an objective chart audit issue; no causal link from symptoms, treatment or personality to the mystery |

Existing pending statuses and `docs/clinical_review_log.md` are unchanged. Approval of dramatic structure, casting or a screenplay summary is not clinical approval. Once the owner approves exact material, add the specific item/source/reviewer/date to the review log; never mark approval on the agent’s judgement.

## Missing assets and content

- Full screenplay text/location and accessible approved bible passages for exact line/character-dynamics review.
- Reviewed Bennett/Voss onboarding and handoff extensions, plus patient interview attempts/responses and nonverbal alternatives. Preserve existing voice IDs; changed wording needs new line IDs/audio/transcripts, not silent replacement.
- Reviewed examination/MSE/formulation/safety templates and explicit not-assessed/uncertain display states, with tests and compatible persistence.
- Safe ordinary clinician/patient staging, camera coverage, gestures and props. Clinical motor/posture animation requires review; candidate neutral turnarounds are not diagnostic animation approval. No new models are assumed available.
- Objective chart/administrative documents with authored timestamps, source records and plausible ordinary explanations; no invented patient biography or dramatic clinical chart data from concept art.
- Text/accessibility equivalents, caption timing and Mac listening/playtest of the first evaluation; no persistent ominous score under clinical work.

## Phased review and implementation

1. When the owner supplies the standalone script, produce a line-by-line redline against the stable keys above; keep all material pending until its review is recorded.
2. Approve source/provenance and unknown-state data semantics; add schema/state regression tests before UI/content integration. If saves change, use an explicit versioned migration and real fixtures.
3. Add one reviewed EHR-preparation/interview slice using existing managers; verify that unperformed examinations establish no findings and silence establishes no negative safety result.
4. Add reviewed exam/MSE/formulation/documentation slices with no new medical logic unless separately approved; preserve appropriate care pathways for all backgrounds/personality styles.
5. Review administrative discrepancy and opening presentation timing separately; retain original late-shift intercom schedule/IDs and save-load dedupe.
6. Run full QA and a clinician-led Mac playthrough. Record clinical, narrative, accessibility and pacing review separately from automated pass counts.

Proposed tests include unchanged clinical state on cancelled/unperformed exam, source-specific observation capture, explicit unknown safety fields, no automatic diagnosis/refusal, same essential care/evidence for every background, clinical/anomaly independence, and night event persistence. These are planned acceptance criteria, not tests claimed to exist now.

Coordination: ongoing P1 contracts stay independent; no Chapter 1 runtime/data/dialogue files are edited in this workstream. PR #27 owns soundtrack integration; environment/Stage 6 and clinical-review owners retain their files. Exact screenplay wording remains the only blocker to a literal line review; the implementation comparison above is complete for the supplied summary.
