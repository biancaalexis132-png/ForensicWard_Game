"""Stage 6: Ward Zero (W0), the historic service and observation zone, plus its props.

Ward Zero lies on the Stage 5 sublevel, south of the sealed connecting corridor:
its threshold room sits behind the bricked-up opening at y = 10, which Stage 5
authors as state_group `sealed_corridor_end`. The zone also sits directly under
the Chapter 1 W0-B door (Door_W0B at x 0, y 0 on the ground floor): a steep
service stair in the W0 corridor tops out just beyond that door, under a floor
hatch (asserted). Like Stage 5 it is its own level, authored at floor z = 0
with the same x/y as the Chapter 1 shared frame.

Layout (wall centrelines, metres):

    y         west side (x -6 .. -1.5)     corridor (x +/-1.5)          east side (x 1.5 .. 6)
    6 .. 10                                threshold (brick at y 10)
    1 .. 6    Observation room             W0 service corridor          Instrument room
   -1 .. 6    (window into the cell)       (stair to W0-B, y -2.5..-0.6)
   -5 .. -1   Isolation cell                                            Plant room          -10 .. 1
  -10 .. -5   Service store

Anomaly states. The owner approved a genuine phenomenon in Ward Zero; its
mechanism is not approved canon. This stage only authors physical, swappable
states that F3's `world_state` and `device_log` manifestations can drive. Every
default state has an ordinary reading, nothing reacts to a patient or to any
clinical event, and every hint describes only what the player can see. Each
state node carries `story_tag: ward_zero_anomaly` and
`approval_status: provisional_owner_review`. The groups:

    w0_clock_offset      synced (default) | offset      corridor slave clock B
    w0_recorder_trace    flat (default)   | repeated    observation-room chart recorder
    w0_teleprinter_log   idle (default)   | printed     instrument-room teleprinter
    w0_door_mimic        (none)           | door_open_indicated   relay-cabinet lamp
    w0_cell_chair        by_window (default) | moved    isolation-cell chair
    w0_instrument_kit    (none)           | installed   modern sensor tripods (supervised observation;
                                                       story_tag ward_zero_investigation, not an anomaly)

Wall ownership: the threshold owns its sides and the south wall with the inner
door; the corridor owns its side walls and the south end wall; each side room
owns its outer walls and its south wall (the first in a row also its north).

Outputs:
    assets/blender/wardzero/FW_Props_WardZero.blend, assets/exports/wardzero/props/*.glb
    assets/blender/wardzero/FW_WardZero.blend, assets/exports/wardzero/env/ENV_*.glb
    assets/renders/stage6/*.png (skipped with --fast)
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
import build_stage5_historic as S5  # noqa: E402
import fw_assets as A  # noqa: E402
import fw_lib as L  # noqa: E402
from fw_lib import WALL_H, MeshBuilder  # noqa: E402

PROPS_BLEND = os.path.join(REPO, "assets/blender/wardzero/FW_Props_WardZero.blend")
ZONE_BLEND = os.path.join(REPO, "assets/blender/wardzero/FW_WardZero.blend")
PROPS_DIR = os.path.join(REPO, "assets/exports/wardzero/props")
ENV_DIR = os.path.join(REPO, "assets/exports/wardzero/env")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage6")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = S4.STATUS
FAST = "--fast" in sys.argv
D90 = math.pi / 2
FRAME = ("Sublevel frame: same x/y as the Chapter 1 shared frame, floor at z = 0; load as its own level "
         "(the Stage 5 sealed corridor and the W0-B service stair connect it)")
W0, LOWER = "M_Paint_W0_GreyGreen", "M_Paint_W0_Lower"
BEIGE, CHECKER, TERRAZZO = S5.BEIGE, S5.CHECKER, S5.TERRAZZO
SOIL = S5.SOIL
W0B_DOOR = (0.0, 0.0)                 # Chapter 1 Door_W0B, ground floor.
STAIR_TOP = (0.6, -0.6)               # Just beyond the W0-B door, under a floor hatch.
APPROVAL = "provisional_owner_review"

place, door, set_props = S2.place, S2.door, S2.set_props
wall_with_collision = S2.wall_with_collision
shell, lamp, decay, debris = S5.shell, S5.lamp, S5.decay, S5.debris

PROP_WALL_MOUNTED = {"PROP_Clock_Wall_Historic"}
PROP_LOCATIONS = {
    "PROP_Clock_Wall_Historic": "W0 service corridor, instrument room",
    "PROP_Recorder_Chart_Strip": "W0 observation room",
    "PROP_Teleprinter_Historic": "W0 instrument room",
    "PROP_Cabinet_Relay_Historic": "W0 instrument room",
    "PROP_MotorGenerator_Set": "W0 plant room",
    "PROP_Sensor_Tripod_Modern": "Ward Zero (state w0_instrument_kit: installed)",
}


def env_root(coll, asset_id, name):
    root = S2.env_root(coll, asset_id, name)
    root["frame"] = FRAME
    root["audio_location"] = "ward_zero"
    return root


def tag(ob, hint, **extra):
    """Environmental-storytelling hook: what the player sees, never a clinical fact."""
    return set_props(ob, dict({"godot_hint": hint, "story_tag": "ward_zero"}, **extra))


def state(ob, group, value, default_visible, hint, manifestation="world_state"):
    """A swappable anomaly state. Inert set dressing until F3 drives it."""
    return set_props(ob, {"state_group": group, "state": value, "default_visible": default_visible,
                          "godot_hint": hint, "story_tag": "ward_zero_anomaly", "manifestation": manifestation,
                          "approval_status": APPROVAL})


def kit(ob, hint):
    """Modern instrument kit for a supervised observation: hidden until its group is 'installed'."""
    return set_props(ob, {"state_group": "w0_instrument_kit", "state": "installed", "default_visible": False,
                          "godot_hint": hint, "story_tag": "ward_zero_investigation"})


def corridor_sign(coll, root, name, loc, rot):
    return place(A.prop_sign_room, coll, root, name, loc, rot)


def child(ob, suffix):
    return next(c for c in ob.children if suffix in c.name)


def strip_collision(ob):
    for o in [o for o in L.descendants(ob) if "-colonly" in o.name]:          # Duplicates end ".001".
        bpy.data.objects.remove(o, do_unlink=True)
    return ob


# --------------------------------------------------------------------------
# Props library
# --------------------------------------------------------------------------

def build_props():
    L.reset_scene()
    scene = bpy.context.scene
    coll = L.collection("FW_Props_WardZero")
    records = []
    for i, builder in enumerate(A.STAGE6_WARD_ZERO_PROP_BUILDERS):
        root = builder(coll, loc=((i % 3) * 3.2, (i // 3) * 3.4, 0))
        has_col = any(o.name.endswith("-colonly") for o in L.descendants(root))
        origin = "wall surface" if root.name in PROP_WALL_MOUNTED else "floor centre"
        records.append((root, PROP_LOCATIONS[root.name],
                        "Box collider (-colonly)" if has_col else "Decorative: no collision",
                        "Ward Zero (historic service zone; the tripod is modern). Origin: %s. Swappable "
                        "children keep stable name suffixes for state_group tagging." % origin))
    for root, *_ in records:
        lo, hi = L.world_bounds(root)
        assert max(hi - lo) < 3.0, "%s too large" % root.name
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
        L.setup_render(scene, 1600, 900, samples=24)
        sun = bpy.data.lights.new("PreviewSun", "SUN")
        sun.energy = 3.0
        sun_ob = bpy.data.objects.new("PreviewSun", sun)
        scene.collection.objects.link(sun_ob)
        sun_ob.rotation_euler = (math.radians(45), 0, math.radians(-25))
        ground = MeshBuilder()
        ground.box((20, 14, 0.02), (3.2, 1.7, -0.01), CHECKER)
        ground.build("PreviewGround", scene.collection)
        cam = L.camera_marker("PreviewCam", scene.collection, None, (3.2, -7.5, 5.0), (3.2, 2.2, 0.8), 26)
        L.render_from(scene, cam, os.path.join(RENDER_DIR, "props_wardzero.png"))
    return len(manifest)


# --------------------------------------------------------------------------
# Threshold and corridor
# --------------------------------------------------------------------------

def build_threshold(coll):
    root = env_root(coll, "ENV_W0_Threshold", "Ward Zero threshold (behind the bricked-up opening)")
    shell(coll, root, -1.5, 1.5, 6.0, 10.0, W0, CHECKER,
          {"west": dict(back_mat=SOIL), "east": dict(back_mat=SOIL),
           "south": dict(back_mat=W0, openings=[A.door_opening(1.5, 1.2)])},
          posts=((-1.5, 6.0), (1.5, 6.0)), floor_extend=(-1.6, 1.6, 6.0, 9.9))
    door(coll, root, "Door_W0_Inner", "service_historic", (0.0, 6.0, 0), math.pi, "door_w0_inner", "",
         "Original inner door of Ward Zero; reached only once the sealed corridor is opened.")
    plate = MeshBuilder()
    plate.box((0.6, 0.006, 0.22), (0.0, 6.109, 2.55), "M_Enamel_Plate_Blue")
    plate.box((0.16, 0.004, 0.08), (0.0, 6.113, 2.58), "M_Paint_Historic_Cream")
    tag(plate.build("W0T_EnamelPlate", coll, root),
        "Enamel plate with the hospital crest and 'W0' beneath it; the rest is painted over.")
    sten = MeshBuilder()
    sten.box((0.42, 0.004, 0.2), (-1.05, 6.108, 1.6), "M_Paint_Historic_Cream")
    tag(sten.build("W0T_Stencil_W0B", coll, root), "Stencilled 'W0-B' with an arrow pointing south.")
    bench = MeshBuilder()
    bench.box((0.4, 1.6, 0.04), (-1.18, 8.0, 0.45), "M_Wood_Aged")
    for y in (7.35, 8.65):
        bench.box((0.36, 0.04, 0.45), (-1.18, y, 0.225), "M_Iron_Cast_Painted")
    bench.build("W0T_Bench", coll, root)
    L.collision_box("W0T_Bench_COL", coll, root, (0.4, 1.6, 0.47), (-1.18, 8.0, 0.235))
    place(A.prop_radiator_cast, coll, root, "W0T_Radiator", (1.29, 8.2, 0), -90)
    tripod = place(A.prop_sensor_tripod, coll, root, "W0T_SensorTripod", (0.75, 6.9, 0), 0)
    kit(tripod, "Sensor tripod aimed at the inner door, cabled to a logger on the floor.")
    lamp(coll, root, "W0T_Lamp", 0.0, 7.6, 16, flicker=True)
    decay(coll, root, "Decay", (("stain", (1.393, 7.0, 1.5), (0.004, 1.4, 1.2)),
                               ("flake", (-1.392, 9.0, 2.0), (0.004, 0.6, 0.5)),
                               ("stain", (0.0, 9.3, 0.003), (2.2, 1.0, 0.004))))
    debris(coll, root, "Debris", ((0.4, 9.4), (-0.3, 8.7), (0.6, 7.4), (-0.6, 6.6)))
    L.camera_marker("CAM_W0T_Threshold", coll, root, (0.4, 9.6, 1.6), (0.0, 6.0, 1.3), 26)
    return root


W0_WEST_DOORS = (("Observation", 4.0, 1.0), ("Cell", -3.0, 1.0), ("Store", -7.5, 1.0))
W0_EAST_DOORS = (("Instrument", 3.5, 1.0), ("Plant", -6.0, 1.2))


def build_corridor(coll):
    root = env_root(coll, "ENV_W0_ServiceCorridor_16m", "Ward Zero service corridor, 16 m, with the W0-B stair")
    west = [A.door_opening(y + 10.0, w) for _, y, w in W0_WEST_DOORS]
    east = [A.door_opening(6.0 - y, w) for _, y, w in W0_EAST_DOORS]
    shell(coll, root, -1.5, 1.5, -10.0, 6.0, W0, CHECKER,
          {"west": dict(openings=west, back_mat=W0), "east": dict(openings=east, back_mat=W0),
           "south": dict(back_mat=SOIL)},
          posts=((-1.5, -10.0), (1.5, -10.0)), floor_extend=(-1.6, 1.6, -10.1, 6.0))
    for name, y, _ in W0_WEST_DOORS:
        door(coll, root, "Door_W0_" + name, "service_historic", (-1.5, y, 0), D90, "door_w0_" + name.lower(), "")
        corridor_sign(coll, root, "Sign_W0_" + name, (-1.394, y + 0.85, 1.7), 90)
    for name, y, _ in W0_EAST_DOORS:
        door(coll, root, "Door_W0_" + name, "service_historic", (1.5, y, 0), -D90, "door_w0_" + name.lower(), "")
        corridor_sign(coll, root, "Sign_W0_" + name, (1.394, y - 0.85, 1.7), -90)

    # The W0-B service stair: tops out just beyond the Chapter 1 W0-B door.
    rise = WALL_H + 0.2
    foot_y = STAIR_TOP[1] - rise / math.tan(math.radians(60))
    place(A.prop_stair_service, coll, root, "W0C_ServiceStair_W0B", (STAIR_TOP[0], foot_y, 0), 0)
    hatch = MeshBuilder()
    hatch.box((1.0, 1.0, 0.02), (STAIR_TOP[0], STAIR_TOP[1] + 0.05, WALL_H - 0.005), "M_Iron_Cast_Painted")
    hatch.box((0.9, 0.9, 0.01), (STAIR_TOP[0], STAIR_TOP[1] + 0.05, WALL_H - 0.02), "M_Steel_Brushed")
    tag(hatch.build("W0C_HatchUnderside", coll, root),
        "Underside of a floor hatch: the far side of the W0-B door on the ground floor.",
        required_access="access_ward_zero")
    L.empty("MARK_Link_W0B", coll, root, (STAIR_TOP[0], STAIR_TOP[1], WALL_H + 0.2), (0, 0, 0),
            display="SINGLE_ARROW", size=0.5,
            props={"marker_type": "level_link", "target": "ENV_ClinicalCorridor_20m/Door_W0B",
                   "godot_hint": "The ground-floor stair head beyond Door_W0B is not modelled; transition here."})

    # Two slave clocks on one circuit. Clock B can show a different time.
    place(A.prop_clock_historic, coll, root, "W0C_ClockA", (-1.394, 0.6, 2.3), 90)
    clock_b = place(A.prop_clock_historic, coll, root, "W0C_ClockB", (1.394, -8.2, 2.3), -90)
    synced = child(clock_b, "_Hands")
    synced.name = "W0C_ClockB_Hands_Synced"
    state(synced, "w0_clock_offset", "synced", True,
          "Clock B has stopped at the same time as clock A.")
    offset = A.clock_hands("W0C_ClockB_Hands_Offset", coll, clock_b, 3, 52, y=-0.0485)
    state(offset, "w0_clock_offset", "offset", False,
          "Clock B shows twelve minutes later than clock A. Both are stopped.")
    services = MeshBuilder()
    services.box((0.3, 15.6, 0.25), (1.2, -2.0, 2.75), "M_Steel_Painted_Grey")             # Cable tray (east).
    for y in (-8.0, -4.0, 0.0, 4.0):
        services.box((0.32, 0.04, 0.3), (1.2, y, 2.75), "M_Metal_Rust")
    services.cyl(0.05, 15.6, (-1.3, -2.0, 2.8), "M_Metal_Rust", axis="Y", segs=10)         # Pipe (west).
    services.build(root.name + "_Services", coll, root)
    for i, y in enumerate((2.0, -5.5)):
        place(A.prop_radiator_cast, coll, root, "W0C_Radiator_%d" % i, (-1.29, y, 0), 90)
    tripod = place(A.prop_sensor_tripod, coll, root, "W0C_SensorTripod", (-0.9, 1.4, 0), 0)
    kit(tripod, "Sensor tripod between the two clocks, cabled to a logger by the wall.")
    for i, (y, w, fl) in enumerate(((4.0, 14, False), (0.0, 0, False), (-4.0, 18, False), (-8.0, 10, True))):
        lamp(coll, root, "W0C_Lamp_%d" % i, 0.0 if y != 0.0 else -0.6, y, w, flicker=fl, dead=(w == 0))
    decay(coll, root, "Decay", (("stain", (-1.393, -1.0, 1.2), (0.004, 2.2, 1.4)),
                               ("flake", (1.392, 1.5, 1.9), (0.004, 0.7, 0.5)),
                               ("stain", (1.393, -9.0, 0.8), (0.004, 1.4, 1.2)),
                               ("stain", (-0.2, -6.5, 0.003), (2.0, 1.8, 0.004))))
    debris(coll, root, "Debris", ((-0.5, 5.0), (0.4, 2.4), (-0.7, -4.6), (0.3, -8.8)))
    L.camera_marker("CAM_W0C_Corridor", coll, root, (0.3, 5.6, 1.65), (0.0, -10.0, 1.2), 24)
    L.camera_marker("CAM_W0C_FromSouth", coll, root, (-0.6, -9.6, 1.6), (0.4, 4.0, 1.5), 26)
    L.camera_marker("CAM_W0C_Stair", coll, root, (-1.1, -4.6, 1.5), (0.6, -0.6, 2.6), 22)
    return root


# --------------------------------------------------------------------------
# West rooms
# --------------------------------------------------------------------------

def west_shell(coll, asset_id, name, y0, y1, paint=W0, floor=TERRAZZO, owns_north=False, south_kwargs=None):
    root = env_root(coll, asset_id, name)
    walls = {"south": dict({"back_mat": W0}, **(south_kwargs or {})), "west": dict(back_mat=SOIL)}
    if owns_north:
        walls["north"] = dict(back_mat=SOIL)
    posts = [(-6.0, y0)] + ([(-6.0, y1)] if owns_north else [])
    shell(coll, root, -6.0, -1.5, y0, y1, paint, floor, walls, posts=posts,
          floor_extend=(-6.1, -1.6, y0, y1 + (0.1 if owns_north else 0.0)))
    return root


def build_observation(coll):
    window = A.window_opening(-1.5 - (-3.75), 1.4, 1.0, 1.8, glass="M_Glass_Grimy")
    root = west_shell(coll, "ENV_W0_ObservationRoom", "Ward Zero observation room", -1.0, 6.0, owns_north=True,
                      south_kwargs=dict(openings=[window], back_mat=BEIGE))
    place(A.prop_desk_steel, coll, root, "OM_Desk", (-3.75, -0.5, 0), 180)
    place(A.prop_chair_wood_historic, coll, root, "OM_Chair", (-3.75, 0.25, 0), 0)
    rec = place(A.prop_recorder_chart, coll, root, "OM_ChartRecorder", (-5.6, 2.2, 0), 90)
    tag(rec, "Two-pen chart recorder, its cable running up into the ceiling towards the corridor.")
    flat, rep = child(rec, "_Trace_Flat"), child(rec, "_Trace_Repeated")
    flat.name, rep.name = "OM_Recorder_Trace_Flat", "OM_Recorder_Trace_Repeated"
    state(flat, "w0_recorder_trace", "flat", True, "Both pens trace flat lines.", "device_log")
    state(rep, "w0_recorder_trace", "repeated", False,
          "One pen traces the same short pattern three times at even spacing.", "device_log")
    place(A.prop_cabinet_instrument, coll, root, "OM_Cabinet", (-2.4, 5.65, 0), 180)
    log = place(A.prop_folder_chart, coll, root, "OM_Document_ObservationLog", (-3.4, -0.4, 0.76), 15)
    tag(log, "Observation log; the columns are for times and instrument readings, not patients.",
        clinical_review_status="PENDING")
    lamp(coll, root, "OM_Lamp", -3.75, 2.5, 16)
    decay(coll, root, "Decay", (("stain", (-5.893, 4.6, 2.3), (0.004, 1.2, 0.9)),
                               ("flake", (-4.6, 5.893, 1.1), (0.5, 0.004, 0.4))))
    debris(coll, root, "Debris", ((-4.8, 3.6), (-2.6, 1.6)))
    L.camera_marker("CAM_OM_Establishing", coll, root, (-1.95, 5.6, 2.3), (-4.6, -0.6, 0.9), 18)
    return root


def build_cell(coll):
    root = west_shell(coll, "ENV_W0_IsolationCell", "Ward Zero isolation cell", -5.0, -1.0, paint=BEIGE)
    place(A.prop_bed_iron, coll, root, "IC_Bed", (-5.4, -3.2, 0), 0)
    by_window = strip_collision(place(A.prop_chair_wood_historic, coll, root, "IC_Chair_ByWindow",
                                      (-3.2, -1.5, 0), 180))
    state(by_window, "w0_cell_chair", "by_window", True, "A chair under the observation window.")
    moved = strip_collision(place(A.prop_chair_wood_historic, coll, root, "IC_Chair_Moved", (-3.9, -3.4, 0), 35))
    state(moved, "w0_cell_chair", "moved", False,
          "The chair stands in the middle of the floor, angled to the door; there are no scuff marks.")
    drain = MeshBuilder()
    drain.cyl(0.08, 0.006, (-3.5, -3.0, 0.003), "M_Iron_Cast_Painted", segs=16)
    drain.build("IC_Drain", coll, root)
    tripod = place(A.prop_sensor_tripod, coll, root, "IC_SensorTripod", (-4.4, -4.3, 0), 0)
    kit(tripod, "Sensor tripod aimed at the chair.")
    lamp(coll, root, "IC_Lamp", -3.75, -3.0, 10)
    decay(coll, root, "Decay", (("stain", (-5.893, -4.0, 0.7), (0.004, 1.3, 1.0)),
                               ("stain", (-3.0, -4.2, 0.003), (1.6, 1.0, 0.004))))
    L.camera_marker("CAM_IC_Establishing", coll, root, (-1.95, -1.4, 2.3), (-5.0, -4.4, 0.6), 18)
    return root


def build_store(coll):
    root = west_shell(coll, "ENV_W0_ServiceStore", "Ward Zero service store", -10.0, -5.0, floor=SOIL,
                      south_kwargs=dict(back_mat=SOIL))
    place(A.prop_shelving_archive, coll, root, "SS_Shelving_0", (-5.67, -7.5, 0), 90)
    place(A.prop_shelving_archive, coll, root, "SS_Shelving_1", (-3.7, -9.67, 0), 180)
    place(A.prop_cabinet_card_index, coll, root, "SS_CardIndex", (-2.5, -5.45, 0), 0)
    reg = place(A.prop_folder_chart, coll, root, "SS_Document_EquipmentRegister", (-2.6, -5.5, 1.2), -20)
    tag(reg, "Equipment register: the chart recorder and both slave clocks are signed out to 'W0 obs.'")
    lamp(coll, root, "SS_Lamp", -3.75, -7.5, 12)
    decay(coll, root, "Decay", (("stain", (-4.5, -9.893, 1.0), (1.4, 0.004, 1.2)),))
    debris(coll, root, "Debris", ((-3.2, -6.6), (-4.4, -8.4)))
    L.camera_marker("CAM_SS_Establishing", coll, root, (-1.95, -5.4, 2.3), (-5.0, -9.0, 0.8), 18)
    return root


# --------------------------------------------------------------------------
# East rooms
# --------------------------------------------------------------------------

def east_shell(coll, asset_id, name, y0, y1, paint=W0, floor=TERRAZZO, owns_north=False, south_kwargs=None):
    root = env_root(coll, asset_id, name)
    walls = {"south": dict({"back_mat": W0}, **(south_kwargs or {})), "east": dict(back_mat=SOIL)}
    if owns_north:
        walls["north"] = dict(back_mat=SOIL)
    posts = [(6.0, y0)] + ([(6.0, y1)] if owns_north else [])
    shell(coll, root, 1.5, 6.0, y0, y1, paint, floor, walls, posts=posts,
          floor_extend=(1.6, 6.1, y0, y1 + (0.1 if owns_north else 0.0)))
    return root


def build_instrument_room(coll):
    root = east_shell(coll, "ENV_W0_InstrumentRoom", "Ward Zero instrument room", 1.0, 6.0, owns_north=True)
    cab = place(A.prop_cabinet_relay, coll, root, "IR_RelayCabinet", (5.67, 3.8, 0), -90)
    tag(cab, "Relay cabinet with a door mimic panel; the inner-door lamp is wired to a contact on that door.")
    mimic = child(cab, "_Lamp_Lit")
    mimic.name = "IR_Mimic_Lamp_InnerDoorOpen"
    state(mimic, "w0_door_mimic", "door_open_indicated", False,
          "The mimic lamp for the inner door is lit although the door is shut.", "device_log")
    tp = place(A.prop_teleprinter, coll, root, "IR_Teleprinter", (3.6, 5.63, 0), 0)
    idle, printed = child(tp, "_Sheet_Idle"), child(tp, "_Sheet_Printed")
    idle.name, printed.name = "IR_Teleprinter_Sheet_Idle", "IR_Teleprinter_Sheet_Printed"
    state(idle, "w0_teleprinter_log", "idle", True, "A torn-off stub of paper in the teleprinter.", "device_log")
    state(printed, "w0_teleprinter_log", "printed", False,
          "A length of fresh print-out: the same short line of figures, repeated.", "device_log")
    place(A.prop_desk_steel, coll, root, "IR_Desk", (4.4, 1.48, 0), 180)
    place(A.prop_chair_wood_historic, coll, root, "IR_Chair", (4.4, 2.2, 0), 0)
    place(A.prop_clock_historic, coll, root, "IR_Clock", (1.606, 2.4, 2.3), 90)
    lamp(coll, root, "IR_Lamp", 3.75, 3.5, 18)
    decay(coll, root, "Decay", (("stain", (5.893, 1.8, 2.2), (0.004, 1.2, 0.9)),
                               ("stain", (3.0, 4.0, 0.003), (1.4, 1.2, 0.004))))
    debris(coll, root, "Debris", ((2.6, 4.6), (4.9, 2.6)))
    L.camera_marker("CAM_IR_Establishing", coll, root, (1.95, 1.4, 2.3), (5.0, 5.0, 1.0), 18)
    return root


def build_plant_room(coll):
    root = east_shell(coll, "ENV_W0_PlantRoom", "Ward Zero plant room", -10.0, 1.0, floor=SOIL,
                      south_kwargs=dict(back_mat=SOIL))
    for i, y in enumerate((-3.4, -7.6)):
        place(A.prop_motor_generator, coll, root, "PR_MotorGenerator_%d" % i, (4.4, y, 0), 90)
    L.empty("MARK_Audio_W0Hum", coll, root, (4.4, -3.4, 1.0), (0, 0, 0), display="SPHERE", size=0.3,
            props={"marker_type": "audio_emitter", "audio_location": "ward_zero",
                   "godot_hint": "Low mechanical hum; the set is still energised from the isolated circuit."})
    place(A.prop_panel_fuse_historic, coll, root, "PR_FuseBoard", (5.894, -0.4, 1.45), -90)
    for i, x in enumerate((2.6, 4.6)):
        place(A.prop_pipes_wall, coll, root, "PR_Pipes_%d" % i, (x, -9.894, 2.5), 180)
    for i, (y, w, fl) in enumerate(((-1.6, 20, False), (-5.5, 14, True), (-9.0, 0, False))):
        lamp(coll, root, "PR_Lamp_%d" % i, 3.2, y, w, flicker=fl, dead=(w == 0))
    decay(coll, root, "Decay", (("stain", (5.893, -6.0, 0.6), (0.004, 2.4, 1.0)),
                               ("stain", (3.4, -5.4, 0.003), (1.6, 2.6, 0.004))))
    place(A.prop_bin, coll, root, "PR_Bucket", (5.5, -9.5, 0), 0)
    L.camera_marker("CAM_PR_Establishing", coll, root, (1.95, 0.6, 2.3), (4.6, -8.0, 0.6), 18)
    return root


# --------------------------------------------------------------------------
# Level
# --------------------------------------------------------------------------

def apply_default_states():
    for ob in bpy.data.objects:
        if "state_group" in ob.keys():
            ob.hide_render = not bool(ob["default_visible"])
            for o in L.descendants(ob):
                o.hide_render = ob.hide_render or "-colonly" in o.name


def apply_variant_states():
    """Shows every non-default state (anomaly variants and the instrument kit)."""
    for ob in bpy.data.objects:
        if "state_group" in ob.keys():
            ob.hide_render = bool(ob["default_visible"])
            for o in L.descendants(ob):
                o.hide_render = ob.hide_render or "-colonly" in o.name


def build_level():
    L.reset_scene()
    scene = bpy.context.scene
    zone = L.collection("FW_WardZero")
    S2.PREVIEW = L.collection("PREVIEW_ONLY_not_exported")
    builders = [
        (build_threshold, "Ward Zero: threshold behind the sealed corridor"),
        (build_corridor, "Ward Zero: service corridor and the W0-B service stair"),
        (build_observation, "Ward Zero: observation room"),
        (build_cell, "Ward Zero: isolation cell"),
        (build_store, "Ward Zero: service store"),
        (build_instrument_room, "Ward Zero: instrument room"),
        (build_plant_room, "Ward Zero: plant room"),
    ]
    envs = []
    for i, (builder, location) in enumerate(builders):
        envs.append((builder(L.collection("ENV_w0_%02d" % i, zone)), location))

    for root, _ in envs:
        lo, hi = L.world_bounds(root)
        assert 3.0 < max(hi - lo) < 22.0, (root.name, tuple(hi - lo))
        assert -6.3 < lo.x and hi.x < 6.3 and lo.y > -10.3 and hi.y < 10.2, root.name + " outside the footprint"
        assert any(o.name.startswith("CAM_") for o in L.descendants(root)), root.name + " has no camera markers"
        assert any(o.name.endswith("-colonly") for o in L.descendants(root)), root.name + " has no collision"
    stair = bpy.data.objects["W0C_ServiceStair_W0B"]
    top = stair.matrix_world @ Vector((0.0, stair["rise_m"] / math.tan(math.radians(60)), stair["rise_m"]))
    assert (Vector((top.x, top.y)) - Vector(STAIR_TOP)).length < 0.05, "stair must top out at the W0-B stair head"
    assert -1.0 < top.y - W0B_DOOR[1] < 0.0 and abs(top.x - W0B_DOOR[0]) < 0.8, "stair head must be beyond W0-B"
    groups = {}
    for ob in bpy.data.objects:
        if "state_group" in ob.keys() and ob.get("story_tag") == "ward_zero_anomaly":
            groups.setdefault(ob["state_group"], []).append(ob)
            assert ob["approval_status"] == APPROVAL, ob.name
            assert not any("-colonly" in o.name for o in L.descendants(ob)), ob.name + " state has collision"
    assert len(groups) == 5, sorted(groups)

    L.save_blend(ZONE_BLEND)
    records = []
    for root, location in envs:
        path = os.path.join(ENV_DIR, root.name + ".glb")
        L.export_glb(root, path)
        records.append(L.asset_record(
            root, ZONE_BLEND, path, location, "Floor + wall + furniture box colliders; door leaves carry their own",
            "Sublevel: place at the level origin (same x/y as Chapter 1; the sealed corridor ends at y 10; the "
            "W0-B stair head is at x 0.6, y -0.6). CAM_* framing references; MARK_* forward = Godot -Z; "
            "LIGHTMARK_* positions (flicker flags); state_group extras with story_tag ward_zero_anomaly are "
            "provisional anomaly states (owner review).", STATUS, REPO))
    L.write_manifest(records, MANIFEST)
    if FAST:
        return len(records)

    L.setup_render(scene, 1280, 720, samples=32)
    apply_default_states()
    shots = (("CAM_W0T_Threshold", "w0_threshold.png"), ("CAM_W0C_Corridor", "w0_corridor.png"),
             ("CAM_W0C_Stair", "w0_stair.png"), ("CAM_OM_Establishing", "w0_observation.png"),
             ("CAM_IC_Establishing", "w0_cell.png"), ("CAM_SS_Establishing", "w0_store.png"),
             ("CAM_IR_Establishing", "w0_instrument_room.png"), ("CAM_PR_Establishing", "w0_plant_room.png"))
    for cam_name, out in shots:
        L.render_from(scene, bpy.data.objects[cam_name], os.path.join(RENDER_DIR, out))
    apply_variant_states()
    for cam_name, out in (("CAM_IR_Establishing", "w0_instrument_room_variant.png"),
                          ("CAM_OM_Establishing", "w0_observation_variant.png"),
                          ("CAM_IC_Establishing", "w0_cell_variant.png")):
        L.render_from(scene, bpy.data.objects[cam_name], os.path.join(RENDER_DIR, out))
    apply_default_states()
    for ob in bpy.data.objects:
        if ob.name.endswith("_Ceiling") or "Lamp" in ob.name or ob.name.endswith("_preview"):
            ob.hide_render = True
    sun = bpy.data.lights.new("PlanSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PlanSun", sun)
    S2.PREVIEW.objects.link(sun_ob)
    plan = L.camera_marker("PlanCam_preview", S2.PREVIEW, None, (0.0, 0.0, 40.0), (0.0, 0.0, 0.0), 30)
    plan.data.type = "ORTHO"
    plan.data.ortho_scale = 22.0
    scene.render.resolution_x, scene.render.resolution_y = 800, 1100
    L.render_from(scene, plan, os.path.join(RENDER_DIR, "w0_plan.png"))
    return len(records)


def main():
    n_props = build_props()
    n_envs = build_level()
    print("STAGE6 WARD ZERO OK: %d props, %d environments exported%s" % (n_props, n_envs, " (fast)" if FAST else ""))


if __name__ == "__main__":
    main()
