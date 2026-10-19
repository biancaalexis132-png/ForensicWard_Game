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

## Next exact task

Chapter 4 (The Official Record): read CH04_OFFICIAL_RECORD_v2.md; Scene 09 major corridor-loop reveal needs explicit owner approval of the effect and F2 safety tests before it is built.
