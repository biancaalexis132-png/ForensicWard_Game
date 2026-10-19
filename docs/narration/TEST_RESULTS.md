# Narration verification — 19 October 2026

The owner subsequently approved the local Piper LJ Speech replacement sample. The production-media verification below supersedes the historical ElevenLabs blocker.

Implementation checkpoint: `d5a10ad782cbc43c72b0f9acccaf5308a5a602ba`, pushed on `codex/cutscene-narration-production`. Baseline main: `27798757a8e8844a7301910a4610d0ec5817a0d2`. No merge or artwork change.

Official Godot `4.7.stable.official.5b4e0cb0f` is used; its downloaded release ZIP was checked against the official SHA512 sums.

## Executed checks

- Every approved PNG independently hashed against the approval inventory: **36/36 identical**.
- Narration text audit: **39 authored tracks**, with no exact normalized matches to spoken gameplay lines in `data/narrative`. These comprise 36 defaults plus three ending alternatives; the neutral Chapter 5 p06 is caption-only recovery, leaving **38 intended voice files**.
- `git diff --check`: pass. Python authoring/import/packaging scripts compile.
- Python content JSON 6/0, audio manifest 4/0, cutscene contracts 6/0, music generation pipeline 3/0: pass during the production pre-checks. Audio manifest builder `--check` passes without new files; no unrecorded voice is represented as an imported asset.
- Standard `tests/qa/run.py` with Godot 4.7: import, pharmacology (0 failures), gameplay QA **19/0/0**, and GLB validation **168/0** completed. Its unchanged 150-second TestRunner limit then timed out. The standard runner itself did **not** pass.
- Separate game-suite execution with a 360-second cap: **280 passed / 0 failed**, exit 0. This includes the original 269 checks plus 11 narration regressions.
- Frozen-checkpoint verification: focused narration suite **11/0**, exit 0; full game suite **280/0**, exit 0. audio suite **336/0**, exit 0; Chapter 1 sequence reached `CH1_SEQUENCE_DONE` at 70.5 seconds, exit 0. No `SCRIPT ERROR`, `ERROR` or `FAIL` markers appeared in this frozen verification.

Narration regressions use a temporary real OGG playback stimulus. They verify exact panel bindings, the three mutually exclusive endings and ambiguous-state recovery, invalid cues, no gameplay-line reuse on narrator panels, caption-only operation with subtitles off, pause of voice/caption/watchdog, real audio completion plus tail, bounded stalled-voice recovery, skip at every Chapter 1 panel, replay/toggle, saved-state invariance, real save/load and replay from completed flags, reduced-motion transforms, and mapped input actions.

Initial cross-suite input/camera failures were reproduced and fixed in the new test cleanup: scenes unregister synchronously and the physics-frame test returns through an idle timer before later suites register input handlers. Existing tests were retained. The original all-panel recap test now runs in caption-only mode with the narration-aware duration; dedicated new tests cover audio timing. Empty narration cleanup no longer creates redundant speech-release fades.

## Local replacement production

Owner approval: “yes” to the 18-second Chapter 1 replacement sample, 19 October 2026. All production uses Piper LJ Speech through Sherpa-ONNX 1.13.8, speed 0.92. No ElevenLabs recording is shipped or mixed into the replacement narration. Exact model/settings/source hashes are recorded in the runtime voice metadata and per-clip provenance.

Final asset and runtime check results are recorded after generation below. The standard runner's 150-second cap remains unchanged; any extended suite run is reported separately. Headless playback validates state, timing and asset loading; it does not establish audible mix or Mac visual acceptance. Realistic cast integration remains unfinished.
