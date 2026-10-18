# CP-001 v2 clinical-content and implementation review

**Disposition: design review only.** This review does not clinically approve the case, diagnose a fictional patient, or authorize runtime use. The owner-approved direction is limited to an established historical schizophrenia diagnosis, potentially co-occurring mood/anxiety symptoms, five longitudinal encounters, and patient-centered recovery. Every clinical detail and playable line remains pending qualified review. Do not activate clinical rules, load this JSON as runtime content, change the save schema, or merge automatically.

**Reviewed source:** `origin/docs/jordan-vale-v2` at `8131b240afd77710b277f010b8b096c1a6b684d2`, the exact source commit merged by PR #36. All nine files from that commit were read; this report is additive and leaves those files unchanged. Review base: `origin/main` at `03f1585a62bd33db7dcfe8116b50db71f8ee171b`. PR #36 is merged; PR #35 and PR #34 are also merged, and no open PRs were returned by the live GitHub query. The pre-existing handoff/status snapshots citing `fb07887` predate those merges and must not be treated as the current GitHub state.

Priority labels below describe implementation/review blockers, not clinical acuity: **P1** blocks clinical or runtime adoption; **P2** must be resolved before the related implementation phase. “Psychiatrist decision required” is deliberately not a clinical conclusion.

## Findings

| # | Priority | Disposition | Finding |
|---|---|---|---|
| 1 | P1 | Owner decision + author correction | Jordan’s identity/canon continuity is unresolved across the two packages. |
| 2 | P1 | Psychiatrist decision + author correction | The historical diagnosis and encounter material lack a reviewable source record; symptom coverage remains intentionally incomplete. |
| 3 | P1 | Psychiatrist + owner approval | Safety, legal-authority, and collateral boundaries are stated as unknown but are not yet operationalized for the five encounters. |
| 4 | P1 | Author correction + technical contract gap | Source IDs name potential records, not versioned records or source events; provenance and consent cannot yet be enforced. |
| 5 | P1 | Technical contract gap | The JSON is a proposal, not content accepted by the existing patient schema/validator; identity and schema version mapping remain undefined. |
| 6 | P1 | Technical contract gap + owner approval | The case lifecycle, ending-independent access, save migration, and replay isolation have no implemented or fully specified integration contract. |
| 7 | P2 | Author correction + technical contract gap | Timeline time, task ownership, and handoff acknowledgment need explicit semantics before deterministic persistence. |
| 8 | P2 | Author correction | The referenced v1 source package is unavailable in the fetched repository history, so the claimed v1 comparison cannot be independently verified. |

### 1. Resolve Jordan’s cross-package identity before canon or case linkage

The v2 README calls this “Jordan Vale” canon in a post-Chapter-5 Continuing Practice case, while the dossier defines Jordan as 36 and gives `pt_cp001_jordan_vale` as a proposed ID (`README.md` **Canon**; `PATIENT_DOSSIER.md` **Identification and setting**, lines 5–8). The merged five-chapter source package instead calls Chapter 1’s Jordan a provisional, unapproved second patient: `docs/design/screenplays/ForensicWard_Five_Chapter_Screenplay/README_START_HERE.md` line 9, `chapters/CH01_THE_ADMISSION_FULL_SCREENPLAY_DRAFT.md` line 229, `clinical/CLINICAL_APPROVAL_REGISTER.md` line 9, and `production/IMPLEMENTATION_CROSSWALK.md` lines 12–15. The v2 handoff says no existing campaign patient is modified, but does not state whether this is that same person or a separate patient (`COPILOT_HANDOFF.md` **Source**).

This is a factual approval-boundary conflict, not a reason to infer an age or rewrite Chapter 1. The owner must decide whether CP-001 introduces a new patient or intentionally reconciles the provisional Chapter 1 character. Then the author should align the package README, dossier, case ID/record ID, campaign references and any future global ID registry. Keep each existing use provisional until that decision is recorded.

### 2. Keep narrative direction distinct from clinical approval and sourced history

The established schizophrenia history is explicitly approved only as narrative direction; the dossier says its original records, diagnosis date, first-episode details and adjudication are not authored (`README.md` **Status** and **Source boundaries**; `PATIENT_DOSSIER.md` **Identification and setting**, **Source-attributed presenting record**, and **Outstanding case approvals**; `CLINICAL_REVIEW_MATRIX.md` row **Historical schizophrenia diagnosis**). The timeline’s only historical source is an undated “prior chart summary” with original details pending (`LONGITUDINAL_TIMELINE.md`, **Prior years**). No clinical review fields are filled in `CLINICAL_REVIEW_MATRIX.md` **Formal signoff fields**.

Treat the historical diagnosis as the approved fictional chart direction, not as independently confirmed by these five interviews. A psychiatrist must review how the summary can be represented and what provenance is appropriate. Do not add diagnostic criteria, dates, admissions, symptoms, or records to make it appear better supported.

The mood/anxiety direction is also not a comorbid diagnosis. The dossier and matrix appropriately leave thresholds and differentials unresolved, but the screenplay contains only a short report of anxiety about appointments and “sometimes I feel low” (Encounter 3, `FIVE_SHIFT_SCREENPLAY.md` lines 104–142); its duration, course, effect and follow-up prompts are not authored. Encounter 4 offers an unfilled prompt branch rather than a reviewed assessment (`FIVE_SHIFT_SCREENPLAY.md` lines 148–184). A qualified reviewer must decide what questions and responses, if any, are suitable. Until then, no symptom score, diagnosis, normal finding, deterioration or improvement may be inferred.

### 3. Turn safety, legal authority, and collateral limits into reviewed boundaries

The dossier correctly says unassessed safety domains are unknown, not low risk; it also leaves detention basis, legal status, capacity and discharge eligibility unavailable (`PATIENT_DOSSIER.md` **Safety and forensic context**, **Consent, confidentiality and legal records**, and **Outstanding case approvals**). The clinical matrix keeps risk and legal/forensic content pending (`CLINICAL_REVIEW_MATRIX.md` rows **Risk**, **Legal/forensic**, and **Capacity**). The screenplay has no authored, reviewed safety prompt or escalation content; Encounter 4 only says to ask about mood/anxiety and to include a reviewed safety assessment “as indicated” (`FIVE_SHIFT_SCREENPLAY.md` Encounter 4, **Meaningful player branches**).

The psychiatrist and owner must decide which domains are in this case, which remain explicitly unassessed, and what reviewed recipient/escalation boundary applies. Do not invent a risk result, legal status, authority, or treatment action. For Sam, the script makes contact optional and requires authorization (Encounter 3, `FIVE_SHIFT_SCREENPLAY.md` lines 115–138), but implementation still needs a reviewed consent basis, scope, record, and no-contact outcome before any private information can be disclosed.

### 4. Make source provenance describe actual records, not just possible source categories

`case_cp001_v2.json` lists five `source_ids` (`source_cp001_referral`, `source_cp001_nursing_shift`, `source_cp001_patient_report`, `source_cp001_medication_reconciliation`, `source_cp001_family`) but contains no source catalog entries, record identifiers, authors, timestamps, reliability, verification state, or acquisition events. Meanwhile the dossier and timeline refer to a prior chart summary, attendance/activity logs, patient reports, and a medication record not yet verified (`PATIENT_DOSSIER.md` **Source-attributed presenting record**; `LONGITUDINAL_TIMELINE.md` rows **Prior years** through **Shift 5**). The `source_cp001_family` name can be mistaken for available collateral even though consent has not been granted.

Before authoring playable records, define an unavailable/not-yet-obtained state distinct from an acquired source. Map each authored statement to its source and event; keep patient report, nursing collateral, chart record, and direct observation distinct. A family source must not exist as available evidence or be disclosed before valid permission. If a record is unavailable, preserve that fact without substituting normal or negative findings.

### 5. Keep the proposal JSON outside the current runtime schema

The file self-identifies as `schema_version: "proposal_0.2"`, `clinical_review_status: "PENDING"` and `case_version: "2.0"` (`case_cp001_v2.json` lines 2, 6, 76). Its patient uses `proposed_id`; it is not the existing patient document shape. The current `ContentSchemas.PATIENT` requires fields including `id`, `fictional`, `legal_status`, `arrival_shift`, `presentation`, and `clinical_review_status`, and `ContentRegistry.MANIFEST` loads `data/patients.json` rather than this case package (`scripts/content/ContentSchemas.gd`, `PATIENT` / `PATIENTS_FILE`; `scripts/autoload/ContentRegistry.gd`, `MANIFEST`). No Continuing Practice runtime director, case lifecycle, or case-package validator is present on the reviewed `main` baseline.

That mismatch is expected for a proposal, not a defect to “fix” by inserting it into `data/patients.json`. Before implementation, specify the case schema and the meanings of proposal/schema/content versions; define a patient identity separate from the case identity; collision-check all IDs; and add deterministic structural and cross-reference validation. A pending case must remain inert and must not register clinical effects. Keep that schema/validator work in a separate technical PR.

### 6. Do not adopt the lifecycle or migration contract until ending and replay ownership is settled

The gameplay contract proposes a single forward lifecycle plus `on_hold`, `handoff_pending`, and `handoff_acknowledged`, while the JSON makes the case optional, lists `chapter_5_completed` as a dependency, and declares access for endings A/B/C (`GAMEPLAY_CONTRACT.md` **Lifecycle**, **State separation**, and **Deterministic tests required**; `case_cp001_v2.json` `mandatory`, `chapter_dependencies`, and `ending_access`). The cited dependency is not yet mapped to the existing `ChapterDirector.has_completed(chapter_id)` contract; `data/campaign.json` still marks Chapter 5 `planned`. The A/B/C ending/state contract is itself a proposal, not runtime state (`docs/design/screenplays/ForensicWard_Chapter5_Finale_v2/CH05_ENDINGS_AND_STATE_CONTRACT_v2.md`, **Ending selection** and **Persisted narrative dimensions**).

`SaveManager.gd` is currently v3 with only v1→v2 and v2→v3 migrations. Its providers snapshot the active run, and `reset_all()` resets every registered provider; there is no CP case provider or case/run instance identifier. Therefore the gameplay contract’s save-per-encounter, post-ending access and restart/replay-isolation tests are requirements, not supported behavior today. Define how case acceptance and recurring follow-up relate to Chapter 5 completion, how all endings retain essential access, and how a new run/replay cannot overwrite or leak into another completed run. Coordinate a single reviewed v3→v4 migration across Continuing Practice, finale, and protagonist/save planning; do not increment the schema or add provider state in this review.

Clinical rules and narrative state must remain separate: case availability, source discovery, and a supernatural event may never change diagnosis or treatment. Preserve this as an explicit negative test, not just a narrative convention.

### 7. Specify time and handoff state sufficiently for deterministic saves

The timeline labels prior history “undated” and shifts as ordered encounters that may span nonconsecutive days (`LONGITUDINAL_TIMELINE.md`, **Prior years** and concluding note). The gameplay contract nevertheless requires replay/save to preserve original source timestamps (`GAMEPLAY_CONTRACT.md`, **State separation** and **Deterministic tests required**). Separate the timestamp on an authored/source record from the in-game time an event was observed or recorded; leave either unknown when the source does not provide it. Do not invent dates or make encounter count imply elapsed-time progression.

The contract also prevents pending tasks from disappearing and disallows shift closure without completion or an appropriate handoff (`GAMEPLAY_CONTRACT.md` **Lifecycle** and test 10). Encounter 5 says a handoff remains open until responsibility is acknowledged and proposes `cp001_handoff_ack`, but does not define task IDs, accountable recipient, transmission/acknowledgment payload, failure/retry, or whether acknowledgment closes the task (`FIVE_SHIFT_SCREENPLAY.md` Encounter 5, **Draft full conversation** and **Documentable exit / state**). Specify those transitions and test them. A signed note is not proof of delivery; acknowledgment is not proof of clinical resolution.

### 8. Restore the referenced v1 baseline before claiming a verified v1 diff

`README.md`, `CHANGELOG.md`, and `FIVE_SHIFT_SCREENPLAY.md` say v2 revises a v1 package and retains earlier v1 dialogue, while `COPILOT_HANDOFF.md` points to `docs/design/continuing_practice/CP001_Jordan_Vale_v1`. That path is absent from the fetched repository refs checked for this review, including `main`, the v2 source branch, and the complete-campaign source branch. The v1 history/path was not found in the fetched Git commit/file history either. Consequently this review cannot verify which v1 content was retained, removed, or changed.

The author should restore/link the exact v1 commit or package, or revise the v2 changelog and handoff to state that the comparison source is unavailable and enumerate only changes that can be evidenced. Do not reconstruct v1 from memory or claim an independently verified comparison.

## Existing architecture and coordination

- **Continuing Practice:** no case lifecycle or case-package runtime is on the reviewed main baseline. Current patient data is loaded through the global `patients.json` schema and `PatientManager`; proposed CP content remains documentation-only.
- **Save/ending state:** SaveManager v3 and Chapter 5/A/B/C state are not a CP implementation contract yet. `GAMEPLAY_CONTRACT.md` correctly calls its v3→v4 migration a coordinated proposal; retain that gate and test authentic v1/v2/v3 fixtures if a later migration is approved.
- **Ending-independent access:** preserve all essential case access across A/B/C and protagonist variations; do not make case acceptance or continuity depend on trust, background, a supernatural discovery, or a clinical result.
- **Naomi:** acting-cue PR #35 is merged on main. Naomi 3D/model work is on the separate active `biancaalexis132-png-naomi-character-pipeline` branch at fetched remote `2a6ffda5e580c551b0f2f235861960e0d7662657`; no model files were touched. The proposed Naomi lines in CP-001 are not runtime dialogue or approved acting-cue IDs. Keep those workstreams separate until identity/canon and clinical content are approved; no Naomi cue should reveal clinical or supernatural facts.
- **Supernatural boundary:** the package’s explicit rule that symptoms never evidence Ward Zero is sound and must remain a hard data/runtime boundary. Neither an anomaly nor its discovery may alter clinical state, risk, diagnosis, eligibility, or access to care.

## Minimal gated implementation sequence

1. **Documentation/canon correction:** owner decides whether this is the provisional Chapter 1 Jordan or a separate patient; author reconciles identity, IDs, v1 provenance, source availability, timeline semantics, and task/handoff language. Preserve unknowns.
2. **Clinical approval:** qualified psychiatrist reviews the exact dossier, each playable line and branch, assessment prompts, consent language, safety/escalation scope, and source-attributed record examples. Owner separately approves canon, legal context, and gameplay authority. Record version, sections, restrictions, date, and reviewer in the signoff matrix. Until then all content remains `PENDING`.
3. **Separate schema/validator PR:** define a case-specific immutable schema, explicit version domains, source-reference model, stable IDs, and cross-reference checks. Test pending-status rejection and malformed/missing/unavailable sources. Do not enable case content or change SaveManager.
4. **Coordinated save proposal and migration PR:** after the finale/protagonist/CP state contract is approved, design one v3→v4 migration. Preserve previous providers and ending state; test real v1, v2, and v3 fixtures, load failure atomicity, deterministic replay, case reset, and cross-run isolation. No independent CP save-version bump.
5. **Lifecycle implementation PR:** only after prior gates, add optional acceptance, deduplicated encounter/task/handoff events, patient-owned notes through `PatientManager`, accountable handoffs, and follow-up access independent of ending/background. Add save/load and replay tests at every encounter and both pending/acknowledged handoff states.
6. **Content activation PR:** only after clinical and owner approval, wire the reviewed immutable case to the runtime. Test A/B/C and profile access, consent/no-contact, unknown vs not assessed, source separation, missing medication records, task persistence, and the invariant that Ward Zero cannot change clinical state. Keep all medical effects disabled unless separately approved.

No step authorizes automatic merge. Do not alter the nine source files as part of this review; corrections belong in a later author-owned content PR.

## Review checks and limits

- `python3 -m json.tool docs/design/continuing_practice/CP001_Jordan_Vale_v2_Schizophrenia_Recovery/case_cp001_v2.json`: **PASS**, JSON syntax only.
- Existing `ContentValidator` was not applied: it validates manifest-loaded runtime documents, and this proposal JSON is not in the manifest or a defined CP schema. There is no applicable CP case-schema validator yet.
- Full Godot/QA suite: **not run**; this is a documentation-only review and no runtime/data files were changed.
- Clinical correctness, legal authority, risk wording, and diagnosis: **not approved or assessed by this review**. Those decisions remain with the owner and qualified psychiatrist.
