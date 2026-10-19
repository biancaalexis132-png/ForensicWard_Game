# The Forensic Ward — narrated Chapters 1–5

This source project includes the existing campaign, all 36 unchanged approved recap illustrations, 38 offline narration recordings and matching timed subtitle files. Chapter 5 has three exclusive ending narrations using the shared artwork. The owner approved the replacement Piper narrator and pacing on 19 October 2026. The earlier ElevenLabs production attempt is superseded.

## Play

1. Extract the entire ZIP.
2. Install **Godot 4.7 stable, standard build**.
3. Import the extracted `project.godot`, wait for asset import, and run the project (F6 runs only the selected scene; use F5 for the game).
4. Complete a chapter normally. Its illustrated narrated recap plays, followed by the normal chapter-completion panel, then the next-chapter choice. Chapter 5 leads to the campaign summary.

This is a Godot source project, not a signed macOS application. No speech service, Python installation, API key or internet connection is needed during gameplay. Chapters 2–5 remain provisional content. Normal gameplay character models remain placeholders; realistic cast drafts are a separate unfinished workstream. Mac visual/performance acceptance remains pending.

## Recap controls

- **Esc / Skip:** finish the recap.
- **Enter / Next:** advance one panel, interrupting its narration.
- **P / Pause:** pause or resume narration and panel timing.
- **R / Replay:** restart the recap.
- **V / Narration:** toggle narration; captions and music remain functional when disabled.
- The pause menu also provides a narration preference and replay of the latest completed chapter recap.

## Review without playing

Open `NARRATION_REVIEW.html` after extraction. Each illustration has its matching narration text and an audio player. Chapter 5 panel 6 offers Ending A, B and C separately for review; the game selects only the ending supported by saved story flags.

## Placement and production records

- `docs/NARRATED_CUTSCENES.md`: exact placement table, ending flags, subtitles, timing/recovery, accessibility and save/load behavior.
- `docs/narration/CH01_SCRIPT.md` through `CH05_SCRIPT.md`: panel scripts.
- `audio/narration/provenance.json`: voice attribution, settings, recording hashes and measured durations.
- `docs/narration/TEST_RESULTS.md`: executed verification and remaining review limits.

The production branch is deliberately unmerged. Narrator approval does not imply approval of character models or clinical rules.
