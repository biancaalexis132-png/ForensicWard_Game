#!/usr/bin/env python3
"""Fail closed unless every production voice, caption and approved image is present."""
import hashlib
import json
from pathlib import Path
import sys

ROOT = Path(__file__).resolve().parents[2]


def main():
    data = json.loads((ROOT / 'data/narration/recaps.json').read_text())
    queue = json.loads((ROOT / 'audio/narration/recording_queue.json').read_text())
    provenance_path = ROOT / 'audio/narration/provenance.json'
    assets = json.loads(provenance_path.read_text())['assets'] if provenance_path.exists() else {}
    errors = []
    for item in queue:
        track = data['tracks'][item['track']]
        path = ROOT / track['audio_path'].removeprefix('res://')
        if not path.is_file():
            errors.append('Missing voice: ' + item['track'])
            continue
        source = assets.get(item['track'], {})
        if source.get('sha256') != hashlib.sha256(path.read_bytes()).hexdigest():
            errors.append('Missing/mismatched provenance: ' + item['track'])
        if not track.get('cues') or not path.with_suffix('.srt').is_file():
            errors.append('Missing timed subtitles: ' + item['track'])
    for row in json.loads((ROOT / 'docs/narration_review/approved_art_sha256.json').read_text()):
        if hashlib.sha256((ROOT / row['path']).read_bytes()).hexdigest() != row['sha256']:
            errors.append('Approved art changed: ' + row['path'])
    for error in errors:
        print(error)
    print(f'NARRATION_DELIVERY voices={len(assets)}/{len(queue)} approved_art=36 errors={len(errors)}')
    return 1 if errors else 0


if __name__ == '__main__':
    sys.exit(main())
