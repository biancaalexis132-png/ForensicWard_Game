"""Add the cast motion clips (walk, arm swing, explaining and thinking gestures) to a
finished draft character and re-export its GLB.

Input is the committed draft .blend named in the character's `_v01_draft` profile
(`outputs.blend`). That file is opened read-only: the new clips are built in memory
with the same clip builder as the original ten (build_animated_character.build_clips),
and only the GLB is written, at the same path, so Godot's extracted textures and every
scene that references the model stay as they are. The .blend is not re-saved; the GLB
is reproducible from the committed .blend plus this script and
clip_library_motion.json, and the run writes a report with both hashes.

Leg roles (thigh, calf, foot) are not in the original profiles. They are resolved
from the rig by the standard game_engine bone names and checked the same way the
builder checks every other role. Characters whose cast config has a `seated` block
(Elias, Mara) sit in their rest pose, so clips marked `standing_only` are skipped
for them.

Run from the repository root with Blender 5.2.2:

    Blender --background --python-exit-code 1 --python tools/character_animation/add_motion_clips.py -- \
        --profile tools/character_animation/profiles/staff_hale_v01_draft.json

or with the bpy 5.2.2 module (Python 3.13):

    python -I tools/character_animation/add_motion_clips.py --profile <profile>
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
import build_animated_character as builder  # noqa: E402
from provenance import provenance_path  # noqa: E402

MOTION_LIBRARY_PATH = ROOT / "tools/character_animation/clip_library_motion.json"
CAST_CONFIG_DIR = ROOT / "tools/blender/characters/cast"
LEG_BONES = {
    "thigh_l": "thigh_l", "thigh_r": "thigh_r",
    "calf_l": "calf_l", "calf_r": "calf_r",
    "foot_l": "foot_l", "foot_r": "foot_r",
}
FOREARM_PREFIXES = ("lowerarm_", "hand_", "thumb_", "index_", "middle_", "ring_", "pinky_")
SLEEVE_RADIUS_M = 0.075


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    parser = argparse.ArgumentParser(description=__doc__.split("\n\n")[0])
    parser.add_argument("--profile", required=True, help="The character's finished profile (_v01_draft or _v02)")
    parser.add_argument("--report-dir", default="tools/character_animation/reports")
    return parser.parse_args(argv)


def is_seated(character_id: str) -> bool:
    config = CAST_CONFIG_DIR / f"{character_id}.json"
    if not config.exists():
        return False
    return "seated" in json.loads(config.read_text(encoding="utf-8"))


def selected_clips(library: dict, seated: bool) -> list[dict]:
    return [c for c in library["clips"] if not (seated and c.get("standing_only"))]


def bone_roles(profile_bones: dict, rig: bpy.types.Object) -> dict:
    bones = dict(profile_bones)
    for role, name in LEG_BONES.items():
        if rig.data.bones.get(name) is None:
            raise RuntimeError(f"Rig {rig.name} has no bone {name!r} for role {role}")
        bones[role] = name
    return bones


def _forearm_groups(obj: bpy.types.Object) -> set[int]:
    return {g.index for g in obj.vertex_groups if g.name.startswith(FOREARM_PREFIXES)}


def detach_garments_from_forearms(rig: bpy.types.Object, meshes: list[bpy.types.Object]) -> dict:
    """Keep jacket and trouser panels beside the hips from following the hands.

    Garment weights were copied from the nearest body skin, and in the rest pose
    the forearms hang beside the hips, so cloth over the hips picked up forearm
    and hand weight. Any arm gesture then dragged a flap of jacket or trouser
    after the hand. A sleeve is the part of a garment that is joined, edge by
    edge, to cloth hugging the forearm, so this floods outward from the cloth
    within a few centimetres of each forearm through forearm-weighted vertices.
    Forearm-weighted vertices the flood never reaches lose those weights and take
    the weights of the nearest garment vertex that has none."""
    from mathutils.geometry import intersect_point_line
    from mathutils.kdtree import KDTree

    segments = []
    for side in ("l", "r"):
        b = rig.data.bones[f"lowerarm_{side}"]
        segments.append((rig.matrix_world @ b.head_local, rig.matrix_world @ b.tail_local))
    report = {}
    for obj in meshes:
        if obj.name.endswith("_Body") or not obj.vertex_groups:
            continue
        groups = _forearm_groups(obj)
        if not groups:
            continue
        verts = obj.data.vertices
        world = [obj.matrix_world @ v.co for v in verts]
        weighted = [any(g.group in groups and g.weight > 0.0 for g in v.groups) for v in verts]
        if not any(weighted):
            continue
        neighbours: list[list[int]] = [[] for _ in verts]
        for e in obj.data.edges:
            a, b = e.vertices
            neighbours[a].append(b)
            neighbours[b].append(a)
        stack = []
        for i, co in enumerate(world):
            if not weighted[i]:
                continue
            for head, tail in segments:
                point, t = intersect_point_line(co, head, tail)
                if 0.25 <= t <= 1.0 and (point - co).length <= SLEEVE_RADIUS_M:
                    stack.append(i)
                    break
        reached = set(stack)
        while stack:
            i = stack.pop()
            for j in neighbours[i]:
                if weighted[j] and j not in reached:
                    reached.add(j)
                    stack.append(j)
        stray = [i for i, w in enumerate(weighted) if w and i not in reached]
        if not stray:
            continue
        clean = [i for i, w in enumerate(weighted) if not w]
        tree = KDTree(len(clean))
        for k, i in enumerate(clean):
            tree.insert(world[i], k)
        tree.balance()
        donors = {}
        for i in stray:
            _co, k, _d = tree.find(world[i])
            donors[i] = clean[k]
        donor_weights = {d: [(g.group, g.weight) for g in verts[d].groups] for d in set(donors.values())}
        for i in stray:
            for g in obj.vertex_groups:
                g.remove([i])
            for gi, w in donor_weights[donors[i]]:
                obj.vertex_groups[gi].add([i], w, "REPLACE")
        report[obj.name] = {"sleeve_vertices": len(reached), "detached_vertices": len(stray)}
    return report


def ground_walk(rig: bpy.types.Object, clip: dict, fps: int) -> dict:
    """Lower the pelvis each frame so the lower ankle stays at its rest height.

    The clip builder writes rotations only, so in a walk the stance leg's swing
    lifts the foot off the floor. This keys pelvis location (straight down in
    world space) so one foot is always planted, which also gives the walk its
    natural rise and fall."""
    scene = bpy.context.scene
    act = bpy.data.actions[clip["name"]]
    rig.animation_data.action = act
    pelvis = rig.pose.bones["pelvis"]
    rest_z = {s: (rig.matrix_world @ rig.data.bones[f"foot_{s}"].head_local).z for s in ("l", "r")}
    to_local = (rig.matrix_world.to_3x3() @ pelvis.bone.matrix_local.to_3x3()).inverted()
    frames = int(round(clip["seconds"] * fps))
    drops = []
    for fr in range(1, frames + 2):
        pelvis.location = Vector()
        scene.frame_set(fr)
        rise = min((rig.matrix_world @ rig.pose.bones[f"foot_{s}"].head).z - rest_z[s] for s in ("l", "r"))
        drops.append(rise)
    # The last frame repeats the first, so the loop stays seamless.
    drops[-1] = drops[0]
    for fr, rise in zip(range(1, frames + 2), drops):
        pelvis.location = to_local @ Vector((0.0, 0.0, -rise))
        pelvis.keyframe_insert("location", frame=fr, group="pelvis")
    pelvis.location = Vector()
    rig.animation_data.action = None
    scene.frame_set(1)
    return {"pelvis_drop_m": [round(min(drops), 3), round(max(drops), 3)]}


def foot_travel(rig: bpy.types.Object, clip: dict, fps: int) -> dict:
    """World-space ankle path over one walk cycle, as a sanity check on the stride."""
    scene = bpy.context.scene
    act = bpy.data.actions[clip["name"]]
    rig.animation_data.action = act
    frames = int(round(clip["seconds"] * fps))
    ys, zs = {"l": [], "r": []}, {"l": [], "r": []}
    for fr in range(1, frames + 2, 2):
        scene.frame_set(fr)
        for side in ("l", "r"):
            pb = rig.pose.bones[f"foot_{side}"]
            p = rig.matrix_world @ pb.head
            ys[side].append(p.y)
            zs[side].append(p.z)
    rig.animation_data.action = None
    scene.frame_set(1)
    return {side: {"forward_range_m": round(max(ys[side]) - min(ys[side]), 3),
                   "lift_m": round(max(zs[side]) - min(zs[side]), 3)} for side in ("l", "r")}


def main() -> None:
    args = parse_args()
    profile_path = (ROOT / args.profile).resolve()
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    blend = ROOT / profile["outputs"]["blend"]
    glb_path = ROOT / profile["outputs"]["glb"]
    blend_digest = builder.sha256(blend)
    library = json.loads(MOTION_LIBRARY_PATH.read_text(encoding="utf-8"))
    seated = is_seated(profile["character_id"])

    bpy.ops.wm.open_mainfile(filepath=str(blend))
    objs = profile["objects"]
    rig = bpy.data.objects[objs["rig"]]
    body = bpy.data.objects[objs["face_mesh"]]
    meshes = [body] + [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig and o is not body]

    # The anim profile carries the role map and the character frame.
    # <id>_v01_draft.json pairs with <id>_v01_anim.json, <id>_v02.json with <id>_v02_anim.json.
    base_version = str(profile["version"]).removesuffix("_draft")
    anim_profile_path = profile_path.with_name(f"{profile['character_id']}_{base_version}_anim.json")
    anim_profile = json.loads(anim_profile_path.read_text(encoding="utf-8"))
    frame = builder.CharacterFrame(anim_profile)
    bones = bone_roles(anim_profile["bones"], rig)

    clips = selected_clips(library, seated)
    sub_library = {"fps": library["fps"], "clips": clips,
                   builder.GESTURE_ROLES_KEY: json.loads(builder.LIBRARY_PATH.read_text(encoding="utf-8"))[builder.GESTURE_ROLES_KEY]}
    builder.validate_library(sub_library, bones)
    existing = {a.name for a in bpy.data.actions}
    already = [c["name"] for c in clips if c["name"] in existing]
    if already:
        raise RuntimeError(f"{blend.name} already has motion clips {already}; nothing to add")
    for shape in (body.data.shape_keys.key_blocks if body.data.shape_keys else []):
        shape.value = 0.0
    detached = detach_garments_from_forearms(rig, meshes)
    inventory = builder.build_clips(rig, frame, sub_library, bones)

    stride = None
    walk = next((c for c in clips if c["name"] == "walk_neutral"), None)
    if walk is not None:
        stride = ground_walk(rig, walk, int(library["fps"]))
        stride.update(foot_travel(rig, walk, int(library["fps"])))

    builder.export_glb(rig, meshes, glb_path)
    glb = builder.inspect_glb(glb_path)
    exported = [a["name"] for a in glb["animations"] if a["channels"] > 0]
    expected = set(profile["expected"]["clips"]) | {c["name"] for c in clips}
    if not expected <= set(exported):
        raise RuntimeError(f"GLB is missing clips: {sorted(expected - set(exported))}")
    morphs = sorted({n for m in glb["morph_targets"] for n in m["targets"]})
    if len(morphs) < profile["expected"]["morph_targets"]:
        raise RuntimeError(f"GLB has {len(morphs)} morph targets, expected {profile['expected']['morph_targets']}")

    report = {
        "blender_version": bpy.app.version_string,
        "character_id": profile["character_id"],
        "seated": seated,
        "source_blend": {"path": provenance_path(blend, ROOT), "sha256": blend_digest,
                         "modified": False},
        "library": {"path": provenance_path(MOTION_LIBRARY_PATH, ROOT), "sha256": builder.sha256(MOTION_LIBRARY_PATH)},
        "profile": provenance_path(profile_path, ROOT),
        "garment_weight_fix": detached,
        "added_clips": inventory,
        "skipped_standing_only": [c["name"] for c in library["clips"] if seated and c.get("standing_only")],
        "walk_foot_travel": stride,
        "glb": {"path": provenance_path(glb_path, ROOT), "sha256": builder.sha256(glb_path),
                "clips": sorted(exported), "morph_targets": len(morphs)},
        "production_status": profile["production_status"],
        "approved": False,
    }
    out = ROOT / args.report_dir / f"{profile['character_id']}_{profile['version']}_motion_report.json"
    out.parent.mkdir(parents=True, exist_ok=True)
    out.write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"MOTION {profile['character_id']} OK: +{len(inventory)} clips "
          f"({', '.join(c['name'] for c in inventory)}); {len(exported)} clips in GLB; stride {stride}")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.stdout.flush()
