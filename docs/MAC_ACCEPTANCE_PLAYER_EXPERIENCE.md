# Mac acceptance: player experience overhaul

Updated 2026-10-20 for `codex/environment-finish`, stacked on `codex/gameplay-completion`. PR #104 repairs are already on main through #109. This candidate adds chart-backed journal entries, the current-floor spatial map, optional protagonist profile, Continuing Practice engineering and environment candidates. Automated Linux and software-rendered previews do not establish Mac visual, audio or performance acceptance.

Hardware target: Apple Silicon MacBook Air, 8 GB.

## 1. Get a clean copy

Use a fresh clone on the internal disk, not the SSK external-drive copy.

```sh
cd ~/Developer
git clone https://github.com/biancaalexis132-png/ForensicWard_Game.git forensicward-pxo
cd forensicward-pxo
git checkout codex/environment-finish
git rev-parse HEAD   # record this exact revision with the report
python3 tools/qa/mac_acceptance.py --godot /Applications/Godot.app/Contents/MacOS/Godot
```

The collector imports assets, runs standard QA and writes `work/mac-acceptance/report.json` plus `qa.log`. It checks that it is running on macOS; visual/listening acceptance remains pending even when automated QA passes. The import step matters: a copy that has never been imported shows grey capsules instead of the cast models, which is the likely cause of the grey characters seen before.

PR #109 repairs are merged into main. Do not use the original pre-repair `kilo/chapter1-vertical-slice` branch for acceptance.

## 2. Play

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --acceptance-perf
```

| Area | What to check | Pass when |
|---|---|---|
| Title | New Game, Customize new psychiatrist, Continue, Settings, Quit; Chapter 1 art behind the menu; "Preparing the ward… / Ready." line | Buttons respond after "Ready." within a few seconds; Settings opens and Back returns to the title |
| Cast | Naomi, Voss, Rahman, Hale, Elias, Mara | Every one shows its 3D model. A magenta capsule labelled "DEV ERROR: missing 3D model" means a model failed to load: report it |
| Dialogue | Talk to Naomi; interview Elias with each authored choice | Your question plays first, then the narrator describes Elias (he never speaks). Space or Enter skips a line. No typed-question box. Subtitles match the voice and never overlap |
| Voices | Staff panels and story passages in Chapters 1-5 | Each speaker sounds like themselves; the narrator is the approved voice; nothing plays twice at once |
| Subtitles | Pause menu: speaker names, background box, size slider, voice volume | Each setting changes subtitles at once |
| EHR Orders | Open the EHR (J), Orders tab | Patient line, witnessed findings, assessment status; Details, Place order, Confirm or Cancel; status and history update; Medication and Laboratory listed as not available with the reason; no "fictional patient" or review labels |
| Objectives | Complete "Report to the charge nurse" | One "Objective complete" banner with a quiet chime, then "New objective". Save, load: no repeat. Pause menu toggles hide the checklist, banners and chime |
| Recap | Finish Chapter 1 | The approved recap plays, then the end-of-chapter panel; closing it returns control |
| Performance | Activity Monitor during play | Memory stays well inside 8 GB; no stutter when a voice line starts |

Additional acceptance for this candidate:

| Area | What to check | Pass when |
|---|---|---|
| Journal | Sign a real EHR note and place an existing referral; open Case journal from Pause | Each appears once; note text is literal, save/load retains it, journal does not modify chart or Evidence board |
| Map | Open Map from Pause, walk between permitted rooms, revisit after save/load | Current floor geometry, room numbers, player/heading, real doors and EHR locations agree; restricted floors stay hidden |
| Protagonist | Customize from title and Pause; confirm, cancel, save/load | Optional fields and portrait choices persist; cancel discards edits; signed notes keep the author's name at signing; competence/access remain unchanged |
| Continuing Practice | Open worklist before and after campaign completion | Pending clinical content cannot enter census or interviews. After explicit activation approval, acceptance needs the five-encounter real chart/interview loop, saves between encounters and unresolved-task sign-out checks |
| Environment | Walk ground floor and travel to research/sublevel; run standalone review below | No outdoor mesh/collider leaks into another level; surfaces and glass remain legible; no flicker, missing textures, unexpected camera takeover or collisions |

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . res://scenes/review/EnvironmentReview.tscn
```

Review scene: 1 campus, 2 apartment, 3 facade; WASD/mouse; Escape exits. It does not instantiate or save a campaign.

For performance, enable the existing Pause → “Diagnostics: log zone performance”, play the ground-to-research round trip ten times and keep `user://perf_log.csv` with the report. The launch command writes `user://acceptance_perf.csv` once per second with a bounded 600-frame rolling p95 and worst CPU frame interval, memory, zone and pause state. This measures CPU frame intervals, not GPU time; preserve the CSV and distinguish paused/menu rows. Record Activity Monitor memory, renderer, screen resolution and power mode; do not infer target-device performance from Linux. Test Cmd-Tab, mouse recapture, pause, voice skip and resume with headphones and speakers.

## 3. Review-only pieces (need your approval before they play in the game)

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cutscene-preview=cs_ch01_prologue
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --milestone-preview=ms_ch1_first_assessment
```

- **Prologue** (`data/cutscenes/cs_ch01_prologue.json`, narration in `data/narrative/prologue_ch1.json`): five plates from the review-only Chapter 1 pilot, 1.5 s dissolves, narrator voice. To approve, set `mode` to `campaign`, `approved` to `true` and `trigger` to `{"kind": "new_game"}`, and add `"cs_ch01_prologue": "new_game"` to `OWNER_APPROVED_CAMPAIGN` in `tests/qa/test_cutscenes.py`. New Game then plays it once before the first objective.
- **Milestone** (`data/milestones.json`): a split-screen moment after "Choose a clinical action". To approve, set `approved` to `true`.

Open `docs/presentation_review.html` locally in a browser for the exact prologue plates/narration, milestone panels, all chapter voice clips and candidate screenshots. It works offline and records no approval. Rebuild with `python3 tools/qa/build_presentation_review.py` after changing source assets/text. The title's dimmed recap background, newer return-to-patient wording in `data/dialogue.json` and order catalog wording in `data/order_catalog.json` also require an explicit decision; existing campaign/cast approval does not cover these later additions.

Record decisions separately for: prologue plates and narration; milestone; newer Kokoro voice profiles and chapter interview/narration wording; title background; return text; order catalog wording; environment candidate appearance. The Jordan activation packet is a separate clinical review at `docs/CP001_ACTIVATION_REVIEW.md`. No pending flag may be changed solely because this checklist was run.

## 4. Report back

For each row, record PASS / FAIL / NOT TESTED with a screenshot or a short note. Attach `report.json`, `qa.log` and both performance CSVs to the candidate PR. Record the exact commit and separate presentation approval decisions. Actual Mac execution remains NOT RUN until this evidence is supplied; no connected Mac or SSK volume is available in the cloud workspace.
