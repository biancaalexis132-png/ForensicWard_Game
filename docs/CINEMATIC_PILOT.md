# Animated cinematic pilot: Naomi handover

First production blocking pass, built from main `fbd1544` in response to the owner's request for movie-like animated cutscenes matching the gameplay cast.

Open `scenes/cinematic/NaomiHandover.tscn` in Godot 4.7 and Run Current Scene (F6; Cmd+R on Mac). Escape ends the scene. For automated playback:

```
Godot --headless --path . res://scenes/cinematic/NaomiHandover.tscn -- --exit-when-done
```

This is a standalone review scene, not yet a campaign replacement. It stages the actual Naomi gameplay model (resolved from the shared cast catalogue) in the existing nursing station, with five authored camera shots, tighter dialogue close-ups, slow lens pushes, warm key/cool fill character lighting, letterboxing, resolution-aware subtitles, the existing five handover recordings, blinking, approximate visemes and Naomi's existing line-specific acting cues. The player remains off-camera; no new protagonist likeness is invented. No new clinical lines, assets or approvals are introduced. All assets retain existing provenance and licences.

Shot data: `data/cinematics/naomi_handover.json`. Dialogue remains owned by the existing narrative/audio catalogue. No save or story progression is written by the preview.

This is an animatic/blocking candidate, not final movie quality. Close-up likeness, room placement, lighting, framing, performance and sound require rendered and Mac review. Existing speech animation uses text-timed approximate visemes, not phoneme alignment or motion capture.

Next production work:

1. Review the actual staged scene on the Mac; correct composition and actor/prop placement.
2. Refine shot timing and performance; author transitions, pauses, additional expressive animation and precise lip sync.
3. Integrate an accepted version at the actual Chapter 1 handover with input/camera restoration, cancellation/load cleanup and no duplicate dialogue or progression.
4. Add further scenes using the same cast catalogue: Elias assessment, Voss briefing, first Ward Zero entry and finale variants. Preserve approved story lines and evidence/clinical separation.
5. Produce rendered video previews after the scene looks right; validate final cinematics on target Mac hardware.

## Local Mac / SSK continuation

The owner requested moving game files to SSK to free laptop space. Finder confirms a volume named `SSK Drive` is connected to the Mac, but this cloud session cannot access it or control Finder. No transfer or deletion was performed. The last recorded Mac checkout is `~/Developer/forensicward-release`; inspect it and the destination before copying, preserve any uncommitted work and saves, verify the external copy before removing the internal one, then resume this branch. Do not interpret the request as permission to move unrelated personal files.

The new local session should read `AGENTS.md`, current status and the latest handoff, then fetch and inspect `codex/cinematic-naomi-pilot` / draft PR #133. Review the cinematic on Metal before campaign integration.
