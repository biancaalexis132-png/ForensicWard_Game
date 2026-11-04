# Bedside conversation with ward-round patients (Claude Code, 2026-11-03)

Branch `claude/ward-round-bedside-talk`, stacked on `claude/patient-hair-cards` (#119). Draft PR, not merged.

## What it does

- New **Bedside** tab, first on the ward-round screen; a patient not yet spoken to opens there (also when you walk up to them on the ward).
- **Opening** (once per run): warm (trust 2), direct (trust 1) or rushed (trust 0, rapport "harms"). The patient's response is generic wording with the name filled in.
- **Questions**: what has been happening (history), how they feel and think (mental state), observations and examination (vitals). History and mental state need trust 1 or more; after a rushed opening they get a short reply and a **repair** choice ("slow down and acknowledge how they are feeling") raises trust to 1. Observations need no trust.
- **Answers are each case's own chart text.** The Chart tab shows History, Mental state and Vitals only once heard; until then it says to ask at the bedside. Reason for review, referral label and current medications stay visible.
- **Debrief**: rapport minus 40 for a rushed opening (minus 20 if repaired), minus 10 for direct, praise for warm; reasoning minus 15 each if the first plan went in before the history or the mental state was heard.
- Data: `data/ward_rounds.json` `bedside` (validated by `WardRoundCatalog.validate_bedside`; without the block, the chart shows everything as before). State saved per case (`opening`, `asked`, `revealed`, `repaired`); replay clears it.
- Logged as pending in `docs/clinical_review_log.md` (generic communication wording; applies to approved cases too).

## Tests

`scripts/tests/test_ward_round_conversation.gd` (5). Full headless QA: game 406/0, audio 1720/0, QA 19/0/0, GLB 199/0, CH1_SEQUENCE_DONE, exit 0. Not tested on the Mac.

## Next

Case-specific bedside lines (each patient answering in their own words, voiced) would need written, reviewed lines per case.
