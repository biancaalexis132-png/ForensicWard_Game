#!/usr/bin/env python3
"""Reproduce the owner-approved local narration; weights stay outside the repo.

Install requirements-local.txt; download/extract voice.source_url from recaps.json.
python tools/narration/generate_local.py /path/to/vits-piper-en_US-ljspeech-high /path/to/wavs
Then import_recordings.py /path/to/wavs. Existing WAVs are retained by default.
"""
import argparse
import hashlib
import json
from pathlib import Path
import sherpa_onnx
import soundfile as sf

ROOT = Path(__file__).resolve().parents[2]

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('model_dir', type=Path)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    data = json.loads((ROOT / 'data/narration/recaps.json').read_text())
    model = args.model_dir / 'en_US-ljspeech-high.onnx'
    if hashlib.sha256(model.read_bytes()).hexdigest() != data['voice']['model_sha256']:
        raise SystemExit('Model hash differs from the approved sample source')
    config = sherpa_onnx.OfflineTtsVitsModelConfig(
        model=str(model), tokens=str(args.model_dir / 'tokens.txt'),
        data_dir=str(args.model_dir / 'espeak-ng-data'))
    tts = sherpa_onnx.OfflineTts(sherpa_onnx.OfflineTtsConfig(
        model=sherpa_onnx.OfflineTtsModelConfig(vits=config, num_threads=2, provider='cpu'),
        max_num_sentences=1))
    args.output.mkdir(parents=True, exist_ok=True)
    for item in json.loads((ROOT / 'audio/narration/recording_queue.json').read_text()):
        target = args.output / (item['track'] + '.wav')
        if target.exists():
            continue
        audio = tts.generate(item['text'], sid=0, speed=0.92)
        sf.write(str(target), audio.samples, audio.sample_rate, subtype='PCM_16')
        print(item['track'], round(len(audio.samples) / audio.sample_rate, 3), flush=True)

if __name__ == '__main__':
    main()
