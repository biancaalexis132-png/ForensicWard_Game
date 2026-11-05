"""Render a motion review sheet for one cast member: the walk cycle from the side
and the peak of each new gesture from the front.

Builds the motion clips in memory exactly as add_motion_clips.py does (nothing is
saved or exported) and renders them with a few Cycles CPU samples, so it runs without a GPU. The
sheet checks poses only; it is not a lighting or material review.

    python -I tools/character_animation/review_motion_clips.py --profile <_v01_draft profile> --out <png>
"""
from __future__ import annotations

import argparse
import json
import math
import sys
from pathlib import Path

import bpy  # noqa: I001
from mathutils import Vector

ROOT = Path.cwd()
sys.path.insert(0, str(ROOT / "tools/character_animation"))
import add_motion_clips as motion  # noqa: E402
import build_animated_character as builder  # noqa: E402


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", required=True)
    parser.add_argument("--out", required=True)
    parser.add_argument("--size", type=int, default=360)
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    profile_path = (ROOT / args.profile).resolve()
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    library = json.loads(motion.MOTION_LIBRARY_PATH.read_text(encoding="utf-8"))
    seated = motion.is_seated(profile["character_id"])
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / profile["outputs"]["blend"]))
    rig = bpy.data.objects[profile["objects"]["rig"]]
    anim_profile = json.loads(profile_path.with_name(
        profile_path.name.replace("_v01_draft.json", "_v01_anim.json")).read_text(encoding="utf-8"))
    frame = builder.CharacterFrame(anim_profile)
    bones = motion.bone_roles(anim_profile["bones"], rig)
    clips = motion.selected_clips(library, seated)
    fps = int(library["fps"])
    meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig]
    print("garment weight fix:", motion.detach_garments_from_forearms(rig, meshes))
    builder.build_clips(rig, frame, {"fps": fps, "clips": clips}, bones)
    walk = next((c for c in clips if c["name"] == "walk_neutral"), None)
    if walk is not None:
        motion.ground_walk(rig, walk, fps)

    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 12
    scene.cycles.use_denoising = False
    scene.render.resolution_x = args.size
    scene.render.resolution_y = int(args.size * 1.6)
    scene.render.film_transparent = False
    for obj in list(bpy.data.objects):
        if obj.type in {"CAMERA", "LIGHT"}:
            bpy.data.objects.remove(obj)
    for name, rot, energy in (("Key", (0.9, 0.0, 0.6), 3.0), ("Fill", (1.1, 0.0, -2.2), 1.2)):
        light = bpy.data.objects.new(name, bpy.data.lights.new(name, "SUN"))
        light.data.energy = energy
        light.rotation_euler = rot
        scene.collection.objects.link(light)
    if scene.world is None:
        scene.world = bpy.data.worlds.new("MotionReviewWorld")
    scene.world.color = (0.25, 0.26, 0.28)
    cam_data = bpy.data.cameras.new("MotionReviewCam")
    cam_data.lens = 50
    cam = bpy.data.objects.new("MotionReviewCam", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    height = 1.2 if seated else 0.95

    def aim(location: Vector, target: Vector) -> None:
        cam.location = location
        cam.rotation_euler = (target - location).to_track_quat("-Z", "Y").to_euler()

    tmp = Path(bpy.app.tempdir or "/tmp") / f"motion_{profile['character_id']}"
    tmp.mkdir(parents=True, exist_ok=True)
    shots: list[Path] = []

    def shot(action: str | None, fr: int, side: bool) -> None:
        rig.animation_data.action = bpy.data.actions[action] if action else None
        scene.frame_set(fr)
        target = Vector((0.0, 0.0, height * 0.85 if seated else height))
        aim(Vector((4.6, 0.0, height)) if side else Vector((-3.0, -3.6, height)), target)
        path = tmp / f"{len(shots):02d}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        shots.append(path)

    if walk is not None:
        frames = int(round(walk["seconds"] * fps))
        for i in range(6):
            shot("walk_neutral", 1 + round(i * frames / 6), True)
    else:
        shot(None, 1, True)
    for clip in clips:
        if clip["player"] != "gesture" or clip.get("loop"):
            continue
        times = sorted({p[0] for k in clip.get("keys", []) for p in k["points"]})
        peak = times[len(times) // 2]
        shot(clip["name"], 1 + round(peak * fps), False)

    out = Path(args.out)
    out.parent.mkdir(parents=True, exist_ok=True)
    builder.contact_sheet(shots, out)
    print(f"REVIEW {profile['character_id']}: {len(shots)} frames -> {out}")


if __name__ == "__main__":
    main()
