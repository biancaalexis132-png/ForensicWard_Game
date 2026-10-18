# Chapter 2 first playable opening

Branch: `codex/chapter2-opening`. Draft PR #69:
https://github.com/biancaalexis132-png/ForensicWard_Game/pull/69.
Recovery checkpoint `9a54ddf6db3152fe7c1ffd7e61967ac9a97c3b71` pushed
and remotely verified; this link-only checkpoint follows. Main now includes owner-merged PRs #67 and #68.
Other AI sessions were confirmed stopped; historical claims and open PRs were
checked before editing. No competing current workstream was found. Face rigs,
DialogueManager, AudioDirector, assets and generated texture dependencies are
unchanged. No branch history rewritten or PR merged automatically.

## Play the slice

Start the normal game. Finish Chapter 1's night sign-out at the nursing-station
board; choose **Return for the next day shift**. Closing the panel keeps the
completed Chapter 1 save available. The explicit choice enters Chapter 2 on the
next morning, reusing the actual staffed clinical-wing assets with chapter-specific
wiring. Existing notes, observations, evidence, patient state and relationships
are retained. No fresh clinical work is inferred from old Chapter 1 notes.

1. Talk to Naomi at the nursing station.
2. Use the handover board and explicitly retain responsibility for outstanding
   clinical review/follow-up. This assigns work; it never marks care completed.
   The existing nursing-station and office EHRs remain available.
3. In Records, use the maintenance-export comparison. Record the reported
   four-minute mismatch/repeated minute as **unresolved**.
4. Use the office source-request workstation to request preservation and an
   authorized export with offsets, clock source and sort order. This does not
   grant restricted access or authenticate a source.
5. Return to Naomi and acknowledge outstanding work. The opening objectives
   finish; `chapter_complete` is deliberately not set for Chapter 2.

This is the first vertical slice, not complete Chapter 2. Screenplay basis:
`docs/design/screenplays/ForensicWard_Revised_Screenplays_v2/chapters/CH02_EXPANDED_SCENES_v2.md`,
Scenes 01–02. The owner requested implementation using these sources; proposed
text is still pending narrative/clinical review, not approved clinical content.
Mara's interview, new clinical facts, Ward Zero entry and supernatural reveals
are absent. Existing paper prop markers are reused; they are not final document
artwork. New dialogue is text-only; no new voice asset is claimed.

## Implementation and recovery

Authored `interactions` on story JSON supply target, condition, display text,
unavailable reason, and explicit option/flag/response. InfoPanel displays the
buttons and sends one EventBus signal. ChapterDirector validates current displayed
interaction, condition and option before setting an existing chapter-local flag.
Close/load/chapter change cancels the pending choice; duplicate events do not
reapply work. No new persistent provider or schema version is needed.

Main rebuilds authored world wiring on chapter changes and during save restoration
before the existing zones provider applies saved doors. A Chapter 1 save loaded
from Chapter 2 reconstructs the original pickups/sign-out board; a Chapter 2 save
loaded from Chapter 1 reconstructs the worklist/comparison/request. Other campaign
fixtures without world files retain their existing behavior. No main scene,
project configuration, QA runner, CI, save migration or source asset edit.

Seven new real-Main regressions exercise displayed buttons, full opening,
precondition bypass, care/evidence separation, restricted doors, partial and
completed save/load, same-chapter reload, returning to Chapter 1, stale/closed
choices, duplicate choice events, delayed continuation and invalid authored
references/options. Existing campaign expectation now recognizes the real Chapter 2
opening while chapters 3–5 remain planned; their fixture coverage stays intact.
Final full QA on pushed/verified runtime `d4fead70db995b21d2de921d222d51eccd75ac72` exited0:
Python6+4+5+3, pharmacology0 failures, QA19/0/0, GLB161/0, game196/0,
audio336/0, bootOK and CH1_SEQUENCE_DONE. Baseline187/0, targeted194/0,
then owner-merged zone tests brought the combined total to196. Hosted CI not
observed. Tests use actual displayed buttons and props; Linux headless is not
Mac visual/performance validation. See AI_HANDOFF.md for recovery checkpoint.

Dependencies: official Godot 4.7 standard, existing project assets. Local `work/`
is excluded from Godot import and remains untracked; no disposable cache or
extracted textures committed/deleted. New script UID is kept beside its source.
Mac frame time, visual approval and interactive feel remain untested here.

## Next exact task

Extend `data/story_chapter2.json` and the existing records workflow into the next
approved Scene 02 step: receive and compare authorized source-system records,
retain immutable originals and source/clock provenance, and keep unreconciled
intervals explicitly unresolved. Add a mid-request and post-reconciliation save
regression before expanding the scene. Re-read screenplay and approval register
first; do not invent a received record, clinical fact or authenticated anomaly.
Mara clinical content remains a separate approval gate. Run the full QA runner
before publishing the next increment. Naomi Mac33ms and geometry gates remain
pending, independent of this campaign work.
