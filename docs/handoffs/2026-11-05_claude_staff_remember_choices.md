# Staff remember earlier choices (Claude Code, 2026-11-05)

Roadmap point 3 from Bi's seven-point plan ("Make choices feel consequential"), thread "Make the game more compelling". Branched from `main`, independent of #137 and the map PR.

## What changed

- **`data/acknowledgements.json`** holds 17 lines (A1 to C6 in the review sheet). Each line belongs to one staff member in one chapter and has a condition, usually a `chapter_flag` from an earlier chapter's choice.
- **`scripts/narrative/Acknowledgements.gd`**: the first time you talk to that staff member in that chapter, the line opens their reply. It plays once; played lines are saved by their own provider (`acknowledgements`), separate from story flags, so it never repeats. `validate()` checks staff, chapters, conditions, and that each referenced flag is really set by a choice or beat.
- **`Character._talk_to_staff`** gets a 5-line addition.
- **All 17 lines approved by Bi on 2026-11-05 ("approved continue") and switched on** (`approved: true`). Review sheet: `/mnt/project-files/consequences/acknowledgement_lines_review.md`. They show as text; voicing them with the local voice pipeline is a follow-up.

## Tests

`test_acknowledgements` (4): data valid; unapproved lines never play; an approved line opens the first reply once, also after save/load; no line without the earlier choice. Full QA: see the `docs/AI_HANDOFF.md` entry.

## Pending

- Voice the 17 lines (follow-up).
- The ending paragraph (review sheet section D) needs `CaseFile` from #137, so it follows once #137 merges.
- Not tested on the Mac.
