# Narrated chapter recaps — implementation and playback guide

**Status: approved local narrator production.** The owner approved the original writing, then approved the 18-second local replacement voice and pacing with “yes” on 19 October 2026. The production narrator is now Piper LJ Speech, consistently across all five chapters and endings; ElevenLabs is superseded. Narration approval is no longer pending. Clinical rules and character-model approval are separate and unchanged.

The current work extends the existing CutsceneDirector and AudioDirector; it does not replace either system or modify an illustration. Runtime captions and voice text live in `data/narration/recaps.json`. Exact panel scripts are in `docs/narration/CH01_SCRIPT.md` through `CH05_SCRIPT.md`; these supersede the historical draft mapping under `docs/narration_review/source_scripts/`.

## Placement

| Chapter | Trigger | Cutscene | Panels | Music |
|---|---|---|---:|---|
| 1 The Admission | chapter_completed(ch1) | cs_ch01_static_gn | 7 | mus_waiting_room |
| 2 The Missing Hours | chapter_completed(ch2) | cs_ch02_static_gn | 7 | mus_transition_unease |
| 3 Beneath the Hospital | chapter_completed(ch3) | cs_ch03_static_gn | 7 | mus_narrative |
| 4 The Official Record | chapter_completed(ch4) | cs_ch04_static_gn | 8 | mus_procedure |
| 5 Beyond the Lines | chapter_completed(ch5) | cs_ch05_static_gn | 7 | mus_compassion |

Measured voice totals are approximately 52 seconds (Chapter 1), 49 (Chapter 2), 50 (Chapter 3), 64 (Chapter 4), and 61 (Chapter 5, depending on ending). Panel tails add a few seconds; pause, skip and caption-only reading holds can change the total.

The existing completion panel is created underneath the recap. The recap owns mouse/keyboard input and pauses the world clock. On completion or skip, its single cleanup path exposes the normal completion panel; the player then chooses the next chapter. Chapter 5 returns to the campaign summary. Existing chapter-opening title cards remain separate and unvoiced. Never trigger a recap at an incomplete chapter slice or use narration to grant story progress.

## Player controls

- Esc / Skip: end the whole recap and restore the prior music context.
- Enter / Next: explicitly skip the rest of this panel, including its voice.
- P / Pause: freeze voice, subtitle clock and active-time watchdog; Resume continues.
- R / Replay: restart the recap without repeating gameplay events.
- V / Narration checkbox: enable or disable voice. Disabling preserves readable captions and music; enabling restarts the current panel so audio/caption clocks agree.
- Pause menu → Replay latest completed chapter recap: replay a completed chapter even after loading a save, using the saved story/ending flags.
- Pause menu → Narrate chapter recaps: persistent preference in the existing Settings config, independent of the save slot. Narration defaults on. Subtitles follow the existing subtitle preference while voice is playing; captions remain present when voice is disabled/unavailable.

## Endings and completed events

Main passes a read-only snapshot from ChapterDirector. The shared Chapter 5 p06 artwork uses exactly one variant:

| Ending | Required saved flags | Track |
|---|---|---|
| A: external review | ch5_ending_review + ch5_epilogue_review | nar_ch05_p06_a |
| B: restriction | ch5_ending_restricted + ch5_epilogue_restricted | nar_ch05_p06_b |
| C: continuing inquiry | ch5_ending_inquiry + ch5_epilogue_inquiry | nar_ch05_p06_c |

Missing or conflicting ending choices use neutral caption-only recovery. No random choice, unearned patient outcome or invented supernatural mechanism is asserted. Chapter 1's optional assessment/corroboration is described neutrally; chapter-completion gates support the later inspection/return/review descriptions. Narrator tracks cannot coexist with a gameplay `line_id` on the same panel. No gameplay dialogue is re-voiced in a recap.

Image mapping corrections include the Chapter 2 archive on p06, all eight Chapter 4 images in their actual order, and patient care on Chapter 5 p05 before the shared ending p06. The Chapter 3 pixels still say Ward Zero; the canonical runtime chapter name remains Beneath the Hospital. Incidental chart details in approved art never become canonical clinical evidence.

## Timing and recovery

Healthy voice holds the panel until actual audio completion plus 0.5 seconds. A manual Next is an explicit interruption. Subtitles use the playback position with output-latency compensation; the imported full-statement cue spans the measured clip, with matching per-panel SRT. Pausing does not spend watchdog time.

Missing voice or missing cue data uses captions and a hold of at least max(original panel duration, word count / 130 * 60 + 0.5 seconds), capped at 120 seconds. A stalled voice is stopped after measured length + 5 active seconds (maximum 120); the panel retains its readable caption time or a 0.5-second recovery tail before continuing. The whole-recap watchdog has an additional five seconds per panel plus ten seconds beyond its nominal duration. Every exit stops owned narration, clears subtitles, releases the speech duck and ends only the recap's music context. User bus volume preferences are not reset.

Save/load preserves chapter and ending flags through existing providers. The recap overlay is transient: loading cancels it and clears the old replay snapshot. It does not resume mid-word or re-fire completion. The pause-menu replay action reconstructs it from the loaded completed chapter. No save-schema migration is needed.

## Voice source and reproducibility

The approved replacement is **Piper LJ Speech US English female**, model `vits-piper-en_US-ljspeech-high`, run locally on CPU through **Sherpa-ONNX 1.13.8** at speed **0.92**, speaker 0, default noise settings. The owner heard Chapter 1 p01/p02 and approved this replacement before the remaining recordings were produced. No new voice cloning was performed. All chapters use this one model; the earlier ElevenLabs take is not mixed into production.

`audio/narration/LOCAL_VOICE_MODEL_CARD.md` retains the upstream attribution (LJ Speech public-domain dataset). `data/narration/recaps.json` records the download URL, model SHA-256, settings and approval. `audio/narration/provenance.json` records source WAV and shipped OGG hashes, measured durations and attribution per clip. Historical `generation_records.json` describes the abandoned ElevenLabs attempt only; it is not the source of shipped audio.

The queue contains **38 recordings**: 36 panels minus neutral Chapter 5 p06 plus three exclusive ending clips. Neutral p06 remains caption-only recovery when saved ending flags are absent or inconsistent. Each finished panel has an OGG, SRT and measured full-statement cue. The shared Chapter 5 artwork remains unchanged.

To reproduce (weights and Python dependencies are authoring-only and stay outside the project):

```
python3 -m pip install -r tools/narration/requirements-local.txt
# Download/extract voice.source_url from data/narration/recaps.json externally.
python3 tools/narration/generate_local.py /path/to/vits-piper-en_US-ljspeech-high /path/to/wavs
python3 tools/narration/import_recordings.py /path/to/wavs
python3 tools/audio/build_manifest.py
python3 tools/narration/check_delivery.py
# After committing validated assets:
python3 tools/narration/package_delivery.py /path/to/ForensicWard_Narrated.zip
```

The importer encodes mono OGG at 44.1 kHz with libvorbis q5, loudness target -18 LUFS/-2 dBTP, and measures actual duration. Subtitles display each complete panel statement from clip start to clip finish; they are not word-by-word karaoke. Generation can vary slightly on rerun, so shipped hashes identify the delivered take. Gameplay is fully offline and requires no voice service or Python installation.

## Verification and final release gate

Run existing suites unchanged except the prior recap-duration assertion now uses the director's narration-aware duration; all prior playback checks remain. The all-panel visual test explicitly covers the required caption-only mode; the new suite separately exercises real audio timing. Additional `test_narration.gd` checks real audio playback using a temporary test-only stimulus, ending variants, paused watchdog, skip at every panel, caption-only operation, toggle/replay, real save/load, progression/input ownership and reduced motion. The test stimulus is deleted afterward and is never shipped as narration.

The mandatory `check_delivery.py` must pass with **38/38 recordings**, measured subtitles and unchanged approved artwork before a ZIP can be called the final narrated delivery. Audible production voice/mix and Forward+/Metal appearance/performance still require Mac review. Realistic 3D cast models are still review-only; normal gameplay retains placeholders. This narration work does not claim to finish or approve those models.

Keep the production branch and PR unmerged. The owner remains responsible for merging after review.
