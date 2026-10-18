# Full-campaign gameplay, clinical and evidence contract (proposed)

## Absolute continuity rules
1. Player always is a psychiatrist; all backgrounds retain competence and access. Moderate optional personal history; no mandated romance/trauma.
2. Naomi Bennett is Charge Nurse, with pulled-back natural twists, navy scrubs and approved reference likeness. Dr. Leila Rahman is Consultant Psychiatrist. Marcus Hale is Security Director. Voss is Medical Director.
3. Mara Ellis begins Chapter 2 as an autonomous patient with her own dossier. She may furnish documents but cannot be the investigator's sole evidence source, and her diagnoses/treatment do not follow from the environmental mystery.
4. Ward Zero first entered in Chapter 3 under Security/Facilities authority; only preliminary/ambiguous measurements occur there. Major first authenticated corridor-loop reveal is Chapter 4 scene 09, never earlier.
5. Supernatural phenomena are true in the fiction but unexplained to the institution. Psychiatry is not a mechanism for the paranormal.
6. Three Chapter 5 endings A/B/C available independent of belief, personality and relationship scores, subject to equivalent mandatory safety/clinical workflow.

## Current engine: avoid unnecessary replacements
Preserve `AuthoredWorld`, `WardCharacter`, `PatientManager`, `ClinicalRules`, `EHRScreen`, `EvidenceManager`, `AudioDirector`, `SaveManager`, and current dialogue/observation IDs. The current protagonist and finale implementation proposals must be reconciled before any new persistent fields.

## Clinical workflow
Chart review → patient approach → source-specific observations → supported hypotheses → bounded note → explicit communication and acknowledgment → outstanding-task handoff or escalation. No missing vital sign/lab/medication/result is assumed normal. PatientManager notes remain append-only. Pending clinical rules cannot produce validated medical effects.

## Data provenance
For each raw source track: stable ID, collector/role, original capture, immutable checksum, acquired time, clock authority/uncertainty, device calibration, site, custody events, transformation lineage and shared source/clock dependencies. An authenticated copy is NOT a second independent observation. Separate authentication / independence / interpretation flags.

## Chapter 3 inspection safe return (requires implementation and approval)
States: PROPOSED → AUTHORIZED → BRIEFED → ENTERED → OBSERVING → EXITING → ALL_ACCOUNTED_FOR → ARCHIVED. PAUSED/ABORTED/RECOVERY_PENDING may occur in any active phase. Stop when staff are lost, route blocked, comms fail, timing condition fails or safety officer calls stop. On app crash/load, restore last authorized safe checkpoint; never reopen a restricted threshold or auto-teleport a player into an unsafe sublevel. Final progression requires accountable egress roster. Verify in both interactive and headless tests.

## Save migrations and ending
Current known schema v3 (v1→v2→v3). If new persistent finale/protagonist state is approved, design a single coordinated v3→v4 migration, not two competing providers. Legacy saves receive safe defaults. Ending selection must be written once, survive save/load, and not replay irreversible actions. Test fixtures for v1, v2, v3, then v4 roundtrip. Never force legacy saves back through protagonist creation.

## Ending requirements
A: referral ID, recipient authority, source inventory, reply owner, follow-up deadline. B: restriction owner, scheduled reassessment and documented reopening criteria. C: approved investigation scope, owner, independent oversight, reporting checkpoints and clear stop conditions. All retain necessary clinical coverage and patient handoff.
