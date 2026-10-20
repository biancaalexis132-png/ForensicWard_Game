#!/usr/bin/env python3
"""Generate voiced dialogue clips from the game's narrative data with Kokoro TTS (offline).

Dialogue text is read from data/narrative/*.json; this script never contains
dialogue of its own. Each line is voiced with its speaker's fixed profile in
audio/voice_profiles.json and written to audio/voice/<chapter>/<line_id>.ogg.
audio/voice/voice_lines.json records which text and profile produced each clip,
so build_manifest.py can flag clips that went stale after a text edit.

Setup (once):
    python3 -m venv .venv-audio
    .venv-audio/bin/pip install -r tools/audio/requirements.txt
    mkdir -p tools/audio/models && cd tools/audio/models
    curl -LO https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/kokoro-v1.0.onnx
    curl -LO https://github.com/thewh1teagle/kokoro-onnx/releases/download/model-files-v1.0/voices-v1.0.bin
    # Narrator profile ("engine": "piper"): the owner-approved recap voice.
    curl -LO https://github.com/k2-fsa/sherpa-onnx/releases/download/tts-models/vits-piper-en_US-ljspeech-high.tar.bz2
    tar xjf vits-piper-en_US-ljspeech-high.tar.bz2   # model sha256 fea8faae...e82e33

Usage, from the repository root:
    .venv-audio/bin/python tools/audio/generate_voice.py               # only new or changed lines
    .venv-audio/bin/python tools/audio/generate_voice.py --force       # everything
    .venv-audio/bin/python tools/audio/generate_voice.py ch1_b2_bennett_001
    .venv-audio/bin/python tools/audio/generate_voice.py --jobs 4       # parallel workers
"""
import argparse
from concurrent.futures import ProcessPoolExecutor
import hashlib
import json
import os
from pathlib import Path
import sys

import numpy as np
from scipy import signal

import synth_sfx as fx

ROOT = fx.ROOT
SR = fx.SR
NARRATIVE_DIR = ROOT / "data/narrative"
PROFILES_PATH = ROOT / "audio/voice_profiles.json"
INDEX_PATH = ROOT / "audio/voice/voice_lines.json"
DEFAULT_MODEL_DIR = ROOT / "tools/audio/models"


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8"))


def narrative_lines():
    """Yields (chapter, line) for every line in data/narrative/*.json."""
    for path in sorted(NARRATIVE_DIR.glob("*.json")):
        data = load_json(path)
        for scene in data.get("scenes", []):
            for line in scene.get("lines", []):
                yield data["chapter"], line


def line_hash(line, profile):
    key = json.dumps({"text": line["text"], "profile": profile}, sort_keys=True)
    return hashlib.sha1(key.encode()).hexdigest()


def trim_silence(audio, threshold_db=-45.0, pad=0.08):
    envelope = np.abs(signal.hilbert(audio))
    loud = np.flatnonzero(envelope > 10 ** (threshold_db / 20) * np.max(envelope))
    if loud.size == 0:
        return audio
    start = max(0, loud[0] - fx.seconds(pad))
    end = min(len(audio), loud[-1] + fx.seconds(pad))
    return audio[start:end]


def level_dialogue(audio, rms_db=-21.0, peak_db=-3.0):
    """Sets speech level on voiced samples only, then soft-limits the peaks."""
    voiced = audio[np.abs(audio) > 0.02 * np.max(np.abs(audio))]
    audio = audio / np.sqrt(np.mean(voiced ** 2)) * 10 ** (rms_db / 20)
    ceiling = 10 ** (peak_db / 20)
    return np.tanh(audio / ceiling) * ceiling


def fx_dialogue(audio, rng):
    audio = fx.butter(audio, "highpass", 70, order=2)
    return fx.fade(level_dialogue(audio), 0.01, 0.03)


def fx_intercom(audio, rng):
    """Old ceiling PA: two-tone chime, band-limited driven speech, line static, big reflective space."""
    chime = np.zeros(fx.seconds(1.6))
    fx.place(chime, fx.piano_note(rng, 659.26, 1.6, 0.5), 0.0)  # E5
    fx.place(chime, fx.piano_note(rng, 523.25, 1.4, 0.5), 0.45)  # C5
    chime = fx.butter(chime, "bandpass", [250, 5000], order=2)

    speech = fx.butter(audio, "bandpass", [380, 3300], order=4)
    speech = np.tanh(speech / np.max(np.abs(speech)) * 2.2)  # Overdriven paging amplifier.
    speech = fx.butter(speech, "bandpass", [450, 3100], order=2)

    lead = fx.seconds(1.1)
    dry = np.zeros(lead + len(speech) + fx.seconds(0.4))
    fx.place(dry, chime / np.max(np.abs(chime)) * 0.5, 0.0)
    fx.place(dry, speech / np.max(np.abs(speech)), lead / SR)

    # Line static with sparse crackle, present only while the PA channel is open.
    static = fx.butter(rng.standard_normal(len(dry)), "bandpass", [1200, 7000], order=2) * 0.02
    crackle = (rng.random(len(dry)) > 0.9994) * rng.standard_normal(len(dry)) * 0.25
    channel = fx.fade(static + fx.butter(crackle, "highpass", 900, order=2), 0.05, 0.25)
    dry += channel

    wet = fx.apply_reverb(dry, fx.reverb_ir(1.8, rng, pre_delay=0.04, brightness=3500), 0.38)
    wet = fx.normalize_peak(wet, -3.0)
    return fx.fade(wet, 0.0, 0.6)


def fx_narration(audio, rng):
    """The approved recap narration was loudness-normalised to about -18 LUFS; match its level."""
    audio = fx.butter(audio, "highpass", 60, order=2)
    return fx.fade(level_dialogue(audio, rms_db=-19.0, peak_db=-2.0), 0.01, 0.05)


FX_CHAINS = {"dialogue": fx_dialogue, "intercom": fx_intercom, "narration": fx_narration}
PIPER_DIR = "vits-piper-en_US-ljspeech-high"
_engines = {}


def _engine(name, model_dir):
    """Loads each TTS engine once per process."""
    if name not in _engines:
        if name == "piper":
            import sherpa_onnx
            base = model_dir / PIPER_DIR
            config = sherpa_onnx.OfflineTtsConfig(model=sherpa_onnx.OfflineTtsModelConfig(
                vits=sherpa_onnx.OfflineTtsVitsModelConfig(model=str(base / "en_US-ljspeech-high.onnx"),
                    tokens=str(base / "tokens.txt"), data_dir=str(base / "espeak-ng-data"),
                    noise_scale=0.667, noise_scale_w=0.8, length_scale=1.0),
                num_threads=1))
            _engines[name] = sherpa_onnx.OfflineTts(config)
        else:
            from kokoro_onnx import Kokoro  # Imported late so --help works without the model.
            _engines[name] = Kokoro(str(model_dir / "kokoro-v1.0.onnx"), str(model_dir / "voices-v1.0.bin"))
    return _engines[name]


def synthesize(model_dir, line, profile):
    if profile.get("engine") == "piper":
        generated = _engine("piper", model_dir).generate(line["text"], sid=0, speed=profile["speed"])
        samples, rate = generated.samples, generated.sample_rate
    else:
        samples, rate = _engine("kokoro", model_dir).create(
                line["text"], voice=profile["voice"], speed=profile["speed"], lang=profile["lang"])
    audio = signal.resample_poly(np.asarray(samples, dtype=np.float64), SR, rate)
    audio = trim_silence(audio)
    seed = int(hashlib.sha1(line["id"].encode()).hexdigest()[:8], 16)
    return FX_CHAINS[profile["fx"]](audio, np.random.default_rng(seed))


def _render(job):
    model_dir, line, profile, relative = job
    fx.write_ogg(synthesize(model_dir, line, profile), relative, quality=5)
    return True


def main():
    parser = argparse.ArgumentParser(description=__doc__, formatter_class=argparse.RawDescriptionHelpFormatter)
    parser.add_argument("line_ids", nargs="*", help="only these line IDs (default: all new or changed lines)")
    parser.add_argument("--force", action="store_true", help="regenerate even if text and profile are unchanged")
    parser.add_argument("--model-dir", type=Path, default=Path(os.environ.get("KOKORO_MODEL_DIR", DEFAULT_MODEL_DIR)),
                        help="folder holding the Kokoro files and the Piper narrator folder")
    parser.add_argument("--jobs", type=int, default=1, help="parallel synthesis processes")
    args = parser.parse_args()

    profiles = load_json(PROFILES_PATH)["profiles"]
    index = load_json(INDEX_PATH) if INDEX_PATH.exists() else {}
    lines = list(narrative_lines())
    known_ids = {line["id"] for _, line in lines}
    unknown = set(args.line_ids) - known_ids
    if unknown:
        parser.error("line IDs not found in data/narrative: " + ", ".join(sorted(unknown)))

    jobs = []
    for chapter, line in lines:
        if args.line_ids and line["id"] not in args.line_ids:
            continue
        if line["speaker"] not in profiles:
            sys.exit(f"{line['id']}: speaker '{line['speaker']}' has no voice profile in {PROFILES_PATH.name}")
        profile = profiles[line["speaker"]]
        digest = line_hash(line, profile)
        relative = f"audio/voice/{chapter}/{line['id']}.ogg"
        if not args.force and index.get(line["id"], {}).get("source_hash") == digest and (ROOT / relative).exists():
            continue
        jobs.append((args.model_dir, line, profile, relative))

    with ProcessPoolExecutor(max_workers=max(1, args.jobs)) as pool:
        for (_, line, profile, relative), _done in zip(jobs, pool.map(_render, jobs)):
            index[line["id"]] = {
                "path": relative, "speaker": line["speaker"], "voice": profile["voice"],
                "speed": profile["speed"], "fx": profile["fx"], "source_hash": line_hash(line, profile),
            }

    for stale in sorted(set(index) - known_ids):
        print(f"warning: {stale} is no longer in data/narrative; delete {index[stale]['path']} if unused")
    INDEX_PATH.parent.mkdir(parents=True, exist_ok=True)
    INDEX_PATH.write_text(json.dumps(dict(sorted(index.items())), indent="\t") + "\n", encoding="utf-8")


if __name__ == "__main__":
    main()
