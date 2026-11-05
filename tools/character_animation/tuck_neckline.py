"""Tuck a draft top's neckline onto the skin, so the inside of the shell does not show.

The cast builder makes a top as an offset shell with thickness. Its neckline is cut
by a horizontal plane at the back and sides, and on the sloping shoulder tops that
leaves the shell's rim standing a centimetre or more off the skin. From the front,
the inside of the shell and the gap under it read as small dark marks at the
shoulder seams (owner Mac pass, 2026-10-21, on Elias).

This pulls the vertices of the garment within `--band-m` of the neckline rim
toward the body, scaling its distance from the skin down to `--rim-scale` at the
rim and blending back to the original shape at the band's edge. Inner and outer
layers scale together, so the shell keeps its order and never crosses the skin.
The front of the neckline, which already lies close, keeps its shape, because
moving a few vertices of the decimated chest shows as a flat patch. Skinning
weights are untouched (vertices only move). The rim is found as the
garment's sharp edges above the shoulders.

The .blend is updated in place; then re-export the GLB with add_motion_clips.py,
which rebuilds the same GLB byte for byte from the committed .blend.

Run from the repository root with Blender 5.2.2, or with the bpy 5.2.2 module:

    python -I tools/character_animation/tuck_neckline.py \
        --blend assets/blender/characters/Elias_Ward_v01_draft.blend --garment Elias_Sweatshirt
"""
from __future__ import annotations

import argparse
import math
import sys

import bpy  # noqa: I001
import bmesh
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else sys.argv[1:]
    parser = argparse.ArgumentParser()
    parser.add_argument("--blend", required=True)
    parser.add_argument("--garment", required=True, help="Garment mesh object, e.g. Elias_Sweatshirt")
    parser.add_argument("--body", default="", help="Body mesh object (default: <prefix>Ward_Body style, the mesh with shape keys)")
    parser.add_argument("--band-m", type=float, default=0.035, help="How far from the rim the tuck reaches")
    parser.add_argument("--rim-scale", type=float, default=0.3, help="Distance from the skin kept at the rim")
    parser.add_argument("--front-keep-half-width-m", type=float, default=0.07,
                        help="The front of the neckline within this |x| keeps its shape (it already lies close)")
    parser.add_argument("--above-neck-m", type=float, default=-0.04,
                        help="Rim edges are those above neck_01's head plus this (excludes cuffs and hem)")
    return parser.parse_args(argv)


def main() -> None:
    args = parse_args()
    bpy.ops.wm.open_mainfile(filepath=args.blend)
    garment = bpy.data.objects[args.garment]
    body = bpy.data.objects[args.body] if args.body else next(
        o for o in bpy.data.objects if o.type == "MESH" and o.data.shape_keys and o.parent == garment.parent)
    rig = garment.parent
    if garment.matrix_world != body.matrix_world:
        raise RuntimeError("garment and body must share a transform")
    neck = rig.matrix_world @ rig.data.bones["neck_01"].head_local
    neck_z = neck.z

    body_bm = bmesh.new()
    body_bm.from_mesh(body.data)
    tree = BVHTree.FromBMesh(body_bm)

    bm = bmesh.new()
    bm.from_mesh(garment.data)
    bm.normal_update()
    rim = {v.index: v.co.copy() for e in bm.edges
           if len(e.link_faces) == 2 and e.calc_face_angle() > math.radians(60)
           for v in e.verts if v.co.z > neck_z + args.above_neck_m}
    if not rim:
        raise RuntimeError("no neckline rim found")
    kd = KDTree(len(rim))
    for i, (_index, co) in enumerate(rim.items()):
        kd.insert(co, i)
    kd.balance()

    moved = 0
    largest = 0.0
    for v in bm.verts:
        _co, _i, dist = kd.find(v.co)
        w = max(0.0, 1.0 - dist / args.band_m)
        if w <= 0.0:
            continue
        if v.co.y < neck.y - 0.05:
            # Front (-Y): fade the tuck in from the centre, so the chest is untouched.
            keep = args.front_keep_half_width_m
            w *= min(1.0, max(0.0, (abs(v.co.x - neck.x) - keep) / 0.05))
            if w <= 0.0:
                continue
        w = w * w * (3.0 - 2.0 * w)  # smoothstep: no crease where the band ends
        hit, normal, _f, _d = tree.find_nearest(v.co)
        if hit is None:
            continue
        offset = (v.co - hit).dot(normal)
        if offset <= 0.0:
            continue
        new = hit + normal * offset * (1.0 - w * (1.0 - args.rim_scale))
        largest = max(largest, (new - v.co).length)
        v.co = new
        moved += 1
    bm.to_mesh(garment.data)
    garment.data.update()
    bm.free()
    body_bm.free()
    bpy.ops.wm.save_mainfile(filepath=args.blend, compress=True)
    print(f"TUCK {args.garment}: {len(rim)} rim vertices, {moved} moved, largest move {largest * 1000:.1f} mm")


if __name__ == "__main__":
    main()
