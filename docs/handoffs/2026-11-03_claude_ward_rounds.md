# Ward rounds: labs and medication plans gate each chapter — Claude Code handoff, 2026-11-03

Requested by Bi on 2026-11-03: "medications and labs should work as a component of progressing in the game based on patient presentation; you should choose the correct medication treatment plan/labs to order. There should be multiple patients to evaluate to progress through the game." This answers #113's open "medication and lab orders" decision.

Branch `claude/ward-rounds`, started from `claude/playtest-fixes` (draft PR #113, unmerged). Draft PR to `claude/playtest-fixes`. Nothing merged by the agent. Independent of `claude/cast-animation` (#114).

## What it does

- Each chapter admits two ward-round patients (ten in all). They stay on the ward in later chapters.
- EHR top bar: **Ward round (N to review)** opens the ward-round screen: patients on the left; Chart, Labs and Plan tabs; the attending's reply and **Submit to attending** always in view.
- Labs: order from a 14-item catalog; the case's qualitative result shows at once (colour by normal / abnormal / critical).
- Plan: continue / reduce / hold / stop for each current medication, medications to start, interventions.
- The attending accepts the plan, or asks for a revision with a reason per item: a missing required lab, an unsafe or not-indicated item, a missing must-include item, or an item chosen before the lab it needs. Helpful labs not ordered and unneeded labs are noted only. Resubmit as often as needed; an accepted plan is locked.
- A chapter cannot close (night sign-out, or a story choice that sets `chapter_complete`) until its patients have accepted plans. The notice names them. The day hand-over is not gated.

## Clinical governance

- All content is `PENDING_PSYCHIATRIST_REVIEW` (catalog and every case). No doses, levels or numeric thresholds.
- Pending cases play only in the prototype build, with a draft badge; each submission raises `clinical_review_flagged("ward_round_draft", …)`. In the validated build they are hidden and never gate a chapter.
- Logged as pending in `docs/clinical_review_log.md`. Review document for Bi with every case and answer key: https://claude.ai/artifact/8RohfXYScnpVj4pfMkedXR (one open question: Lindqvist transfer vs. ward cardiac monitoring).

## Files

| Area | Paths |
|---|---|
| Data | `data/ward_rounds.json` |
| Rules (validation, judging) | `scripts/clinical/WardRoundCatalog.gd` |
| State, admission, gate, save provider `ward_rounds` | `scripts/clinical/WardRounds.gd` (autoload, one line in `project.godot`) |
| Screen | `scripts/ui/WardRoundScreen.gd`, `scenes/ui/WardRoundScreen.tscn`; routed in `Main.gd`; button in `EHRScreen.gd` |
| Gate | `ChapterDirector.sign_out` and `_on_story_option_selected` |
| Tests | `scripts/tests/test_ward_rounds.gd` (9); `TestCase.before_each` sets `WardRounds.enforce_gate = false` (documented in `docs/TESTING.md`) |
| Capture | `tools/godot/CaptureWardRound.tscn` → EHR button, chart, labs, plan sent back, plan accepted |

## Not done / limits

- Not looked at on the Mac.
- No in-game time cost for labs or plans; results return at once.
- Cases are not tied to the story's patients or rooms; they are chart-only (no 3D patient).
- Answer keys need Bi's approval or corrections before they count as approved content.

## Resume here

1. `git fetch origin --prune`; read the newest `docs/AI_HANDOFF.md` entry.
2. Corrections from Bi go in `data/ward_rounds.json`; `test_ward_rounds.gd` checks every case still has an accepted answer and every wrong choice is sent back. Record any approval in `docs/clinical_review_log.md` and set that case's `clinical_review_status` to `APPROVED` only on Bi's explicit word.
