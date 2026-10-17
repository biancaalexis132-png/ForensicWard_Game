#!/usr/bin/env python3
"""Validate the Naomi presentation cue asset against existing story/voice manifests."""
import json
import pathlib
import sys

repo = pathlib.Path(sys.argv[1]).resolve() if len(sys.argv) > 1 else pathlib.Path.cwd()
cues_path = pathlib.Path(__file__).with_name('naomi_acting_cues.json')
cues = json.loads(cues_path.read_text())
story = json.loads((repo/'data/narrative/chapter1.json').read_text())
voices = json.loads((repo/'audio/voice/voice_lines.json').read_text())
scenes = {s['id']: s for s in story['scenes']}
scene = scenes[cues['scene_id']]
line_ids = {line['id']:line for line in scene['lines']}
errors = []
for key, stages in cues['cues'].items():
    if key not in line_ids:
        errors.append(f'Unknown dialogue ID: {key}')
    if key not in voices:
        errors.append(f'Missing voice mapping: {key}')
    if key in line_ids and line_ids[key]['speaker'] != 'staff_bennett' and 'during_speech' not in stages:
        errors.append(f'Player listener cue lacks during_speech: {key}')
    for stage, data in stages.items():
        if stage not in ('on_enter','during_speech','on_exit'):
            errors.append(f'Invalid stage: {stage}')
        for field in ('body','face','gaze','gesture'):
            if field not in data:
                errors.append(f'Missing {field} at {key}/{stage}')
for key in line_ids:
    if key not in cues['cues']:
        errors.append(f'Missing cue for line: {key}')
if cues['rules']['clinical_state_effect'] != 'none':
    errors.append('Presentation layer cannot mutate clinical state')
if errors:
    print('\n'.join('FAIL: '+error for error in errors))
    sys.exit(1)
print(f'PASS: {len(line_ids)} dialogue IDs have valid Naomi acting cues; all voice mappings found.')
