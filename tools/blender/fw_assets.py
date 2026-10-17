"""The Forensic Ward: parametric asset builders (architecture, doors, props).

Every builder creates an asset root empty named with its asset id and returns
it. Geometry is real, metrically scaled and exported as-is. Builders take a
collection and an optional location so the same code produces both the
library .blend files and the assembled environments.

Coordinate frame for wall-like assets: the wall runs along local +X, its
thickness spans local Y, and its FRONT face is -Y. In wall_run() the front
face is on the right-hand side of the travel direction p -> q.
"""

import math

from mathutils import Vector

import fw_lib as L
from fw_lib import DOOR_H, WALL_H, WALL_T, MeshBuilder

PI = math.pi

# --------------------------------------------------------------------------
# Walls
# --------------------------------------------------------------------------


def add_wall(mb, length, front_mat="M_Wall_WarmWhite", back_mat="M_Wall_WarmWhite", openings=(),
             protected_front=False, height=WALL_H, skirting=True):
    """A wall slab along local X (0..length). openings: dicts with
    x (centre), w, bottom, top, kind ("door" | "window"), glass (material or
    None), glass_front (material seen from the front, for one-way glass)."""
    t = WALL_T
    ops = sorted(openings, key=lambda o: o["x"])
    cursor = 0.0
    solid_ranges = []    # x-ranges with full-height wall (for skirting/dado)
    door_ranges = []
    for op in ops:
        a, b = op["x"] - op["w"] / 2, op["x"] + op["w"] / 2
        if a - cursor > 1e-4:
            mb.box((a - cursor, t, height), ((cursor + a) / 2, 0, height / 2), back_mat, face_mats={"-y": front_mat})
            solid_ranges.append((cursor, a))
        if height - op["top"] > 1e-4:
            mb.box((b - a, t, height - op["top"]), ((a + b) / 2, 0, (op["top"] + height) / 2), back_mat,
                   face_mats={"-y": front_mat})
        if op["bottom"] > 1e-4:
            mb.box((b - a, t, op["bottom"]), ((a + b) / 2, 0, op["bottom"] / 2), back_mat, face_mats={"-y": front_mat})
            solid_ranges.append((a, b))
        if op["kind"] == "door":
            door_ranges.append((a, b))
        else:
            _window(mb, op, a, b)
        cursor = b
    if length - cursor > 1e-4:
        mb.box((length - cursor, t, height), ((cursor + length) / 2, 0, height / 2), back_mat,
               face_mats={"-y": front_mat})
        solid_ranges.append((cursor, length))

    for a, b in _merge(solid_ranges):
        if skirting:
            for side in (-1, 1):
                mb.box((b - a, 0.012, 0.1), ((a + b) / 2, side * (t / 2 + 0.006), 0.05), "M_Skirting_Coved")
        if protected_front:
            # Impact-resistant PVC dado sheet, 0.1-1.0 m.
            mb.box((b - a, 0.006, 0.9), ((a + b) / 2, -(t / 2 + 0.003), 0.55), "M_Wall_Protection_Green")
    return _merge(solid_ranges), door_ranges


def _merge(ranges):
    out = []
    for a, b in sorted(ranges):
        if out and a - out[-1][1] < 1e-4:
            out[-1] = (out[-1][0], max(b, out[-1][1]))
        else:
            out.append((a, b))
    return out


def _window(mb, op, a, b):
    t = WALL_T
    bottom, top = op["bottom"], op["top"]
    w, h = b - a, top - bottom
    cx, cz = (a + b) / 2, (bottom + top) / 2
    f = 0.05
    frame = "M_Steel_Painted_White"
    depth = t + 0.02
    mb.box((w, depth, f), (cx, 0, top - f / 2), frame)
    mb.box((w, depth, f), (cx, 0, bottom + f / 2), frame)
    mb.box((f, depth, h - 2 * f), (a + f / 2, 0, cz), frame)
    mb.box((f, depth, h - 2 * f), (b - f / 2, 0, cz), frame)
    glass = op.get("glass", "M_Glass_Clear")
    if glass:
        face = {"-y": op["glass_front"]} if op.get("glass_front") else None
        mb.box((w - 2 * f, 0.012, h - 2 * f), (cx, 0, cz), glass, face_mats=face)
    # Sills both sides.
    for side in (-1, 1):
        mb.box((w + 0.08, 0.05, 0.02), (cx, side * (t / 2 + 0.015), bottom - 0.01), frame)


def wall_run(mb, p, q, **kwargs):
    """Wall from p to q (x, y); its FRONT face is on the right of p -> q.
    Opening "x" values are distances from p."""
    p, q = Vector((p[0], p[1], 0)), Vector((q[0], q[1], 0))
    d = q - p
    theta = math.atan2(d.y, d.x)
    with mb.at(tuple(p), (0, 0, theta)):
        return add_wall(mb, d.length, **kwargs)


def door_opening(x, w, h=DOOR_H):
    return {"x": x, "w": w, "bottom": 0.0, "top": h, "kind": "door"}


def window_opening(x, w, bottom, top, glass="M_Glass_Clear", glass_front=None):
    return {"x": x, "w": w, "bottom": bottom, "top": top, "kind": "window", "glass": glass,
            "glass_front": glass_front}


def corner_post(mb, x, y, mat="M_Wall_WarmWhite"):
    mb.box((WALL_T, WALL_T, WALL_H), (x, y, WALL_H / 2), mat)


# --------------------------------------------------------------------------
# Floors and ceilings
# --------------------------------------------------------------------------

def add_floor(mb, x0, x1, y0, y1, mat="M_Floor_Vinyl_Corridor"):
    mb.box((x1 - x0, y1 - y0, 0.1), ((x0 + x1) / 2, (y0 + y1) / 2, -0.05), mat)


def add_ceiling(mb, x0, x1, y0, y1, z=WALL_H, tile=0.5, lights=(), vents=()):
    """Suspended ceiling on the world grid: board, exposed T-bar grid,
    recessed LED panels (lights: (cx, cy, sx, sy)) and return-air grilles."""
    mb.box((x1 - x0, y1 - y0, 0.02), ((x0 + x1) / 2, (y0 + y1) / 2, z + 0.01), "M_Ceiling_Tile")
    gx = math.ceil(x0 / tile + 1e-6) * tile
    while gx < x1 - 1e-6:
        mb.box((0.024, y1 - y0, 0.012), (gx, (y0 + y1) / 2, z - 0.006), "M_Ceiling_Grid")
        gx += tile
    gy = math.ceil(y0 / tile + 1e-6) * tile
    while gy < y1 - 1e-6:
        mb.box((x1 - x0, 0.024, 0.012), ((x0 + x1) / 2, gy, z - 0.006), "M_Ceiling_Grid")
        gy += tile
    for cx, cy, sx, sy in lights:
        mb.box((sx, sy, 0.03), (cx, cy, z - 0.02), "M_Steel_Painted_White", face_mats={"-z": "M_Emissive_LightPanel"})
    for cx, cy, sx, sy in vents:
        mb.box((sx, sy, 0.02), (cx, cy, z - 0.015), "M_Steel_Painted_White")
        n = int(sx / 0.04)
        for i in range(n):
            mb.box((0.012, sy - 0.04, 0.02), (cx - sx / 2 + 0.02 + i * (sx - 0.04) / max(n - 1, 1), cy, z - 0.03),
                   "M_Steel_Painted_Grey")


# --------------------------------------------------------------------------
# Corridor modules (local frame: centreline x = 0, walls at x = +/-1.5)
# --------------------------------------------------------------------------

CORRIDOR_HALF = 1.5          # wall centreline offset -> 2.8 m clear width
RAIL_Z = 0.9


def _handrail(mb, ranges):
    """Closed-profile anti-ligature handrail fixed flush to the wall face
    (no gap behind the rail), with returns at each end."""
    for a, b in ranges:
        if b - a < 0.4:
            continue
        a2, b2 = a + 0.1, b - 0.1
        y = -(WALL_T / 2 + 0.006 + 0.035)
        mb.box((b2 - a2, 0.07, 0.05), ((a2 + b2) / 2, y, RAIL_Z), "M_Upholstery_Charcoal")
        for x in (a2, b2):
            mb.box((0.05, 0.07, 0.05), (x, y, RAIL_Z), "M_Rubber_Dark")


def corridor_slice(mb, length=2.0, west=None, east=None, light=True, west_back="M_Wall_WarmWhite",
                   east_back="M_Wall_WarmWhite", vent=False, rails=True, ceiling_mb=None):
    """Straight corridor slice from y = 0 to y = length.
    west/east: None, or opening dicts with x measured along +y from y = 0.
    ceiling_mb: optional separate builder for the ceiling (same local frame)."""
    add_floor(mb, -CORRIDOR_HALF - WALL_T / 2, CORRIDOR_HALF + WALL_T / 2, 0, length)
    lights = [(0, length / 2, 0.5, 1.0)] if light else []
    vents = [(0, length / 2, 0.5, 0.25)] if vent and not light else []
    add_ceiling(ceiling_mb or mb, -CORRIDOR_HALF + WALL_T / 2, CORRIDOR_HALF - WALL_T / 2, 0, length,
                lights=lights, vents=vents)
    w_open = [west] if west else []
    solid, _ = wall_run(mb, (-CORRIDOR_HALF, 0), (-CORRIDOR_HALF, length), front_mat="M_Wall_WarmWhite",
                        back_mat=west_back, openings=w_open, protected_front=True)
    if rails:
        with mb.at((-CORRIDOR_HALF, 0, 0), (0, 0, PI / 2)):
            _handrail(mb, solid)
    e_open = []
    if east:
        e = dict(east)
        e["x"] = length - east["x"]
        e_open = [e]
    solid, _ = wall_run(mb, (CORRIDOR_HALF, length), (CORRIDOR_HALF, 0), front_mat="M_Wall_WarmWhite",
                        back_mat=east_back, openings=e_open, protected_front=True)
    if rails:
        with mb.at((CORRIDOR_HALF, length, 0), (0, 0, -PI / 2)):
            _handrail(mb, solid)


def corridor_node(mb, open_sides):
    """3 x 3 m junction square (x -1.5..1.5, y 0..3). open_sides: subset of
    {"south", "north", "west", "east"}. Corner posts close every corner."""
    h = CORRIDOR_HALF
    x0 = -h - (0 if "west" in open_sides else WALL_T / 2)
    x1 = h + (0 if "east" in open_sides else WALL_T / 2)
    y0 = 0 - (0 if "south" in open_sides else WALL_T / 2)
    y1 = 3 + (0 if "north" in open_sides else WALL_T / 2)
    add_floor(mb, x0, x1, y0, y1)
    add_ceiling(mb, -h + (0 if "west" in open_sides else WALL_T / 2), h - (0 if "east" in open_sides else WALL_T / 2),
                0 + (0 if "south" in open_sides else WALL_T / 2), 3 - (0 if "north" in open_sides else WALL_T / 2),
                lights=[(0, 1.5, 1.0, 0.5)])
    runs = {
        "west": ((-h, 0), (-h, 3), (-h, 0, PI / 2)),
        "north": ((-h, 3), (h, 3), (-h, 3, 0)),
        "east": ((h, 3), (h, 0), (h, 3, -PI / 2)),
        "south": ((h, 0), (-h, 0), (h, 0, PI)),
    }
    for side, (p, q, frame) in runs.items():
        if side in open_sides:
            continue
        solid, _ = wall_run(mb, p, q, protected_front=True)
        with mb.at((frame[0], frame[1], 0), (0, 0, frame[2])):
            _handrail(mb, [(0.15, 2.85)])
    for x, y in ((-h, 0), (h, 0), (-h, 3), (h, 3)):
        corner_post(mb, x, y)


# --------------------------------------------------------------------------
# Doors (local frame: opening centred on x = 0, wall plane y = 0,
# front/push side is -y, hinge on the left seen from the front)
# --------------------------------------------------------------------------

def _door_frame(mb, width, height, mat):
    depth = WALL_T + 0.04
    jamb = 0.05
    mb.box((jamb, depth, height), (-width / 2 + jamb / 2, 0, height / 2), mat)
    mb.box((jamb, depth, height), (width / 2 - jamb / 2, 0, height / 2), mat)
    mb.box((width, depth, jamb), (0, 0, height - jamb / 2), mat)
    # Architraves on both faces.
    for side in (-1, 1):
        y = side * (depth / 2 + 0.005)
        mb.box((0.06, 0.01, height + 0.06), (-width / 2 - 0.03, y, (height + 0.06) / 2), mat)
        mb.box((0.06, 0.01, height + 0.06), (width / 2 + 0.03, y, (height + 0.06) / 2), mat)
        mb.box((width + 0.12, 0.01, 0.06), (0, y, height + 0.03), mat)


def _leaf(mb, width, height, leaf_mat, vision=None, kick=True, handle="lever", mirror=False):
    """Door leaf built from the hinge (x = 0) towards +x (or -x if mirror).
    vision: (width, height, bottom, offset_from_lock_edge)."""
    s = -1 if mirror else 1
    t = 0.054
    if vision:
        vw, vh, vb, off = vision
        vx1 = width - off            # lock-side edge of the vision panel
        vx0 = vx1 - vw
        parts = [((0, vx0), (0, height)), ((vx1, width), (0, height)),
                 ((vx0, vx1), (0, vb)), ((vx0, vx1), (vb + vh, height))]
        for (xa, xb), (za, zb) in parts:
            mb.box((xb - xa, t, zb - za), (s * (xa + xb) / 2, 0, (za + zb) / 2), leaf_mat)
        mb.box((vw, 0.008, vh), (s * (vx0 + vx1) / 2, 0, vb + vh / 2), "M_Glass_Wired")
        for side in (-1, 1):  # Glazing beads.
            y = side * (t / 2 + 0.006)
            mb.box((vw + 0.04, 0.012, 0.02), (s * (vx0 + vx1) / 2, y, vb - 0.01), "M_Steel_Brushed")
            mb.box((vw + 0.04, 0.012, 0.02), (s * (vx0 + vx1) / 2, y, vb + vh + 0.01), "M_Steel_Brushed")
            mb.box((0.02, 0.012, vh), (s * (vx0 - 0.01), y, vb + vh / 2), "M_Steel_Brushed")
            mb.box((0.02, 0.012, vh), (s * (vx1 + 0.01), y, vb + vh / 2), "M_Steel_Brushed")
    else:
        mb.box((width, t, height), (s * width / 2, 0, height / 2), leaf_mat)
    if kick:
        for side in (-1, 1):
            mb.box((width - 0.04, 0.002, 0.3), (s * width / 2, side * (t / 2 + 0.001), 0.17), "M_Steel_Brushed")
    # Continuous (piano) hinge.
    mb.cyl(0.012, height - 0.02, (0, -t / 2, height / 2), "M_Steel_Brushed", segs=10)
    hx = s * (width - 0.09)
    if handle == "lever":
        for side in (-1, 1):
            y = side * (t / 2 + 0.03)
            mb.box((0.06, 0.012, 0.16), (hx, side * (t / 2 + 0.006), 1.0), "M_Steel_Brushed")
            mb.box((0.13, 0.025, 0.022), (hx - s * 0.05, y, 1.04), "M_Steel_Brushed")
    else:  # Anti-ligature flush pull plates on both faces.
        for side in (-1, 1):
            mb.box((0.08, 0.02, 0.3), (hx, side * (t / 2 + 0.01), 1.0), "M_Steel_Brushed")
            mb.box((0.06, 0.006, 0.22), (hx, side * (t / 2 + 0.021), 1.0), "M_Plastic_Black")
    # Secure lock case.
    mb.box((0.03, t + 0.006, 0.25), (s * (width - 0.02), 0, 1.0), "M_Steel_Brushed")


def build_door(coll, asset_id, kind, loc=(0, 0, 0), rot=(0, 0, 0)):
    """kind: 'secure_single' (1200), 'secure_double' (1800), 'interior' (1000),
    'service_historic' (1200, mid-century painted service door)."""
    spec = {
        "secure_single": dict(opening=1.2, leaves=1, leaf_mat="M_Door_Secure_SteelBlue", frame="M_Steel_Painted_Grey",
                              vision=(0.2, 0.75, 1.1, 0.18), handle="pull", closer=True),
        "secure_double": dict(opening=1.8, leaves=2, leaf_mat="M_Door_Secure_SteelBlue", frame="M_Steel_Painted_Grey",
                              vision=(0.25, 0.6, 1.15, 0.2), handle="pull", closer=True),
        "interior": dict(opening=1.0, leaves=1, leaf_mat="M_Door_Laminate_Wood", frame="M_Steel_Painted_White",
                         vision=(0.12, 0.9, 0.95, 0.12), handle="lever", closer=False),
        "service_historic": dict(opening=1.2, leaves=1, leaf_mat="M_Paint_Historic_Green", frame="M_Paint_Historic_Cream",
                                 vision=None, handle="lever", closer=False),
    }[kind]
    root = L.empty(asset_id, coll, loc=loc, rot=rot, display="ARROWS", size=0.4,
                   props={"category": "door", "opening_width_m": spec["opening"], "opening_height_m": DOOR_H,
                          "leaf_hinge_axis": "local Z (Godot Y); rotate leaf node to open"})
    root["display_name"] = asset_id.replace("_", " ")
    w = spec["opening"]
    mb = MeshBuilder()
    _door_frame(mb, w, DOOR_H, spec["frame"])
    if spec["closer"]:
        mb.box((0.3, 0.06, 0.06), (-w / 2 + 0.35, -(WALL_T / 2 + 0.06), DOOR_H + 0.06), "M_Steel_Painted_Grey")
    if kind == "secure_double":
        mb.box((w - 0.1, 0.05, 0.04), (0, -(WALL_T / 2 + 0.03), DOOR_H - 0.07), "M_Steel_Brushed")  # Mag-lock.
    mb.build(asset_id + "_Frame", coll, root, bevel=0.002)
    leaf_h = DOOR_H - 0.06
    if spec["leaves"] == 1:
        lw = w - 0.11
        mb = MeshBuilder()
        _leaf(mb, lw, leaf_h, spec["leaf_mat"], spec["vision"], handle=spec["handle"])
        leaf = mb.build(asset_id + "_Leaf", coll, root, loc=(-lw / 2, 0, 0.01), bevel=0.003)
        L.collision_box(asset_id + "_Leaf_COL", coll, leaf, (lw, 0.06, leaf_h), (lw / 2, 0, leaf_h / 2))
    else:
        lw = (w - 0.11) / 2
        for side, sign, x in (("L", 1, -(w - 0.11) / 2), ("R", -1, (w - 0.11) / 2)):
            mb = MeshBuilder()
            _leaf(mb, lw, leaf_h, spec["leaf_mat"], spec["vision"], handle=spec["handle"], mirror=sign < 0)
            leaf = mb.build("%s_Leaf_%s" % (asset_id, side), coll, root, loc=(x, 0, 0.01), bevel=0.003)
            L.collision_box("%s_Leaf_%s_COL" % (asset_id, side), coll, leaf, (lw, 0.06, leaf_h),
                            (sign * lw / 2, 0, leaf_h / 2))
    return root


# --------------------------------------------------------------------------
# Props (origin: floor centre unless noted; front faces -Y)
# --------------------------------------------------------------------------

def _root(coll, asset_id, category, loc, rot, display_name, collision_note=None):
    root = L.empty(asset_id, coll, loc=loc, rot=rot, display="ARROWS", size=0.3,
                   props={"category": category, "display_name": display_name})
    if collision_note:
        root["collision"] = collision_note
    return root


def prop_desk_clinical(coll, aid="PROP_Desk_Clinical", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Clinical office desk 1600")
    mb = MeshBuilder()
    w, d, h = 1.6, 0.8, 0.75
    mb.box((w, d, 0.03), (0, 0, h - 0.015), "M_Wood_Laminate_Desk")
    mb.box((0.03, d - 0.05, h - 0.03), (-w / 2 + 0.03, 0, (h - 0.03) / 2), "M_Steel_Painted_Grey")
    mb.box((0.03, d - 0.05, h - 0.03), (w / 2 - 0.03, 0, (h - 0.03) / 2), "M_Steel_Painted_Grey")
    mb.box((w - 0.1, 0.02, 0.4), (0, d / 2 - 0.08, h - 0.25), "M_Steel_Painted_Grey")  # Modesty panel.
    px = w / 2 - 0.26  # Drawer pedestal under the right side.
    mb.box((0.42, d - 0.12, h - 0.06), (px, -0.02, (h - 0.06) / 2), "M_Steel_Painted_White")
    for i, (z, dh) in enumerate(((0.58, 0.14), (0.42, 0.14), (0.17, 0.3))):
        mb.box((0.4, 0.01, dh - 0.01), (px, -d / 2 + 0.035, z), "M_Steel_Painted_White")
        mb.box((0.14, 0.02, 0.012), (px, -d / 2 + 0.025, z + dh / 2 - 0.035), "M_Steel_Brushed")
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_chair_office(coll, aid="PROP_Chair_Office", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Task chair (staff only)")
    mb = MeshBuilder()
    for i in range(5):
        a = i * 2 * PI / 5
        with mb.at((0, 0, 0.07), (0, 0, a)):
            mb.box((0.3, 0.04, 0.03), (0.15, 0, 0), "M_Plastic_Black")
            mb.sphere(0.025, (0.29, 0, -0.04), "M_Plastic_Black", segs=10, rings=5)
    mb.cyl(0.025, 0.32, (0, 0, 0.25), "M_Steel_Brushed")
    mb.box((0.5, 0.48, 0.08), (0, 0, 0.46), "M_Upholstery_Charcoal")
    mb.box((0.46, 0.06, 0.52), (0, 0.24, 0.8), "M_Upholstery_Charcoal", rot=(-0.12, 0, 0))
    mb.box((0.04, 0.12, 0.25), (0, 0.2, 0.5), "M_Plastic_Black")
    for x in (-0.27, 0.27):
        mb.box((0.04, 0.05, 0.2), (x, 0.05, 0.56), "M_Plastic_Black")
        mb.box((0.06, 0.26, 0.03), (x, 0.03, 0.67), "M_Plastic_Black")
    mb.build(aid + "_Mesh", coll, root, bevel=0.006)
    L.collision_box(aid + "_COL", coll, root, (0.6, 0.6, 1.05), (0, 0, 0.525))
    return root


def prop_chair_visitor(coll, aid="PROP_Chair_Visitor", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Visitor chair, sled base")
    mb = MeshBuilder()
    for x in (-0.22, 0.22):
        mb.box((0.025, 0.5, 0.02), (x, 0, 0.01), "M_Steel_Brushed")
        mb.box((0.025, 0.025, 0.44), (x, -0.22, 0.23), "M_Steel_Brushed")
        mb.box((0.025, 0.025, 0.84), (x, 0.22, 0.43), "M_Steel_Brushed")
        mb.box((0.025, 0.47, 0.025), (x, 0, 0.62), "M_Steel_Brushed")
    mb.box((0.5, 0.48, 0.06), (0, 0, 0.46), "M_Upholstery_Teal")
    mb.box((0.48, 0.05, 0.32), (0, 0.24, 0.72), "M_Upholstery_Teal", rot=(-0.1, 0, 0))
    mb.build(aid + "_Mesh", coll, root, bevel=0.006)
    L.collision_box(aid + "_COL", coll, root, (0.55, 0.55, 0.9), (0, 0, 0.45))
    return root


def prop_chair_interview(coll, aid="PROP_Chair_Interview_Weighted", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot,
                 "Weighted moulded interview chair (anti-ligature, no gaps, cannot be lifted)")
    mb = MeshBuilder()
    mb.box((0.56, 0.56, 0.38), (0, 0, 0.19), "M_Polyurethane_Interview")
    mb.box((0.6, 0.58, 0.08), (0, 0.0, 0.42), "M_Polyurethane_Interview")
    mb.box((0.6, 0.14, 0.5), (0, 0.24, 0.7), "M_Polyurethane_Interview", rot=(-0.14, 0, 0))
    for x in (-0.28, 0.28):
        mb.box((0.08, 0.5, 0.2), (x, 0.02, 0.55), "M_Polyurethane_Interview")
    mb.build(aid + "_Mesh", coll, root, bevel=0.03)
    L.collision_box(aid + "_COL", coll, root, (0.64, 0.64, 0.95), (0, 0.02, 0.475))
    return root


def prop_table_interview(coll, aid="PROP_Table_Interview_Fixed", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Interview table, floor-fixed pedestal, radiused corners")
    mb = MeshBuilder()
    mb.box((1.2, 0.8, 0.04), (0, 0, 0.72), "M_Wood_Laminate_Desk")
    mb.box((1.18, 0.78, 0.02), (0, 0, 0.69), "M_Plastic_Black")
    mb.box((0.2, 0.2, 0.66), (0, 0, 0.36), "M_Steel_Painted_Grey")
    mb.box((0.6, 0.5, 0.025), (0, 0, 0.0125), "M_Steel_Painted_Grey")
    for x in (-0.25, 0.25):
        for y in (-0.2, 0.2):
            mb.cyl(0.012, 0.01, (x, y, 0.03), "M_Steel_Brushed", segs=8)
    mb.build(aid + "_Mesh", coll, root, bevel=0.015)
    L.collision_box(aid + "_COL", coll, root, (1.2, 0.8, 0.74), (0, 0, 0.37))
    return root


def prop_filing_cabinet(coll, aid="PROP_Cabinet_Filing_4Drawer", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Locking 4-drawer filing cabinet")
    mb = MeshBuilder()
    w, d, h = 0.47, 0.62, 1.32
    mb.box((w, d, h), (0, 0, h / 2), "M_Steel_Painted_Grey")
    for i in range(4):
        z = 0.17 + i * 0.32
        mb.box((w - 0.03, 0.012, 0.3), (0, -d / 2 - 0.006, z), "M_Steel_Painted_Grey")
        mb.box((0.16, 0.025, 0.025), (0, -d / 2 - 0.02, z + 0.06), "M_Steel_Brushed")
        mb.box((0.08, 0.004, 0.035), (0, -d / 2 - 0.014, z + 0.11), "M_Paper")
    mb.cyl(0.012, 0.02, (0.17, -d / 2 - 0.01, h - 0.05), "M_Steel_Brushed", axis="Y", segs=10)
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_bookcase(coll, aid="PROP_Bookcase_Binders", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Steel bookcase with clinical binders")
    mb = MeshBuilder()
    w, d, h = 0.9, 0.35, 1.9
    mat = "M_Steel_Painted_White"
    for x in (-w / 2 + 0.01, w / 2 - 0.01):
        mb.box((0.02, d, h), (x, 0, h / 2), mat)
    mb.box((w, 0.01, h), (0, d / 2 - 0.005, h / 2), mat)
    binder_mats = ["M_Binder_Navy", "M_Binder_Grey", "M_Binder_Maroon", "M_Binder_Navy", "M_Folder_Manila"]
    for i in range(5):
        z = 0.05 + i * 0.45
        mb.box((w - 0.04, d - 0.02, 0.02), (0, 0, z), mat)
        if i < 4:
            x = -w / 2 + 0.04
            n = 0
            while x < w / 2 - 0.12 and not (i == 2 and n > 9):
                bw = 0.05 + 0.02 * ((n * 7 + i * 3) % 3)
                bh = 0.29 + 0.03 * ((n * 5 + i) % 2)
                mb.box((bw - 0.004, d - 0.08, bh), (x + bw / 2, -0.01, z + 0.01 + bh / 2),
                       binder_mats[(n * 3 + i) % len(binder_mats)])
                x += bw
                n += 1
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_terminal_ehr(coll, aid="PROP_Terminal_EHR", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Desk-top EHR workstation. Origin on the desk surface. The screen is a
    separate object with 0..1 UVs so Godot can show a SubViewport texture."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "EHR workstation (24\" monitor, keyboard, mouse, thin client)")
    mb = MeshBuilder()
    mb.box((0.24, 0.2, 0.012), (0, 0.05, 0.006), "M_Plastic_Black")
    mb.box((0.06, 0.03, 0.3), (0, 0.08, 0.16), "M_Plastic_Black")
    mb.box((0.56, 0.035, 0.34), (0, 0.04, 0.38), "M_Plastic_Black")
    for i in range(5):
        mb.box((0.4, 0.012, 0.012), (0, -0.22 + i * 0.022, 0.018 + i * 0.002), "M_Plastic_OffWhite")
    mb.box((0.44, 0.15, 0.015), (0, -0.18, 0.008), "M_Plastic_Black")
    mb.sphere(0.03, (0.3, -0.18, 0.012), "M_Plastic_Black", segs=12, rings=6, scale=(0.75, 1.1, 0.45))
    mb.box((0.04, 0.18, 0.18), (-0.38, 0.05, 0.09), "M_Plastic_Black")
    mb.box((0.004, 0.006, 0.006), (-0.38, -0.04, 0.16), "M_Emissive_LED_Green")
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    smb = MeshBuilder()
    smb.box((0.52, 0.004, 0.3), (0, 0.02, 0.38), "M_Emissive_Screen")
    screen = smb.build(aid + "_Screen", coll, root)
    L.planar_uv(screen, ("x", "z"))
    screen["godot_hint"] = "Apply a ViewportTexture to this surface for the live EHR screen."
    return root


def prop_phone(coll, aid="PROP_Phone_Institutional", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Institutional desk phone")
    mb = MeshBuilder()
    mb.box((0.2, 0.22, 0.05), (0, 0, 0.03), "M_Plastic_OffWhite", rot=(0.15, 0, 0))
    mb.box((0.05, 0.21, 0.04), (-0.065, 0.0, 0.07), "M_Plastic_OffWhite")
    for r in range(4):
        for c in range(3):
            mb.box((0.018, 0.014, 0.006), (0.02 + c * 0.025, -0.06 + r * 0.025, 0.06 + r * 0.004), "M_Plastic_Black")
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    return root


def prop_clock_caged(coll, aid="PROP_Clock_Wall_Caged", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Origin at wall-mount centre; face looks toward -Y."""
    root = _root(coll, aid, "fixture", loc, rot, "Wall clock behind polycarbonate guard")
    mb = MeshBuilder()
    mb.cyl(0.16, 0.04, (0, -0.02, 0), "M_Plastic_Black", axis="Y", segs=32, cap_mat="M_Clock_Face")
    for i in range(12):
        a = i * PI / 6
        mb.box((0.006, 0.004, 0.025 if i % 3 else 0.04), (0.13 * math.sin(a), -0.042, 0.13 * math.cos(a)),
               "M_Plastic_Black", rot=(0, a, 0))
    mb.box((0.006, 0.004, 0.08), (0.028, -0.045, 0.028), "M_Plastic_Black", rot=(0, PI / 4, 0))   # 10:10
    mb.box((0.004, 0.004, 0.11), (-0.04, -0.046, 0.038), "M_Plastic_Black", rot=(0, -PI / 3.3, 0))
    mb.cyl(0.175, 0.07, (0, -0.035, 0), "M_Glass_Clear", axis="Y", segs=32)
    mb.build(aid + "_Mesh", coll, root)
    return root


def prop_camera_dome(coll, aid="PROP_Camera_Dome", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Origin at the ceiling surface; hangs toward -Z."""
    root = _root(coll, aid, "security", loc, rot, "Ceiling dome CCTV camera")
    mb = MeshBuilder()
    mb.cyl(0.09, 0.025, (0, 0, -0.0125), "M_Plastic_OffWhite", segs=24)
    mb.sphere(0.07, (0, 0, -0.025), "M_Glass_OneWay_Observer", segs=20, rings=10, scale=(1, 1, 0.8))
    mb.sphere(0.02, (0, -0.02, -0.06), "M_Plastic_Black", segs=10, rings=5)
    mb.build(aid + "_Mesh", coll, root)
    return root


def prop_light_vandal(coll, aid="PROP_Light_VandalResistant", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Flush, tamper-resistant round luminaire for patient areas. Origin at ceiling."""
    root = _root(coll, aid, "lighting", loc, rot, "Tamper-resistant flush luminaire")
    mb = MeshBuilder()
    mb.cyl(0.2, 0.05, (0, 0, -0.025), "M_Steel_Painted_White", segs=32, cap_mat="M_Emissive_LightPanel")
    for i in range(6):
        a = i * PI / 3
        mb.cyl(0.006, 0.004, (0.185 * math.cos(a), 0.185 * math.sin(a), -0.051), "M_Steel_Brushed", segs=6)
    mb.build(aid + "_Mesh", coll, root)
    L.empty("LIGHTMARK_" + aid, coll, root, (0, 0, -0.12), display="SPHERE", size=0.06,
            props={"marker_type": "light", "light_kind": "spot_down", "energy_hint": 1.0, "color": "#FFF4E5",
                   "range_m": 5.0})
    return root


def prop_vent_grille(coll, aid="PROP_Vent_Grille_Wall", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Anti-ligature perforated grille; origin at wall centre, faces -Y."""
    root = _root(coll, aid, "fixture", loc, rot, "Anti-ligature ventilation grille 600x300")
    mb = MeshBuilder()
    mb.box((0.6, 0.02, 0.3), (0, -0.01, 0), "M_Steel_Painted_White")
    for i in range(11):
        mb.box((0.5, 0.004, 0.012), (0, -0.021, -0.11 + i * 0.022), "M_Steel_Painted_Grey")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


def prop_bin(coll, aid="PROP_Bin_Waste", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Waste bin (staff areas)")
    mb = MeshBuilder()
    mb.cyl(0.15, 0.4, (0, 0, 0.2), "M_Steel_Painted_Grey", segs=24, r2=0.17)
    mb.cyl(0.172, 0.02, (0, 0, 0.405), "M_Plastic_Black", segs=24)
    mb.build(aid + "_Mesh", coll, root)
    return root


def prop_reader(coll, aid="PROP_Reader_Access", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Card reader; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "security", loc, rot, "Access card reader with status LEDs")
    mb = MeshBuilder()
    mb.box((0.05, 0.022, 0.1), (0, -0.011, 0), "M_Plastic_Black")
    mb.box((0.03, 0.002, 0.03), (0, -0.023, 0.01), "M_Steel_Brushed")
    led = MeshBuilder()
    led.box((0.008, 0.003, 0.008), (-0.01, -0.023, 0.04), "M_Emissive_LED_Red")
    led.box((0.008, 0.003, 0.008), (0.01, -0.023, 0.04), "M_Emissive_LED_Green")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    led.build(aid + "_LEDs", coll, root)["godot_hint"] = "Toggle red/green surfaces for locked/unlocked."
    return root


def prop_intercom(coll, aid="PROP_Intercom_Speaker", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "security", loc, rot, "Vandal-resistant intercom panel")
    mb = MeshBuilder()
    mb.box((0.14, 0.02, 0.22), (0, -0.01, 0), "M_Steel_Brushed")
    for r in range(5):
        for c in range(5):
            mb.cyl(0.004, 0.003, (-0.04 + c * 0.02, -0.021, 0.02 + r * 0.016), "M_Plastic_Black", axis="Y", segs=6)
    mb.cyl(0.018, 0.01, (0, -0.024, -0.06), "M_Steel_Painted_Grey", axis="Y", segs=16)
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


def prop_duress_strip(coll, aid="PROP_Duress_Strip_2m", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Wall-run personal-alarm strip; origin at left end on the wall, faces -Y."""
    root = _root(coll, aid, "security", loc, rot, "Staff duress (panic) strip, 2 m")
    mb = MeshBuilder()
    mb.box((2.0, 0.025, 0.05), (1.0, -0.0125, 0), "M_Steel_Painted_Grey")
    mb.box((1.96, 0.006, 0.025), (1.0, -0.028, 0), "M_Safety_Red")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


def prop_acoustic_panel(coll, aid="PROP_Acoustic_Panel", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "fixture", loc, rot, "Fabric acoustic wall panel 1200x600")
    mb = MeshBuilder()
    mb.box((1.2, 0.04, 0.6), (0, -0.02, 0), "M_Acoustic_Fabric")
    mb.build(aid + "_Mesh", coll, root, bevel=0.01)
    return root


def prop_sign_room(coll, aid="PROP_Sign_Room", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Room-ID sign mount; the face is a separate object with UVs so text
    can be applied in Godot (Label3D or texture)."""
    root = _root(coll, aid, "signage", loc, rot, "Room identification sign mount")
    mb = MeshBuilder()
    mb.box((0.3, 0.012, 0.15), (0, -0.006, 0), "M_Signage_Blue")
    mb.box((0.3, 0.004, 0.02), (0, -0.014, -0.06), "M_Steel_Brushed")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    face = MeshBuilder()
    face.box((0.27, 0.002, 0.1), (0, -0.0135, 0.01), "M_Signage_Panel")
    ob = face.build(aid + "_Face", coll, root)
    L.planar_uv(ob, ("x", "z"))
    return root


def prop_folder_chart(coll, aid="PROP_Folder_MedicalChart", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "document", loc, rot, "Paper medical chart folder")
    mb = MeshBuilder()
    mb.box((0.24, 0.31, 0.012), (0, 0, 0.006), "M_Folder_Manila")
    mb.box((0.22, 0.29, 0.006), (0.005, 0.0, 0.013), "M_Paper")
    mb.box((0.06, 0.02, 0.008), (0, 0.13, 0.02), "M_Steel_Brushed")
    mb.build(aid + "_Mesh", coll, root, bevel=0.001)
    return root


def prop_certificate(coll, aid="PROP_Frame_Certificate", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "decor", loc, rot, "Framed qualification certificate")
    mb = MeshBuilder()
    mb.box((0.32, 0.02, 0.42), (0, -0.01, 0), "M_Plastic_Black")
    mb.box((0.27, 0.004, 0.37), (0, -0.021, 0), "M_Paper")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


def prop_handrail(coll, aid="PROP_Handrail_Wall_2m", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Origin at left end on the wall face at floor level; rail at 0.9 m."""
    root = _root(coll, aid, "fixture", loc, rot, "Anti-ligature closed-profile handrail, 2 m")
    mb = MeshBuilder()
    with mb.at((0, WALL_T / 2 + 0.006, 0)):
        _handrail(mb, [(0.0, 2.0)])
    mb.build(aid + "_Mesh", coll, root, bevel=0.008)
    return root


def prop_bed_antiligature(coll, aid="PROP_Bed_AntiLigature", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Moulded plinth bed fixed to the floor: no gaps, legs or ligature points.
    Head end at +Y."""
    root = _root(coll, aid, "furniture", loc, rot, "Anti-ligature plinth bed with mattress")
    mb = MeshBuilder()
    mb.box((0.95, 2.05, 0.32), (0, 0, 0.16), "M_Polyurethane_Interview")
    mb.box((0.9, 1.98, 0.16), (0, 0, 0.4), "M_Upholstery_Teal")
    mb.box((0.84, 0.6, 0.02), (0, 0.6, 0.49), "M_Paper")              # Sheet fold.
    mb.box((0.6, 0.38, 0.1), (0, 0.76, 0.53), "M_Plastic_OffWhite")   # Pillow.
    mb.build(aid + "_Mesh", coll, root, bevel=0.025)
    L.collision_box(aid + "_COL", coll, root, (0.95, 2.05, 0.48), (0, 0, 0.24))
    return root


def prop_wardrobe_antiligature(coll, aid="PROP_Wardrobe_AntiLigature", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Doorless wardrobe with sloped top and anti-ligature shelving; front -Y."""
    root = _root(coll, aid, "furniture", loc, rot, "Anti-ligature open wardrobe, sloped top")
    mb = MeshBuilder()
    w, d, h = 0.8, 0.55, 1.8
    mat = "M_Wood_Laminate_Desk"
    for x in (-w / 2 + 0.015, w / 2 - 0.015):
        mb.box((0.03, d, h), (x, 0, h / 2), mat)
    mb.box((w, 0.02, h), (0, d / 2 - 0.01, h / 2), mat)
    mb.box((w, d, 0.03), (0, 0, 0.015), mat)
    mb.box((w, d + 0.05, 0.03), (0, -0.02, h + 0.08), mat, rot=(0.35, 0, 0))   # Sloped top.
    for z in (0.45, 0.9, 1.35):
        mb.box((w - 0.06, d - 0.05, 0.025), (0, 0.01, z), mat, rot=(-0.12, 0, 0))  # Sloped shelves.
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_shelving_archive(coll, aid="PROP_Shelving_Archive", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Steel archive shelving bay 1.8 m with archive boxes and loose files."""
    root = _root(coll, aid, "furniture", loc, rot, "Steel archive shelving with record boxes")
    mb = MeshBuilder()
    w, d, h = 1.8, 0.45, 2.2
    for x in (-w / 2, w / 2):
        for y in (-d / 2, d / 2):
            mb.box((0.035, 0.035, h), (x, y, h / 2), "M_Steel_Painted_Grey")
    box_mats = ["M_Folder_Manila", "M_Paper", "M_Folder_Manila", "M_Binder_Grey"]
    for i in range(6):
        z = 0.08 + i * 0.4
        mb.box((w, d, 0.02), (0, 0, z), "M_Steel_Painted_Grey")
        if i == 5:
            continue
        x = -w / 2 + 0.06
        n = 0
        while x < w / 2 - 0.36:
            bw = 0.34 if (n + i) % 4 else 0.26
            bh = 0.26 if (n * 3 + i) % 5 else 0.18
            mb.box((bw - 0.02, d - 0.07, bh), (x + bw / 2, -0.01, z + 0.01 + bh / 2), box_mats[(n + 2 * i) % 4])
            mb.box((0.08, 0.002, 0.05), (x + bw / 2, -d / 2 + 0.024, z + 0.01 + bh * 0.6), "M_Paper")
            x += bw
            n += 1
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_noticeboard(coll, aid="PROP_NoticeBoard", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Staff notice board (rotas, policies); origin at wall centre, faces -Y."""
    root = _root(coll, aid, "decor", loc, rot, "Staff notice board with pinned notices")
    mb = MeshBuilder()
    mb.box((1.2, 0.025, 0.9), (0, -0.0125, 0), "M_Steel_Painted_Grey")
    mb.box((1.14, 0.006, 0.84), (0, -0.028, 0), "M_Acoustic_Fabric")
    for i, (x, z, w, h) in enumerate(((-0.4, 0.2, 0.21, 0.3), (-0.12, 0.15, 0.21, 0.3), (0.2, 0.22, 0.3, 0.21),
                                      (-0.35, -0.2, 0.3, 0.21), (0.05, -0.18, 0.21, 0.3), (0.38, -0.15, 0.21, 0.3))):
        mb.box((w, 0.002, h), (x, -0.032, z), "M_Paper" if i % 3 else "M_Folder_Manila")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


PROP_BUILDERS = [
    prop_desk_clinical, prop_chair_office, prop_chair_visitor, prop_chair_interview, prop_table_interview,
    prop_filing_cabinet, prop_bookcase, prop_terminal_ehr, prop_phone, prop_clock_caged, prop_camera_dome,
    prop_light_vandal, prop_vent_grille, prop_bin, prop_reader, prop_intercom, prop_duress_strip,
    prop_acoustic_panel, prop_sign_room, prop_folder_chart, prop_certificate, prop_handrail,
    prop_bed_antiligature, prop_wardrobe_antiligature, prop_shelving_archive, prop_noticeboard,
]


# --------------------------------------------------------------------------
# Stage 3: medication, ward beds, linen and emergency equipment
# (origin: floor centre unless noted; front faces -Y)
# --------------------------------------------------------------------------

def _castors(mb, xs, ys, r=0.04, mount_z=0.1):
    """Swivel castors: a fork stem under each corner and a wheel on local X."""
    for x in xs:
        for y in ys:
            mb.box((0.03, 0.03, mount_z - 2 * r), (x, y, (mount_z + 2 * r) / 2), "M_Steel_Brushed")
            mb.cyl(r, 0.025, (x, y, r), "M_Rubber_Dark", axis="X", segs=12)


def prop_cart_medication(coll, aid="PROP_Cart_Medication", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Locking medication cart for the nursing station. Drawers face -Y."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Locking medication cart, 6 drawers")
    mb = MeshBuilder()
    w, d, h = 0.62, 0.48, 1.0
    body_z0 = 0.12
    mb.box((w, d, h - body_z0 - 0.04), (0, 0, (h + body_z0 - 0.04) / 2), "M_Steel_Painted_White")
    mb.box((w + 0.04, d + 0.04, 0.035), (0, 0, h - 0.0175), "M_Wood_Laminate_Desk")    # Work top.
    z = h - 0.08
    for dh in (0.1, 0.1, 0.1, 0.16, 0.16, 0.2):                                        # Drawer fronts.
        mb.box((w - 0.04, 0.012, dh - 0.012), (0, -d / 2 - 0.006, z - dh / 2), "M_Plastic_MedCart_Blue")
        mb.box((0.18, 0.02, 0.016), (0, -d / 2 - 0.02, z - 0.03), "M_Steel_Brushed")
        z -= dh
    mb.cyl(0.012, 0.02, (w / 2 - 0.06, -d / 2 - 0.012, h - 0.065), "M_Steel_Brushed", axis="Y", segs=10)  # Key lock.
    for x in (-w / 2 - 0.03, w / 2 + 0.03):                                             # Push handles.
        mb.box((0.025, 0.025, 0.12), (x, d / 2 - 0.08, h - 0.12), "M_Steel_Brushed")
        mb.box((0.025, 0.025, 0.12), (x, -d / 2 + 0.08, h - 0.12), "M_Steel_Brushed")
        mb.box((0.025, d - 0.14, 0.025), (x, 0, h - 0.07), "M_Steel_Brushed")
    mb.box((0.3, 0.004, 0.08), (0, d / 2 + 0.002, h - 0.15), "M_Paper")                 # MAR clip-board.
    _castors(mb, (-w / 2 + 0.06, w / 2 - 0.06), (-d / 2 + 0.06, d / 2 - 0.06), mount_z=body_z0)
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (w + 0.06, d + 0.04, h), (0, 0, h / 2))
    return root


def prop_bed_hospital(coll, aid="PROP_Bed_Hospital_Adjustable", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Profiling hospital bed on castors with split side rails. Head end at +Y.
    Medical bay / infirmary only: it has ligature points by design."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Profiling hospital bed with side rails (medical bay)")
    mb = MeshBuilder()
    w, l, deck = 0.98, 2.18, 0.55
    for x in (-0.38, 0.38):                                                             # Base frame.
        mb.box((0.05, l - 0.2, 0.06), (x, 0, 0.16), "M_Steel_Painted_Grey")
    mb.box((0.81, 0.05, 0.06), (0, 0, 0.16), "M_Steel_Painted_Grey")
    for y in (-0.55, 0.55):                                                             # Lifting columns.
        mb.box((0.12, 0.12, deck - 0.2), (0, y, 0.19 + (deck - 0.2) / 2), "M_Steel_Painted_White")
    _castors(mb, (-0.38, 0.38), (-l / 2 + 0.12, l / 2 - 0.12), r=0.06, mount_z=0.13)
    mb.box((0.9, l - 0.14, 0.05), (0, 0, deck), "M_Steel_Painted_White")                # Deck.
    mb.box((0.88, 1.98, 0.14), (0, 0, deck + 0.095), "M_Upholstery_Teal")               # Mattress.
    mb.box((0.9, 1.4, 0.02), (0, -0.25, deck + 0.175), "M_Linen_White")                 # Sheet.
    mb.box((0.62, 0.4, 0.11), (0, 0.72, deck + 0.22), "M_Linen_White")                  # Pillow.
    mb.box((w, 0.05, 0.5), (0, l / 2 - 0.025, deck + 0.2), "M_Plastic_OffWhite")       # Headboard.
    mb.box((w, 0.05, 0.36), (0, -l / 2 + 0.025, deck + 0.13), "M_Plastic_OffWhite")    # Footboard.
    for side in (-1, 1):                                                                # Split side rails.
        x = side * (w / 2 - 0.01)
        for y0, y1 in ((0.15, 0.95), (-0.85, -0.05)):
            for zz in (deck + 0.2, deck + 0.38):
                mb.box((0.025, y1 - y0, 0.03), (x, (y0 + y1) / 2, zz), "M_Plastic_OffWhite")
            for y in (y0 + 0.03, y1 - 0.03):
                mb.box((0.025, 0.03, 0.2), (x, y, deck + 0.29), "M_Plastic_OffWhite")
    mb.box((0.18, 0.04, 0.09), (w / 2 - 0.02, 0.6, deck + 0.29), "M_Plastic_Black")    # Rail controls.
    mb.build(aid + "_Mesh", coll, root, bevel=0.006)
    L.collision_box(aid + "_COL", coll, root, (w, l, deck + 0.45), (0, 0, (deck + 0.45) / 2))
    return root


def prop_trolley_linen(coll, aid="PROP_Trolley_Linen", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Single-bag linen skip with lid on castors."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Linen skip trolley with lidded bag")
    mb = MeshBuilder()
    s, h = 0.5, 0.95
    for x in (-s / 2, s / 2):
        for y in (-s / 2, s / 2):
            mb.box((0.025, 0.025, h - 0.12), (x, y, 0.12 + (h - 0.12) / 2), "M_Steel_Brushed")
    for zz in (0.2, h - 0.02):                                                          # Frame hoops.
        for y in (-s / 2, s / 2):
            mb.box((s, 0.025, 0.025), (0, y, zz), "M_Steel_Brushed")
        for x in (-s / 2, s / 2):
            mb.box((0.025, s, 0.025), (x, 0, zz), "M_Steel_Brushed")
    mb.box((s - 0.04, s - 0.04, h - 0.32), (0, 0, 0.24 + (h - 0.32) / 2), "M_Fabric_LaundryBag_Blue")
    mb.box((s - 0.06, s - 0.06, 0.04), (0, 0, h - 0.06), "M_Linen_White")             # Linen showing.
    mb.box((s + 0.04, s + 0.04, 0.02), (0, 0.02, h + 0.03), "M_Plastic_OffWhite", rot=(-0.12, 0, 0))  # Lid.
    mb.box((0.12, 0.03, 0.02), (0, -s / 2 - 0.02, h + 0.02), "M_Plastic_Black")
    _castors(mb, (-s / 2, s / 2), (-s / 2, s / 2), r=0.035, mount_z=0.12)
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (s + 0.05, s + 0.05, h + 0.05), (0, 0, (h + 0.05) / 2))
    return root


def prop_cart_crash(coll, aid="PROP_Cart_Crash_Resus", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Resuscitation (crash) trolley: tagged drawers, defibrillator on top,
    CPR board on the back and an oxygen cylinder in a side holder."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Resuscitation trolley with defibrillator")
    mb = MeshBuilder()
    w, d, h = 0.76, 0.52, 0.98
    body_z0 = 0.13
    mb.box((w, d, h - body_z0), (0, 0, (h + body_z0) / 2), "M_Safety_Red")
    mb.box((w + 0.04, d + 0.04, 0.03), (0, 0, h + 0.015), "M_Plastic_OffWhite")
    z = h - 0.04
    for dh in (0.12, 0.12, 0.16, 0.2, 0.2):
        mb.box((w - 0.05, 0.012, dh - 0.014), (0, -d / 2 - 0.006, z - dh / 2), "M_Steel_Painted_White")
        mb.box((0.22, 0.02, 0.016), (0, -d / 2 - 0.02, z - 0.035), "M_Steel_Brushed")
        z -= dh
    mb.box((0.02, 0.006, 0.03), (w / 2 - 0.06, -d / 2 - 0.015, h - 0.07), "M_Plastic_Sharps_Yellow")  # Seal tag.
    mb.box((0.5, 0.03, 0.6), (0, d / 2 + 0.03, h - 0.25), "M_Plastic_Black")                         # CPR board.
    defib_z = h + 0.03
    mb.box((0.34, 0.26, 0.2), (-0.1, -0.02, defib_z + 0.1), "M_Plastic_OffWhite")
    mb.box((0.34, 0.03, 0.06), (-0.1, -0.02, defib_z + 0.23), "M_Plastic_Black")                     # Carry handle.
    mb.box((0.06, 0.12, 0.08), (0.18, -0.05, defib_z + 0.04), "M_Plastic_Black")                     # Pads pouch.
    mb.cyl(0.075, 0.68, (w / 2 + 0.09, 0.08, 0.52), "M_Plastic_OffWhite", segs=16)                   # O2 cylinder.
    mb.cyl(0.03, 0.08, (w / 2 + 0.09, 0.08, 0.9), "M_Steel_Brushed", segs=10)                        # Regulator.
    mb.box((0.04, 0.12, 0.3), (w / 2 + 0.02, 0.08, 0.5), "M_Steel_Brushed")                          # Holder.
    _castors(mb, (-w / 2 + 0.07, w / 2 - 0.07), (-d / 2 + 0.07, d / 2 - 0.07), r=0.05, mount_z=body_z0)
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    smb = MeshBuilder()
    smb.box((0.2, 0.004, 0.12), (-0.12, -0.152, defib_z + 0.1), "M_Emissive_Screen")
    screen = smb.build(aid + "_DefibScreen", coll, root)
    L.planar_uv(screen, ("x", "z"))
    screen["godot_hint"] = "Optional ViewportTexture for a live rhythm display."
    L.collision_box(aid + "_COL", coll, root, (w + 0.3, d + 0.1, h + 0.28), (0.1, 0.02, (h + 0.28) / 2))
    return root


def prop_cabinet_aed(coll, aid="PROP_Cabinet_AED_Wall", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Wall AED cabinet with glazed door; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "emergency", loc, rot, "Wall-mounted AED cabinet with signage")
    mb = MeshBuilder()
    w, d, h = 0.4, 0.18, 0.45
    mb.box((w, d, h), (0, -d / 2, 0), "M_Plastic_AED_Green", face_mats={"-y": "M_Plastic_OffWhite"})
    mb.box((0.26, 0.09, 0.3), (0, -d + 0.06, -0.02), "M_Plastic_Sharps_Yellow")       # AED unit inside.
    mb.box((w - 0.04, 0.006, h - 0.04), (0, -d - 0.004, 0), "M_Glass_Clear")
    mb.box((0.03, 0.03, 0.12), (w / 2 - 0.04, -d - 0.02, 0), "M_Steel_Brushed")       # Door pull.
    mb.box((0.3, 0.008, 0.12), (0, -0.004, h / 2 + 0.12), "M_Plastic_AED_Green")       # AED sign above.
    mb.box((0.08, 0.004, 0.08), (0, -0.01, h / 2 + 0.12), "M_Plastic_OffWhite")
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    return root


def prop_cylinder_oxygen(coll, aid="PROP_Cylinder_Oxygen_Trolley", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Oxygen cylinder on a two-wheel trolley. Cylinder colours follow the
    usual medical-oxygen white shoulder; no labels or markings are claimed."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Oxygen cylinder on transport trolley")
    mb = MeshBuilder()
    mb.cyl(0.09, 0.95, (0, 0.02, 0.6), "M_Steel_Painted_Grey", segs=20)
    mb.cyl(0.09, 0.12, (0, 0.02, 1.1), "M_Plastic_OffWhite", segs=20, r2=0.045)       # Shoulder.
    mb.cyl(0.03, 0.08, (0, 0.02, 1.2), "M_Steel_Brushed", segs=10)                    # Valve.
    mb.cyl(0.035, 0.03, (0, -0.02, 1.2), "M_Plastic_Black", axis="Y", segs=12)        # Gauge.
    for x in (-0.13, 0.13):
        mb.box((0.025, 0.025, 1.15), (x, 0.1, 0.62), "M_Steel_Brushed", rot=(0.08, 0, 0))
        mb.cyl(0.1, 0.04, (x, 0.12, 0.1), "M_Rubber_Dark", axis="X", segs=16)
    mb.box((0.28, 0.025, 0.025), (0, 0.15, 1.18), "M_Steel_Brushed")                  # Handle.
    for zz in (0.35, 0.85):
        mb.box((0.26, 0.2, 0.02), (0, 0.02, zz), "M_Steel_Brushed")                   # Retaining straps.
    mb.box((0.26, 0.24, 0.02), (0, 0.0, 0.12), "M_Steel_Brushed")                     # Foot plate.
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (0.34, 0.34, 1.25), (0, 0.04, 0.625))
    return root


def prop_monitor_vitals(coll, aid="PROP_Monitor_VitalSigns_Stand", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Mobile observations monitor on a 5-star stand. Screen faces -Y."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Mobile vital-signs monitor on stand")
    mb = MeshBuilder()
    for i in range(5):
        a = i * 2 * PI / 5
        with mb.at((0, 0, 0.07), (0, 0, a)):
            mb.box((0.26, 0.035, 0.025), (0.13, 0, 0), "M_Plastic_OffWhite")
            mb.sphere(0.022, (0.25, 0, -0.04), "M_Plastic_Black", segs=10, rings=5)
    mb.cyl(0.018, 1.0, (0, 0, 0.57), "M_Steel_Brushed", segs=12)
    mb.box((0.28, 0.14, 0.22), (0, 0, 1.18), "M_Plastic_OffWhite")
    mb.box((0.28, 0.04, 0.04), (0, 0.02, 1.31), "M_Plastic_OffWhite")
    mb.box((0.22, 0.12, 0.08), (0, 0.02, 0.92), "M_Steel_Painted_Grey")               # Accessory basket.
    mb.box((0.08, 0.06, 0.04), (0.04, 0.01, 0.98), "M_Upholstery_Charcoal")           # BP cuff.
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    smb = MeshBuilder()
    smb.box((0.2, 0.004, 0.14), (0, -0.072, 1.19), "M_Emissive_Screen")
    screen = smb.build(aid + "_Screen", coll, root)
    L.planar_uv(screen, ("x", "z"))
    screen["godot_hint"] = "Optional ViewportTexture for live observations."
    L.collision_box(aid + "_COL", coll, root, (0.55, 0.55, 1.35), (0, 0, 0.675))
    return root


def prop_bin_sharps(coll, aid="PROP_Bin_Sharps", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Counter-top sharps container; origin at the base centre."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Sharps container (treatment room counter)")
    mb = MeshBuilder()
    mb.box((0.24, 0.17, 0.26), (0, 0, 0.13), "M_Plastic_Sharps_Yellow")
    mb.box((0.25, 0.18, 0.05), (0, 0, 0.285), "M_Plastic_Sharps_Yellow")
    mb.box((0.08, 0.01, 0.025), (0, -0.09, 0.29), "M_Plastic_Black")                  # Aperture.
    mb.box((0.14, 0.002, 0.09), (0, -0.086, 0.14), "M_Paper")                         # Blank label.
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    return root


def prop_dispenser_handgel(coll, aid="PROP_Dispenser_HandGel", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Wall hand-gel dispenser; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "fixture", loc, rot, "Wall hand-gel dispenser (staff areas)")
    mb = MeshBuilder()
    mb.box((0.11, 0.1, 0.24), (0, -0.05, 0), "M_Plastic_OffWhite")
    mb.box((0.08, 0.04, 0.05), (0, -0.1, -0.06), "M_Steel_Painted_Grey", rot=(0.3, 0, 0))   # Push lever.
    mb.box((0.06, 0.004, 0.08), (0, -0.101, 0.05), "M_Glass_Clear")                  # Level window.
    mb.build(aid + "_Mesh", coll, root, bevel=0.006)
    return root


def prop_wheelchair(coll, aid="PROP_Wheelchair", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Folding transit wheelchair. Front (footplates) faces -Y."""
    root = _root(coll, aid, "clinical_equipment", loc, rot, "Transit wheelchair")
    mb = MeshBuilder()
    sw = 0.46
    for side in (-1, 1):
        x = side * (sw / 2 + 0.02)
        mb.cyl(0.3, 0.03, (x + side * 0.04, 0.12, 0.3), "M_Rubber_Dark", axis="X", segs=28)     # Rear wheel.
        mb.cyl(0.05, 0.05, (x + side * 0.04, 0.12, 0.3), "M_Steel_Brushed", axis="X", segs=12)  # Hub.
        mb.cyl(0.07, 0.025, (x, -0.33, 0.07), "M_Rubber_Dark", axis="X", segs=14)               # Front castor.
        mb.box((0.025, 0.5, 0.025), (x, -0.08, 0.48), "M_Steel_Brushed")                       # Seat rail.
        mb.box((0.025, 0.025, 0.42), (x, -0.33, 0.3), "M_Steel_Brushed")
        mb.box((0.025, 0.025, 0.55), (x, 0.17, 0.72), "M_Steel_Brushed", rot=(-0.08, 0, 0))    # Back post.
        mb.box((0.025, 0.12, 0.025), (x, 0.24, 0.99), "M_Steel_Brushed")                       # Push handle.
        mb.box((0.04, 0.07, 0.04), (x, 0.3, 0.99), "M_Plastic_Black")
        mb.box((0.04, 0.32, 0.03), (x, -0.06, 0.68), "M_Plastic_Black")                         # Armrest.
        mb.box((0.025, 0.025, 0.2), (x, -0.06, 0.58), "M_Steel_Brushed")
        mb.box((0.16, 0.13, 0.015), (side * 0.1, -0.44, 0.1), "M_Plastic_Black")                # Footplate.
        mb.box((0.025, 0.025, 0.36), (side * 0.18, -0.39, 0.27), "M_Steel_Brushed", rot=(0.35, 0, 0))
    mb.box((sw, 0.44, 0.03), (0, -0.08, 0.5), "M_Upholstery_Charcoal")
    mb.box((sw, 0.02, 0.38), (0, 0.18, 0.74), "M_Upholstery_Charcoal", rot=(-0.08, 0, 0))
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (0.7, 1.0, 1.0), (0, -0.07, 0.5))
    return root


STAGE3_PROP_BUILDERS = [
    prop_cart_medication, prop_bed_hospital, prop_trolley_linen, prop_cart_crash, prop_cabinet_aed,
    prop_cylinder_oxygen, prop_monitor_vitals, prop_bin_sharps, prop_dispenser_handgel, prop_wheelchair,
]


# --------------------------------------------------------------------------
# Stage 4: security and administration wing
# (origin: floor centre unless noted; front faces -Y)
# --------------------------------------------------------------------------

def _screens(coll, root, aid, boxes, mat="M_Emissive_Screen", hint=None):
    """One UV'd mesh holding every screen face, so Godot can swap textures."""
    smb = MeshBuilder()
    for size, centre in boxes:
        smb.box(size, centre, mat)
    screen = smb.build(aid + "_Screens", coll, root)
    L.planar_uv(screen, ("x", "z"))
    if hint:
        screen["godot_hint"] = hint
    return screen


def prop_console_security(coll, aid="PROP_Console_SecurityDesk", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Operator console 2.4 m: three monitors, radio base and push-to-talk mic.
    The operator sits on the -Y side."""
    root = _root(coll, aid, "security", loc, rot, "Security operator console with three monitors")
    mb = MeshBuilder()
    w, d, h = 2.4, 0.9, 0.75
    mb.box((w, d, 0.04), (0, 0, h - 0.02), "M_Plastic_Black")
    mb.box((w, 0.04, h - 0.04), (0, d / 2 - 0.02, (h - 0.04) / 2), "M_Metal_Dark")
    for x in (-w / 2 + 0.02, w / 2 - 0.02, -0.4, 0.4):
        mb.box((0.04, d - 0.04, h - 0.04), (x, 0, (h - 0.04) / 2), "M_Metal_Dark")
    mb.box((w, 0.3, 0.12), (0, d / 2 - 0.15, h + 0.06), "M_Metal_Dark")                   # Equipment riser.
    screens = []
    for i, x in enumerate((-0.75, 0.0, 0.75)):
        yaw = (0.25, 0.0, -0.25)[i]
        with mb.at((x, d / 2 - 0.2, h + 0.12), (0, 0, yaw)):
            mb.box((0.62, 0.04, 0.38), (0, 0, 0.29), "M_Plastic_Black")
            mb.box((0.06, 0.06, 0.12), (0, 0.03, 0.06), "M_Plastic_Black")
        screens.append((x, yaw))
    for x in (-0.75, 0.0, 0.75):
        mb.box((0.44, 0.14, 0.015), (x, -0.15, h + 0.008), "M_Plastic_Black")             # Keyboards.
    mb.box((0.2, 0.16, 0.08), (-1.0, -0.05, h + 0.04), "M_Plastic_Black")                 # Radio base.
    mb.cyl(0.006, 0.25, (-1.05, 0.0, h + 0.2), "M_Steel_Brushed", segs=6)                 # Mic gooseneck.
    mb.box((0.12, 0.08, 0.03), (1.0, -0.2, h + 0.015), "M_Safety_Red")                    # Alarm acknowledge.
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    smb = MeshBuilder()
    for x, yaw in screens:
        with smb.at((x, d / 2 - 0.2, h + 0.12), (0, 0, yaw)):
            smb.box((0.58, 0.004, 0.34), (0, -0.022, 0.29), "M_Emissive_Screen")
    screen = smb.build(aid + "_Screens", coll, root)
    L.planar_uv(screen, ("x", "z"))
    screen["godot_hint"] = "Camera feeds / access log: ViewportTexture per monitor."
    L.collision_box(aid + "_COL", coll, root, (w, d, h + 0.2), (0, 0, (h + 0.2) / 2))
    return root


def prop_videowall(coll, aid="PROP_VideoWall_3x2", loc=(0, 0, 0), rot=(0, 0, 0)):
    """3 x 2 wall of 55" displays; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "security", loc, rot, "Surveillance video wall, 3 x 2 displays")
    mb = MeshBuilder()
    pw, ph = 1.22, 0.69
    mb.box((3 * pw + 0.08, 0.06, 2 * ph + 0.08), (0, -0.03, 0), "M_Metal_Dark")
    boxes = []
    for c in range(3):
        for r in range(2):
            cx, cz = (c - 1) * pw, (r - 0.5) * ph
            mb.box((pw - 0.01, 0.05, ph - 0.01), (cx, -0.085, cz), "M_Plastic_Black")
            boxes.append(((pw - 0.04, 0.004, ph - 0.04), (cx, -0.112, cz)))
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    _screens(coll, root, aid, boxes, "M_Emissive_VideoWall", "Six camera feeds; UVs span the whole wall.")
    return root


def prop_cabinet_keys(coll, aid="PROP_Cabinet_Keys_Wall", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Electronic key cabinet; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "security", loc, rot, "Electronic key-control cabinet with keypad")
    mb = MeshBuilder()
    mb.box((0.6, 0.14, 0.8), (0, -0.07, 0), "M_Steel_Painted_Grey")
    mb.box((0.56, 0.01, 0.76), (0, -0.145, 0), "M_Steel_Painted_Grey")
    mb.box((0.12, 0.012, 0.16), (0.18, -0.152, 0.15), "M_Plastic_Black")                  # Keypad.
    mb.box((0.03, 0.03, 0.1), (-0.24, -0.16, 0), "M_Steel_Brushed")
    led = MeshBuilder()
    led.box((0.01, 0.004, 0.01), (0.18, -0.16, 0.26), "M_Emissive_LED_Red")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    led.build(aid + "_LED", coll, root)["godot_hint"] = "Red = locked; swap to green when authorised."
    return root


def prop_lockers(coll, aid="PROP_Lockers_Staff_4", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Staff locker bank, 4 full-height doors")
    mb = MeshBuilder()
    w, d, h = 1.2, 0.5, 1.85
    mb.box((w, d, h), (0, 0, h / 2 + 0.1), "M_Steel_Painted_Grey")
    mb.box((w, d - 0.05, 0.1), (0, 0.02, 0.05), "M_Plastic_Black")                        # Plinth.
    for i in range(4):
        x = -w / 2 + w / 8 + i * w / 4
        mb.box((w / 4 - 0.012, 0.01, h - 0.02), (x, -d / 2 - 0.005, h / 2 + 0.1), "M_Steel_Painted_White")
        for z in (h - 0.05, h - 0.09, h - 0.13):
            mb.box((0.12, 0.004, 0.012), (x, -d / 2 - 0.011, z), "M_Plastic_Black")      # Vents.
        mb.box((0.03, 0.02, 0.06), (x + 0.1, -d / 2 - 0.02, 1.05), "M_Steel_Brushed")     # Lock.
        mb.box((0.1, 0.002, 0.03), (x, -d / 2 - 0.011, h - 0.25), "M_Paper")              # Name card.
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    L.collision_box(aid + "_COL", coll, root, (w, d, h + 0.1), (0, 0, (h + 0.1) / 2))
    return root


def prop_detector_walkthrough(coll, aid="PROP_Detector_WalkThrough", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Walk-through metal detector arch; walk direction is local Y."""
    root = _root(coll, aid, "security", loc, rot, "Walk-through metal detector")
    mb = MeshBuilder()
    inner, depth, h = 0.8, 0.6, 2.2
    for side in (-1, 1):
        mb.box((0.12, depth, h), (side * (inner / 2 + 0.06), 0, h / 2), "M_Plastic_OffWhite")
        mb.box((0.14, depth + 0.1, 0.04), (side * (inner / 2 + 0.06), 0, 0.02), "M_Plastic_Black")
    mb.box((inner + 0.24, depth, 0.18), (0, 0, h + 0.09), "M_Plastic_OffWhite")
    mb.box((0.3, 0.02, 0.1), (0, -depth / 2 - 0.01, h + 0.09), "M_Plastic_Black")         # Display.
    for z in (0.4, 0.8, 1.2, 1.6, 2.0):
        mb.box((0.02, 0.01, 0.06), (-(inner / 2 + 0.121), -depth / 2 + 0.06, z), "M_Plastic_Black")
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    led = MeshBuilder()
    led.box((0.04, 0.004, 0.02), (0.08, -depth / 2 - 0.022, h + 0.09), "M_Emissive_LED_Green")
    led.build(aid + "_LED", coll, root)["godot_hint"] = "Swap to M_Emissive_LED_Red on an alarm."
    for side in (-1, 1):
        L.collision_box("%s_COL_%s" % (aid, "L" if side < 0 else "R"), coll, root, (0.12, depth, h),
                        (side * (inner / 2 + 0.06), 0, h / 2))
    return root


def prop_table_conference(coll, aid="PROP_Table_Conference_3m", loc=(0, 0, 0), rot=(0, 0, 0)):
    root = _root(coll, aid, "furniture", loc, rot, "Conference table 3.0 x 1.2 m with cable box")
    mb = MeshBuilder()
    mb.box((3.0, 1.2, 0.04), (0, 0, 0.72), "M_Wood_Executive")
    for x in (-0.95, 0.95):
        mb.box((0.12, 0.7, 0.66), (x, 0, 0.37), "M_Metal_Dark")
        mb.box((0.5, 0.9, 0.03), (x, 0, 0.015), "M_Metal_Dark")
    mb.box((0.3, 0.12, 0.012), (0, 0, 0.746), "M_Metal_Dark")                             # Cable box lid.
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    L.collision_box(aid + "_COL", coll, root, (3.0, 1.2, 0.74), (0, 0, 0.37))
    return root


def prop_seating_waiting(coll, aid="PROP_Seating_Waiting_3", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Floor-fixed beam seating, three seats. Seats face -Y."""
    root = _root(coll, aid, "furniture", loc, rot, "Floor-fixed beam seating, 3 seats")
    mb = MeshBuilder()
    mb.box((1.75, 0.06, 0.06), (0, 0.05, 0.38), "M_Steel_Brushed")                       # Beam.
    for x in (-0.7, 0.7):
        mb.box((0.06, 0.06, 0.38), (x, 0.05, 0.19), "M_Steel_Brushed")
        mb.box((0.06, 0.5, 0.02), (x, 0.05, 0.01), "M_Steel_Brushed")
    for i in range(3):
        x = (i - 1) * 0.58
        mb.box((0.52, 0.46, 0.05), (x, -0.02, 0.44), "M_Upholstery_Teal")
        mb.box((0.52, 0.05, 0.42), (x, 0.24, 0.7), "M_Upholstery_Teal", rot=(-0.12, 0, 0))
    for x in (-0.87, -0.29, 0.29, 0.87):
        mb.box((0.04, 0.4, 0.03), (x, 0.0, 0.62), "M_Plastic_Black")                      # Armrests.
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    L.collision_box(aid + "_COL", coll, root, (1.8, 0.6, 0.9), (0, 0.04, 0.45))
    return root


def prop_desk_executive(coll, aid="PROP_Desk_Executive", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Medical director's desk. The occupant sits on the +Y side."""
    root = _root(coll, aid, "furniture", loc, rot, "Executive desk, wood, with modesty panel")
    mb = MeshBuilder()
    w, d, h = 1.8, 0.9, 0.76
    mb.box((w, d, 0.045), (0, 0, h - 0.0225), "M_Wood_Executive")
    for x in (-w / 2 + 0.25, w / 2 - 0.25):
        mb.box((0.45, d - 0.06, h - 0.045), (x, 0, (h - 0.045) / 2), "M_Wood_Executive")
        for z in (0.55, 0.3):
            mb.box((0.12, 0.02, 0.012), (x, d / 2 - 0.02, z), "M_Steel_Brushed")
    mb.box((w - 0.95, 0.03, 0.45), (0, -d / 2 + 0.02, 0.45), "M_Wood_Executive")          # Modesty panel.
    mb.box((0.5, 0.35, 0.004), (0.1, 0.1, h + 0.002), "M_Upholstery_Leather_Black")       # Desk pad.
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_printer_badge(coll, aid="PROP_Printer_Badge", loc=(0, 0, 0), rot=(0, 0, 0)):
    """ID card printer; origin on the desk surface."""
    root = _root(coll, aid, "security", loc, rot, "ID badge printer")
    mb = MeshBuilder()
    mb.box((0.22, 0.38, 0.22), (0, 0, 0.11), "M_Plastic_OffWhite")
    mb.box((0.1, 0.06, 0.02), (0, -0.2, 0.06), "M_Plastic_Black")                         # Output tray.
    mb.box((0.06, 0.004, 0.03), (0.05, -0.192, 0.18), "M_Plastic_Black")
    mb.build(aid + "_Mesh", coll, root, bevel=0.01)
    return root


def prop_door_elevator(coll, aid="PROP_Door_Elevator", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Elevator landing doors in a wall opening 1.1 x 2.1 m. Origin at the
    opening centre, floor level, wall plane; the landing side is -Y.
    Leaves are separate nodes so Godot can slide them along local X."""
    root = _root(coll, aid, "door", loc, rot, "Elevator landing doors with call panel and key switch")
    root["opening_width_m"] = 1.1
    w, h = 1.1, 2.1
    mb = MeshBuilder()
    for side in (-1, 1):
        mb.box((0.08, WALL_T + 0.04, h + 0.08), (side * (w / 2 + 0.04), 0, (h + 0.08) / 2), "M_Steel_Brushed")
    mb.box((w + 0.16, WALL_T + 0.04, 0.08), (0, 0, h + 0.04), "M_Steel_Brushed")
    mb.box((w, 0.3, 0.02), (0, 0, 0.01), "M_Steel_Brushed")                               # Sill.
    mb.box((w + 0.2, WALL_T + 0.04, 0.6), (0, 0, h + 0.38), "M_Metal_Dark")                # Hoistway header.
    mb.box((0.1, 0.02, 0.24), (w / 2 + 0.25, -(WALL_T / 2 + 0.01), 1.1), "M_Steel_Brushed")  # Call panel.
    mb.cyl(0.018, 0.01, (w / 2 + 0.25, -(WALL_T / 2 + 0.025), 1.14), "M_Plastic_Black", axis="Y", segs=12)
    mb.box((0.03, 0.01, 0.03), (w / 2 + 0.25, -(WALL_T / 2 + 0.025), 1.04), "M_Steel_Painted_Grey")  # Key switch.
    mb.box((0.3, 0.01, 0.08), (0, -(WALL_T / 2 + 0.025), h + 0.2), "M_Plastic_Black")     # Floor indicator.
    mb.build(aid + "_Frame", coll, root, bevel=0.002)
    for side, sign in (("L", -1), ("R", 1)):
        lmb = MeshBuilder()
        lmb.box((w / 2, 0.03, h), (sign * w / 4, 0, h / 2), "M_Steel_Brushed")
        leaf = lmb.build("%s_Leaf_%s" % (aid, side), coll, root, loc=(0, -0.05, 0))
        leaf["godot_hint"] = "Slide along local X by %.2f m to open." % (sign * w / 2)
        L.collision_box("%s_Leaf_%s_COL" % (aid, side), coll, leaf, (w / 2, 0.03, h), (sign * w / 4, 0, h / 2))
    return root


def prop_panel_electrical(coll, aid="PROP_Panel_Electrical", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Distribution board; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "fixture", loc, rot, "Electrical distribution board (maintenance only)")
    mb = MeshBuilder()
    mb.box((0.8, 0.2, 1.2), (0, -0.1, 0), "M_Steel_Painted_Grey")
    mb.box((0.38, 0.01, 1.16), (-0.2, -0.205, 0), "M_Steel_Painted_Grey")
    mb.box((0.38, 0.01, 1.16), (0.2, -0.205, 0), "M_Steel_Painted_Grey")
    for x in (-0.03, 0.03):
        mb.box((0.02, 0.03, 0.12), (x, -0.22, 0), "M_Steel_Brushed")
    mb.box((0.1, 0.004, 0.09), (0.2, -0.212, 0.4), "M_Plastic_Sharps_Yellow")            # Warning label.
    mb.cyl(0.03, 0.6, (0.2, -0.1, 0.9), "M_Metal_Dark", segs=10)                          # Conduit up.
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


def prop_pipes_wall(coll, aid="PROP_Pipes_Wall_2m", loc=(0, 0, 0), rot=(0, 0, 0)):
    """2 m bundle of service pipes; origin at left end on the wall, faces -Y."""
    root = _root(coll, aid, "fixture", loc, rot, "Wall-run service pipes, 2 m")
    mb = MeshBuilder()
    for i, (r, z, mat) in enumerate(((0.05, 0.0, "M_Steel_Painted_Grey"), (0.035, 0.14, "M_Paint_Historic_Green"),
                                     (0.025, 0.25, "M_Steel_Brushed"))):
        mb.cyl(r, 2.0, (1.0, -0.08 - r, z), mat, axis="X", segs=12)
    for x in (0.3, 1.0, 1.7):
        mb.box((0.04, 0.16, 0.36), (x, -0.08, 0.12), "M_Metal_Dark")                       # Brackets.
    mb.build(aid + "_Mesh", coll, root)
    return root


def prop_display_wall(coll, aid="PROP_Display_Wall_65", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Meeting-room display; origin at wall surface centre, faces -Y."""
    root = _root(coll, aid, "decor", loc, rot, "Wall-mounted 65-inch meeting display")
    mb = MeshBuilder()
    mb.box((1.46, 0.05, 0.84), (0, -0.045, 0), "M_Plastic_Black")
    mb.box((0.3, 0.02, 0.3), (0, -0.01, 0), "M_Metal_Dark")
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    _screens(coll, root, aid, [((1.42, 0.004, 0.8), (0, -0.072, 0))], hint="Presentation / video call surface.")
    return root


STAGE4_SECURITY_PROP_BUILDERS = [
    prop_console_security, prop_videowall, prop_cabinet_keys, prop_lockers, prop_detector_walkthrough,
    prop_table_conference, prop_seating_waiting, prop_desk_executive, prop_printer_badge, prop_door_elevator,
    prop_panel_electrical, prop_pipes_wall, prop_display_wall,
]


# --------------------------------------------------------------------------
# Stage 4b: research wing
# (origin: floor centre unless noted; front faces -Y)
# --------------------------------------------------------------------------

def prop_counter_reception(coll, aid="PROP_Counter_Reception", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Reception counter 2.4 m with a raised transaction ledge; staff side +Y."""
    root = _root(coll, aid, "furniture", loc, rot, "Research reception counter")
    mb = MeshBuilder()
    w, d, h = 2.4, 0.7, 0.75
    mb.box((w, d, 0.03), (0, 0, h - 0.015), "M_Laminate_LabWhite")
    mb.box((w, 0.04, 1.1), (0, -d / 2 + 0.02, 0.55), "M_Laminate_LabWhite")              # Front modesty panel.
    mb.box((w + 0.04, 0.3, 0.03), (0, -d / 2 + 0.1, 1.115), "M_Wood_Laminate_Desk")      # Transaction ledge.
    mb.box((w, 0.006, 0.12), (0, -d / 2 - 0.003, 0.85), "M_Accent_ResearchTeal")         # Accent band.
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        mb.box((0.04, d - 0.04, h - 0.03), (x, 0.0, (h - 0.03) / 2), "M_Laminate_LabWhite")
    mb.box((0.3, 0.22, 0.01), (-0.5, 0.05, h + 0.005), "M_Paper")                        # Visitor sign-in book.
    mb.box((0.006, 0.12, 0.006), (-0.32, 0.05, h + 0.012), "M_Plastic_Black")            # Pen.
    mb.build(aid + "_Mesh", coll, root, bevel=0.003)
    L.collision_box(aid + "_COL", coll, root, (w, d, 1.13), (0, 0, 0.565))
    return root


def prop_chair_assessment(coll, aid="PROP_Chair_Assessment_Recliner", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Padded reclining assessment chair on a pedestal base; the occupant faces -Y."""
    root = _root(coll, aid, "furniture", loc, rot, "Reclining research assessment chair")
    mb = MeshBuilder()
    mb.box((0.6, 0.6, 0.06), (0, 0, 0.03), "M_Steel_Painted_White")                       # Base plate.
    mb.cyl(0.07, 0.35, (0, 0, 0.235), "M_Steel_Brushed", segs=12)                         # Pedestal.
    mb.box((0.62, 0.62, 0.12), (0, 0, 0.47), "M_Upholstery_Vinyl_Grey")                   # Seat.
    mb.box((0.62, 0.14, 0.72), (0, 0.36, 0.86), "M_Upholstery_Vinyl_Grey", rot=(-0.35, 0, 0))   # Reclined back.
    mb.box((0.32, 0.14, 0.18), (0, 0.55, 1.28), "M_Upholstery_Vinyl_Grey", rot=(-0.35, 0, 0))   # Headrest.
    mb.box((0.6, 0.42, 0.08), (0, -0.48, 0.38), "M_Upholstery_Vinyl_Grey", rot=(0.5, 0, 0))     # Leg rest.
    for side in (-1, 1):
        mb.box((0.1, 0.56, 0.06), (side * 0.36, 0.0, 0.66), "M_Upholstery_Vinyl_Grey")    # Armrests.
        mb.box((0.04, 0.04, 0.16), (side * 0.36, 0.16, 0.56), "M_Steel_Brushed")
    mb.build(aid + "_Mesh", coll, root, bevel=0.01)
    L.collision_box(aid + "_COL", coll, root, (0.8, 1.2, 1.0), (0, 0.0, 0.5))
    return root


def prop_bench_lab(coll, aid="PROP_Bench_Lab_2m", loc=(0, 0, 0), rot=(0, 0, 0)):
    """2 m laboratory bench, resin top, reagent shelf at the back (+Y)."""
    root = _root(coll, aid, "furniture", loc, rot, "Laboratory bench with reagent shelf")
    mb = MeshBuilder()
    w, d, h = 2.0, 0.75, 0.9
    mb.box((w, d, 0.03), (0, 0, h - 0.015), "M_Resin_LabTop")
    for x in (-w / 2 + 0.3, w / 2 - 0.3):
        mb.box((0.58, d - 0.05, h - 0.03), (x, 0.02, (h - 0.03) / 2), "M_Laminate_LabWhite")   # Cupboards.
        mb.box((0.012, 0.004, 0.12), (x + 0.24, -d / 2 + 0.005, h - 0.15), "M_Steel_Brushed")
    for x in (-w / 2 + 0.02, w / 2 - 0.02):
        mb.box((0.03, 0.03, 0.6), (x, d / 2 - 0.05, h + 0.3), "M_Steel_Painted_White")
    mb.box((w, 0.25, 0.02), (0, d / 2 - 0.13, h + 0.45), "M_Laminate_LabWhite")          # Reagent shelf.
    for i, x in enumerate((-0.8, -0.65, -0.5, 0.1, 0.22, 0.6, 0.75)):
        mat = ("M_Plastic_OffWhite", "M_Glass_Clear", "M_Plastic_MedCart_Blue")[i % 3]
        mb.cyl(0.035, 0.14, (x, d / 2 - 0.13, h + 0.53), mat, segs=10)                    # Bottles.
    mb.box((0.36, 0.26, 0.03), (0.55, -0.05, h + 0.015), "M_Plastic_OffWhite")           # Tube rack.
    for i in range(6):
        mb.cyl(0.007, 0.1, (0.4 + i * 0.06, -0.05, h + 0.08), "M_Plastic_OffWhite", segs=6)
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_centrifuge(coll, aid="PROP_Centrifuge_Benchtop", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Benchtop centrifuge; origin on the bench surface."""
    root = _root(coll, aid, "equipment", loc, rot, "Benchtop sample centrifuge")
    mb = MeshBuilder()
    mb.box((0.42, 0.5, 0.26), (0, 0, 0.13), "M_Plastic_OffWhite")
    mb.cyl(0.17, 0.02, (0, 0.03, 0.27), "M_Steel_Painted_Grey", segs=20)                  # Lid.
    mb.box((0.3, 0.06, 0.01), (0, -0.22, 0.2), "M_Plastic_Black", rot=(0.6, 0, 0))        # Control panel.
    mb.build(aid + "_Mesh", coll, root, bevel=0.01)
    led = MeshBuilder()
    led.box((0.08, 0.004, 0.02), (-0.06, -0.255, 0.21), "M_Emissive_LED_Green", rot=(0.6, 0, 0))
    led.build(aid + "_Display", coll, root)["godot_hint"] = "Run display; animate the lid for the sample beat."
    return root


def prop_freezer_upright(coll, aid="PROP_Freezer_Upright_ULT", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Upright ultra-low sample freezer with keypad lock and temperature display."""
    root = _root(coll, aid, "equipment", loc, rot, "Upright ultra-low sample freezer")
    mb = MeshBuilder()
    w, d, h = 0.85, 0.85, 1.95
    mb.box((w, d, h), (0, 0, h / 2 + 0.05), "M_Steel_Painted_White")
    mb.box((w - 0.04, 0.03, h - 0.3), (0, -d / 2 - 0.015, h / 2 - 0.05), "M_Steel_Painted_White")   # Door.
    mb.box((0.04, 0.05, 0.5), (w / 2 - 0.1, -d / 2 - 0.05, 1.1), "M_Steel_Brushed")       # Handle.
    mb.box((w, d, 0.05), (0, 0, 0.025), "M_Plastic_Black")                                # Plinth.
    mb.box((w - 0.04, 0.02, 0.18), (0, -d / 2 - 0.01, h - 0.05), "M_Plastic_OffWhite")   # Control head.
    mb.box((0.08, 0.012, 0.1), (0.25, -d / 2 - 0.022, h - 0.05), "M_Plastic_Black")       # Keypad.
    mb.box((0.18, 0.002, 0.1), (-0.1, -d / 2 - 0.031, 1.4), "M_Paper")                    # Contents label.
    mb.build(aid + "_Mesh", coll, root, bevel=0.004)
    led = MeshBuilder()
    led.box((0.16, 0.004, 0.05), (-0.15, -d / 2 - 0.022, h - 0.05), "M_Emissive_LED_Green")
    led.build(aid + "_Display", coll, root)["godot_hint"] = "Temperature readout; red on an alarm."
    L.collision_box(aid + "_COL", coll, root, (w, d + 0.06, h + 0.05), (0, -0.03, (h + 0.05) / 2))
    return root


def prop_desk_workstation(coll, aid="PROP_Desk_Workstation_Dual", loc=(0, 0, 0), rot=(0, 0, 0)):
    """Analyst desk 1.6 m with two monitors; the user sits on the -Y side."""
    root = _root(coll, aid, "furniture", loc, rot, "Data analysis workstation with dual monitors")
    mb = MeshBuilder()
    w, d, h = 1.6, 0.75, 0.74
    mb.box((w, d, 0.03), (0, 0, h - 0.015), "M_Laminate_LabWhite")
    for x in (-w / 2 + 0.03, w / 2 - 0.03):
        mb.box((0.05, d - 0.1, h - 0.03), (x, 0, (h - 0.03) / 2), "M_Steel_Painted_Grey")
    mb.box((w - 0.1, 0.02, 0.35), (0, d / 2 - 0.05, h - 0.2), "M_Steel_Painted_Grey")     # Modesty panel.
    for x, yaw in ((-0.32, 0.15), (0.32, -0.15)):
        with mb.at((x, d / 2 - 0.22, h), (0, 0, yaw)):
            mb.box((0.56, 0.035, 0.34), (0, 0, 0.33), "M_Plastic_Black")
            mb.box((0.05, 0.05, 0.16), (0, 0.03, 0.08), "M_Plastic_Black")
    mb.box((0.44, 0.14, 0.015), (0, -0.12, h + 0.008), "M_Plastic_Black")                 # Keyboard.
    mb.box((0.2, 0.42, 0.42), (0.6, 0.1, 0.21), "M_Plastic_Black")                        # Tower under desk.
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    smb = MeshBuilder()
    for x, yaw in ((-0.32, 0.15), (0.32, -0.15)):
        with smb.at((x, d / 2 - 0.22, h), (0, 0, yaw)):
            smb.box((0.52, 0.004, 0.3), (0, -0.019, 0.33), "M_Emissive_Screen")
    screen = smb.build(aid + "_Screens", coll, root)
    L.planar_uv(screen, ("x", "z"))
    screen["godot_hint"] = "Dataset / analysis output: ViewportTexture per monitor."
    L.collision_box(aid + "_COL", coll, root, (w, d, h), (0, 0, h / 2))
    return root


def prop_rack_server(coll, aid="PROP_Rack_Server_42U", loc=(0, 0, 0), rot=(0, 0, 0)):
    """42U server rack with a perforated door; front -Y."""
    root = _root(coll, aid, "equipment", loc, rot, "Server rack, 42U, locked")
    mb = MeshBuilder()
    w, d, h = 0.6, 1.0, 2.0
    mb.box((w, d, h), (0, 0, h / 2), "M_Metal_Dark")
    mb.box((w - 0.04, 0.02, h - 0.1), (0, -d / 2 - 0.01, h / 2), "M_Plastic_Black")
    for i in range(18):
        mb.box((w - 0.12, 0.004, 0.012), (0, -d / 2 - 0.022, 0.2 + i * 0.09), "M_Metal_Dark")   # Perforation bands.
    mb.box((0.03, 0.03, 0.2), (w / 2 - 0.06, -d / 2 - 0.035, 1.1), "M_Steel_Brushed")
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    led = MeshBuilder()
    for i in range(10):
        led.box((0.012, 0.004, 0.008), (-0.18 + (i % 2) * 0.03, -d / 2 - 0.026, 0.45 + i * 0.13),
                "M_Emissive_LED_Green" if i % 4 else "M_Emissive_LED_Red")
    led.build(aid + "_LEDs", coll, root)["godot_hint"] = "Blink the LEDs; drive disk activity from story beats."
    L.collision_box(aid + "_COL", coll, root, (w, d + 0.04, h), (0, -0.02, h / 2))
    return root


def prop_whiteboard(coll, aid="PROP_Whiteboard_Wall", loc=(0, 0, 0), rot=(0, 0, 0), residue=True):
    """1.8 m whiteboard with marker tray; origin at wall surface centre, faces -Y.
    The faint residue strokes read as something recently wiped off."""
    root = _root(coll, aid, "decor", loc, rot, "Wall whiteboard (recently wiped)")
    mb = MeshBuilder()
    mb.box((1.8, 0.02, 1.2), (0, -0.01, 0), "M_Steel_Brushed")
    mb.box((1.76, 0.004, 1.16), (0, -0.022, 0), "M_Whiteboard")
    mb.box((0.8, 0.06, 0.02), (0, -0.05, -0.61), "M_Steel_Brushed")                       # Marker tray.
    for i, mat in enumerate(("M_Plastic_Black", "M_Signage_Blue", "M_Safety_Red")):
        mb.cyl(0.008, 0.12, (-0.2 + i * 0.15, -0.05, -0.59), mat, axis="X", segs=6)
    if residue:
        for x, z, w, a in ((-0.5, 0.3, 0.6, 0.05), (-0.45, 0.18, 0.5, -0.04), (0.2, 0.25, 0.7, 0.0),
                           (0.25, -0.05, 0.3, 0.3), (-0.3, -0.2, 0.8, 0.02), (0.5, -0.3, 0.25, -0.2)):
            mb.box((w, 0.001, 0.012), (x, -0.0245, z), "M_Marker_Residue", rot=(0, a, 0))
    mb.build(aid + "_Mesh", coll, root, bevel=0.002)
    return root


STAGE4_RESEARCH_PROP_BUILDERS = [
    prop_counter_reception, prop_chair_assessment, prop_bench_lab, prop_centrifuge, prop_freezer_upright,
    prop_desk_workstation, prop_rack_server, prop_whiteboard,
]
