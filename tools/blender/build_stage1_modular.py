"""Stage 1: modular architecture kit + doors.

Run (repo root):
    <blender-python> tools/blender/build_stage1_modular.py
    # or: blender --background --python tools/blender/build_stage1_modular.py

Outputs:
    assets/blender/modular/FW_Modular_Kit.blend
    assets/exports/modular/<ASSET_ID>.glb   (one per module / door)
    assets/renders/stage1/modular_kit_overview.png, doors_closeup.png
    assets/asset_manifest/asset_manifest.json (+ .md)
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))

import bpy  # noqa: E402

import fw_assets as A  # noqa: E402
import fw_lib as L  # noqa: E402
from fw_lib import DOOR_H, WALL_H, WALL_T, MeshBuilder  # noqa: E402

BLEND = os.path.join(REPO, "assets/blender/modular/FW_Modular_Kit.blend")
EXPORT_DIR = os.path.join(REPO, "assets/exports/modular")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage1")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = "v1 geometry complete; untextured PBR (Stage 8: textures/UVs)"


def module_root(coll, asset_id, loc, display_name):
    return L.empty(asset_id, coll, loc=loc, display="ARROWS", size=0.3,
                   props={"category": "modular_architecture", "display_name": display_name})


def wall_collision(coll, root, asset_id, length, door_ranges, origin=(0, 0)):
    """Collision boxes for the solid parts of a wall (door gaps stay open)."""
    cursor, i = 0.0, 0
    for a, b in sorted(door_ranges) + [(length, length)]:
        if a - cursor > 1e-3:
            L.collision_box("%s_COL%d" % (asset_id, i), coll, root, (a - cursor, WALL_T, WALL_H),
                            (origin[0] + (cursor + a) / 2, origin[1], WALL_H / 2))
            i += 1
        cursor = b


def build_walls(coll, records, x0):
    specs = [
        ("MOD_Wall_2m_Plain", 2.0, [], False, "Plain wall 2 m"),
        ("MOD_Wall_1m_Plain", 1.0, [], False, "Plain wall 1 m"),
        ("MOD_Wall_0p5m_Plain", 0.5, [], False, "Plain wall 0.5 m"),
        ("MOD_Wall_2m_CorridorProtected", 2.0, [], True, "Corridor wall 2 m with PVC dado protection (front)"),
        ("MOD_Wall_2m_Door1000", 2.0, [A.door_opening(1.0, 1.0)], False, "Wall 2 m, 1000 door opening"),
        ("MOD_Wall_2m_Door1200", 2.0, [A.door_opening(1.0, 1.2)], True, "Corridor wall 2 m, 1200 secure-door opening"),
        ("MOD_Wall_2m_Door1800", 2.0, [A.door_opening(1.0, 1.8)], True, "Corridor wall 2 m, 1800 double-door opening"),
        ("MOD_Wall_2m_ObservationWindow", 2.0,
         [A.window_opening(1.0, 1.2, 1.0, 2.0, "M_Mirror_OneWay_Room", "M_Glass_OneWay_Observer")], True,
         "Observation window: one-way glass (front = observer side)"),
        ("MOD_Wall_2m_ExteriorWindow", 2.0, [A.window_opening(1.0, 1.6, 0.9, 2.3, "M_Glass_Clear")], False,
         "Exterior window 1600 x 1400 with venetian blind"),
    ]
    for i, (aid, length, openings, protected, name) in enumerate(specs):
        loc = (x0 + i * 3.0, 0, 0)
        root = module_root(coll, aid, loc, name)
        mb = MeshBuilder()
        _solid, doors = A.add_wall(mb, length, openings=openings, protected_front=protected)
        mb.build(aid + "_Mesh", coll, root)
        wall_collision(coll, root, aid, length, doors)
        if aid == "MOD_Wall_2m_ExteriorWindow":
            blinds = MeshBuilder()
            blinds.box((1.5, 0.05, 0.05), (1.0, -0.06, 2.22), "M_Steel_Painted_White")
            z = 2.17
            while z > 0.95:
                blinds.box((1.48, 0.028, 0.002), (1.0, -0.06, z), "M_Steel_Painted_White", rot=(0.5, 0, 0))
                z -= 0.03
            ob = blinds.build(aid + "_Blinds", coll, root)
            ob["godot_hint"] = "Separate node: hide or scale Z to raise the blind."
        records.append((root, "modular", "Any wall run on the 2 m module grid",
                        "Box colliders on solid sections; door gaps open" if doors else "Box collider",
                        "Origin at left end, floor level; front face -Y. Rotate in 90-degree steps."))


def build_post_floor_ceiling(coll, records, x0):
    root = module_root(coll, "MOD_Wall_CornerPost", (x0, 0, 0), "0.2 x 0.2 corner post (fills wall junctions)")
    mb = MeshBuilder()
    A.corner_post(mb, 0, 0)
    mb.build("MOD_Wall_CornerPost_Mesh", coll, root)
    L.collision_box("MOD_Wall_CornerPost_COL", coll, root, (WALL_T, WALL_T, WALL_H), (0, 0, WALL_H / 2))
    records.append((root, "modular", "Every wall junction/end on the grid", "Box collider",
                    "Origin at the grid intersection."))

    root = module_root(coll, "MOD_Floor_2x2_Vinyl", (x0 + 2, 0, 0), "Floor slab 2 x 2 m, sheet vinyl")
    mb = MeshBuilder()
    A.add_floor(mb, 0, 2, 0, 2)
    mb.build("MOD_Floor_2x2_Vinyl_Mesh", coll, root)
    L.collision_box("MOD_Floor_2x2_Vinyl_COL", coll, root, (2, 2, 0.1), (1, 1, -0.05))
    records.append((root, "modular", "Room/corridor floors", "Box collider",
                    "Origin at the -X/-Y corner; top surface at z = 0. Swap material per room."))

    for aid, lights, vents, name in (
            ("MOD_Ceiling_2x2_Tile", [], [], "Suspended ceiling 2 x 2 m, 500 grid"),
            ("MOD_Ceiling_2x2_LightPanel", [(1.0, 1.0, 0.5, 1.0)], [], "Ceiling 2 x 2 m with LED panel"),
            ("MOD_Ceiling_2x2_ReturnGrille", [], [(1.0, 1.0, 0.5, 0.25)], "Ceiling 2 x 2 m with return-air grille")):
        root = module_root(coll, aid, (x0 + (4 if not lights and not vents else 6 if lights else 8), 0, 0), name)
        mb = MeshBuilder()
        A.add_ceiling(mb, 0, 2, 0, 2, lights=lights, vents=vents)
        mb.build(aid + "_Mesh", coll, root)
        if lights:
            L.empty("LIGHTMARK_" + aid, coll, root, (1.0, 1.0, WALL_H - 0.1), display="SPHERE", size=0.08,
                    props={"marker_type": "light", "light_kind": "omni", "energy_hint": 1.0,
                           "color": "#FFF4E5", "range_m": 6.0})
        records.append((root, "modular", "Ceilings at 3.0 m", "None (out of reach)",
                        "Origin at the -X/-Y corner at floor level; ceiling underside at z = 3.0."
                        + (" LIGHTMARK empty marks where Godot should place a light." if lights else "")))


def build_corridors(coll, records, x0):
    specs = [
        ("MOD_Corridor_Straight_2m", dict(light=False), "Corridor slice 2 m (2.8 m clear)"),
        ("MOD_Corridor_Straight_2m_Light", dict(light=True), "Corridor slice 2 m with ceiling light"),
        ("MOD_Corridor_Straight_2m_DoorEast1200", dict(light=False, east=A.door_opening(1.0, 1.2)),
         "Corridor slice 2 m, 1200 opening east"),
        ("MOD_Corridor_Straight_2m_DoorWest1000", dict(light=False, west=A.door_opening(1.0, 1.0)),
         "Corridor slice 2 m, 1000 opening west"),
    ]
    for i, (aid, kwargs, name) in enumerate(specs):
        root = module_root(coll, aid, (x0 + i * 4.0, 0, 0), name)
        mb = MeshBuilder()
        A.corridor_slice(mb, 2.0, **kwargs)
        mb.build(aid + "_Mesh", coll, root)
        L.collision_box(aid + "_COL_Floor", coll, root, (3.2, 2.0, 0.1), (0, 1.0, -0.05))
        for side, key in ((-1, "west"), (1, "east")):
            op = kwargs.get(key)
            gaps = [(op["x"] - op["w"] / 2, op["x"] + op["w"] / 2)] if op else []
            cursor, j = 0.0, 0
            for a, b in gaps + [(2.0, 2.0)]:
                if a - cursor > 1e-3:
                    L.collision_box("%s_COL_%s%d" % (aid, key, j), coll, root, (WALL_T, a - cursor, WALL_H),
                                    (side * A.CORRIDOR_HALF, (cursor + a) / 2, WALL_H / 2))
                    j += 1
                cursor = b
        if kwargs.get("light"):
            L.empty("LIGHTMARK_" + aid, coll, root, (0, 1.0, WALL_H - 0.1), display="SPHERE", size=0.08,
                    props={"marker_type": "light", "light_kind": "omni", "energy_hint": 1.0,
                           "color": "#FFF4E5", "range_m": 6.0})
        records.append((root, "modular", "Clinical corridors", "Floor + wall box colliders",
                        "Origin on the centreline at the slice start (y = 0); runs +Y for 2 m. "
                        "Walls at x = +/-1.5 (2.8 m clear). Chain end to end; rotate 180 degrees to mirror."))

    for j, (aid, open_sides, name) in enumerate((
            ("MOD_Corridor_Corner_L", {"south", "east"}, "Corridor corner (south -> east)"),
            ("MOD_Corridor_T_Junction", {"south", "east", "west"}, "Corridor T-junction"),
            ("MOD_Corridor_Crossing", {"south", "east", "west", "north"}, "Corridor crossing"))):
        root = module_root(coll, aid, (x0 + 16 + j * 5.0, 0, 0), name)
        mb = MeshBuilder()
        A.corridor_node(mb, open_sides)
        mb.build(aid + "_Mesh", coll, root)
        L.collision_box(aid + "_COL_Floor", coll, root, (3.2, 3.2, 0.1), (0, 1.5, -0.05))
        walls = {"west": ((WALL_T, 3.2, WALL_H), (-1.5, 1.5)), "east": ((WALL_T, 3.2, WALL_H), (1.5, 1.5)),
                 "north": ((3.2, WALL_T, WALL_H), (0, 3.0)), "south": ((3.2, WALL_T, WALL_H), (0, 0.0))}
        for side, (size, (cx, cy)) in walls.items():
            if side not in open_sides:
                L.collision_box("%s_COL_%s" % (aid, side), coll, root, size, (cx, cy, WALL_H / 2))
        for k, (px, py) in enumerate(((-1.5, 0), (1.5, 0), (-1.5, 3), (1.5, 3))):
            L.collision_box("%s_COL_Post%d" % (aid, k), coll, root, (WALL_T, WALL_T, WALL_H), (px, py, WALL_H / 2))
        records.append((root, "modular", "Corridor junctions", "Floor, wall and post box colliders",
                        "3 x 3 m square from y = 0 to 3 on the centreline; connects to 2 m slices on open sides."))


def build_doors(coll, records, x0):
    for i, (aid, kind) in enumerate((("DOOR_Secure_Single_1200", "secure_single"),
                                     ("DOOR_Secure_Double_1800", "secure_double"),
                                     ("DOOR_Interior_Single_1000", "interior"),
                                     ("DOOR_Service_Historic_1200", "service_historic"))):
        root = A.build_door(coll, aid, kind, loc=(x0 + i * 3.0, 0, 0))
        records.append((root, "door", "Matching MOD_Wall_2m_Door* opening",
                        "Leaf box collider(s) parented to each leaf (-colonly); frame relies on wall colliders",
                        "Origin at opening centre, floor level, wall plane y = 0. Leaf node origin is the hinge: "
                        "rotate it about Godot Y to open. Push side is -Y (front)."))


def main():
    L.reset_scene()
    scene = bpy.context.scene
    kit = L.collection("FW_Modular_Kit")
    walls = L.collection("Walls", kit)
    misc = L.collection("Floors_Ceilings_Posts", kit)
    corr = L.collection("Corridors", kit)
    doors = L.collection("Doors", kit)
    records = []
    build_walls(walls, records, 0.0)
    build_post_floor_ceiling(misc, records, 0.0)
    for ob in misc.objects:
        if ob.parent is None:
            ob.location.y += 5.0
    build_corridors(corr, records, 0.0)
    for ob in corr.objects:
        if ob.parent is None:
            ob.location.y += 9.0
    build_doors(doors, records, 0.0)
    for ob in doors.objects:
        if ob.parent is None:
            ob.location.y -= 5.0

    # ---- Validation ---------------------------------------------------------
    roots = [r for r, *_ in records]
    names = [r.name for r in roots]
    assert len(names) == len(set(names)), "duplicate asset ids"
    for root in roots:
        meshes = [o for o in L.descendants(root) if o.type == "MESH" and not o.name.endswith("-colonly")]
        assert meshes, "%s has no visual mesh" % root.name
        lo, hi = L.world_bounds(root)
        size = hi - lo
        assert 0.01 < max(size) < 40.0, "%s has implausible size %s" % (root.name, tuple(size))
        for o in L.descendants(root):
            assert all(abs(s - 1.0) < 1e-6 for s in o.scale), "%s has unapplied scale" % o.name

    # ---- Save, export, manifest ---------------------------------------------
    L.save_blend(BLEND)
    manifest = []
    for root, category, location, collision, notes in records:
        path = os.path.join(EXPORT_DIR, root.name + ".glb")
        L.export_glb(root, path)
        manifest.append(L.asset_record(root, BLEND, path, location, collision, notes, STATUS, REPO))
    L.write_manifest(manifest, MANIFEST)

    # ---- Preview renders ----------------------------------------------------
    L.setup_render(scene, 1600, 900, samples=32)
    sun = bpy.data.lights.new("PreviewSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PreviewSun", sun)
    scene.collection.objects.link(sun_ob)
    sun_ob.rotation_euler = (math.radians(50), math.radians(10), math.radians(30))
    ground = MeshBuilder()
    ground.box((80, 50, 0.02), (14, 3, -0.12), "M_Steel_Painted_Grey")
    ground.build("PreviewGround", scene.collection)
    cam = L.camera_marker("PreviewCam", scene.collection, None, (14, -22, 16), (14, 4, 0), 28)
    L.render_from(scene, cam, os.path.join(RENDER_DIR, "modular_kit_overview.png"))
    cam2 = L.camera_marker("PreviewCamDoors", scene.collection, None, (3.0, -10.5, 1.8), (3.0, -5, 1.1), 35)
    L.render_from(scene, cam2, os.path.join(RENDER_DIR, "doors_closeup.png"))
    print("STAGE1 OK: %d assets exported" % len(manifest))


if __name__ == "__main__":
    main()
