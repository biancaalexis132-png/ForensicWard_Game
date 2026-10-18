# Chapter 3 — Beneath the Hospital: Authorized Inspection and Verification
**Draft v2 | Owner-approved first entry premise; new events and dialogue proposed.**

## Non-negotiable continuity boundary
In the older merged screenplay, the **major self-repeating corridor reveal belongs to Chapter 4 Scene 09**. This revision must NOT preempt it. Chapter 3 may show a confusing route, similar landmarks, questionable signs, conflicting plans and inconsistent preliminary measurements, but ordinary explanations remain viable. There is NO demonstrated topological loop, no confirmed changed geometry, no inescapable maze. Observations remain `reported`, `disputed`, or `unresolved`, not `independently_corroborrated_spatial_loop`.

## Scene 01 — Authorization
Morning clinical station; Bennett hands the protagonist an inspection notice for the historic-access discrepancy. Hale and Facilities will lead, and the psychiatrist attends as clinical liaison regarding the transfer workflow. Active clinical needs receive coverage before departure.

**BENNETT:** You've got an inspection briefing. Apparently your day job now includes reading old floor plans.
**PLAYER:** Only the part related to clinical transfers.
**BENNETT:** Good. We'd hate to lose another psychiatrist to Facilities.

Choice priorities: confirm clinical coverage; read audit summary; clarify clinical scope. Each required item is completed before departure.

## Scene 02 — Security briefing
Hale points to current and historic maps. A Facilities engineer reviews approved areas, communications and stop conditions.

**HALE:** This is an authorized inspection, not a tour. Nobody enters alone; nobody opens an uncleared door.
**ENGINEER:** The old drawings weren't consistently revised. We'll establish what exists before we draw conclusions.
**PLAYER:** What is the specific clinical question?
**HALE:** Whether an obsolete code is still being routed through patient-transfer software. The building survey is ours.

The player reviews boundaries and a planned return route. **No access if clinical coverage, entry approval or life-safety assessment is missing.**

## Scene 03 — Descent
Normal service elevator. Motor noise, administrative labels and maintenance inspections; no ominous soundtrack.

**ENGINEER:** Renovations changed the levels. The old plan's 'ground' isn't our current ground.
**PLAYER:** So the drawing might differ without anything being wrong.
**ENGINEER:** Exactly.

## Scene 04 — First actual entry into Ward Zero
Following Facilities clearance, Hale opens the authorized historical threshold. Heavy doorframes, faded institutional paint, empty fixtures; no gore, occult symbols or patient demonization.

**HALE:** This area isn't in clinical service. Keep within the marked route.
**PLAYER:** Was this designated W0-B?
**ENGINEER:** The archival plan says so. We'll verify physical markers.

Actions: compare current map, historical map, inspect authorized signage, document the entrance condition, verify the return route. No restricted patient archive rummaging.

## Scene 05 — The alcove
A wall alcove appears displaced relative to one version of an older plan.

**ENGINEER:** This alcove should be one bay earlier, according to this drawing.
**PLAYER:** Could there have been a renovation?
**ENGINEER:** Yes. Or the drawing is inaccurate. Let's annotate the reference points.

Choice: compare plans, request proper survey, preserve discrepancy without concluding cause.

## Scene 06 — Route concern, NOT an impossible loop
As the team returns, a faded junction marker resembles one logged on the inbound route. The corridor is straight, but the written route note is ambiguous. The team pauses at the authorized holding point.

**ENGINEER:** I thought we'd already passed that damaged ceiling tile.
**PLAYER:** Is it the same tile, or another one with similar damage?
**HALE:** We're not moving until we confirm the route. Stay together.

Security contacts control. The engineer checks the entrance/exit sequence. **The team can identify an approved, physically continuous return route. No teleportation, dynamic corridor substitution, or proof of repeated geometry.**

## Scene 07 — Account for the team
**HALE:** Dispatch, confirm the last authorized door event and our safe return route.
**DISPATCH:** Receiving. Stand by while Facilities checks the access plan.
**ENGINEER:** Two areas on these plans use identical labels. That could explain our notes.
**PLAYER:** Then we should record the ambiguity exactly as it occurred.

The team remains together. Explicit state `inspection_paused_for_route_check`. If route validation fails, invoke an authored safe-abort sequence rather than permitting aimless exploration.

## Scene 08 — Safe return
A confirmed operational-side access point is used; no forced door or unsupervised exit. On returning, all escort members are accounted for.

**HALE:** Initial inspection is over. Further access is suspended until Facilities signs off.
**ENGINEER:** I want the original notes and photographs preserved. There's a discrepancy we should survey properly.

**Exit condition:** returned to safe lobby with all party members; no scene softlock; no required paranormal affirmation.

## Scene 09 — Formal debrief
Hale, Facilities and player separately document observations. Memory, map editions, photos and access records retain distinct provenance.

**HALE:** State what you saw, not what you think it means.
**ENGINEER:** Similar landmarks, uncertain plan revision and one location note that doesn't reconcile yet.
**PLAYER:** We shouldn't call that a physical loop.
**HALE:** Correct.

## Scene 10 — Back to patient care
Bennett is busy with clinical documentation.

**BENNETT:** Well, you came back. Your EHR notifications didn't miss you.
**PLAYER:** The survey raised more questions.
**BENNETT:** Those can wait long enough for a safe handoff.

Optional Mara follow-up addresses her sleep, uncertainty and functioning; Mara is never made an investigator, and information she shares is independently verified outside clinical notes.

## Scene 11 — Survey request
Facilities proposes a controlled nonintrusive comparison of room identifiers, floor plans, reference points and instruments, contingent on safety authorization.

**ENGINEER:** We need independent measurements, not another set of assumptions.
**HALE:** No repeat entry until the inspection route is cleared.
**PLAYER:** What would count as a reliable contradiction?
**ENGINEER:** Two properly logged observations that cannot be reconciled by reference points, clocks or instruments. We're not there.

## Scene 12 — Inconsistent preliminary measurements
The engineer compares two records that differ. Their reference-frame equivalence and independence are **not yet proven**. No physically impossible dimension is confirmed.

**ENGINEER:** These measurements don't match, but they weren't taken under identical conditions.
**PLAYER:** So we have a reason for a more controlled review, not a conclusion.
**ENGINEER:** Exactly.

Actions: mark `unresolved_measurement`, request protocol, maintain restricted status.

## Scene 13 — Inspection report
Voss reviews source notes and authorizes an independent engineering assessment if safely feasible.

**VOSS:** Do not change the original measurements to make the summary read cleanly. Also don't present an unexplained difference as a discovered physical law.
**HALE:** Until we establish safety, access remains restricted.

## Scene 14 — Closing image: The unannotated photograph
At the end of the shift, the protagonist receives a legitimate notice that Facilities has preserved the raw inspection images for authorized review. A corridor photograph seems to disagree with one version of the plan; its camera position, lens and plan revision are unverified.

**PLAYER (OPTIONAL REFLECTION):** We knew the drawings might be wrong. That didn't explain why I kept wanting to look again.

No supernatural proof. No Chapter 4 loop. Fade to ordinary exterior.

## Required Chapter 3 saved state (PROPOSED)
- `ward_zero_first_entry_authorized = true` only after actual authorized access.
- `inspection_safely_returned = true` only once lobby exit and escort reconciliation succeed.
- `route_uncertainty = unresolved`; `survey_data_independence = unverified`.
- `major_corridor_loop_revealed = false` until Chapter 4 verified scripted event.

## Key production warnings
F2 does not currently prove a rollback contract. Do not implement these as independent geometry swaps without the contract in `production/F2_F3_INSPECTION_AND_EVIDENCE_CONTRACT.md`. Do not assert scene IDs or shipped evidence IDs until they are mapped against actual GitHub data and tested.
