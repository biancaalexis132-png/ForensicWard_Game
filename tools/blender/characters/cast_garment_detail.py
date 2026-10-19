"""Garment detail for the cast (v02): fit, trims and baked fold detail.

v01 garments were plain offset shells. v02 keeps the same shells (and their
colours) and adds, from each garment's ``detail`` block in the cast config:

* **folds**: a procedural fold height field (elbow and wrist compression, armpit
  pull, soft drape below the bust, blousing above a tucked hem, crotch
  "whiskers", knee and ankle breaks, a pressed crease, a gathered waist, seams
  and fine wrinkles), baked into a unique-UV colour map (crests a little
  lighter, troughs darker) and a tangent-space normal map. The normal is derived
  from texel positions and their UV derivatives, so it matches the
  MikkTSpace tangents Blender and Godot use without a high-poly bake.
* **trims**: bands built on the shell's own open edges (shirt cuffs, rib cuffs and
  hems, crew-neck binding, trouser waistband, cardigan front band, blazer
  lapels and collar), front patches (shirt placket, chest pockets with flaps,
  blazer hip-pocket flaps) and buttons. Trims are joined into their garment as
  extra material slots, so the object names and the rest of the pipeline are
  unchanged.

Everything is procedural; nothing is downloaded. Positions are in the builder's
nominal (1.665 m) frame, before the character is scaled to its own height.
"""
from __future__ import annotations

import math

import bpy  # noqa: I001
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree


def _smooth(x):
    x = np.clip(x, 0.0, 1.0)
    return x * x * (3 - 2 * x)


# ------------------------------------------------------------------ shells and loops

def garment_shell(v3, name: str, body, face_mask: np.ndarray, offset_fn, smooth_iterations: int,
                  thickness: float, material, before_thicken=None, decimate_ratio: float | None = None):
    """build_naomi_v03.shell_from_faces, also returning the shell's open edges (ordered loops).

    The loops are taken after the shell is pushed out and before it is thickened,
    so trims built on them sit exactly on the garment's hems, cuffs and necklines.
    """
    mesh = body.data.copy()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = body.matrix_world
    obj.modifiers.clear()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not face_mask[f.index]], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    boundary = {v.index for v in bm.verts if v.is_boundary}
    for _ in range(smooth_iterations):
        bmesh.ops.smooth_vert(bm, verts=[v for v in bm.verts if v.index not in boundary],
                              factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    for _ in range(25):
        moves = {}
        for v in bm.verts:
            if not v.is_boundary:
                continue
            nbrs = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
            if len(nbrs) == 2:
                moves[v] = (nbrs[0].co + nbrs[1].co) / 2
        for v, target in moves.items():
            v.co = v.co.lerp(target, 0.6)
    bm.normal_update()
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())

    def push_out():
        for v in bm.verts:
            offset = offset_fn(v.co)
            location, normal, _i, _d = tree.find_nearest(v.co)
            if location is None:
                continue
            outward = (v.co - location)
            if outward.dot(normal) < offset or outward.length > offset + 0.05:
                v.co = location + normal * offset

    push_out()
    for _ in range(6 if smooth_iterations > 1 else 0):
        for _ in range(4):
            bmesh.ops.smooth_vert(bm, verts=[v for v in bm.verts if v.index not in boundary],
                                  factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
        for _ in range(3):
            for v in bm.verts:
                if v.is_boundary:
                    nbrs = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
                    if len(nbrs) == 2:
                        v.co = v.co.lerp((nbrs[0].co + nbrs[1].co) / 2, 0.5)
        push_out()
    bm.normal_update()
    loops = ordered_loops(bm)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.clear()
    mesh.materials.append(material)
    for poly in mesh.polygons:
        poly.use_smooth = True
    if before_thicken is not None:
        before_thicken(obj)
    if decimate_ratio is not None and decimate_ratio < 1.0:
        # Decimate the single surface, then thicken: decimating a thin closed shell lets
        # the inner wall cross the outer one.
        v3.decimate(obj, decimate_ratio)
        obj["cast_detail"] = True
    v3.select_only(obj)
    if thickness:
        sol = obj.modifiers.new("Thickness", "SOLIDIFY")
        sol.thickness = thickness
        sol.offset = 1.0
        bpy.ops.object.modifier_apply(modifier=sol.name)
    return obj, loops


def ordered_loops(bm) -> list[dict]:
    """Open edges of a surface as ordered loops of points and outward normals."""
    edges = [e for e in bm.edges if e.is_boundary]
    nbr: dict = {}
    for e in edges:
        a, b = e.verts
        nbr.setdefault(a, []).append(b)
        nbr.setdefault(b, []).append(a)
    seen = set()
    loops = []
    for start in list(nbr):
        if start in seen or len(nbr[start]) != 2:
            continue
        order = [start]
        seen.add(start)
        prev, cur = None, start
        while True:
            nxt = [v for v in nbr[cur] if v is not prev]
            if not nxt:
                break
            n = nxt[0]
            if n is start or n in seen:
                break
            order.append(n)
            seen.add(n)
            prev, cur = cur, n
        if len(order) < 6:
            continue
        pts = np.array([v.co[:] for v in order])
        nrm = np.array([v.normal[:] for v in order])
        loops.append({"pts": pts, "nrm": nrm, "centre": pts.mean(axis=0)})
    return loops


# ------------------------------------------------------------------ trim geometry

def _tangents(pts: np.ndarray, closed: bool) -> np.ndarray:
    if closed:
        t = np.roll(pts, -1, axis=0) - np.roll(pts, 1, axis=0)
    else:
        t = np.gradient(pts, axis=0)
    return t / np.maximum(np.linalg.norm(t, axis=1, keepdims=True), 1e-9)


def resample_loop(pts: np.ndarray, nrm: np.ndarray, spacing: float, closed: bool = True):
    p = np.vstack([pts, pts[:1]]) if closed else pts
    n = np.vstack([nrm, nrm[:1]]) if closed else nrm
    seg = np.linalg.norm(np.diff(p, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seg)])
    count = max(8, int(round(s[-1] / spacing)))
    t = np.linspace(0, s[-1], count, endpoint=not closed)
    out = np.stack([np.interp(t, s, p[:, k]) for k in range(3)], axis=1)
    on = np.stack([np.interp(t, s, n[:, k]) for k in range(3)], axis=1)
    on /= np.maximum(np.linalg.norm(on, axis=1, keepdims=True), 1e-9)
    # Smooth the normals a little: they come from a coarse shell.
    for _ in range(3):
        on = (np.roll(on, 1, 0) + 2 * on + np.roll(on, -1, 0)) / 4 if closed else on
        on /= np.maximum(np.linalg.norm(on, axis=1, keepdims=True), 1e-9)
    return out, on, s[-1]


def band(name: str, pts: np.ndarray, nrm: np.ndarray, widths, garment_tree: BVHTree, lift: float,
         closed: bool, mat_index: int, uv_scale: float = 6.0, roll: float = 0.0012, overhang: float = 0.003,
         rows: int = 3, flip: bool = False) -> bpy.types.Object:
    """A strip lying on the garment along one of its open edges, reaching `widths` into it.

    The strip starts `overhang` beyond the edge (so it covers the shell's cut) and
    rolls slightly at the edge like a turned hem.
    """
    widths = np.broadcast_to(np.asarray(widths, dtype=float), (len(pts),))
    tang = _tangents(pts, closed)
    into = np.cross(nrm, tang)
    # Point the strip into the garment: a step that way stays on the cloth.
    votes = 0
    for i in range(0, len(pts), max(1, len(pts) // 16)):
        p = Vector(pts[i].tolist())
        d = Vector(into[i].tolist())
        _a, _n, _i, da = garment_tree.find_nearest(p + d * 0.015)
        _b, _m, _j, db = garment_tree.find_nearest(p - d * 0.015)
        votes += 1 if (da or 1) < (db or 1) else -1
    if (votes < 0) != flip:
        into = -into
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    grid = []
    offsets = np.linspace(0.0, 1.0, rows + 1)
    for i, p in enumerate(pts):
        col = []
        w = widths[i]
        for k, o in enumerate(offsets):
            s = -overhang + (w + overhang) * o
            bulge = roll * math.sin(math.pi * min(1.0, max(0.0, (s + overhang) / max(1e-6, w * 0.6))))
            fade = 1.0 if w > 0.004 else w / 0.004
            q = p + into[i] * s + nrm[i] * (lift + bulge) * fade
            col.append(bm.verts.new(q.tolist()))
        grid.append(col)
    arc = np.concatenate([[0], np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))])
    n = len(pts)
    last = n if closed else n - 1
    for i in range(last):
        j = (i + 1) % n
        for k in range(rows):
            f = bm.faces.new((grid[i][k], grid[j][k], grid[j][k + 1], grid[i][k + 1]))
            f.material_index = mat_index
            ua = arc[i] * uv_scale
            ub = (arc[i] + np.linalg.norm(pts[j] - pts[i])) * uv_scale
            va = (widths[i] * offsets[k]) * uv_scale
            vb = (widths[i] * offsets[k + 1]) * uv_scale
            for lp, uv in zip(f.loops, ((ua, va), (ub, va), (ub, vb), (ua, vb))):
                lp[uv_layer].uv = uv
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    # Outward faces: compare with the garment normal at the middle of the strip.
    mid = Vector(pts[len(pts) // 2].tolist())
    if mesh.polygons:
        f = min(mesh.polygons, key=lambda q: (q.center - mid).length)
        if f.normal.dot(Vector(nrm[len(pts) // 2].tolist())) < 0:
            for poly in mesh.polygons:
                poly.flip()
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


def front_patch(name: str, garment_tree: BVHTree, x0: float, x1: float, z0: float, z1: float, lift: float,
                mat_index: int, nx: int = 4, nz: int = 4, uv_scale: float = 6.0, taper=None) -> bpy.types.Object | None:
    """A grid laid on the garment's front by casting rays toward +Y (pockets, flaps, placket).

    `taper(u, v) -> lift scale` shapes it (flaps thicker at the bottom edge).
    """
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    grid = []
    for j in range(nz + 1):
        row = []
        for i in range(nx + 1):
            x = x0 + (x1 - x0) * i / nx
            z = z0 + (z1 - z0) * j / nz
            hit, n, _f, _d = garment_tree.ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
            if hit is None:
                bm.free()
                return None
            k = taper(i / nx, j / nz) if taper else 1.0
            row.append(bm.verts.new((hit + n * lift * k)[:]))
        grid.append(row)
    for j in range(nz):
        for i in range(nx):
            f = bm.faces.new((grid[j][i], grid[j][i + 1], grid[j + 1][i + 1], grid[j + 1][i]))
            f.material_index = mat_index
            for lp in f.loops:
                c = lp.vert.co
                lp[uv_layer].uv = (c.x * uv_scale, c.z * uv_scale)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        if poly.normal.y > 0:
            poly.flip()
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def button(name: str, garment_tree: BVHTree, x: float, z: float, radius: float, lift: float,
           mat_index: int, segments: int = 10) -> bpy.types.Object | None:
    hit, n, _f, _d = garment_tree.ray_cast(Vector((x, -0.6, z)), Vector((0, 1, 0)))
    if hit is None:
        return None
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, segments=segments, radius1=radius, radius2=radius * 0.88,
                          depth=0.0028)
    for v in bm.verts:
        # Slightly domed face.
        if v.co.z > 0:
            v.co.z += 0.0006 * (1 - (v.co.x ** 2 + v.co.y ** 2) / radius ** 2)
    rot = Vector((0, 0, 1)).rotation_difference(n).to_matrix().to_4x4()
    bmesh.ops.transform(bm, matrix=rot, verts=bm.verts)
    bmesh.ops.translate(bm, vec=hit + n * (lift + 0.0014), verts=bm.verts)
    for f in bm.faces:
        f.material_index = mat_index
        f.smooth = False
    mesh = bpy.data.meshes.new(name)
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        for lp in f.loops:
            lp[uv].uv = (0.5, 0.5)
    bm.to_mesh(mesh)
    bm.free()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def thicken(v3, obj, thickness: float) -> None:
    v3.select_only(obj)
    sol = obj.modifiers.new("Thickness", "SOLIDIFY")
    sol.thickness = thickness
    sol.offset = -1.0
    bpy.ops.object.modifier_apply(modifier=sol.name)


# ------------------------------------------------------------------ fold field

class Skeleton:
    def __init__(self, rig):
        self.b = {b.name: (np.array(b.head_local[:]), np.array(b.tail_local[:])) for b in rig.data.bones}

    def seg(self, P: np.ndarray, name: str):
        a, b = self.b[name]
        u = b - a
        L = np.linalg.norm(u)
        u = u / L
        s = (P - a) @ u
        foot = a + np.outer(s, u)
        r = P - foot
        d = np.linalg.norm(r, axis=1)
        fwd = np.array([0.0, -1.0, 0.0])
        f = fwd - u * (fwd @ u)
        f /= np.linalg.norm(f)
        g = np.cross(u, f)
        theta = np.arctan2(r @ g, r @ f)  # 0 = facing forward
        return s, d, theta, L


def fold_height(P: np.ndarray, w: dict, kind: str, spec: dict, sk: Skeleton, noise, seated: bool,
                hem_z: float | None = None) -> np.ndarray:
    """Fold height (m, + outward) at points P for one garment.

    w: the body's skin weights at P (bone name -> array), interpolated, so every
    region blends smoothly; gating by a nearest bone left steps that the normal map
    showed as facets.
    """
    zero = np.zeros(len(P))

    def wt(*names):
        return sum((w.get(n, zero) for n in names), zero.copy())
    h = np.zeros(len(P))
    n1 = noise(P, 0.05, 11)
    n2 = noise(P, 0.018, 12)
    amp = float(spec.get("fold_scale", 1.0))
    torso = np.clip(wt("pelvis", "spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r", "neck_01"), 0, 1)
    if kind == "top":
        for side in ("l", "r"):
            # Elbow: compression rings, strongest in the crook, twisting round the arm.
            arm = np.clip(wt(f"upperarm_{side}", f"lowerarm_{side}", f"hand_{side}") * 1.3, 0, 1)
            s, d, th, _L = sk.seg(P, f"lowerarm_{side}")
            env = np.exp(-((s + 0.005) / 0.075) ** 2) * arm * (d < 0.09)
            inner = 0.5 + 0.5 * np.cos(th)
            h += 0.0026 * amp * env * (0.35 + 0.65 * inner) * np.sin(2 * np.pi * s / 0.032 + 2.0 * th + 1.6 * n1)
            if spec.get("sleeves") == "long":
                # Wrist: the sleeve gathers above the cuff.
                above = _L - s
                env = _smooth((above - 0.02) / 0.03) * _smooth((0.14 - above) / 0.05) * arm * (d < 0.09)
                h += 0.0019 * amp * env * np.sin(2 * np.pi * above / 0.03 + 1.7 * th + 1.4 * n2)
            # Upper arm below the shoulder: a few long diagonal pulls.
            s, d, th, _L = sk.seg(P, f"upperarm_{side}")
            env = _smooth((s - 0.04) / 0.05) * _smooth((0.2 - s) / 0.06) * arm * (d < 0.1)
            h += 0.0012 * amp * env * np.sin(3 * th + 2 * np.pi * s / 0.09 + n1)
            # Armpit: folds radiating from under the arm across the chest and back.
            ua, ub = sk.b[f"upperarm_{side}"]
            pit = ua + np.array([-0.025 * np.sign(ua[0]), 0.0, -0.075])
            v = P - pit
            dist = np.linalg.norm(v, axis=1)
            ang = np.arctan2(v[:, 2], np.abs(v[:, 0]) + 0.3 * np.abs(v[:, 1]))
            env = _smooth((dist - 0.02) / 0.03) * _smooth((0.17 - dist) / 0.06) * torso
            h += 0.0016 * amp * env * np.sin(9 * ang + 2.0 * n1)
        # Torso drape: soft vertical folds below the bust, deeper toward the hem.
        bust = sk.b["spine_03"][0][2]
        theta = np.arctan2(P[:, 0], -(P[:, 1] - sk.b["spine_02"][0][1]))
        lo = hem_z if hem_z is not None else bust - 0.4
        env = _smooth((bust - P[:, 2]) / 0.2) * torso
        drape = float(spec.get("drape_folds_m", 0.0014))
        h += drape * amp * env * (0.5 + 0.5 * _smooth((bust - 0.1 - P[:, 2]) / max(0.05, bust - 0.1 - lo))) * \
            np.sin(theta * float(spec.get("drape_count", 11)) + 1.8 * n1)
        if spec.get("tucked") and hem_z is not None:
            # Blousing just above the tuck: loose horizontal folds.
            above = P[:, 2] - hem_z
            env = _smooth(above / 0.02) * _smooth((0.11 - above) / 0.05) * torso
            h += 0.0028 * amp * env * np.sin(2 * np.pi * above / 0.026 + 2.5 * np.sin(theta * 2) + 1.5 * n1)
    elif kind == "trousers":
        for side in ("l", "r"):
            s, d, th, L = sk.seg(P, f"thigh_{side}")
            onleg = np.clip(wt(f"thigh_{side}", f"calf_{side}", f"foot_{side}") * 1.2, 0, 1)
            # Crotch whiskers: diagonals from the inner top of the thigh across the front.
            ha, _hb = sk.b[f"thigh_{side}"]
            crotch = np.array([0.0, ha[1] - 0.01, ha[2] - 0.075])
            v = P - crotch
            ang = np.arctan2(v[:, 2], np.abs(v[:, 0]))
            dist = np.linalg.norm(v, axis=1)
            front = _smooth((np.cos(th) - 0.1) / 0.5)
            env = _smooth((dist - 0.03) / 0.03) * _smooth((0.2 - dist) / 0.06) * front * onleg
            k = 1.6 if seated else 1.0
            h += 0.0016 * amp * k * env * np.sin(8 * ang + 1.8 * n1)
            # Knee: compression rings, mostly behind; deep when seated.
            s, d, th, L = sk.seg(P, f"calf_{side}")
            env = np.exp(-(s / (0.07 if not seated else 0.09)) ** 2) * onleg
            back = 0.5 - 0.5 * np.cos(th)
            h += 0.0013 * amp * (2.6 if seated else 1.0) * env * (0.3 + 0.7 * back) * (0.55 + 0.45 * n2) * \
                np.sin(2 * np.pi * s / 0.034 + 1.5 * th + 2.5 * n1)
            # Ankle break: the leg stacks above the shoe.
            above = L - s
            env = _smooth((above - 0.005) / 0.02) * _smooth((0.16 - above) / 0.06) * onleg
            h += 0.0028 * amp * env * (0.6 + 0.4 * np.cos(th)) * np.sin(2 * np.pi * above / 0.038 + 2.2 * th + 1.5 * n2)
            if spec.get("crease"):
                # Pressed front crease from mid-thigh to the hem.
                s2, d2, th2, L2 = sk.seg(P, f"calf_{side}")
                st, dt, tht, Lt = sk.seg(P, f"thigh_{side}")
                wc = w.get(f"calf_{side}", zero) / np.maximum(wt(f"calf_{side}", f"thigh_{side}"), 1e-6)
                lat = wc * th2 * d2 + (1 - wc) * tht * dt
                env = wc + (1 - wc) * _smooth((st - Lt * 0.35) / 0.08)
                h += 0.0011 * env * onleg * np.exp(-(lat / 0.0035) ** 2)
            # Outer seam: a shallow groove down the side of the leg.
            for bone in (f"thigh_{side}", f"calf_{side}"):
                sb, db, thb, _Lb = sk.seg(P, bone)
                outward = np.sign(sk.b[bone][0][0]) or 1.0
                lat = (np.abs(thb) - np.pi / 2) * db
                sel = onleg * w.get(bone, zero) * (np.sign(np.sin(thb)) != outward)
                h -= 0.0006 * sel * np.exp(-(lat / 0.002) ** 2)
        if spec.get("gathered_waist"):
            waist = float(spec.get("waist_z_m", 1.0))
            below = waist - P[:, 2]
            theta = np.arctan2(P[:, 0], -(P[:, 1] - sk.b["pelvis"][0][1]))
            env = _smooth(below / 0.01) * _smooth((0.07 - below) / 0.04)
            h += 0.0013 * env * np.sin(theta * 34 + 1.2 * n2)
    # Fine wrinkles everywhere.
    h += 0.00035 * noise(P, 0.03, 13) + 0.0002 * noise(P, 0.009, 14)
    return h


def bake_corner_vectors(v3, obj, size: int, values: np.ndarray, material_index: int = 0) -> np.ndarray:
    """Bake a per-corner (loop) vector into UV space: (size, size, 3), linearly interpolated."""
    tmp = obj.copy()
    tmp.data = obj.data.copy()
    tmp.modifiers.clear()
    bpy.context.scene.collection.objects.link(tmp)
    attr = tmp.data.color_attributes.new("_Vec", "FLOAT_COLOR", "CORNER")
    rgba = np.ones((len(values), 4), dtype=np.float32)
    rgba[:, :3] = values * 0.5 + 0.5
    attr.data.foreach_set("color", rgba.ravel())
    bm = bmesh.new()
    bm.from_mesh(tmp.data)
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if f.material_index != material_index], context="FACES")
    bm.to_mesh(tmp.data)
    bm.free()
    image = bpy.data.images.new("_VecBake", size, size, alpha=True, float_buffer=True)
    image.generated_color = (0.5, 0.5, 0.5, 0)
    mat = bpy.data.materials.new("_VecBake")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    col = nt.nodes.new("ShaderNodeVertexColor")
    col.layer_name = "_Vec"
    nt.links.new(col.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    img = nt.nodes.new("ShaderNodeTexImage")
    img.image = image
    nt.nodes.active = img
    tmp.data.materials.clear()
    tmp.data.materials.append(mat)
    scene = bpy.context.scene
    engine = scene.render.engine
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    v3.select_only(tmp)
    bpy.ops.object.bake(type="EMIT", margin=0, use_clear=False)
    px = np.empty(size * size * 4, dtype=np.float32)
    image.pixels.foreach_get(px)
    scene.render.engine = engine
    bpy.data.objects.remove(tmp, do_unlink=True)
    bpy.data.materials.remove(mat)
    bpy.data.images.remove(image)
    return px.reshape(size, size, 4)[..., :3].astype(np.float64) * 2.0 - 1.0


def mikk_frames(v3, obj, size: int) -> tuple[np.ndarray, np.ndarray]:
    """Per-texel MikkTSpace tangent and bitangent, as Blender and Godot interpolate them."""
    mesh = obj.data
    mesh.calc_tangents()
    n = len(mesh.loops)
    t = np.empty(n * 3)
    nn = np.empty(n * 3)
    sign = np.empty(n)
    mesh.loops.foreach_get("tangent", t)
    mesh.loops.foreach_get("normal", nn)
    mesh.loops.foreach_get("bitangent_sign", sign)
    t = t.reshape(-1, 3)
    nn = nn.reshape(-1, 3)
    b = sign[:, None] * np.cross(nn, t)
    mesh.free_tangents()
    return bake_corner_vectors(v3, obj, size, t), bake_corner_vectors(v3, obj, size, b)


def bake_fold_maps(anim, obj, h_fn, base_srgb: np.ndarray, size: int, name: str, shade: float = 22.0, v3=None):
    """Colour and tangent-space normal maps of the fold field on obj's (unique) UVs, material 0."""
    pos, valid = anim.bake_positions(obj, size, 0)
    H = np.zeros((size, size))
    idx = np.flatnonzero(valid.ravel())
    H.ravel()[idx] = h_fn(pos.reshape(-1, 3)[idx])

    def d(a, axis):
        f = np.roll(a, -1, axis)
        b = np.roll(a, 1, axis)
        return (f - b) * 0.5

    vf = np.roll(valid, -1, 1) & np.roll(valid, 1, 1) & valid
    vv = np.roll(valid, -1, 0) & np.roll(valid, 1, 0) & valid
    T = np.where(vf[..., None], d(pos, 1), 0.0)   # dP/du (per texel)
    B = np.where(vv[..., None], d(pos, 0), 0.0)   # dP/dv
    hu = np.where(vf, d(H, 1), 0.0)
    hv = np.where(vv, d(H, 0), 0.0)
    tt = (T * T).sum(-1)
    tb = (T * B).sum(-1)
    bb = (B * B).sum(-1)
    det = tt * bb - tb * tb
    ok = det > 1e-16
    a = np.where(ok, (bb * hu - tb * hv) / np.where(ok, det, 1), 0.0)
    b = np.where(ok, (tt * hv - tb * hu) / np.where(ok, det, 1), 0.0)
    g = a[..., None] * T + b[..., None] * B          # surface gradient of h
    if v3 is not None:
        # Express the gradient in the interpolated MikkTSpace frame the renderer uses;
        # a per-triangle frame shows every triangle edge where folds are strong.
        Th, Bh = mikk_frames(v3, obj, size)
        Th /= np.maximum(np.linalg.norm(Th, axis=-1, keepdims=True), 1e-9)
        Bh /= np.maximum(np.linalg.norm(Bh, axis=-1, keepdims=True), 1e-9)
    else:
        tl = np.sqrt(np.maximum(tt, 1e-20))[..., None]
        Th = T / tl
        N = np.cross(T, B)
        N /= np.maximum(np.linalg.norm(N, axis=-1, keepdims=True), 1e-12)
        Bh = np.cross(N, Th)
    nx = -(g * Th).sum(-1)
    ny = -(g * Bh).sum(-1)
    nz = np.ones_like(nx)
    nrm = np.stack([nx, ny, nz], -1)
    nrm /= np.linalg.norm(nrm, axis=-1, keepdims=True)
    nrm = np.where(ok[..., None], nrm, np.array([0.0, 0.0, 1.0]))
    lin = np.clip(1.0 + shade * H, 0.82, 1.12)
    col = np.clip(base_srgb[None, None, :] * lin[..., None], 0, 1)
    # Grow the islands into the margins so mipmaps and filtering do not bleed in black.
    filled = valid.copy()
    col = np.where(valid[..., None], col, 0.0)
    nmap = np.where(valid[..., None], nrm, 0.0)
    for _ in range(10):
        acc_c = np.zeros_like(col)
        acc_n = np.zeros_like(nmap)
        cnt = np.zeros(filled.shape)
        for ax, sh in ((0, 1), (0, -1), (1, 1), (1, -1)):
            f = np.roll(filled, sh, ax)
            acc_c += np.where(f[..., None], np.roll(col, sh, ax), 0)
            acc_n += np.where(f[..., None], np.roll(nmap, sh, ax), 0)
            cnt += f
        grow = ~filled & (cnt > 0)
        col[grow] = acc_c[grow] / cnt[grow][:, None]
        nmap[grow] = acc_n[grow] / cnt[grow][:, None]
        filled |= grow
    col[~filled] = base_srgb
    nmap[~filled] = (0, 0, 1)
    corner = int(size * 0.985)
    col[corner:, corner:] = base_srgb
    nmap[corner:, corner:] = (0, 0, 1)
    nmap /= np.maximum(np.linalg.norm(nmap, axis=-1, keepdims=True), 1e-9)
    c_img = np.ones((size, size, 4))
    c_img[..., :3] = col
    n_img = np.ones((size, size, 4))
    n_img[..., :3] = nmap * 0.5 + 0.5
    ci = bpy.data.images.new(name + "_BaseColor", size, size, alpha=False)
    ci.pixels.foreach_set(c_img.astype(np.float32).ravel())
    ci.pack()
    ni = bpy.data.images.new(name + "_Normal", size, size, alpha=False)
    ni.colorspace_settings.name = "Non-Color"
    ni.pixels.foreach_set(n_img.astype(np.float32).ravel())
    ni.pack()
    return ci, ni, {"texels": int(valid.sum()), "height_mm_p99": round(float(np.percentile(np.abs(H[valid]), 99)) * 1000, 2)}


def fabric_material(name: str, colour_img, normal_img, roughness: float, specular: float,
                    strength: float = 1.0) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nt = mat.node_tree
    bsdf = nt.nodes["Principled BSDF"]
    tex = nt.nodes.new("ShaderNodeTexImage")
    tex.image = colour_img
    nt.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    ntex = nt.nodes.new("ShaderNodeTexImage")
    ntex.image = normal_img
    nmap = nt.nodes.new("ShaderNodeNormalMap")
    nmap.inputs["Strength"].default_value = strength
    nt.links.new(ntex.outputs["Color"], nmap.inputs["Color"])
    nt.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = specular
    return mat


FLAT_UV = (0.995, 0.995)  # a texel kept at the plain cloth colour and a flat normal


def smart_uvs(v3, obj, body, margin: float = 0.006) -> int:
    """Unique UVs for the outside of a thickened shell; the inside wall maps to one flat texel.

    The inner wall faces the body and is only seen at hems, but on tight concave
    spots (behind the knee) it pokes through the outer wall. Given the fold maps,
    those triangles showed folds lit the wrong way; flat, they match the cloth.
    It also doubles the texel density of the outside.
    """
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    mesh = obj.data
    inner = []
    for f in mesh.polygons:
        loc, _n, _i, _d = tree.find_nearest(f.center)
        inner.append(loc is not None and f.normal.dot(f.center - loc) < 0)
    v3.select_only(obj)
    bpy.ops.object.mode_set(mode="EDIT")
    bm = bmesh.from_edit_mesh(mesh)
    bm.faces.ensure_lookup_table()
    for f in bm.faces:
        f.select = not inner[f.index]
    bmesh.update_edit_mesh(mesh)
    bpy.ops.uv.smart_project(angle_limit=math.radians(60), island_margin=margin, area_weight=0.0,
                             correct_aspect=True, scale_to_bounds=False)
    bm = bmesh.from_edit_mesh(mesh)
    uv = bm.loops.layers.uv.active
    for f in bm.faces:
        for lp in f.loops:
            lp[uv].uv = FLAT_UV if inner[f.index] else (lp[uv].uv[0] * 0.98, lp[uv].uv[1] * 0.98)
    bmesh.update_edit_mesh(mesh)
    bpy.ops.object.mode_set(mode="OBJECT")
    return int(sum(inner))


class SkinWeights:
    """The body's bone weights at any point: inverse-distance blend of the nearest vertices."""

    def __init__(self, v3, body, k: int = 6):
        self.weights, self.names = v3.vertex_weights(body)
        co = np.array([v.co[:] for v in body.data.vertices])
        self.tree = KDTree(len(co))
        for i, c in enumerate(co):
            self.tree.insert(c, i)
        self.tree.balance()
        self.k = k

    def at(self, P: np.ndarray, bones) -> dict:
        cols = [self.names.index(b) for b in bones if b in self.names]
        keep = [b for b in bones if b in self.names]
        out = np.zeros((len(P), len(cols)))
        for i, p in enumerate(P):
            near = self.tree.find_n(p, self.k)
            ws = np.array([1.0 / (d + 1e-4) for _c, _j, d in near])
            rows = self.weights[[j for _c, j, _d in near]][:, cols]
            out[i] = ws @ rows / ws.sum()
        return {b: out[:, k] for k, b in enumerate(keep)}


def lens(name: str, centre: Vector, ring: list[Vector], mat) -> bpy.types.Object:
    """A thin, slightly domed lens filling a glasses rim."""
    bm = bmesh.new()
    c = bm.verts.new((centre + Vector((0, -0.0008, 0)))[:])
    rim = [bm.verts.new((centre + (p - centre) * 0.97)[:]) for p in ring]
    for i in range(len(rim)):
        bm.faces.new((c, rim[i], rim[(i + 1) % len(rim)]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces[:])
    mesh = bpy.data.meshes.new(name)
    uv = bm.loops.layers.uv.new("UVMap")
    for f in bm.faces:
        for lp in f.loops:
            lp[uv].uv = (0.5, 0.5)
    bm.to_mesh(mesh)
    bm.free()
    for poly in mesh.polygons:
        if poly.normal.y > 0:
            poly.flip()
        poly.use_smooth = True
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def lens_material(name: str, tint_srgb=(0.92, 0.95, 1.0), alpha: float = 0.12) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    bsdf.inputs["Base Color"].default_value = (*[c ** 2.2 for c in tint_srgb], 1.0)
    bsdf.inputs["Alpha"].default_value = alpha
    bsdf.inputs["Roughness"].default_value = 0.04
    bsdf.inputs["Specular IOR Level"].default_value = 0.6
    mat.surface_render_method = "BLENDED"
    mat.use_backface_culling = False
    return mat
