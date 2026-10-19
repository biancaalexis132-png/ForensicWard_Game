"""Layered hair cards for the cast (v02): strips of quads with a procedural strand texture.

v01 hair was a painted scalp shell that read as a cap. v02 keeps a thin, dark,
stripe-free scalp base (so no skin shows between cards) and grows hair cards over
it along each style's flow:

* ``crop``: short cards radiating from the crown, tips lifted so the outline
  breaks up, a short fringe allowed past the hairline;
* ``chignon`` / ``ponytail``: long cards combed from the hairline to the tie
  point, a few lifted flyaways, then a wrapped bun or a tail of cards around a
  dark core.

Cards use one RGBA strand atlas per character (four strand-clump variants side by
side, root at v=0, tip at v=1). The alpha goes through a Round node, which the
glTF exporter writes as ``alphaMode: MASK`` (alpha scissor in Godot). Everything
is generated here from the cast config; nothing is downloaded.

Config (``hair.cards``, all optional; defaults per style in ``STYLE_DEFAULTS``)::

    "cards": {"count": 420, "length_m": [0.025, 0.045], "width_m": [0.010, 0.015],
              "segments": 3, "lift_m": 0.004, "flyaways": 24, "seed": 3,
              "atlas_size": 1024, "base_offset_m": 0.0012}
"""
from __future__ import annotations

import math

import bpy  # noqa: I001
import bmesh
import numpy as np
from mathutils import Vector
from mathutils.bvhtree import BVHTree

# Long combed cards map their first ROOT_M metres to the texture's root fade.
ROOT_M = 0.009
ROOT_V = 0.15

STYLE_DEFAULTS = {
    "crop": {"count": 720, "length_m": [0.024, 0.042], "width_m": [0.008, 0.012], "segments": 3,
             "lift_m": 0.002, "flyaways": 0, "base_offset_m": 0.0016, "step_m": 0.012},
    "chignon": {"count": 460, "length_m": [0.30, 0.30], "width_m": [0.012, 0.018], "segments": 0,
                "lift_m": 0.0, "flyaways": 26, "base_offset_m": 0.0012, "step_m": 0.016,
                "bun_cards": 48, "tail_cards": 0},
    "ponytail": {"count": 460, "length_m": [0.30, 0.30], "width_m": [0.012, 0.018], "segments": 0,
                 "lift_m": 0.0, "flyaways": 22, "base_offset_m": 0.0012, "step_m": 0.016,
                 "bun_cards": 0, "tail_cards": 40},
}


def _srgb(hex_value: str) -> np.ndarray:
    h = hex_value.lstrip("#")
    return np.array([int(h[i:i + 2], 16) / 255.0 for i in (0, 2, 4)])


# ------------------------------------------------------------------ textures

def strand_atlas(spec: dict, name: str, size: int, seed: int) -> bpy.types.Image:
    """Four clump variants across U; each column is a card from root (v=0) to tip (v=1).

    Strands are gathered in clumps so a card keeps ~70 % coverage through its
    length at low mip levels (an alpha-scissor card made of isolated 1-pixel
    strands disappears at a distance), and thin out toward the tip.
    """
    rng = np.random.default_rng(seed)
    base = _srgb(spec["srgb_hex"])
    grey = _srgb(spec.get("grey_srgb_hex", "#9a958f"))
    grey_fraction = float(spec.get("grey_fraction", 0.0))
    w = h = size
    cols = 4
    cw = w // cols
    rgb = np.zeros((h, w, 3))
    alpha = np.zeros((h, w))
    v = (np.arange(h) + 0.5) / h  # 0 root .. 1 tip
    for c in range(cols):
        x0 = c * cw
        xs = np.arange(cw)
        # Background colour (never seen through the clip, but keeps mips from fringing dark).
        rgb[:, x0:x0 + cw] = base * 0.9
        n_strands = int(cw * 1.1)
        clumps = rng.integers(5, 9)
        centres = np.sort(rng.uniform(0.08, 0.92, clumps)) * cw
        for _s in range(n_strands):
            k = rng.integers(0, clumps)
            spread = cw / clumps * 1.1
            sx = centres[k] + rng.normal(0, spread * 0.45)
            if sx < 2 or sx > cw - 3:
                continue
            # Strands start and end at different heights so neither end of a card shows a line.
            # Column 2 is the hairline variant: a few strands right at the root, denser above.
            # Every root fade ends by v = ROOT_V, which cards map to their first ROOT_M metres.
            start = rng.uniform(0.0, 0.07) if c != 2 else rng.uniform(0.0, 0.12)
            length = min(1.0 - start, rng.uniform(0.5, 1.0) if c != 3 else rng.uniform(0.4, 0.8))
            amp = rng.uniform(0.0, cw * 0.012)
            freq = rng.uniform(3.0, 9.0)
            phase = rng.uniform(0, math.tau)
            drift = rng.normal(0, cw * 0.025)
            width_px = rng.uniform(0.9, 2.1)
            is_grey = rng.random() < grey_fraction
            tone = rng.uniform(0.86, 1.1)
            colour = (grey if is_grey else base) * tone
            cx = sx + amp * np.sin(v * freq * math.pi + phase) + drift * v  # per row
            d = np.abs(xs[None, :] - cx[:, None])
            prof = np.clip(1.0 - (d - width_px * 0.5) / 0.9, 0.0, 1.0)
            along = np.clip((v - start) / (0.07 if c != 2 else 0.025), 0, 1) * np.clip((start + length - v) / (0.3 * length), 0, 1)
            a = prof * along[:, None]
            # Root darker (shadowed by the hair above), tip a little lighter.
            shade = (0.9 + 0.12 * np.clip(v, 0, 1))[:, None, None]
            blk = alpha[:, x0:x0 + cw]
            over = a > blk
            rgb[:, x0:x0 + cw] = np.where(over[..., None], colour[None, None, :] * shade, rgb[:, x0:x0 + cw])
            alpha[:, x0:x0 + cw] = np.maximum(blk, a)
        # Fade the column edges so cards never show a straight vertical border.
        edge = np.clip(np.minimum(xs, cw - 1 - xs) / (cw * 0.03), 0, 1)
        alpha[:, x0:x0 + cw] *= edge[None, :]
    img = np.ones((h, w, 4))
    img[..., :3] = np.clip(rgb, 0, 1)
    img[..., 3] = np.clip(alpha, 0, 1)
    image = bpy.data.images.new(name, w, h, alpha=True)
    image.pixels.foreach_set(img.astype(np.float32).ravel())
    image.pack()
    # The scalp base takes the strands' average colour, so gaps between cards do not read as patches.
    opaque = img[..., 3] > 0.5
    image["mean_srgb"] = [float(x) for x in img[..., :3][opaque].mean(axis=0)]
    return image


def base_texture(spec: dict, name: str, seed: int, mean_srgb=None) -> bpy.types.Image:
    """Scalp/core base: the strands' average colour, a little darker, with soft, stripe-free variation."""
    rng = np.random.default_rng(seed)
    base = _srgb(spec["srgb_hex"])
    grey = _srgb(spec.get("grey_srgb_hex", "#9a958f"))
    mix = base * (1 - 0.5 * float(spec.get("grey_fraction", 0.0))) + grey * 0.5 * float(spec.get("grey_fraction", 0.0))
    if mean_srgb is not None:
        mix = np.array(mean_srgb) / 0.88
    n = 128
    noise = rng.normal(0, 1, (n, n))
    for _ in range(3):
        noise = (noise + np.roll(noise, 1, 0) + np.roll(noise, -1, 0) + np.roll(noise, 1, 1) + np.roll(noise, -1, 1)) / 5
    noise /= max(1e-6, noise.std())
    img = np.ones((n, n, 4))
    img[..., :3] = np.clip(mix[None, None, :] * (0.84 + 0.04 * noise[..., None]), 0, 1)
    image = bpy.data.images.new(name, n, n, alpha=False)
    image.pixels.foreach_set(img.astype(np.float32).ravel())
    image.pack()
    return image


def card_material(name: str, image: bpy.types.Image, roughness: float, specular: float) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
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
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = specular
    mat.use_backface_culling = False
    return mat


def base_material(name: str, image: bpy.types.Image, roughness: float) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes["Principled BSDF"]
    tex = mat.node_tree.nodes.new("ShaderNodeTexImage")
    tex.image = image
    mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = 0.15
    return mat


# ------------------------------------------------------------------ geometry

def cards_object(name: str, cards: list[dict], mat, columns: int = 4) -> bpy.types.Object:
    """cards: dicts with points (n,3), normals (n,3), widths (n,), column (int), v_end (float)."""
    bm = bmesh.new()
    uv_layer = bm.loops.layers.uv.new("UVMap")
    for card in cards:
        pts = np.asarray(card["points"], dtype=float)
        nrm = np.asarray(card["normals"], dtype=float)
        wid = np.asarray(card["widths"], dtype=float)
        n = len(pts)
        if n < 2:
            continue
        tang = np.gradient(pts, axis=0)
        tang /= np.maximum(np.linalg.norm(tang, axis=1, keepdims=True), 1e-9)
        side = np.cross(nrm, tang)
        side /= np.maximum(np.linalg.norm(side, axis=1, keepdims=True), 1e-9)
        left = [bm.verts.new((pts[i] - side[i] * wid[i] * 0.5).tolist()) for i in range(n)]
        right = [bm.verts.new((pts[i] + side[i] * wid[i] * 0.5).tolist()) for i in range(n)]
        col = int(card["column"]) % columns
        u0 = col / columns + 0.004
        u1 = (col + 1) / columns - 0.004
        v_end = float(card.get("v_end", 1.0))
        # V follows arc length; a card can map its first metres to a fixed share of the
        # texture (root_m -> root_v) so long cards keep a short, absolute root fade.
        arc = np.concatenate([[0.0], np.cumsum(np.linalg.norm(np.diff(pts, axis=0), axis=1))])
        total = max(arc[-1], 1e-9)
        root_m = card.get("root_m")
        if root_m:
            rv = float(card.get("root_v", ROOT_V))
            vs = np.where(arc <= root_m, rv * arc / root_m,
                          rv + (v_end - rv) * (arc - root_m) / max(total - root_m, 1e-9))
        else:
            vs = v_end * arc / total
        for i in range(n - 1):
            f = bm.faces.new((left[i], right[i], right[i + 1], left[i + 1]))
            va, vb = float(vs[i]), float(vs[i + 1])
            for loop, uv in zip(f.loops, ((u0, va), (u1, va), (u1, vb), (u0, vb))):
                loop[uv_layer].uv = uv
            # Faces point along the scalp/core normal so shading matches the hair mass.
            if f.normal.dot(Vector(nrm[i].tolist())) < 0:
                f.normal_flip()
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def _sample_faces(body, face_mask: np.ndarray, count: int, rng, weight=None) -> tuple[np.ndarray, np.ndarray]:
    polys = body.data.polygons
    idx = np.flatnonzero(face_mask)
    areas = np.array([polys[i].area for i in idx])
    if weight is not None:
        areas = areas * weight[idx]
    p = areas / areas.sum()
    pick = rng.choice(idx, size=count, p=p)
    pts, nrms = [], []
    verts = body.data.vertices
    for fi in pick:
        f = polys[fi]
        vs = [verts[i].co for i in f.vertices]
        # Random point in the polygon: fan triangle, barycentric.
        k = rng.integers(1, len(vs) - 1)
        a, b = rng.random(), rng.random()
        if a + b > 1:
            a, b = 1 - a, 1 - b
        q = vs[0] + (vs[k] - vs[0]) * a + (vs[k + 1] - vs[0]) * b
        pts.append(q[:])
        nrms.append(f.normal[:])
    return np.array(pts), np.array(nrms)


class Scalp:
    """Surface queries on the head (body mesh) and the scalp base (cap)."""

    def __init__(self, body, cap):
        dg = bpy.context.evaluated_depsgraph_get()
        self.tree = BVHTree.FromObject(body, dg)
        self.cap = BVHTree.FromObject(cap, dg)

    def project(self, p: Vector) -> tuple[Vector, Vector]:
        loc, nrm, _i, _d = self.tree.find_nearest(p)
        return loc, nrm

    def cap_height(self, q: Vector, n: Vector) -> float:
        """Height of the scalp base above head-surface point q (0 beyond the base's edge)."""
        loc, _cn, _i, _d = self.cap.find_nearest(q)
        if loc is None:
            return 0.0
        d = loc - q
        up = d.dot(n)
        return max(0.0, up) if (d - n * up).length < 0.002 else 0.0

    def lift(self, pts: np.ndarray, nrms: np.ndarray, h: np.ndarray) -> np.ndarray:
        """Place card points h above the scalp base (cards never sink into it)."""
        out = np.empty_like(pts)
        for i, (q, n) in enumerate(zip(pts, nrms)):
            qv, nv = Vector(q.tolist()), Vector(n.tolist())
            out[i] = (qv + nv * (self.cap_height(qv, nv) + h[i]))[:]
        return out

    def outside_cap(self, p: Vector) -> float:
        """How far p's surface point lies beyond the cap edge (0 when under the cap)."""
        loc, _n, _i, d = self.cap.find_nearest(p)
        return 0.0 if loc is None else float(d)


def trace(scalp: Scalp, root: Vector, flow, step: float, max_steps: int, stop=None,
          allowance: float = 0.004) -> tuple[list[Vector], list[Vector]]:
    """Walk along the head surface following flow(p, n) -> direction."""
    p, n = scalp.project(root)
    pts, nrms = [p], [n]
    for _ in range(max_steps):
        d = flow(p, n)
        d = d - n * d.dot(n)
        if d.length < 1e-6:
            break
        # Step along the tangent, then drop onto the surface along its normal. Snapping to the
        # nearest point instead pulls paths onto the coarse mesh's edges and bunches the cards.
        q = p + d.normalized() * step
        loc, qn = scalp.project(q)
        q = q - qn * (q - loc).dot(qn)
        if scalp.outside_cap(q) > allowance + 0.0035:
            break
        pts.append(q)
        nrms.append(qn)
        p, n = q, qn
        if stop is not None and stop(p):
            break
    return pts, nrms


def resample(pts: list[Vector], count: int, first: float = 0.0) -> np.ndarray:
    """count points evenly along the path; with first > 0, an extra short root segment."""
    a = np.array([p[:] for p in pts])
    seg = np.linalg.norm(np.diff(a, axis=0), axis=1)
    s = np.concatenate([[0], np.cumsum(seg)])
    if s[-1] < 1e-6:
        return np.repeat(a[:1], count, axis=0)
    if first and s[-1] > first * 3:
        t = np.concatenate([[0.0], np.linspace(first, s[-1], count - 1)])
    else:
        t = np.linspace(0, s[-1], count)
    return np.stack([np.interp(t, s, a[:, k]) for k in range(3)], axis=1)


def _smooth(x: float) -> float:
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def combed_segments(pts: list[Vector]) -> int:
    """Segments of at most ~1.8 cm: a flat quad over the curved scalp dips by L^2/8r, which
    over a longer span would sink the card's middle into the scalp base."""
    length = sum((b - a).length for a, b in zip(pts, pts[1:]))
    return int(min(16, max(3, math.ceil(length / 0.018))))


def combed_flow(tie: Vector):
    """Toward the tie, plus a backward pull in front of it.

    On the forehead and crown the straight line to a low tie points into the head,
    so its tangent part is tiny and unstable (cards fanned out in a starburst). The
    backward pull, strongest at the front, combs that hair straight back.
    """
    def flow(p: Vector, n: Vector) -> Vector:
        to_tie = tie - p
        to_tie = to_tie - n * to_tie.dot(n)
        back = Vector((0.0, 1.0, 0.0))
        back = back - n * back.dot(n)
        w = _smooth((tie.y - p.y - 0.04) / 0.1)
        t = to_tie.normalized() if to_tie.length > 1e-6 else Vector()
        b = back.normalized() if back.length > 1e-6 else Vector()
        return t * (1.0 - 0.85 * w) + b * (2.0 * w)
    return flow


def scalp_cards(body, cap, centre: Vector, top_z: float, spec: dict, cfg: dict, tie: Vector | None,
                face_mask: np.ndarray, rng) -> list[dict]:
    """Cards over the scalp for every style."""
    scalp = Scalp(body, cap)
    style = spec["style"]
    vol_top = float(spec.get("volume_top_m", 0.006))
    vol_side = float(spec.get("volume_side_m", 0.003))
    count = int(cfg["count"])
    lmin, lmax = cfg["length_m"]
    wmin, wmax = cfg["width_m"]
    step = float(cfg["step_m"])
    crown = Vector((centre.x, centre.y + float(cfg.get("crown_back_m", 0.035)), top_z - 0.012))
    sweep = float(cfg.get("sweep", 0.25))
    fringe = float(spec.get("fringe_m", 0.006))

    def up_weight(p: Vector) -> float:
        return _smooth((p.z - centre.z) / max(1e-6, top_z - centre.z))

    # Roots: uniform over the scalp plus a band along the visible hairline.
    weight = None
    if tie is not None:
        # Combed-back hair: every card runs to the tie, so cards rooted far from it (the front
        # and crown) must be more numerous for the coverage to stay even along their length.
        weight = np.zeros(len(body.data.polygons))
        far = max((body.data.polygons[i].center - tie).length for i in np.flatnonzero(face_mask))
        for i in np.flatnonzero(face_mask):
            weight[i] = 1.0 + 0.5 * ((body.data.polygons[i].center - tie).length / far) ** 2
    roots, _n = _sample_faces(body, face_mask, count, rng, weight=weight)
    cards = []
    for k, r in enumerate(roots):
        root = Vector(r.tolist())
        if style == "crop":
            # Short at the sides and nape (a taper), longest on top.
            length = rng.uniform(lmin, lmax) * (0.55 + 0.55 * up_weight(root))

            def flow(p, n):
                up = up_weight(p)
                side = 1.0 if p.x > centre.x else -1.0
                # Top: combed back with a slight sweep to one side; sides and back: down and back.
                top = Vector((sweep, 1.0, 0.25))
                low = Vector((0.25 * side, 0.45, -1.0))
                return top * up + low * (1.0 - up)
            steps = max(2, int(round(length / step)))
            pts, nrms = trace(scalp, root, flow, length / steps, steps, allowance=fringe)
            if len(pts) < 2:
                continue
            seg = 3
        else:
            # Cards of 8-16 cm from roots spread evenly: coverage comes from local roots, so the
            # cards fanning out from the forehead toward the crown leave no gaps between them.
            flow = combed_flow(tie)
            max_len = rng.uniform(*cfg.get("combed_length_m", (0.08, 0.16)))
            pts, nrms = trace(scalp, root, flow, step, max(2, int(max_len / step)),
                              stop=lambda p: (p - tie).length < 0.014, allowance=0.002)
            if len(pts) < 2:
                continue
            seg = combed_segments(pts)
        res = resample(pts, seg + 1, first=ROOT_M if style != "crop" else 0.0)
        nn = np.array([scalp.project(Vector(p.tolist()))[1][:] for p in res])
        t = np.linspace(0, 1, len(res))
        up = np.array([up_weight(Vector(p.tolist())) for p in res])
        layer = rng.integers(0, 3)
        if style == "crop":
            vol = vol_side + (vol_top - vol_side) * up
            lift = float(cfg["lift_m"]) * rng.uniform(0.5, 1.2) * (0.4 + 0.6 * up)
            h = 0.0004 + layer * 0.0008 + vol * 0.4 * t + lift * t ** 1.5
        else:
            # Combed back: hugs the scalp, a little fuller over the crown, flat at the tie.
            arc = np.sin(np.pi * t)
            h = 0.0009 + layer * 0.0009 + (vol_side + (vol_top - vol_side) * up) * 0.35 * arc
        pos = scalp.lift(res, nn, h)
        w = rng.uniform(wmin, wmax) * (1.0 - 0.35 * t if style == "crop" else 1.0 - 0.45 * t ** 2)
        card = {"points": pos, "normals": nn, "widths": w, "column": int(rng.choice([0, 1, 3])),
                "v_end": 1.0 if style == "crop" else rng.uniform(0.85, 1.0)}
        card["root_m"] = ROOT_M if style != "crop" else min(ROOT_M * 0.6, 0.3 * float(np.linalg.norm(
            np.diff(pos, axis=0), axis=1).sum()))
        cards.append(card)
    # Hairline row: cards rooted just outside the scalp base's edge, so feathered strand
    # roots, not the base's rim, make the hairline.
    bm = bmesh.new()
    bm.from_mesh(cap.data)
    edge = [v.co.copy() for v in bm.verts if v.is_boundary]
    cap_centre = sum((v.co for v in bm.verts), Vector()) / len(bm.verts)
    bm.free()
    spacing = float(cfg.get("hairline_spacing_m", 0.0042))
    picked: list[Vector] = []
    for p in sorted(edge, key=lambda q: math.atan2(q.x - centre.x, q.y - centre.y)):
        if all((p - q).length > spacing for q in picked[-6:]):
            picked.append(p)
    made = 0
    for p in picked:
        outward = p - cap_centre
        # Irregular root offsets, so the narrow cards' starts never line up into steps.
        root, n = scalp.project(p + outward.normalized() * rng.uniform(0.0005, 0.0035))
        if style == "crop":
            def flow(q, nn):
                up = up_weight(q)
                side = 1.0 if q.x > centre.x else -1.0
                return Vector((sweep, 1.0, 0.25)) * up + Vector((0.25 * side, 0.45, -1.0)) * (1.0 - up)
            length = rng.uniform(lmin, lmax) * (0.5 + 0.6 * up_weight(root))
            steps = 3
            pts, nrms = trace(scalp, root, flow, length / steps, steps, allowance=0.006)
            seg = 3
        else:
            pts, nrms = trace(scalp, root, combed_flow(tie), step, 24,
                              stop=lambda q: (q - tie).length < 0.014, allowance=0.006)
            seg = combed_segments(pts)
        if len(pts) < 2:
            print("    hairline card failed at", tuple(round(c, 3) for c in p))
            continue
        made += 1
        res = resample(pts, seg + 1, first=0.0 if style == "crop" else ROOT_M)
        nn = np.array([scalp.project(Vector(q.tolist()))[1][:] for q in res])
        t = np.linspace(0, 1, len(res))
        h = 0.0008 + 0.0008 * t
        card = {"points": scalp.lift(res, nn, h), "normals": nn,
                "widths": rng.uniform(0.006, 0.01) * (1.0 - 0.3 * t), "column": 2, "v_end": 1.0}
        if style != "crop":
            card["root_m"] = ROOT_M
        cards.append(card)

    print(f"  hairline row: {made} of {len(picked)} edge points")
    # Flyaways: a few narrow, lifted cards over the crown and temples break the outline.
    fly = int(cfg.get("flyaways", 0))
    if fly:
        weight = np.zeros(len(body.data.polygons))
        for i in np.flatnonzero(face_mask):
            c = body.data.polygons[i].center
            weight[i] = 0.2 + _smooth((c.z - centre.z) / max(1e-6, top_z - centre.z))
        roots, _n = _sample_faces(body, face_mask, fly, rng, weight=weight)
        for r in roots:
            root = Vector(r.tolist())

            flow = combed_flow(tie) if tie is not None else (lambda p, n: p - crown)
            pts, nrms = trace(scalp, root, flow, 0.014, 5, allowance=0.002)
            if len(pts) < 3:
                continue
            res = resample(pts, 5)
            nn = np.array([scalp.project(Vector(p.tolist()))[1][:] for p in res])
            t = np.linspace(0, 1, len(res))
            h = 0.0025 + 0.006 * np.sin(np.pi * t * 0.8) * rng.uniform(0.6, 1.2)
            cards.append({"points": scalp.lift(res, nn, h), "normals": nn,
                          "widths": rng.uniform(0.004, 0.007) * (1 - 0.5 * t), "column": 3, "v_end": 0.9})
    return cards


def bun_cards(centre: Vector, axis: Vector, radii, count: int, rng) -> list[dict]:
    """Ribbons wrapped round a chignon, like a twisted roll seen from behind."""
    out = axis.normalized()
    e1 = Vector((1, 0, 0))
    e2 = out.cross(e1).normalized()
    e1 = e2.cross(out).normalized()
    rx, ry, rz = radii  # x across, y along out, z vertical
    cards = []
    for k in range(count // 2):
        # Outer face: spirals from the middle of the roll outward, like a twisted coil.
        th0 = rng.uniform(0, math.tau)
        ph0 = rng.uniform(0.0, 0.2)
        dph = rng.uniform(0.9, 1.25)
        dth = rng.uniform(1.6, 2.6)
        scale = rng.uniform(1.0, 1.08)
        n = 10
        pts, nrms, widths = [], [], []
        for i in range(n):
            s = i / (n - 1)
            ph = min(1.5, ph0 + dph * s)
            th = th0 + dth * s
            local = Vector((math.sin(ph) * math.cos(th), math.cos(ph), math.sin(ph) * math.sin(th)))
            p = centre + (e1 * (local.x * rx) + out * (local.y * ry) + e2 * (local.z * rz)) * scale
            g = Vector((local.x / rx, local.y / ry, local.z / rz))
            nrm = (e1 * g.x + out * g.y + e2 * g.z).normalized()
            pts.append(p[:])
            nrms.append(nrm[:])
            widths.append(rng.uniform(0.016, 0.024) * (0.6 + 0.4 * s))
        cards.append({"points": np.array(pts), "normals": np.array(nrms), "widths": np.array(widths),
                      "column": int(rng.choice([0, 1])), "v_end": rng.uniform(0.85, 1.0)})
    for k in range(count - count // 2):
        tilt = rng.uniform(-0.9, 0.9)
        start = rng.uniform(0, math.tau)
        sweep = rng.uniform(math.pi * 0.9, math.pi * 1.6)
        scale = rng.uniform(1.0, 1.1)
        n = 12
        pts, nrms, widths = [], [], []
        for i in range(n):
            a = start + sweep * i / (n - 1)
            # Circle in the plane perpendicular to a tilted roll axis, on the ellipsoid.
            ca, sa = math.cos(a), math.sin(a)
            lat = tilt * 0.6
            local = Vector((ca * math.cos(lat), math.sin(lat) * 0.6 + 0.15, sa * math.cos(lat)))
            p = centre + (e1 * (local.x * rx) + out * (local.y * ry) + e2 * (local.z * rz)) * scale
            g = Vector((local.x / rx, local.y / ry, local.z / rz))
            nrm = (e1 * g.x + out * g.y + e2 * g.z).normalized()
            pts.append(p[:])
            nrms.append(nrm[:])
            widths.append(rng.uniform(0.014, 0.02) * (1 - 0.3 * (i / (n - 1)) ** 2))
        cards.append({"points": np.array(pts), "normals": np.array(nrms), "widths": np.array(widths),
                      "column": rng.integers(0, 3), "v_end": rng.uniform(0.8, 1.0)})
    return cards


def tail_cards(axis_pts: list[Vector], radii: list[float], count: int, rng) -> list[dict]:
    """Cards around a ponytail axis, overlapping, with the tips spreading slightly."""
    a = np.array([p[:] for p in axis_pts])
    n = len(a)
    tang = np.gradient(a, axis=0)
    tang /= np.linalg.norm(tang, axis=1, keepdims=True)
    cards = []
    for k in range(count):
        ang = math.tau * k / count + rng.uniform(-0.15, 0.15)
        frac = rng.uniform(0.95, 1.25)
        length_frac = rng.uniform(0.78, 1.0)
        m = max(4, int(n * length_frac))
        pts, nrms, widths = [], [], []
        for i in range(m):
            t = tang[i]
            e1 = Vector((1, 0, 0))
            e1 = (e1 - Vector(t.tolist()) * e1.dot(Vector(t.tolist()))).normalized()
            e2 = Vector(t.tolist()).cross(e1).normalized()
            s = i / (n - 1)
            r = radii[i] * frac * (1.0 + 0.25 * s * s)
            wob = 0.002 * math.sin(s * 7 + k)
            radial = e1 * math.cos(ang) + e2 * math.sin(ang)
            p = Vector(a[i].tolist()) + radial * (r + wob)
            pts.append(p[:])
            nrms.append(radial[:])
            widths.append(max(0.005, math.tau * r / count * 2.6) * (1 - 0.25 * s))
        cards.append({"points": np.array(pts), "normals": np.array(nrms), "widths": np.array(widths),
                      "column": rng.integers(0, 4), "v_end": 1.0})
    return cards
