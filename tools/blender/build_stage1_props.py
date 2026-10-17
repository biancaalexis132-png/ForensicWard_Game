"""Stage 1/3: reusable clinical props.

Outputs:
    assets/blender/clinical/FW_Props_Clinical.blend
    assets/exports/clinical/props/<ASSET_ID>.glb
    assets/renders/stage1/props_overview.png
    assets/asset_manifest/asset_manifest.json (merged)
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
from fw_lib import MeshBuilder  # noqa: E402

BLEND = os.path.join(REPO, "assets/blender/clinical/FW_Props_Clinical.blend")
EXPORT_DIR = os.path.join(REPO, "assets/exports/clinical/props")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage1")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = "v1 geometry complete; untextured PBR (Stage 8: textures/UVs)"

LOCATIONS = {
    "furniture": "Offices, interview rooms, nursing station (see supervision notes)",
    "clinical_equipment": "Staff-only areas",
    "fixture": "Walls/ceilings throughout the clinical wing",
    "security": "Corridors, secure doors, interview rooms",
    "lighting": "Patient-accessible rooms (tamper-resistant)",
    "signage": "Beside room doors at 1.5 m",
    "document": "Desks, nursing station, archives",
    "decor": "Staff offices only",
}
PATIENT_SAFE = {"PROP_Chair_Interview_Weighted", "PROP_Table_Interview_Fixed", "PROP_Light_VandalResistant",
                "PROP_Vent_Grille_Wall", "PROP_Clock_Wall_Caged", "PROP_Camera_Dome", "PROP_Handrail_Wall_2m",
                "PROP_Acoustic_Panel", "PROP_Sign_Room", "PROP_Intercom_Speaker", "PROP_Reader_Access",
                "PROP_Bed_AntiLigature", "PROP_Wardrobe_AntiLigature"}


def main():
    L.reset_scene()
    scene = bpy.context.scene
    coll = L.collection("FW_Props_Clinical")
    records = []
    for i, builder in enumerate(A.PROP_BUILDERS):
        loc = ((i % 6) * 2.2, (i // 6) * 2.2, 0)
        root = builder(coll, loc=loc)
        has_col = any(o.name.endswith("-colonly") for o in L.descendants(root))
        supervision = ("Approved for patient-accessible areas" if root.name in PATIENT_SAFE
                       else "Staff-only / supervised areas (not for unsupervised patient spaces)")
        records.append((root, LOCATIONS.get(root["category"], ""),
                        "Box collider (-colonly)" if has_col else "Decorative: no collision",
                        supervision + ". Origin: " + (
                            "floor centre" if root["category"] == "furniture" else "mounting surface")))

    for root, *_ in records:
        lo, hi = L.world_bounds(root)
        assert max(hi - lo) < 3.0, "%s too large" % root.name
        assert any(o.type == "MESH" for o in L.descendants(root)), root.name

    L.save_blend(BLEND)
    manifest = []
    for root, location, collision, notes in records:
        path = os.path.join(EXPORT_DIR, root.name + ".glb")
        L.export_glb(root, path)
        manifest.append(L.asset_record(root, BLEND, path, location, collision, notes, STATUS, REPO))
    L.write_manifest(manifest, MANIFEST)

    # Wall-mounted props sit at z = 0 in the library; lift them for the preview.
    for root, *_ in records:
        if root["category"] in ("fixture", "security", "signage", "decor", "lighting") and \
                root.name not in ("PROP_Handrail_Wall_2m", "PROP_Camera_Dome", "PROP_Light_VandalResistant"):
            root.location.z += 1.2
        if root.name in ("PROP_Camera_Dome", "PROP_Light_VandalResistant"):
            root.location.z += 1.0
        if root.name in ("PROP_Terminal_EHR", "PROP_Phone_Institutional", "PROP_Folder_MedicalChart"):
            root.location.z += 0.75
    L.setup_render(scene, 1600, 900, samples=32)
    sun = bpy.data.lights.new("PreviewSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PreviewSun", sun)
    scene.collection.objects.link(sun_ob)
    sun_ob.rotation_euler = (math.radians(45), 0, math.radians(-25))
    ground = MeshBuilder()
    ground.box((30, 20, 0.02), (5.5, 3, -0.01), "M_Floor_Vinyl_Corridor")
    ground.build("PreviewGround", scene.collection)
    cam = L.camera_marker("PreviewCam", scene.collection, None, (5.5, -7.5, 5.5), (5.5, 2.6, 0.4), 30)
    L.render_from(scene, cam, os.path.join(RENDER_DIR, "props_overview.png"))
    print("PROPS OK: %d assets exported" % len(manifest))


if __name__ == "__main__":
    main()
