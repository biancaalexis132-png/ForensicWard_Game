# AI handoff

> Overwrite this file at every handoff (see `AGENTS.md` §2). Earlier handoffs remain in Git history.

## Current handoff

| | |
|---|---|
| Agent | Claude Code (cloud session, Linux container, no GPU) |
| Date | 2026-10-17 |
| Workstream | Audio production (voices, SFX, adaptive audio engine, AI music pipeline) |
| Branch | `claude/quirky-ptolemy-6j16b7`, assigned by the session harness. The owner asked for `claude/audio-production`; treat this branch as that workstream. |
| Latest verified code commit | `3e3f287269f30aae21a50ad604f42990e15c7f79` (pushed). This handoff file is in the commit after it. |
| Base | `main` at `8e64eaf` (merge of PR #3, which contained `c58efc9`: AudioDirector + Chapter 1 audio) |
| Open PRs | #1 `claude/sprint-01-foundation` (gameplay foundation, unmerged, conflicts with `main`; see `docs/PROJECT_STATUS.md`). The PR for this branch is opened right after this handoff. |

### Done in this session (all on GitHub)

1. **Merged to `main` (PR #3):**
   - `systems/audio/AudioDirector.gd` autoload: location ambience with day/night variants, room reverb, music states (calm/tense crossfade by intensity), 2D/3D one-shots, dialogue playback that drives `EventBus.subtitle_shown`/`subtitle_cleared`, music and ambience ducking under dialogue, volume settings per bus, `reduce_startling_audio`, `music_intensity_cap`, and narrative events from `audio/cues.json`.
   - Three new signals in `autoload/EventBus.gd`.
   - Chapter 1 assets: the corridor loop, secure door, pager, unease transition, five Kokoro lines for the Bennett handover, and the intercom announcement.
   - `data/narrative/chapter1.json`, the manifest, the generators, `tests/audio/`, the `scenes/audio/Ch1AudioSequence.tscn` demo, and the QA runner hooks.
2. **On this branch, not merged:**
   - `tools/music_ai/`: the ACE-Step 1.5 installer, Mac checker, server launcher, `score.json` plan (10 tracks plus 3 main-menu directions), and the `generate_music.py` client (generate → verify → QA → approve/import).
   - `tests/music_ai/` (mock server).
   - Docs: `docs/AUDIO.md`, `docs/MUSIC_AI_MAC_GUIDE.md`, `AGENTS.md`, `CLAUDE.md`, `docs/PROJECT_STATUS.md`, this file, and edits to README and TESTING.
   - The commit message of `3e3f287` says "AudioDirector gains music states…". Those engine changes actually landed earlier, in `c58efc9`/PR #3; `3e3f287` itself only adds tools, tests and docs.

### Test results at `3e3f287` (local, Godot 4.7 stable Linux headless, `python3 tests/qa/run.py`)

| Suite | Result |
|---|---|
| `tests/qa/test_json.py` | 4 tests OK |
| `tests/qa/test_audio_manifest.py` | 3 tests OK |
| `tests/music_ai/test_generate_music.py` (mock ACE-Step) | 2 tests OK |
| `tests/TestPharmacology.tscn` | PASSED, 0 failures |
| `tests/qa/TestQA.tscn` | 16 passed, 0 failed, 2 skipped (no player controller on `main`) |
| Boot smoke test | Boot OK |
| `tests/audio/TestAudio.tscn` | 92 passed, 0 failed |
| `Ch1AudioSequence` (`--exit-when-done`) | All beats in order, done at 61.4 s |
| `tools/audio/build_manifest.py --check` | Up to date |

GitHub-hosted CI on this branch has **not** been observed. Check the PR's checks.

### Not done, blocked, or unverified

- **AI music: blocked on the owner's Mac.** No ACE-Step audio exists anywhere. The container cannot reach Hugging Face, ModelScope or files.acemusic.ai, and it has no GPU. The milestone stays open until real files are generated, listened to and approved.
- No sound has been reviewed by ear. Every manifest entry is `pending_listening_review`.
- The ACE-Step model-weight license has not been read, because the model card was unreachable. The code is MIT.
- `generate_music.py` does not yet support ACE-Step reference-audio, cover or repaint modes, which are needed to carry the approved main theme into other cues.
- Remaining SFX list: footsteps per surface (`footstep()` already exists in `synth_sfx.py`), standalone badge reader, computer UI, elevator, distant staff conversations, historic intercom static bed, electrical disturbances, Ward Zero anomaly set (triggered by events only), nursing-station and night ambience beds.
- Only one protagonist voice profile exists, although the protagonist is customizable.

### Local-only files (not on GitHub, unavailable to remote agents)

- Kokoro model files: `tools/audio/models/kokoro-v1.0.onnx` and `voices-v1.0.bin`, both ignored by Git. Download URLs and SHA-256 hashes are in `docs/AUDIO.md`.
- ACE-Step checkout and weights: `tools/music_ai/ACE-Step-1.5/`, which will exist only on the Mac after the installer runs.
- Generated candidates: `tools/music_ai/output/` (ignored by Git). Only approved tracks are committed, through LFS.
- The Godot 4.7 binary and Python virtual environments used here were in the session scratchpad and are gone.

### Next tasks, in order

1. **Owner, on the Mac:**
   ```
   bash tools/music_ai/check_mac.sh
   bash tools/music_ai/install_acestep_mac.sh
   bash tools/music_ai/start_server.sh
   python3 tools/music_ai/generate_music.py generate --first-deliverable
   ```
   Then listen to `tools/music_ai/output/main_menu_*/*_preview.ogg` and choose a direction. Done when three real WAV files and their `qa.json` files exist.
2. **Any agent, after the owner picks:** run `generate_music.py approve <id> --approved-by "<owner>"`, commit `audio/music_ai/` through LFS, add `"main_menu"` music-state use to the main-menu scene, and run `python3 tests/qa/run.py`.
3. **Any agent:** add reference-audio support to `generate_music.py` (multipart `/release_task` with `reference_audio`, following `docs/en/API.md` in ACE-Step), so the approved theme seeds the other nine tracks. Extend `tests/music_ai/test_generate_music.py` so the mock asserts that the file upload happened.
4. **Any agent (no Mac needed):** add the remaining procedural SFX to `tools/audio/synth_sfx.py`, add cues and events to `audio/cues.json`, run `build_manifest.py`, and add assertions to `tests/audio/TestAudio.gd`. Anomaly cues must be startle-flagged and event-only.
5. **Gameplay owner:** follow the PR #1 integration plan in `docs/PROJECT_STATUS.md` before merging PR #1.

### How to verify this handoff

```sh
git fetch origin
git log --oneline -3 origin/claude/quirky-ptolemy-6j16b7     # expect the handoff commit on top of 3e3f287
python3 tests/qa/run.py --godot <path to Godot 4.7>
```
