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

## Next exact task

Chapter 2 Scene 05 "A Working Explanation": an analyst tests clock skew,
migrated location codes, export sorting and identifier collision; each may
explain part of the discrepancy and at least one item stays open. Implement
it with the existing authored interactions on an existing Records prop or
actor, gated on either Voss follow-up flag, with choices for source
extraction, identifier crosswalk and a neutral second review. Do not invent a
received source packet or a resolved interval. Add partial and post-choice
save/load tests. Mara's Scene 03 needs its own clinical approval before
implementation. Naomi Mac 33 ms, lid/hem geometry, gesture shadows and the
final in-game visual review remain pending independently.
