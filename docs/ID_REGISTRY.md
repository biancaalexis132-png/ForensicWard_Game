# Id registry

Rules for stable ids across all five chapters. `ContentValidator.check_global_ids` enforces the prefix and uniqueness rules on every load; this page lists what exists and what is reserved so two workstreams never pick the same id.

## Rules

- Ids are lowercase letters, digits and underscores, starting with a letter (`ContentSchemas.ID_PATTERN`).
- Patients, staff, clues, hypotheses, objectives, beats, zones and zone connections carry their prefix and are unique across every file and chapter. A chapter is a field (`"chapter": "ch2"` on a story file), never an id rewrite.
- Chapter ids are `ch1` … `ch5` (`data/campaign.json`).
- Never reuse an id for different content. Voice line ids follow the same rule: changed wording gets a new line id and regenerated audio (`AGENTS.md` §5, `docs/AUDIO.md`).
- Reserve an id here before using it in a branch.

| Kind | Prefix | Checked by the validator |
|---|---|---|
| Patient | `pt_` | yes |
| Staff | `staff_` | yes |
| Clue | `clue_` | yes |
| Hypothesis | `hyp_` | yes |
| Objective | `obj_` | yes |
| Beat | `beat_` | yes |
| Observation | `obs_` | per patient (convention, not yet enforced) |
| Zone, zone connection | `zone_`, `conn_` | yes |
| Anomaly episode | `anom_` | planned (F3) |
| Chapter | `ch<n>` | yes |

Pharmacology placeholder patients (`data/patients/PT-001.json`, `PT-002.json`) use a separate upper-case scheme read only by `PharmacologyEngine`. When a story patient needs pharmacology, link it from the `pt_*` record instead of adding a second patient id (F0 C8).

## Existing ids (2026-10-17, `main` at `33b2e8c`)

| Kind | Ids |
|---|---|
| Patients | `pt_elias_ward` |
| Observations (Elias) | `obs_mutism`, `obs_posturing` |
| Staff | `staff_voss`, `staff_bennett`, `staff_hale` |
| Clues | `clue_transfer`, `clue_roster`, `clue_access` |
| Hypotheses | `hyp_identity_reuse` |
| Chapter 1 objectives | `obj_meet_bennett`, `obj_see_elias`, `obj_document`, `obj_act`, `obj_compare_records`, `obj_sign_out`, `obj_w0b`, `obj_end` |
| Chapter 1 beats | `beat_b2_handover`, `beat_b6_intercom`, `beat_b6_unease` |
| Clinical actions | `evaluate_catatonia`, `request_medical_review` |
| Clinical rules | `clinical_rule_catatonia_escalation_v1`, `clinical_rule_medical_review_request_v1` |
| Zones (`data/zones.json`) | `zone_clinical_wing`, `zone_security_admin`, `zone_research_level`, `zone_historic_sublevel`, `zone_ward_zero` (placeholder) |
| Zone connections | `conn_ward_entry`, `conn_restricted_lift`, `conn_service_hatch` |
| Chapter 1 voice scenes and lines | `ch1_b2_bennett_handover` (`ch1_b2_bennett_001`–`003`, `ch1_b2_player_001`–`002`), `ch1_b6_after_hours_intercom` (`ch1_b6_intercom_001`) |

## Reserved, no content yet

From the v1.1 handoff package. Reserving an id does not approve its content.

| Kind | Ids |
|---|---|
| Patients | `pt_mara_ellis` (introduced Ch2; owner-approved placement), `pt_julian_reyes`, `pt_evelyn_park` (Ch2), `pt_nadia_bell`, `pt_robert_vale` (Ch3), `pt_tessa_monroe`, `pt_gabriel_chen` (Ch4) |
| Staff | `staff_mercer`, `staff_rahman`, `staff_price`, `staff_torres`, `staff_brooks`, `staff_kim`, `staff_cross`, `staff_okafor` |
| Chapter 2 (Mara; placement amended 2026-10-17) | `obj_evaluate_mara`, `clue_mara_archive_date`, `hyp_archival_code_reuse` |
| Zones and connections | `zone_exterior`, `zone_apartment` (Stage 7), `conn_sealed_corridor` (historic substructure to Ward Zero), `conn_lift_historic` (restricted lift to the historic landing) |
| Later hypotheses | `hyp_time_gap` (Ch2), `hyp_legacy_bridge` (Ch3), `hyp_known_risk_not_remediated` (Ch4) |

Not reserved on purpose: the package's `obs_elias_*` set, which would duplicate the meaning of `obs_mutism` and `obs_posturing` (F0 §3).

## Protagonist option contract (P1)

Prefix `popt_` is reserved for future authored protagonist catalog options. `ProtagonistValidator` checks syntax, a nonempty suffix, group-specific references and uniqueness across a supplied catalog. It is not yet integrated into ContentRegistry/global shipped-content validation. `popt_fixture_*` IDs under `scripts/tests/fixtures/protagonist/` are synthetic test data, not approved player options or reserved narrative content. No authored protagonist catalog ships in `data/`.
