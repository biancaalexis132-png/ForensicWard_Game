"""Validate the editable Naomi blend and the exported self-contained GLB.

Run with:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/validate_naomi.py
"""

from __future__ import annotations

import json
from pathlib import Path
import struct
import sys

import bpy
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
CONFIG_PATH = Path(__file__).with_name("naomi_appearance.json")
CONFIG = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
ASSET_VERSION = str(CONFIG["character"]["asset_version"])
ASSET_STEM = f"Naomi_Bennett_Base_{ASSET_VERSION}"
BLEND_PATH = ROOT / f"assets/blender/characters/{ASSET_STEM}.blend"
GLB_PATH = ROOT / f"assets/exports/characters/{ASSET_STEM}.glb"
PREVIEW_PATH = ROOT / f"assets/exports/characters/{ASSET_STEM}_preview.png"
MANIFEST_PATH = ROOT / f"assets/asset_manifest/naomi_character_manifest_{ASSET_VERSION}.json"
GAME_ASSET_MANIFEST_PATH = ROOT / "assets/asset_manifest/asset_manifest.json"
QA_VIEW_PATHS = (
    ROOT / f"assets/exports/characters/{ASSET_STEM}_front.png",
    ROOT / f"assets/exports/characters/{ASSET_STEM}_right.png",
    ROOT / f"assets/exports/characters/{ASSET_STEM}_back.png",
)
EXPECTED_IMAGES = {
    "Naomi_Skin_BaseColor",
    "Naomi_Scrubs_BaseColor",
    "Naomi_Scrubs_Trousers_BaseColor",
}
REQUIRED_OBJECTS = {
    "Naomi_Bennett_Body",
    "Naomi_Bennett_Rig",
    "Naomi_Scrub_Top",
    "Naomi_Scrub_Trousers",
    "Naomi_Practical_Shoes",
    "Naomi_Hair_Scalp",
    "Naomi_Pulled_Back_Twists",
    "Naomi_Low_Twist_Bun",
    "Naomi_Eyeball_L",
    "Naomi_Eyeball_R",
    "Naomi_Iris_L",
    "Naomi_Iris_R",
    "Naomi_Pupil_L",
    "Naomi_Pupil_R",
}
UNAPPROVED_ACCESSORY_OBJECTS = {"Naomi_ID_Card", "Naomi_Badge_Clip"}


def fail(message: str) -> None:
    raise RuntimeError("Naomi validation failed: " + message)


def collection_dimensions(collection: bpy.types.Collection) -> list[float]:
    points = [
        obj.matrix_world @ Vector(corner)
        for obj in collection.objects if obj.type == "MESH"
        for corner in obj.bound_box
    ]
    if not points:
        fail("the Naomi collection has no mesh bounds.")
    return [
        round(max(point[axis] for point in points)
              - min(point[axis] for point in points), 4)
        for axis in range(3)
    ]


def read_glb_json(path: Path) -> dict:
    data = path.read_bytes()
    if len(data) < 20:
        fail(f"GLB is truncated ({len(data)} bytes).")
    magic, version, length = struct.unpack_from("<4sII", data, 0)
    if magic != b"glTF" or version != 2 or length != len(data):
        fail("GLB header/magic/version/length is invalid.")
    chunk_length, chunk_type = struct.unpack_from("<II", data, 12)
    if chunk_type != 0x4E4F534A or 20 + chunk_length > len(data):
        fail("GLB has no valid JSON chunk.")
    return json.loads(data[20:20 + chunk_length].decode("utf-8").rstrip(" \t\r\n\0"))


def validate_blend() -> None:
    bpy.ops.wm.open_mainfile(filepath=str(BLEND_PATH))
    collection = bpy.data.collections.get("Naomi_Bennett")
    if collection is None:
        fail("the Naomi_Bennett collection is missing from the .blend.")
    missing = REQUIRED_OBJECTS - set(bpy.data.objects.keys())
    if missing:
        fail("the .blend is missing objects: " + ", ".join(sorted(missing)))
    present_unapproved = UNAPPROVED_ACCESSORY_OBJECTS & set(bpy.data.objects.keys())
    if present_unapproved:
        fail("the .blend contains unapproved accessories: "
             + ", ".join(sorted(present_unapproved)))

    rig = bpy.data.objects["Naomi_Bennett_Rig"]
    if rig.type != "ARMATURE" or len(rig.data.bones) < 40:
        fail("the .blend rig is missing or has fewer than 40 bones.")
    if rig.get("character_id") != "staff_bennett":
        fail("the .blend rig does not preserve the staff_bennett character ID.")
    macro_profile = json.loads(rig.get("morph_profile", "{}"))
    if float(macro_profile.get("gender", 1.0)) != 0.0:
        fail("the MPFB macro profile is not set to its documented female endpoint.")
    target_stack = json.loads(rig.get("mpfb_macro_target_stack", "[]"))
    if not target_stack:
        fail("the .blend is missing its MPFB morph-target provenance.")
    if not any("african-female-" in item[0] for item in target_stack):
        fail("the rig provenance does not include female African MPFB targets.")
    if any("african-male-" in item[0] for item in target_stack):
        fail("the rig provenance unexpectedly includes male African MPFB targets.")
    body = bpy.data.objects["Naomi_Bennett_Body"]
    if body.type != "MESH" or len(body.data.vertices) < 10000:
        fail("the .blend body is not a generated human mesh.")
    if not any(
        material is not None and material.name == "Naomi_Scrubs_Navy"
        for material in body.data.materials
    ):
        fail("the source body has no scrub fabric material regions.")
    if not any(
        material is not None and material.name == "Naomi_Scrubs_Trousers_Navy"
        for material in body.data.materials
    ):
        fail("the source body has no separate scrub-trouser material region.")
    twist_mesh = bpy.data.objects["Naomi_Pulled_Back_Twists"]
    head_group = body.vertex_groups.get("head")
    if head_group is None:
        fail("the source body has no MPFB head vertex group.")
    head_y = [
        vertex.co.y
        for vertex in body.data.vertices
        if any(
            item.group == head_group.index and item.weight > 0.05
            for item in vertex.groups
        )
    ]
    if not head_y or min(vertex.co.y for vertex in twist_mesh.data.vertices) <= (
        min(head_y) + max(head_y)
    ) * 0.5:
        fail("the pulled-back twist geometry crosses the face plane.")
    for image_name in EXPECTED_IMAGES:
        image = bpy.data.images.get(image_name)
        if image is None or image.packed_file is None:
            fail(f"the .blend is missing its packed texture {image_name}.")
    if not PREVIEW_PATH.is_file() or PREVIEW_PATH.stat().st_size < 10000:
        fail("the preview render is missing or unexpectedly small.")


def validate_glb() -> tuple[int, int]:
    document = read_glb_json(GLB_PATH)
    meshes = document.get("meshes", [])
    skins = document.get("skins", [])
    materials = document.get("materials", [])
    images = document.get("images", [])
    textures = document.get("textures", [])
    if not meshes:
        fail("GLB has no meshes.")
    if not skins or not skins[0].get("joints"):
        fail("GLB has no skeletal skin/joints.")
    if len(skins[0]["joints"]) < 40:
        fail("GLB skin contains fewer than 40 joints.")
    if not any(
        {"JOINTS_0", "WEIGHTS_0"}.issubset(primitive.get("attributes", {}))
        for mesh in meshes for primitive in mesh.get("primitives", [])
    ):
        fail("GLB meshes have no joint and weight attributes.")

    embedded_images = set()
    for image in images:
        if "bufferView" in image:
            embedded_images.add(image.get("name", "").removesuffix(".png"))
        elif "uri" not in image:
            fail("GLB image has neither an embedded buffer view nor a URI.")
        elif not (GLB_PATH.parent / image["uri"]).is_file():
            fail(f"GLB references a missing external image: {image['uri']}")
    if not EXPECTED_IMAGES.issubset(embedded_images):
        fail("GLB does not embed all generated color textures: "
             + ", ".join(sorted(EXPECTED_IMAGES - embedded_images)))

    texture_indices: set[int] = set()
    for material in materials:
        pbr = material.get("pbrMetallicRoughness", {})
        base_color = pbr.get("baseColorTexture")
        if base_color is not None:
            texture_indices.add(base_color["index"])
    if not texture_indices or any(index >= len(textures) for index in texture_indices):
        fail("GLB materials do not reference valid base-color textures.")
    referenced_images = {
        images[textures[index]["source"]].get("name", "").removesuffix(".png")
        for index in texture_indices
        if "source" in textures[index]
        and textures[index]["source"] < len(images)
    }
    if not EXPECTED_IMAGES.issubset(referenced_images):
        fail("GLB materials do not reference all generated color textures.")

    triangle_count = 0
    accessors = document.get("accessors", [])
    for mesh in meshes:
        for primitive in mesh.get("primitives", []):
            if primitive.get("mode", 4) != 4:
                continue
            index_accessor = primitive.get("indices")
            if index_accessor is not None:
                triangle_count += accessors[index_accessor]["count"] // 3
            else:
                triangle_count += accessors[primitive["attributes"]["POSITION"]]["count"] // 3
    if triangle_count <= 0:
        fail("GLB contains no triangle primitives.")
    triangle_budget = int(CONFIG["mesh"]["triangle_budget"])
    if triangle_count > triangle_budget:
        fail(f"GLB exceeds its {triangle_budget}-triangle budget ({triangle_count}).")
    return triangle_count, len(skins[0]["joints"])


def validate_provenance(triangle_count: int) -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    if manifest.get("asset_version") != ASSET_VERSION:
        fail("the character manifest version does not match the configured asset.")
    if manifest.get("review", {}).get("visual_review") != "PENDING_OWNER_APPEARANCE_REVIEW":
        fail("the manifest does not keep owner appearance review pending.")
    checklist_path = manifest.get("review", {}).get("visual_qa_checklist", "")
    if not (ROOT / checklist_path).is_file():
        fail("the manifest references a missing visual QA checklist.")
    mpfb_input = next(
        (item for item in manifest.get("external_inputs", [])
         if item.get("source") == "makehumancommunity/mpfb2 v2.0.18"),
        None,
    )
    if mpfb_input is None or mpfb_input.get("license") != "CC0-1.0":
        fail("the manifest does not record the verified MPFB asset license.")
    assets = mpfb_input.get("exact_used_assets", [])
    if not assets or any("*" in asset for asset in assets):
        fail("the manifest does not enumerate the exact MPFB input assets.")
    target_assets = {
        record["asset"]
        for record in mpfb_input.get("macro_target_weights", [])
        if "asset" in record
    }
    if not target_assets or not target_assets.issubset(set(assets)):
        fail("the manifest is missing exact MPFB macro-target provenance.")
    for output in manifest.get("outputs", []):
        path = ROOT / output["path"]
        if not path.is_file() or output.get("size_bytes") != path.stat().st_size:
            fail(f"the manifest output record is stale: {output['path']}")
    if manifest.get("build_metrics", {}).get("glb_triangles") != triangle_count:
        fail("the manifest triangle count does not match the exported GLB.")
    collection = bpy.data.collections.get("Naomi_Bennett")
    if collection is None:
        fail("the Naomi collection is missing during dimension validation.")
    source_dimensions = collection_dimensions(collection)
    if manifest.get("build_metrics", {}).get("dimensions_m") != source_dimensions:
        fail("the character manifest dimensions do not match the Blender source.")


def validate_game_asset_manifest(triangle_count: int) -> None:
    manifest = json.loads(GAME_ASSET_MANIFEST_PATH.read_text(encoding="utf-8"))
    asset = manifest.get("assets", {}).get(ASSET_STEM)
    if asset is None:
        fail("the shared game asset manifest has no configured Naomi version.")
    if asset.get("export_file") != f"assets/exports/characters/{ASSET_STEM}.glb":
        fail("the shared game asset manifest points to the wrong GLB.")
    if asset.get("source_file") != f"assets/blender/characters/{ASSET_STEM}.blend":
        fail("the shared game asset manifest points to the wrong Blender source.")
    dimensions = asset.get("dimensions_m", [])
    if len(dimensions) != 3 or any(float(value) <= 0.0 for value in dimensions):
        fail("the shared game asset manifest has invalid dimensions.")
    if asset.get("triangles_base") != triangle_count:
        fail("the shared game asset manifest triangle count is stale.")


def main() -> None:
    blender_version = ".".join(str(part) for part in bpy.app.version[:3])
    if blender_version != "5.2.2":
        fail(f"expected Blender 5.2.2, found {blender_version}.")
    if not BLEND_PATH.is_file():
        fail(f"missing editable source: {BLEND_PATH}")
    if not GLB_PATH.is_file():
        fail(f"missing exported model: {GLB_PATH}")
    validate_blend()
    triangles, joints = validate_glb()
    validate_provenance(triangles)
    validate_game_asset_manifest(triangles)
    for path in (PREVIEW_PATH, *QA_VIEW_PATHS):
        if not path.is_file() or path.stat().st_size < 10000:
            fail(f"missing or unexpectedly small review render: {path}")
    print(
        "Naomi outputs validated: "
        f"{len(REQUIRED_OBJECTS)} required scene objects, {joints} GLB joints, "
        f"{triangles} GLB triangles, {len(EXPECTED_IMAGES)} referenced embedded "
        f"textures, {1 + len(QA_VIEW_PATHS)} review renders."
    )


if __name__ == "__main__":
    try:
        main()
    except Exception as error:
        print(str(error), file=sys.stderr)
        raise
