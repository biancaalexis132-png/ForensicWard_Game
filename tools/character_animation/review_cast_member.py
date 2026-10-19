"""Render a review sheet of a finished character: clips on the body and the face morphs.

Read-only on the .blend. Writes `<Display_Name>_<version>_review_body.png` (rest,
listening, the chart gesture at its peak, the greeting nod) and
`<Display_Name>_<version>_review_face.png` (neutral, two expressions and three
visemes) under assets/renders/characters/. Cameras are placed from the eyes and the
character's height, so it frames any cast member. Run from the repository root:

    blender -b --python-exit-code 1 --python tools/character_animation/review_cast_member.py -- \
        --profile tools/character_animation/profiles/staff_voss_v01_draft.json
"""
from __future__ import annotations

import argparse
import importlib.util
import json
import sys
from pathlib import Path

import bpy  # noqa: I001
import numpy as np
from mathutils import Vector

ROOT = Path.cwd()
_spec = importlib.util.spec_from_file_location("animated_builder",
                                               ROOT / "tools/character_animation/build_animated_character.py")
builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(builder)

BODY_SHOTS = (("rest", "idle_neutral", 0.0), ("listen", "listen_neutral", 0.5),
              ("chart_gesture", "restrained_chart_indication", 0.5), ("greeting_nod", "small_greeting_nod", 0.45))
FACE_SHOTS = ("neutral", "warm_subtle", "concerned_restrained", "viseme_aa_02", "viseme_w_uw_07", "viseme_f_v_18")


def main() -> None:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--profile", required=True)
    args = p.parse_args(argv)
    profile = json.loads((ROOT / args.profile).read_text(encoding="utf-8"))
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / profile["outputs"]["blend"]))
    objs = profile["objects"]
    rig = bpy.data.objects[objs["rig"]]
    body = bpy.data.objects[objs["face_mesh"]]
    centres = []
    for key in ("eye_l", "eye_r"):
        eye = bpy.data.objects[objs[key]]
        pts = np.array([eye.matrix_world @ v.co for v in eye.data.vertices])
        centres.append(Vector(((pts.min(0) + pts.max(0)) / 2).tolist()))
    mid = (centres[0] + centres[1]) / 2
    height = mid.z / 0.93
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.cycles.use_denoising = True
    scene.render.resolution_percentage = 100
    cam = scene.camera
    keys = body.data.shape_keys.key_blocks
    rig.animation_data_create()
    rig.animation_data.use_nla = False
    out_dir = ROOT / "assets/renders/characters"
    stem = f"{profile['display_name'].replace(' ', '_')}_{profile['version']}"
    tmp = Path(bpy.app.tempdir)

    def shot(name: str, loc: Vector, target: Vector, lens: float, w: int, h: int) -> Path:
        cam.location = loc
        cam.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
        cam.data.type, cam.data.lens = "PERSP", lens
        scene.render.resolution_x, scene.render.resolution_y = w, h
        path = tmp / f"{stem}_{name}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        return path

    for kb in keys:
        kb.value = 0.0
    frames = []
    fps = scene.render.fps
    for name, clip, at in BODY_SHOTS:
        action = bpy.data.actions[clip]
        rig.animation_data.action = action
        rig.animation_data.action_slot = action.slots[0]
        start, end = action.frame_range
        scene.frame_set(int(round(start + (end - start) * at)))
        frames.append(shot(name, Vector((-1.5, -2.9, height * 0.72)), Vector((0, 0, height * 0.58)), 50, 480, 720))
    builder.contact_sheet(frames, out_dir / f"{stem}_review_body.png")
    rig.animation_data.action = bpy.data.actions["idle_neutral"]
    rig.animation_data.action_slot = rig.animation_data.action.slots[0]
    scene.frame_set(1)
    del fps
    faces = []
    for name in FACE_SHOTS:
        for kb in keys:
            kb.value = 1.0 if kb.name == name else 0.0
        faces.append(shot(name, mid + Vector((-0.12, -0.5, -0.02)), mid + Vector((0, 0, -0.035)), 85, 400, 480))
    builder.contact_sheet(faces, out_dir / f"{stem}_review_face.png")
    print(f"REVIEW {profile['character_id']} OK")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.stdout.flush()
