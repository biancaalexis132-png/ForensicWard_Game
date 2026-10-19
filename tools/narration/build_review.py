#!/usr/bin/env python3
"""Build the offline, per-panel listening page from the runtime catalogue."""
import html
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
def main():
    data = json.loads((ROOT / 'data/narration/recaps.json').read_text())
    rows = ['<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>Forensic Ward narrated recaps</title>',
            '<style>body{background:#161b20;color:#eee;font:18px system-ui;max-width:1000px;margin:30px auto;padding:20px}img{width:100%;height:auto}article{margin:45px 0}aside{background:#453619;padding:16px}a{color:#a9d8ff}audio{display:block;width:100%;margin:12px 0}</style>',
            '<h1>Narrated chapter recaps</h1><aside>Owner-approved replacement narrator: Piper LJ Speech, speed 0.92. All 36 approved illustrations are unchanged. Chapter 5 endings share the approved artwork. This page supports individual panel listening; the Godot game provides synchronized transitions, controls and soundtrack ducking.</aside>',
            '<p>Unzip first, then open this file. <a href="docs/NARRATED_CUTSCENES.md">Placement and playback guide</a>.</p>']
    for chapter in range(1, 6):
        scene = json.loads((ROOT / f'data/cutscenes/cs_ch0{chapter}_static_gn.json').read_text())
        rows.append(f'<h2>Chapter {chapter}</h2>')
        for panel in scene['panels']:
            panel_id = panel['id']
            rows.append(f'<article><h3>{panel_id}</h3><img loading="lazy" src="assets/cutscenes/static_gn_v1/ch0{chapter}/chapter_0{chapter}_panel_{panel_id[1:]}.png" alt="Approved chapter {chapter} panel {panel_id}">')
            track_id = f'nar_ch0{chapter}_{panel_id}'
            ids = [track_id + '_' + e for e in 'abc'] if chapter == 5 and panel_id == 'p06' else [track_id]
            for tid in ids:
                track = data['tracks'][tid]
                if len(ids) > 1:
                    rows.append(f'<h4>Ending {tid[-1].upper()}</h4>')
                rows.append('<p>' + html.escape(track['text']) + '</p>')
                rows.append('<audio controls preload="none" src="' + html.escape(track['audio_path'].removeprefix('res://'), quote=True) + '"></audio>')
            rows.append('</article>')
    rows.append('</html>')
    (ROOT / 'NARRATION_REVIEW.html').write_text('\n'.join(rows) + '\n')

if __name__ == '__main__':
    main()
