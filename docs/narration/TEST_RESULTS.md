# Narration implementation validation — 19 October 2026

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

## Media and release gate

`tools/narration/check_delivery.py` currently reports **0/38 imported voices**, 36 approved images intact, and rejects final delivery. The packaging command was also executed and refused to create a final ZIP, as required by the missing-media gate. One production clip exists remotely, Chapter 2 p04 (`uqvmiHtJM7fBjQYYjviy`, 6.037 seconds), with its session/node IDs in `audio/narration/generation_records.json`. The remaining 37 nodes are confirmed not run. Later first-start attempts on previously unstarted nodes were also rejected with provider HTTP 429; completed media was not regenerated.

A fresh download of the completed clip failed at the proxy with HTTP 403. The live environment status still reports only api.github.com allowed, revision 9; the owner's saved storage-host edit is not reflected in the active runtime. No production MP3/OGG/SRT has been imported, and production narration listening or mix approval is not claimed.

The runtime works through its caption/music recovery path while media is unavailable. Mac Forward+/Metal visual/audio/performance checks and finished realistic character integration remain pending. The normal campaign uses placeholders; review-only cast candidates do not establish finished realistic gameplay.

Local verification logs are `/workspace/work/production-qa.log`, `/workspace/work/narration-verified-game.log`, and `/workspace/work/narration-checkpoint-verification.log`. These disposable paths are not a substitute for this pushed summary. Hosted CI success is not claimed.
