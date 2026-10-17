"""Stage 2: Chapter 1 clinical wing, assembled in one shared frame.

Placing every exported ENV_* at the Godot origin assembles the wing
(Blender +Y -> Godot -Z). Layout (wall centrelines, metres):

    y   west side (x -6 .. -1.5)        corridor (x +/-1.5)   east side (x 1.5 .. 5.5)
    0                                   W0-B sealed door (S)
    2-6   Psychiatrist's office (door 5)                       Patient room 01 (door 3)
    6-10                                                       Patient room 02 (door 7)
    8-12  Nursing station (door 9, counter 10-12)
    10-14                                                      Interview room A (window 11, door 13)
    14-18 Records archive (door 17, badge)
    20                                  Ward-entry double door (N)

Walls shared between two spaces belong to exactly one asset (the corridor
owns corridor walls; room 01 owns the 01/02 party wall; interview room A
owns the 02/A party wall), painted appropriately on each face.

Outputs:
    assets/blender/clinical/FW_Chapter1_ClinicalWing.blend
    assets/exports/clinical/env/ENV_*.glb
    assets/renders/stage2/*.png
"""

import math
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
REPO = os.path.abspath(os.path.join(HERE, "..", ".."))

import bpy  # noqa: E402
from mathutils import Vector  # noqa: E402

import fw_assets as A  # noqa: E402
import fw_lib as L  # noqa: E402
from fw_lib import WALL_H, WALL_T, MeshBuilder  # noqa: E402

BLEND = os.path.join(REPO, "assets/blender/clinical/FW_Chapter1_ClinicalWing.blend")
EXPORT_DIR = os.path.join(REPO, "assets/exports/clinical/env")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage2")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = "v1 geometry complete; untextured PBR (Stage 8: textures/UVs)"
D90 = math.pi / 2
FAST = "--fast" in sys.argv  # Skip renders (CI / quick rebuilds).

PREVIEW = None  # Collection for unexported preview lights/backdrops.


# --------------------------------------------------------------------------
# Helpers
# --------------------------------------------------------------------------

def env_root(coll, asset_id, name):
    return L.empty(asset_id, coll, display="ARROWS", size=0.6,
                   props={"category": "environment", "display_name": name,
                          "frame": "Chapter 1 shared frame: place at the Godot origin"})


def wall_with_collision(mb, coll, root, p, q, tag, **kwargs):
    solid, _doors = A.wall_run(mb, p, q, **kwargs)
    p, q = Vector((p[0], p[1], 0)), Vector((q[0], q[1], 0))
    d = (q - p).normalized()
    theta = math.atan2(d.y, d.x)
    for i, (a, b) in enumerate(solid):
        mid = p + d * ((a + b) / 2)
        L.collision_box("%s_COL_%s%d" % (root.name, tag, i), coll, root, (b - a, WALL_T, WALL_H),
                        (mid.x, mid.y, WALL_H / 2), rot=(0, 0, theta))


def set_props(ob, props):
    for key, value in props.items():
        ob[key] = value
    return ob


def place(builder, coll, root, name, loc, rot_z_deg=0.0):
    ob = builder(coll, loc=loc, rot=(0, 0, math.radians(rot_z_deg)))
    ob.name = name
    ob.parent = root
    return ob


def door(coll, root, name, kind, loc, rot_z, door_id, access="", note=""):
    asset = {"interior": "DOOR_Interior_Single_1000", "secure_single": "DOOR_Secure_Single_1200",
             "secure_double": "DOOR_Secure_Double_1800", "service_historic": "DOOR_Service_Historic_1200"}[kind]
    d = A.build_door(coll, asset, kind, loc=loc, rot=(0, 0, rot_z))
    d.name, d.parent = name, root
    d["door_id"] = door_id
    d["required_access"] = access
    d["gameplay_note"] = note
    return d


def lightmark(coll, root, name, loc, range_m=6.0, watts=45.0, size=(0.5, 1.0), color="#FFF4E5"):
    return L.light_marker(name, coll, root, loc, kind="omni", range_m=range_m, color=color,
                          preview_coll=PREVIEW, preview_size=size, preview_watts=watts)


def add_preview_light(name, loc, watts, size=(0.4, 0.4), color="#FFF4E5"):
    data = bpy.data.lights.new(name, "AREA")
    data.shape = "RECTANGLE"
    data.size, data.size_y = size
    data.energy = watts
    data.color = L.srgb_to_linear(color)[:3]
    ob = bpy.data.objects.new(name, data)
    PREVIEW.objects.link(ob)
    ob.location = loc


def room_shell(coll, root, x0, x1, y0, y1, paint, floor_mat, walls, lights=(), solid_ceiling=False,
               floor_extend=None):
    """Floor + ceiling + the walls listed in `walls` ({side: kwargs}).
    Sides not listed are owned by a neighbour. Lights: (cx, cy, sx, sy)."""
    fx0, fx1, fy0, fy1 = floor_extend or (x0, x1, y0, y1)
    mb, cmb = MeshBuilder(), MeshBuilder()
    A.add_floor(mb, fx0, fx1, fy0, fy1, floor_mat)
    if solid_ceiling:
        cmb.box((x1 - x0 - 0.2, y1 - y0 - 0.2, 0.02), ((x0 + x1) / 2, (y0 + y1) / 2, WALL_H + 0.01), "M_Ceiling_Tile")
    else:
        A.add_ceiling(cmb, x0 + 0.1, x1 - 0.1, y0 + 0.1, y1 - 0.1, lights=lights)
    runs = {"south": ((x1, y0), (x0, y0)), "north": ((x0, y1), (x1, y1)),
            "east": ((x1, y1), (x1, y0)), "west": ((x0, y0), (x0, y1))}
    for side, kwargs in walls.items():
        kw = dict(front_mat=paint)
        kw.update(kwargs)
        wall_with_collision(mb, coll, root, runs[side][0], runs[side][1], side.capitalize(), **kw)
    mb.build(root.name + "_Architecture", coll, root)
    cmb.build(root.name + "_Ceiling", coll, root)
    L.collision_box(root.name + "_COL_Floor", coll, root, (fx1 - fx0, fy1 - fy0, 0.1),
                    ((fx0 + fx1) / 2, (fy0 + fy1) / 2, -0.05))
    for cx, cy, sx, sy in lights:
        lightmark(coll, root, "LIGHTMARK_%s_%d_%d" % (root.name.replace("ENV_", ""), int(cx * 10), int(cy * 10)),
                  (cx, cy, WALL_H - 0.1), size=(sx, sy), watts=55)


# --------------------------------------------------------------------------
# Corridor
# --------------------------------------------------------------------------

WEST_DOORS = {2: (1.0, 1.0), 4: (1.0, 1.0), 8: (1.0, 1.2)}      # slice: (x, width)
EAST_DOORS = {1: (1.0, 1.2), 3: (1.0, 1.2), 6: (1.0, 1.2)}
WEST_BACK = {1: "M_Wall_OfficeSage", 2: "M_Wall_OfficeSage", 4: "M_Wall_NurseStation", 5: "M_Wall_NurseStation",
             7: "M_Wall_Archive", 8: "M_Wall_Archive"}
EAST_BACK = {1: "M_Wall_PatientRoom", 2: "M_Wall_PatientRoom", 3: "M_Wall_PatientRoom", 4: "M_Wall_PatientRoom",
             5: "M_Wall_InterviewBlueGrey", 6: "M_Wall_InterviewBlueGrey"}


def build_corridor(coll):
    root = env_root(coll, "ENV_ClinicalCorridor_20m", "Main clinical corridor, 20 m")
    mb, cmb = MeshBuilder(), MeshBuilder()
    for i in range(10):
        y0 = 2.0 * i
        kwargs = dict(light=(i % 2 == 0), vent=(i % 2 == 1), west_back=WEST_BACK.get(i, "M_Wall_WarmWhite"),
                      east_back=EAST_BACK.get(i, "M_Wall_WarmWhite"))
        if i in WEST_DOORS:
            kwargs["west"] = A.door_opening(*WEST_DOORS[i])
        if i in EAST_DOORS:
            kwargs["east"] = A.door_opening(*EAST_DOORS[i])
        if i == 5:  # Nursing-station counter (open below a glazed screen) and observation window.
            kwargs["west"] = A.window_opening(1.0, 1.8, 1.05, 2.2, glass=None)
            kwargs["east"] = A.window_opening(1.0, 1.2, 1.0, 2.0, "M_Mirror_OneWay_Room", "M_Glass_OneWay_Observer")
        with mb.at((0, y0, 0)), cmb.at((0, y0, 0)):
            A.corridor_slice(mb, 2.0, ceiling_mb=cmb, **kwargs)
        if i % 2 == 0:
            lightmark(coll, root, "LIGHTMARK_Corridor_%02d" % i, (0, y0 + 1.0, WALL_H - 0.1))
    mb.box((0.012, 1.7, 0.75), (-1.5, 11.0, 1.78), "M_Glass_Clear")       # Nurse-station screen glass.
    mb.box((0.36, 1.8, 0.03), (-1.5, 11.0, 1.065), "M_Wood_Laminate_Desk")  # Transaction ledge.
    wall_with_collision(mb, coll, root, (1.5, 0.0), (-1.5, 0.0), "South", protected_front=True,
                        openings=[A.door_opening(1.5, 1.2)])
    wall_with_collision(mb, coll, root, (-1.5, 20.0), (1.5, 20.0), "North", protected_front=True,
                        openings=[A.door_opening(1.5, 1.8)])
    for x, y in ((-1.5, 0), (1.5, 0), (-1.5, 20), (1.5, 20)):
        A.corner_post(mb, x, y)
    mb.build("ENV_ClinicalCorridor_20m_Architecture", coll, root)
    cmb.build("ENV_ClinicalCorridor_20m_Ceiling", coll, root)

    L.collision_box("ENV_ClinicalCorridor_20m_COL_Floor", coll, root, (3.2, 20.0, 0.1), (0, 10.0, -0.05))
    for side, x, doors in (("West", -1.5, WEST_DOORS), ("East", 1.5, EAST_DOORS)):
        gaps = sorted((2.0 * i + dx - w / 2, 2.0 * i + dx + w / 2) for i, (dx, w) in doors.items())
        cursor, j = 0.0, 0
        for a, b in gaps + [(20.0, 20.0)]:
            L.collision_box("ENV_ClinicalCorridor_20m_COL_%s%d" % (side, j), coll, root,
                            (WALL_T, a - cursor, WALL_H), (x, (cursor + a) / 2, WALL_H / 2))
            cursor, j = b, j + 1

    door(coll, root, "Door_Office", "interior", (-1.5, 5.0, 0), D90, "door_office")
    door(coll, root, "Door_NurseStation", "interior", (-1.5, 9.0, 0), D90, "door_nurse_station")
    door(coll, root, "Door_Archive", "secure_single", (-1.5, 17.0, 0), D90, "door_archive",
         "access_records_archive", "Locked until the charge nurse issues the archive badge.")
    door(coll, root, "Door_PatientRoom01", "secure_single", (1.5, 3.0, 0), -D90, "door_patient_01")
    door(coll, root, "Door_PatientRoom02", "secure_single", (1.5, 7.0, 0), -D90, "door_patient_02")
    door(coll, root, "Door_InterviewA", "secure_single", (1.5, 13.0, 0), -D90, "door_interview")
    door(coll, root, "Door_WardEntry", "secure_double", (0.0, 20.0, 0), 0.0, "door_ward_entry",
         "access_ward_entry", "Exit to the wider hospital (out of Chapter 1 scope).")
    door(coll, root, "Door_W0B", "service_historic", (0.0, 0.0, 0), math.pi, "door_w0b",
         "access_ward_zero", "Sealed historic service door labelled W0-B.")
    # W0-B seal (a toggleable state; canonical geometry unchanged when removed).
    seal = MeshBuilder()
    seal.box((1.5, 0.05, 0.12), (0.0, 0.16, 1.1), "M_Steel_Painted_Grey")
    for x in (-0.68, 0.68):
        seal.box((0.06, 0.08, 0.2), (x, 0.13, 1.1), "M_Steel_Brushed")
    seal.box((0.07, 0.03, 0.09), (0.25, 0.2, 1.02), "M_Steel_Brushed")
    seal.box((0.32, 0.004, 0.18), (0.0, 0.112, 1.55), "M_Safety_Red")
    ob = seal.build("W0B_Seal_Sealed", coll, root, bevel=0.003)
    set_props(ob, {"state_group": "w0b_seal", "state": "sealed", "default_visible": True})

    place(A.prop_clock_caged, coll, root, "Corridor_Clock", (-1.394, 7.0, 2.25), 90)
    place(A.prop_camera_dome, coll, root, "Corridor_CCTV_South", (-0.9, 3.0, WALL_H), 0)
    place(A.prop_camera_dome, coll, root, "Corridor_CCTV_North", (0.9, 16.0, WALL_H), 0)
    place(A.prop_intercom, coll, root, "WardEntry_Intercom", (1.394, 19.2, 1.4), -90)
    place(A.prop_reader, coll, root, "WardEntry_Reader", (1.394, 19.65, 1.1), -90)
    place(A.prop_reader, coll, root, "InterviewA_Reader", (1.394, 13.85, 1.1), -90)
    place(A.prop_reader, coll, root, "Archive_Reader", (-1.394, 17.85, 1.1), 90)
    set_props(place(A.prop_intercom, coll, root, "W0B_AccessPanel", (-1.394, 0.85, 1.35), 90),
              {"godot_hint": "Security access log terminal for the W0-B door (clue_access)."})
    for name, loc, rot in (("Sign_Office", (-1.394, 4.25, 1.5), 90), ("Sign_NurseStation", (-1.394, 8.25, 1.5), 90),
                           ("Sign_Archive", (-1.394, 16.15, 1.5), 90), ("Sign_PatientRoom01", (1.394, 2.15, 1.5), -90),
                           ("Sign_PatientRoom02", (1.394, 6.15, 1.5), -90), ("Sign_InterviewA", (1.394, 12.15, 1.5), -90),
                           ("Sign_W0B", (0.95, 0.106, 1.6), 180)):
        place(A.prop_sign_room, coll, root, name, loc, rot)
    for state, visible in (("Open", True), ("Closed", False)):
        smb = MeshBuilder()
        smb.box((0.04, 1.3, 0.06), (1.37, 11.0, 2.05), "M_Steel_Painted_Grey")
        if state == "Closed":
            z = 1.98
            while z > 1.02:
                smb.box((0.002, 1.18, 0.028), (1.375, 11.0, z), "M_Steel_Painted_Grey")
                z -= 0.03
        ob = smb.build("OBS_Shutter_" + state, coll, root)
        set_props(ob, {"state_group": "interviewA_observation_shutter", "state": state.lower(),
                   "default_visible": visible})
    L.empty("MARK_PlayerSpawn", coll, root, (0.0, 1.6, 0.0), (0, 0, 0), display="SINGLE_ARROW", size=0.5,
            props={"marker_type": "spawn", "faces": "+Y (north, down the corridor)"})
    L.camera_marker("CAM_CR_Overview", coll, root, (0.0, 0.7, 1.65), (0.0, 20.0, 1.35), 22)
    L.camera_marker("CAM_CR_W0B", coll, root, (0.4, 5.5, 1.65), (0.0, 0.0, 1.2), 30,
                    props={"shot": "looking south at the sealed W0-B door"})
    L.camera_marker("CAM_IR_ObservationWindow", coll, root, (0.4, 11.0, 1.6), (4.5, 12.0, 1.1), 30,
                    props={"purpose": "Observer view into Interview Room A through one-way glass"})
    return root


# --------------------------------------------------------------------------
# Rooms
# --------------------------------------------------------------------------

def build_interview_room(coll):
    root = env_root(coll, "ENV_InterviewRoom_A", "Psychiatric interview room A")
    paint = "M_Wall_InterviewBlueGrey"
    room_shell(coll, root, 1.5, 5.5, 10.0, 14.0, paint, "M_Floor_Vinyl_Interview",
               {"south": dict(back_mat="M_Wall_PatientRoom"), "north": {}, "east": {}},
               solid_ceiling=True, floor_extend=(1.6, 5.6, 10.1, 14.1))
    pm = MeshBuilder()
    A.corner_post(pm, 5.5, 10.0)
    A.corner_post(pm, 5.5, 14.0)
    pm.build("ENV_InterviewRoom_A_Posts", coll, root)

    place(A.prop_table_interview, coll, root, "IR_Table", (3.5, 12.0, 0), 0)
    place(A.prop_chair_interview, coll, root, "IR_Chair_Psychiatrist", (2.55, 12.0, 0), 90)
    place(A.prop_chair_interview, coll, root, "IR_Chair_Patient", (4.45, 12.0, 0), -90)
    place(A.prop_duress_strip, coll, root, "IR_DuressStrip", (2.2, 13.9, 1.1), 0)
    place(A.prop_clock_caged, coll, root, "IR_Clock", (5.4, 12.0, 2.2), -90)
    place(A.prop_acoustic_panel, coll, root, "IR_Acoustic_South", (3.5, 10.1, 1.6), 180)
    place(A.prop_acoustic_panel, coll, root, "IR_Acoustic_North", (3.6, 13.9, 1.85), 0)
    place(A.prop_camera_dome, coll, root, "IR_CCTV", (5.1, 10.45, WALL_H), 0)
    place(A.prop_vent_grille, coll, root, "IR_Vent", (5.4, 10.9, 2.65), -90)
    place(A.prop_intercom, coll, root, "IR_Intercom", (1.6, 12.15, 1.4), 90)
    for i, x in enumerate((2.75, 4.25)):
        place(A.prop_light_vandal, coll, root, "IR_Light_%d" % i, (x, 12.0, WALL_H), 0)
        add_preview_light("IR_Light_%d_preview" % i, (x, 12.0, WALL_H - 0.08), 70, (0.35, 0.35))

    psych_eye, patient_eye = (2.45, 12.0, 1.22), (4.55, 12.0, 1.22)
    L.empty("MARK_Seat_Psychiatrist", coll, root, (2.55, 12.0, 0.45), (0, 0, -D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "+X (towards patient)"})
    L.empty("MARK_Seat_Patient", coll, root, (4.45, 12.0, 0.45), (0, 0, D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "-X (towards psychiatrist)"})
    L.empty("MARK_Eye_Psychiatrist", coll, root, psych_eye, display="SPHERE", size=0.05,
            props={"marker_type": "eye_line", "height_m": 1.22})
    L.empty("MARK_Eye_Patient", coll, root, patient_eye, display="SPHERE", size=0.05,
            props={"marker_type": "eye_line", "height_m": 1.22})
    L.empty("MARK_Standing_Staff_Door", coll, root, (1.95, 10.6, 0), (0, 0, -D90 / 2), display="SINGLE_ARROW",
            size=0.4, props={"marker_type": "standing", "use": "orderly / second staff member"})
    L.camera_marker("CAM_IR_Establishing", coll, root, (1.85, 10.35, 2.45), (4.3, 12.4, 0.85), 18)
    L.camera_marker("CAM_IR_OTS_OnPatient", coll, root, (1.95, 11.68, 1.36), patient_eye, 40,
                    props={"shot": "over psychiatrist's right shoulder onto patient"})
    L.camera_marker("CAM_IR_OTS_OnPsychiatrist", coll, root, (5.05, 12.32, 1.36), psych_eye, 40,
                    props={"shot": "over patient's right shoulder onto psychiatrist"})
    L.camera_marker("CAM_IR_CU_Patient", coll, root, (3.05, 11.82, 1.26), patient_eye, 70,
                    props={"shot": "close-up on patient, psychiatrist eye line"})
    L.camera_marker("CAM_IR_CU_Psychiatrist", coll, root, (3.95, 12.18, 1.26), psych_eye, 70,
                    props={"shot": "close-up on psychiatrist, patient eye line"})
    return root


def build_office(coll):
    root = env_root(coll, "ENV_PsychiatristOffice", "Psychiatrist's office")
    room_shell(coll, root, -6.0, -1.5, 2.0, 6.0, "M_Wall_OfficeSage", "M_Floor_Vinyl_WoodOffice",
               {"south": {}, "north": {}, "west": dict(openings=[A.window_opening(2.0, 1.6, 0.9, 2.3)])},
               lights=[(-4.25, 3.25, 1.0, 0.5), (-4.25, 4.75, 1.0, 0.5)], floor_extend=(-6.1, -1.6, 1.9, 6.1))
    pm = MeshBuilder()
    A.corner_post(pm, -6.0, 2.0)
    A.corner_post(pm, -6.0, 6.0)
    pm.build("ENV_PsychiatristOffice_Posts", coll, root)
    blinds = MeshBuilder()
    blinds.box((0.05, 1.5, 0.05), (-5.84, 4.0, 2.22), "M_Steel_Painted_White")
    z = 2.17
    while z > 1.6:
        blinds.box((0.028, 1.48, 0.002), (-5.84, 4.0, z), "M_Steel_Painted_White", rot=(0, 0.5, 0))
        z -= 0.03
    blinds.build("OF_WindowBlinds", coll, root)["godot_hint"] = "Half-lowered venetian blind; hide to fully raise."

    place(A.prop_desk_clinical, coll, root, "OF_Desk", (-4.45, 4.0, 0), -90)
    place(A.prop_chair_office, coll, root, "OF_Chair_Psychiatrist", (-5.15, 4.0, 0), 90)
    place(A.prop_chair_visitor, coll, root, "OF_Chair_Visitor_1", (-3.45, 3.5, 0), -90)
    place(A.prop_chair_visitor, coll, root, "OF_Chair_Visitor_2", (-3.45, 4.5, 0), -90)
    place(A.prop_terminal_ehr, coll, root, "OF_Terminal_EHR", (-4.6, 3.7, 0.75), -90)
    place(A.prop_phone, coll, root, "OF_Phone", (-4.4, 4.55, 0.75), -90)
    place(A.prop_folder_chart, coll, root, "OF_Document_TransferSummary", (-4.2, 3.25, 0.75), -70)
    place(A.prop_filing_cabinet, coll, root, "OF_FilingCabinet", (-5.45, 5.55, 0), 0)
    place(A.prop_bookcase, coll, root, "OF_Bookcase", (-3.1, 2.28, 0), 180)
    place(A.prop_bin, coll, root, "OF_Bin", (-5.3, 4.95, 0), 0)
    place(A.prop_clock_caged, coll, root, "OF_Clock", (-3.6, 5.9, 2.2), 0)
    place(A.prop_certificate, coll, root, "OF_Certificate_1", (-4.75, 2.1, 1.6), 180)
    place(A.prop_certificate, coll, root, "OF_Certificate_2", (-4.25, 2.1, 1.6), 180)
    place(A.prop_vent_grille, coll, root, "OF_Vent", (-2.6, 5.9, 2.65), 0)
    L.empty("MARK_Seat_Psychiatrist_Desk", coll, root, (-5.15, 4.0, 0.45), (0, 0, -D90), display="SINGLE_ARROW",
            size=0.4, props={"marker_type": "seat"})
    L.empty("MARK_Character_DrVoss", coll, root, (-3.0, 5.2, 0.0), (0, 0, math.radians(150)), display="SINGLE_ARROW",
            size=0.5, props={"marker_type": "character", "character_id": "staff_voss"})
    L.camera_marker("CAM_OF_Establishing", coll, root, (-1.95, 2.45, 2.2), (-4.6, 4.6, 0.9), 20)
    L.camera_marker("CAM_OF_EHR_Closeup", coll, root, (-5.2, 3.7, 1.2), (-4.6, 3.7, 1.13), 35,
                    props={"shot": "seated view of the EHR screen"})
    card = MeshBuilder()
    card.box((0.02, 6.0, 4.0), (-7.5, 4.0, 1.6), "M_Exterior_Backdrop")
    card.build("BG_ExteriorCard_preview", PREVIEW)
    return root


def build_nurse_station(coll):
    root = env_root(coll, "ENV_NursingStation", "Nursing station (glazed counter onto the corridor)")
    room_shell(coll, root, -5.0, -1.5, 8.0, 12.0, "M_Wall_NurseStation", "M_Floor_Vinyl_Corridor",
               {"south": {}, "north": {}, "west": {}},
               lights=[(-3.25, 9.25, 1.0, 0.5), (-3.25, 10.75, 1.0, 0.5)], floor_extend=(-5.1, -1.6, 7.9, 12.1))
    pm = MeshBuilder()
    A.corner_post(pm, -5.0, 8.0)
    A.corner_post(pm, -5.0, 12.0)
    pm.build("ENV_NursingStation_Posts", coll, root)
    place(A.prop_desk_clinical, coll, root, "NS_Desk", (-2.0, 11.0, 0), -90)
    place(A.prop_chair_office, coll, root, "NS_Chair_1", (-2.75, 10.6, 0), 90)
    place(A.prop_chair_office, coll, root, "NS_Chair_2", (-2.85, 11.55, 0), 70)
    place(A.prop_terminal_ehr, coll, root, "NS_Terminal_EHR", (-2.15, 10.7, 0.75), -90)
    place(A.prop_phone, coll, root, "NS_Phone", (-1.95, 11.6, 0.75), -90)
    place(A.prop_folder_chart, coll, root, "NS_Chart_1", (-1.85, 10.25, 0.75), -100)
    place(A.prop_folder_chart, coll, root, "NS_Chart_2", (-1.86, 10.27, 0.765), -96)
    place(A.prop_filing_cabinet, coll, root, "NS_FilingCabinet_1", (-4.7, 11.4, 0), 90)
    place(A.prop_filing_cabinet, coll, root, "NS_FilingCabinet_2", (-4.7, 10.85, 0), 90)
    place(A.prop_noticeboard, coll, root, "NS_NoticeBoard", (-3.4, 11.9, 1.5), 0)
    place(A.prop_clock_caged, coll, root, "NS_Clock", (-3.3, 8.1, 2.2), 180)
    place(A.prop_bin, coll, root, "NS_Bin", (-4.6, 8.4, 0), 0)
    place(A.prop_camera_dome, coll, root, "NS_CCTV", (-4.6, 8.4, WALL_H), 0)
    L.empty("MARK_Character_NurseBennett", coll, root, (-2.25, 11.0, 0.0), (0, 0, -D90), display="SINGLE_ARROW",
            size=0.5, props={"marker_type": "character", "character_id": "staff_bennett",
                             "faces": "+X (across the counter into the corridor)"})
    L.camera_marker("CAM_NS_Establishing", coll, root, (-4.7, 8.35, 2.3), (-2.0, 11.0, 0.8), 20)
    return root


def build_archive(coll):
    root = env_root(coll, "ENV_RecordsArchive", "Records archive (badge access)")
    room_shell(coll, root, -5.5, -1.5, 14.0, 18.0, "M_Wall_Archive", "M_Floor_Vinyl_Corridor",
               {"south": {}, "north": {}, "west": {}}, lights=[(-3.5, 15.25, 1.0, 0.5), (-3.5, 16.75, 1.0, 0.5)],
               floor_extend=(-5.6, -1.6, 13.9, 18.1))
    pm = MeshBuilder()
    A.corner_post(pm, -5.5, 14.0)
    A.corner_post(pm, -5.5, 18.0)
    pm.build("ENV_RecordsArchive_Posts", coll, root)
    place(A.prop_shelving_archive, coll, root, "AR_Shelving_W1", (-5.15, 15.05, 0), 90)
    place(A.prop_shelving_archive, coll, root, "AR_Shelving_W2", (-5.15, 16.95, 0), 90)
    place(A.prop_shelving_archive, coll, root, "AR_Shelving_Mid", (-3.75, 15.3, 0), -90)
    place(A.prop_shelving_archive, coll, root, "AR_Shelving_N", (-3.2, 17.65, 0), 0)
    place(A.prop_desk_clinical, coll, root, "AR_ReadingDesk", (-2.55, 14.75, 0), 180)
    place(A.prop_chair_visitor, coll, root, "AR_Chair", (-2.55, 15.5, 0), 0)
    set_props(place(A.prop_folder_chart, coll, root, "AR_Document_WardRoster1968", (-2.4, 14.7, 0.75), 15),
              {"godot_hint": "Pickup for clue_roster (1968 ward roster)."})
    place(A.prop_camera_dome, coll, root, "AR_CCTV", (-1.9, 14.4, WALL_H), 0)
    L.camera_marker("CAM_AR_Establishing", coll, root, (-1.8, 17.7, 2.3), (-3.6, 15.0, 0.7), 20)
    return root


def build_patient_room(coll, number, y0, owns_north):
    rid = "ENV_PatientRoom_%02d" % number
    root = env_root(coll, rid, "Patient bedroom %02d (single, anti-ligature)" % number)
    walls = {"east": dict(openings=[A.window_opening(2.0, 1.0, 0.9, 2.0)])}
    if number == 1:
        walls["south"] = {}
    if owns_north:
        walls["north"] = dict(back_mat="M_Wall_PatientRoom")
    room_shell(coll, root, 1.5, 5.0, y0, y0 + 4.0, "M_Wall_PatientRoom", "M_Floor_Vinyl_Interview", walls,
               solid_ceiling=True, floor_extend=(1.6, 5.1, y0 + (-0.1 if number == 1 else 0.0), y0 + 4.0))
    pm = MeshBuilder()
    A.corner_post(pm, 5.0, y0 + 4.0)
    if number == 1:
        A.corner_post(pm, 5.0, y0)
    pm.build(rid + "_Posts", coll, root)
    p = "PR%02d_" % number
    place(A.prop_bed_antiligature, coll, root, p + "Bed", (4.1, y0 + 2.85, 0), 0)
    place(A.prop_wardrobe_antiligature, coll, root, p + "Wardrobe", (4.4, y0 + 0.38, 0), 180)
    place(A.prop_light_vandal, coll, root, p + "Light", (3.25, y0 + 2.0, WALL_H), 0)
    add_preview_light(p + "Light_preview", (3.25, y0 + 2.0, WALL_H - 0.08), 60, (0.35, 0.35))
    place(A.prop_vent_grille, coll, root, p + "Vent", (2.2, y0 + 3.9, 2.65), 0)
    L.empty("MARK_Bed_%02d" % number, coll, root, (4.1, y0 + 2.85, 0.5), (0, 0, 0), display="SINGLE_ARROW",
            size=0.4, props={"marker_type": "patient_bed"})
    L.camera_marker("CAM_PR%02d_Establishing" % number, coll, root, (1.75, y0 + 0.35, 2.3), (4.3, y0 + 2.6, 0.5), 18)
    card = MeshBuilder()
    card.box((0.02, 4.0, 3.0), (6.5, y0 + 2.0, 1.5), "M_Exterior_Backdrop")
    card.build(p + "ExteriorCard_preview", PREVIEW)
    return root


# --------------------------------------------------------------------------

def main():
    global PREVIEW
    L.reset_scene()
    scene = bpy.context.scene
    wing = L.collection("FW_Chapter1_ClinicalWing")
    PREVIEW = L.collection("PREVIEW_ONLY_not_exported")
    envs = [
        (build_corridor(L.collection("ENV_ClinicalCorridor_20m", wing)),
         "Chapter 1: main clinical corridor (spawn, all room doors, W0-B, ward entry)"),
        (build_interview_room(L.collection("ENV_InterviewRoom_A", wing)), "Chapter 1: Elias Ward interview"),
        (build_office(L.collection("ENV_PsychiatristOffice", wing)), "Chapter 1: player's office / EHR workstation"),
        (build_nurse_station(L.collection("ENV_NursingStation", wing)), "Chapter 1: charge nurse (Bennett) station"),
        (build_archive(L.collection("ENV_RecordsArchive", wing)), "Chapter 1: archive, 1968 roster clue"),
        (build_patient_room(L.collection("ENV_PatientRoom_01", wing), 1, 2.0, True), "Chapter 1: patient bedroom"),
        (build_patient_room(L.collection("ENV_PatientRoom_02", wing), 2, 6.0, False), "Chapter 1: patient bedroom"),
    ]

    for root, _ in envs:
        lo, hi = L.world_bounds(root)
        assert 3.0 < max(hi - lo) < 25.0, (root.name, tuple(hi - lo))
        assert any(o.name.startswith("CAM_") for o in L.descendants(root)), root.name + " has no camera markers"
        assert any(o.name.endswith("-colonly") for o in L.descendants(root)), root.name + " has no collision"
    psych = bpy.data.objects["IR_Chair_Psychiatrist"].location
    patient = bpy.data.objects["IR_Chair_Patient"].location
    assert (psych - Vector((1.5, 13.0, 0))).length < (patient - Vector((1.5, 13.0, 0))).length, \
        "clinician must sit nearer the exit"

    L.save_blend(BLEND)
    records = []
    for root, location in envs:
        path = os.path.join(EXPORT_DIR, root.name + ".glb")
        L.export_glb(root, path)
        records.append(L.asset_record(
            root, BLEND, path, location, "Floor + wall + furniture box colliders; door leaves carry their own",
            "Place at the Godot origin (shared Chapter 1 frame). CAM_* framing references; MARK_* forward = "
            "Godot -Z; LIGHTMARK_* light positions; *_Ceiling is a separate mesh; state nodes carry "
            "state_group/state/default_visible extras.", STATUS, REPO))
    L.write_manifest(records, MANIFEST)
    if FAST:
        print("STAGE2 OK (fast): %d environments exported" % len(records))
        return

    for name in ("OBS_Shutter_Closed",):
        bpy.data.objects[name].hide_render = True
    L.setup_render(scene, 1280, 720, samples=40)
    shots = (("CAM_CR_Overview", "corridor_20m.png"), ("CAM_CR_W0B", "corridor_w0b_door.png"),
             ("CAM_IR_Establishing", "interview_room_a.png"), ("CAM_IR_OTS_OnPatient", "interview_room_a_ots.png"),
             ("CAM_OF_Establishing", "psychiatrist_office.png"), ("CAM_NS_Establishing", "nursing_station.png"),
             ("CAM_AR_Establishing", "records_archive.png"), ("CAM_PR01_Establishing", "patient_room_01.png"))
    for cam_name, out in shots:
        L.render_from(scene, bpy.data.objects[cam_name], os.path.join(RENDER_DIR, out))

    # Plan view: hide ceilings and lights, look straight down.
    for ob in bpy.data.objects:
        if ob.name.endswith("_Ceiling") or "Light" in ob.name or ob.name.endswith("_preview") or "CCTV" in ob.name:
            ob.hide_render = True
    sun = bpy.data.lights.new("PlanSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PlanSun", sun)
    PREVIEW.objects.link(sun_ob)
    plan = L.camera_marker("PlanCam_preview", PREVIEW, None, (0.0, 10.0, 30.0), (0.0, 10.0, 0.0), 30)
    plan.data.type = "ORTHO"
    plan.data.ortho_scale = 22.0
    scene.render.resolution_x, scene.render.resolution_y = 1000, 1100
    L.render_from(scene, plan, os.path.join(RENDER_DIR, "chapter1_plan.png"))
    print("STAGE2 OK: %d environments exported" % len(records))


if __name__ == "__main__":
    main()
