"""Stage 4a: security and administration wing, plus its props library.

The wing continues the Chapter 1 shared frame north of the clinical
corridor's ward-entry double door (y = 20), so every ENV_* still goes at the
Godot origin. Layout (wall centrelines, metres):

    y      west side (x -6 .. -1.5)        corridor (x +/-1.5)        east side (x 1.5 .. 6)
    20-24  Visitor screening (entry W)     ward-entry door (S, y 20)  Secure interview suite
    24-28  Credentialing and access                                   Security control room
    28-32  Records office                                             (window onto corridor)
    32     ------------------------------- security interlock door -------------------------
    32-36  Medical director's office                                  Surveillance monitoring
    36-40  Administrative conference                                  Maintenance access
    40-44                                  Restricted elevator lobby (x -3 .. 3)

Walls shared between two spaces belong to exactly one asset: the corridor
owns both corridor walls, the interlock and the lobby door wall; each room
owns its south wall (and the last one in a row its north wall); the lobby
owns its west, east and north walls.

Outputs:
    assets/blender/security/FW_Props_Security.blend, assets/exports/security/props/*.glb
    assets/blender/security/FW_SecurityAdminWing.blend, assets/exports/security/env/ENV_*.glb
    assets/renders/stage4/*.png (skipped with --fast)
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

import build_stage2_chapter1 as S2  # noqa: E402  (room_shell, door, place, ... helpers)
import fw_assets as A  # noqa: E402
import fw_lib as L  # noqa: E402
from fw_lib import WALL_H, MeshBuilder  # noqa: E402

PROPS_BLEND = os.path.join(REPO, "assets/blender/security/FW_Props_Security.blend")
WING_BLEND = os.path.join(REPO, "assets/blender/security/FW_SecurityAdminWing.blend")
PROPS_DIR = os.path.join(REPO, "assets/exports/security/props")
ENV_DIR = os.path.join(REPO, "assets/exports/security/env")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage4")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = "v1 geometry complete; untextured PBR (Stage 8: textures/UVs)"
FAST = "--fast" in sys.argv
D90 = math.pi / 2
COLD = "#DCE8FF"      # Security lighting: desaturated cool white.
WARM = "#FFF4E5"

place, door, room_shell, env_root, set_props = S2.place, S2.door, S2.room_shell, S2.env_root, S2.set_props
wall_with_collision = S2.wall_with_collision

PROP_WALL_MOUNTED = {"PROP_VideoWall_3x2", "PROP_Cabinet_Keys_Wall", "PROP_Panel_Electrical", "PROP_Pipes_Wall_2m",
                     "PROP_Display_Wall_65", "PROP_Door_Elevator"}
PROP_LOCATIONS = {
    "PROP_Console_SecurityDesk": "Security control room, surveillance monitoring room",
    "PROP_VideoWall_3x2": "Security control and surveillance rooms",
    "PROP_Cabinet_Keys_Wall": "Security control room",
    "PROP_Lockers_Staff_4": "Security control room, visitor screening (visitor belongings)",
    "PROP_Detector_WalkThrough": "Visitor screening",
    "PROP_Table_Conference_3m": "Administrative conference room",
    "PROP_Seating_Waiting_3": "Visitor screening and waiting",
    "PROP_Desk_Executive": "Medical director's office",
    "PROP_Printer_Badge": "Credentialing and access office",
    "PROP_Door_Elevator": "Restricted elevator lobby",
    "PROP_Panel_Electrical": "Maintenance access area",
    "PROP_Pipes_Wall_2m": "Maintenance access area, service corridors",
    "PROP_Display_Wall_65": "Administrative conference room",
}


# --------------------------------------------------------------------------
# Props library
# --------------------------------------------------------------------------

def build_props():
    L.reset_scene()
    scene = bpy.context.scene
    coll = L.collection("FW_Props_Security")
    records = []
    for i, builder in enumerate(A.STAGE4_SECURITY_PROP_BUILDERS):
        root = builder(coll, loc=((i % 5) * 4.0, (i // 5) * 3.5, 0))
        has_col = any(o.name.endswith("-colonly") for o in L.descendants(root))
        origin = "wall surface (opening centre for the elevator)" if root.name in PROP_WALL_MOUNTED \
            else "floor centre (desk surface for the badge printer)"
        records.append((root, PROP_LOCATIONS[root.name],
                        "Box collider (-colonly)" if has_col else "Decorative: no collision",
                        "Staff-only / security-controlled areas (not patient-accessible). Origin: %s." % origin))
    for root, *_ in records:
        lo, hi = L.world_bounds(root)
        assert max(hi - lo) < 4.0, "%s too large" % root.name
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
            if root.name in PROP_WALL_MOUNTED and root.name != "PROP_Door_Elevator":
                root.location.z += 1.5
        L.setup_render(scene, 1600, 900, samples=24)
        sun = bpy.data.lights.new("PreviewSun", "SUN")
        sun.energy = 3.0
        sun_ob = bpy.data.objects.new("PreviewSun", sun)
        scene.collection.objects.link(sun_ob)
        sun_ob.rotation_euler = (math.radians(45), 0, math.radians(-25))
        ground = MeshBuilder()
        ground.box((40, 20, 0.02), (8.0, 3.5, -0.01), "M_Floor_Epoxy_Security")
        ground.build("PreviewGround", scene.collection)
        cam = L.camera_marker("PreviewCam", scene.collection, None, (8.0, -11.5, 7.5), (8.0, 3.6, 0.7), 24)
        L.render_from(scene, cam, os.path.join(RENDER_DIR, "props_security.png"))
    return len(manifest)


# --------------------------------------------------------------------------
# Wing
# --------------------------------------------------------------------------

def readers_and_sign(coll, root, prefix, x, y, side):
    """Card reader and room sign beside a corridor door at (x, y).
    side: -1 for the west corridor wall, +1 for the east one."""
    rot = 90 if side < 0 else -90
    face = x + (0.106 if side < 0 else -0.106)
    place(A.prop_reader, coll, root, prefix + "_Reader", (face, y + 0.85, 1.1), rot)
    place(A.prop_sign_room, coll, root, prefix + "_Sign", (face, y - 0.85, 1.5), rot)


def build_corridor(coll):
    root = env_root(coll, "ENV_SecurityCorridor_20m", "Controlled-access security corridor, 20 m, with interlock")
    paint = "M_Concrete_Grey"
    west = [A.door_opening(y - 20.0, w) for y, w in ((22.0, 1.2), (25.0, 1.2), (31.0, 1.0), (35.0, 1.0),
                                                       (38.0, 1.0))]
    east = [A.door_opening(40.0 - y, 1.2) for y in (22.5, 30.5, 33.0, 38.5)]
    east.append(A.window_opening(40.0 - 27.0, 3.0, 0.9, 2.1, glass="M_Glass_Reinforced"))
    lights = [(0.0, y, 0.6, 1.2) for y in (21.25, 23.75, 26.25, 28.75, 30.75, 33.25, 35.75, 38.25)]
    room_shell(coll, root, -1.5, 1.5, 20.0, 40.0, paint, "M_Floor_Epoxy_Security",
               {"west": dict(openings=west, back_mat="M_Wall_AdminTaupe"),
                "east": dict(openings=east, back_mat="M_Wall_SecurityBlueGrey")},
               lights=lights, floor_extend=(-1.6, 1.6, 20.0, 40.0), light_color=COLD)
    mb = MeshBuilder()
    wall_with_collision(mb, coll, root, (-1.5, 32.0), (1.5, 32.0), "Interlock", front_mat=paint, back_mat=paint,
                        openings=[A.door_opening(1.5, 1.8)])
    wall_with_collision(mb, coll, root, (-1.5, 40.0), (1.5, 40.0), "LobbyDoor", front_mat=paint, back_mat=paint,
                        openings=[A.door_opening(1.5, 1.8)])
    for x, y in ((-1.5, 32.0), (1.5, 32.0), (-1.5, 40.0), (1.5, 40.0)):
        A.corner_post(mb, x, y, paint)
    mb.build(root.name + "_CrossWalls", coll, root)

    door(coll, root, "Door_VisitorScreening", "secure_single", (-1.5, 22.0, 0), D90, "door_visitor_screening",
         "access_security_wing", "Visitors pass screening before entering the wing.")
    door(coll, root, "Door_Credentialing", "secure_single", (-1.5, 25.0, 0), D90, "door_credentialing",
         "access_admin")
    door(coll, root, "Door_RecordsOffice", "interior", (-1.5, 31.0, 0), D90, "door_records_office")
    door(coll, root, "Door_DirectorOffice", "interior", (-1.5, 35.0, 0), D90, "door_director_office")
    door(coll, root, "Door_Conference", "interior", (-1.5, 38.0, 0), D90, "door_conference")
    door(coll, root, "Door_SecureInterview", "secure_single", (1.5, 22.5, 0), -D90, "door_secure_interview",
         "access_security_wing")
    door(coll, root, "Door_SecurityControl", "secure_single", (1.5, 30.5, 0), -D90, "door_security_control",
         "access_security_control", "Hale's team only; the player needs an escort or a granted badge.")
    door(coll, root, "Door_Surveillance", "secure_single", (1.5, 33.0, 0), -D90, "door_surveillance",
         "access_security_control")
    door(coll, root, "Door_Maintenance", "secure_single", (1.5, 38.5, 0), -D90, "door_maintenance",
         "access_maintenance", "Price's maintenance key; leads to the service hatch.")
    door(coll, root, "Door_SecurityInterlock", "secure_double", (0.0, 32.0, 0), 0.0, "door_security_interlock",
         "access_security_wing", "Interlock between the public admin half and the restricted half.")
    door(coll, root, "Door_LiftLobby", "secure_double", (0.0, 40.0, 0), 0.0, "door_lift_lobby",
         "access_restricted_lift")

    for prefix, y in (("VisitorScreening", 22.0), ("Credentialing", 25.0), ("RecordsOffice", 31.0),
                      ("DirectorOffice", 35.0), ("Conference", 38.0)):
        readers_and_sign(coll, root, prefix, -1.5, y, -1)
    for prefix, y in (("SecureInterview", 22.5), ("SecurityControl", 30.5), ("Surveillance", 33.0),
                      ("Maintenance", 38.5)):
        readers_and_sign(coll, root, prefix, 1.5, y, 1)
    for name, y, rot in (("Interlock_Reader_S", 31.894, 0), ("Interlock_Reader_N", 32.106, 180),
                         ("LiftLobby_Reader", 39.894, 0)):
        place(A.prop_reader, coll, root, name, (1.2, y, 1.1), rot)
    place(A.prop_intercom, coll, root, "Interlock_Intercom", (-1.2, 31.894, 1.4), 0)
    for i, (x, y) in enumerate(((0.9, 21.0), (-0.9, 26.5), (0.9, 31.4), (-0.9, 32.6), (0.9, 37.0), (-0.9, 39.4))):
        place(A.prop_camera_dome, coll, root, "Corridor_CCTV_%d" % i, (x, y, WALL_H), 0)
    place(A.prop_clock_caged, coll, root, "Corridor_Clock", (-1.394, 28.0, 2.25), 90)
    place(A.prop_dispenser_handgel, coll, root, "Corridor_HandGel", (-1.394, 23.6, 1.2), 90)
    L.empty("MARK_Waypoint_WardEntry", coll, root, (0.0, 20.8, 0.0), (0, 0, 0), display="SINGLE_ARROW", size=0.5,
            props={"marker_type": "waypoint", "faces": "+Y (north into the security wing)"})
    L.camera_marker("CAM_SW_Corridor", coll, root, (0.0, 20.6, 1.65), (0.0, 32.0, 1.4), 24)
    L.camera_marker("CAM_SW_ControlWindow", coll, root, (-1.0, 25.0, 1.65), (3.5, 27.5, 1.3), 28,
                    props={"shot": "looking into the security control room through reinforced glass"})
    return root


def west_room(coll, asset_id, name, y0, paint, floor, lights, below_paint, owns_north=False, west_kwargs=None,
              solid_ceiling=False, light_color=WARM):
    root = env_root(coll, asset_id, name)
    walls = {"south": dict(back_mat=below_paint), "west": dict(back_mat="M_Concrete_Grey", **(west_kwargs or {}))}
    if owns_north:
        walls["north"] = dict(back_mat="M_Concrete_Grey")
    room_shell(coll, root, -6.0, -1.5, y0, y0 + 4.0, paint, floor, walls, lights=lights, solid_ceiling=solid_ceiling,
               floor_extend=(-6.1, -1.6, y0, y0 + 4.0 + (0.1 if owns_north else 0.0)), light_color=light_color)
    pm = MeshBuilder()
    A.corner_post(pm, -6.0, y0)
    if owns_north:
        A.corner_post(pm, -6.0, y0 + 4.0)
    pm.build(asset_id + "_Posts", coll, root)
    return root


def east_room(coll, asset_id, name, y0, y1, paint, floor, lights, below_paint, owns_north=False,
              solid_ceiling=False, light_color=COLD):
    root = env_root(coll, asset_id, name)
    walls = {"south": dict(back_mat=below_paint), "east": dict(back_mat="M_Concrete_Grey")}
    if owns_north:
        walls["north"] = dict(back_mat="M_Concrete_Grey")
    room_shell(coll, root, 1.5, 6.0, y0, y1, paint, floor, walls, lights=lights, solid_ceiling=solid_ceiling,
               floor_extend=(1.6, 6.1, y0, y1 + (0.1 if owns_north else 0.0)), light_color=light_color)
    pm = MeshBuilder()
    A.corner_post(pm, 6.0, y0)
    if owns_north:
        A.corner_post(pm, 6.0, y1)
    pm.build(asset_id + "_Posts", coll, root)
    return root


def panel_lights(cx, y0, y1, step=1.5):
    out, y = [], y0 + step / 2 + 0.25
    while y < y1 - 0.5:
        out.append((cx, y, 1.0, 0.5))
        y += step
    return out


def build_visitor_screening(coll):
    paint = "M_Wall_SecurityBlueGrey"
    root = west_room(coll, "ENV_VisitorScreening", "Visitor screening and waiting", 20.0, paint,
                     "M_Floor_Epoxy_Security", panel_lights(-3.75, 20.0, 24.0), "M_Concrete_Grey",
                     west_kwargs=dict(openings=[A.door_opening(2.0, 1.2)]), light_color=COLD)
    door(coll, root, "Door_VisitorEntry", "secure_single", (-6.0, 22.0, 0), D90, "door_visitor_entry",
         "access_visitor_entry", "From hospital reception (Stage 7).")
    place(A.prop_detector_walkthrough, coll, root, "VS_MetalDetector", (-4.7, 22.0, 0), 90)
    place(A.prop_desk_clinical, coll, root, "VS_ScreeningDesk", (-3.3, 21.2, 0), 0)
    place(A.prop_chair_office, coll, root, "VS_Chair_Officer", (-3.3, 20.5, 0), 180)
    place(A.prop_terminal_ehr, coll, root, "VS_Terminal_VisitorLog", (-3.3, 21.3, 0.75), 180)
    place(A.prop_lockers, coll, root, "VS_Lockers_VisitorBelongings", (-5.2, 20.36, 0), 180)
    place(A.prop_seating_waiting, coll, root, "VS_Seating_Waiting", (-4.2, 23.6, 0), 0)
    place(A.prop_duress_strip, coll, root, "VS_DuressStrip", (-2.3, 20.106, 1.1), 180)
    place(A.prop_camera_dome, coll, root, "VS_CCTV", (-2.0, 20.5, WALL_H), 0)
    place(A.prop_intercom, coll, root, "VS_Intercom_Entry", (-5.894, 23.1, 1.4), 90)
    place(A.prop_clock_caged, coll, root, "VS_Clock", (-2.6, 23.894, 2.2), 0)
    L.empty("MARK_Character_ScreeningOfficer", coll, root, (-3.3, 20.5, 0.0), (0, 0, 0), display="SINGLE_ARROW",
            size=0.5, props={"marker_type": "character", "character_id": "staff_security_officer",
                             "faces": "Godot -Z (north, across the desk)"})
    L.camera_marker("CAM_VS_Establishing", coll, root, (-1.9, 23.7, 2.3), (-4.6, 21.6, 0.9), 18)
    return root


def build_credentialing(coll):
    root = west_room(coll, "ENV_CredentialingOffice", "Staff credentialing and access office", 24.0,
                     "M_Wall_AdminTaupe", "M_Floor_Vinyl_Corridor", panel_lights(-3.75, 24.0, 28.0),
                     "M_Wall_SecurityBlueGrey")
    place(A.prop_desk_clinical, coll, root, "CR_Desk", (-4.45, 26.2, 0), -90)
    place(A.prop_chair_office, coll, root, "CR_Chair_Officer", (-5.15, 26.2, 0), 90)
    place(A.prop_chair_visitor, coll, root, "CR_Chair_Applicant", (-3.45, 26.2, 0), -90)
    place(A.prop_terminal_ehr, coll, root, "CR_Terminal_AccessControl", (-4.6, 25.9, 0.75), -90)
    place(A.prop_printer_badge, coll, root, "CR_BadgePrinter", (-4.35, 26.75, 0.75), -90)
    place(A.prop_filing_cabinet, coll, root, "CR_FilingCabinet_1", (-5.45, 27.55, 0), 0)
    place(A.prop_filing_cabinet, coll, root, "CR_FilingCabinet_2", (-4.95, 27.55, 0), 0)
    place(A.prop_noticeboard, coll, root, "CR_NoticeBoard_AccessLevels", (-3.6, 24.106, 1.5), 180)
    place(A.prop_clock_caged, coll, root, "CR_Clock", (-2.6, 27.894, 2.2), 0)
    place(A.prop_camera_dome, coll, root, "CR_CCTV", (-2.0, 27.5, WALL_H), 0)
    set_props(place(A.prop_folder_chart, coll, root, "CR_Document_BadgeLog", (-4.25, 25.6, 0.75), -80),
              {"godot_hint": "Badge issue log: which credentials were active on which night."})
    L.camera_marker("CAM_CR_Establishing", coll, root, (-1.9, 24.4, 2.3), (-4.6, 26.6, 0.9), 18)
    return root


def build_records_office(coll):
    root = west_room(coll, "ENV_RecordsOffice", "Administrative records office", 28.0, "M_Wall_AdminTaupe",
                     "M_Floor_Vinyl_Corridor", panel_lights(-3.75, 28.0, 32.0), "M_Wall_AdminTaupe")
    for i, y in enumerate((28.55, 29.05, 29.55, 30.05, 30.55)):
        place(A.prop_filing_cabinet, coll, root, "RO_FilingCabinet_%d" % i, (-5.6, y, 0), 90)
    place(A.prop_shelving_archive, coll, root, "RO_Shelving", (-4.0, 31.65, 0), 0)
    place(A.prop_desk_clinical, coll, root, "RO_Desk", (-2.8, 29.4, 0), -90)
    place(A.prop_chair_office, coll, root, "RO_Chair", (-3.5, 29.4, 0), 90)
    place(A.prop_terminal_ehr, coll, root, "RO_Terminal_Records", (-2.95, 29.1, 0.75), -90)
    place(A.prop_phone, coll, root, "RO_Phone", (-2.75, 29.95, 0.75), -90)
    set_props(place(A.prop_folder_chart, coll, root, "RO_Document_TransferLedger", (-2.7, 28.9, 0.75), -100),
              {"godot_hint": "Transfer ledger: patient moves between units (Act II)."})
    place(A.prop_camera_dome, coll, root, "RO_CCTV", (-2.0, 28.5, WALL_H), 0)
    place(A.prop_clock_caged, coll, root, "RO_Clock", (-3.75, 28.106, 2.2), 180)
    L.camera_marker("CAM_RO_Establishing", coll, root, (-1.9, 31.6, 2.3), (-4.6, 29.6, 0.8), 18)
    return root


def build_director_office(coll):
    root = west_room(coll, "ENV_MedicalDirectorOffice", "Medical director's office (Dr Voss)", 32.0,
                     "M_Wall_AdminTaupe", "M_Carpet_Admin", panel_lights(-3.75, 32.0, 36.0), "M_Wall_AdminTaupe",
                     west_kwargs=dict(openings=[A.window_opening(2.0, 1.6, 0.9, 2.3)]))
    place(A.prop_desk_executive, coll, root, "MD_Desk", (-4.4, 34.0, 0), 90)
    place(A.prop_chair_office, coll, root, "MD_Chair_Director", (-5.15, 34.0, 0), 90)
    place(A.prop_chair_visitor, coll, root, "MD_Chair_Visitor_1", (-3.35, 33.5, 0), -90)
    place(A.prop_chair_visitor, coll, root, "MD_Chair_Visitor_2", (-3.35, 34.5, 0), -90)
    place(A.prop_terminal_ehr, coll, root, "MD_Terminal", (-4.6, 33.65, 0.76), 90)
    place(A.prop_phone, coll, root, "MD_Phone", (-4.35, 34.6, 0.76), 90)
    place(A.prop_bookcase, coll, root, "MD_Bookcase_1", (-3.1, 32.28, 0), 180)
    place(A.prop_bookcase, coll, root, "MD_Bookcase_2", (-4.05, 32.28, 0), 180)
    place(A.prop_filing_cabinet, coll, root, "MD_FilingCabinet", (-5.45, 35.55, 0), 0)
    place(A.prop_certificate, coll, root, "MD_Certificate_1", (-4.6, 35.9, 1.6), 0)
    place(A.prop_certificate, coll, root, "MD_Certificate_2", (-4.1, 35.9, 1.6), 0)
    place(A.prop_clock_caged, coll, root, "MD_Clock", (-2.8, 35.894, 2.2), 0)
    set_props(place(A.prop_folder_chart, coll, root, "MD_Document_ResearchAgreement", (-4.2, 33.55, 0.76), -70),
              {"godot_hint": "Research affiliation agreement (Concordance thread, Act III)."})
    L.empty("MARK_Character_DrVoss_Director", coll, root, (-5.15, 34.0, 0.0), (0, 0, -D90), display="SINGLE_ARROW",
            size=0.5, props={"marker_type": "character", "character_id": "staff_voss",
                             "faces": "+X (towards the door)"})
    L.camera_marker("CAM_MD_Establishing", coll, root, (-1.95, 32.45, 2.2), (-4.7, 34.6, 0.9), 20)
    card = MeshBuilder()
    card.box((0.02, 6.0, 4.0), (-7.5, 34.0, 1.6), "M_Exterior_Backdrop")
    card.build("BG_DirectorWindow_preview", S2.PREVIEW)
    return root


def build_conference(coll):
    root = west_room(coll, "ENV_AdminConference", "Administrative conference room", 36.0, "M_Wall_AdminTaupe",
                     "M_Carpet_Admin", panel_lights(-3.75, 36.0, 40.0), "M_Wall_AdminTaupe", owns_north=True)
    place(A.prop_table_conference, coll, root, "AC_Table", (-4.0, 38.0, 0), 0)
    for i, x in enumerate((-4.9, -4.0, -3.1)):
        place(A.prop_chair_office, coll, root, "AC_Chair_S%d" % i, (x, 36.95, 0), 180)
        place(A.prop_chair_office, coll, root, "AC_Chair_N%d" % i, (x, 39.05, 0), 0)
    place(A.prop_display_wall, coll, root, "AC_Display", (-5.894, 38.0, 1.5), 90)
    place(A.prop_phone, coll, root, "AC_Phone_Conference", (-4.0, 38.0, 0.74), 0)
    place(A.prop_camera_dome, coll, root, "AC_CCTV", (-2.0, 39.5, WALL_H), 0)
    place(A.prop_clock_caged, coll, root, "AC_Clock", (-4.0, 36.106, 2.3), 180)
    L.camera_marker("CAM_AC_Establishing", coll, root, (-1.95, 36.45, 2.2), (-4.6, 38.4, 0.8), 20)
    return root


def build_secure_interview(coll):
    paint = "M_Wall_SecurityBlueGrey"
    root = east_room(coll, "ENV_SecureInterviewSuite", "Secure interview suite", 20.0, 24.0, paint,
                     "M_Floor_Vinyl_Interview", [], "M_Concrete_Grey", solid_ceiling=True)
    place(A.prop_table_interview, coll, root, "SI_Table", (3.6, 22.0, 0), 0)
    place(A.prop_chair_interview, coll, root, "SI_Chair_Clinician", (2.65, 22.0, 0), 90)
    place(A.prop_chair_interview, coll, root, "SI_Chair_Patient", (4.55, 22.0, 0), -90)
    place(A.prop_duress_strip, coll, root, "SI_DuressStrip", (2.3, 23.894, 1.1), 0)
    place(A.prop_acoustic_panel, coll, root, "SI_Acoustic_S", (3.6, 20.106, 1.6), 180)
    place(A.prop_clock_caged, coll, root, "SI_Clock", (5.894, 22.0, 2.2), -90)
    place(A.prop_camera_dome, coll, root, "SI_CCTV", (5.6, 20.45, WALL_H), 0)
    place(A.prop_intercom, coll, root, "SI_Intercom", (1.606, 21.4, 1.4), -90)
    for i, x in enumerate((2.85, 4.35)):
        place(A.prop_light_vandal, coll, root, "SI_Light_%d" % i, (x, 22.0, WALL_H), 0)
        S2.add_preview_light("SI_Light_%d_preview" % i, (x, 22.0, WALL_H - 0.08), 70, (0.35, 0.35), COLD)
        L.light_marker("LIGHTMARK_SecureInterview_%d" % i, coll, root, (x, 22.0, WALL_H - 0.1), color=COLD,
                       range_m=5.0)
    clin_eye, pat_eye = (2.55, 22.0, 1.22), (4.65, 22.0, 1.22)
    L.empty("MARK_Seat_Clinician", coll, root, (2.65, 22.0, 0.45), (0, 0, -D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "+X (towards patient)"})
    L.empty("MARK_Seat_Patient", coll, root, (4.55, 22.0, 0.45), (0, 0, D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "-X (towards clinician)"})
    L.empty("MARK_Standing_Officer", coll, root, (2.0, 23.4, 0.0), (0, 0, -D90 / 2), display="SINGLE_ARROW",
            size=0.4, props={"marker_type": "standing", "use": "security officer present for high-risk interviews"})
    L.camera_marker("CAM_SI_Establishing", coll, root, (1.95, 20.35, 2.45), (4.4, 22.4, 0.85), 18)
    L.camera_marker("CAM_SI_OTS_OnPatient", coll, root, (2.05, 21.68, 1.36), pat_eye, 40,
                    props={"shot": "over clinician's right shoulder onto patient"})
    L.camera_marker("CAM_SI_OTS_OnClinician", coll, root, (5.15, 22.32, 1.36), clin_eye, 40,
                    props={"shot": "over patient's right shoulder onto clinician"})
    return root


def build_security_control(coll):
    root = east_room(coll, "ENV_SecurityControl", "Security control room (Hale)", 24.0, 32.0,
                     "M_Wall_SecurityBlueGrey", "M_Floor_Epoxy_Security", panel_lights(3.75, 24.0, 32.0, 2.0),
                     "M_Wall_SecurityBlueGrey")
    place(A.prop_console_security, coll, root, "SC_Console", (4.6, 27.0, 0), -90)
    place(A.prop_videowall, coll, root, "SC_VideoWall", (5.894, 27.0, 1.85), -90)
    place(A.prop_chair_office, coll, root, "SC_Chair_Operator_1", (3.85, 26.4, 0), 90)
    place(A.prop_chair_office, coll, root, "SC_Chair_Operator_2", (3.85, 27.6, 0), 90)
    place(A.prop_cabinet_keys, coll, root, "SC_KeyCabinet", (3.0, 24.106, 1.5), 180)
    place(A.prop_lockers, coll, root, "SC_Lockers", (5.65, 30.9, 0), -90)
    place(A.prop_desk_clinical, coll, root, "SC_Desk_Supervisor", (3.6, 30.6, 0), 0)
    place(A.prop_chair_office, coll, root, "SC_Chair_Supervisor", (3.6, 31.35, 0), 0)
    place(A.prop_terminal_ehr, coll, root, "SC_Terminal_AccessLog", (3.6, 30.5, 0.75), 180)
    place(A.prop_phone, coll, root, "SC_Phone", (4.15, 30.45, 0.75), 180)
    place(A.prop_duress_strip, coll, root, "SC_DuressStrip", (4.0, 24.106, 1.1), 180)
    place(A.prop_clock_caged, coll, root, "SC_Clock", (5.894, 29.4, 2.4), -90)
    place(A.prop_camera_dome, coll, root, "SC_CCTV", (2.0, 31.5, WALL_H), 0)
    set_props(place(A.prop_folder_chart, coll, root, "SC_Document_IncidentLog", (3.3, 30.4, 0.75), 160),
              {"godot_hint": "Night incident log; compare with the W0-B door log."})
    L.empty("MARK_Character_MarcusHale", coll, root, (3.6, 31.35, 0.0), (0, 0, math.pi), display="SINGLE_ARROW",
            size=0.5, props={"marker_type": "character", "character_id": "staff_hale",
                             "faces": "Godot +Z (south, over the desk)"})
    L.empty("MARK_Seat_Operator", coll, root, (3.85, 27.0, 0.45), (0, 0, -D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "+X (towards the video wall)"})
    L.camera_marker("CAM_SC_Establishing", coll, root, (2.0, 24.4, 2.4), (5.2, 27.6, 1.3), 18)
    L.camera_marker("CAM_SC_OverOperator", coll, root, (2.9, 27.0, 1.55), (5.9, 27.0, 1.85), 32,
                    props={"shot": "over the operator's shoulder onto the video wall"})
    return root


def build_surveillance(coll):
    root = east_room(coll, "ENV_SurveillanceMonitoring", "Surveillance monitoring room", 32.0, 36.0,
                     "M_Wall_SecurityBlueGrey", "M_Floor_Epoxy_Security", [(3.0, 34.0, 1.0, 0.5)],
                     "M_Wall_SecurityBlueGrey")
    place(A.prop_console_security, coll, root, "SM_Console", (4.6, 34.2, 0), -90)
    place(A.prop_videowall, coll, root, "SM_VideoWall", (5.894, 34.2, 1.85), -90)
    place(A.prop_chair_office, coll, root, "SM_Chair_1", (3.85, 33.6, 0), 90)
    place(A.prop_chair_office, coll, root, "SM_Chair_2", (3.85, 34.8, 0), 90)
    place(A.prop_filing_cabinet, coll, root, "SM_Cabinet_Recordings", (2.3, 35.55, 0), 0)
    place(A.prop_camera_dome, coll, root, "SM_CCTV", (2.0, 35.5, WALL_H), 0)
    set_props(place(A.prop_folder_chart, coll, root, "SM_Document_FootageRequest", (4.4, 33.4, 0.75), -100),
              {"godot_hint": "Footage retention request with a gap in the timestamps."})
    L.camera_marker("CAM_SM_Establishing", coll, root, (2.0, 32.4, 2.4), (5.4, 34.6, 1.4), 18)
    return root


def build_maintenance(coll):
    root = east_room(coll, "ENV_MaintenanceAccess", "Maintenance access area (Price)", 36.0, 40.0, "M_Concrete_Grey",
                     "M_Floor_Epoxy_Security", [(3.75, 38.0, 0.6, 1.2)], "M_Wall_SecurityBlueGrey",
                     owns_north=True, light_color=WARM)
    place(A.prop_panel_electrical, coll, root, "MA_ElectricalPanel", (5.894, 37.0, 1.4), -90)
    place(A.prop_pipes_wall, coll, root, "MA_Pipes_1", (2.0, 39.894, 2.55), 0)
    place(A.prop_pipes_wall, coll, root, "MA_Pipes_2", (3.95, 39.894, 2.55), 0)
    place(A.prop_shelving_archive, coll, root, "MA_Shelving", (4.4, 36.33, 0), 180)
    place(A.prop_lockers, coll, root, "MA_Lockers", (2.2, 39.6, 0), 0)
    place(A.prop_bin, coll, root, "MA_Bin", (5.6, 39.5, 0), 0)
    hatch = MeshBuilder()
    hatch.box((0.9, 0.9, 0.012), (4.5, 38.6, 0.006), "M_Steel_Brushed")
    for i in range(7):
        hatch.box((0.84, 0.01, 0.004), (4.5, 38.22 + i * 0.12, 0.014), "M_Steel_Painted_Grey")
    hatch.box((0.18, 0.03, 0.02), (4.5, 38.2, 0.022), "M_Metal_Dark")
    hatch.box((0.05, 0.03, 0.06), (4.62, 38.2, 0.04), "M_Steel_Painted_Grey")              # Padlock.
    set_props(hatch.build("MA_ServiceHatch", coll, root),
              {"godot_hint": "Locked floor hatch down to the historic substructure (Stage 5).",
               "required_access": "access_maintenance"})
    L.empty("MARK_Character_SamuelPrice", coll, root, (3.3, 37.4, 0.0), (0, 0, 0), display="SINGLE_ARROW", size=0.5,
            props={"marker_type": "character", "character_id": "staff_price"})
    L.camera_marker("CAM_MA_Establishing", coll, root, (1.95, 36.45, 2.3), (4.6, 38.6, 0.4), 18)
    return root


def build_lift_lobby(coll):
    root = env_root(coll, "ENV_RestrictedLiftLobby", "Restricted elevator lobby")
    paint = "M_Concrete_Grey"
    room_shell(coll, root, -3.0, 3.0, 40.0, 44.0, paint, "M_Floor_Epoxy_Security",
               {"west": dict(back_mat=paint), "east": dict(back_mat=paint),
                "north": dict(back_mat=paint, openings=[A.door_opening(3.0, 1.1, 2.1)])},
               lights=[(0.0, 41.5, 1.0, 0.5), (0.0, 43.0, 1.0, 0.5)], floor_extend=(-3.1, 3.1, 40.0, 44.1),
               light_color=COLD)
    pm = MeshBuilder()
    for x, y in ((-3.0, 40.0), (3.0, 40.0), (-3.0, 44.0), (3.0, 44.0)):
        A.corner_post(pm, x, y, paint)
    pm.build("ENV_RestrictedLiftLobby_Posts", coll, root)
    lift = place(A.prop_door_elevator, coll, root, "LL_ElevatorDoors", (0.0, 44.0, 0), 0)
    set_props(lift, {"door_id": "door_restricted_lift", "required_access": "access_restricted_lift",
                     "gameplay_note": "Key-switch lift; serves the research wing and the sublevels."})
    place(A.prop_camera_dome, coll, root, "LL_CCTV", (2.4, 40.6, WALL_H), 0)
    place(A.prop_sign_room, coll, root, "LL_Sign_Floors", (-1.2, 43.894, 1.5), 0)
    place(A.prop_intercom, coll, root, "LL_Intercom", (2.894, 42.0, 1.4), -90)
    L.camera_marker("CAM_LL_Establishing", coll, root, (0.0, 40.4, 1.65), (0.0, 44.0, 1.3), 24)
    return root


def build_wing():
    L.reset_scene()
    scene = bpy.context.scene
    wing = L.collection("FW_SecurityAdminWing")
    S2.PREVIEW = L.collection("PREVIEW_ONLY_not_exported")
    builders = [
        (build_corridor, "Security wing: controlled-access corridor north of the ward entry"),
        (build_visitor_screening, "Security wing: visitor screening and waiting"),
        (build_credentialing, "Admin: staff credentialing and access office"),
        (build_records_office, "Admin: records office"),
        (build_director_office, "Admin: medical director's office"),
        (build_conference, "Admin: conference room"),
        (build_secure_interview, "Security wing: secure interview suite"),
        (build_security_control, "Security wing: security control room"),
        (build_surveillance, "Security wing: surveillance monitoring"),
        (build_maintenance, "Security wing: maintenance access (service hatch)"),
        (build_lift_lobby, "Security wing: restricted elevator lobby"),
    ]
    envs = []
    for builder, location in builders:
        name = builder.__name__.replace("build_", "")
        envs.append((builder(L.collection("ENV_" + name, wing)), location))

    for root, _ in envs:
        lo, hi = L.world_bounds(root)
        assert 3.0 < max(hi - lo) < 25.0, (root.name, tuple(hi - lo))
        assert lo.y > 19.5, root.name + " overlaps the clinical wing"
        assert any(o.name.startswith("CAM_") for o in L.descendants(root)), root.name + " has no camera markers"
        assert any(o.name.endswith("-colonly") for o in L.descendants(root)), root.name + " has no collision"
    clin = bpy.data.objects["SI_Chair_Clinician"].location
    pat = bpy.data.objects["SI_Chair_Patient"].location
    exit_pt = Vector((1.5, 22.5, 0))
    assert (clin - exit_pt).length < (pat - exit_pt).length, "clinician must sit nearer the exit"

    L.save_blend(WING_BLEND)
    records = []
    for root, location in envs:
        path = os.path.join(ENV_DIR, root.name + ".glb")
        L.export_glb(root, path)
        records.append(L.asset_record(
            root, WING_BLEND, path, location, "Floor + wall + furniture box colliders; door leaves carry their own",
            "Place at the Godot origin (Chapter 1 shared frame, north of y = 20). CAM_* framing references; "
            "MARK_* forward = Godot -Z; LIGHTMARK_* light positions; *_Ceiling is a separate mesh.", STATUS, REPO))
    L.write_manifest(records, MANIFEST)
    if FAST:
        return len(records)

    L.setup_render(scene, 1280, 720, samples=32)
    shots = (("CAM_SW_Corridor", "security_corridor.png"), ("CAM_VS_Establishing", "visitor_screening.png"),
             ("CAM_SC_Establishing", "security_control.png"), ("CAM_MD_Establishing", "director_office.png"),
             ("CAM_SI_Establishing", "secure_interview.png"), ("CAM_LL_Establishing", "lift_lobby.png"))
    for cam_name, out in shots:
        L.render_from(scene, bpy.data.objects[cam_name], os.path.join(RENDER_DIR, out))
    for ob in bpy.data.objects:
        if ob.name.endswith("_Ceiling") or "Light" in ob.name or ob.name.endswith("_preview") or "CCTV" in ob.name:
            ob.hide_render = True
    sun = bpy.data.lights.new("PlanSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PlanSun", sun)
    S2.PREVIEW.objects.link(sun_ob)
    plan = L.camera_marker("PlanCam_preview", S2.PREVIEW, None, (0.0, 32.0, 30.0), (0.0, 32.0, 0.0), 30)
    plan.data.type = "ORTHO"
    plan.data.ortho_scale = 26.0
    scene.render.resolution_x, scene.render.resolution_y = 1000, 1100
    L.render_from(scene, plan, os.path.join(RENDER_DIR, "security_admin_plan.png"))
    return len(records)


def main():
    n_props = build_props()
    n_envs = build_wing()
    print("STAGE4 SECURITY OK: %d props, %d environments exported%s" % (n_props, n_envs, " (fast)" if FAST else ""))


if __name__ == "__main__":
    main()
