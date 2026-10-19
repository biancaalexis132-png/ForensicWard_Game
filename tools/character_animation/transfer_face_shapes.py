"""Give a cast member Naomi's finished face morphs (MPFB2 faceunits, visemes and blinks).

Every cast member is built from the same MPFB2 base mesh as Naomi
(tools/blender/characters/build_cast_member.py), and each builder keeps the head at
full resolution, so a face vertex of either character is still a vertex of the base
mesh. This script finds that base vertex for every face vertex of Naomi v07 and of
the cast member, and moves each of the target's face vertices by Naomi's offset for
the same base vertex, scaled by the ratio of the two faces' eye spacing. Vertices
that are not on the base (lashes, brow strokes) take the inverse-distance mean of
their nearest matched neighbours. The 32 morph targets replace the stable shapes
build_animated_character.py authored, so every character shares Naomi's lip-sync
and expression set. It needs no MPFB add-on: the offsets come from Naomi's file.

Inputs are never modified; outputs must be new files. Run from the repository root:

    blender -b --python-exit-code 1 --python tools/character_animation/transfer_face_shapes.py -- \
        --profile tools/character_animation/profiles/staff_voss_v01_face.json
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

import bpy  # noqa: I001
import numpy as np
from mathutils.kdtree import KDTree

ROOT = Path.cwd()
if not (ROOT / "project.godot").exists():
    raise SystemExit("Run from the repository root (project.godot not found).")
sys.path.insert(0, str(ROOT / "tools/character_animation"))
from provenance import provenance_path  # noqa: E402

_spec = importlib.util.spec_from_file_location("animated_builder",
                                               ROOT / "tools/character_animation/build_animated_character.py")
builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(builder)

MATCH_TOLERANCE_M = 2e-4


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--profile", required=True)
    return p.parse_args(argv)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def coords(mesh: bpy.types.Mesh) -> np.ndarray:
    a = np.zeros(len(mesh.vertices) * 3)
    mesh.vertices.foreach_get("co", a)
    return a.reshape(-1, 3)


def key_coords(block, n: int) -> np.ndarray:
    a = np.zeros(n * 3)
    block.data.foreach_get("co", a)
    return a.reshape(-1, 3)


def base_positions(path: Path, body_name: str, weights: dict | None) -> np.ndarray:
    """Base mesh vertex positions under the given macro key weights (stored ones if None)."""
    bpy.ops.wm.open_mainfile(filepath=str(path))
    body = bpy.data.objects[body_name]
    blocks = body.data.shape_keys.key_blocks
    n = len(body.data.vertices)
    basis = key_coords(blocks["Basis"], n)
    out = basis.copy()
    for kb in blocks[1:]:
        w = kb.value if weights is None else weights[kb.name]
        out += w * (key_coords(kb, n) - basis)
    return out


def match(points: np.ndarray, base: np.ndarray, tol: float) -> np.ndarray:
    """Index of the base vertex at each point, or -1."""
    tree = KDTree(len(base))
    for i, p in enumerate(base):
        tree.insert(p, i)
    tree.balance()
    out = np.full(len(points), -1)
    for i, p in enumerate(points):
        _co, j, d = tree.find(p)
        if d < tol:
            out[i] = j
    return out


def eye_spacing(left: str, right: str) -> float:
    centres = []
    for name in (left, right):
        obj = bpy.data.objects[name]
        pts = np.array([obj.matrix_world @ v.co for v in obj.data.vertices])
        centres.append((pts.min(0) + pts.max(0)) / 2)
    return float(np.linalg.norm(centres[0] - centres[1]))


def main() -> None:
    args = parse_args()
    profile_path = ROOT / args.profile
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    fs = profile["face_source"]
    source = ROOT / profile["source_blend"]
    outputs = {k: ROOT / v for k, v in profile["outputs"].items()}
    if outputs["blend"].resolve() == source.resolve():
        raise RuntimeError("Output .blend must differ from the source.")

    # Naomi: her face offsets per base vertex.
    naomi_base = base_positions(ROOT / fs["base_blend"], fs["base_body"], None)
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / fs["blend"]))
    nbody = bpy.data.objects[fs["body"]]
    nrest = coords(nbody.data)
    n_idx = match(nrest, naomi_base, MATCH_TOLERANCE_M)
    names = [kb.name for kb in nbody.data.shape_keys.key_blocks[1:]]
    nbasis = key_coords(nbody.data.shape_keys.key_blocks[0], len(nrest))
    naomi_ipd = eye_spacing("Naomi_Eye_L", "Naomi_Eye_R")
    offsets = {}
    for name in names:
        d = key_coords(nbody.data.shape_keys.key_blocks[name], len(nrest)) - nbasis
        per_base = np.zeros((len(naomi_base), 3))
        per_base[n_idx[n_idx >= 0]] = d[n_idx >= 0]
        offsets[name] = per_base
    has = np.zeros(len(naomi_base), dtype=bool)
    has[n_idx[n_idx >= 0]] = True

    # The cast member's base positions, in its final scale.
    bpy.ops.wm.open_mainfile(filepath=str(source))
    rig = bpy.data.objects[profile["objects"]["rig"]]
    weights = json.loads(rig["cast_macro_weights"])
    scale = float(rig["cast_base_scale"])
    floor = float(rig["cast_base_floor_z_m"])
    offset = float(rig.get("cast_offset_z_m", 0.0))
    tb = profile["target_base"]
    target_base = base_positions(ROOT / tb["blend"], tb["body"], weights)
    target_base[:, 2] -= floor
    target_base *= scale
    target_base[:, 2] += offset

    bpy.ops.wm.open_mainfile(filepath=str(source))
    rig = bpy.data.objects[profile["objects"]["rig"]]
    body = bpy.data.objects[profile["objects"]["face_mesh"]]
    rest = coords(body.data) if not body.data.shape_keys else key_coords(body.data.shape_keys.key_blocks[0],
                                                                         len(body.data.vertices))
    t_idx = match(rest, target_base, MATCH_TOLERANCE_M * scale)
    ratio = eye_spacing(profile["objects"]["eye_l"], profile["objects"]["eye_r"]) / naomi_ipd
    usable = (t_idx >= 0) & has[np.maximum(t_idx, 0)]
    # Nearest matched neighbours for vertices that are not on the base (lashes, brows).
    tree = KDTree(int(usable.sum()))
    usable_idx = np.flatnonzero(usable)
    for j, i in enumerate(usable_idx):
        tree.insert(rest[i], j)
    tree.balance()
    fill = []
    for i in np.flatnonzero(~usable):
        near = [(j, d) for _c, j, d in tree.find_n(rest[i], 4) if d < 0.01]
        if near:
            w = np.array([1.0 / max(d, 1e-5) for _j, d in near])
            fill.append((i, [usable_idx[j] for j, _d in near], w / w.sum()))

    v_sel = bpy.context.view_layer.objects
    v_sel.active = body
    if body.data.shape_keys:
        body.shape_key_clear()
    body.shape_key_add(name="Basis", from_mix=False)
    moved = {}
    for name in names:
        d = np.zeros_like(rest)
        d[usable] = offsets[name][t_idx[usable]] * ratio
        for i, idx, w in fill:
            d[i] = (d[idx] * w[:, None]).sum(0)
        kb = body.shape_key_add(name=name, from_mix=False)
        kb.data.foreach_set("co", (rest + d).ravel())
        moved[name] = int((np.linalg.norm(d, axis=1) > 1e-5).sum())
    # A morph Naomi's file leaves at rest (the silence viseme) stays at rest here too.
    empty = [n for n, c in moved.items() if c == 0 and np.abs(offsets[n]).max() > 1e-6]
    if empty:
        raise RuntimeError(f"Morph targets moved nothing: {empty}")

    meshes = [body] + [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig and o is not body]
    builder.export_glb(rig, meshes, outputs["glb"])
    glb = builder.inspect_glb(outputs["glb"])
    morphs = {n for m in glb["morph_targets"] for n in m["targets"]}
    if not set(names) <= morphs:
        raise RuntimeError(f"GLB is missing morph targets: {sorted(set(names) - morphs)}")
    outputs["blend"].parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(outputs["blend"]), compress=True, copy=True)
    report = {
        "blender_version": bpy.app.version_string,
        "profile": provenance_path(profile_path, ROOT),
        "profile_sha256": sha256(profile_path),
        "source": {"path": profile["source_blend"], "sha256": sha256(source)},
        "face_source": {"path": fs["blend"], "sha256": sha256(ROOT / fs["blend"])},
        "naomi_vertices_on_base": int((n_idx >= 0).sum()),
        "target_vertices_on_base_with_offsets": int(usable.sum()),
        "target_vertices_filled_from_neighbours": len(fill),
        "eye_spacing_ratio": round(ratio, 4),
        "morph_targets": names,
        "vertices_moved": moved,
        "glb": glb,
    }
    outputs["report"].parent.mkdir(parents=True, exist_ok=True)
    outputs["report"].write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    print(f"FACE SHAPES {profile['character_id']} OK: {len(names)} morphs, {int(usable.sum())} base matches, "
          f"{len(fill)} filled, ratio {ratio:.3f}")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.stdout.flush()
