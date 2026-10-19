# Chapter 2 Scene 04: Voss institutional review

Branch: `claude/chapter2-voss-review`, Claude Code (cloud), 2026-10-18.
Based on Codex's verified checkpoint `codex/chapter2-records-review`
`4605568a7054ab6938cee3f0563a745a808d3805` (draft PR #70, open, unmerged,
no comments or reviews when checked). The Codex branch was not modified.
Codex handed over and stopped; no newer branch, PR or ownership claim was
found after `4605568` (remote branch list and open PR list checked
2026-10-18 23:15 UTC). The draft PR for this branch targets
`codex/chapter2-records-review`, so it shows only this increment; once the
owner merges PR #70, retarget it to `main`.

## Play through

Finish the Chapter 2 opening and the records review as before (see
`2026-10-18_codex_chapter2_records.md`), ending with Naomi's records
follow-up acknowledgment. Then walk to Dr Voss (the existing staff actor at
`MARK_Character_DrVoss`) and talk to her three times:

1. **Factual scope.** Voss asks what was actually established. Saying
   someone deliberately used the inactive credential, or that the export
   proves lost time, gets her pushback and no progress. Stating only what is
   established (an inactive credential appears in the transfer-request
   audit and does not identify the user; the export mismatch is unresolved)
   records the scope. She asks for patient-safety and information-security
   concerns to be documented separately.
2. **Missing permissions.** Asking her to authorize a solo W0-B inspection,
   or direct raw source-system access, is refused with the reason. Recording
   the missing permissions lists owners: Information Security (credential
   audit), Records (the pending preservation/export request), Security (W0-B
   access policy; no inspection authorized), clinical follow-up with the
   player and nursing team.
3. **Authorized follow-up.** Pressing for an urgent patient-safety
   escalation is feedback-only: no new clinical finding is documented, so
   Voss says to escalate through clinical channels if an assessment finds
   one. Two follow-ups record: request the written escalation process, or
   propose an independent records reconciliation (Voss disagrees about
   timing but agrees to put it in writing). Either keeps the source request,
   preservation confirmation and credential audit pending.

Afterwards Voss gives a read-only status line and offers no further choice.
Chapter 2 is not complete; the next authored scene is Scene 05.

Before the records memo is acknowledged, Voss only says clinical work comes
first and offers no review choice.

## Sources and boundaries

- Screenplay: `docs/design/screenplays/ForensicWard_Revised_Screenplays_v2/chapters/CH02_EXPANDED_SCENES_v2.md`
  Scene 04 (Voss lines and the three branches) and the campaign package
  Scene 04 ("Identify missing permissions"; choices preserve required access).
- The inactive credential and unidentified requester come from Chapter 1's
  existing chart audit entry (`data/story_chapter1.json`,
  `transfer_request_logged` by `credential:inactive`). Nothing new is
  asserted about who used it.
- No clinical finding, diagnosis, medication detail or source record is
  invented. The "urgent safety" branch exists but cannot record progress
  because nothing documented supports it, per the screenplay's "when
  supported".
- No Ward Zero entry, access grant, Mara content or supernatural element.
  Hale is named only as the owner of access policy; he is not placed.
- Proposed dialogue remains narrative-review pending (story file stays
  `provisional`, `clinical_review_status` PENDING).

## Implementation

Data only: `data/story_chapter2.json` gains three objectives, three Voss
staff lines and three `character:staff_voss` interactions using the existing
authored-interaction, feedback-option and expiry system. New flags:
`ch2_voss_scope_recorded`, `ch2_voss_permissions_recorded`,
`ch2_voss_followup_written_process`, `ch2_voss_followup_independent_review`.
Existing chapter flags and save schema are reused; no provider, migration,
EventBus, Main, scene, project, CI or QA-runner change.

`scripts/tests/test_chapter2_voss.gd` (+ Godot-generated UID) drives the real
Main scene, real Voss actor and displayed buttons:

- Voss waits for the memo and grants nothing; an undisplayed choice is rejected.
- Written-process branch and independent-reconciliation branch: every
  unsupported claim leaves flags unchanged; each step keeps clinical
  records, evidence and TrustManager access identical, the source request
  recorded, W0-B locked and Chapter 2 incomplete; post-choice save, reset and
  load is an exact roundtrip; Voss is read-only afterwards and a stale option
  cannot rewrite the follow-up.
- Interruption: closing the conversation abandons the displayed choice;
  saving with the permissions step on screen and loading from a fresh game
  restores exactly, rejects the pre-load choice, resumes at the permissions
  step without replaying scope; reloading rolls back a later choice; closing
  the follow-up step leaves it open.

`scripts/tests/test_chapter2_records.gd`: the one assertion that expected no
objective after the records review now expects `obj_ch2_voss_scope`. All its
other assertions are unchanged.

## Tests

See `docs/AI_HANDOFF.md` (2026-10-18 Claude Code entry) for the exact
commands, SHAs and counts. Godot 4.7 stable standard was downloaded from the
official release and its SHA-512 verified as CI does. Mac visual and
performance checks were not run; hosted CI for this branch is recorded there.

## Addendum: Scene 03 Mara Ellis (owner-approved)

Owner, project thread 2026-10-18 23:27 UTC: "i approve scene 3". Runtime
`09e4a8cb45981dd0959c7dc6058b62bc870e0d58` on this branch. Logged in `docs/clinical_review_log.md`.

**Play:** after either Voss follow-up, Mara Ellis is seated in Interview Room A
(Elias is back on the unit meanwhile). Approach her: the existing interview
screen runs `data/dialogue_mara.json`, which transcribes revised CH02 Scene 03
(three opening alternatives, the two-copies exchange, then sleep, mood history,
alternatives, safety and collateral modules in any order, and the closing
exchange). Each module records one patient-report observation with provenance;
the records-origin question records one clinician observation. Then save a note
in the EHR, and refer her date question to Records at the office workstation.
Attaching clinical details or adding it to the W0-B inquiry gives feedback only.
Elias returns once the referral is sent.

**Order:** Scene 03 runs after Scene 04 in this build (objectives are
sequential and Scene 04 was already built); neither scene's text depends on the
other.

**Boundaries:** dialogue `APPROVED` (owner); patient record `pt_mara_ellis`
stays `PENDING_PSYCHIATRIST_REVIEW` because its observation wording and three
`differential_tags` are the agent's. No diagnosis, medication, treatment effect,
forensic opinion, clue or evidence. Dana is named only as possible collateral;
nothing is obtained from her. The legal status is recorded as a question to
check against the actual order.

**Code:** StoryLogic gains `not`; world characters gain optional
`present_when` (validated like story conditions; checked on objective change
and tree entry); `PatientManager.is_admitted()` keeps later arrivals off the
EHR census and shift summary before their `arrival_shift`. Old saves without
Mara load with fresh state for her. `test_chapter2_mara.gd` covers census
timing, the full scene with save/load and presence, an interrupted interview
resumed after load, older saves and presence validation. `test_content.gd`
patient list and the Voss test's final objective were updated to include her.

**Tests on `09e4a8cb45981dd0959c7dc6058b62bc870e0d58`:** full runner exit 0: game 212/0, GLB 161/0, audio 336/0,
QA 19/0/0, Python 6+4+5+3, pharmacology 0 failures, boot, CH1_SEQUENCE_DONE.
First runs failed 208/3 (null tree in presence update for characters outside
the tree, fixed with a guard; two stale test expectations updated). Mac not run.

## Addendum: Scene 05 analyst working explanation

Runtime `0d298cfa7a557eeab11a0b265e203116012fe0ad` on `claude/chapter2-mara-intro` (PR #72). After Mara's referral,
the Records worksheet shows the analyst's four candidate explanations (clock
skew, migrated location codes, export sorting, identifier collision; the last
is grounded in Elias's existing `transfer_identifier_collision` discrepancy).
Log them as untested, then choose one next check: source extraction, identifier
crosswalk or neutral second review. Accepting skew as the whole answer, calling
the remainder altered time, or closing it as a migration artefact gives
feedback only. Everything stays open; no source packet is received. New
`test_chapter2_analyst.gd` covers all three branches with post-choice save/load
and a mid-scene interrupted load. Full runner exit 0: game 216/0, GLB 161/0,
audio 336/0, QA 19/0/0, Python 6+4+5+3, pharmacology 0, boot, CH1 sequence.

## Addendum: Scene 06 Hale's Door

Runtime `ffd5730f9d6182d26f104f9d340fad566587fdb8` on `claude/chapter2-hale` (stacked on Scene 05's branch; PR to
main). Once the analyst's next check is chosen, Marcus Hale stands at the
psychiatrist's office desk (`MARK_Seat_Psychiatrist_Desk`, via `present_when`;
his own marker is in the unreachable security wing). Talk to him: scope the
question (how the restricted designation appeared in a live request; he answers
with both screenplays' lines), then request one permitted follow-up: clinical
risk check, access-log report summary or archived facilities plans. Asking for a
badge, an escort into W0-B, or claiming the request proves a door opened gives
feedback only. No access, inspection or patient movement. New
`test_chapter2_hale.gd` covers all three follow-ups with post-choice save/load
and an interrupted conversation. Full runner exit 0: game 220/0, GLB 161/0,
audio 336/0, QA 19/0/0, Python 6+4+5+3, pharmacology 0, boot, CH1 sequence.

## Addendum: Scene 07 An Incomplete Witness

Runtime `3a919c972c4cbac795dd72844567516dae68a04f` on `claude/chapter2-witness` (stacked on Hale's branch / PR #74).
New staff entry `staff_facilities_tech` ("Facilities technician", role only; no
invented name) stands at `MARK_Standing_Staff_Door` once a Hale follow-up is
requested. Asking "Did you actually see anyone use the elevator?" records the
account as witness memory; a leading question or recording lift movement gives
feedback only. Follow-ups: confirm work orders, keep the statement as reported,
or check timing without suggesting one. No clue, evidence, anomaly or patient
change (tested). New `test_chapter2_witness.gd`. Full runner exit 0: game
224/0, GLB 161/0, audio 336/0, QA 19/0/0, Python 6+4+5+3, pharmacology 0, boot,
CH1 sequence.

## Addendum: Scene 08 The Door That Wasn't Left Open

Runtime `4669c7c387107584e6429cf79cb035194fcec0b5` on `claude/chapter2-lobby` (stacked on the witness branch / PR #75).
Owner chose "Escorted pass". After the technician's follow-up, Hale offers an
escorted look at the restricted lift lobby doors only (asking for W0-B is
refused). Accepting grants `access_ward_entry` for this inspection; walk through
the ward entry doors to the end of the security corridor and use the lobby
doors' inspection point (the camera dome in front of `Door_LiftLobby`; the lobby
door shares `access_restricted_lift` with the lift, so the player never enters).
Note them closed; the escort's radio draws you both to the maintenance door; on
return they are ajar. The escort's and player's screenplay lines play. Document
the state, have it secured, or request a latch and ventilation assessment;
stepping in or recording an intruder is feedback-only. Return the pass to Hale
at the psychiatrist's office: access is revoked and the ward entry doors swing
shut. No trapping, portal, anomaly, evidence or patient change (tested).

**Follow-up:** a dedicated MARK/story prop at the lobby doors would read better
than the ceiling camera dome; needs an asset change.

## Addendum: Scene 09 A File for the Wrong Day

Runtime `1481c7ea32b8a5cb553d50529afd387e382f5898` on `claude/chapter2-wrong-day` (stacked on the lobby branch / PR #76).
After the pass is returned, the export comparison worksheet shows two archived
export representations disagreeing about the access-event date, with time-zone
provenance unreconciled (revised CH02 Scene 09). Adding it to Mara's note or
treating it as a symptom gives feedback only; the player's screenplay line puts
it in the authorized incident record and the Records technician answers with
theirs. Then one handling: formal audit escalation, preserve separate source
versions, or independent technical review. "Correct one version" is refused.
Mara's note, evidence, anomalies and access are unchanged (tested).

## Addendum: Scene 10 Missing Hours (closing beat)

Runtime `1bb194df802b68591f9e7ab8a7939754e91bd8e3` on `claude/chapter2-missing-hours` (stacked on PR #77). The
analyst's note at the export worksheet accounts for part of the mismatch but not
the whole interval (revised CH02 Scene 10 lines). Reporting it all as skew, or
the remainder as missing time, is feedback-only; "Then the report should say
that." records the limits. Bennett, ending her shift, asks "Any luck?"; claiming
the missing hours were found is feedback-only; "We confirmed there are records
we can't reconcile yet." gets her screenplay reply and completes Chapter 2. No
evidence, anomaly, access or clinical change; W0-B locked; Chapter 3 is not
started (campaign status planned). Not built: the optional personal-contact
message (needs a personal-history system) and the exterior fade-out.

Code: `ChapterDirector.set_flag` emits `chapter_completed` for the completion
flag (sign-out no longer emits separately, so it still fires once).
`interaction_ch2_review_return` now expires after acknowledgement.

## Next exact task

Chapter 2 is completable end to end. Ask the owner for narrative review of
Scenes 04–10 (story file remains provisional / PENDING). Then plan Chapter 3
(first authorized Ward Zero entry) only on the owner's go-ahead. Naomi
Mac/geometry gates remain pending.
