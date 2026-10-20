# Mac acceptance: player experience overhaul

The checks below cover the stacked player-experience pull requests (cast models, voiced dialogue, EHR order catalog, objective feedback, title screen, prologue, presentation states and milestones). Headless tests in a Linux container ran them; none of this has been looked at or listened to on a Mac yet. Cloud and headless runs are not visual or audio acceptance.

Hardware target: Apple Silicon MacBook Air, 8 GB.

## 1. Get a clean copy

Use a fresh clone on the internal disk, not the SSK external-drive copy.

```sh
cd ~/Developer
git clone https://github.com/biancaalexis132-png/ForensicWard_Game.git forensicward-pxo
cd forensicward-pxo
git checkout main   # #102 and #105–108 are merged
/Applications/Godot.app/Contents/MacOS/Godot --headless --path . --editor --import
python3 tests/qa/run.py --godot /Applications/Godot.app/Contents/MacOS/Godot
```

PR #109 repairs are merged into main. Use current main for journal/directory acceptance; the original `kilo/chapter1-vertical-slice` branch contains the pre-repair autoload and should not be used for this check.

The import step matters: a copy that has never been imported shows grey capsules instead of the cast models, which is the likely cause of the grey characters seen before.

## 2. Play

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path .
```

| Area | What to check | Pass when |
|---|---|---|
| Title | New Game, Continue, Settings, Quit; Chapter 1 art behind the menu; "Preparing the ward… / Ready." line | Buttons respond after "Ready." within a few seconds; Settings opens and Back returns to the title |
| Cast | Naomi, Voss, Rahman, Hale, Elias, Mara | Every one shows its 3D model. A magenta capsule labelled "DEV ERROR: missing 3D model" means a model failed to load: report it |
| Dialogue | Talk to Naomi; interview Elias with each authored choice | Your question plays first, then the narrator describes Elias (he never speaks). Space or Enter skips a line. No typed-question box. Subtitles match the voice and never overlap |
| Voices | Staff panels and story passages in Chapters 1-5 | Each speaker sounds like themselves; the narrator is the approved voice; nothing plays twice at once |
| Subtitles | Pause menu: speaker names, background box, size slider, voice volume | Each setting changes subtitles at once |
| EHR Orders | Open the EHR (J), Orders tab | Patient line, witnessed findings, assessment status; Details, Place order, Confirm or Cancel; status and history update; Medication and Laboratory listed as not available with the reason; no "fictional patient" or review labels |
| Journal and directory (#109) | In-game pause menu: Clinical Case Journal and Floor Directory; reopen each and press Esc | Both open, release the mouse, stop movement/clock and close cleanly. Title-screen Settings hides these buttons. An empty journal is expected until real documentation actions are wired; the directory is text, not a spatial map |
| Objectives | Complete "Report to the charge nurse" | One "Objective complete" banner with a quiet chime, then "New objective". Save, load: no repeat. Pause menu toggles hide the checklist, banners and chime |
| Recap | Finish Chapter 1 | The approved recap plays, then the end-of-chapter panel; closing it returns control |
| Performance | Activity Monitor during play | Memory stays well inside 8 GB; no stutter when a voice line starts |

## 3. Review-only pieces (need your approval before they play in the game)

```sh
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --cutscene-preview=cs_ch01_prologue
/Applications/Godot.app/Contents/MacOS/Godot --path . -- --milestone-preview=ms_ch1_first_assessment
```

- **Prologue** (`data/cutscenes/cs_ch01_prologue.json`, narration in `data/narrative/prologue_ch1.json`): five plates from the review-only Chapter 1 pilot, 1.5 s dissolves, narrator voice. To approve, set `mode` to `campaign`, `approved` to `true` and `trigger` to `{"kind": "new_game"}`, and add `"cs_ch01_prologue": "new_game"` to `OWNER_APPROVED_CAMPAIGN` in `tests/qa/test_cutscenes.py`. New Game then plays it once before the first objective.
- **Milestone** (`data/milestones.json`): a split-screen moment after "Choose a clinical action". To approve, set `approved` to `true`.

## 4. Report back

For each row, say pass or fail with a screenshot or a short note. Fails go to the matching pull request.
