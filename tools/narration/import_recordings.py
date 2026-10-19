#!/usr/bin/env python3
"""Import the approved narrator's downloaded panel recordings, without network calls.

Name each WAV/MP3 <track_id>.wav or <track_id>.mp3 using audio/narration/recording_queue.json, then:
  python3 tools/narration/import_recordings.py /path/to/downloads
  python3 tools/narration/check_delivery.py
Requires FFmpeg/ffprobe with libvorbis. Does not synthesize substitute voices.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess

ROOT = Path(__file__).resolve().parents[2]
DATA = ROOT / 'data/narration/recaps.json'


def load(path):
    return json.loads(path.read_text())


def timestamp(seconds):
    ms = round(seconds * 1000)
    hours, ms = divmod(ms, 3600000)
    minutes, ms = divmod(ms, 60000)
    sec, ms = divmod(ms, 1000)
    return f'{hours:02}:{minutes:02}:{sec:02},{ms:03}'


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('downloads', type=Path)
    args = parser.parse_args()
    data = load(DATA)
    queue = load(ROOT / 'audio/narration/recording_queue.json')
    provenance_path = ROOT / 'audio/narration/provenance.json'
    provenance = load(provenance_path) if provenance_path.exists() else {'assets': {}}
    missing = []
    for item in queue:
        track_id = item['track']
        track = data['tracks'][track_id]
        source = args.downloads / (track_id + '.wav')
        if not source.exists():
            source = args.downloads / (track_id + '.mp3')
        target = ROOT / track['audio_path'].removeprefix('res://')
        if source.exists():
            target.parent.mkdir(parents=True, exist_ok=True)
            subprocess.run(['ffmpeg', '-v', 'error', '-y', '-i', str(source),
                            '-ar', '44100', '-ac', '1', '-af', 'loudnorm=I=-18:TP=-2:LRA=7',
                            '-c:a', 'libvorbis', '-q:a', '5', str(target)], check=True)
            source_hash = hashlib.sha256(source.read_bytes()).hexdigest()
        elif target.exists():
            source_hash = provenance['assets'].get(track_id, {}).get('source_sha256', '')
        else:
            missing.append(track_id)
            continue
        measured = json.loads(subprocess.check_output(['ffprobe', '-v', 'error',
                    '-show_entries', 'format=duration', '-of', 'json', str(target)]))
        duration = float(measured['format']['duration'])
        if not 0 < duration <= 120:
            raise ValueError(f'{track_id}: invalid measured duration {duration}')
        track['duration_seconds'] = duration
        track['estimated_seconds'] = duration
        track['cues'] = [{'start': 0.0, 'end': duration, 'text': track['text']}]
        target.with_suffix('.srt').write_text(
            f'1\n00:00:00,000 --> {timestamp(duration)}\n{track["text"]}\n', encoding='utf-8')
        provenance['assets'][track_id] = {
            'file': str(target.relative_to(ROOT)), 'track_id': track_id,
            'source_sha256': source_hash, 'sha256': hashlib.sha256(target.read_bytes()).hexdigest(),
            'duration_seconds': duration, 'voice': data['voice'],
            'conversion': 'FFmpeg libvorbis q5, mono 44100Hz; loudnorm I=-18 TP=-2 LRA=7',
            'license': data['voice'].get('license', 'ElevenLabs-generated recording through the connected owner account; private/personal project scope. Commercial rights not independently verified.'),
            'review_status': 'approved_narrator_production_listening_pending'}
    DATA.write_text(json.dumps(data, indent=2) + '\n')
    provenance_path.write_text(json.dumps(provenance, indent=2) + '\n')
    print(f'Imported/retained {len(queue)-len(missing)}/{len(queue)} panel recordings')
    if missing:
        print('Missing recordings: ' + ', '.join(missing))
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
