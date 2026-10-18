"""Add the cast animation standard to a rigged character .blend and export a GLB.

Reusable for every Forensic Ward character. Character specifics live in
`profiles/<character_id>.json` (source file, object names, a role -> bone map
and face landmarks); the clips and face shapes every character shares live in
`clip_library.json`. Nothing assumes a bone naming or axis convention: clip
rotations are written in the character's own frame (flex, turn, tilt, raise,
swing) and converted per bone from its rest orientation.

What it does, in order:
1. Opens the source .blend read-only and checks the rig against the skinned mesh
   (every mapped bone must sit inside the vertices weighted to it).
2. Adds eyelashes and brow strokes to the face mesh.
3. Authors face morph targets: blink, blink_L, blink_R, mouth_open and the
   expression names used by the acting cues.
4. Authors the body and gesture clips as actions on the rig (rest pose untouched).
5. Saves a NEW .blend and GLB (refuses to write over the source), inspects the GLB
   for non-empty animation channels and morph targets, renders review frames,
   and writes a rig/clip report and an asset manifest.

Run from the repository root:

    /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
        --python tools/character_animation/build_animated_character.py -- \
        --profile tools/character_animation/profiles/staff_bennett.json

or, with the bpy 5.2.2 module: `python -c "import sys; sys.argv=['b','--','--profile',
'tools/character_animation/profiles/staff_bennett.json']; exec(open(
'tools/character_animation/build_animated_character.py').read())"`.
Add `--no-render` to skip the Cycles review frames.
"""
from __future__ import annotations

import argparse
import hashlib
import json
import math
import struct
import sys
from pathlib import Path

import bpy  # noqa: I001  (bpy must load before bmesh in the standalone module)
import bmesh
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

ROOT = Path.cwd()
if not (ROOT / "project.godot").exists():
    raise SystemExit("Run from the repository root (project.godot not found).")
LIBRARY_PATH = ROOT / "tools/character_animation/clip_library.json"

GESTURE_ROLES_KEY = "body_roles_reserved_for_gestures"


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    parser = argparse.ArgumentParser()
    parser.add_argument("--profile", required=True)
    parser.add_argument("--no-render", action="store_true")
    return parser.parse_args(argv)


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def select_only(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)


def smoothstep(e0: float, e1: float, x):
    t = np.clip((x - e0) / (e1 - e0), 0.0, 1.0)
    return t * t * (3.0 - 2.0 * t)


# --------------------------------------------------------------------------- frame

class CharacterFrame:
    """The character's own axes, so clips never depend on rig conventions."""

    def __init__(self, profile: dict):
        self.forward = Vector(profile.get("forward", (0, -1, 0))).normalized()
        self.up = Vector(profile.get("up", (0, 0, 1))).normalized()
        self.left = self.up.cross(self.forward).normalized()

    def axis(self, rot: str, bone: bpy.types.Bone, rig: bpy.types.Object) -> Vector:
        head = rig.matrix_world @ bone.head_local
        tail = rig.matrix_world @ bone.tail_local
        direction = (tail - head).normalized()
        if rot == "flex":
            return self.left
        if rot == "turn":
            return self.up
        if rot == "tilt":
            return -self.forward
        if rot == "raise":
            lateral = direction - self.up * direction.dot(self.up)
            return lateral.normalized().cross(self.up).normalized()
        if rot == "swing":
            return direction.cross(self.forward).normalized()
        raise ValueError(f"Unknown rotation type {rot!r}")


# --------------------------------------------------------------------------- rig QA

def rig_report(rig: bpy.types.Object, meshes: list[bpy.types.Object], bones: dict) -> dict:
    """Check every mapped bone against the vertices weighted to it."""
    report = {"rig": rig.name, "bone_count": len(rig.data.bones), "roles": {}, "meshes": []}
    # Pool every skinned mesh: clothing covers (and replaces) most of the torso skin.
    co_parts, weight_maps = [], []
    for mesh in meshes:
        co_parts.append(np.array([mesh.matrix_world @ v.co for v in mesh.data.vertices]))
        index_to_name = {g.index: g.name for g in mesh.vertex_groups}
        weight_maps.append([{index_to_name[g.group]: g.weight for g in v.groups} for v in mesh.data.vertices])
    co = np.concatenate(co_parts)
    all_weights = [m for part in weight_maps for m in part]
    failures = []
    for role, name in bones.items():
        if name not in rig.data.bones:
            failures.append(f"{role}: bone {name!r} missing")
            continue
        bone = rig.data.bones[name]
        head = np.array(rig.matrix_world @ bone.head_local)
        tail = np.array(rig.matrix_world @ bone.tail_local)
        entry = {"bone": name, "head": head.round(4).tolist(), "tail": tail.round(4).tolist()}
        w = np.array([m.get(name, 0.0) for m in all_weights])
        if w.sum() > 0:
            centroid = (co * w[:, None]).sum(0) / w.sum()
            seg = tail - head
            t = np.clip(np.dot(centroid - head, seg) / max(1e-9, np.dot(seg, seg)), 0, 1)
            gap = float(np.linalg.norm(centroid - (head + seg * t)))
            entry["weighted_vertices"] = int((w > 0.01).sum())
            entry["centroid_to_bone_m"] = round(gap, 4)
            # The bone must run through the flesh it moves: its midpoint lies
            # inside the box of strongly weighted vertices (2 cm margin). A rig
            # left offset from the mesh, as v02's was, fails this at once.
            strong = co[w > 0.05]
            mid = (head + tail) / 2
            inside = bool(np.all(mid > strong.min(0) - 0.02) and np.all(mid < strong.max(0) + 0.02))
            entry["bone_inside_weighted_volume"] = inside
            if not inside:
                failures.append(f"{role}: bone {name} lies outside the vertices it deforms")
        report["roles"][role] = entry
    for mesh in meshes:
        mod = next((m for m in mesh.modifiers if m.type == "ARMATURE"), None)
        report["meshes"].append({
            "name": mesh.name,
            "armature_modifier": bool(mod and mod.object == rig),
            "vertex_groups": len(mesh.vertex_groups),
            "shape_keys": list(mesh.data.shape_keys.key_blocks.keys()) if mesh.data.shape_keys else [],
        })
        if not mod or mod.object != rig:
            failures.append(f"{mesh.name} is not skinned to {rig.name}")
    report["failures"] = failures
    if failures:
        raise RuntimeError("Rig check failed:\n  " + "\n  ".join(failures))
    return report


# --------------------------------------------------------------------------- skin weights

def capture_weight_reference(spec: dict) -> dict:
    """Rebuild the full skinned body a garment was cut from, before it lost faces.

    Naomi v03's scrubs copied weights from the body after the covered torso and
    leg faces were deleted, so they took weights from the nearest surviving skin:
    the hanging hands and forearms. Re-running the v03 builder's own first steps
    reproduces the complete posed body to transfer from.
    """
    namespace = {"__name__": "weight_reference", "__file__": str(ROOT / spec["builder"])}
    exec(compile((ROOT / spec["builder"]).read_text(encoding="utf-8"), spec["builder"], "exec"), namespace)
    body, rig, *_rest = namespace["load_source"]()
    for step in spec.get("steps", []):
        namespace[step](body, rig)
    bone_names = {b.name for b in rig.data.bones}
    mesh = body.data
    names = [g.name for g in body.vertex_groups]
    return {
        "verts": np.array([v.co[:] for v in mesh.vertices]),
        "faces": [tuple(p.vertices) for p in mesh.polygons],
        "groups": {names[g.group]: [] for v in mesh.vertices for g in v.groups if names[g.group] in bone_names},
        "weights": [[(names[g.group], g.weight) for g in v.groups if names[g.group] in bone_names]
                    for v in mesh.vertices],
    }


def transfer_weights(reference: dict, targets: list[bpy.types.Object], exclude: list[str]) -> dict:
    # Hands and forearms hang beside the hips; leave them out of the reference so a
    # garment never takes weights from them (an arm gesture would drag the hem).
    def excluded(i: int) -> bool:
        pairs = reference["weights"][i]
        return bool(pairs) and max(pairs, key=lambda p: p[1])[0].startswith(tuple(exclude))
    drop = {i for i in range(len(reference["verts"])) if excluded(i)}
    faces = [f for f in reference["faces"] if not drop.intersection(f)]
    mesh = bpy.data.meshes.new("WeightReference")
    mesh.from_pydata(reference["verts"].tolist(), [], faces)
    ref = bpy.data.objects.new("WeightReference", mesh)
    bpy.context.scene.collection.objects.link(ref)
    groups = {name: ref.vertex_groups.new(name=name) for name in reference["groups"]}
    for i, pairs in enumerate(reference["weights"]):
        for name, w in pairs:
            groups[name].add([i], w, "REPLACE")
    summary = {}
    for obj in targets:
        for g in list(obj.vertex_groups):
            obj.vertex_groups.remove(g)
        for name in groups:
            obj.vertex_groups.new(name=name)
        select_only(obj)
        mod = obj.modifiers.new("WeightTransfer", "DATA_TRANSFER")
        mod.object = ref
        mod.use_vert_data = True
        mod.data_types_verts = {"VGROUP_WEIGHTS"}
        mod.vert_mapping = "POLYINTERP_NEAREST"
        mod.layers_vgroup_select_src = "ALL"
        mod.layers_vgroup_select_dst = "NAME"
        # Transfer must run before the armature modifier in the stack.
        bpy.ops.object.modifier_move_to_index(modifier=mod.name, index=0)
        bpy.ops.object.modifier_apply(modifier=mod.name)
        names = {g.index: g.name for g in obj.vertex_groups}
        dominant: dict[str, int] = {}
        for v in obj.data.vertices:
            ws = sorted(((g.weight, g.group) for g in v.groups), reverse=True)
            for w, gi in ws[4:]:
                obj.vertex_groups[gi].remove([v.index])
            kept = [(w, gi) for w, gi in ws[:4] if w > 0]
            total = sum(w for w, _ in kept)
            for w, gi in kept:
                obj.vertex_groups[gi].add([v.index], w / total, "REPLACE")
            if kept:
                dominant[names[kept[0][1]]] = dominant.get(names[kept[0][1]], 0) + 1
        for g in list(obj.vertex_groups):
            if not any(g.index == vg.group for v in obj.data.vertices for vg in v.groups):
                obj.vertex_groups.remove(g)
        summary[obj.name] = dict(sorted(dominant.items(), key=lambda kv: -kv[1]))
    bpy.data.objects.remove(ref, do_unlink=True)
    bpy.data.meshes.remove(mesh)
    return summary


# --------------------------------------------------------------------------- face

class Face:
    """Landmarks measured from the eyeballs and the face mesh itself."""

    def __init__(self, profile: dict, frame: CharacterFrame, body: bpy.types.Object):
        self.frame = frame
        self.body = body
        self.cfg = profile["face"]
        self.eyes = {}
        for side, key in (("L", "eye_l"), ("R", "eye_r")):
            eye = bpy.data.objects[profile["objects"][key]]
            pts = np.array([eye.matrix_world @ v.co for v in eye.data.vertices])
            centre = (pts.min(0) + pts.max(0)) / 2
            radius = float((pts.max(0) - pts.min(0)).max() / 2)
            self.eyes[side] = (Vector(centre), radius)
        cl, cr = self.eyes["L"][0], self.eyes["R"][0]
        self.eye_mid = (cl + cr) / 2
        # Lateral "outward" for each side, in the character frame.
        self.out = {"L": frame.left if (cl - self.eye_mid).dot(frame.left) > 0 else -frame.left}
        self.out["R"] = -self.out["L"]

    def coords(self) -> np.ndarray:
        return np.array([v.co[:] for v in self.body.data.vertices])

    def local(self, co: np.ndarray, centre: Vector) -> tuple[np.ndarray, ...]:
        d = co - np.array(centre)
        fwd = d @ np.array(self.frame.forward)
        up = d @ np.array(self.frame.up)
        lat = d @ np.array(self.frame.left)
        dist = np.linalg.norm(d, axis=1)
        return d, fwd, up, lat, dist

    def lid_margins(self, side: str) -> tuple[np.ndarray, np.ndarray, np.ndarray]:
        """Upper and lower eyelid margin elevation (deg) per azimuth bin."""
        centre, r = self.eyes[side]
        co = self.coords()
        _d, fwd, up, lat, dist = self.local(co, centre)
        sign = 1.0 if side == "L" else -1.0
        az = np.degrees(np.arctan2(lat * sign, fwd))
        el = np.degrees(np.arcsin(np.clip(up / np.maximum(dist, 1e-9), -1, 1)))
        near = (dist < 2.0 * r) & (dist > 0.7 * r) & (fwd > 0)
        bins = np.arange(-50, 55, 5.0)
        upper, lower = [], []
        for a in bins:
            band = near & (np.abs(az - a) < 4.0)
            u = el[band & (el > 0)]
            lo = el[band & (el < 0)]
            upper.append(u.min() if len(u) else np.nan)
            lower.append(lo.max() if len(lo) else np.nan)
        upper, lower = np.array(upper), np.array(lower)
        ok = ~np.isnan(upper) & ~np.isnan(lower)
        upper = np.interp(bins, bins[ok], upper[ok])
        lower = np.interp(bins, bins[ok], lower[ok])
        return bins, upper, lower

    def lid_weights(self, side: str, co: np.ndarray):
        centre, r = self.eyes[side]
        _d, fwd, up, lat, dist = self.local(co, centre)
        sign = 1.0 if side == "L" else -1.0
        az = np.degrees(np.arctan2(lat * sign, fwd))
        el = np.degrees(np.arcsin(np.clip(up / np.maximum(dist, 1e-9), -1, 1)))
        bins, upper, lower = self.lid_margins(side)
        up_m = np.interp(az, bins, upper)
        lo_m = np.interp(az, bins, lower)
        gap = np.maximum(up_m - lo_m, 0.0)
        region = ((fwd > -0.15 * r) & (dist < 2.3 * r)).astype(float)
        region = region * (1.0 - smoothstep(1.7 * r, 2.3 * r, dist))
        region = region * (1.0 - smoothstep(42.0, 60.0, np.abs(az)))
        w_upper = region * (el >= up_m - 1.5) * (1.0 - smoothstep(up_m + 5.0, up_m + 32.0, el))
        w_lower = region * (el <= lo_m + 1.5) * (1.0 - smoothstep(-lo_m + 4.0, -lo_m + 22.0, -el))
        return w_upper, w_lower, gap

    def rotate_about(self, co: np.ndarray, pivot: Vector, axis: Vector, deg: np.ndarray) -> np.ndarray:
        """Displacement of each point rotated by its own angle about axis through pivot."""
        p = co - np.array(pivot)
        k = np.array(axis.normalized())
        th = np.radians(deg)[:, None]
        cross = np.cross(k, p)
        dot = (p @ k)[:, None]
        rot = p * np.cos(th) + cross * np.sin(th) + k * dot * (1 - np.cos(th))
        return rot - p

    def lid_delta(self, co: np.ndarray, side: str, upper_deg, lower_deg, gap_scaled=False):
        centre, _r = self.eyes[side]
        wu, wl, gap = self.lid_weights(side, co)
        if gap_scaled:
            angle = wu * gap * upper_deg - wl * gap * lower_deg
        else:
            angle = wu * upper_deg - wl * lower_deg
        return self.rotate_about(co, centre, self.frame.left, angle)

    def surface_point(self, approx: Vector) -> Vector:
        tree = BVHTree.FromObject(self.body, bpy.context.evaluated_depsgraph_get())
        origin = approx + self.frame.forward * 0.08
        hit, _n, _i, _d = tree.ray_cast(origin, -self.frame.forward, 0.2)
        if hit is None:
            hit, _n, _i, _d = tree.find_nearest(approx)
        return hit

    def landmarks(self) -> dict:
        f = self.frame
        lm = {}
        mouth_z = self.eye_mid + f.up * -self.cfg["mouth_line_z_below_eyes_m"]
        lm["mouth"] = self.surface_point(mouth_z)
        for side in ("L", "R"):
            c, _r = self.eyes[side]
            o = self.out[side]
            lateral = (c - self.eye_mid).dot(o)
            lm[f"brow_{side}"] = self.surface_point(c + f.up * 0.024)
            lm[f"inner_brow_{side}"] = self.surface_point(self.eye_mid + o * lateral * 0.45 + f.up * 0.021)
            k = self.eye_mid + o * lateral * self.cfg["mouth_corner_x_of_eye_x"] + \
                f.up * -self.cfg["mouth_line_z_below_eyes_m"]
            lm[f"mouth_corner_{side}"] = self.surface_point(k)
            lm[f"cheek_{side}"] = self.surface_point(c + f.up * -0.032 + o * 0.006)
        return lm


def gauss(co: np.ndarray, centre: Vector, sigma: float) -> np.ndarray:
    d2 = ((co - np.array(centre)) ** 2).sum(1)
    return np.exp(-d2 / (2 * sigma * sigma))


def build_face_details(face: Face, profile: dict) -> dict:
    """Eyelashes and brow strokes, joined into the face mesh so morphs move them."""
    f = face.frame
    body = face.body
    cfg = profile["face"]
    created = {}
    lash_cfg = cfg.get("lashes")
    bm = bmesh.new()
    if lash_cfg:
        for side in ("L", "R"):
            centre, r = face.eyes[side]
            bins, upper, _lower = face.lid_margins(side)
            sign = 1.0 if side == "L" else -1.0
            rows = []
            for a in np.arange(-38, 39, 4.0):
                el = math.radians(float(np.interp(a, bins, upper)) - 1.0)
                az = math.radians(a)
                direction = (f.forward * math.cos(az) + f.left * (math.sin(az) * sign)) * math.cos(el) \
                    + f.up * math.sin(el)
                base = centre + direction * (r * 1.06)
                taper = 1.0 - abs(a) / 48.0
                tip = base + (direction * 0.55 + f.up * 0.7).normalized() * lash_cfg["length_m"] * taper
                rows.append((base, tip))
            verts = [(bm.verts.new(b), bm.verts.new(t)) for b, t in rows]
            for (b0, t0), (b1, t1) in zip(verts, verts[1:]):
                bm.faces.new((b0, b1, t1, t0))
    created["lash_faces"] = len(bm.faces)
    brow_cfg = cfg.get("brows")
    brow_faces_start = len(bm.faces)
    if brow_cfg:
        tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
        for side in ("L", "R"):
            c, _r = face.eyes[side]
            o = face.out[side]
            lateral = (c - face.eye_mid).dot(o)
            rows = []
            for t in np.linspace(0, 1, 12):
                x = lateral * (0.42 + 1.18 * t)
                z = 0.019 + 0.007 * math.sin(math.pi * min(1.0, t * 1.15)) - 0.004 * t
                approx = face.eye_mid + o * x + f.up * z
                hit, n, _i, _d = tree.ray_cast(approx + f.forward * 0.08, -f.forward, 0.2)
                if hit is None:
                    continue
                half = (0.0040 - 0.0022 * t)
                rows.append((hit + n * 0.0006 + f.up * half, hit + n * 0.0006 - f.up * half, t))
            verts = [(bm.verts.new(a), bm.verts.new(b), t) for a, b, t in rows]
            for (a0, b0, t0), (a1, b1, t1) in zip(verts, verts[1:]):
                bm.faces.new((b0, b1, a1, a0))
    created["brow_faces"] = len(bm.faces) - brow_faces_start
    if not bm.faces:
        bm.free()
        return created
    mesh = bpy.data.meshes.new("FaceDetails")
    bm.to_mesh(mesh)
    bm.free()
    uv = mesh.uv_layers.new(name=body.data.uv_layers[0].name if body.data.uv_layers else "UVMap")
    # Lashes: solid dark. Brows: UVs run along the stroke so the texture draws hairs.
    for poly in mesh.polygons:
        is_brow = poly.index >= created["lash_faces"]
        poly.material_index = 1 if is_brow else 0
        poly.use_smooth = True
        for k, li in enumerate(poly.loop_indices):
            uv.data[li].uv = ((0.0, 0.0), (1.0, 0.0), (1.0, 1.0), (0.0, 1.0))[k] if is_brow else (0.5, 0.5)
    lash_mat = dark_material(cfg.get("lashes", {}).get("material", "Lash"),
                             cfg.get("lashes", {}).get("color_srgb_hex", "#140d0a"))
    brow_mat = brow_material(cfg.get("lashes", {}).get("color_srgb_hex", "#140d0a"))
    obj = bpy.data.objects.new("FaceDetails", mesh)
    bpy.context.scene.collection.objects.link(obj)
    head_bone = profile["bones"]["head"]
    group = obj.vertex_groups.new(name=head_bone)
    group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
    # Joining maps these slots onto the body's by material.
    body.data.materials.append(lash_mat)
    body.data.materials.append(brow_mat)
    mesh.materials.append(lash_mat)
    mesh.materials.append(brow_mat)
    bpy.ops.object.select_all(action="DESELECT")
    obj.select_set(True)
    body.select_set(True)
    bpy.context.view_layer.objects.active = body
    bpy.ops.object.join()
    return created


def srgb_hex_to_linear(value: str) -> tuple[float, float, float, float]:
    value = value.lstrip("#")
    out = []
    for i in (0, 2, 4):
        c = int(value[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, 1.0)


def dark_material(name: str, hex_color: str) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = srgb_hex_to_linear(hex_color)
    bsdf.inputs["Roughness"].default_value = 0.9
    bsdf.inputs["Specular IOR Level"].default_value = 0.1
    return mat


def brow_material(hex_color: str) -> bpy.types.Material:
    """Alpha-masked hair strokes, so the brow reads as hairs over the skin, not a stripe."""
    n = 128
    rng = np.random.default_rng(11)
    img = np.zeros((n, n, 4), dtype=np.float32)
    col = np.array(srgb_hex_to_linear(hex_color)[:3]) ** (1 / 2.2)
    img[..., :3] = col
    yy, xx = np.mgrid[0:n, 0:n] / n
    alpha = np.zeros((n, n))
    for _ in range(320):
        x0 = rng.uniform(0, 1)
        y0 = rng.uniform(0.15, 0.85)
        angle = math.radians(rng.uniform(10, 35))
        length = rng.uniform(0.08, 0.16)
        along = (xx - x0) * math.cos(angle) + (yy - y0) * math.sin(angle)
        across = -(xx - x0) * math.sin(angle) + (yy - y0) * math.cos(angle)
        stroke = (np.abs(across) < 0.016) & (along > 0) & (along < length)
        alpha = np.maximum(alpha, stroke * rng.uniform(0.75, 1.0))
    edge = smoothstep(0.0, 0.18, yy) * smoothstep(0.0, 0.18, 1 - yy)
    img[..., 3] = alpha * edge
    image = bpy.data.images.new("Brow_Strokes", n, n, alpha=True)
    image.pixels.foreach_set(img.ravel())
    image.pack()
    mat = bpy.data.materials.new("Brow")
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    tex = nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    # A Round node is how the glTF exporter marks alpha-clip (alphaMode MASK).
    clip = nodes.new("ShaderNodeMath")
    clip.operation = "ROUND"
    mat.node_tree.links.new(tex.outputs["Alpha"], clip.inputs[0])
    mat.node_tree.links.new(clip.outputs[0], bsdf.inputs["Alpha"])
    # Hair strokes must not catch a specular sheen, or they read grey against the skin.
    bsdf.inputs["Roughness"].default_value = 1.0
    bsdf.inputs["Specular IOR Level"].default_value = 0.0
    return mat


def build_face_shapes(face: Face, library: dict) -> list[str]:
    body = face.body
    f = face.frame
    if body.data.shape_keys is None:
        body.shape_key_add(name="Basis", from_mix=False)
    co = face.coords()
    shapes: dict[str, np.ndarray] = {}
    blink = library["face_shapes"]["blink"]
    close = blink["close_fraction"]
    low = blink["lower_lid_share"]
    for side in ("L", "R"):
        shapes[f"blink_{side}"] = face.lid_delta(co, side, close * (1 - low), close * low, gap_scaled=True)
    shapes["blink"] = shapes["blink_L"] + shapes["blink_R"]

    lm = face.landmarks()
    up, fwd = np.array(f.up), np.array(f.forward)
    mm = 0.001
    front = (co @ fwd) > (np.array(face.eye_mid) @ fwd) - 0.02

    def both(name: str) -> tuple[str, str]:
        return f"{name}_L", f"{name}_R"

    for name, spec in library["face_shapes"]["expressions"].items():
        delta = np.zeros_like(co)
        for side in ("L", "R"):
            out = np.array(face.out[side])
            if spec.get("brow_raise"):
                delta += up * spec["brow_raise"] * mm * gauss(co, lm[f"brow_{side}"], 0.013)[:, None]
            if spec.get("inner_brow_raise"):
                delta += up * spec["inner_brow_raise"] * mm * gauss(co, lm[f"inner_brow_{side}"], 0.008)[:, None]
            if spec.get("brow_knit"):
                g = gauss(co, lm[f"inner_brow_{side}"], 0.009)[:, None]
                delta += (-out * 1.0 - up * 0.35) * spec["brow_knit"] * mm * g
            if spec.get("lid"):
                delta += face.lid_delta(co, side, spec["lid"], 0.0)
            if spec.get("lower_lid"):
                delta += face.lid_delta(co, side, 0.0, spec["lower_lid"])
            if spec.get("mouth_corner_up"):
                g = gauss(co, lm[f"mouth_corner_{side}"], 0.0075)[:, None]
                delta += (up + out * 0.35) * spec["mouth_corner_up"] * mm * g
            if spec.get("mouth_corner_back"):
                g = gauss(co, lm[f"mouth_corner_{side}"], 0.0075)[:, None]
                delta += -fwd * spec["mouth_corner_back"] * mm * g
            if spec.get("cheek_up"):
                delta += up * spec["cheek_up"] * mm * gauss(co, lm[f"cheek_{side}"], 0.012)[:, None]
        if spec.get("mouth_press"):
            delta += -fwd * spec["mouth_press"] * mm * gauss(co, lm["mouth"], 0.011)[:, None]
        delta *= front[:, None]
        shapes[name] = delta

    # Speech: the jaw opens slightly about a pivot in front of the ears.
    cfg = face.cfg
    pivot_off = cfg["jaw_pivot_offset_from_eye_mid_m"]
    pivot = face.eye_mid - f.forward * pivot_off[1] + f.up * pivot_off[2]
    mouth_up = float(np.array(lm["mouth"]) @ up)
    h = co @ up
    lat = np.abs((co - np.array(face.eye_mid)) @ np.array(f.left))
    w = smoothstep(mouth_up + 0.0008, mouth_up - 0.004, h)
    w *= 1.0 - smoothstep(mouth_up - 0.07, mouth_up - 0.10, h)
    w *= 1.0 - smoothstep(0.045, 0.068, lat)
    w *= (co @ fwd) > (np.array(pivot) @ fwd)
    shapes["mouth_open"] = face.rotate_about(co, pivot, f.left,
                                             w * library["face_shapes"]["speech"]["mouth_open_deg"])

    names = []
    for name, delta in shapes.items():
        key = body.shape_key_add(name=name, from_mix=False)
        flat = (co + delta).astype(np.float32).ravel()
        key.data.foreach_set("co", flat)
        names.append(name)
    return names


# --------------------------------------------------------------------------- clips

def clip_value(clip: dict, role: str, rot: str, t: float) -> float:
    value = 0.0
    for s in clip.get("static", []):
        if s["role"] == role and s["rot"] == rot:
            value += s["deg"]
    for wv in clip.get("waves", []):
        if wv["role"] == role and wv["rot"] == rot:
            value += wv["amp"] * math.sin(math.tau * t / wv["period"] + math.radians(wv.get("phase", 0)))
    for k in clip.get("keys", []):
        if k["role"] != role or k["rot"] != rot:
            continue
        pts = k["points"]
        if t <= pts[0][0]:
            value += pts[0][1]
        elif t >= pts[-1][0]:
            value += pts[-1][1]
        else:
            for (t0, v0), (t1, v1) in zip(pts, pts[1:]):
                if t0 <= t <= t1:
                    s = float(smoothstep(t0, t1, t))
                    value += v0 + (v1 - v0) * s
                    break
    return value


def clip_channels(clip: dict) -> list[tuple[str, str]]:
    seen = []
    for group in ("static", "waves", "keys"):
        for item in clip.get(group, []):
            pair = (item["role"], item["rot"])
            if pair not in seen:
                seen.append(pair)
    return seen


def validate_library(library: dict, bones: dict) -> None:
    reserved = set(library.get(GESTURE_ROLES_KEY, []))
    for clip in library["clips"]:
        for role, rot in clip_channels(clip):
            if role not in bones:
                raise RuntimeError(f"Clip {clip['name']} uses role {role!r} with no bone in the profile")
            if clip["player"] == "body" and role in reserved:
                raise RuntimeError(f"Body clip {clip['name']} animates {role}, which is reserved for gestures")


def build_clips(rig: bpy.types.Object, frame: CharacterFrame, library: dict, bones: dict) -> list[dict]:
    fps = int(library["fps"])
    scene = bpy.context.scene
    scene.render.fps = fps
    if rig.animation_data is None:
        rig.animation_data_create()
    inventory = []
    for clip in library["clips"]:
        name = clip["name"]
        if bpy.data.actions.get(name):
            raise RuntimeError(f"Source already has an action named {name}; refusing to replace it")
        frames = int(round(clip["seconds"] * fps))
        act = bpy.data.actions.new(name)
        act.use_fake_user = True
        rig.animation_data.action = act
        channels = clip_channels(clip)
        by_bone: dict[str, list[tuple[str, str]]] = {}
        for role, rot in channels:
            by_bone.setdefault(bones[role], []).append((role, rot))
        for pb in rig.pose.bones:
            pb.rotation_mode = "QUATERNION"
            pb.rotation_quaternion = Quaternion()
        step = 2
        sample_frames = list(range(0, frames + 1, step))
        if sample_frames[-1] != frames:
            sample_frames.append(frames)
        for bone_name, pairs in by_bone.items():
            pb = rig.pose.bones[bone_name]
            rest = (rig.matrix_world.to_3x3() @ pb.bone.matrix_local.to_3x3()).to_quaternion()
            axes = [(role, rot, frame.axis(rot, pb.bone, rig)) for role, rot in pairs]
            for fr in sample_frames:
                t = fr / fps
                world = Quaternion()
                for role, rot, axis in axes:
                    world = Quaternion(axis, math.radians(clip_value(clip, role, rot, t))) @ world
                pb.rotation_quaternion = rest.inverted() @ world @ rest
                pb.keyframe_insert("rotation_quaternion", frame=fr + 1, group=bone_name)
        rig.animation_data.action = None
        track = rig.animation_data.nla_tracks.new()
        track.name = name
        strip = track.strips.new(name, 1, act)
        strip.name = name
        track.mute = True
        inventory.append({"name": name, "player": clip["player"], "loop": bool(clip["loop"]),
                          "seconds": clip["seconds"], "frames": frames,
                          "bones": sorted(by_bone), "description": clip.get("description", "")})
    for pb in rig.pose.bones:
        pb.rotation_quaternion = Quaternion()
    scene.frame_set(1)
    return inventory


# --------------------------------------------------------------------------- export

def inspect_glb(path: Path) -> dict:
    data = path.read_bytes()
    magic, version, length = struct.unpack_from("<4sII", data)
    if magic != b"glTF" or version != 2 or length != len(data):
        raise RuntimeError("Invalid GLB header")
    n, _kind = struct.unpack_from("<II", data, 12)
    doc = json.loads(data[20:20 + n])
    nodes = doc.get("nodes", [])
    anims = []
    for anim in doc.get("animations", []):
        ch = anim.get("channels", [])
        anims.append({"name": anim.get("name", ""), "channels": len(ch),
                      "nodes": sorted({nodes[c["target"]["node"]].get("name", "") for c in ch})})
    morphs = [{"mesh": m.get("name", ""), "targets": m.get("extras", {}).get("targetNames", [])}
              for m in doc.get("meshes", []) if m.get("extras", {}).get("targetNames")]
    return {"skins": len(doc.get("skins", [])), "animations": anims, "morph_targets": morphs}


def export_glb(rig: bpy.types.Object, meshes: list[bpy.types.Object], path: Path) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    path.parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=str(path), export_format="GLB", use_selection=True, export_apply=False,
        export_skins=True, export_texcoords=True, export_normals=True, export_image_format="AUTO",
        export_morph=True, export_morph_normal=True, export_morph_animation=False,
        export_animations=True, export_animation_mode="ACTIONS", export_force_sampling=True,
        export_optimize_animation_size=True, export_optimize_animation_keep_anim_armature=False,
        export_reset_pose_bones=True, export_anim_slide_to_zero=True, export_def_bones=False,
        export_nla_strips=True)
    if "FINISHED" not in result:
        raise RuntimeError(f"glTF export failed: {result}")


# --------------------------------------------------------------------------- render

def contact_sheet(paths: list[Path], out: Path) -> None:
    """Side-by-side sheet using Blender's own image API (no PIL in Blender's Python)."""
    images = [bpy.data.images.load(str(p)) for p in paths]
    w, h = images[0].size
    sheet = np.zeros((h, w * len(images), 4), dtype=np.float32)
    for i, im in enumerate(images):
        px = np.empty(w * h * 4, dtype=np.float32)
        im.pixels.foreach_get(px)
        sheet[:, i * w:(i + 1) * w] = px.reshape(h, w, 4)
    result = bpy.data.images.new(out.stem, w * len(images), h, alpha=False)
    result.pixels.foreach_set(sheet.ravel())
    result.filepath_raw = str(out)
    result.file_format = "PNG"
    result.save()
    for im in images + [result]:
        bpy.data.images.remove(im)


def render_review(rig, body, library: dict, profile: dict, out_dir: Path) -> list[Path]:
    """Cycles frames: full body at rest/inhale and a face sheet of the morph targets."""
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 32
    scene.cycles.use_denoising = True
    cam = scene.camera
    if cam is None:
        raise RuntimeError("Source .blend has no review camera")
    version = profile["version"]
    stem = profile["display_name"].replace(" ", "_")
    paths = []

    def shot(path: Path, loc, target, lens, w, h):
        cam.location = loc
        cam.data.lens = lens
        cam.rotation_euler = (Vector(target) - Vector(loc)).to_track_quat("-Z", "Y").to_euler()
        scene.render.resolution_x, scene.render.resolution_y = w, h
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(path)

    keys = body.data.shape_keys.key_blocks

    def set_shape(name: str | None):
        for kb in keys[1:]:
            kb.value = 1.0 if kb.name == name else 0.0

    out_dir.mkdir(parents=True, exist_ok=True)
    # Face sheet.
    face_names = ["neutral", "blink", "attentive", "warm_subtle", "concerned_restrained",
                  "focused", "mouth_open"]
    for name in face_names:
        set_shape(None if name == "neutral" else name)
        shot(out_dir / f"_face_{name}.png", (-0.22, -0.78, 1.57), (0, -0.05, 1.53), 95, 420, 480)
    set_shape(None)
    # Breathing: exhale vs inhale (frame of max chest extension) on idle_breathing.
    act = bpy.data.actions["idle_breathing"]
    rig.animation_data.action = act
    for label, fr in (("exhale", 61), ("inhale", 1 + 30)):
        scene.frame_set(fr)
        shot(out_dir / f"_body_{label}.png", (-1.6, -2.6, 1.25), (0, 0, 1.05), 60, 600, 800)
    act = bpy.data.actions["listen_neutral"]
    rig.animation_data.action = act
    scene.frame_set(46)
    shot(out_dir / "_body_listen.png", (-1.6, -2.6, 1.25), (0, 0, 1.05), 60, 600, 800)
    rig.animation_data.action = bpy.data.actions["restrained_chart_indication"]
    scene.frame_set(31)
    shot(out_dir / "_body_chart_gesture.png", (-1.6, -2.6, 1.25), (0, 0, 1.05), 60, 600, 800)
    rig.animation_data.action = None
    scene.frame_set(1)

    face_sheet = out_dir / f"{stem}_{version}_face_controls.png"
    contact_sheet([out_dir / f"_face_{n}.png" for n in face_names], face_sheet)
    body_sheet = out_dir / f"{stem}_{version}_body_clips.png"
    contact_sheet([out_dir / f"_body_{n}.png" for n in ("exhale", "inhale", "listen", "chart_gesture")],
                  body_sheet)
    for p in paths:
        p.unlink()
    return [face_sheet, body_sheet]


# --------------------------------------------------------------------------- main

def main() -> None:
    args = parse_args()
    profile_path = (ROOT / args.profile).resolve()
    profile = json.loads(profile_path.read_text(encoding="utf-8"))
    library = json.loads(LIBRARY_PATH.read_text(encoding="utf-8"))
    source = ROOT / profile["source_blend"]
    outputs = {k: ROOT / v for k, v in profile["outputs"].items()}
    if outputs["blend"].resolve() == source.resolve():
        raise RuntimeError("Output .blend must differ from the source; the source is never modified.")
    source_digest = sha256(source)
    weight_spec = profile.get("clothing_weight_reference")
    reference = capture_weight_reference(weight_spec) if weight_spec else None
    bpy.ops.wm.open_mainfile(filepath=str(source))
    objs = profile["objects"]
    rig = bpy.data.objects[objs["rig"]]
    body = bpy.data.objects[objs["face_mesh"]]
    skinned = [o for o in bpy.data.objects if o.type == "MESH" and o.parent == rig]
    meshes = [body] + [o for o in skinned if o is not body]
    bones = profile["bones"]
    frame = CharacterFrame(profile)

    reskinned = {}
    if reference is not None:
        reskinned = transfer_weights(reference, [bpy.data.objects[n] for n in weight_spec["meshes"]],
                                     weight_spec.get("exclude_bone_prefixes", []))
    report = rig_report(rig, meshes, bones)
    report["reskinned_dominant_bones"] = reskinned
    validate_library(library, bones)
    face = Face(profile, frame, body)
    details = build_face_details(face, profile)
    shape_names = build_face_shapes(face, library)
    clips = build_clips(rig, frame, library, bones)

    export_glb(rig, meshes, outputs["glb"])
    glb = inspect_glb(outputs["glb"])
    exported = {a["name"]: a for a in glb["animations"]}
    missing = [c["name"] for c in clips if exported.get(c["name"], {}).get("channels", 0) == 0]
    if missing:
        raise RuntimeError(f"GLB is missing animation channels for: {missing}")
    morphs = {n for m in glb["morph_targets"] for n in m["targets"]}
    if not set(shape_names) <= morphs:
        raise RuntimeError(f"GLB is missing morph targets: {sorted(set(shape_names) - morphs)}")
    for c in clips:
        c["glb_channels"] = exported[c["name"]]["channels"]
        c["glb_nodes"] = exported[c["name"]]["nodes"]

    renders = [] if args.no_render else render_review(rig, body, library, profile, outputs["renders"])
    for image in bpy.data.images:
        if not image.packed_file and image.has_data and image.source == "GENERATED":
            image.pack()
    outputs["blend"].parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(outputs["blend"]), compress=True, copy=True)

    tris = 0
    for o in meshes:
        tris += sum(len(p.vertices) - 2 for p in o.data.polygons)
    report.update({
        "blender_version": bpy.app.version_string,
        "profile": str(profile_path.relative_to(ROOT)),
        "face_details": details,
        "morph_targets": shape_names,
        "clips": clips,
        "glb": glb,
        "triangles": tris,
    })
    outputs["report"].parent.mkdir(parents=True, exist_ok=True)
    outputs["report"].write_text(json.dumps(report, indent=2) + "\n", encoding="utf-8")
    manifest = {
        "asset_id": f"CHR_{profile['display_name'].replace(' ', '')}_{profile['version']}",
        "character_id": profile["character_id"],
        "version": profile["version"],
        "production_status": profile["production_status"],
        "approved": False,
        "builder": "tools/character_animation/build_animated_character.py",
        "profile": str(profile_path.relative_to(ROOT)),
        "clip_library": str(LIBRARY_PATH.relative_to(ROOT)),
        "blender_version": bpy.app.version_string,
        "inputs": [{"path": profile["source_blend"], "sha256": source_digest,
                    "used": "rigged character, unchanged rest pose"}],
        "external_assets": [],
        "generated": ["animation actions (clip_library.json)", "face morph targets",
                      "eyelash and brow-stroke geometry, brow stroke texture"],
        "triangle_count": tris,
        "clips": [{k: c[k] for k in ("name", "player", "loop", "seconds", "glb_channels")} for c in clips],
        "morph_targets": shape_names,
        "outputs": {"blend": profile["outputs"]["blend"], "glb": profile["outputs"]["glb"],
                    "report": profile["outputs"]["report"],
                    "renders": [str(p.relative_to(ROOT)) for p in renders]},
        "known_limitations": [
            "Procedural keyframed clips, not motion capture; reviewed only in the Linux container.",
            "Face morphs are authored from measured landmarks, not sculpted; no lip sync.",
            "Clothing follows the body skin weights; no cloth simulation or corrective shapes.",
            "Not measured on the target Mac.",
        ],
    }
    outputs["manifest"].write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"ANIMATED {profile['character_id']} {profile['version']} OK: {len(clips)} clips, "
          f"{len(shape_names)} morph targets, {tris} triangles, {len(renders)} review sheets")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.stdout.flush()
