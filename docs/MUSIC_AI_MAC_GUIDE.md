# AI music on the Mac with ACE-Step 1.5

This guide produces the game's AI-generated score with [ACE-Step 1.5](https://github.com/ACE-Step/ACE-Step-1.5) on an Apple Silicon Mac, using its native **MLX** backend. The pipeline is separate from the procedural SFX and Kokoro voices, and it never overwrites them.

**Status:** this has not been run yet. The scripts were written against ACE-Step commit `ca1e85fe` (29 Aug 2026), using its documented macOS launchers and REST API, and the Godot import path was tested with a mock server. ACE-Step itself has not been executed, because the build container is a GPU-less Linux machine and both Hugging Face and ModelScope are blocked from it. The AI-music milestone stays **open** until real ACE-Step files have been generated, listened to and approved.

## 1. Requirements

| | Minimum | Recommended |
|---|---|---|
| Chip | Apple Silicon (M1 or later) | M2 Pro / M3 / M4 or later |
| Memory | 16 GB (8 GB: use the 0.6B LM, see below) | 32 GB or more |
| macOS | 14 Sonoma | latest |
| Free disk | 30 GB | 50 GB |
| Tools | Xcode command line tools, Homebrew, git, ffmpeg | git-lfs |

Check everything without installing anything:

```sh
cd ~/Documents/ForensicWard_Game          # your clone
bash tools/music_ai/check_mac.sh
```

The script reports your chip, memory, macOS version, free disk, tools, whether Hugging Face and ModelScope are reachable, which model folders exist, and whether the API server is running.

## 2. Install (one time)

```sh
xcode-select --install                     # if check_mac.sh asked for it
brew install ffmpeg git-lfs uv && git lfs install
bash tools/music_ai/install_acestep_mac.sh
```

The installer:

1. Clones ACE-Step 1.5 into `tools/music_ai/ACE-Step-1.5/` (ignored by Git) and checks out the pinned commit. Use `ACESTEP_REF=main` to try the latest version instead.
2. Runs `uv sync` to build ACE-Step's own Python 3.11/3.12 environment, including `mlx` and `mlx-lm`. It then confirms that `import mlx.core` works.
3. Runs ACE-Step's `acestep-download`, which fetches the main model from Hugging Face and falls back to ModelScope. The main model includes the `acestep-v15-turbo` DiT, the VAE, the `Qwen3-Embedding-0.6B` text encoder and the `acestep-5Hz-lm-1.7B` planner LM.
4. **Verifies the download:** every model folder must contain weight files, and each `.safetensors` header must parse, which catches truncated downloads.

For a Mac with 8 to 16 GB of memory, add the smaller planner model:

```sh
LM_MODEL=acestep-5Hz-lm-0.6B bash tools/music_ai/install_acestep_mac.sh
```

ACE-Step also publishes a ready-made macOS package at <https://files.acemusic.ai/acemusic/mac/ACE-Step-1.5.zip>. You can extract it into `tools/music_ai/ACE-Step-1.5/` instead. The launcher detects its embedded Python automatically.

## 3. Start the API server

In terminal 1, leave this running:

```sh
bash tools/music_ai/start_server.sh
# smaller LM:  LM_MODEL_PATH=acestep-5Hz-lm-0.6B bash tools/music_ai/start_server.sh
```

This runs ACE-Step's own `start_api_server_macos.sh` with `ACESTEP_LM_BACKEND=mlx` on `http://127.0.0.1:8001`. The API documentation is at `http://127.0.0.1:8001/docs`. The launcher's interactive update prompt is switched off so the pinned commit stays pinned.

In terminal 2:

```sh
python3 tools/music_ai/generate_music.py check     # ffmpeg + /health + /v1/models
```

(Optional) ACE-Step's web UI, useful for exploring by ear: `cd tools/music_ai/ACE-Step-1.5 && ./start_gradio_ui_macos.sh`, then open <http://localhost:7860>.

## 4. First deliverable: three main-menu directions

```sh
python3 tools/music_ai/generate_music.py generate --first-deliverable
```

This generates `main_menu_a_piano`, `main_menu_b_strings` and `main_menu_c_analog`, 90 s each. Each one lands in `tools/music_ai/output/<id>/`:

| File | Contents |
|---|---|
| `<id>.wav` | Untouched ACE-Step master |
| `<id>_preview.ogg` | Loudness-normalized copy for listening |
| `generation.json` | Exact request (caption, seed, steps, model), returned metadata, ACE-Step commit, timing, host |
| `qa.json` | Duration, integrated LUFS, true peak, full-scale sample count, seconds of silence, SHA-256, warnings |

A result counts as real only if the full file decodes cleanly in ffmpeg. The script also warns about near-silent output, clipping, true peak above −1 dBTP, output shorter than requested, or a track that is mostly silence.

Listen to the three previews, choose a direction, and then approve it:

```sh
python3 tools/music_ai/generate_music.py approve main_menu_b_strings --approved-by "Your Name" --notes "why"
```

Approving does the following:

1. Normalizes the track to −20 LUFS with a −1.5 dBTP ceiling, using two-pass EBU R128.
2. Builds an equal-power 4 s loop seam for looping tracks.
3. Encodes 48 kHz OGG to `audio/music_ai/<track>/mus_ai_<id>.ogg`.
4. Updates `audio/music_ai/music_cues.json`, which AudioDirector loads automatically, and `audio/music_ai/manifest.json`, which records the prompt, seed, settings, model, commit, loudness, license note and approver.

Open Godot once so it imports the file, then run `python3 tests/qa/run.py`. Commit the result through Git LFS, which `.gitattributes` already routes for `audio/music_ai/**/*.ogg`.

## 5. Expanding the score

`tools/music_ai/score.json` is the editable plan. It defines a shared identity (caption prefix, motifs, tonal plan in D minor moving to D Phrygian for Ward Zero, an "avoid" list), engine settings, and ten tracks:

| Track | Variants | Game hook |
|---|---|---|
| main_menu: The Forensic Ward | 3 directions (A piano, B strings, C analog) | `music_state: main_menu` |
| the_admission: The Admission | calm | opening chapter |
| clinical_routine: Clinical Routine | calm / tense | corridor, daytime |
| elias_ward: Elias Ward | calm / tense | interview room (ducked under dialogue) |
| contradictory_records: Contradictory Records | calm / tense | records archive |
| after_hours: After Hours | calm / tense | night exploration |
| research_wing: The Research Wing | calm / tense | research wing |
| historical_wing: The Historical Wing | calm / tense | old asylum |
| ward_zero: Ward Zero | calm / tense | Ward Zero |
| concordance_protocol: The Concordance Protocol | full | revelation |

```sh
python3 tools/music_ai/generate_music.py list
python3 tools/music_ai/generate_music.py generate after_hours_calm after_hours_tense
python3 tools/music_ai/generate_music.py generate after_hours_calm --seed-offset 1   # alternate take, new id
python3 tools/music_ai/generate_music.py generate --all                             # whole plan
```

Every request is instrumental. Lyrics are set to `[Instrumental]`, which ACE-Step's server treats as instrumental, `vocal_language` is `unknown`, and an LM negative prompt excludes vocals, choirs, EDM/rock drums, trailer braams and jump-scare hits. Seeds are fixed (`use_random_seed: false`), so the same commit, model and settings reproduce a take.

**Motif consistency:** text prompts alone cannot guarantee a melody. Every caption restates the motif, and the key, BPM and instrumentation are shared. Once the main theme is approved, pass it to ACE-Step as reference audio. The track is uploaded as `reference_audio` (multipart), and its path and SHA-256 are recorded in `generation.json` and the manifest:

```sh
python3 tools/music_ai/generate_music.py generate after_hours_calm after_hours_tense --reference main_theme
python3 tools/music_ai/generate_music.py generate ward_zero_tense --reference path/to/approved.ogg
```

Use only the project's own approved tracks as references. For stronger thematic carry-over, ACE-Step's `cover` task re-renders a source track at a chosen strength (`audio_cover_strength`, where about 0.2–0.4 keeps only the style). It is available in the Gradio UI but not yet in `generate_music.py`.

**Calm/tense layers:** ACE-Step renders complete mixes, not stems. "Intensity layers" are therefore separate calm and tense renders of the same cue. AudioDirector crossfades between them over 4 s as `set_music_intensity` crosses each variant's `min_intensity`. For true stems, ACE-Step's "extract" task can be explored later.

**Hooking music to the game:** add a `location_music` map to `audio/music_ai/music_cues.json`, for example `{"corridor": {"day": "clinical_routine", "night": "after_hours"}}`. Narrative-driven changes go in `events`, for example `"ch1_after_hours_intercom": [{"at": 0, "music_state": "after_hours"}]`. Both are loaded at startup.

## 6. QA checklist for each track (record in the manifest `notes`)

- **Musical coherence:** a clear arc, no aimless wandering, and the motif is recognizable.
- **Audible artifacts:** metallic or phasey smearing, garbled pseudo-vocals, abrupt timbre changes, noise bursts, an unwanted fade at the end.
- **Fit for the scene:** daytime clinical cues must feel realistic, not supernatural, and must not compete with dialogue (play them under `Ch1AudioSequence`).
- **Originality:** listen for close resemblance to known film or game themes. ACE-Step's README asks users to verify originality and disclose AI involvement. If in doubt, regenerate with a new seed.
- **Loop quality:** loop the exported OGG in Godot (or `ffplay -loop 0`) and listen across the seam three times.
- **Loudness:** `qa.json` is close to −20 LUFS after approval, true peak ≤ −1.5 dBTP, with no clipping warnings.
- **Godot performance:** OGG is streamed. Check the CPU and memory monitors while crossfading variants.
- **Licensing:** see below.

## 7. Licensing (review before commercial release)

- **ACE-Step 1.5 code:** MIT, from the repository's `LICENSE` (checked at the pinned commit).
- **Model weights:** check the license shown on <https://huggingface.co/ACE-Step/Ace-Step1.5> (or the ModelScope page) at the time you download, and record it in the manifest. The build container could not reach either site, so this guide does not assume the license.
- **Generated output:** the README's disclaimer puts responsibility on the user: verify the originality of generated works, disclose AI involvement, and do not imitate protected material. Keep `generation.json` for every shipped track as provenance. Some storefronts, including Steam, ask developers to disclose AI-generated content.
- **No vocals and no reference audio from third parties.** Only use the project's own approved tracks as reference audio.

## 8. Troubleshooting

| Symptom | Fix |
|---|---|
| `check_mac.sh` says Intel Mac | MLX needs Apple Silicon. ACE-Step would fall back to CPU PyTorch, which is impractically slow. |
| `uv sync` fails | Check the network. Run `xcode-select --install`, retry, or use the portable package. |
| `import mlx.core` fails | Update macOS, then `cd tools/music_ai/ACE-Step-1.5 && uv pip install --upgrade mlx mlx-lm`. |
| Hugging Face is blocked or slow | `cd tools/music_ai/ACE-Step-1.5 && uv run acestep-download` falls back to ModelScope automatically, or force it with `ACESTEP_DOWNLOAD_SOURCE=modelscope`. Behind a proxy, set `HTTPS_PROXY`. |
| Download stopped partway | `uv run acestep-download --force`, then re-run the installer to verify. |
| Models in another folder | `export ACESTEP_CHECKPOINTS_DIR=~/ace-step-models` before installing and starting the server. |
| Out of memory / swap storm | Use `LM_MODEL_PATH=acestep-5Hz-lm-0.6B`, close other apps, or pass `--overrides '{"thinking": false}'`, which skips the LM planner. |
| `generate_music.py check` cannot connect | The server is not running yet, or is still loading models. The first start downloads and loads the models, which takes several minutes. |
| `FAILED: ACE-Step reported failure` | Read the server terminal. Try a shorter `--overrides '{"audio_duration": 60}'`. |
| Output has vocals | Confirm the lyrics are `[Instrumental]` in `generation.json`, then regenerate with a new seed. |
| Port 8001 in use | `bash ACE-Step-1.5/close_api_server.sh`, or set `ACESTEP_API_URL` to another port after editing `PORT` in the launcher. |
