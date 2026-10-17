"""Stage 4b: research wing (the research level), plus its props library.

The research wing is the level the restricted lift serves (Stage 4a's
"Key-switch lift; serves the research wing and the sublevels"). It is its
own level, authored at floor z = 0 with the same x/y as the Chapter 1 shared
frame, so its lift doors stand exactly above the security wing's
(x 0, y 44). Load it as a separate level scene; if both levels are ever
stacked in one scene, raise every research ENV_* by the same floor height.

Layout (wall centrelines, metres):

    y      west side (x -6 .. -1.5)        corridor (x +/-1.5)          east side (x 1.5 .. 6)
    40-44                                  Reception + lift (x -3 .. 3)
    36-40  Research physician office A     research corridor            Clinical assessment room
    32-36  Research physician office B                                  Observation and monitoring
    28-32  Data analysis office            (one-way window y 36)        Laboratory support
    28     ------------------------------- restricted door ------------------------------------
    24-28  Research records archive        restricted research          Secure sample storage
    20-24  (unsigned) protocol office      corridor, dead end at y 20   (y 20 .. 28)

The wing must read as a legitimate, well-funded clinical research unit. Its
unease comes only from small inconsistencies: an unsigned door with a
stronger lock than the rest, a whiteboard wiped in a hurry, an archive bay
emptied, a freezer with a second padlock and no study label, an observation
room set for more observers than an assessment needs. Each is tagged with a
godot_hint so gameplay can hang evidence on it; none states a clinical fact.

Wall ownership follows Stage 4a: the corridors own their side walls and the
cross walls; each room owns its south wall (and the last in a row its north
wall); reception owns its west, east and north walls.

Outputs:
    assets/blender/research/FW_Props_Research.blend, assets/exports/research/props/*.glb
    assets/blender/research/FW_ResearchWing.blend, assets/exports/research/env/ENV_*.glb
    assets/renders/stage4/research_*.png (skipped with --fast)
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
import build_stage4_security_admin as S4  # noqa: E402  (west_room, east_room, panel_lights, ...)
import fw_assets as A  # noqa: E402
import fw_lib as L  # noqa: E402
from fw_lib import WALL_H, MeshBuilder  # noqa: E402

PROPS_BLEND = os.path.join(REPO, "assets/blender/research/FW_Props_Research.blend")
WING_BLEND = os.path.join(REPO, "assets/blender/research/FW_ResearchWing.blend")
PROPS_DIR = os.path.join(REPO, "assets/exports/research/props")
ENV_DIR = os.path.join(REPO, "assets/exports/research/env")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage4")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = S4.STATUS
FAST = "--fast" in sys.argv
D90 = math.pi / 2
CLEAN = "#F4F8FF"     # Research lighting: bright, neutral-cool, a touch clinical.
FRAME = ("Research level frame: same x/y as the Chapter 1 shared frame, floor at z = 0; "
         "load as its own level (the restricted lift connects the two)")
PAINT = "M_Wall_ResearchWhite"
FLOOR = "M_Floor_Vinyl_Research"

place, door, room_shell, set_props = S2.place, S2.door, S2.room_shell, S2.set_props
wall_with_collision = S2.wall_with_collision
readers_and_sign, panel_lights = S4.readers_and_sign, S4.panel_lights

PROP_WALL_MOUNTED = {"PROP_Whiteboard_Wall"}
PROP_BENCHTOP = {"PROP_Centrifuge_Benchtop"}
PROP_LOCATIONS = {
    "PROP_Counter_Reception": "Research reception",
    "PROP_Chair_Assessment_Recliner": "Clinical assessment room",
    "PROP_Bench_Lab_2m": "Laboratory support, secure sample storage",
    "PROP_Centrifuge_Benchtop": "Laboratory support",
    "PROP_Freezer_Upright_ULT": "Secure sample storage, laboratory support",
    "PROP_Desk_Workstation_Dual": "Data analysis office, observation room",
    "PROP_Rack_Server_42U": "Data analysis office",
    "PROP_Whiteboard_Wall": "Data analysis office, protocol office",
}


def env_root(coll, asset_id, name):
    root = S2.env_root(coll, asset_id, name)
    root["frame"] = FRAME
    return root


def tag(ob, hint, **extra):
    """Environmental-storytelling hook: a hint for gameplay, never a clinical fact."""
    return set_props(ob, dict({"godot_hint": hint, "story_tag": "research_inconsistency"}, **extra))


# --------------------------------------------------------------------------
# Props library
# --------------------------------------------------------------------------

def build_props():
    L.reset_scene()
    scene = bpy.context.scene
    coll = L.collection("FW_Props_Research")
    records = []
    for i, builder in enumerate(A.STAGE4_RESEARCH_PROP_BUILDERS):
        root = builder(coll, loc=((i % 4) * 3.5, (i // 4) * 3.0, 0))
        has_col = any(o.name.endswith("-colonly") for o in L.descendants(root))
        origin = ("wall surface" if root.name in PROP_WALL_MOUNTED
                  else "bench surface" if root.name in PROP_BENCHTOP else "floor centre")
        records.append((root, PROP_LOCATIONS[root.name],
                        "Box collider (-colonly)" if has_col else "Decorative: no collision",
                        "Staff-only research areas (not patient-accessible). Origin: %s." % origin))
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
            if root.name in PROP_WALL_MOUNTED:
                root.location.z += 1.5
            elif root.name in PROP_BENCHTOP:
                root.location.z += 0.9
        L.setup_render(scene, 1600, 900, samples=24)
        sun = bpy.data.lights.new("PreviewSun", "SUN")
        sun.energy = 3.0
        sun_ob = bpy.data.objects.new("PreviewSun", sun)
        scene.collection.objects.link(sun_ob)
        sun_ob.rotation_euler = (math.radians(45), 0, math.radians(-25))
        ground = MeshBuilder()
        ground.box((30, 16, 0.02), (5.25, 1.5, -0.01), FLOOR)
        ground.build("PreviewGround", scene.collection)
        cam = L.camera_marker("PreviewCam", scene.collection, None, (5.25, -8.5, 5.5), (5.25, 1.8, 0.7), 26)
        L.render_from(scene, cam, os.path.join(RENDER_DIR, "props_research.png"))
    return len(manifest)


# --------------------------------------------------------------------------
# Wing
# --------------------------------------------------------------------------

def west_room(coll, asset_id, name, y0, lights, **kw):
    root = S4.west_room(coll, asset_id, name, y0, PAINT, FLOOR, lights, PAINT, light_color=CLEAN, **kw)
    root["frame"] = FRAME
    return root


def east_room(coll, asset_id, name, y0, y1, lights, **kw):
    kw.setdefault("light_color", CLEAN)
    root = S4.east_room(coll, asset_id, name, y0, y1, PAINT, FLOOR, lights, PAINT, **kw)
    root["frame"] = FRAME
    return root


def build_research_corridor(coll):
    root = env_root(coll, "ENV_ResearchCorridor_12m", "Research corridor, 12 m (reception to restricted door)")
    west = [A.door_opening(y - 28.0, 1.0) for y in (30.0, 34.0, 38.0)]
    east = [A.door_opening(40.0 - y, w) for y, w in ((30.5, 1.2), (33.0, 1.0), (37.0, 1.0))]
    lights = [(0.0, y, 0.6, 1.2) for y in (29.5, 32.0, 34.5, 37.0, 39.2)]
    room_shell(coll, root, -1.5, 1.5, 28.0, 40.0, PAINT, FLOOR,
               {"west": dict(openings=west, back_mat=PAINT), "east": dict(openings=east, back_mat=PAINT)},
               lights=lights, floor_extend=(-1.6, 1.6, 28.0, 40.0), light_color=CLEAN)
    mb = MeshBuilder()
    wall_with_collision(mb, coll, root, (-1.5, 28.0), (1.5, 28.0), "RestrictedDoor", front_mat=PAINT,
                        back_mat="M_Wall_SecurityBlueGrey", openings=[A.door_opening(1.5, 1.8)])
    wall_with_collision(mb, coll, root, (-1.5, 40.0), (1.5, 40.0), "ReceptionDoor", front_mat=PAINT, back_mat=PAINT,
                        openings=[A.door_opening(1.5, 1.8)])
    for x, y in ((-1.5, 28.0), (1.5, 28.0), (-1.5, 40.0), (1.5, 40.0)):
        A.corner_post(mb, x, y, PAINT)
    mb.build(root.name + "_CrossWalls", coll, root)

    door(coll, root, "Door_ResearchReception", "secure_double", (0.0, 40.0, 0), 0.0, "door_research_reception",
         "access_research")
    door(coll, root, "Door_PhysicianOfficeA", "interior", (-1.5, 38.0, 0), D90, "door_research_office_a")
    door(coll, root, "Door_PhysicianOfficeB", "interior", (-1.5, 34.0, 0), D90, "door_research_office_b")
    door(coll, root, "Door_DataAnalysis", "interior", (-1.5, 30.0, 0), D90, "door_data_analysis", "access_research")
    door(coll, root, "Door_Assessment", "interior", (1.5, 37.0, 0), -D90, "door_research_assessment")
    door(coll, root, "Door_Observation", "interior", (1.5, 33.0, 0), -D90, "door_research_observation",
         "access_research")
    door(coll, root, "Door_LabSupport", "secure_single", (1.5, 30.5, 0), -D90, "door_lab_support", "access_research")
    door(coll, root, "Door_RestrictedResearch", "secure_double", (0.0, 28.0, 0), 0.0, "door_restricted_research",
         "access_research_restricted", "Badge plus PIN; most research staff badges are refused here.")

    for prefix, y in (("PhysicianOfficeA", 38.0), ("PhysicianOfficeB", 34.0), ("DataAnalysis", 30.0)):
        readers_and_sign(coll, root, prefix, -1.5, y, -1)
    for prefix, y in (("Assessment", 37.0), ("Observation", 33.0), ("LabSupport", 30.5)):
        readers_and_sign(coll, root, prefix, 1.5, y, 1)
    place(A.prop_reader, coll, root, "RestrictedDoor_Reader", (1.2, 28.106, 1.1), 180)
    keypad = MeshBuilder()
    keypad.box((0.09, 0.03, 0.13), (1.2, 28.121, 1.35), "M_Plastic_Black")
    tag(keypad.build("RestrictedDoor_PINPad", coll, root), "Second factor on the restricted door only.")
    place(A.prop_sign_room, coll, root, "RestrictedDoor_Sign", (-1.0, 28.106, 2.2), 180)
    for i, (x, y) in enumerate(((0.9, 39.4), (-0.9, 33.5), (0.9, 28.6))):
        place(A.prop_camera_dome, coll, root, "ResearchCorridor_CCTV_%d" % i, (x, y, WALL_H), 0)
    place(A.prop_dispenser_handgel, coll, root, "ResearchCorridor_HandGel", (-1.394, 36.0, 1.2), 90)
    place(A.prop_noticeboard, coll, root, "ResearchCorridor_NoticeBoard_Studies", (1.394, 35.6, 1.5), -90)
    L.camera_marker("CAM_RC_Corridor", coll, root, (0.0, 39.6, 1.65), (0.0, 28.0, 1.3), 24)
    return root


def build_restricted_corridor(coll):
    root = env_root(coll, "ENV_RestrictedResearchCorridor_8m", "Restricted research corridor, 8 m, dead end")
    west = [A.door_opening(y - 20.0, w) for y, w in ((21.5, 1.2), (26.0, 1.0))]
    east = [A.door_opening(28.0 - y, 1.2) for y in (24.0,)]
    room_shell(coll, root, -1.5, 1.5, 20.0, 28.0, PAINT, FLOOR,
               {"west": dict(openings=west, back_mat=PAINT), "east": dict(openings=east, back_mat=PAINT),
                "south": dict(back_mat="M_Concrete_Grey")},
               lights=[(0.0, 26.5, 0.6, 1.2), (0.0, 23.0, 0.6, 1.2)], floor_extend=(-1.6, 1.6, 19.9, 28.0),
               light_color=CLEAN)
    pm = MeshBuilder()
    for x in (-1.5, 1.5):
        A.corner_post(pm, x, 20.0, PAINT)
    pm.build(root.name + "_Posts", coll, root)
    door(coll, root, "Door_RecordsArchive", "interior", (-1.5, 26.0, 0), D90, "door_research_archive",
         "access_research_restricted")
    door(coll, root, "Door_SampleStorage", "secure_single", (1.5, 24.0, 0), -D90, "door_sample_storage",
         "access_research_restricted")
    tag(door(coll, root, "Door_ProtocolOffice", "secure_single", (-1.5, 21.5, 0), D90, "door_protocol_office",
             "access_protocol_office", "No room sign; the reader rejects every badge the player can obtain early."),
        "Unsigned door: the sign holder is empty and its lock is heavier than any other office's.")
    readers_and_sign(coll, root, "RecordsArchive", -1.5, 26.0, -1)
    readers_and_sign(coll, root, "SampleStorage", 1.5, 24.0, 1)
    place(A.prop_reader, coll, root, "ProtocolOffice_Reader", (-1.394, 22.35, 1.1), 90)
    holder = MeshBuilder()                                                                 # Empty sign holder.
    holder.box((0.012, 0.3, 0.12), (-1.388, 20.65, 1.5), "M_Steel_Brushed")
    holder.box((0.004, 0.27, 0.1), (-1.38, 20.65, 1.5), PAINT)
    tag(holder.build("ProtocolOffice_EmptySignHolder", coll, root), "Every other door here has a room sign.")
    place(A.prop_camera_dome, coll, root, "RestrictedCorridor_CCTV", (0.9, 21.0, WALL_H), 0)
    L.camera_marker("CAM_RR_Corridor", coll, root, (0.0, 27.6, 1.65), (-0.6, 20.0, 1.2), 24)
    return root


def build_reception(coll):
    root = env_root(coll, "ENV_ResearchReception", "Research reception and lift landing")
    room_shell(coll, root, -3.0, 3.0, 40.0, 44.0, PAINT, FLOOR,
               {"west": dict(back_mat=PAINT), "east": dict(back_mat=PAINT),
                "north": dict(back_mat="M_Concrete_Grey", openings=[A.door_opening(3.0, 1.1, 2.1)])},
               lights=[(-1.5, 41.5, 1.0, 0.5), (1.5, 41.5, 1.0, 0.5), (0.0, 43.0, 1.0, 0.5)],
               floor_extend=(-3.1, 3.1, 40.0, 44.1), light_color=CLEAN)
    pm = MeshBuilder()
    for x, y in ((-3.0, 40.0), (3.0, 40.0), (-3.0, 44.0), (3.0, 44.0)):
        A.corner_post(pm, x, y, PAINT)
    pm.build(root.name + "_Posts", coll, root)
    set_props(place(A.prop_door_elevator, coll, root, "RE_ElevatorDoors", (0.0, 44.0, 0), 0),
              {"door_id": "door_restricted_lift_research", "required_access": "access_restricted_lift",
               "gameplay_note": "Same shaft as the security wing's restricted lift (x 0, y 44)."})
    place(A.prop_counter_reception, coll, root, "RE_Counter", (-1.6, 41.3, 0), 90)
    place(A.prop_chair_office, coll, root, "RE_Chair_Receptionist", (-2.45, 41.3, 0), 90)
    place(A.prop_terminal_ehr, coll, root, "RE_Terminal_Scheduling", (-1.8, 41.0, 0.75), -90)
    place(A.prop_phone, coll, root, "RE_Phone", (-1.75, 41.9, 0.75), 90)
    place(A.prop_seating_waiting, coll, root, "RE_Seating", (2.5, 42.0, 0), -90)
    place(A.prop_display_wall, coll, root, "RE_Display_UnitInfo", (2.894, 42.0, 1.75), -90)
    place(A.prop_sign_room, coll, root, "RE_Sign_ClinicalResearchUnit", (-2.894, 42.0, 2.0), 90)
    place(A.prop_dispenser_handgel, coll, root, "RE_HandGel", (-1.6, 43.894, 1.2), 0)
    place(A.prop_camera_dome, coll, root, "RE_CCTV", (2.4, 40.6, WALL_H), 0)
    place(A.prop_clock_caged, coll, root, "RE_Clock", (1.6, 43.894, 2.3), 0)
    tag(place(A.prop_folder_chart, coll, root, "RE_Document_VisitorBook", (-1.45, 41.7, 1.13), 80),
        "Visitor sign-in book: one recurring visitor never signs out.")
    L.empty("MARK_Character_ResearchReceptionist", coll, root, (-2.45, 41.3, 0.0), (0, 0, -D90),
            display="SINGLE_ARROW", size=0.5,
            props={"marker_type": "character", "character_id": "staff_research_receptionist",
                   "faces": "+X (across the counter)"})
    L.camera_marker("CAM_RE_Establishing", coll, root, (2.6, 40.4, 2.3), (-1.8, 42.6, 0.9), 20)
    return root


def build_office_a(coll):
    root = west_room(coll, "ENV_ResearchPhysicianOfficeA", "Research physician office A", 36.0,
                     [(-3.75, 38.0, 1.0, 0.5)], owns_north=True)
    place(A.prop_desk_clinical, coll, root, "OA_Desk", (-4.4, 38.0, 0), 90)
    place(A.prop_chair_office, coll, root, "OA_Chair", (-5.15, 38.0, 0), 90)
    place(A.prop_chair_visitor, coll, root, "OA_Chair_Visitor", (-3.4, 38.0, 0), -90)
    place(A.prop_terminal_ehr, coll, root, "OA_Terminal", (-4.55, 37.65, 0.75), -90)
    place(A.prop_phone, coll, root, "OA_Phone", (-4.3, 38.55, 0.75), 90)
    place(A.prop_bookcase, coll, root, "OA_Bookcase", (-4.2, 39.72, 0), 0)
    place(A.prop_certificate, coll, root, "OA_Certificate", (-5.894, 37.0, 1.6), 90)
    place(A.prop_filing_cabinet, coll, root, "OA_FilingCabinet", (-5.5, 36.45, 0), 180)
    tag(place(A.prop_folder_chart, coll, root, "OA_Document_ConsentForms", (-4.2, 37.6, 0.75), -70),
        "Consent form batch; the study title field is printed blank on every copy.")
    L.camera_marker("CAM_OA_Establishing", coll, root, (-1.95, 36.45, 2.2), (-4.7, 38.4, 0.9), 20)
    return root


def build_office_b(coll):
    root = west_room(coll, "ENV_ResearchPhysicianOfficeB", "Research physician office B (vacated)", 32.0,
                     [(-3.75, 34.0, 1.0, 0.5)])
    place(A.prop_desk_clinical, coll, root, "OB_Desk", (-4.4, 34.0, 0), 90)
    place(A.prop_chair_office, coll, root, "OB_Chair", (-5.15, 34.0, 0), 90)
    place(A.prop_chair_visitor, coll, root, "OB_Chair_Visitor", (-3.4, 34.0, 0), -90)
    place(A.prop_bookcase, coll, root, "OB_Bookcase", (-4.2, 35.72, 0), 0)
    place(A.prop_filing_cabinet, coll, root, "OB_FilingCabinet", (-5.5, 32.45, 0), 180)
    mb = MeshBuilder()                                                                     # Clean squares on the wall.
    for z in (1.45, 1.85):
        mb.box((0.004, 0.42, 0.32), (-5.892, 34.6, z), "M_Paint_Historic_Cream")
    tag(mb.build("OB_CertificateOutlines", coll, root),
        "Paler rectangles where certificates hung; the office was cleared recently.")
    tag(place(A.prop_bin, coll, root, "OB_Bin_Shredding", (-3.4, 35.5, 0), 0), "Full shredding bin, sealed.")
    L.camera_marker("CAM_OB_Establishing", coll, root, (-1.95, 32.45, 2.2), (-4.7, 34.4, 1.0), 20)
    return root


def build_data_analysis(coll):
    root = west_room(coll, "ENV_DataAnalysisOffice", "Research data analysis office", 28.0,
                     [(-3.75, 29.2, 1.0, 0.5), (-3.75, 30.8, 1.0, 0.5)])
    place(A.prop_desk_workstation, coll, root, "DA_Workstation_1", (-4.0, 29.0, 0), 180)
    place(A.prop_desk_workstation, coll, root, "DA_Workstation_2", (-4.0, 31.2, 0), 0)
    place(A.prop_chair_office, coll, root, "DA_Chair_1", (-4.0, 29.65, 0), 0)
    place(A.prop_chair_office, coll, root, "DA_Chair_2", (-4.0, 30.55, 0), 180)
    place(A.prop_rack_server, coll, root, "DA_ServerRack", (-5.35, 30.0, 0), 90)
    tag(place(A.prop_whiteboard, coll, root, "DA_Whiteboard", (-3.6, 28.106, 1.55), 180),
        "Wiped whiteboard: residue of a cohort table and a crossed-out enrolment count.")
    tag(place(A.prop_folder_chart, coll, root, "DA_Document_DatasetExport", (-3.6, 31.0, 0.74), 15),
        "Dataset export log; one participant ID range is excluded without a reason.")
    L.camera_marker("CAM_DA_Establishing", coll, root, (-1.95, 31.6, 2.2), (-4.8, 29.4, 0.9), 20)
    return root


def build_records_archive(coll):
    root = west_room(coll, "ENV_ResearchRecordsArchive", "Research records archive", 24.0,
                     [(-3.75, 25.2, 1.0, 0.5), (-3.75, 26.8, 1.0, 0.5)])
    for i, (y, r) in enumerate(((24.6, 180), (26.0, 0))):
        place(A.prop_shelving_archive, coll, root, "RA_Shelving_%d" % i, (-4.3, y, 0), r)
    place(A.prop_shelving_archive, coll, root, "RA_Shelving_2", (-5.65, 26.6, 0), 90)
    bay = MeshBuilder()                                                                    # Emptied bay.
    w, d, h, cx, cy = 1.8, 0.45, 2.2, -4.3, 27.45
    for x in (cx - w / 2, cx + w / 2):
        for y in (cy - d / 2, cy + d / 2):
            bay.box((0.035, 0.035, h), (x, y, h / 2), "M_Steel_Painted_Grey")
    for i in range(6):
        z = 0.08 + i * 0.4
        bay.box((w, d, 0.02), (cx, cy, z), "M_Steel_Painted_Grey")
        if 0 < i < 5:
            for j in range(4):                                                             # Dust-free box outlines.
                bay.box((0.3, d - 0.08, 0.002), (cx - 0.6 + j * 0.4, cy, z + 0.011), "M_Steel_Brushed")
    tag(bay.build("RA_Shelving_Emptied", coll, root), "One bay emptied: dust outlines where boxes sat.")
    L.collision_box("RA_Shelving_Emptied_COL", coll, root, (w, d, h), (cx, cy, h / 2))
    place(A.prop_desk_clinical, coll, root, "RA_Desk", (-2.5, 27.35, 0), 0)
    place(A.prop_chair_office, coll, root, "RA_Chair", (-2.5, 26.6, 0), 180)
    tag(place(A.prop_folder_chart, coll, root, "RA_Document_RetrievalLog", (-2.2, 27.3, 0.75), 10),
        "Retrieval log; the last entry for the emptied bay is a transfer with no destination.")
    L.camera_marker("CAM_RA_Establishing", coll, root, (-1.95, 24.4, 2.3), (-4.8, 26.8, 0.9), 18)
    return root


def build_protocol_office(coll):
    root = west_room(coll, "ENV_ProtocolOffice", "Undisclosed protocol office (unsigned)", 20.0,
                     [(-3.75, 22.0, 1.0, 0.5)], solid_ceiling=True)
    place(A.prop_desk_executive, coll, root, "PO_Desk", (-4.6, 22.0, 0), 90)
    place(A.prop_chair_office, coll, root, "PO_Chair", (-5.35, 22.0, 0), 90)
    place(A.prop_terminal_ehr, coll, root, "PO_Terminal_Offline", (-4.75, 21.65, 0.76), -90)
    for i, x in enumerate((-5.5, -5.0)):
        place(A.prop_filing_cabinet, coll, root, "PO_FilingCabinet_%d" % i, (x, 23.55, 0), 0)
    bar = MeshBuilder()
    bar.box((1.0, 0.04, 0.04), (-5.25, 23.2, 1.05), "M_Metal_Dark")
    bar.box((0.06, 0.03, 0.08), (-4.8, 23.17, 1.0), "M_Steel_Brushed")
    tag(bar.build("PO_FilingCabinet_LockBar", coll, root), "Lock bar across both cabinets; nowhere else has one.")
    tag(place(A.prop_whiteboard, coll, root, "PO_Whiteboard", (-4.6, 20.106, 1.55), 180),
        "Wiped whiteboard: a flow chart with numbered boxes, the labels erased.")
    tag(place(A.prop_folder_chart, coll, root, "PO_Document_ProtocolBinder", (-4.45, 22.3, 0.76), -95),
        "Protocol binder: cover carries a number only, no title, sponsor or ethics reference.",
        clinical_review_status="PENDING")
    place(A.prop_shelving_archive, coll, root, "PO_Shelving", (-2.7, 20.33, 0), 180)
    L.camera_marker("CAM_PO_Establishing", coll, root, (-1.95, 23.6, 2.3), (-4.8, 21.4, 0.9), 18)
    return root


def build_assessment(coll):
    """South wall carries the one-way window: mirror inside, see-through from observation."""
    window = A.window_opening(2.25, 1.6, 1.0, 2.0, "M_Glass_OneWay_Observer", "M_Mirror_OneWay_Room")
    root = env_root(coll, "ENV_ClinicalAssessmentRoom", "Clinical assessment room (observed)")
    room_shell(coll, root, 1.5, 6.0, 36.0, 40.0, PAINT, FLOOR,
               {"south": dict(back_mat=PAINT, openings=[window]), "east": dict(back_mat="M_Concrete_Grey"),
                "north": dict(back_mat="M_Concrete_Grey")},
               lights=[(3.75, 37.2, 1.0, 0.5), (3.75, 38.8, 1.0, 0.5)], floor_extend=(1.6, 6.1, 36.0, 40.1),
               light_color=CLEAN)
    pm = MeshBuilder()
    for y in (36.0, 40.0):
        A.corner_post(pm, 6.0, y, PAINT)
    pm.build(root.name + "_Posts", coll, root)
    place(A.prop_chair_assessment, coll, root, "AS_Chair_Participant", (4.7, 38.4, 0), -90)
    place(A.prop_chair_office, coll, root, "AS_Chair_Clinician", (2.6, 38.4, 0), 90)
    place(A.prop_table_interview, coll, root, "AS_Table_Side", (3.5, 39.4, 0), 0)
    place(A.prop_monitor_vitals, coll, root, "AS_Monitor_Vitals", (5.5, 39.5, 0), 180)
    place(A.prop_dispenser_handgel, coll, root, "AS_HandGel", (1.606, 39.2, 1.2), 90)
    place(A.prop_clock_caged, coll, root, "AS_Clock", (5.894, 37.6, 2.2), -90)
    tag(place(A.prop_camera_dome, coll, root, "AS_CCTV_OnChair", (5.6, 36.4, WALL_H), 0),
        "Second camera trained on the chair; the room already has the observation window.")
    place(A.prop_camera_dome, coll, root, "AS_CCTV", (2.0, 39.6, WALL_H), 0)
    L.empty("MARK_Seat_Clinician", coll, root, (2.6, 38.4, 0.45), (0, 0, -D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "+X (towards participant)"})
    L.empty("MARK_Seat_Participant", coll, root, (4.7, 38.4, 0.5), (0, 0, D90), display="SINGLE_ARROW", size=0.4,
            props={"marker_type": "seat", "faces": "-X (towards clinician)"})
    L.camera_marker("CAM_AS_Establishing", coll, root, (1.95, 39.6, 2.3), (4.6, 37.6, 0.9), 18)
    L.camera_marker("CAM_AS_ThroughGlass", coll, root, (3.75, 34.6, 1.6), (4.7, 38.4, 0.9), 30,
                    props={"shot": "from the observation room through the one-way glass"})
    return root


def build_observation(coll):
    root = east_room(coll, "ENV_ObservationMonitoring", "Observation and monitoring room", 32.0, 36.0,
                     [(3.75, 34.0, 1.0, 0.5)], light_color="#C9D4E6")
    place(A.prop_desk_workstation, coll, root, "OM_Workstation", (5.45, 34.2, 0), -90)
    place(A.prop_chair_office, coll, root, "OM_Chair_Operator", (4.75, 34.2, 0), 90)
    for i, x in enumerate((2.6, 3.35, 4.1)):
        place(A.prop_chair_office, coll, root, "OM_Chair_%d" % i, (x, 35.1, 0), 180)
    tag(place(A.prop_chair_visitor, coll, root, "OM_Chair_Extra_0", (3.4, 32.55, 0), 180),
        "Six chairs for a room that serves one assessment: observers outnumber the participant.")
    place(A.prop_chair_visitor, coll, root, "OM_Chair_Extra_1", (4.1, 32.55, 0), 180)
    place(A.prop_rack_server, coll, root, "OM_Recorder", (5.37, 32.9, 0), -90)
    tag(place(A.prop_folder_chart, coll, root, "OM_Document_ObserverLog", (5.3, 34.6, 0.74), -80),
        "Observer sign-in sheet: several names are initials only.")
    L.camera_marker("CAM_OM_Establishing", coll, root, (2.0, 32.4, 2.3), (4.5, 35.8, 1.2), 18)
    return root


def build_lab_support(coll):
    root = east_room(coll, "ENV_LabSupport", "Laboratory support room", 28.0, 32.0,
                     [(3.75, 29.2, 1.0, 0.5), (3.75, 30.8, 1.0, 0.5)])
    place(A.prop_bench_lab, coll, root, "LS_Bench_East", (5.5, 30.0, 0), -90)
    place(A.prop_bench_lab, coll, root, "LS_Bench_North", (3.6, 31.5, 0), 0)
    place(A.prop_centrifuge, coll, root, "LS_Centrifuge", (5.45, 30.6, 0.9), -90)
    place(A.prop_freezer_upright, coll, root, "LS_Freezer", (4.3, 28.57, 0), 180)
    place(A.prop_bin_sharps, coll, root, "LS_SharpsBin", (5.45, 30.05, 0.9), -90)
    place(A.prop_dispenser_handgel, coll, root, "LS_HandGel", (1.606, 29.2, 1.2), 90)
    place(A.prop_chair_office, coll, root, "LS_Stool", (4.8, 30.0, 0), 90)
    tag(place(A.prop_folder_chart, coll, root, "LS_Document_SampleManifest", (3.3, 31.45, 0.9), 170),
        "Sample manifest; the count leaving this room does not match the count logged in storage.")
    L.camera_marker("CAM_LS_Establishing", coll, root, (2.0, 28.4, 2.3), (5.0, 30.8, 0.9), 18)
    return root


def build_sample_storage(coll):
    root = east_room(coll, "ENV_SecureSampleStorage", "Secure sample storage", 20.0, 28.0,
                     panel_lights(3.75, 20.0, 28.0, 2.0), solid_ceiling=True)
    for i, y in enumerate((20.8, 21.75, 22.7, 26.25, 27.2)):
        place(A.prop_freezer_upright, coll, root, "SS_Freezer_%d" % i, (5.45, y, 0), -90)
    odd = place(A.prop_freezer_upright, coll, root, "SS_Freezer_Unlabelled", (2.15, 20.57, 0), 180)
    lock = MeshBuilder()
    lock.box((0.06, 0.03, 0.08), (1.83, 21.08, 0.95), "M_Steel_Brushed")
    lock.box((0.012, 0.012, 0.12), (1.83, 21.07, 1.03), "M_Metal_Dark")
    tag(lock.build("SS_Freezer_Unlabelled_Padlock", coll, root), "Second padlock; no contents label, no study number.")
    tag(odd, "The only freezer without a contents label.")
    place(A.prop_bench_lab, coll, root, "SS_Bench", (3.5, 27.5, 0), 0)
    place(A.prop_terminal_ehr, coll, root, "SS_Terminal_Inventory", (3.0, 27.3, 0.9), 0)
    place(A.prop_camera_dome, coll, root, "SS_CCTV", (2.0, 21.0, WALL_H), 0)
    place(A.prop_clock_caged, coll, root, "SS_Clock", (5.894, 24.0, 2.3), -90)
    tag(place(A.prop_folder_chart, coll, root, "SS_Document_TemperatureLog", (4.1, 27.4, 0.9), 175),
        "Temperature log: a gap of several nights, then entries in a different hand.")
    L.camera_marker("CAM_SS_Establishing", coll, root, (2.0, 27.6, 2.3), (5.0, 21.6, 1.0), 18)
    return root


def build_wing():
    L.reset_scene()
    scene = bpy.context.scene
    wing = L.collection("FW_ResearchWing")
    S2.PREVIEW = L.collection("PREVIEW_ONLY_not_exported")
    builders = [
        (build_reception, "Research level: reception and restricted-lift landing"),
        (build_research_corridor, "Research level: research corridor"),
        (build_restricted_corridor, "Research level: restricted research corridor"),
        (build_office_a, "Research level: research physician office A"),
        (build_office_b, "Research level: research physician office B (vacated)"),
        (build_data_analysis, "Research level: data analysis office"),
        (build_records_archive, "Research level: research records archive"),
        (build_protocol_office, "Research level: undisclosed protocol office"),
        (build_assessment, "Research level: clinical assessment room"),
        (build_observation, "Research level: observation and monitoring room"),
        (build_lab_support, "Research level: laboratory support"),
        (build_sample_storage, "Research level: secure sample storage"),
    ]
    envs = []
    for builder, location in builders:
        name = builder.__name__.replace("build_", "")
        envs.append((builder(L.collection("ENV_" + name, wing)), location))

    for root, _ in envs:
        lo, hi = L.world_bounds(root)
        assert 3.0 < max(hi - lo) < 25.0, (root.name, tuple(hi - lo))
        assert -6.3 < lo.x and hi.x < 6.3 and lo.y > 19.5 and hi.y < 44.5, root.name + " outside the footprint"
        assert any(o.name.startswith("CAM_") for o in L.descendants(root)), root.name + " has no camera markers"
        assert any(o.name.endswith("-colonly") for o in L.descendants(root)), root.name + " has no collision"
    clin = bpy.data.objects["AS_Chair_Clinician"].location
    part = bpy.data.objects["AS_Chair_Participant"].location
    exit_pt = Vector((1.5, 37.0, 0))
    assert (clin - exit_pt).length < (part - exit_pt).length, "clinician must sit nearer the exit"
    lift = bpy.data.objects["RE_ElevatorDoors"].matrix_world.translation
    assert (lift - Vector((0.0, 44.0, 0.0))).length < 1e-4, "research lift must sit above the security lift"

    L.save_blend(WING_BLEND)
    records = []
    for root, location in envs:
        path = os.path.join(ENV_DIR, root.name + ".glb")
        L.export_glb(root, path)
        records.append(L.asset_record(
            root, WING_BLEND, path, location, "Floor + wall + furniture box colliders; door leaves carry their own",
            "Research level: place at the level origin (same x/y as Chapter 1; lift at x 0, y 44). CAM_* framing "
            "references; MARK_* forward = Godot -Z; LIGHTMARK_* light positions; godot_hint + story_tag mark "
            "environmental-storytelling hooks.", STATUS, REPO))
    L.write_manifest(records, MANIFEST)
    if FAST:
        return len(records)

    L.setup_render(scene, 1280, 720, samples=32)
    shots = (("CAM_RE_Establishing", "research_reception.png"), ("CAM_RC_Corridor", "research_corridor.png"),
             ("CAM_AS_Establishing", "research_assessment.png"), ("CAM_OM_Establishing", "research_observation.png"),
             ("CAM_LS_Establishing", "research_lab_support.png"), ("CAM_SS_Establishing", "research_sample_storage.png"),
             ("CAM_PO_Establishing", "research_protocol_office.png"), ("CAM_RR_Corridor", "research_restricted.png"))
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
    L.render_from(scene, plan, os.path.join(RENDER_DIR, "research_plan.png"))
    return len(records)


def main():
    n_props = build_props()
    n_envs = build_wing()
    print("STAGE4 RESEARCH OK: %d props, %d environments exported%s" % (n_props, n_envs, " (fast)" if FAST else ""))


if __name__ == "__main__":
    main()
