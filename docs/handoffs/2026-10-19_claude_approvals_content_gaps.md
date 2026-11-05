# Owner approvals and content gaps (Claude Code, 2026-10-19)

- **Branch:** `claude/owner-approvals-content-gaps` from main `572bf40`. Code checkpoint `04fdb8c` (full QA passed); later commits are documentation only. Draft PR to main; do not merge automatically.
- **Owner request (Bi, project thread, 2026-10-19 21:55 UTC):** "I approve all cast models and the narrative review. I reviewed clinical items ... Create completed cast models. Improve hair and clothing. FIx small content gaps." The clinical sentence was cut off, so a card asked; Bi chose **"Approve all"** for the four listed items (Elias dialogue, Mara record, catatonia rule, Chapter 2 work).
- The cast hair/clothing work is a separate branch, `claude/cast-hair-clothing`, with its own handoff. It also records the cast visual approval in `data/character_visuals.json`. This branch does not touch cast files.

## Approvals recorded

| Item | Change |
|---|---|
| Narrative review | `provisional: false` for Chapters 1–5 in `data/campaign.json` and every `data/story_chapter*.json`; stale campaign note replaced |
| Catatonia rule | `clinical_rule_catatonia_escalation_v1` and its action `evaluate_catatonia` APPROVED. It still applies only `mark_assessment_started`. It now also applies in validated build mode. `clinical_rule_medical_review_request_v1` stays pending |
| Elias dialogue | `data/dialogue.json` APPROVED. Elias's patient record stays pending because it was not on the list |
| Mara record | `pt_mara_ellis` APPROVED |
| Chapter 2 work items | `data/story_chapter2.json` clinical_review_status APPROVED. Chapters 1 and 3–5 keep PENDING clinical status |

All are logged in `docs/clinical_review_log.md`.

**Later the same evening (22:48 UTC)**, Bi also approved the following, recorded as written. Their message ends mid-word: "...without a separately scripted Chapter 3 follow-".

- The Chapter 4 Mara follow-up dialogue "exactly as shown, including the insomnia, anxiety, daily functioning and follow-up wording".
- Elias's record (`pt_elias_ward` APPROVED).
- "the medical review" (`clinical_rule_medical_review_request_v1` and `request_medical_review` APPROVED).

Every shipped clinical rule is now approved. The governance tests load a test-only fixture where the medical review rule is pending, and `test_shipped_clinical_rules_are_all_approved` guards the shipped state.

**Chapter 3 decision (owner):** Mara's optional follow-up is left unimplemented. Chapter 3 focuses on the authorized Ward Zero inspection, and her established clinical care continues through the existing systems (`data/story_chapter3.json` notes).

## Content gaps filled

- **Chapter 2 Scene 10:**
  - Bennett's line ("Don't decide the answer first") now leads straight into the optional personal message in the same panel.
  - The message can come from a partner, a friend or family, can be the player's own reminder, or can be left for later. Sharing work detail is refused.
  - The choice is stored as `ch2_contact_*`, the player's moderate personal history.
  - "Head out" then closes the chapter over the ordinary hospital exterior, and the recap plays.
  - The message waits at `NS_NoticeBoard` if the panel is closed.
  - New objective: `obj_ch2_end_of_shift`.
- **Chapter 4 Scene 04 (optional):**
  - Mara attends a follow-up in Interview Room A from Rahman's boundary until the door check starts. Elias steps out meanwhile.
  - Uses the screenplay lines only. Claiming the review has found the wrong date is refused.
  - Flag: `ch4_mara_followup`.
  - The owner approved the wording exactly as shown on 2026-10-19.
- **Chapter 4 Scene 06 (optional):**
  - After the paper trail, a phone notification sends the player to the nursing station.
  - The call comes from the Chapter 2 contact. The self-reminder gets its own version. If the message was left until later, or the save predates the message, the player sees only a neutral break reminder, so no relationship is assumed.
  - The player can accept support, keep it short or set a boundary (`ch4_call_*`). Sharing inquiry detail is refused.
- **Not built, by owner decision:**
  - Chapter 3's optional Mara follow-up.

## Owner review checks (2026-10-19 22:43 UTC)

1. **Protagonist customization and confidentiality**, checked against `docs/design/PROTAGONIST_CUSTOMIZATION_PLAN.md`:
   - Personal-life scope is moderate. No relationship, romance or family is mandatory: the own-reminder and "Leave it for now" choices are independent-life paths, and the later path never assumes a relationship.
   - No trauma or personality score is involved.
   - Only stable flag ids are stored (`ch2_contact_*`, `ch4_call_*`), never contact details.
   - Text appears in the existing InfoPanel only, with no phone simulation and no new location.
   - No protagonist name or pronouns are used, so the text stays valid for any future identity.
   - Sharing ward, patient or inquiry detail is refused in both chapters.
   - Mara's follow-up adds nothing to incident evidence (the test checks this).
   - Clinical rules take no personal input.
   - When the P1 protagonist schema lands, these flags map into its choice ledger.

   Callback authoring table:

   | Chapter | Selected option | Delivery | Fallback | Dedupe | Convergence |
   |---|---|---|---|---|---|
   | 2 | partner, friend, family, self, later | InfoPanel after Bennett; re-open at `NS_NoticeBoard` | "Leave it for now" | one flag; the interaction expires once chosen | "Head out" then `chapter_complete` |
   | 4 | Chapter 2 flag via `chapter_flag` | notify toast, then `NS_NoticeBoard` | neutral break reminder (later or old saves) | expires on any `ch4_call_*` | none needed; the door check proceeds regardless |

2. **Chapter 2 exterior fade:**
   - The approved Static Graphic-Novel art has no hospital exterior panel; Chapter 2's panels are the ward, interviews, nursing station, records and the Mara record comparison.
   - So the close is text only ("You sign out at the staff entrance. The shift is over." and "The screen fades out.").
   - The owner-approved `cs_ch02_static_gn` recap then plays, opening on its black fade.
   - No new image, scene or environment was added. The branch changes no files under `assets/`.

3. **Save/load, skipping and recap:** new tests cover each of these.
   - Save with the message unanswered, load, answer at the notice board, head out.
   - The recap `cs_ch02_static_gn` opens over the end panel, and Chapter 3 follows.
   - Save and load with Mara in the room and with the call waiting. The Chapter 2 contact survives in the archive.
   - Skipping the Mara follow-up returns Elias at the door check.
   - Chapters 3–5 and Chapter 4 still complete through the existing tests without either optional scene.

## Engine changes

- Story options accept `next_interaction`, which opens the next scene in the same panel when its conditions hold. Schema, validator and `ChapterDirector._follow_on_panel` were changed; the validator rejects unknown or self references.
- `Character` re-checks `present_when` after any story choice (deferred), so optional scenes that don't move the objective can swap who is in a room.

## Tests

- **Command:** `python3 tests/qa/run.py --godot Godot_v4.7-stable_linux.x86_64` (official 4.7 Linux binary, SHA-512 verified) on `04fdb8c`, exit 0.
- **Results:**
  - Gameplay 293/0.
  - GLB 168/0.
  - Audio 412/0.
  - QA 19/0/0.
  - Python 6+4+6+3, pharmacology 0 failures.
  - `CH1_SEQUENCE_DONE` at 61.8 s.
- **New and updated tests:**
  - New file `test_chapter4_optional_scenes.gd`:
    - Mara follow-up.
    - Skipped window.
    - Partner call, self-reminder and later/older-save calls.
  - `test_chapter2_missing_hours.gd` covers the message, the refusal, re-opening at the board, the fade-out and save/load resume.
  - The eight chapter tests that replay Chapter 2 pick "Leave it for now" and "Head out".
  - Rule-governance tests now exercise the still-pending medical review rule. New tests check that the approved catatonia rule applies in validated mode.
- **Not run:** Mac. Hosted CI runs on the PR.

## Next

1. Bi reviews and merges this PR and the cast PR.
2. The executive producer reviews the Chapter 4 Mara wording.
3. Decide whether to write Chapter 3's optional Mara follow-up.
4. Do a Mac playthrough, then create export presets.
