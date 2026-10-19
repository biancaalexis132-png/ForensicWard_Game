# Chapters 3–5 (Claude Code)

Owner, project thread 2026-10-19 00:31 UTC: "i like the scenes continue building till chapter 5 completed". Built in small stacked slices, one draft PR each, from the revised v2 screenplays (`docs/design/screenplays/ForensicWard_Revised_Screenplays_v2/chapters/`) and the campaign package. Proposed dialogue stays narrative-review pending (story files `provisional`, `clinical_review_status` PENDING). Boundaries kept: no corridor-loop reveal before Chapter 4 Scene 09; clinical care separate from the investigation; no psychiatric symptom used as proof; copies are not corroboration.

## Chapter 3 Scenes 01-02 notice and briefing

Runtime `4c1bb95df4dc22781005a335222398a3e836b845` on `claude/chapter3-briefing`. Chapter 2's close continues to the next day shift. Bennett hands over the inspection notice (coverage, audit summary, clinical scope, in any order; leaving uncovered refused). Hale's briefing at the office desk with the engineer's line; asking to go alone refused; boundaries, stop conditions and the return route recorded. Entry approval and the life-safety check are stated as signed, but nothing is unlocked in this slice.

Tests: Full runner exit 0: game 238/0, GLB 161/0, audio 336/0, QA 19/0/0, Python, pharmacology 0, boot, CH1 sequence.

## Chapter 3 Scenes 03-04 descent and first Ward Zero entry

Runtime `2151b58662236e548d507a853eb1c400d42fd5fc` on `claude/chapter3-descent`. The team pass (ward entry, maintenance) comes from Hale; descent via the security wing's maintenance hatch. Facilities clears the isolated circuit, the brick end opens (world state), and a fade connection enters the threshold. Inside, four documented actions; patient records are off limits. Save/load inside Ward Zero restores the zone. Ward Zero performance on the target Mac is unmeasured.

Tests: Full runner exit 0: game 241/0, GLB 161/0, audio 336/0, QA 19/0/0, Python, pharmacology 0, boot, CH1 sequence. Mac not run; Ward Zero frame time on the 8 GB Mac is unmeasured.

## Chapter 3 Scenes 05-08 alcove, route check and safe return

Runtime `aee2b95bd353bf60b649e3485be5eadd497880f4` on `claude/chapter3-return`. The alcove's one-bay difference is recorded three possible ways without a cause. A familiar marker pauses the inspection; a loop is never claimed; the team holds together while control confirms one continuous route. Back in the office Hale counts the team in and takes back every scene pass.

Tests: Full runner exit 0: game 244/0, GLB 161/0, audio 336/0, QA 19/0/0, Python, pharmacology 0, boot, CH1 sequence.

## Chapter 3 Scenes 09-14 debrief to closing photograph

Runtime `095fef19331e8b72891d0027f2b7346274712b3c` on `claude/chapter3-report`. Debrief keeps statements separate and refuses the loop; Bennett returns the player to clinical work; the survey is requested without a repeat entry; two measurements stay unresolved with a protocol and the restriction; Voss keeps the originals; the photograph is logged with camera, lens and plan revision unverified (optional reflection line). Chapter 3 completes.

Tests: Full runner exit 0: game 246/0, GLB 161/0, audio 336/0, QA 19/0/0, Python, pharmacology 0, boot, CH1 sequence.

## Chapter 4 Scenes 01-03 and 05 official record

Runtime `e17fa49fb6b9665ac8f15d43990188620ba3a048` on `claude/chapter4-record`. Voss keeps two incident files; the draft summary's unproven 'confirmed mapping error' is corrected (geometry claims refused too) with the first version kept; Rahman's clinical boundary; both retained originals preserved with the checks performed. Rahman is placed with the generic character body until her model exists.

Tests: Full runner exit 0: game 249/0, GLB 161/0, audio 336/0, QA 19/0/0, Python, pharmacology 0, boot, CH1 sequence.

## Chapter 4 Scenes 07-08

Runtime `daca017` on `claude/chapter4-door-test`. data/story_chapter4.json, data/world_chapter4.json, scripts/tests/TestRunner.gd, scripts/tests/test_chapter4_door_test.gd

Tests: Full QA at daca017: all executed checks passed; game tests 252 passed 0 failed; GLB 161/0. Mac checks not run.

## Chapter 4 Scenes 09-10

Runtime `ec4d3d4` on `claude/chapter4-loop`. data/story_chapter4.json, data/world_chapter4.json, scripts/narrative/ChapterDirector.gd, scripts/narrative/StoryLogic.gd, scripts/tests/test_chapter4_loop.gd, scripts/tests/test_chapter4_door_test.gd

Tests: Full QA at ec4d3d4: all executed checks passed; game tests 255/0; GLB 161/0. Mac checks not run; Ward Zero Mac performance unmeasured.

## Chapter 5 finale

Runtime `e545408` on `claude/chapter5-finale`. data/campaign.json, data/story_chapter4.json, data/story_chapter5.json, data/world_chapter5.json, scripts/tests/test_campaign.gd, scripts/tests/test_chapter5_finale.gd

Tests: Full QA at e545408: all executed checks passed; game tests 258/0 (3 endings each reachable with save/load at the decision); GLB 161/0. Mac checks not run.

## Next exact task

Owner review of Chapter 5 text; decide on Scene 08 (Mara) once patient-state content is approved; Naomi Mac/geometry gates still pending.
