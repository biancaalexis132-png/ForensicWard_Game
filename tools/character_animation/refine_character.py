"""Fix review defects on a finished character and save it as a new version.

Runs after build_animated_character.py (and bake_mpfb_face_shapes.py, when used).
It keeps the rig, clips and every face morph of the source, and only changes the
parts a profile's `refine` section names:

1. `skin_rim`: paints out a texture-painted lash line that sits on the lid crease
   instead of the lid margin. When the eye closes the skin under it does not
   move, so it read as a wavy dark rim above the closed lid. Texels inside the
   band are refilled from the skin around them.
2. `lashes`: the lash strips follow the upper lid in every lid shape, but a
   closed lid buried them under the skin. In each named shape, any lash vertex
   behind the deformed skin is pushed out through it, and the shape's lid
   motion is relaxed a little so the closed lid line is smooth.
3. `trousers`: replaces the bottom of each trouser leg (below `cut_m`) with a
   straight tube to `hem_m` and a short turned-in hem. The source garment is a
   thin closed shell whose two walls crossed at the old hem and showed as
   torn, flickering teeth. The inner wall is kept open inside the leg.
4. `shoes`: relaxes the shoe hulls so they read as rounded clogs, keeping the sole.

The source .blend is never modified. Run from the repository root:

    /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
        --python tools/character_animation/refine_character.py -- \
        --profile tools/character_animation/profiles/staff_bennett_v07.json

or, with the bpy 5.2.2 module: `python -c "import sys; sys.argv=['b','--','--profile',
'tools/character_animation/profiles/staff_bennett_v07.json']; import bpy; exec(open(
'tools/character_animation/refine_character.py').read())"`. Add `--no-render` to skip
the Cycles review sheets.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import sys
from pathlib import Path

import bpy  # noqa: I001  (bpy must load before bmesh in the standalone module)
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

ROOT = Path.cwd()
if not (ROOT / "project.godot").exists():
    raise SystemExit("Run from the repository root (project.godot not found).")
sys.path.insert(0, str(ROOT / "tools/character_animation"))
from provenance import provenance_path

_spec = importlib.util.spec_from_file_location(
    "build_animated_character", ROOT / "tools/character_animation/build_animated_character.py")
builder = importlib.util.module_from_spec(_spec)
_spec.loader.exec_module(builder)


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", required=True)
    parser.add_argument("--no-render", action="store_true")
    return parser.parse_args(argv)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def eye_centre(name: str) -> np.ndarray:
    eye = bpy.data.objects[name]
    pts = np.array([eye.matrix_world @ v.co for v in eye.data.vertices])
    return (pts.min(0) + pts.max(0)) / 2


def shape_array(key: bpy.types.ShapeKey, count: int) -> np.ndarray:
    a = np.zeros(count * 3)
    key.data.foreach_get("co", a)
    return a.reshape(-1, 3)


# --------------------------------------------------------------------------- skin

def paint_out_rim(body: bpy.types.Object, cfg: dict, eyes: list[np.ndarray]) -> dict:
    """Refill the texels of a painted lid-crease band from the skin around them."""
    src = bpy.data.images[cfg["image"]]
    width, height = src.size
    pos, valid = builder.bake_positions(body, width, cfg.get("material_index", 0))
    px = np.empty(width * height * 4, dtype=np.float32)
    src.pixels.foreach_get(px)
    px = px.reshape(height, width, 4)
    half_w, half_h = cfg["ellipse_half_m"]
    lo, hi = cfg["band"]
    mask = np.zeros((height, width), bool)
    for centre in eyes:
        rel = pos - centre
        d = np.sqrt((rel[..., 0] / half_w) ** 2 + (rel[..., 2] / half_h) ** 2)
        mask |= (valid & (np.abs(rel[..., 0]) < half_w * hi) & (rel[..., 2] > cfg["above_centre_m"])
                 & (rel[..., 1] < 0.0) & (d > lo) & (d < hi))
    col = px[..., :3].copy()
    known = valid & ~mask
    todo = mask.copy()
    passes = 0
    while todo.any() and passes < 200:
        acc = np.zeros_like(col)
        cnt = np.zeros((height, width))
        for dy, dx in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (1, -1), (-1, 1), (-1, -1)):
            k = np.roll(np.roll(known, dy, 0), dx, 1)
            acc += np.roll(np.roll(col, dy, 0), dx, 1) * k[..., None]
            cnt += k
        fill = todo & (cnt > 0)
        col[fill] = acc[fill] / cnt[fill][:, None]
        known |= fill
        todo &= ~fill
        passes += 1
    if todo.any():
        raise RuntimeError(f"{int(todo.sum())} rim texels could not be refilled")
    px[..., :3] = np.where(mask[..., None], col, px[..., :3])
    out = src.copy()
    out.name = cfg["output_image"]
    out.pixels.foreach_set(px.ravel())
    out.update()
    out.pack()
    for mat in body.data.materials:
        if mat and mat.node_tree:
            for node in mat.node_tree.nodes:
                if node.type == "TEX_IMAGE" and node.image == src:
                    node.image = out
    return {"image": out.name, "texels_refilled": int(mask.sum()), "fill_passes": passes}


def paint_lash_line(body: bpy.types.Object, cfg: dict, image_name: str) -> dict:
    """Darken the skin right at the upper lid margin, under the lash roots.

    The line is painted on the lid skin itself, so it rides down with the lid and
    reads as the lash line of a closed eye; open, it frames the eye.
    """
    mesh = body.data
    count = len(mesh.vertices)
    lash_index = [i for i, m in enumerate(mesh.materials) if m and m.name == cfg["lash_material"]][0]
    lash = sorted({v for p in mesh.polygons if p.material_index == lash_index for v in p.vertices})
    base = shape_array(mesh.shape_keys.key_blocks["Basis"], count) if mesh.shape_keys else \
        np.array([v.co[:] for v in mesh.vertices])
    roots = base[lash]
    img = bpy.data.images[image_name]
    width, height = img.size
    pos, valid = builder.bake_positions(body, width, 0)
    px = np.empty(width * height * 4, dtype=np.float32)
    img.pixels.foreach_get(px)
    px = px.reshape(height, width, 4)
    flat = pos.reshape(-1, 3)
    idx = np.flatnonzero(valid.ravel())
    near = np.full(len(idx), np.inf)
    for r in roots:
        d = np.linalg.norm(flat[idx] - r, axis=1)
        near = np.minimum(near, d)
    w = np.clip(1.0 - (near - cfg["line_core_m"]) / cfg["line_feather_m"], 0.0, 1.0) * cfg["line_strength"]
    dark = np.array(srgb_to_linear_hex(cfg["line_color_srgb_hex"]))
    col = px.reshape(-1, 4)
    col[idx, :3] = col[idx, :3] * (1 - w[:, None]) + dark[None, :] * w[:, None]
    img.pixels.foreach_set(col.ravel())
    img.update()
    img.pack()
    return {"texels_darkened": int((w > 0.05).sum())}


def srgb_to_linear_hex(value: str) -> list[float]:
    rgb = [int(value.lstrip("#")[i:i + 2], 16) / 255 for i in (0, 2, 4)]
    return [c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4 for c in rgb]


# --------------------------------------------------------------------------- lids and lashes

def mesh_neighbours(mesh: bpy.types.Mesh) -> list[list[int]]:
    nbr: list[set[int]] = [set() for _ in mesh.vertices]
    for e in mesh.edges:
        a, b = e.vertices
        nbr[a].add(b)
        nbr[b].add(a)
    return [sorted(n) for n in nbr]


def _lash_strips(mesh: bpy.types.Mesh, lash_index: int) -> list[list[int]]:
    parent: dict[int, int] = {}

    def find(x: int) -> int:
        while parent.setdefault(x, x) != x:
            parent[x] = parent[parent[x]]
            x = parent[x]
        return x

    for p in mesh.polygons:
        if p.material_index == lash_index:
            vs = list(p.vertices)
            for v in vs[1:]:
                parent[find(v)] = find(vs[0])
    groups: dict[int, list[int]] = {}
    for v in parent:
        groups.setdefault(find(v), []).append(v)
    return [sorted(g) for g in groups.values()]


def fix_lids(body: bpy.types.Object, cfg: dict) -> dict:
    mesh = body.data
    count = len(mesh.vertices)
    lash_index = [i for i, m in enumerate(mesh.materials) if m and m.name == cfg["lash_material"]][0]
    lash = sorted({v for p in mesh.polygons if p.material_index == lash_index for v in p.vertices})
    lash_set = set(lash)
    skin_polys = [p for p in mesh.polygons if p.material_index != lash_index]
    keys = mesh.shape_keys.key_blocks
    base = shape_array(keys["Basis"], count)
    strips = _lash_strips(mesh, lash_index)
    nbr = mesh_neighbours(mesh)
    # The nearest skin vertex to each lash vertex, at rest, anchors it to the lid.
    skin_ids = np.array(sorted(set(range(count)) - lash_set))
    anchors, dist_to_skin = {}, {}
    for i in lash:
        d = np.linalg.norm(base[skin_ids] - base[i], axis=1)
        anchors[i] = int(skin_ids[d.argmin()])
        dist_to_skin[i] = float(d.min())
    # A lash strip is a ribbon: a row of roots on the lid and a row of tips. Each tip
    # follows its own root so the ribbon moves without twisting.
    root_of = {}
    for strip in strips:
        ranked = sorted(strip, key=lambda i: dist_to_skin[i])
        roots = set(ranked[:len(ranked) // 2])
        for i in strip:
            if i in roots:
                root_of[i] = i
            else:
                partners = [j for j in nbr[i] if j in roots]
                root_of[i] = min(partners or roots, key=lambda j: np.linalg.norm(base[j] - base[i]))
    report = {"lash_strips": len(strips)}
    for name in cfg["shapes"]:
        co = shape_array(keys[name], count)
        delta = co - base
        moved = np.linalg.norm(delta, axis=1) > 1e-5
        # Relax the lid motion of skin vertices: the closed lid line follows a smooth curve.
        alpha = cfg["smoothing_factor"]
        skin_moving = [i for i in np.flatnonzero(moved) if i not in lash_set]
        for _ in range(cfg["smoothing_iterations"]):
            new = delta.copy()
            for i in skin_moving:
                ring = [j for j in nbr[i] if j not in lash_set]
                if ring:
                    new[i] = (1 - alpha) * delta[i] + alpha * delta[ring].mean(0)
            delta = new
        co = base + delta
        # Each lash vertex moves with the lid skin it sits on, then the strip goes out
        # through the closed lid wherever the skin covers it. The push is smoothed
        # along the strip so the lashes stay a clean line.
        verts = [Vector(c) for c in co]
        tree = BVHTree.FromPolygons(verts, [tuple(p.vertices) for p in skin_polys])
        placed = {i: base[i] + delta[anchors[root_of[i]]] for i in lash}
        push, normals = {}, {}
        for i in lash:
            if np.linalg.norm(delta[anchors[root_of[i]]]) < 1e-5:
                push[i], normals[i] = 0.0, np.zeros(3)
                continue
            hit, normal, _idx, _dist = tree.find_nearest(Vector(placed[i]))
            depth = (Vector(placed[i]) - hit).dot(normal) if hit is not None else 1.0
            push[i] = max(0.0, cfg["clearance_m"] - depth)
            normals[i] = np.array(normal) if hit is not None else np.zeros(3)
        for _ in range(cfg.get("lash_push_smoothing", 6)):
            push = {i: max(push[i], float(np.mean([push[j] for j in nbr[i] if j in lash_set] or [push[i]])))
                    for i in lash}
        pushed = 0
        for i in lash:
            push[i], normals[i] = push[root_of[i]], normals[root_of[i]]
        for i in lash:
            n = normals[i]
            if cfg["push_out"] and push[i] > 0 and np.linalg.norm(n) > 0:
                placed[i] = placed[i] + n / np.linalg.norm(n) * push[i]
                pushed += 1
            co[i] = placed[i]
        keys[name].data.foreach_set("co", co.astype(np.float32).ravel())
        report[name] = {"skin_vertices_relaxed": len(skin_moving), "lash_vertices_pushed_out": pushed}
    mesh.update()
    return report


# --------------------------------------------------------------------------- clothing

def _boundary_loops(bm: bmesh.types.BMesh) -> list[dict]:
    edges = [e for e in bm.edges if e.is_boundary]
    by_vert: dict = {}
    for e in edges:
        for v in e.verts:
            by_vert.setdefault(v, []).append(e)
    loops, seen = [], set()
    for e in edges:
        if e in seen:
            continue
        stack, comp = [e], []
        while stack:
            x = stack.pop()
            if x in seen:
                continue
            seen.add(x)
            comp.append(x)
            for v in x.verts:
                stack.extend(y for y in by_vert[v] if y not in seen)
        verts = {v for x in comp for v in x.verts}
        centre = sum((v.co for v in verts), Vector()) / len(verts)
        radius = float(np.mean([(v.co - centre).xy.length for v in verts]))
        loops.append({"edges": comp, "verts": verts, "centre": centre, "radius": radius})
    return loops


def rebuild_hems(obj: bpy.types.Object, cfg: dict) -> dict:
    """Cut each leg at cut_m and give it a straight tube and turned-in hem to hem_m."""
    cut, hem = cfg["cut_m"], cfg["hem_m"]
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    geom = bm.verts[:] + bm.edges[:] + bm.faces[:]
    bmesh.ops.bisect_plane(bm, geom=geom, plane_co=(0, 0, cut), plane_no=(0, 0, 1), clear_inner=True)
    loops = _boundary_loops(bm)
    report = []
    for side in (True, False):
        legs = sorted([lp for lp in loops if (lp["centre"].x > 0) == side], key=lambda lp: -lp["radius"])
        if len(legs) != 2:
            raise RuntimeError(f"expected an outer and inner wall per leg, found {len(legs)}")
        outer, inner = legs
        for v in inner["verts"]:
            d = v.co - inner["centre"]
            d.z = 0
            v.co.xy -= d.xy.normalized() * cfg["inner_wall_tuck_m"]
        c, r = outer["centre"], outer["radius"]
        tube = bmesh.ops.extrude_edge_only(bm, edges=outer["edges"])
        for v in (g for g in tube["geom"] if isinstance(g, bmesh.types.BMVert)):
            d = v.co - c
            d.z = 0
            v.co.xy = c.xy + d.xy.normalized() * (0.5 * d.length + 0.5 * r * (1.0 + cfg["flare"]))
            v.co.z = hem
        rim = [g for g in tube["geom"] if isinstance(g, bmesh.types.BMEdge) and g.is_boundary]
        for e in rim:
            e.smooth = False
        fold = bmesh.ops.extrude_edge_only(bm, edges=rim)
        for v in (g for g in fold["geom"] if isinstance(g, bmesh.types.BMVert)):
            d = v.co - c
            d.z = 0
            v.co.xy = c.xy + d.xy.normalized() * (d.length - cfg["fold_depth_m"])
            v.co.z = hem + cfg["fold_height_m"]
        report.append({"side": "left" if side else "right", "outer_radius_m": round(r, 4),
                       "loop_vertices": len(outer["verts"])})
    # New faces take a plain patch of cloth from just above the cut, so the
    # stretched texels of the old hem do not streak down the tube.
    uv = bm.loops.layers.uv.active
    new_faces = [f for f in bm.faces if len(f.verts) == 4 and all(v.co.z <= cut + 1e-5 for v in f.verts)]
    ref = [f for f in bm.faces if cut + 0.01 < f.calc_center_median().z < cut + 0.05 and f.calc_center_median().y < 0]
    for f in new_faces:
        centre = f.calc_center_median()
        best = min((g for g in ref if (g.calc_center_median().x > 0) == (centre.x > 0)),
                   key=lambda g: (g.calc_center_median().xy - centre.xy).length)
        u = sum((lp[uv].uv for lp in best.loops), Vector((0, 0))) / len(best.loops)
        for lp in f.loops:
            lp[uv].uv = u
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return {"cut_m": cut, "hem_m": hem, "legs": report, "new_faces": len(new_faces)}


def relax_shoes(obj: bpy.types.Object, cfg: dict) -> dict:
    bm = bmesh.new()
    bm.from_mesh(obj.data)
    upper = [v for v in bm.verts if v.co.z > cfg["keep_sole_below_m"]]
    for _ in range(cfg["iterations"]):
        bmesh.ops.smooth_vert(bm, verts=upper, factor=cfg["factor"], use_axis_x=True, use_axis_y=True,
                              use_axis_z=True)
    bm.to_mesh(obj.data)
    bm.free()
    obj.data.update()
    return {"vertices_relaxed": len(upper), "iterations": cfg["iterations"]}


# --------------------------------------------------------------------------- review

def render_review(profile: dict, body: bpy.types.Object, out_dir: Path) -> list[Path]:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 16
    scene.cycles.seed = 0
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = True
    scene.render.resolution_percentage = 100
    rig = bpy.data.objects[profile["objects"]["rig"]]
    rig.animation_data.use_nla = False
    rig.animation_data.action = bpy.data.actions["idle_neutral"]
    rig.animation_data.action_slot = rig.animation_data.action.slots[0]
    scene.frame_set(1)
    keys = body.data.shape_keys.key_blocks
    for k in keys:
        k.value = 0.0
    cam = scene.camera
    el, er = (Vector(eye_centre(profile["objects"][k])) for k in ("eye_l", "eye_r"))
    mid = (el + er) / 2
    version = profile["version"]
    out_dir.mkdir(parents=True, exist_ok=True)
    frames = []

    def shot(name, loc, target, lens, w, h):
        cam.location = loc
        cam.rotation_euler = (target - loc).to_track_quat("-Z", "Y").to_euler()
        cam.data.type, cam.data.lens = "PERSP", lens
        scene.render.resolution_x, scene.render.resolution_y = w, h
        path = (out_dir / f"Naomi_Bennett_{version}_{name}.png").resolve()
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        frames.append(path)

    eyes = mid + Vector((0, -0.35, 0))
    shot("eyes_open", eyes, mid, 85, 640, 360)
    keys["blink"].value = 0.5
    shot("eyes_half", eyes, mid, 85, 640, 360)
    keys["blink"].value = 1.0
    shot("eyes_closed", eyes, mid, 85, 640, 360)
    shot("eyes_closed_side", el + Vector((0.15, -0.06, 0)), el, 85, 640, 360)
    keys["blink"].value = 0.0
    shot("hems_front", Vector((0, -1.2, 0.14)), Vector((0, 0, 0.14)), 50, 640, 360)
    shot("hems_side", Vector((1.2, -0.4, 0.14)), Vector((0, 0, 0.14)), 50, 640, 360)
    shot("hems_back", Vector((-0.4, 1.2, 0.14)), Vector((0, 0, 0.14)), 50, 640, 360)
    sheet = out_dir / f"Naomi_Bennett_{version}_refine_sheet.png"
    builder.contact_sheet(frames, sheet)
    for p in frames:
        p.unlink()
    return [sheet]


# --------------------------------------------------------------------------- main

def main() -> None:
    args = parse_args()
    profile_path = (ROOT / args.profile).resolve()
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    source = ROOT / profile["source_blend"]
    outputs = {k: ROOT / v for k, v in profile["outputs"].items()}
    if outputs["blend"].resolve() == source.resolve():
        raise RuntimeError("Output .blend must differ from the source; the source is never modified.")
    source_digest = sha256(source)
    bpy.ops.wm.open_mainfile(filepath=str(source))
    objs = profile["objects"]
    rig = bpy.data.objects[objs["rig"]]
    body = bpy.data.objects[objs["face_mesh"]]
    meshes = [body] + [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig and o is not body]
    cfg = profile["refine"]
    eyes = [eye_centre(objs["eye_l"]), eye_centre(objs["eye_r"])]
    details = {}
    if cfg.get("skin_rim"):
        details["skin_rim"] = paint_out_rim(body, cfg["skin_rim"], eyes)
    if cfg.get("lashes"):
        details["lids"] = fix_lids(body, cfg["lashes"])
        if cfg["lashes"].get("line_strength"):
            image = cfg.get("skin_rim", {}).get("output_image", cfg["lashes"].get("image"))
            details["lash_line"] = paint_lash_line(body, cfg["lashes"], image)
    if cfg.get("trousers"):
        details["trousers"] = rebuild_hems(bpy.data.objects[cfg["trousers"]["object"]], cfg["trousers"])
    if cfg.get("shoes"):
        details["shoes"] = relax_shoes(bpy.data.objects[cfg["shoes"]["object"]], cfg["shoes"])
    for k in body.data.shape_keys.key_blocks:
        k.value = 0.0

    builder.export_glb(rig, meshes, outputs["glb"])
    glb = builder.inspect_glb(outputs["glb"])
    clips = [a["name"] for a in glb["animations"] if a["channels"] > 0]
    morphs = sorted({n for m in glb["morph_targets"] for n in m["targets"]})
    expected = set(profile["expected"]["clips"])
    if not expected <= set(clips):
        raise RuntimeError(f"GLB is missing clips: {sorted(expected - set(clips))}")
    if len(morphs) < profile["expected"]["morph_targets"]:
        raise RuntimeError(f"GLB has {len(morphs)} morph targets, expected {profile['expected']['morph_targets']}")

    renders = [] if args.no_render else render_review(profile, body, outputs["renders"])
    outputs["blend"].parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(outputs["blend"]), compress=True, copy=True)
    tris = sum(sum(len(p.vertices) - 2 for p in o.data.polygons) for o in meshes)
    report = {
        "blender_version": bpy.app.version_string,
        "profile": provenance_path(profile_path, ROOT),
        "profile_sha256": sha256(profile_path),
        "source": {"path": profile["source_blend"], "sha256": source_digest},
        "refinements": details,
        "clips": clips,
        "morph_targets": morphs,
        "glb": glb,
        "triangles": tris,
    }
    outputs["report"].parent.mkdir(parents=True, exist_ok=True)
    outputs["report"].write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    manifest = {
        "asset_id": f"CHR_{profile['display_name'].replace(' ', '')}_{profile['version']}",
        "character_id": profile["character_id"],
        "version": profile["version"],
        "production_status": profile["production_status"],
        "approved": False,
        "builder": "tools/character_animation/refine_character.py",
        "profile": provenance_path(profile_path, ROOT),
        "profile_sha256": sha256(profile_path),
        "blender_version": bpy.app.version_string,
        "inputs": [{"path": profile["source_blend"], "sha256": source_digest,
                    "used": "finished character: rig, clips and face morphs kept; see refinements"}],
        "external_assets": [],
        "licence": "Inherits the source character's provenance and licence (original work plus MPFB2 CC0 face targets).",
        "generated": sorted(details),
        "triangle_count": tris,
        "clips": clips,
        "morph_targets": morphs,
        "outputs": {"blend": profile["outputs"]["blend"], "glb": profile["outputs"]["glb"],
                    "report": profile["outputs"]["report"],
                    "renders": [provenance_path(p, ROOT) for p in renders]},
        "known_limitations": profile.get("known_limitations", []),
    }
    outputs["manifest"].parent.mkdir(parents=True, exist_ok=True)
    outputs["manifest"].write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"REFINED {profile['character_id']} {profile['version']} OK: {len(clips)} clips, "
          f"{len(morphs)} morph targets, {tris} triangles, {len(renders)} review sheets")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.stdout.flush()
