"""Stage 5: historic asylum substructure (the sublevel), plus its props library.

The sublevel is the mid-century hospital the modern building was put on top
of. It is reached two ways, both already set up in Stage 4a: the locked floor
hatch in maintenance access (MA_ServiceHatch at x 4.5, y 38.6) and the
restricted lift, whose shaft (x 0, y 44) also serves the sublevels. Like the
research level it is its own level, authored at floor z = 0 with the same x/y
as the Chapter 1 shared frame, so the service stair tops out under the hatch
and the old lift doors stand under the modern ones (both asserted).

Layout (wall centrelines, metres):

    y      west side (x -6 .. -1.5)        corridor (x +/-1.5)          east side (x 1.5 .. 6)
    40-44                                  disused lift landing (N)
    34-40  Abandoned nursing station       historic corridor            Historic stairwell (hatch)  36-40
    31-34  Former patient room 1                                        Old medication storage      32-36
    28-31  Former patient room 2                                        Historical treatment room   26-32
    24-28  Disused administrative office                                Closed observation rooms    20-26
    20-24  Paper medical records archive                                (two cells)
    17-20  ------------------ mechanical and maintenance corridor (x -6 .. 6) ------------------
    10-17                                  sealed connecting corridor   Historic records vault      12-17
    10     bricked-up end (towards Ward Zero, Stage 6)

Visual identity: green-over-beige paint, terrazzo and checker tile, glazed
wall tile in the treatment room, iron and enamel fixtures, knife-switch
electrics, caged tungsten lamps at uneven brightness (several flagged to
flicker), damp stains, flaking paint and a little debris. Decay is subtle:
the place was closed, not wrecked.

Wall ownership: the corridor owns its side walls and the lift-landing north
wall; each room owns its south wall (and the last in a row its north wall);
the mechanical corridor owns its south wall and both end walls; the sealed
corridor owns its side walls and the bricked-up end; the vault owns its east
and south walls.

Outputs:
    assets/blender/historic/FW_Props_Historic.blend, assets/exports/historic/props/*.glb
    assets/blender/historic/FW_HistoricSubstructure.blend, assets/exports/historic/env/ENV_*.glb
    assets/renders/stage5/*.png (skipped with --fast)
    assets/asset_manifest/asset_manifest.json (merged)
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import build_stage2_chapter1 as S2  # noqa: E402
import build_stage4_security_admin as S4  # noqa: E402
import fw_assets as A  # noqa: E402
import fw_lib as L  # noqa: E402
from fw_lib import WALL_H, MeshBuilder  # noqa: E402

PROPS_BLEND = os.path.join(REPO, "assets/blender/historic/FW_Props_Historic.blend")
WING_BLEND = os.path.join(REPO, "assets/blender/historic/FW_HistoricSubstructure.blend")
PROPS_DIR = os.path.join(REPO, "assets/exports/historic/props")
ENV_DIR = os.path.join(REPO, "assets/exports/historic/env")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage5")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = S4.STATUS
FAST = "--fast" in sys.argv
D90 = math.pi / 2
TUNGSTEN = "#FFC98A"
FRAME = ("Sublevel frame: same x/y as the Chapter 1 shared frame, floor at z = 0; load as its own level "
         "(the maintenance hatch and the restricted lift connect it)")
GREEN, BEIGE = "M_Paint_Historic_Green_Aged", "M_Paint_Historic_Beige_Aged"
TERRAZZO, CHECKER = "M_Tile_Floor_Terrazzo", "M_Tile_Floor_Checker_Dark"
SOIL = "M_Concrete_Stained"          # Back face of outer walls (against earth).
HATCH = (4.5, 38.6)
LIFT = (0.0, 44.0)

place, door, set_props = S2.place, S2.door, S2.set_props
wall_with_collision = S2.wall_with_collision

PROP_WALL_MOUNTED = {"PROP_Panel_Fuse_Historic"}
PROP_CEILING = {"PROP_Light_Bulkhead_Historic"}
PROP_LOCATIONS = {
    "PROP_Bed_Iron_Historic": "Former patient rooms, closed observation rooms",
    "PROP_Cabinet_Instrument_Glass": "Historical treatment room, abandoned nursing station",
    "PROP_Tub_Hydrotherapy": "Historical treatment room",
    "PROP_Table_Exam_Historic": "Historical treatment room",
    "PROP_Desk_Steel_Tanker": "Disused administrative office, abandoned nursing station",
    "PROP_Chair_Wood_Historic": "Throughout the substructure",
    "PROP_Cabinet_Card_Index": "Paper records archive, historic records vault",
    "PROP_Shelf_Medication_Historic": "Old medication storage",
    "PROP_Panel_Fuse_Historic": "Mechanical and maintenance corridor",
    "PROP_Light_Bulkhead_Historic": "Throughout the substructure",
    "PROP_Door_Vault_Records": "Historic records vault",
    "PROP_Stair_Service_Historic": "Historic stairwell (to the maintenance hatch)",
    "PROP_Radiator_Cast_Iron": "Throughout the substructure",
}


def env_root(coll, asset_id, name):
    root = S2.env_root(coll, asset_id, name)
    root["frame"] = FRAME
    return root


def tag(ob, hint, **extra):
    """Environmental-storytelling hook: what the player sees, never a clinical fact."""
    return set_props(ob, dict({"godot_hint": hint, "story_tag": "historic_record"}, **extra))


# --------------------------------------------------------------------------
# Props library
# --------------------------------------------------------------------------

def build_props():
    L.reset_scene()
    scene = bpy.context.scene
    coll = L.collection("FW_Props_Historic")
    records = []
    for i, builder in enumerate(A.STAGE5_HISTORIC_PROP_BUILDERS):
        root = builder(coll, loc=((i % 5) * 3.2, (i // 5) * 3.4, 0))
        has_col = any(o.name.endswith("-colonly") for o in L.descendants(root))
        origin = ("wall surface" if root.name in PROP_WALL_MOUNTED else "ceiling" if root.name in PROP_CEILING
                  else "wall plane, opening centre" if root.name == "PROP_Door_Vault_Records"
                  else "foot of the stair" if root.name == "PROP_Stair_Service_Historic" else "floor centre")
        records.append((root, PROP_LOCATIONS[root.name],
                        "Box collider (-colonly)" if has_col else "Decorative: no collision",
                        "Historic sublevel (mid-century, disused). Origin: %s." % origin))
    for root, *_ in records:
        lo, hi = L.world_bounds(root)
        assert max(hi - lo) < 4.5, "%s too large" % root.name      # The service stair is 4.1 m tall with rails.
        assert any(o.type == "MESH" for o in L.descendants(root)), root.name
    L.save_blend(PROPS_BLEND)
    manifest = []
    for root, location, collision, notes in records:
        path = os.path.join(PROPS_DIR, root.name + ".glb")
        L.export_glb(root, path)
        manifest.append(L.asset_record(root, PROPS_BLEND, path, location, collision, notes, STATUS, REPO))
    L.write_manifest(manifest, MANIFEST)
    if not FAST:
        for root, *_ in records:
            if root.name in PROP_WALL_MOUNTED:
                root.location.z += 1.5
            elif root.name in PROP_CEILING:
                root.location.z += 1.2
        L.setup_render(scene, 1600, 900, samples=24)
        sun = bpy.data.lights.new("PreviewSun", "SUN")
        sun.energy = 3.0
        sun_ob = bpy.data.objects.new("PreviewSun", sun)
        scene.collection.objects.link(sun_ob)
        sun_ob.rotation_euler = (math.radians(45), 0, math.radians(-25))
        ground = MeshBuilder()
        ground.box((34, 18, 0.02), (6.4, 3.4, -0.01), TERRAZZO)
        ground.build("PreviewGround", scene.collection)
        cam = L.camera_marker("PreviewCam", scene.collection, None, (6.4, -10.5, 7.0), (6.4, 3.6, 0.8), 24)
        L.render_from(scene, cam, os.path.join(RENDER_DIR, "props_historic.png"))
    return len(manifest)


# --------------------------------------------------------------------------
# Shared helpers
# --------------------------------------------------------------------------

def shell(coll, root, x0, x1, y0, y1, paint, floor, walls, posts=(), floor_extend=None):
    """Room shell with a solid plaster ceiling; lighting comes from lamp() calls."""
    S2.room_shell(coll, root, x0, x1, y0, y1, paint, floor, walls, solid_ceiling=True,
                  floor_extend=floor_extend or (x0, x1, y0, y1))
    if posts:
        pm = MeshBuilder()
        for x, y in posts:
            A.corner_post(pm, x, y, paint)
        pm.build(root.name + "_Posts", coll, root)


def lamp(coll, root, name, x, y, watts=35.0, flicker=False, dead=False):
    """Caged bulkhead plus its light marker. Uneven by design: pass different watts;
    `dead` lamps get no light at all."""
    ob = place(A.prop_light_bulkhead_historic, coll, root, name, (x, y, WALL_H), 0)
    if dead:
        set_props(ob, {"lamp_state": "dead"})
        return ob
    mark = S2.lightmark(coll, root, "LIGHTMARK_%s" % name, (x, y, WALL_H - 0.3), range_m=5.0, watts=watts,
                        size=(0.2, 0.2), color=TUNGSTEN)
    if flicker:
        set_props(mark, {"flicker": True})
        set_props(ob, {"lamp_state": "flicker"})
    return ob


def decay(coll, root, name, items):
    """Damp stains and flaking paint as thin overlay boxes.
    items: (kind, centre, size) with kind 'stain' or 'flake'."""
    mb = MeshBuilder()
    for kind, centre, size in items:
        mb.box(size, centre, "M_Stain_Damp" if kind == "stain" else "M_Paint_Flaking")
    return mb.build(root.name + "_" + name, coll, root)


def debris(coll, root, name, spots):
    """A few fallen paper sheets and plaster flakes on the floor."""
    mb = MeshBuilder()
    for i, (x, y) in enumerate(spots):
        if i % 2:
            mb.box((0.21, 0.3, 0.002), (x, y, 0.002), "M_Paper", rot=(0, 0, 0.4 * i))
        else:
            mb.box((0.12, 0.08, 0.02), (x, y, 0.01), "M_Paint_Flaking", rot=(0, 0, 0.7 * i))
    return mb.build(root.name + "_" + name, coll, root)


def corridor_sign(coll, root, name, loc, rot, hint=None):
    ob = place(A.prop_sign_room, coll, root, name, loc, rot)
    return tag(ob, hint) if hint else ob


# --------------------------------------------------------------------------
# Corridors
# --------------------------------------------------------------------------

WEST_DOORS = (("Archive", 22.0, 1.0), ("AdminOffice", 26.0, 1.0), ("PatientRoom2", 29.5, 1.0),
              ("PatientRoom1", 32.5, 1.0), ("NursingStation", 37.0, 1.0))
EAST_DOORS = (("ObservationA", 21.5, 1.0), ("ObservationB", 24.5, 1.0), ("Treatment", 29.0, 1.2),
              ("MedStorage", 34.0, 1.0), ("Stairwell", 38.0, 1.0))


def build_historic_corridor(coll):
    root = env_root(coll, "ENV_HistoricCorridor_24m", "Historic ward corridor, 24 m, with disused lift landing")
    west = [A.door_opening(y - 20.0, w) for _, y, w in WEST_DOORS]
    west.append(A.window_opening(39.0 - 20.0, 1.4, 1.0, 1.9, glass="M_Glass_Grimy"))          # Nursing hatch.
    east = [A.door_opening(44.0 - y, w) for _, y, w in EAST_DOORS]
    shell(coll, root, -1.5, 1.5, 20.0, 44.0, GREEN, TERRAZZO,
          {"west": dict(openings=west, back_mat=BEIGE), "east": dict(openings=east, back_mat=BEIGE),
           "north": dict(back_mat=SOIL, openings=[A.door_opening(1.5, 1.1, 2.1)])},
          posts=((-1.5, 44.0), (1.5, 44.0)), floor_extend=(-1.6, 1.6, 20.0, 44.1))
    for name, y, _ in WEST_DOORS:
        door(coll, root, "Door_" + name, "service_historic", (-1.5, y, 0), D90, "door_h_" + name.lower(),
             "access_historic" if name in ("Archive", "AdminOffice") else "")
        corridor_sign(coll, root, "Sign_" + name, (-1.394, y + 0.85, 1.7), 90)
    for name, y, w in EAST_DOORS:
        door(coll, root, "Door_" + name, "service_historic", (1.5, y, 0), -D90, "door_h_" + name.lower(),
             "access_historic" if name == "MedStorage" else "")
        corridor_sign(coll, root, "Sign_" + name, (1.394, y - 0.85, 1.7), -90)
    lift = MeshBuilder()                                                                     # Collapsible gate.
    for i in range(12):
        lift.box((0.012, 0.02, 2.1), (-0.55 + i * 0.1, 43.86, 1.05), "M_Metal_Rust")
    for z in (0.1, 1.05, 2.0):
        lift.box((1.12, 0.02, 0.03), (0.0, 43.85, z), "M_Metal_Rust")
    lift.box((1.3, 0.06, 0.3), (0.0, 43.86, 2.3), "M_Iron_Cast_Painted")                     # Floor indicator.
    lift.box((0.5, 0.01, 0.08), (0.0, 43.825, 2.3), "M_Paint_Historic_Cream")
    gate = lift.build("LiftLanding_Gate", coll, root)
    tag(gate, "Disused lift landing; the modern restricted lift still stops here on its key switch.",
        door_id="door_historic_lift", required_access="access_restricted_lift")
    L.collision_box("LiftLanding_Gate_COL", coll, root, (1.12, 0.04, 2.1), (0.0, 43.86, 1.05))
    for i, (y, w, fl, dead) in enumerate(((21.0, 30, False, False), (24.5, 22, True, False), (28.0, 35, False, False),
                                          (31.5, 0, False, True), (35.0, 30, False, False), (38.5, 18, True, False),
                                          (42.0, 26, False, False))):
        lamp(coll, root, "Corridor_Lamp_%d" % i, 0.0, y, w, flicker=fl, dead=dead)
    for i, y in enumerate((23.0, 30.5, 36.0)):
        place(A.prop_radiator_cast, coll, root, "Corridor_Radiator_%d" % i, (1.29, y, 0), -90)
    decay(coll, root, "Decay", (
        ("stain", (-1.393, 27.0, 2.6), (0.004, 1.4, 0.6)), ("stain", (1.393, 33.2, 0.4), (0.004, 0.9, 0.5)),
        ("flake", (-1.392, 30.8, 1.9), (0.004, 0.3, 0.2)), ("flake", (1.392, 26.6, 1.3), (0.004, 0.25, 0.35)),
        ("stain", (0.3, 31.6, 0.003), (1.1, 1.6, 0.004)), ("stain", (0.0, 31.5, WALL_H - 0.004), (1.4, 1.8, 0.004))))
    debris(coll, root, "Debris", ((0.4, 31.2), (-0.6, 27.5), (0.8, 35.6), (-0.3, 41.0)))
    tag(place(A.prop_noticeboard, coll, root, "Corridor_NoticeBoard_Rota", (-1.394, 41.0, 1.5), 90),
        "Last duty rota pinned here; the final week is filled in and then nothing.")
    place(A.prop_chair_wood_historic, coll, root, "Corridor_Chair", (-1.1, 42.6, 0), 90)
    L.empty("MARK_Waypoint_LiftLanding", coll, root, (0.0, 43.2, 0.0), (0, 0, math.pi), display="SINGLE_ARROW",
            size=0.5, props={"marker_type": "waypoint", "faces": "south, into the corridor"})
    L.camera_marker("CAM_HC_Corridor", coll, root, (0.0, 43.4, 1.65), (0.0, 20.0, 1.2), 22)
    L.camera_marker("CAM_HC_FromSouth", coll, root, (0.6, 20.6, 1.6), (-0.2, 40.0, 1.4), 24)
    return root


def build_mechanical_corridor(coll):
    root = env_root(coll, "ENV_MechanicalCorridor", "Mechanical and maintenance corridor")
    south = [A.door_opening(6.0 - 3.75, 1.2), A.door_opening(6.0, 3.0)]                     # Vault, sealed corridor.
    shell(coll, root, -6.0, 6.0, 17.0, 20.0, SOIL, "M_Concrete_Stained",
          {"south": dict(openings=south, back_mat=SOIL), "west": dict(back_mat=SOIL), "east": dict(back_mat=SOIL)},
          posts=((-6.0, 17.0), (6.0, 17.0), (-6.0, 20.0), (6.0, 20.0), (-1.5, 17.0), (1.5, 17.0), (1.5, 20.0),
                 (-1.5, 20.0)), floor_extend=(-6.1, 6.1, 16.9, 20.0))
    for i, x in enumerate((-5.6, -3.6, -1.6, 0.4, 2.4)):
        place(A.prop_pipes_wall, coll, root, "MC_Pipes_%d" % i, (x, 19.894, 2.5), 0)
    place(A.prop_panel_fuse_historic, coll, root, "MC_FuseBoard", (-4.0, 17.106, 1.45), 180)
    tag(place(A.prop_panel_fuse_historic, coll, root, "MC_FuseBoard_Isolated", (-5.894, 18.5, 1.45), 90),
        "One circuit is still live, labelled only with a ward number that is not on any modern plan.")
    mb = MeshBuilder()                                                                       # Ducting and valves.
    mb.box((11.6, 0.5, 0.4), (0.0, 18.0, 2.65), "M_Steel_Painted_Grey")
    for x in (-4.5, -1.0, 2.5, 5.0):
        mb.box((0.04, 0.6, 0.35), (x, 18.0, 2.65), "M_Metal_Rust")
    for x in (-2.8, 3.0):
        mb.cyl(0.12, 0.04, (x, 19.75, 1.2), "M_Safety_Red", axis="Y", segs=14)               # Valve wheels.
        mb.cyl(0.04, 0.3, (x, 19.88, 1.2), "M_Metal_Rust", axis="Y", segs=8)
    mb.build(root.name + "_Services", coll, root)
    for i, (x, w, fl) in enumerate(((-4.5, 25, False), (-1.0, 0, False), (2.5, 20, True), (5.2, 15, False))):
        lamp(coll, root, "MC_Lamp_%d" % i, x, 18.5, w, flicker=fl, dead=(w == 0))
    decay(coll, root, "Decay", (("stain", (-5.894 + 0.001, 18.6, 0.6), (0.004, 1.2, 1.0)),
                               ("stain", (1.0, 18.4, 0.003), (2.2, 1.0, 0.004))))
    place(A.prop_bin, coll, root, "MC_Bucket", (5.4, 19.4, 0), 0)
    L.camera_marker("CAM_MC_Establishing", coll, root, (-5.6, 19.6, 1.8), (4.0, 17.8, 1.0), 20)
    return root


def build_sealed_corridor(coll):
    root = env_root(coll, "ENV_SealedConnectingCorridor", "Sealed connecting corridor (towards Ward Zero)")
    end = [A.door_opening(1.5, 1.6, 2.4)]
    shell(coll, root, -1.5, 1.5, 10.0, 17.0, GREEN, CHECKER,
          {"west": dict(back_mat=SOIL), "east": dict(back_mat=SOIL),
           "south": dict(back_mat=SOIL, openings=end)},
          posts=((-1.5, 10.0), (1.5, 10.0)), floor_extend=(-1.6, 1.6, 9.9, 17.0))
    brick = MeshBuilder()                                                                    # Bricked-up opening.
    for row in range(32):
        z = 0.0375 + row * 0.075
        off = 0.11 if row % 2 else 0.0
        x = -0.8 + off
        while x < 0.8 - 1e-3:
            bw = min(0.215, 0.8 - x)
            brick.box((bw - 0.01, 0.1, 0.065), (x + bw / 2, 10.0, z), "M_Brick_Old")
            x += 0.22
        if off:
            brick.box((0.1, 0.1, 0.065), (-0.75, 10.0, z), "M_Brick_Old")
    brick.box((1.6, 0.11, 0.01), (0.0, 10.0, 2.4), "M_Concrete_Stained")
    tag(brick.build("SC_BrickInfill", coll, root),
        "Newer brick than the walls around it; a stencilled W0 is half-covered by mortar.",
        state_group="sealed_corridor_end", state="sealed", default_visible=True)
    L.collision_box("SC_BrickInfill_COL", coll, root, (1.6, 0.12, 2.4), (0.0, 10.0, 1.2))
    sten = MeshBuilder()
    sten.box((0.34, 0.004, 0.2), (0.35, 10.058, 1.6), "M_Plastic_Black")
    sten.build("SC_Stencil_W0", coll, root)
    tape = MeshBuilder()
    for i, z in enumerate((0.9, 1.25)):
        tape.box((2.6, 0.004, 0.06), (0.0, 10.12 + i * 0.002, z), "M_Plastic_Sharps_Yellow", rot=(0, 0.15 * (-1) ** i, 0))
    tape.build("SC_HazardTape", coll, root)
    lamp(coll, root, "SC_Lamp_0", 0.0, 15.5, 16)
    lamp(coll, root, "SC_Lamp_1", 0.0, 12.0, 8, flicker=True)
    decay(coll, root, "Decay", (("stain", (-1.393, 12.5, 1.4), (0.004, 2.0, 1.6)),
                               ("flake", (1.392, 13.6, 1.8), (0.004, 0.5, 0.4)),
                               ("stain", (0.0, 11.2, 0.003), (2.4, 1.6, 0.004))))
    debris(coll, root, "Debris", ((0.5, 10.6), (-0.7, 11.4), (0.2, 12.8)))
    L.camera_marker("CAM_SC_Corridor", coll, root, (0.4, 16.6, 1.6), (0.0, 10.0, 1.2), 26)
    return root


# --------------------------------------------------------------------------
# West rooms
# --------------------------------------------------------------------------

def west_shell(coll, asset_id, name, y0, y1, paint=BEIGE, floor=TERRAZZO, owns_north=False):
    root = env_root(coll, asset_id, name)
    walls = {"south": dict(back_mat=BEIGE), "west": dict(back_mat=SOIL)}
    if owns_north:
        walls["north"] = dict(back_mat=SOIL)
    posts = [(-6.0, y0)] + ([(-6.0, y1)] if owns_north else [])
    shell(coll, root, -6.0, -1.5, y0, y1, paint, floor, walls, posts=posts,
          floor_extend=(-6.1, -1.6, y0, y1 + (0.1 if owns_north else 0.0)))
    return root


def build_records_archive(coll):
    root = west_shell(coll, "ENV_PaperRecordsArchive", "Paper medical records archive", 20.0, 24.0)
    for i, y in enumerate((20.6, 22.0)):
        place(A.prop_shelving_archive, coll, root, "PA_Shelving_%d" % i, (-4.3, y, 0), 180 if i == 0 else 0)
    place(A.prop_cabinet_card_index, coll, root, "PA_CardIndex", (-5.6, 23.3, 0), 90)
    place(A.prop_desk_steel, coll, root, "PA_Desk", (-2.6, 23.4, 0), 0)
    place(A.prop_chair_wood_historic, coll, root, "PA_Chair", (-2.6, 22.75, 0), 180)
    tag(place(A.prop_folder_chart, coll, root, "PA_Document_AdmissionLedger", (-2.4, 23.4, 0.76), 15),
        "Admission ledger; several pages cut out cleanly near the spine.", clinical_review_status="PENDING")
    lamp(coll, root, "PA_Lamp", -3.75, 22.0, 22, flicker=True)
    decay(coll, root, "Decay", (("stain", (-5.893, 21.2, 2.4), (0.004, 1.2, 0.8)),))
    debris(coll, root, "Debris", ((-3.3, 21.3), (-4.9, 23.0), (-3.0, 22.4)))
    L.camera_marker("CAM_PA_Establishing", coll, root, (-1.95, 20.4, 2.3), (-4.8, 22.8, 0.9), 18)
    return root


def build_admin_office(coll):
    root = west_shell(coll, "ENV_DisusedAdminOffice", "Disused administrative office", 24.0, 28.0,
                      floor="M_Wood_Aged")
    place(A.prop_desk_steel, coll, root, "AO_Desk", (-4.3, 26.0, 0), -90)
    place(A.prop_chair_wood_historic, coll, root, "AO_Chair", (-5.1, 26.0, 0), 90)
    place(A.prop_chair_wood_historic, coll, root, "AO_Chair_Visitor", (-3.4, 26.3, 0), -110)
    place(A.prop_filing_cabinet, coll, root, "AO_FilingCabinet", (-5.5, 27.55, 0), 0)
    place(A.prop_bookcase, coll, root, "AO_Bookcase", (-3.4, 24.28, 0), 180)
    place(A.prop_radiator_cast, coll, root, "AO_Radiator", (-5.79, 24.9, 0), 90)
    place(A.prop_clock_caged, coll, root, "AO_Clock_Stopped", (-3.75, 27.894, 2.3), 0)
    tag(place(A.prop_certificate, coll, root, "AO_Frame_StaffPhoto", (-5.894, 26.8, 1.6), 90),
        "Staff photograph; one face scratched out of the glass.")
    tag(place(A.prop_folder_chart, coll, root, "AO_Document_ClosureMemo", (-4.15, 26.3, 0.76), -80),
        "Closure memorandum: the date is typed, the reason line is left blank.")
    lamp(coll, root, "AO_Lamp", -3.75, 26.0, 28)
    decay(coll, root, "Decay", (("flake", (-5.893, 25.0, 2.2), (0.004, 0.6, 0.4)),
                               ("stain", (-3.75, 26.0, WALL_H - 0.004), (1.2, 1.0, 0.004))))
    L.camera_marker("CAM_AO_Establishing", coll, root, (-1.95, 27.6, 2.3), (-4.9, 25.6, 0.9), 18)
    return root


def build_patient_room(coll, n, y0):
    root = west_shell(coll, "ENV_FormerPatientRoom%d" % n, "Former patient room %d" % n, y0, y0 + 3.0,
                      floor=CHECKER, owns_north=False)
    place(A.prop_bed_iron, coll, root, "PR%d_Bed" % n, (-4.9, y0 + 1.5, 0), 90)
    place(A.prop_chair_wood_historic, coll, root, "PR%d_Chair" % n, (-3.2, y0 + 2.5, 0), 200)
    place(A.prop_radiator_cast, coll, root, "PR%d_Radiator" % n, (-3.6, y0 + 0.21, 0), 180)
    lamp(coll, root, "PR%d_Lamp" % n, -3.75, y0 + 1.5, 20 if n == 1 else 0, dead=(n == 2))
    if n == 1:
        scratches = MeshBuilder()
        for i in range(9):
            scratches.box((0.004, 0.012, 0.18), (-5.893, y0 + 2.45 + (i // 3) * 0.06, 0.8 + (i % 3) * 0.05),
                          "M_Paint_Flaking")
        tag(scratches.build("PR1_TallyMarks", coll, root), "Tally marks scratched low on the wall beside the bed.")
    else:
        tag(debris(coll, root, "PR2_Debris", ((-4.0, y0 + 1.2), (-3.0, y0 + 1.9), (-4.6, y0 + 2.6))),
            "Room 2 was cleared in a hurry: the mattress is gone and the bed is pulled from the wall.")
    decay(coll, root, "Decay", (("stain", (-5.893, y0 + 0.8, 2.5), (0.004, 0.9, 0.7)),))
    L.camera_marker("CAM_PR%d_Establishing" % n, coll, root, (-1.95, y0 + 0.4 if n == 1 else y0 + 2.6, 2.3),
                    (-5.0, y0 + 1.5, 0.6), 18)
    return root


def build_nursing_station(coll):
    root = west_shell(coll, "ENV_AbandonedNursingStation", "Abandoned nursing station", 34.0, 40.0,
                      owns_north=True)
    counter = MeshBuilder()
    counter.box((0.6, 1.6, 1.0), (-1.95, 39.0, 0.5), "M_Wood_Aged")                         # Counter under hatch.
    counter.box((0.7, 1.7, 0.04), (-1.95, 39.0, 1.02), "M_Wood_Aged")
    counter.build("NS_Counter", coll, root)
    L.collision_box("NS_Counter_COL", coll, root, (0.6, 1.6, 1.04), (-1.95, 39.0, 0.52))
    place(A.prop_desk_steel, coll, root, "NS_Desk", (-3.2, 38.4, 0), 0)
    place(A.prop_chair_wood_historic, coll, root, "NS_Chair", (-3.2, 37.7, 0), 180)
    place(A.prop_cabinet_instrument, coll, root, "NS_InstrumentCabinet", (-5.65, 38.6, 0), 90)
    place(A.prop_cabinet_card_index, coll, root, "NS_CardIndex_Patients", (-5.6, 36.0, 0), 90)
    place(A.prop_radiator_cast, coll, root, "NS_Radiator", (-4.0, 34.21, 0), 180)
    place(A.prop_clock_caged, coll, root, "NS_Clock_Stopped", (-4.6, 39.894, 2.3), 0)
    tag(place(A.prop_noticeboard, coll, root, "NS_Board_Census", (-3.4, 39.894, 1.6), 0),
        "Patient census board; names chalked out, one bed number still circled.")
    tag(place(A.prop_folder_chart, coll, root, "NS_Document_NightReport", (-3.0, 38.5, 0.76), 10),
        "Night report book, open on its last page; the final entry stops mid-sentence.",
        clinical_review_status="PENDING")
    place(A.prop_phone, coll, root, "NS_Phone_Bakelite", (-3.6, 38.55, 0.76), 0)
    lamp(coll, root, "NS_Lamp_0", -3.75, 38.4, 26, flicker=True)
    lamp(coll, root, "NS_Lamp_1", -3.75, 35.4, 0, dead=True)
    decay(coll, root, "Decay", (("stain", (-5.893, 35.0, 2.3), (0.004, 1.6, 1.1)),
                               ("flake", (-2.8, 34.107, 1.8), (0.4, 0.004, 0.3)),
                               ("stain", (-4.0, 35.6, 0.003), (1.4, 1.2, 0.004))))
    debris(coll, root, "Debris", ((-4.4, 35.2), (-2.6, 36.1), (-4.9, 37.3), (-3.6, 36.6)))
    L.camera_marker("CAM_NS_Establishing", coll, root, (-1.95, 34.5, 2.3), (-4.6, 38.6, 0.9), 18)
    L.camera_marker("CAM_NS_ThroughHatch", coll, root, (-0.6, 39.0, 1.6), (-4.8, 38.6, 1.1), 26,
                    props={"shot": "from the corridor through the nursing hatch"})
    return root


# --------------------------------------------------------------------------
# East rooms
# --------------------------------------------------------------------------

def east_shell(coll, asset_id, name, y0, y1, paint=BEIGE, floor=TERRAZZO, owns_north=False, south_kwargs=None):
    root = env_root(coll, asset_id, name)
    walls = {"south": dict(back_mat=BEIGE, **(south_kwargs or {})), "east": dict(back_mat=SOIL)}
    if owns_north:
        walls["north"] = dict(back_mat=SOIL)
    posts = [(6.0, y0)] + ([(6.0, y1)] if owns_north else [])
    shell(coll, root, 1.5, 6.0, y0, y1, paint, floor, walls, posts=posts,
          floor_extend=(1.6, 6.1, y0, y1 + (0.1 if owns_north else 0.0)))
    return root


def build_observation(coll):
    root = east_shell(coll, "ENV_ClosedObservationRooms", "Closed observation rooms (two cells)", 20.0, 26.0,
                      paint="M_Paint_Historic_Green_Aged")
    mb = MeshBuilder()
    wall_with_collision(mb, coll, root, (1.5, 23.0), (6.0, 23.0), "CellDivider", front_mat=GREEN, back_mat=GREEN)
    A.corner_post(mb, 6.0, 23.0, GREEN)
    mb.build(root.name + "_CellDivider", coll, root)
    for cell, y0 in (("A", 20.0), ("B", 23.0)):
        place(A.prop_bed_iron, coll, root, "OB%s_Bed" % cell, (4.9, y0 + 1.5, 0), -90)
        lamp(coll, root, "OB%s_Lamp" % cell, 3.75, y0 + 1.5, 14 if cell == "A" else 0, dead=(cell == "B"))
        hatch = MeshBuilder()
        hatch.box((0.004, 0.3, 0.2), (1.607, y0 + 1.5 + (0.0 if cell == "A" else 0.0), 1.55), "M_Iron_Cast_Painted")
        hatch.build("OB%s_WallHatch" % cell, coll, root)
    tag(place(A.prop_folder_chart, coll, root, "OBB_Document_ObservationCard", (5.2, 24.9, 0.55), 30),
        "Observation card on the bed of the dark cell, dated after the ward's closure memo.")
    pad = MeshBuilder()
    for i in range(6):
        pad.box((0.004, 0.5, 0.9), (5.893, 23.6 + i * 0.4, 1.4), "M_Canvas_Aged")             # Padded wall, cell B.
    tag(pad.build("OBB_PaddedWall", coll, root), "Canvas wall padding, torn at seam height.")
    decay(coll, root, "Decay", (("stain", (5.893, 21.0, 2.5), (0.004, 1.0, 0.8)),
                               ("stain", (3.6, 24.4, 0.003), (1.6, 1.2, 0.004))))
    L.camera_marker("CAM_OB_Establishing", coll, root, (1.95, 22.6, 2.3), (5.2, 20.9, 0.6), 18)     # Lit cell A.
    L.camera_marker("CAM_OB_DarkCell", coll, root, (1.95, 25.6, 2.3), (5.2, 23.9, 0.6), 18)
    return root


def build_treatment(coll):
    root = east_shell(coll, "ENV_HistoricalTreatmentRoom", "Historical treatment room (hydrotherapy)", 26.0, 32.0,
                      paint="M_Tile_Wall_Glazed_Cream", floor=CHECKER)
    place(A.prop_tub_hydrotherapy, coll, root, "TR_Tub_1", (4.9, 27.6, 0), 0)
    place(A.prop_tub_hydrotherapy, coll, root, "TR_Tub_2", (4.9, 30.4, 0), 180)
    place(A.prop_table_exam_historic, coll, root, "TR_ExamTable", (2.55, 30.6, 0), 90)
    place(A.prop_cabinet_instrument, coll, root, "TR_InstrumentCabinet", (3.6, 31.69, 0), 0)
    place(A.prop_chair_wood_historic, coll, root, "TR_Chair_Attendant", (3.3, 27.0, 0), 160)
    canvas = MeshBuilder()
    canvas.box((0.95, 2.1, 0.01), (4.9, 27.6, 0.69), "M_Canvas_Aged")                         # Tub cover sheet.
    canvas.box((0.5, 0.01, 0.12), (4.9, 26.56, 0.62), "M_Canvas_Aged")
    tag(canvas.build("TR_TubCover", coll, root), "Canvas tub cover with a head opening; the straps were cut off.")
    drain = MeshBuilder()
    drain.cyl(0.12, 0.01, (3.9, 29.0, 0.005), "M_Iron_Cast_Painted", segs=14)
    drain.build("TR_FloorDrain", coll, root)
    for i, y in enumerate((27.6, 30.4)):
        lamp(coll, root, "TR_Lamp_%d" % i, 4.2, y, (30, 16)[i], flicker=(i == 1))
    decay(coll, root, "Decay", (("stain", (5.893, 28.8, 0.9), (0.004, 1.4, 1.4)),
                               ("flake", (1.607, 27.0, 1.8), (0.004, 0.4, 0.3)),
                               ("stain", (3.9, 29.0, 0.003), (1.4, 1.4, 0.004))))
    L.camera_marker("CAM_TR_Establishing", coll, root, (1.95, 26.4, 2.3), (5.0, 29.6, 0.6), 18)
    return root


def build_med_storage(coll):
    root = east_shell(coll, "ENV_OldMedicationStorage", "Old medication storage", 32.0, 36.0)
    place(A.prop_shelf_medication_historic, coll, root, "MS_Shelf_East", (5.7, 34.0, 0), -90)
    place(A.prop_shelf_medication_historic, coll, root, "MS_Shelf_South", (3.9, 32.29, 0), 180)
    place(A.prop_desk_steel, coll, root, "MS_Counter", (3.6, 35.45, 0), 0)
    tag(place(A.prop_folder_chart, coll, root, "MS_Document_DispensingRegister", (3.4, 35.3, 0.76), 10),
        "Dispensing register; one compound is recorded by code number only.", clinical_review_status="PENDING")
    grille = MeshBuilder()
    for i in range(10):
        grille.box((0.012, 0.012, 0.8), (1.62, 35.0 + i * 0.08, 1.6), "M_Metal_Rust")
    grille.build("MS_ServingGrille", coll, root)
    lamp(coll, root, "MS_Lamp", 3.75, 34.0, 24)
    decay(coll, root, "Decay", (("stain", (5.893, 35.3, 2.5), (0.004, 1.0, 0.6)),))
    debris(coll, root, "Debris", ((4.2, 33.5), (4.9, 34.7)))
    L.camera_marker("CAM_MS_Establishing", coll, root, (1.95, 35.6, 2.3), (5.2, 33.2, 1.0), 18)
    return root


def build_stairwell(coll):
    root = east_shell(coll, "ENV_HistoricStairwell", "Historic stairwell to the maintenance hatch", 36.0, 40.0,
                      paint=GREEN, owns_north=True)
    rise = WALL_H + 0.2
    foot_y = HATCH[1] - rise / math.tan(math.radians(60))
    place(A.prop_stair_service, coll, root, "SW_ServiceStair", (HATCH[0], foot_y, 0), 0)
    hatch = MeshBuilder()
    hatch.box((1.0, 1.0, 0.02), (HATCH[0], HATCH[1] + 0.05, WALL_H - 0.005), "M_Iron_Cast_Painted")
    hatch.box((0.9, 0.9, 0.01), (HATCH[0], HATCH[1] + 0.05, WALL_H - 0.02), "M_Steel_Brushed")
    tag(hatch.build("SW_HatchUnderside", coll, root), "Underside of the maintenance hatch (Stage 4a MA_ServiceHatch).",
        required_access="access_maintenance")
    L.empty("MARK_Link_MaintenanceHatch", coll, root, (HATCH[0], HATCH[1], WALL_H + 0.2), (0, 0, 0),
            display="SINGLE_ARROW", size=0.5,
            props={"marker_type": "level_link", "target": "ENV_MaintenanceAccess/MA_ServiceHatch"})
    place(A.prop_panel_fuse_historic, coll, root, "SW_FuseBoard", (1.607, 39.2, 1.45), 90)
    stencil = MeshBuilder()
    stencil.box((0.5, 0.004, 0.18), (3.0, 39.893, 2.2), "M_Paint_Historic_Cream")
    stencil.build("SW_Stencil_Level", coll, root)
    lamp(coll, root, "SW_Lamp_0", 3.0, 37.2, 22, flicker=True)
    lamp(coll, root, "SW_Lamp_1", 5.3, 39.4, 12)
    decay(coll, root, "Decay", (("stain", (5.893, 37.0, 1.6), (0.004, 1.6, 2.4)),
                               ("flake", (3.4, 39.893, 1.4), (0.5, 0.004, 0.4))))
    L.camera_marker("CAM_SW_Establishing", coll, root, (1.95, 36.4, 1.9), (4.5, 38.8, 2.2), 20)
    return root


def build_vault(coll):
    root = env_root(coll, "ENV_HistoricRecordsVault", "Historic records vault")
    shell(coll, root, 1.5, 6.0, 12.0, 17.0, SOIL, "M_Concrete_Stained",
          {"east": dict(back_mat=SOIL), "south": dict(back_mat=SOIL)}, posts=((6.0, 12.0), (1.5, 12.0)),
          floor_extend=(1.6, 6.1, 11.9, 17.0))
    tag(place(A.prop_door_vault, coll, root, "RV_VaultDoor", (3.75, 17.0, 0), 180),
        "Combination lost; the dial has fresh scratches around one number.",
        door_id="door_records_vault", required_access="access_records_vault")
    for i, y in enumerate((12.9, 14.2, 15.5)):                                  # Clear of the inward door swing.
        place(A.prop_shelving_archive, coll, root, "RV_Shelving_%d" % i, (4.9, y, 0), 0)
    place(A.prop_cabinet_card_index, coll, root, "RV_CardIndex", (2.2, 12.36, 0), 180)
    tag(place(A.prop_folder_chart, coll, root, "RV_Document_TransferRegister", (2.3, 14.2, 0.0), 40),
        "Transfer register dropped on the floor: patients moved 'to W0', no onward entries.",
        clinical_review_status="PENDING")
    lamp(coll, root, "RV_Lamp", 3.75, 14.5, 18)
    decay(coll, root, "Decay", (("stain", (5.893, 13.0, 2.4), (0.004, 1.4, 0.7)),))
    L.camera_marker("CAM_RV_Establishing", coll, root, (2.0, 16.5, 2.2), (4.9, 13.0, 0.9), 18)
    return root


# --------------------------------------------------------------------------
# Level
# --------------------------------------------------------------------------

def build_level():
    L.reset_scene()
    scene = bpy.context.scene
    wing = L.collection("FW_HistoricSubstructure")
    S2.PREVIEW = L.collection("PREVIEW_ONLY_not_exported")
    builders = [
        (build_historic_corridor, "Sublevel: historic ward corridor and disused lift landing"),
        (build_mechanical_corridor, "Sublevel: mechanical and maintenance corridor"),
        (build_sealed_corridor, "Sublevel: sealed connecting corridor (Ward Zero beyond, Stage 6)"),
        (build_records_archive, "Sublevel: paper medical records archive"),
        (build_admin_office, "Sublevel: disused administrative office"),
        (lambda c: build_patient_room(c, 2, 28.0), "Sublevel: former patient room 2"),
        (lambda c: build_patient_room(c, 1, 31.0), "Sublevel: former patient room 1"),
        (build_nursing_station, "Sublevel: abandoned nursing station"),
        (build_observation, "Sublevel: closed observation rooms"),
        (build_treatment, "Sublevel: historical treatment room"),
        (build_med_storage, "Sublevel: old medication storage"),
        (build_stairwell, "Sublevel: historic stairwell to the maintenance hatch"),
        (build_vault, "Sublevel: historic records vault"),
    ]
    envs = []
    for i, (builder, location) in enumerate(builders):
        envs.append((builder(L.collection("ENV_sub_%02d" % i, wing)), location))

    for root, _ in envs:
        lo, hi = L.world_bounds(root)
        assert 3.0 < max(hi - lo) < 26.0, (root.name, tuple(hi - lo))
        assert -6.3 < lo.x and hi.x < 6.3 and lo.y > 9.7 and hi.y < 44.5, root.name + " outside the footprint"
        assert any(o.name.startswith("CAM_") for o in L.descendants(root)), root.name + " has no camera markers"
        assert any(o.name.endswith("-colonly") for o in L.descendants(root)), root.name + " has no collision"
    stair = bpy.data.objects["SW_ServiceStair"]
    top = stair.matrix_world @ Vector((0.0, stair["rise_m"] / math.tan(math.radians(60)), stair["rise_m"]))
    assert (Vector((top.x, top.y)) - Vector(HATCH)).length < 0.05, "stair must top out under the hatch"
    gate = bpy.data.objects["LiftLanding_Gate"]
    gx = sum((gate.matrix_world @ v.co).x for v in gate.data.vertices) / len(gate.data.vertices)
    assert abs(gx - LIFT[0]) < 0.05, "lift landing must sit under the restricted lift"

    L.save_blend(WING_BLEND)
    records = []
    for root, location in envs:
        path = os.path.join(ENV_DIR, root.name + ".glb")
        L.export_glb(root, path)
        records.append(L.asset_record(
            root, WING_BLEND, path, location, "Floor + wall + furniture box colliders; door leaves carry their own",
            "Sublevel: place at the level origin (same x/y as Chapter 1; hatch at x 4.5, y 38.6; lift at x 0, y 44). "
            "CAM_* framing references; MARK_* forward = Godot -Z; LIGHTMARK_* positions (flicker flags); "
            "godot_hint + story_tag mark storytelling hooks.", STATUS, REPO))
    L.write_manifest(records, MANIFEST)
    if FAST:
        return len(records)

    L.setup_render(scene, 1280, 720, samples=32)
    shots = (("CAM_HC_Corridor", "historic_corridor.png"), ("CAM_NS_Establishing", "historic_nursing_station.png"),
             ("CAM_TR_Establishing", "historic_treatment.png"), ("CAM_OB_Establishing", "historic_observation.png"),
             ("CAM_SW_Establishing", "historic_stairwell.png"), ("CAM_MC_Establishing", "historic_mechanical.png"),
             ("CAM_SC_Corridor", "historic_sealed_corridor.png"), ("CAM_PR1_Establishing", "historic_patient_room.png"),
             ("CAM_MS_Establishing", "historic_med_storage.png"), ("CAM_RV_Establishing", "historic_vault.png"))
    for cam_name, out in shots:
        L.render_from(scene, bpy.data.objects[cam_name], os.path.join(RENDER_DIR, out))
    for ob in bpy.data.objects:
        if ob.name.endswith("_Ceiling") or "Lamp" in ob.name or ob.name.endswith("_preview"):
            ob.hide_render = True
    sun = bpy.data.lights.new("PlanSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PlanSun", sun)
    S2.PREVIEW.objects.link(sun_ob)
    plan = L.camera_marker("PlanCam_preview", S2.PREVIEW, None, (0.0, 27.0, 40.0), (0.0, 27.0, 0.0), 30)
    plan.data.type = "ORTHO"
    plan.data.ortho_scale = 36.0
    scene.render.resolution_x, scene.render.resolution_y = 800, 1100
    L.render_from(scene, plan, os.path.join(RENDER_DIR, "historic_plan.png"))
    return len(records)


def main():
    n_props = build_props()
    n_envs = build_level()
    print("STAGE5 HISTORIC OK: %d props, %d environments exported%s" % (n_props, n_envs, " (fast)" if FAST else ""))


if __name__ == "__main__":
    main()
