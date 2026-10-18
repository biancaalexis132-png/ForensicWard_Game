"""Replace a built character's face morphs with MPFB2 faceunits and add MPFB2 visemes.

Runs after build_animated_character.py. MPFB targets index the full MPFB base mesh, but the
game body is cut down and decimated (v03 keeps 5,194 of 19,158 vertices). The head is
protected from decimation, so its vertices still sit exactly on the MPFB base. This script
loads each target as a shape key on the MPFB base body, then carries the per-vertex offsets
to the built body by inverse-distance weighting of the nearest base vertices. Added face
detail (lashes, brow strokes) follows the skin under it. Offsets fade to zero past
max_transfer_distance_m. The built .blend is never modified; outputs must be new files.

Run from the repository root on a Mac with MPFB2 and its faceunits01 and visemes01 packs:
    /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
        --python tools/character_animation/bake_mpfb_face_shapes.py -- \
        --base assets/blender/characters/Naomi_Bennett_Base_v02.blend --base-body Naomi_Bennett_Body \
        --built BUILT.blend --body Naomi_Bennett_Body --rig Naomi_Bennett_Rig \
        --out-blend assets/blender/characters/Naomi_Bennett_v05_mpfb.blend \
        --out-glb assets/exports/characters/Naomi_Bennett_v05_mpfb.glb
"""
from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils.kdtree import KDTree

ROOT = Path.cwd()
MAPPING = ROOT / "tools/character_animation/mpfb_face_mapping.json"


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    for name in ("--base", "--base-body", "--built", "--body", "--rig", "--out-blend", "--out-glb"):
        p.add_argument(name, required=True)
    p.add_argument("--report")
    return p.parse_args(argv)


def mpfb_targets_dir() -> Path:
    from bl_ext.blender_org.mpfb.services import LocationService  # noqa: PLC0415
    return Path(LocationService.get_user_data()) / "targets"


def coords(mesh: bpy.types.Mesh) -> np.ndarray:
    a = np.zeros(len(mesh.vertices) * 3, dtype=np.float64)
    mesh.vertices.foreach_get("co", a)
    return a.reshape(-1, 3)


def base_offsets(base_file: Path, body_name: str, units: set[str], visemes: list[str]) -> tuple[np.ndarray, dict]:
    """Rest positions of the MPFB base body and each target's per-vertex offset."""
    from bl_ext.blender_org.mpfb.services.targetservice import TargetService  # noqa: PLC0415
    bpy.ops.wm.open_mainfile(filepath=str(base_file))
    body = bpy.data.objects[body_name]
    bpy.context.view_layer.objects.active = body
    if body.data.shape_keys:
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)
    rest = coords(body.data)
    targets = mpfb_targets_dir()
    wanted = [("faceunits", u, u) for u in sorted(units)] + [("visemes", v, f"viseme_{v}") for v in visemes]
    offsets = {}
    for folder, stem, key in wanted:
        path = targets / folder / f"{stem}.target"
        if not path.exists():
            raise RuntimeError(f"MPFB target missing: {path} (install the faceunits01/visemes01 packs)")
        TargetService.load_target(body, str(path), weight=1.0, name=key)
        block = body.data.shape_keys.key_blocks[key]
        a = np.zeros(len(rest) * 3)
        block.data.foreach_get("co", a)
        offsets[key] = a.reshape(-1, 3) - rest
    return rest, offsets


def transfer(rest: np.ndarray, offsets: dict, built: np.ndarray, k: int, max_d: float) -> tuple[dict, dict]:
    tree = KDTree(len(rest))
    for i, v in enumerate(rest):
        tree.insert(v, i)
    tree.balance()
    idx = np.zeros((len(built), k), dtype=np.int64)
    wts = np.zeros((len(built), k))
    exact = 0
    for n, v in enumerate(built):
        hits = tree.find_n(v, k)
        d = np.array([h[2] for h in hits])
        idx[n] = [h[1] for h in hits]
        if d[0] < 1e-6:
            wts[n] = [1.0] + [0.0] * (k - 1)
            exact += 1
            continue
        w = 1.0 / np.maximum(d, 1e-6) ** 2
        fade = np.clip(1.0 - (d[0] - max_d * 0.5) / (max_d * 0.5), 0.0, 1.0)
        wts[n] = w / w.sum() * fade
    moved = {name: (off[idx] * wts[:, :, None]).sum(axis=1) for name, off in offsets.items()}
    stats = {"built_vertices": len(built), "exact_base_matches": exact}
    return moved, stats


def main() -> None:
    args = parse_args()
    mapping = json.loads(MAPPING.read_text(encoding="utf-8"))
    built_path, out_blend, out_glb = (ROOT / args.built), (ROOT / args.out_blend), (ROOT / args.out_glb)
    for out in (out_blend, out_glb):
        if out.exists():
            raise RuntimeError(f"Refusing to overwrite {out}")
    if out_blend.resolve() in (built_path.resolve(), (ROOT / args.base).resolve()):
        raise RuntimeError("Output .blend must be a new file")
    units = {u for spec in mapping["stable_shapes"].values() for u in spec}
    rest, offsets = base_offsets(ROOT / args.base, args.base_body, units, mapping["visemes"])

    bpy.ops.wm.open_mainfile(filepath=str(built_path))
    body = bpy.data.objects[args.body]
    rig = bpy.data.objects[args.rig]
    if body.data.shape_keys is None:
        body.shape_key_add(name="Basis", from_mix=False)
    basis = coords(body.data)
    moved, stats = transfer(rest, offsets, basis, mapping["neighbours"], mapping["max_transfer_distance_m"])

    keys = body.data.shape_keys.key_blocks
    written = []
    for name, spec in mapping["stable_shapes"].items():
        delta = sum(moved[u] * w for u, w in spec.items())
        block = keys.get(name) or body.shape_key_add(name=name, from_mix=False)
        block.data.foreach_set("co", (basis + delta).astype(np.float32).ravel())
        written.append(name)
    for v in mapping["visemes"]:
        name = f"viseme_{v}"
        block = keys.get(name) or body.shape_key_add(name=name, from_mix=False)
        block.data.foreach_set("co", (basis + moved[name]).astype(np.float32).ravel())
        written.append(name)
    for block in keys[1:]:
        block.value = 0.0
    stats["largest_offset_mm"] = {n: round(float(np.linalg.norm(
        coords_of(keys[n]) - basis, axis=1).max()) * 1000, 2) for n in written}

    meshes = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig]
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    out_glb.parent.mkdir(parents=True, exist_ok=True)
    # Same settings as build_animated_character.export_glb.
    result = bpy.ops.export_scene.gltf(
        filepath=str(out_glb), export_format="GLB", use_selection=True, export_apply=False,
        export_skins=True, export_texcoords=True, export_normals=True, export_image_format="AUTO",
        export_morph=True, export_morph_normal=True, export_morph_animation=False,
        export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True,
        export_optimize_animation_size=True, export_optimize_animation_keep_anim_armature=False,
        export_reset_pose_bones=True, export_anim_slide_to_zero=True, export_def_bones=False,
        export_nla_strips=True)
    if "FINISHED" not in result:
        raise RuntimeError(f"glTF export failed: {result}")
    out_blend.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(out_blend), compress=True, copy=True)
    stats["shape_keys"] = written
    if args.report:
        Path(ROOT / args.report).write_text(json.dumps(stats, indent=2) + "\n", encoding="utf-8")
    print("MPFB face shapes:", json.dumps({k: v for k, v in stats.items() if k != "largest_offset_mm"}))


def coords_of(block: bpy.types.ShapeKey) -> np.ndarray:
    a = np.zeros(len(block.data) * 3)
    block.data.foreach_get("co", a)
    return a.reshape(-1, 3)


main()
