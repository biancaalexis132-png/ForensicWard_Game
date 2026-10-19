# Narrated chapter recaps — implementation and playback guide

**Status: implementation candidate, not final delivery.** The owner approved the Chapter 1 narrator, pacing and writing with “i approve of the narration. Continue” on 19 October 2026. Narration approval is no longer pending. Clinical rules and character-model approval are separate and unchanged.

The current work extends the existing CutsceneDirector and AudioDirector; it does not replace either system or modify an illustration. Runtime captions and voice text live in `data/narration/recaps.json`. Exact panel scripts are in `docs/narration/CH01_SCRIPT.md` through `CH05_SCRIPT.md`; these supersede the historical draft mapping under `docs/narration_review/source_scripts/`.

## Placement

| Chapter | Trigger | Cutscene | Panels | Music |
|---|---|---|---:|---|
| 1 The Admission | chapter_completed(ch1) | cs_ch01_static_gn | 7 | mus_waiting_room |
| 2 The Missing Hours | chapter_completed(ch2) | cs_ch02_static_gn | 7 | mus_transition_unease |
| 3 Beneath the Hospital | chapter_completed(ch3) | cs_ch03_static_gn | 7 | mus_narrative |
| 4 The Official Record | chapter_completed(ch4) | cs_ch04_static_gn | 8 | mus_procedure |
| 5 Beyond the Lines | chapter_completed(ch5) | cs_ch05_static_gn | 7 | mus_compassion |

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

## Voice provenance and production blockers

Approved voice: ElevenLabs **Shawn – Calm & Grounded**, `d8XDgkC47nxEyrCyckjI`; model `eleven_multilingual_v2`, provider default voice settings and MP3 44.1 kHz/128 kbps. No cloned voice was created. The source queue has 38 recordings: 36 panels minus the neutral Chapter 5 p06 plus three exclusive ending clips. The neutral p06 still has a caption recovery script.

Flow: https://elevenlabs.io/app/flows/yQMcIpjsr8E8Q7HI00l7

`audio/narration/generation_records.json` maps every track to its provider node. One production recording completed (Chapter 2 p04); remaining starts were rejected with HTTP 429 or remain prepared. No completed recording was regenerated. At the latest live check the active environment still allowed only api.github.com, despite the owner's saved network edit; a fresh Google Storage download was denied by the proxy with HTTP 403. The completed recording is not yet imported. Do not mark the voice delivery complete or silently replace the approved voice.

After the provider/network issue is resolved, retrieve existing completed generations by their recorded IDs. Generate only nodes confirmed not to have started; never blindly rerun the batch or charge for another completed take. Download each as `<track_id>.mp3`. Import with:

```
python3 tools/narration/import_recordings.py /path/to/downloads
python3 tools/audio/build_manifest.py
python3 tools/narration/check_delivery.py
# After committing the validated media and source tree:
python3 tools/narration/package_delivery.py /path/to/ForensicWard_Narrated.zip
```

The importer encodes mono OGG 44.1 kHz with libvorbis q5 and loudness target -18 LUFS/-2 dBTP, measures actual duration, creates exact full-statement subtitle cues/SRT, and records source/output SHA-256 and settings. It does not generate replacement voices. Runtime voice is offline; no API calls or inference are needed during play. Scope remains the owner's private/personal project; commercial rights are not independently verified.

## Verification and final release gate

Run existing suites unchanged except the prior recap-duration assertion now uses the director's narration-aware duration; all prior playback checks remain. The all-panel visual test explicitly covers the required caption-only mode; the new suite separately exercises real audio timing. Additional `test_narration.gd` checks real audio playback using a temporary test-only stimulus, ending variants, paused watchdog, skip at every panel, caption-only operation, toggle/replay, real save/load, progression/input ownership and reduced motion. The test stimulus is deleted afterward and is never shipped as narration.

The mandatory `check_delivery.py` must pass with **38/38 recordings**, measured subtitles and unchanged approved artwork before a ZIP can be called the final narrated delivery. Audible production voice/mix and Forward+/Metal appearance/performance still require Mac review. Realistic 3D cast models are still review-only; normal gameplay retains placeholders. This narration work does not claim to finish or approve those models.

Keep the production branch and PR unmerged. The owner remains responsible for merging after review.
