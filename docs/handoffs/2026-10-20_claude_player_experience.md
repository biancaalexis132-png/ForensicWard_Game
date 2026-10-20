# Player experience overhaul: Claude Code handoff, 2026-10-20

Requested by Bi. Five stacked draft pull requests to `main`, merged in order. Nothing was merged by the agent. Headless Linux runs only; nothing was looked at or listened to on a Mac.

## Stack

| PR | Branch | Covers |
|---|---|---|
| #102 | `claude/player-experience-overhaul` | P1 cast models (DEV ERROR capsule for a missing model), placeholder labels removed, "fictional patient" moved from the EHR to the title and pause menus |
| #105 | `claude/player-experience-dialogue` | P2 every authored choice voiced: the psychiatrist's line, then the response; Elias's response narrated (never spoken); story advances once; subtitle and voice-volume settings; about 600 Kokoro-82M (Apache-2.0) clips plus the approved Piper narrator; QA runner and CI time limits raised |
| #106 | `claude/player-experience-ehr-orders` | P3 `data/order_catalog.json` drives the EHR Orders tab (details, place, confirm, cancel, status, history); medication and laboratory listed as not available with a reason; no invented outcomes |
| #107 | `claude/player-experience-objectives` | P5 objective checklist, one "Objective complete" banner with a quiet chime, "New objective" notice; derived from ChapterDirector, save-aware, three toggles |
| #108 | `claude/player-experience-title-prologue` | P4 title (New Game, Continue, Settings, Quit, art, bounded preload), review-only prologue `cs_ch01_prologue`; P7 presentation states in Main; P6 review-only split-screen milestone; Mac checklist |

## Resume here

1. `git fetch origin --prune`, then read the newest `docs/AI_HANDOFF.md` entry; it records SHAs and the full QA result for each branch.
2. If Bi asks for changes on a lower PR, fix it on that branch and restack: `git rebase --update-refs` from the top branch, then push every branch with `--force-with-lease` (these are our own branches).
3. Merge order: #102, B, C, D, E. Each PR's base is `main`, so a lower PR's commits also appear in the higher PRs' diffs until the lower one merges.

## Approvals still needed (none inferred)

- Elias's spoken interview questions and the narrated responses (`data/narrative/interview_ch1.json`, `voice_ch1..5.json`).
- The replacement return text in `data/dialogue.json`.
- Order catalog wording (`data/order_catalog.json`); recorded as pending in `docs/clinical_review_log.md`.
- The new Kokoro character voice profiles.
- The prologue: plates reused from the review-only pilot and five narrator lines (`data/narrative/prologue_ch1.json`). Approve by following `docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md` §3.
- The milestone `ms_ch1_first_assessment` (`data/milestones.json`, set `approved` to `true`).
- Using Chapter 1 recap page 1 (approved art, unchanged) as the dimmed title background.

## Known limits

- The full headless suite now takes about 7–8 minutes; the runner's TestRunner cap is 900 s and the CI job's is 20 min.
- Grey characters on the Mac most likely come from an un-imported copy or one older than PR #98; a clean clone plus `--editor --import` fixes it (Mac checklist §1).
- The prologue and milestone stay off in the campaign until approved.

## Mac acceptance

`docs/MAC_ACCEPTANCE_PLAYER_EXPERIENCE.md` (clean clone, import, QA, play, previews).
