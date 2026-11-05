#!/usr/bin/env bash
# Builds the Elias-encounter cast (player psychiatrist, 1:1 sitter, background ward staff)
# with the existing cast pipeline. Run from the repository root:
#   PY=/path/to/python-with-bpy-5.2.2 tools/encounter/build_encounter_cast.sh [character_id ...]
set -euo pipefail
PY="${PY:-python3}"
IDS=("$@")
[ ${#IDS[@]} -eq 0 ] && IDS=(protagonist_female protagonist_male staff_sitter_adler staff_bg_nurse_a staff_bg_nurse_b staff_bg_housekeeping)
for id in "${IDS[@]}"; do
  P=tools/character_animation/profiles
  echo "== $id"
  "$PY" tools/blender/characters/build_cast_member.py -- --config tools/blender/characters/cast/$id.json --no-render
  "$PY" -c "import sys; sys.argv=['b','--','--profile','$P/${id}_v01_anim.json','--no-render']; exec(open('tools/character_animation/build_animated_character.py').read())"
  "$PY" -c "import sys; sys.argv=['b','--','--profile','$P/${id}_v01_face.json']; exec(open('tools/character_animation/transfer_face_shapes.py').read())"
  "$PY" -c "import sys; sys.argv=['b','--','--profile','$P/${id}_v01_draft.json','--no-render']; exec(open('tools/character_animation/refine_character.py').read())"
  "$PY" tools/character_animation/add_motion_clips.py --profile $P/${id}_v01_draft.json
done
