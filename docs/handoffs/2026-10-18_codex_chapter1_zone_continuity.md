# Chapter 1 zone-condition continuity

Branch: `codex/chapter1-zone-continuity`, based on verified `origin/main` `996fd9a`.

The owner confirmed other AI sessions stopped. Historical F2/F3 claims were
checked before editing. This increment is independent of draft viseme PR #67:
no CharacterFaceRig, DialogueManager, AudioDirector, asset or generated import
files changed. The owner's animation approval remains scoped to animations
shown so far; Mac frame-time and outstanding geometry gates remain pending.

## Change

ChapterDirector accepted `zone` conditions but omitted location from its story
context and did not evaluate on zone changes. Real walking therefore could not
complete a location objective or run its arrival beat. ZoneDirector now exposes
its existing authoritative state through a scene group; ChapterDirector reads
that state and subscribes to the existing zone_changed signal. No duplicate
location save field or save migration is introduced.

Two integration tests use a clearly labelled nonclinical story fixture with the
real Main scene and real ward-entry walk. They verify initial location, automatic
arrival beat/objective/HUD updates, returning to the clinical wing, deduplication,
same-zone save/load, and a fresh game. Fixture-only access grants do not change
shipped Chapter 1 restrictions. No authored patient facts or screenplay changes.

## Validation

Baseline: gameplay 177 passed, 0 failed. New tests first reproduced 177 passed,
2 failed. After the fix: 179 passed, 0 failed. No checks disabled or weakened.
Full runner exited0 on `e13fb0cec0b501d566fec090b8c14aac55766254`: Python6+4+5+3,
pharmacology0 failures, QA19/0/0, GLB161/0, game179/0, audio336/0,
bootOK and CH1_SEQUENCE_DONE. Draft PR #68:
https://github.com/biancaalexis132-png/ForensicWard_Game/pull/68.
Hosted CI not observed. Linux headless results do not validate Mac performance or visuals.
Local scratch `work/` remains untracked and excluded from Godot import. Required
engine: official Godot 4.7 standard; no new dependency or asset generation.

## Next exact implementation task

Implement the Chapter 2 Scene 01 nursing-station opening as a separately tested
vertical slice using the existing campaign loader, ChapterDirector and authored
JSON. Begin from the owner's latest merged main; keep clinical review/assignment
separate from the audit lead. Cross-check
`docs/design/screenplays/ForensicWard_Revised_Screenplays_v2/chapters/CH02_EXPANDED_SCENES_v2.md`
and existing campaign/clinical approval contracts before shipping dialogue:
that screenplay explicitly remains narrative-approval pending. Do not add Mara
findings, inaccessible record access or Ward Zero entry. Retain Chapter 1 saves,
new-shift objective continuity and idempotent handoff. Mac Naomi checks may
proceed separately; this QA increment does not certify Naomi technically ready.
