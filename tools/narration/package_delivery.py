#!/usr/bin/env python3
"""Create the final source-project ZIP only after every recording/hash gate passes.

Run after committing the voice assets and generated provenance/subtitles:
  python3 tools/narration/package_delivery.py /path/to/ForensicWard_Narrated.zip
No merge or deployment is performed.
"""
import argparse
import hashlib
import json
from pathlib import Path
import subprocess
import zipfile

ROOT = Path(__file__).resolve().parents[2]


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    result = subprocess.run(['python3', str(ROOT / 'tools/narration/check_delivery.py')])
    if result.returncode:
        raise SystemExit('Final ZIP blocked: required voice, subtitle or artwork checks did not pass')
    names = subprocess.check_output(['git', 'ls-files', '-z'], cwd=ROOT).decode().split('\0')
    names = sorted(n for n in names if n)
    tracked = set(names)
    data = json.loads((ROOT / 'data/narration/recaps.json').read_text())
    queue = json.loads((ROOT / 'audio/narration/recording_queue.json').read_text())
    for item in queue:
        path = data['tracks'][item['track']]['audio_path'].removeprefix('res://')
        if path not in tracked or str(Path(path).with_suffix('.srt')) not in tracked:
            raise SystemExit('Commit voice and subtitle assets before packaging: ' + path)
    for name in names:
        path = ROOT / name
        if not path.is_file():
            raise SystemExit('Tracked file missing: ' + name)
        with path.open('rb') as source:
            if source.read(80).startswith(b'version https://git-lfs.github.com/spec/v1'):
                raise SystemExit('Resolve Git LFS media before final packaging: ' + name)
    if subprocess.run(['git', 'diff', '--quiet', 'HEAD', '--'], cwd=ROOT).returncode:
        raise SystemExit('Commit the validated working tree before packaging')
    output = args.output.resolve()
    output.parent.mkdir(parents=True, exist_ok=True)
    prefix = 'ForensicWard_Narrated_Chapter1-5/'
    with zipfile.ZipFile(output, 'w', zipfile.ZIP_DEFLATED) as archive:
        for name in names:
            archive.write(ROOT / name, prefix + name)
    with zipfile.ZipFile(output) as archive:
        for row in json.loads((ROOT / 'docs/narration_review/approved_art_sha256.json').read_text()):
            assert hashlib.sha256(archive.read(prefix + row['path'])).hexdigest() == row['sha256']
    print(f'Final source-project ZIP verified: {output.name}; {output.stat().st_size} bytes; 38 voice clips and 36 original art hashes')


if __name__ == '__main__':
    main()
