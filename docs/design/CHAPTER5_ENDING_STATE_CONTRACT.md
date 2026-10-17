# Chapter 5 ending-state contract — pure foundation

**Status:** Technical proposal implemented as a non-persistent validator on `copilot/chapter5-ending-state-foundation`. Owner approved this bounded contract/test milestone. This is not approval of Chapter 5 dialogue, task content, evidence thresholds, or gameplay. It adds no SaveManager provider, runtime effect, authored Chapter 5 data, or clinical rule.

## Scope and ownership

`FinaleStateSchemas` and `FinaleStateValidator` accept in-memory dictionaries only. They do not load files, mutate state, emit events, use random numbers, access clinical managers, or register with `SaveManager`/`ContentRegistry`. `TestRunner` discovers the accompanying synthetic tests automatically.

The current save format stays at v3. The protagonist P1 branch (`codex/protagonist-schema-p1`) separately defines a pure creation-draft contract; it does not define a persisted profile. Finale eligibility has no protagonist profile, personality, relationship, trust, supernatural-belief, diagnosis, symptom, or treatment input.

## Contract v1

The finale dictionary has:

- `schema_version`
- `clinical_tasks`: task IDs and `pending`, `completed`, or `safely_escalated` outcomes
- `evidence`: evidence ID, original `source_id` or `derived_from` IDs, authentication status, and review status
- `report_status`: `not_started`, `draft`, or `reviewed`
- `decision`: `none`, `independent_review`, `restricted_access`, or `continuing_inquiry`
- `completed`

The validator takes an external clinical-task catalog and a list of required task IDs. Each required or recorded task must exist in that catalog with `clinical_review_status: APPROVED`; no actual task, clinical wording, or rule is added here. The required task list comes from reviewed authored content when such content exists. Unapproved entries cannot satisfy a gate.

Evidence authentication and review are separate. An original acquisition has a `source_id`; a derivative references one or more evidence IDs and cannot declare a new acquisition source. The validator rejects duplicate evidence IDs, duplicate dependency edges, unknown dependencies, and derivation cycles. Unique acquisition-source IDs are deduplicated, and only original entries that are authenticated and accepted in review contribute. Derived copies do not increase the source count. Distinct IDs are not, by themselves, proof of independent origins.

The contract intentionally defines **no minimum corroboration count**. A reviewed unresolved/disputed/refuted item remains reportable and does not by itself make responsible endings unavailable. A pending authentication or review keeps the evidence gate open. Full source provenance such as clock authority, raw-file digest, acquisition procedure, calibration, custody events, and shared infrastructure is still needed before any future claim of real-world independence; this first contract only prevents obvious duplicate/derived-copy counting.

All three ending IDs are available when every required clinical task is completed or safely escalated, all evidence has non-pending authentication and review states, and the factual report is reviewed. Eligibility is independent of profile/relationship/clinical interpretation. The decision and completion fields must be consistent with the gates. This contract does not decide who has institutional signing authority or add a decision audit trail; those remain design requirements before playable implementation.

The major corridor-loop reveal remains Chapter 4, Scene 09. This contract has no anomaly trigger or reveal progression field. A future content/runtime PR must preserve that boundary and test that clinical state cannot trigger or promote anomaly evidence.

## Deterministic coverage

`scripts/tests/test_finale_state_contract.gd` uses test-only synthetic IDs and checks:

- incomplete gates and all-three-ending availability after gates
- approved-only task resolution, including safely escalated tasks
- authentication/review distinction and explicit unresolved review
- duplicate-source and derived-export counting
- distinct acquisition-source counting without an asserted threshold
- malformed/unknown/cyclic lineage, duplicate IDs, invalid decision and completion consistency
- closed fields, deterministic repeated validation, input immutability, and no changes to PatientManager, SaveManager providers, or run seed

## Deferred approval

No persistent schema or v3→v4 migration is included. Before persistence, design one migration that coordinates the future protagonist provider and any finale provider; preserve and test the complete v1→v2→v3 chain, real v1/v2/v3 fixtures, round trips, resets, and idempotence before and after a decision. The owner must separately approve that schema/migration and the resulting gameplay contract. Clinical reviewers must approve any clinical task definitions or wording; no approval is implied by this validator or its synthetic tests.
