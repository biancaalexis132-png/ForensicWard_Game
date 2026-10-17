# THE FORENSIC WARD — ENGINEERING HANDOFF TO CLAUDE (v0.1)

## Role and deliverable
You are the Lead Godot 4/GDScript Engineer. Implement a running, portable **macOS-first Godot 4** prototype, with keyboard/mouse controls. The executive producer is a psychiatrist and approves all clinical rules. Follow the locked master GDD; do not invent clinical doses or silently turn story clues into psychosis symptoms. Deliver code in small runnable batches with explicit file paths and in-editor steps.

## Locked constraints
- Cinematic realistic target with progressive greybox-to-final art; macOS first; keyboard and mouse.
- Offline core gameplay; no paid inference/API dependencies; hybrid structured dialogue with bounded free-text intent recognition.
- Deterministic clinically-reviewed rule engine separate from narrative triggers; save/load all mutable state.
- 90–120 minute chapter **content target**; first build 10–15 minute functionality proof.
- Never embed textbook passages or unapproved prescribing rules into released assets.

## Architecture
Suggested autoloads, each with narrow APIs:
1. `EventBus.gd`: typed/signalled domain events, e.g. `clinical_action_committed(patient_id, action_id, event_id)`, `clue_acquired(clue_id)`, `hypothesis_updated(hypothesis_id, status)`.
2. `ContentRegistry.gd`: loads `res://data/*.json`, performs required-field/type/id/reference validation, fails with actionable errors.
3. `TimeManager.gd`: clock, shift, advance action minutes, schedule queues, explicit pause policies.
4. `PatientManager.gd`: immutable patient definitions, mutable observation/treatment state, longitudinal update hooks.
5. `ClinicalRules.gd`: receives patient state + coded action, returns structured effects, alerts and review flags; **no hardcoded narrative unlock**.
6. `DialogueManager.gd`: authored dialogue states; deterministic question intent matcher; transcript capture and rapport deltas.
7. `EvidenceManager.gd`: clues, provenance, manual connections, hypotheses, independent verifications.
8. `TrustManager.gd`: professional-respect/trust/suspicion vectors, bounded and non-binary.
9. `SaveManager.gd`: `save_version`, canonical state, migrations, checksum optional, event dedupe.

## Scenes and folders
```
res://
  scenes/main/Main.tscn
  scenes/world/HospitalGreybox.tscn
  scenes/player/FirstPersonController.tscn
  scenes/ui/EHR.tscn
  scenes/ui/Interview.tscn
  scenes/ui/EvidenceBoard.tscn
  scenes/ui/PauseMenu.tscn
  scripts/autoload/{EventBus,ContentRegistry,TimeManager,PatientManager,ClinicalRules,DialogueManager,EvidenceManager,TrustManager,SaveManager}.gd
  scripts/tests/
  data/{patients,dialogue,clinical_rules,clues,hypotheses}.json
  assets/placeholders/
```

## Prototype scene flow
Main → FirstPersonController in hospital greybox (corridor, office, interview room) → interact with nurse → Elias interview (cinematic fixed camera) → EHR → record assessment and safe action → patient response → collect transfer record and archived roster → manually link clues → notification → save/reload. All UI accepts Esc and restores mouse capture appropriately.

## JSON data contracts
See adjacent `data/*.json` fixtures. Stable IDs required. No PHP or network services. Keep patient PII entirely fictional. Never conflate source facts with physician belief: observations include author, timestamp, provenance, reliability clues and `verified` flag.

Clinical action event sample:
```json
{"event_id":"evt_day1_assess_catatonia","type":"clinical_action","patient_id":"pt_elias_ward","action_id":"evaluate_catatonia","at_minutes":522,"payload":{"finding_ids":["obs_mutism","obs_posturing"]}}
```
Outcome evaluator contract:
```json
{"rule_id":"clinical_rule_catatonia_escalation_v1","condition":{"patient_id":"pt_elias_ward","action_id":"evaluate_catatonia"},"effects":[{"path":"patients.pt_elias_ward.assessment.catatoniasuspected","set":true}],"clinical_review_status":"PENDING"}
```
Do not activate PENDING clinical rules in build modes presented as medically validated.

## MVP acceptance tests
1. Godot imports and opens with no parsing errors on target Mac.
2. WASD movement, mouse look, E interaction and Esc pause work reliably.
3. Dialogue intent parser maps ‘Is he eating?’ to a supported nutrition topic and falls back politely for unsupported input.
4. Opening the same patient record twice does not duplicate events.
5. Clinical and narrative state reducers produce repeatable results for a fixed seed.
6. One action changes observation/patient-state data; independent story-clue availability uses explicit event subscription.
7. Two clues can be pinned, manually linked, unlinked and persist after save/load.
8. A false hypothesis can be registered without invalidating the patient chart or causing a soft lock.
9. Time progression and emergency escalation do not trigger contradictions (e.g. patient simultaneously in ICU and Ward Zero).
10. Audio/transcript and visual effects can be independently disabled via accessibility options.

## First three engineering sprints
**Sprint 1:** repository and project setup; graybox rooms; controller and interaction; input map; JSON schema validator; sample content importer; test runner.
**Sprint 2:** patient record view; dialogue UI and topic matcher; observation capture; rule engine scaffolding using non-medical placeholder outcomes; save/load.
**Sprint 3:** evidence board and manual links; shift time; nurse trust; scripted Ward Zero clue; integrated branch and regression tests.

## Request to Claude
Start with Sprint 1. Return a file tree, the complete contents of every new script/scene/project file, a Mac-specific import/run checklist, and a test checklist. Never skip a dependency or use pseudocode for files claimed runnable. Ask for the Mac hardware model only if actually required for renderer selection; default to a conservative scalable starting renderer and allow reconfiguration.
