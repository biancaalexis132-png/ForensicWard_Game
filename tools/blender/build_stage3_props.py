"""Stage 3: medication, ward-bed, linen and emergency equipment props.

Completes the Stage 3 prop list that build_stage1_props.py started. Kept in
its own .blend so rebuilding these never touches the Stage 1 library file.

Outputs:
    assets/blender/clinical/FW_Props_Clinical_Stage3.blend
    assets/exports/clinical/props/<ASSET_ID>.glb
    assets/renders/stage3/props_stage3.png
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

BLEND = os.path.join(REPO, "assets/blender/clinical/FW_Props_Clinical_Stage3.blend")
EXPORT_DIR = os.path.join(REPO, "assets/exports/clinical/props")
RENDER_DIR = os.path.join(REPO, "assets/renders/stage3")
MANIFEST = os.path.join(REPO, "assets/asset_manifest/asset_manifest.json")
STATUS = "v1 geometry complete; untextured PBR (Stage 8: textures/UVs)"

LOCATIONS = {
    "PROP_Cart_Medication": "Nursing station / clinic room (locked when unattended)",
    "PROP_Bed_Hospital_Adjustable": "Medical bay or infirmary only",
    "PROP_Trolley_Linen": "Corridors and sluice, staff-escorted",
    "PROP_Cart_Crash_Resus": "Nursing station alcove or clinic room",
    "PROP_Cabinet_AED_Wall": "Staff corridor walls at 1.2 m, beside the nursing station",
    "PROP_Cylinder_Oxygen_Trolley": "Clinic room or beside the resuscitation trolley",
    "PROP_Monitor_VitalSigns_Stand": "Clinic room, medical bay, patient rooms during observations",
    "PROP_Bin_Sharps": "Clinic room and medication cart top",
    "PROP_Dispenser_HandGel": "Staff-side walls at 1.2 m (nursing station, office doors)",
    "PROP_Wheelchair": "Ward entry, medical bay",
}
WALL_MOUNTED = {"PROP_Cabinet_AED_Wall", "PROP_Dispenser_HandGel"}
SUPERVISION = ("Staff-only / supervised areas (not for unsupervised patient spaces): "
               "this equipment has ligature, weapon or ingestion risks by design")


def main():
    L.reset_scene()
    scene = bpy.context.scene
    coll = L.collection("FW_Props_Clinical_Stage3")
    records = []
    for i, builder in enumerate(A.STAGE3_PROP_BUILDERS):
        loc = ((i % 5) * 2.4, (i // 5) * 3.0, 0)
        root = builder(coll, loc=loc)
        has_col = any(o.name.endswith("-colonly") for o in L.descendants(root))
        origin = "mounting surface" if root.name in WALL_MOUNTED else "floor centre"
        records.append((root, LOCATIONS[root.name],
                        "Box collider (-colonly)" if has_col else "Decorative: no collision",
                        SUPERVISION + ". Origin: " + origin + "."))

    for root, *_ in records:
        lo, hi = L.world_bounds(root)
        assert max(hi - lo) < 3.0, "%s too large" % root.name
        assert lo.z > -0.01 or root.name in WALL_MOUNTED, "%s below the floor" % root.name
        assert any(o.type == "MESH" for o in L.descendants(root)), root.name

    L.save_blend(BLEND)
    manifest = []
    for root, location, collision, notes in records:
        path = os.path.join(EXPORT_DIR, root.name + ".glb")
        L.export_glb(root, path)
        manifest.append(L.asset_record(root, BLEND, path, location, collision, notes, STATUS, REPO))
    L.write_manifest(manifest, MANIFEST)

    for root, *_ in records:
        if root.name in WALL_MOUNTED:
            root.location.z += 1.2
    L.setup_render(scene, 1600, 900, samples=32)
    sun = bpy.data.lights.new("PreviewSun", "SUN")
    sun.energy = 3.0
    sun_ob = bpy.data.objects.new("PreviewSun", sun)
    scene.collection.objects.link(sun_ob)
    sun_ob.rotation_euler = (math.radians(45), 0, math.radians(-25))
    ground = MeshBuilder()
    ground.box((30, 20, 0.02), (4.8, 1.5, -0.01), "M_Floor_Vinyl_Corridor")
    ground.build("PreviewGround", scene.collection)
    cam = L.camera_marker("PreviewCam", scene.collection, None, (4.8, -9.5, 5.5), (4.8, 1.5, 0.5), 26)
    L.render_from(scene, cam, os.path.join(RENDER_DIR, "props_stage3.png"))
    print("STAGE3 PROPS OK: %d assets exported" % len(manifest))


if __name__ == "__main__":
    main()
