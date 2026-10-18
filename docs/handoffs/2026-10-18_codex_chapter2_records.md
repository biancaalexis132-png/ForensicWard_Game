# Chapter 2 records-review continuation

Branch: `codex/chapter2-records-review`. Draft PR #70:
https://github.com/biancaalexis132-png/ForensicWard_Game/pull/70.
Recovery `5f60dfbfacb3def003dce3ebfa2ee71cd39fa813` pushed/verified; this
link-only checkpoint follows. Started from verified opening
`6e04daf`; owner merged PR #69 during work, so main `3b6e9b8` is integrated.
No other active session found; the owner's confirmation that other AI sessions
stopped remains in force. Changes avoid face/audio controllers and source assets.

## Play through

Continue through the Chapter 2 opening normally. After its Naomi acknowledgment,
return to Records. The same worksheet now supports the next stage:

1. Review missing clock authority/offsets. An unsupported four-minute correction
   gives feedback; retaining uncertainty records the review.
2. Review raw event ordering and the repeated minute. A missing-time conclusion
   gives feedback; requesting ordering metadata records the review.
3. At the office request workstation, inspect source independence. A copy alone
   cannot promote corroboration; request lineage and shared dependencies.
4. At that workstation, distinguish a sent preservation request from confirmed
   receipt/custody/checksum. Keep confirmation outstanding.
5. Return to Records and scope the unresolved memo, prioritizing either clock
   authority or source lineage/custody. Both retain every outstanding question.
6. Return to Naomi and acknowledge records follow-up separately from clinical
   responsibility. This completes the authored review slice, not Chapter 2.

The original display discrepancy, repeated minute and unknown metadata come from
existing revised CH02 Scenes 01–02 and the campaign evidence contract. No raw
export, exact event time, custody receipt, preserved-original checksum or verified
source is invented. Reconciliation remains pending. Proposed text retains
review-pending metadata; no clinical facts or automatic medical effects are added.
Mara, Ward Zero access and supernatural mechanics remain outside this increment.

## Runtime and saves

Story interactions can expire on authored conditions and provide read-only
completed status. Feedback options may omit `flag`; they show a response without
mutating progress. ChapterDirector selects the next eligible phase on a reused
prop and rechecks expiry before committing a displayed option. Completed memo
choices expire, preventing another emphasis from rewriting the saved decision.
Expiry conditions are validated with the existing StoryLogic vocabulary.

All progress uses existing chapter flags and existing save schema. Old opening
saves without these flags naturally resume at the first review objective. No new
provider, new manager, asset generation, source-catalog/clinical coupling, main
scene, EventBus, project/CI/QA-runner change. The seven new real-Main tests cover
both complete branches with populated existing clinical notes/findings, exact
partial/completed save roundtrips, old opening state, unsupported inference,
read-only memo replay, expired display choices and invalid expiry references.
The original opening test now expects its next review objective instead of an
empty objective list; all prior assertions about opening completion remain.

Baseline and targeted totals: 196/0 → 203/0. Full runner on pushed/verified
runtime `122304d460126f6645c9ce6afd63395e8e52ec32` exited0: Python6+4+5+3,
pharmacology0 failures, QA19/0/0, GLB161/0, game203/0, audio336/0, bootOK,
CH1_SEQUENCE_DONE and all executed checks passed. No skips or weakened tests.
Publication/recovery checkpoint is recorded in AI_HANDOFF.md. New test UID
is retained; `.godot`/extracted textures/import caches are untouched. Untracked
`work/` contains isolated XDG state/logs, with `.gdignore`; no new dependency.
Use official Godot4.7 at
`/workspace/.tools/godot-4.7/Godot_v4.7-stable_linux.x86_64` in this workspace.
Mac visuals/frame time and hosted CI remain unobserved until separately checked.

## Next exact implementation task

Implement Chapter 2 Scene04 Voss's institutional review conversation using the
existing staff actor, authored interactions and source screenplay. Record a
factual scope, missing permissions and authorized follow-up without resolving
the source request or granting Ward Zero entry. Add interrupted conversation and
post-choice save/load tests. Scene06 Hale access-policy work can follow through
existing authorization systems. Re-read narrative/clinical contracts first;
Mara's clinical content needs its own approval, and no received technical source
packet may be invented to force reconciliation. Naomi Mac33ms/geometry/owner
visual checkpoint remains pending independently of campaign development.
