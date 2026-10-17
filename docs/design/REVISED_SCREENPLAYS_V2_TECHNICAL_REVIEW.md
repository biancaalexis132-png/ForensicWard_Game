# Revised screenplays v2 — line-referenced technical and continuity review

2026-10-17 · Documentation review only. No implementation, clinical approval or automatic merge.

## Verified input and reading method

All five files reviewed from main **1dbd26a96288d7947ebd6a90b151ba1f6a0fc2a6**, “Add revised Chapter2–4 screenplay and inspection contract.” Requested `docs/revised-screenplays-v2` branch was not present; main supplies the package. Review branch `codex/revised-screenplays-v2-review` includes screenplay integration base **ca7488980be3dd4d065810ae2f75cc6741727906** (owner merged PR32; earlier PR31 also merged there), then ordinary main merge. Main's new commit adds only five documents; it does not merge the preceding feature architecture/canon proposals into main or change runtime data.

Tables below group consecutive source lines forming one speech/action/requirement; line ranges refer to the exact v2 files at that commit, not invented production IDs. Blank lines/headings carry no runtime effect. Compared earlier PR30 manuscripts scene-by-scene, F2 source, F1 campaign, pending flags and owner canon. **Existing support** means verified code/data, **new** means unimplemented, **review** means owner narrative/clinical/design decision still needed. Draft labels are never silently treated as API signatures.

Paths below are relative to `docs/design/screenplays/ForensicWard_Revised_Screenplays_v2/`, unless qualified.

## README, lines1–20

Lines1–9 correctly describe addenda alongside, not replacement of, original manuscripts. Lines11–13 separate established canon from new dialogue/clinical/geometry/timeline decisions. Lines15–17 resolve the earlier treatment's reveal ambiguity: Ch3 ordinary explanations remain viable, Ch4 scene09 is proposed major loop with safety/evidence gate. This is a coherent **draft revision**, not approval of the whole reveal. Lines19–20 require comparison and implementation review, both honored here. No missing file within the five-file package; no manifest supplied, so source commit identifies bytes.

## Chapter2 line comparison

Source: `chapters/CH02_EXPANDED_SCENES_v2.md`.

| Lines / exact content | Earlier manuscript / current systems | Finding, required change and review |
|---|---|---|
| 1–4 revision/source claim | Original Ch2 ten-scene treatment | Appropriate proposed expansion. “Pre-existing dossier” is a provenance assertion, not supplied original clinical documentation or approval |
| 6–15 station routine/overnight review | Original scene01; Ch1 Bennett staff interaction and EHR exist | Dialogue/context expansion, not new findings. Actual overnight reports/coverage tasks and branch completion need authored data. Reviewing summary cannot count as an examination |
| 17 haunted-computer joke; 19 exit | Original grounded opening, no effect | Narrative tone review; joke is not evidence or a cue. “Reviewed or assigned appropriately” needs exact safe follow-up/completion contract rather than universal bypass |
| 21–32 log comparison | Original scene02 four-minute gap; EvidenceManager acquisition supports provenance string/time only | More precise clock-offset/sort alternatives. Need source artifacts, raw offsets/export versions, request authorization and unresolved outcome. `reported` is proposed claim state, not current hypothesis status |
| **34–35 Mara provisional dossier** | Owner supplied age37, prior records work, disputed mood label, fatigue/insomnia/anxiety/checking, Dana, Lillian Oct12/14 1988; Mara absent from `data/patients.json` | New supplied draft now includes **4–5h sleep, bipolar-spectrum specificity, organized speech/thought, historical passive death wishes, current SI/HI denial, medication/legal details**. Preserve as pending source claims, not current established findings. Compare original dossier when supplied. No automatic patient schema entry, diagnosis or risk finding |
| 37–46 first contact/three approaches | Original scene03 unnamed patient; owner approves Mara Ch2/agency | Role-clarification and non-morality branches fit requirements; exact dialogue pending. Need responses/next states with all essential assessments accessible |
| 48–58 places copies/paper vs archive origin/alternatives | Original general document discussion | **Paper-source vs later archive copy is newly specified**; needs document-source review, custody and consent. Current script assumes sharing in every branch; add voluntary decline/partial sharing/withdrawal routes and independent mandatory source access. Do not invent aunt's event or resolve correct date |
| 60–64 sleep module | No Mara interview authored | Clinical review: actual patient-reported sleep/functional facts, no symptom/diagnosis inference from 4–5h alone. Do not turn explanation into automated mania exclusion rule |
| 66–74 mood/alternatives | Main no Mara medical logic | Appropriately provisional; exact history/source/clinical wording pending. “Acknowledges alternatives” not automatic absence of delusion or capacity finding; branch must not diagnose by agreeing with records |
| **76–79 safety question/answer** | Existing clinical gates pending | Broad question asks suicide/self-harm/others; answer says hopeless in past/no self-harm now. **L35 says current SI/HI denial, but L79 correctly forbids inferred HI negatives. Reconcile summary and interview**; do not substitute hopelessness for a documented passive-death-wish history. Complete risk formulation remains source/clinician reviewed |
| 81–85 Dana collateral | Prior crosswalk names sister only | New claimed source content (late-night checking/worry/fatigue/older activity) must retain actual source/time/authority. No call/contact on dialogue consent assumption; do not prepopulate collateral not obtained in this encounter |
| 87–92 clinical/document distinction and follow-up | EHR note/actions available, no Mara case | Good separation; approve exact care plan/medication reconciliation/legal role independently. “Records differ” can confirm a narrow fact without endorsing all interpretations. No treatment effects from document findings |
| 94–101 Voss | Original scene04; main Voss info interaction | Credible safety/confidentiality/accountability direction retained. Inactive credential does not identify user; do not convert allegation into fact. Need distinct incident owners, follow-up branches, actual administrative artifact source and review |
| 103–110 analyst | Original scene05 | New tests of clock skew/export/migration must have authored results and limits, not auto-success; neutral review path available across personalities |
| 112–117 Hale | Original scene06; TrustManager grants/F2 permissions | Correct role and separate clinical/security systems; no solo access. Need authorized reports/requests separate from physical-entry entitlement; no trust-to-badge shortcut |
| 119–126 witness | Original scene07 | Explicitly heard bell, saw no entry; this is testimony only, not movement proof. Store source/scope and do not infer reliability from clinical symptoms |
| 128–134 lobby/ajar door | Original scene08 ambiguous door | Clarifies Ch2 stays outside WardZero. Ordinary scene action/door-state handling possible, but exact observation, missing continuous watch and mechanical checks need authored records. No teleport/loop |
| 136–142 exports/incident | Original scene09 | Two representations may share lineage: cannot call independent by file count. Separate confidential clinical note from incident record; current evidence method strings insufficient |
| 144–158 closing/callback/evidence cap | Original scene10; P1 only pure draft validator, not creator/save provider | Proposed personal callback has no runtime durable-contact system. No-contact fallback required; don't expand P1 into persistence implicitly. Clear Ch2 cap excludes proven time alteration/supernatural evidence; exact report and staff lines need review |

### Mara clinical review status

The manuscript supplies more proposed details than earlier owner anchor messages; availability does not imply explicit clinical sign-off. Keep prior facts as source claims, preserve uncertainty/legal questions and distinguish patient report, collateral and examination. A headline describing organized thought or denial cannot become an encounter finding before the corresponding assessment. Do not erase these draft details or mark them approved; flag exact lines35/63/78/85/92 for source reconciliation and clinical review. Existing draft claim of HI denial conflicts internally; current runtime has no Mara record to “fix.”

## Chapter3 line comparison

Source: `chapters/CH03_AUTHORIZED_INSPECTION_v2.md`.

| Lines | Old manuscript / implemented capability | Technical/content assessment |
|---|---|---|
| 1–5 boundary | Old Ch3 ambiguous reflection/object claims and Ch4 scene09 loop | Resolves reveal conflict in text: Ch3 no topology/geometry changes. Keep exact proposed claim vocabulary under review; typo `independently_corroborrated_spatial_loop` is not a registered ID. Earlier F0 proposed Ch3 corroboration ladder must be reconciled per claim, not assumed to corroborate loops |
| 7–14 coverage/liaison | Old scene01 inspection; no coverage/roster model | New briefing dialogue/role scope, clinical task ownership and completion data required. A **procedural coverage state** can be a safety entry prerequisite; never read a patient's diagnosis/clinical score as anomaly trigger |
| 16–24 briefing | Old scene01; access grant check exists | Authorization/hazard/roster/communications/return route new. Named Facilities engineer remains unspecified; do not invent identity. Current badge access alone cannot implement these prerequisites |
| 26–31 service elevator | Old scene02 stairwell; current lift goes security↔research, hatch to historic | **Transport change requires environment owner/connection review.** No WardZero lift endpoint exists; reusing research lift as this service route would alter established connectivity. Coordinate target/marker/access/return route; no F2 rebuild needed |
| 33–40 threshold/W0-B | Old scenes02–03; WardZero placeholder | First Ch3 authorized physical entry fits approved premise; exact sign/code equivalence still draft (“archival plan says so”). Need real zone content/bounds/entry markers/permissions and source plan; don't equate Ch1 sealed W0-B door/log with a newly accessible room automatically |
| 42–49 alcove vs plan | No such source-specific interaction | Static landmark and different plan edition are sufficient; **no moving alcove required**. Need actual plan/reference points, observation/uncertainty and text equivalent, reviewed authoring |
| 51–58 lookalike junction | Prior Ch3 scene07 reflection, Ch4 scene09 true loop | **No repeated-corridor effect in Ch3**: static distinct similar markers, ambiguous notes, continuous return route. Requirement supersedes earlier engineering option for a Ch3 repeated presentation; retain finite-graph safety design for future approved Ch4 only |
| 60–66 control check/pause | F2 pauses only during transition | Roster/dispatch/route-check holding state missing; no automatic loss of normal exit. `inspection_paused_for_route_check` maps to a proposed lifecycle reason, not new parallel boolean. Unvalidated route invokes abort, not exploration |
| 68–74 safe return | Old scene10 safe stairwell exit; current F2 normal transition only | Party reconciliation, suspended deeper access, marker/collision validation and bounded abort/recovery new. Returning is not evidence confirmation. Do not globally revoke egress permission |
| 76–82 debrief | Old scene10 careful report | Separate observer memory/photos/map versions/access source lineage. Review workflow missing; two staff repeating same account does not establish impossible loop |
| 84–91 care return/Mara | Old scene05 Rahman care consult | Need care/case/coverage content and pending review; no automatic Mara sharing or mystery-derived treatment. Bennett's “wait for safe handoff” is proposed narrative, not medical urgency rule |
| 93–99 survey request | Old work orders scene08 | Restriction remains; **this is a request, not permission for a second entry**. Define actual control protocol. “Two ... observations ... cannot be reconciled” is not a complete proof criterion/independence gate |
| 101–108 preliminary measurements | Old scene10 inventory mismatch | Explicit unequal conditions/unproven independence, no impossible dimension. Define actual readings/units/frame/uncertainty; `unresolved_measurement` proposed label only. Do not fill numbers from imagination |
| 110–121 report/photograph | Old scene09 duplicated file; no notification | Adds pending independent review, plan/lens/position uncertainty and ordinary close. Need source image/artifact/notice and role-limited access; don't count image rendering as independently acquired sensor proof |
| 123–130 proposed saved state | F1 chapter archive, no inspection provider | First-entry flag **after actual commit**, safely-returned only with team/anchor validation; route uncertainty/unverified independence not claim corroboration. “loop_revealed=false” needs default/missing semantics, no resetting a historical Ch4 flag on later Ch3 revisit. Persist by chapter/session, no unregistered globals |

Old Ch3 scene03 W3 station,04 wheelchair,05 Rahman consultation,06 unsigned ledger,07 reflection,08 work orders,09 duplicated file and10 inventory mismatch do not map one-to-one to v2's fourteen scenes. Addenda do not themselves delete these. Owner needs an explicit retention/reorder/defer decision, especially for wheelchair/reflection escalation, W3/D7 and historical ledger/D4. New draft scene numbers must not be reused as existing production event IDs.

## Chapter4 line comparison

Source: `chapters/CH04_OFFICIAL_RECORD_v2.md`.

| Lines | Earlier draft | Required work/review |
|---|---|---|
| 1–4 premise | Old major loop scene09 retained | Clear placement; exact execution still approval-gated. Genuine world mystery does not prescribe proof thresholds/mechanism |
| 6–15 separate incident files | Old scene01 review | Author report custody/authority and safety review; no automatic causal link between credential incident and spatial survey |
| 17–23 wrong summary/editor | Old scene02 testimony | **New record-correction UI/branch**, not replacement by default. Original/wrong/revised versions remain immutable linked artifacts; “well-supported final finding” needs exact reviewed eligibility, not personality morality score |
| 25–30 Rahman | Old scene03 independently confirmed wheelchair | New scene; don't silently remove wheelchair branch. Appropriate clinical separation, exact dialogue pending; no psychiatric assessment standards coded from two lines |
| 32–40 Mara | Old scene04 Voss disclosure conflict | New independent care follow-up requires clinical review/source and no mandatory document access. Fact of date difference must have actual authorized review; unshared/private patient source not exported |
| 42–48 chronology | Old scene05 time-order contradiction | Independence described, not assumed; exact raw originals/known clock/export checks and remaining contradiction missing. No auto proof or source deletion |
| 50–51 personal callback | Old scene06 | Preserve optional/no-contact path; durable contacts not implemented; no forced family/romance |
| 53–58 door replication | Old scene07 claimed corroborated door contradiction | **Downgrades old certainty** to attempted replication/unresolved entry evidence. Align existing proposed evidence ladder/artifacts when reviewed; same script firing twice never independent |
| 60–67 institutional disagreement | Old scene08 | Safe access plus care continuity; allow dissent without blocking mandatory notices. Staff authority/clinical content remain bounded |
| 69–74 controlled repeat | Old scene09 linear repeat/defect | Requires new deterministic bounded route/presentation, explicitly approved geometry/timing and safe-return infrastructure. “Matching defect” alone does not exclude duplicated damage/signs; exact independent route/access evidence and control criteria need source authoring |
| 76–82 stop/radio/options/hard guards | Old exit-after-second-pass guard | Improves immediate-exit and bounded replay contract. Options cannot gate return. Freeze subsequent mutations on abort; no late callback reshuffle. `observed_repetition_unverified` and misspelled `independently_corroborrated` are proposed labels, not existing statuses. Missing independence means no promotion |
| 84–94 review/ending bridge | Old scene10 report; old ending bible proposed | Safe exit separate from independent evidence gate; no claim of mechanism in charts. **L91 says Ch5 “retains” prior pathways, but the ending bible remains proposed**—not new approval of exclusive outcomes/thresholds. Claims of “reproducible” require a second protocol/run definition without endlessly replaying the dramatic effect |

## Technical contract: requirement-by-requirement mapping

Source: `production/F2_F3_INSPECTION_AND_EVIDENCE_CONTRACT.md`.

| Lines | Existing support | New contract details/required tests/approval |
|---|---|---|
| 1–7 scope/caps | Campaign Ch1 playable only; others planned; no F3 runtime | Keep Ch2 no-entry, Ch3 no-geometry, Ch4 pending effect separation; validate per-chapter allowed transitions/claims without auto enabling F3 |
| 9–11 lifecycle | No inspection machine | Need transition table/event inputs/guards/invariants. Is PAUSED mandatory on normal route? Define normal RETURNED vs RETURNED_SAFE distinction, terminal/reopen/new-session behavior, rejection of illegal edges, recovery-failure deadline. Names are proposals |
| 13 preflight | `ZoneDirector.use_connection` checks access+built target | Add actual authorization/roster/coverage/communications/hazard/return validation; badge/trust not substitutes. Checkpoint write failure blocks entry or uses reviewed alternative, never ignored. Persist completion before proceeding |
| 15 stop conditions | `in_transition` prevents overlapping F2 requests | New idempotent stop token/timeout/escort/communication event; stop cancels pending effect mutations, retains egress and makes progress to validated safe state independent of FPS. Timeout bounded monotonic elapsed **fault detection** may be useful; semantic results/order must not depend on frame count |
| 17 postconditions | F2 successful placement/restores input/clock; object state storage | Validate whole roster/zone/collision/interaction/pause-owner cleanup, no duplicated staff/doors/events; unchanged clinical data means no mutation caused by inspection. Don't roll back legitimate care changes made elsewhere during elapsed time |
| 20 snapshot | F2 `{current, objects}` plus world/player provider | No portal IDs/system exists. Version snapshot with recipe/session/logical stage/object namespaces/anchor validation; loaded IDs alone cannot recreate safe physics/assets. Scope snapshot, reject invalid/missing data and no whole-SaveManager reset to “undo inspection” |
| 21 rollback scope | Providers separate | Apply only owned transient changes, not entire zone object dictionary if unrelated valid actions occurred after snapshot. Store mutation ownership/deltas and preserve clinical/campaign records/source observations; tests for concurrent durable changes |
| 22 two exits/bounded attempt | Start-zone fallback for unbuilt saved target only | Must supply verified modern marker AND tiny safe recovery scene/resources, bounded first attempt and fallback. A GLB on the same disconnected drive cannot be the sole fallback. No persistent simultaneous levels to guarantee exit; resource availability preflight and load-failure coverage required |
| 23 idempotency | Clue once-per-ID, verification once-per-method, chapter beat fired tracking | No transactional inspection/session/event identity. Add stable command/event IDs, sequence/order, duplicates/stale async callbacks, retry/reentry semantics; do not grant duplicate trust/evidence |
| **24 crash/reload** | SaveManager already writes a temporary file then renames it and verifies checksums; providers restore sorted, then game_loaded; no special inspection phase | Resolve tension with durable completed source observations atL25. **Do not restore whole pre-entry save and erase valid later notes/evidence**. Propose current durable provider state plus inspection interruption journal/safe checkpoint; a real crash before persistence cannot preserve unsaved data by promise. Define atomic write/commit policy, latest-state selection and honest interruption notice |
| 25 evidence preservation | Existing acquisition time/method only | Need committed observation/event payload and correct audit of aborted/unobserved actions. Never fabricate a “witnessed” result during reconstruction |
| 27–28 independence | Existing verifications dedup method string, no lineage checks | New directed lineage/custody/capture/time-authority model; same raw source/clock faults/capture pipeline remain dependent even across exports. Detect cycles/missing ancestry; independence is claim/control-specific, not an asset hash or enum |
| 30 fields | Clue definitions/acquisitions/manual hypotheses | Need raw timestamp separate from collection/simulation time, clock offset/uncertainty, units/reference frame/calibration for measurement, explicit schema versions, session/source/raw artifact IDs, access/reviewer and correction links. New `scope`/`confidence` need semantics, not arbitrary score. `clinical_record_link=none` supports separation; don't make sensitive note replication a hidden pointer |
| 32 statuses | `ContentSchemas.HYPOTHESIS_STATUSES` only unresolved/supported/refuted | Keep hypothesis status separate from source authenticity and claim corroboration. Define transitions/reviewer/retraction/correction; verified_source != physically impossible. Reconcile spelling/vocabulary with chapter labels and F0 proposed ladder before authoring |
| 34 clinical separation | ClinicalRules pending-effect gate, PatientManager/EvidenceManager separate | Validate both directions: clinical state cannot trigger/promote anomaly; inspection cannot alter medical state/clinical approvals. Coverage is procedural duty, not patient pathology. All Mara disclosure/rapport paths need independent essential sources |
| 36–48 test list | Existing full runner and F2/save/evidence tests, no inspection engine | Test-by-test plan below; these tests have not run merely because written. Hardware/clinical validation distinct from headless acceptance |
| 50–57 PR sequence/warnings | Existing branches, no automatic merge | Correct order; refine tests/architecture PR into pure contracts then actual F2 failure injection. Mocked zones alone cannot demonstrate real loading/egress; owner reviews scope before runtime changes |

### Code anchors supporting that mapping

- `scripts/world/ZoneDirector.gd:149` access+built target, `:166` transition/input/clock, `:180` unload before destination build, `:184` no bounded inspection wait/fallback, `:191` placement, `:405` saved zones state, `:414` direct load/start-zone fallback. No inspection rollback/party state.
- `scripts/player/FirstPersonController.gd:47` place resets velocity; input disabled alone does not stop gravity. Validate floor/collision before unlock.
- `scripts/autoload/EvidenceManager.gd:162` verification query, `:167` add_verification/once-per-method; no typed capture lineage/clock independence. Board-supported hypothesis means an argument can be made, not factual truth.
- `scripts/autoload/SaveManager.gd:19` v3, `:122` checksum before migrations, `:134` sequential provider restoration. Existing `save_game` uses temp-file/rename; reuse it rather than replacing its file-write safety. No new provider/migration or durable inspection journal added by package. Cross-provider restore needs review; game_loaded is not already an atomic inspection transaction.
- `scripts/narrative/ChapterDirector.gd:139` refuses planned modules, stores per-chapter archives. `data/campaign.json` only Ch1 story/world/dialogue; Ch2–5 planned. `data/zones.json` WardZero empty placeholder; existing lift research/hatch historic, not new service elevator/inspection entry.

## Acceptance tests mapped to contract list

| Contract item | Required test / method |
|---|---|
| 1 preflight | Table-driven each missing/invalid permission, roster member, coverage, exit, communications and failed checkpoint; zero entry/effects and honest failure |
| 2 normal route | Real F2 import/load/collision/markers+team, approved route and save/restore in Godot; actual8GB Mac input/frame/memory check, not mocks alone |
| 3 all abort stages | Enumerate every reachable state, partial transition and pause; bounded safe egress, no remaining mutation/clock/input lock, including double stop/failed first rollback |
| 4 failure/reload | Inject unavailable/bad GLB, missing marker/floor, load error/hang, drive unavailability, journal/save write failure and interrupted restore; prevalidated fallback independent of failed content, preserve durable noninspection state |
| 5 reentry | Same command retry dedup, new inspection session with renewed clearance, no duplicated evidence/trust/staff/doors; late callbacks rejected |
| 6 effects off | Ch3 ordinary static observation/return/report progression fully works without any loop or F3 state; clinical work and mandatory sources accessible |
| 7 chapter cap | Ch3 cannot mutate geometry or set Ch4 loop/corroborated-loop flag; revisiting/restoring Ch3 cannot erase recorded Ch4 history |
| 8 source independence | Same raw stream→two displays/exports fails; distinct capture alone insufficient if shared error invalidates claim; test lineage cycles, unknown clock/frame/units, original corrections, claim-specific approved positive control |
| 9 clinical invariant | Compare PatientManager/ClinicalRules output/flags before/after effect/failure/replay under identical care inputs; clinical events/personality/medication/Bleed leave anomaly state unchanged; no suppressing valid concurrent care |
| 10 accessibilities | Text/captions/reduce-motion/explicit stop parity, no audio-only/colour-only essential evidence; no timed dexterity exit; no-contact/Mara-decline/low-rapport branch routes |
| 11 determinism | Same recipe/version/input-event ordering and saved local seed if needed across FPS/tick scheduling/reload yield identical semantic events/state; physics drift not used as evidence truth |
| 12 profiling | Baseline/normal/abort/fallback/stress,20 return cycles and sustained15–30minute thermal capture on8GB Mac; draw/texture/load peak and process/OS pressure recorded |

Test outcomes for these **new** systems: not implemented/not run. Existing regression results only appear in validation record below. No claim of mathematically/operationally guaranteed exit until graph invariants, real engine failure cases and target hardware pass.

## Owner decisions and recommended small PRs

1. **R0 this review:** preserve both packages byte-for-byte, review exact line findings. No new clinical findings/canon changes inferred from merge.
2. **R1 pure safety/inspection contracts after bounded approval:** resolve state table (normal/abort/pause), static physically continuous Ch3 route, entry/roster/coverage/access semantics and save/crash policy. Pure deterministic reducer/route/recovery graph validators with synthetic non-anomaly fixtures; no registered provider or hospital geometry change. Review acceptance before claiming safety proven.
3. **R2 F2 non-supernatural recovery lab after scope approval:** verified anchors/party placement, bounded failures, pause/input ownership and rescue content with real loading fault injection. Coordinate environment/scene owners; no repeat geometry. Retain F1/F2 architecture, no blanket rewrite.
4. **R3 independent source/claim schema and validator:** lineage/clock/custody/calibration/status semantics, rejected duplicate sources and explicit reviewed positive-control fixtures. No promotion from script output. Inert runtime/no medical integration first; actual provenance adapter and read-only review next.
5. **R4 persistence/replay integration:** approved journal/checkpoint/current-state policy, once-only events, pure read-only reconstruction vs new authorized run, reviewed migrations preserving v1/v2/v3 checksum-first behavior. Do not bump version solely for docs; if durable schema changes, provide explicit migration/default/unknown-version tests. R2+R3+R4 must pass before effects.
6. **R5 reviewed Ch2 then Ch3 content slices:** narrative approvals, full Mara source/clinical review, no forced document sharing, transport/threshold/geometry and old-scene disposition decided. Keep later chapter slots planned until real accepted modules exist; approved entry premise not enough to mark them playable.
7. **R6 Chapter4 effect only after explicit owner approval:** exact bounded loop/independence controls/safe return and reveal flags; prerequisites R2–R4 passed on real engine/Mac, Ch3 parity tests. No major effect implemented from this request.

Unresolved concrete decisions: Mara lines35/79 HI/history/clinical specifics and original-source authority; voluntary disclosure/fallback; retained/deferred old Ch3 W3/wheelchair/reflection/ledger and old Ch4 testimony/wheelchair/Voss scenes; new elevator/threshold/code relationship and Facilities role/casting; normal/abort state semantics, crash journal vs checkpoint, independent fallback resources, lawful egress after revocation; source/claim status vocabulary/independence control protocol; exact geometry/timing of Ch4 and whether reproducibility requires multiple survey attempts; Ch5 ending selection/precedence still draft. D4–D9/F0 C2/C6/C7 remain unresolved unless separately explicitly approved. Do not ask again for Mara placement/agency or Ch3 authorized first entry; already approved.

Naomi production remains separately reviewed in `CHARACTER_PRODUCTION_NAOMI_FIRST.md`, owner-merged PR31 into screenplay base. No new model work/appearance/asset acquisition is authorized here. Inspection contract can be validated with explicit test stand-ins; these are not production humanoids.

## Validation and limits

All five v2 files read including every dialogue/action/contract line; earlier manuscript scenes compared as above. Runtime and original package unchanged by this review; current main's new commit is docs-only. Current standard QA on application bytes identical to checkpoint84257e2 **passed exit0**: `python3 tests/qa/run.py --godot /workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64`; Python6+3+3, pharmacology0 failures, QA19/0/0, GLB138/138, gameplay131/0, boot OK, audio334/0 and full Chapter1 sequence62.2s. Local log `/tmp/forensic-revised-v2-qa.log`; whitespace/package/runtime-preservation checks passed. New safety/replay/independence systems and Mac performance are not implemented or validated. Hosted CI must be observed before claiming its result. Prior intermittent audio fixed-timer failure remains historical even if current runner passes. No new clinical approval granted.
