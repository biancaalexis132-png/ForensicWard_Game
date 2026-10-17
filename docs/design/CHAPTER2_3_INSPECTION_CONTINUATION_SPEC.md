# Chapter 2 institutional drama / Chapter 3 controlled inspection

2026-10-17 · Proposed integration and engineering specification, **not authorization to implement supernatural behavior or clinical logic**.

## Baseline, sources and approved boundary

Compared owner summaries in this session with PR30 package `docs/design/screenplays/ForensicWard_Five_Chapter_Screenplay/chapters/CH02*`, `CH03*` and Ch4 scene09; main **052859a984d7db599282914cbc300cc8cecc887b**, screenplay feature **0ead6cbd79710577852ab9a79522a5a61b960a46**. Owner explicitly confirms the new expansions exist only in the ChatGPT creative conversation, not any branch/file, and will provide revised manuscripts. Exact newly expanded scripts have not been supplied; the comparison is at scene/function level, not a line-by-line review of unseen text. Do not reconstruct dialogue or claim it is approved. Earlier package remains untouched.

**Approved:** protagonist first actual WardZero entry is in Ch3, accompanied by authorized Security and Facilities staff through a formal inspection. **Proposed:** exact entry dialogue/plan, repeated junction, temporary navigation discrepancy, controlled measurement, evidence conclusions and institutional scene expansion. No F3/Bleed decision, anomaly threshold, treatment logic or entire later chapter is approved by the entry premise. Keep five chapter slots/IDs; Ch2–5 remain planned, not playable by implication.

Already approved character roles and Mara protections still govern: Voss Medical Director with credible institutional responsibilities; Hale Security Director; Rahman Consultant Psychiatrist; Mara introduced Ch2 with clinical agency/independent care and mandatory independent evidence routes. Expanded wording remains reviewable creative material, not a wholesale canon replacement.

## Chapter 2 comparison

| Existing screenplay anchor | New summary alignment | Missing detail / review dependency |
|---|---|---|
| 01 routine/overnight changes, 03 unnamed clinical slot | Care remains primary; Mara has her own goals | Expand a real clinical scene from preserved Mara dossier, not an audit exposition shortcut. Exact history/risk/collateral/legal sources and dialogue pending; declined documents/limited rapport must retain independent mandatory evidence |
| 02 log gap, 05 ordinary explanations, 09 wrong-night file, 10 missing interval | EHR/security/facilities/archive verification; distinguish facts/interpretation | Specify source documents, event/time-zone lineage, authorized extraction, missing/uncertain results and independently corroborated facts. Do not call duplicate exports independent sources |
| 04 Voss institutional friction | Existing Voss explicitly distinguishes error and allegation, not a villain | Expanded accountability/confidentiality/safety conflict fits direction but needs exact dialogue, obligations, choices and resolutions. Respectful disagreement cannot deny core evidence or care |
| 06 Hale's Door | Existing Hale denies unsafe shortcut while allowing audit request | Need precise request/grant/revocation, access roster, legitimate denial and alternate formal route. No tactical confrontation or relationship-score badge |
| Rahman not in Ch2 draft; current Ch3 scene05 consult | Independent clinical perspective proposed for Ch2 | New placement/scene is an addition, not an existing conversation. Avoid duplicating Ch3 consult or inventing cases; approve role/scene/medical content separately |
| 07 facilities memory, 08 door ajar at historic lobby | Independent witnesses/systems, ordinary hypotheses | Memory is testimony, not objective anomaly confirmation. Lobby/door review must stay outside WardZero in Ch2. Ajar door is not permission or proof of entry |

Narrative branch table needed before content: observation (what/source/time), hypothesis (explanation/alternatives), allegation (claim about conduct/authority/recipient). Corrections do not erase the original source. No automatic guilt label, generic credibility scalar or “skepticism wins” score. Optional staff responses can vary with choices; mandatory authorized source and professional care routes remain equivalent across personality/background.

## Chapter 3 comparison and continuity conflicts

| Existing draft scene(s) | New controlled-verification sequence | Integration issue |
|---|---|---|
| 01 legitimate escorted inspection; 02 historic stairwell | Formal authorization/briefing/first entry aligns approved premise | Distinguish historic substructure from WardZero threshold; Ch3 entry needs explicit clearance/roster/exit plan, not just an access token |
| 03 W3 compact station | Route inspection could pass it | W3 layout/D7 not approved; no duplicate Stage5 station or renamed zone without environment coordination |
| 04 camera/wheelchair contradiction; 07 unconfirmed reflection | Repeated junction/navigation discrepancy is new proposed material | Decide retain/reorder/defer object/reflection beats so escalation is coherent. Do not silently replace either or prove supernatural origin from a navigation error |
| 05 current patient/Rahman consultation | Clinical/investigative separation remains required | Preserve care coverage while team inspects; findings cannot diagnose a patient or unlock treatment. Exact case still pending |
| 06 unsigned ledger; 08 work orders; 09 duplicated file | Controlled measurement and independent review expand inquiry | Need actual measurement protocol/reference plan/calibration/source facts; “controlled” cannot just be asserted. History/signatory/D4 remain open |
| 10 safe stairwell return with documented mismatch | Safe return and separate evidence preservation align | Separate observation, completed return, review and corroboration; no compulsory conclusion or forced repeat for safe exit |
| **Ch4 scene09 major looping corridor reveal** | Ch3 now proposes repeated junction/temporary discrepancy | Owner must distinguish Ch3 ambiguous/reproducible observations from Ch4 confirmed geometry. Approved first entry does not move the major reveal to Ch3. A repeat-looking junction may remain a report until independent checks; decide exact behavior before implementation |

Branch dependencies: stop/withdraw, declined measurement, incomplete records, disputed witness account and restricted access need authored convergence and later re-entry. Mandatory story facts remain available through approved independent sources without Mara, rapport, diagnosis, medication or personality conditions. A safe withdrawal need not grant uncollected evidence or instantly complete the inspection.

## F2 reuse and gaps (verified code, not hypothetical existing capabilities)

- `data/zones.json`: clinical/security/research/historic zones built; `zone_ward_zero` placeholder has no environment files/bounds. No WardZero connection exists. `conn_service_hatch` leads security→historic and requires `access_maintenance`; lift leads research, not automatically WardZero. Do not reinterpret these as unrestricted access to all lower spaces.
- `ZoneDirector`: current-zone/required same-level-neighbour residency, fade transitions for other levels, explicit access grants through `TrustManager.has_access`, and saved per-zone object state. `zone_at` uses level plus floor-plan rectangles, **not semantic corridor progress**. Repeated physical bounds/overlapping instances would confuse it.
- `use_connection` denies non-built targets and checked connections; `AuthoredWorld` builds zone assets and persists objects by IDs. Current code has no inspection roster, semantic route stages, repeat encounter transaction, rollback contract, stable safe-egress event or independent measurement ledger.
- `_run_fade` pauses clock/input, unloads scenes, waits loading and places player. It has no inspection-specific bounded loading deadline, validated target-marker/escort commit, failed-build rollback or inspection state recovery. Reuse successful transition behavior, but do not claim guaranteed safe return from it alone.
- `FirstPersonController.place` clears velocity. Input disable alone is not a safety freeze: normal physics still applies gravity. Destination collision/floor validation and controlled movement release must be part of a future return contract.
- F1 `ChapterDirector` archives chapter-local flags/fired/pending events; `start_chapter` refuses planned modules. SaveManager v3 verifies checksum before sequential migrations/providers. No clinical/system replacement is needed, and no schema bump is made here.

## Proposed deterministic repeated-junction design

**Recommendation for owner review:** bounded authored route, preferably a doorway/fade transition, not recursive portals/infinite geometry or a screen distortion. Reduce-motion uses the same logical outcomes and explicit safe transition. This is an engineering option, not approved supernatural canon.

1. Define one versioned inspection recipe: permitted chapter/zone, named authorized entry anchor/return anchor, roster, authored route states, maximum repeat count (propose one repeat), explicit crossing/measurement actions and exit transitions. Use stable IDs assigned only when approved. Keep content definitions immutable.
2. Use a semantic route state machine: `briefed → authorized → entered → baseline_recorded → junction_observed → measurement_optional → returning → returned → reviewed`, with abort/withdraw exits from every inside state. These are proposed state names, not existing flags. Repeat progress is bounded and the normal safe-exit edge remains available at all times.
3. Crossings are deliberate logical events with ID and sequence ordinal, generated after a debounced directional threshold/explicit action. Do not count every physics frame, volume re-entry jitter, looking around or changing FPS. Same recipe/version, run seed (only if variants approved), prior durable state and accepted ordered input events must yield the same semantic state/evidence IDs. Prefer fixed authored layout initially; if variation is later approved, use local saved PRNG state, never global random calls/render timing/system time.
4. Represent visual repetition with fixed corridor modules in one valid bounded zone, or two isolated finite slots connected by a controlled transition. Reused resources do not mean duplicate logical IDs. Give instances unique persistence keys (`inspection/route segment/instance/object`) and keep logical route IDs independent from render-slot reuse. Avoid overlapping zone bounds and reassigning F2 persistent door IDs to different logical objects.
5. Limit changes to approved geometry/marker state; do not move/delete colliders under players or escorts, swap room contents while visible, or reauthor unrelated canonical door states. A repeat records a presentation/route event, not automatically corroborated supernatural evidence. Label any diagnostic “simulated repeat” telemetry separate from in-world measurements.
6. Team movement is one coordinated transition: roster members either reach validated anchors or the inspection holds/withdraws. No required flawless pathfinding; an explicit regroup/fade may be used after review. No abandoning escort at a streamed-out zone or trusting animation position as access authorization. Naomi's new character rig is not a dependency of this design; any future lab uses clearly labelled stand-ins, never production character claims.

## Guaranteed safe-return acceptance contract (conditional on functioning runtime)

“Guaranteed” must mean a tested route/state invariant and bounded recovery while the game runs, not a promise against process/OS/device failure. Every reachable inside state has a valid return edge to an authored, accessible, collision-checked safe anchor. Return never requires another anomaly, diagnosis, clinical action, chosen hypothesis, a successful measurement or a minimum trust score.

- Preflight entry: explicit inspection authorization, access grant(s), Security AND Facilities roster, operational exit and reserved return destination/asset availability. No Ch1/2 physical WardZero entry; merely owning historic-maintenance access cannot satisfy inspection entry. Represent a formal procedural alternative if optional dialogue is declined.
- Egress is a narrowly scoped safety capability granted with lawful entry. Revoking deeper-entry permission blocks further progression but retains the authorized return route; do not erase security grants globally, unlock arbitrary doors or allow an “emergency return” exploit to enter unopened areas. Suspended/aborted inspections can return without granting narrative completion/evidence.
- Validate recipe graph statically: every inside state reaches return; no cycle without explicit maximum and exit; anchors exist; player/escort clearance and doors permit passage; every failure/timeout edge terminates at safe egress. Verify collision/navigation on actual exported geometry, not only marker names.
- Transactional transition: capture last safe route/zone/player/roster/door state, preflight destination resources/anchors/collision; begin fade and clock/input lock; build/validate placement and team; commit state/event only after success; release every lock/pause on success or failure. Use operation tokens to reject stale callbacks and avoid overlapping transitions. Never blanket-unpause other systems.
- Set bounded loader/team/regroup deadlines; missing resource/marker, script failure or escort stall aborts repetition and offers safe return. Recovery must not wait forever for the same failed load. Proposed fallback is a tiny prevalidated return staging area on the current level or validated prior safe anchor, chosen with environment owner; it cannot rely on unbuilt WardZero geometry or keeping two levels instanced. Staging/fallback is future work, not supplied now.
- Restore player velocity/pose sensibly via the established controller API; hold safe floor/collision during input lock. On failure, cancel pending callbacks, restore non-anomalous route and existing object state without duplicating effects. If safe content itself is absent, fail entry rather than strand player. No forced mouse/camera shake, endless looping, jumpscare or mandatory retreat jump.
- Save/reload at each stage: only persist committed state or a declared recoverable checkpoint. A save request mid-transition must queue/defer safely or serialize a recovery descriptor before atomic state capture; decide policy explicitly. Reload never infers successful measurement from destination appearance. Bad/unknown recipe versions restore the validated return checkpoint with an honest incomplete record, not an unearned corroboration.

## Independent evidence logging and replay proposal

Existing `EvidenceManager` has immutable clue definitions, acquisition `{method, at_minutes}`, manual board links/hypotheses and per-clue verifications `{method, at_minutes}` deduplicated by method string. **It does not prove independence**, store clock calibration/uncertainty or provide an append-only inspection event log. Two different method names do not establish independent instruments. An event recording the game effect is operational telemetry, not in-world evidence that proves the effect's premise.

Proposed inspection records (schema names/IDs pending review):

| Record | Required data and boundary |
|---|---|
| Inspection session | Stable session/recipe/version/chapter/zone, lawful purpose/access reference, Security/Facilities roster, entry/return safe anchors, run seed only if used; no patient symptom inputs |
| Observation/source artifact | Immutable record/source ID, source class/device/document author, source creation timestamp/timezone plus acquisition game-time/sequence separately, raw value/text/units, position/reference-frame/calibration and uncertainty, collector/authority/custody, optional content hash |
| Source lineage | Capture system/original ID, export lineage, shared clock/calibration/equipment chain; separately captured copies of one source remain dependent. Staff statements identify speaker/time and remain testimony |
| Claim/hypothesis | Observation IDs, explicitly stated interpretation/alternatives, disputed/unknown/retracted status, reviewer and rationale; allegations routed separately with recipient/process, no automatic guilt or diagnosis |
| Action/event | Event ID/session/sequence, type, actor, causal references, before/after semantic state, completion vs abort and logical time. Never use a wall-clock timestamp as sole identity |
| Review | Which sources actually independently support a particular claim, controls performed/missing, limits, corrected interpretation and approved outcome; never automatically “supernatural confirmed” from repetition count |

Illustrative source families: authorized access-control raw log, original facilities work order/route plan, independently operated measurement device/reference marker and archived source document. EHR exports may be relevant administrative artifacts but never convert clinical notes/symptoms into paranormal proof. A security camera and its export share lineage; synchronized devices can share a clock fault. Review independence per claim, not merely “two files/two witnesses.” No fictional physics/clinical threshold is approved here.

Retain original observations/corrections as separate records; do not edit an earlier timestamp or destroy source to reconcile discrepancies. Optional hashes identify exact bytes and detect accidental mismatch; they are not a signature proving authenticity or independent scientific validity. Evidence access/collection must remain authorized, confidential and purpose-limited. Patient documents require consent/authority and an alternative mandatory route; investigation records must not absorb private care narratives. No diagnosis/rapport/personality/medication/Bleed values read by inspection condition evaluation.

**Replay has three distinct meanings:**

- Resume a saved inspection: restore committed state once, suppress already-applied events by session+event ID and restore same remaining route. No duplicate clue, grant, audio notification or verification.
- Re-run an inspection deliberately: create a new session referencing the prior attempt; same inputs recipe produce same route, but new measurements remain separately identified and must not count as independence solely because the run number changed. Preconditions/clearance/coverage still apply.
- Review/playback: render a read-only event timeline/recorded observations; do not acquire clues, emit runtime scene effects, grant access or apply clinical actions. A reconstruction must be visibly labelled; it cannot overwrite original sensor/document evidence.

Proposed event reducer is pure and deterministic, effect adapters consume committed events idempotently via EventBus. No new autoload/provider yet. Assess whether an inspection provider and migration are necessary after approved schema: v3→new version only in a bounded reviewed PR; existing v1/v2/v3 compatibility/checksum-first behavior preserved. Providers currently restore sequentially by key, so cross-provider restore/effect replay needs an explicit post-load reconciliation contract, not a claim of existing atomic restore. Interrupted replay must converge on last committed safe checkpoint without silently erasing audit events.

## 8GB Apple Silicon performance and accessibility

Retain F2 level isolation. Bound residency to current inspection module, required neighbour and small return resource; reuse shared meshes/materials; do not keep modern hospital/research/WardZero levels instantiated simultaneously. Two render slots are a maximum option, not permission to spawn a full extra hospital. No recursive Viewport portals, live multi-camera feeds, dynamic reflections or physics cloth required for a repeated-looking junction. Use reviewed static captures/textual records when compatible with approved fiction; simulation/render captures alone do not become independent sources.

Provisional targets: baseline30fps floor/33.3ms sustained, aim60fps at documented render scale; inspection incremental GPU≤2ms/CPU≤1ms and resident-memory delta≤128MiB as initial lab targets. Whole-game process target≤3GiB, investigate >4GiB and OS pressure/swap; measure shared CPU/GPU accounting rather than double-counting. These are proposed, not achieved. Keep evidence event payload bounded to references/compact readings, not raw video arrays in JSON saves. Profile both one/two-module cases, observers, worst shadows and rollback/load peaks.

Use existing `perf_log`/`sample_performance` for coarse memory/frame samples plus actual Mac Godot/Instruments traces, p50/p95/p99 frame and load times, memory pressure, source readback stalls and20 enter/return cycles; 15–30minute thermal test. Headless uses main-thread resource loading, so it cannot validate threaded Metal safety/performance. Text alternative for every discrepancy/measurement, captions, reduce-motion fade, explicit exit indication and no audio-only clue. Reduced presentation changes no logical observations/evidence eligibility. Safe return/decline must be reachable with standard controls and no timed dexterity check.

## Owner decisions and small PR sequence

| Gate | Exact decision needed |
|---|---|
| Narrative N1 | Supply/review exact expanded Ch2/3 scripts and branches; which generic package scenes remain/reorder? Rahman's Ch2 consult addition and care coverage require review |
| Narrative N2 | Is Ch3 repeated junction ambiguous route recognition, controlled repeatable navigation discrepancy, or independently established impossible geometry? Preserve/defer Ch4 major reveal accordingly |
| Safety N3 | Approve bounded repeat count (recommend1), visible return/regroup controls, escort/authorization prerequisites and entry/withdraw/resume semantics |
| Evidence N4 | Approve exact artifacts, measurement/control limits, clock lineage, claim-specific independence and allowed outcome vocabulary; F3/C6/C7 governance remains separate |
| Production N5 | Approve inspection module/anchors/fallback, D4 history/D7 layout and environment ownership; no Stage6 replacement by proposal |
| Persistence N6 | Decide mid-transition save policy, replay/new-session/read-only semantics and schema/provider/migration boundary after content approval |

1. **This docs-only PR:** summary crosswalk, approved-entry boundary and engineering/test requirements. No scripted effects, rules, new IDs/data or scene edits.
2. **Independent safety-contract PR after N3:** pure recipe/route-graph validator and recovery/state contract with synthetic non-anomaly test fixtures, disabled/inert integration. Explicit owner approval of that bounded scope first; no F3 semantics hidden in tests.
3. **Non-supernatural authorized route lab after production review:** existing F2 semantics, validated entry/return anchors and failure/timeout behavior using labelled lab geometry. Do not call it WardZero production or alter hospital scenes yet.
4. **Independent source/event contract after N4/N6:** versioned durable events and read-only timeline, idempotency/recovery/migration tests, disabled authored anomalies; coordinate EvidenceManager/EventBus ownership.
5. **Reviewed Ch2 content slices:** institutional branches and independent-source/clinical routes, only clinically approved patient-facing content. Ch2 still planned until accepted module ready.
6. **Reviewed Ch3 entry/measurement slice:** approved source/script/module integration; entry is first actual WardZero visit. Add proposed repeat presentation only after exact N2/N3 approval and disabled-to-enabled review. Do not enable full F3 on this premise.
7. **Mac/clinical/accessibility acceptance**, then later chapters independently. Naomi remains separate PR31; no models/assets/audio timing adapter are prerequisites of this documentation.

Future tests: static graph reachability for every state/failure; same semantic inputs across frame rates/unload/reload give identical state/events; zero/one/bounded repeat; crossing jitter/backtracking; denied entry Ch1/2/missing access/roster; lawful egress after permission change; missing file/marker/invalid collision/timeout/escort stall returns safely; lock/pause cleanup; save/reload before/during/after transition; old-save migration and unknown recipe recovery; duplicate/stale/replayed events cannot duplicate effects; “two exports” not independent; no patient/clinical/personality/Bleed mutation or condition, plus clinical-state unchanged by route events; declined Mara disclosure and all personality/background paths retain essential evidence/care access; reduce-motion outcome parity; no off-level residency/leaks over20cycles. These tests are proposed, **not executed** by this docs task.

## Validation at this checkpoint

Source/code comparison and runtime/package preservation checks only establish this proposal's grounding. Standard Godot4.7 QA on identical application bytes from inspection checkpoint8e30681 through final docs passed exit0: Python6+3+3, pharmacology0 failures, QA19/0/0, GLB138/138, gameplay131/0, boot OK, audio334/0, Chapter1 sequence61.0s. Command `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`; local log `/tmp/forensic-inspection-spec-qa.log`. Whitespace, package/runtime preservation and resolved-conflict checks passed. Prior latest run on the separate Naomi branch had gameplay131/0 and audio333/1 cinematic-resume timing assertion; reduced probe passed, cause unconfirmed. No audio/test patch is bundled here. Actual repeated-corridor behavior, safety invariants, independence engine and Mac performance are unimplemented/unvalidated. No new clinical approval granted.

## Revised manuscript availability — 2026-10-17

V2 five-file package now available on main1dbd26a. Earlier missing-text statements describe the preceding checkpoint. Actual line-reference review is in [REVISED_SCREENPLAYS_V2_TECHNICAL_REVIEW.md](REVISED_SCREENPLAYS_V2_TECHNICAL_REVIEW.md). In particular Ch3 explicitly prohibits dynamic substitution/teleportation; earlier repeated-presentation options here are future Ch4 proposals, not Ch3 implementation instructions. Source documents preserved.
