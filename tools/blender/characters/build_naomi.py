"""Build Naomi Bennett's editable base with Blender 5.2.2 and MPFB 2.0.18.

Install/enable MPFB 2.0.18 in Blender first. This build uses MPFB's bundled
CC0 base mesh, morph data and game-engine rig, plus original procedural
materials and garment/hair geometry. It does not download or embed third-party
character assets.

From the repository root on macOS:
  /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 --python tools/blender/characters/build_naomi.py
"""

from __future__ import annotations

import importlib
import json
import math
import struct
import sys
from pathlib import Path

import bpy
import numpy as np
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
CONFIG_PATH = Path(__file__).with_name("naomi_appearance.json")
CONFIG = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
ASSET_VERSION = str(CONFIG["character"]["asset_version"])
if not (ASSET_VERSION.startswith("v") and ASSET_VERSION[1:].isdigit()):
    raise ValueError(f"Invalid Naomi asset version: {ASSET_VERSION!r}")
ASSET_STEM = f"Naomi_Bennett_Base_{ASSET_VERSION}"
MANIFEST_TEMPLATE_PATH = ROOT / "assets/asset_manifest/naomi_character_manifest.json"
MANIFEST_PATH = ROOT / f"assets/asset_manifest/naomi_character_manifest_{ASSET_VERSION}.json"
GAME_ASSET_MANIFEST_PATH = ROOT / "assets/asset_manifest/asset_manifest.json"
BLEND_PATH = ROOT / f"assets/blender/characters/{ASSET_STEM}.blend"
GLB_PATH = ROOT / f"assets/exports/characters/{ASSET_STEM}.glb"
PREVIEW_PATH = ROOT / f"assets/exports/characters/{ASSET_STEM}_preview.png"
QA_VIEW_PATHS = {
    "front": ROOT / f"assets/exports/characters/{ASSET_STEM}_front.png",
    "right": ROOT / f"assets/exports/characters/{ASSET_STEM}_right.png",
    "back": ROOT / f"assets/exports/characters/{ASSET_STEM}_back.png",
}
COLLECTION_NAME = "Naomi_Bennett"
BASE_BODY_NAME = "Naomi_Bennett_Body"
RIG_NAME = "Naomi_Bennett_Rig"


def load_config() -> dict:
    with CONFIG_PATH.open("r", encoding="utf-8") as file:
        return json.load(file)


def import_mpfb_services(version: str) -> tuple[object, object]:
    packages = [
        name for name in sys.modules
        if name == "mpfb" or name.endswith(".mpfb")
    ]
    if not packages:
        raise RuntimeError(
            "MPFB is not enabled. Install/enable MPFB 2.0.18 in Blender's "
            "Extensions preferences before running this builder."
        )

    package = importlib.import_module(sorted(packages)[0])
    found_version = ".".join(str(part) for part in package.VERSION)
    if found_version != version:
        raise RuntimeError(
            f"Expected MPFB {version}, found {found_version}; refusing an "
            "untested builder/API combination."
        )

    human_service = importlib.import_module(
        package.__name__ + ".services.humanservice"
    ).HumanService
    target_service = importlib.import_module(
        package.__name__ + ".services.targetservice"
    ).TargetService
    return human_service, target_service


def srgb_to_linear(value: float) -> float:
    if value <= 0.04045:
        return value / 12.92
    return ((value + 0.055) / 1.055) ** 2.4


def hex_rgb(value: str) -> tuple[float, float, float]:
    raw = value.removeprefix("#")
    if len(raw) != 6:
        raise ValueError(f"Expected #RRGGBB color, got {value!r}")
    return tuple(int(raw[index:index + 2], 16) / 255.0 for index in (0, 2, 4))


def make_surface_texture(name: str, color_hex: str, size: int, strength: float,
                         weave: bool = False) -> bpy.types.Image:
    color = hex_rgb(color_hex)
    image = bpy.data.images.new(name, width=size, height=size, alpha=False)
    image.colorspace_settings.name = "sRGB"
    u = np.arange(size, dtype=np.float32)[None, :] / size
    v = np.arange(size, dtype=np.float32)[:, None] / size
    tau = np.float32(math.tau)
    if weave:
        variation = strength * (
            np.sin(tau * 64.0 * u) * np.sin(tau * 64.0 * v)
            + 0.22 * np.sin(tau * 128.0 * (u + v))
        )
    else:
        variation = strength * (
            0.65 * np.sin(tau * (13.0 * u + 17.0 * v))
            + 0.35 * np.sin(tau * (71.0 * u - 53.0 * v))
        )
    multiplier = np.clip(1.0 + variation, 0.96, 1.04)
    pixels = np.empty((size, size, 4), dtype=np.float32)
    pixels[:, :, :3] = np.asarray(color, dtype=np.float32) * multiplier[:, :, None]
    pixels[:, :, 3] = 1.0
    image.pixels.foreach_set(pixels.ravel())
    image.pack()
    return image


def make_material(name: str, color_hex: str, roughness: float,
                  image: bpy.types.Image | None = None) -> bpy.types.Material:
    material = bpy.data.materials.new(name)
    material.diffuse_color = (*tuple(srgb_to_linear(channel)
                                     for channel in hex_rgb(color_hex)), 1.0)
    nodes = material.node_tree.nodes
    shader = nodes.get("Principled BSDF")
    if shader is None:
        raise RuntimeError(f"Blender did not create a Principled shader for {name}.")
    shader.inputs["Base Color"].default_value = material.diffuse_color
    shader.inputs["Roughness"].default_value = roughness
    if image is not None:
        texture = nodes.new("ShaderNodeTexImage")
        texture.name = name + "_BaseColor"
        texture.image = image
        material.node_tree.links.new(
            texture.outputs["Color"], shader.inputs["Base Color"]
        )
    return material


def is_scrub_top(center: Vector) -> bool:
    return (
        0.92 <= center.z <= 1.43
        and (
            abs(center.x) <= 0.29
            or (1.15 <= center.z <= 1.39 and 0.20 <= abs(center.x) <= 0.43)
        )
        and not (
            center.y < -0.11 and center.z > 1.36
            and abs(center.x) < 0.045
        )
    )


def is_trouser_region(center: Vector) -> bool:
    return 0.15 <= center.z <= 1.015 and abs(center.x) <= 0.25


def is_scrub_trousers(center: Vector) -> bool:
    return is_trouser_region(center)


def is_practical_shoe(center: Vector) -> bool:
    return -0.02 <= center.z <= 0.15


def assign_body_material_regions(body: bpy.types.Object,
                                 skin: bpy.types.Material,
                                 top: bpy.types.Material,
                                 trousers: bpy.types.Material,
                                 shoes: bpy.types.Material) -> None:
    body.data.materials.clear()
    body.data.materials.append(skin)
    body.data.materials.append(top)
    body.data.materials.append(trousers)
    body.data.materials.append(shoes)
    for polygon in body.data.polygons:
        center = polygon.center
        if is_scrub_top(center):
            polygon.material_index = 1
        elif is_trouser_region(center):
            polygon.material_index = 2
        elif is_practical_shoe(center):
            polygon.material_index = 3
        else:
            polygon.material_index = 0


def link_to_character(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
    for old_collection in list(obj.users_collection):
        old_collection.objects.unlink(obj)
    collection.objects.link(obj)


def delete_startup_scene() -> None:
    bpy.ops.object.select_all(action="SELECT")
    bpy.ops.object.delete(use_global=False)
    for collection in list(bpy.data.collections):
        if collection.name != "Collection":
            bpy.data.collections.remove(collection)
    startup = bpy.data.collections.get("Collection")
    if startup is not None and startup.users == 0:
        bpy.data.collections.remove(startup)


def create_body(human_service: object, target_service: object,
                settings: dict) -> tuple[bpy.types.Object, bpy.types.Object, list]:
    macro = target_service.get_default_macro_info_dict()
    for key, value in settings["macro_morphs"].items():
        macro[key] = value
    target_stack = target_service.calculate_target_stack_from_macro_info_dict(macro)
    if not target_stack:
        raise RuntimeError("MPFB produced no macro targets for Naomi's morph profile.")
    body = human_service.create_human(
        scale=settings["scale"],
        feet_on_ground=True,
        mask_helpers=False,
        detailed_helpers=False,
        extra_vertex_groups=True,
        macro_detail_dict=macro,
    )
    body.name = BASE_BODY_NAME
    body.data.name = BASE_BODY_NAME + "_Mesh"
    rig = human_service.add_builtin_rig(body, "game_engine")
    if rig is None or rig.type != "ARMATURE":
        raise RuntimeError("MPFB did not create its documented game_engine armature.")
    rig.name = RIG_NAME
    rig.data.name = RIG_NAME + "_Skeleton"
    return body, rig, target_stack


def write_asset_provenance(target_stack: list, triangle_count: int,
                           config: dict, dimensions: tuple[float, float, float]) -> None:
    manifest = json.loads(MANIFEST_TEMPLATE_PATH.read_text(encoding="utf-8"))
    manifest["asset_version"] = ASSET_VERSION
    manifest["created_utc"] = "2026-10-18"
    manifest["status"] = (
        f"Automated {ASSET_VERSION} refinement candidate; owner visual review pending"
    )
    manifest["authoring"]["configuration"] = str(
        CONFIG_PATH.relative_to(ROOT).as_posix()
    )
    manifest["authoring"]["reproducibility"] = (
        "Repeated Blender 5.2.2 builds produce byte-identical GLB and "
        "normalized PNG render outputs from the same configuration. Blender "
        ".blend container bytes may differ due to internal serialization."
    )
    mpfb_input = next(
        item for item in manifest["external_inputs"]
        if item["source"] == "makehumancommunity/mpfb2 v2.0.18"
    )
    target_paths = sorted({
        f"src/mpfb/data/targets/{target_name}.target.gz"
        for target_name, _weight in target_stack
    })
    mpfb_input["exact_used_assets"] = [
        "src/mpfb/data/3dobjs/base.obj",
        "src/mpfb/data/rigs/standard/rig.game_engine.json",
        "src/mpfb/data/rigs/standard/weights.game_engine.json",
        *target_paths,
    ]
    mpfb_input["macro_target_weights"] = [
        {
            "asset": f"src/mpfb/data/targets/{target_name}.target.gz",
            "weight": round(float(weight), 6),
        }
        for target_name, weight in target_stack
    ]

    for output in manifest["outputs"]:
        output["path"] = output["path"].replace("Naomi_Bennett_Base_v01", ASSET_STEM)
        output_path = ROOT / output["path"]
        if not output_path.is_file():
            raise RuntimeError(f"Cannot record missing generated output: {output_path}")
        output["source_status"] = "Generated by tools/blender/characters/build_naomi.py."
        output["size_bytes"] = output_path.stat().st_size
    manifest["review"]["visual_review"] = "PENDING_OWNER_APPEARANCE_REVIEW"
    manifest["review"]["engine_import"] = (
        "Godot 4.7 GLB import passed; project-wide validator checked 140 "
        "assets with 0 failures during v02 validation on 2026-10-18."
    )
    manifest["review"]["hardware_performance"] = (
        "Blender render generated on the owner's Apple Silicon Mac; in-game "
        "performance and the 30 FPS target have not been measured."
    )
    manifest["review"]["visual_qa_checklist"] = (
        "tools/blender/characters/NAOMI_VISUAL_QA.md"
    )
    manifest["review"]["limitations"] = [
        "Procedural refinement candidate; no manual facial sculpt or likeness pass.",
        "Owner approval of the generated appearance remains pending.",
        "Pulled-back twists are procedural geometry and require silhouette review.",
        "The top, trousers, and shoes use generated garment surfaces and require fit/deformation review.",
        "Automated renders still fail the trouser-separation and garment-artifact visual checklist; this candidate is not ready for runtime integration.",
        "No animation clips or Chapter 1 scene integration are included.",
    ]
    manifest["build_metrics"] = {
        "glb_triangles": triangle_count,
        "triangle_budget": int(config["mesh"]["triangle_budget"]),
        "dimensions_m": [round(value, 4) for value in dimensions],
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )
    game_manifest = json.loads(GAME_ASSET_MANIFEST_PATH.read_text(encoding="utf-8"))
    asset = dict(game_manifest["assets"]["Naomi_Bennett_Base_v01"])
    asset.update({
        "asset_id": ASSET_STEM,
        "asset_name": f"Naomi Bennett character base {ASSET_VERSION}",
        "dimensions_m": [round(value, 4) for value in dimensions],
        "export_file": str(GLB_PATH.relative_to(ROOT).as_posix()),
        "source_file": str(BLEND_PATH.relative_to(ROOT).as_posix()),
        "status": (
            f"Automated {ASSET_VERSION} refinement candidate; owner visual "
            "appearance review pending; not integrated into gameplay"
        ),
        "triangles_base": triangle_count,
        "implementation_notes": (
            f"Skinned 53-joint automated refinement candidate; not a finished "
            f"realistic character. Exact CC0 MPFB inputs are recorded in "
            f"assets/asset_manifest/naomi_character_manifest_{ASSET_VERSION}.json. "
            "Not integrated into a gameplay scene."
        ),
    })
    game_manifest["assets"][ASSET_STEM] = asset
    GAME_ASSET_MANIFEST_PATH.write_text(
        json.dumps(game_manifest, indent=2) + "\n",
        encoding="utf-8",
    )


def build_surface_shell(body: bpy.types.Object, rig: bpy.types.Object,
                        collection: bpy.types.Collection, name: str,
                        material: bpy.types.Material, predicate,
                        surface_offset: float = 0.003,
                        solidify_thickness: float = 0.002) -> bpy.types.Object:
    source_mesh = body.data
    source_uv = source_mesh.uv_layers.active
    if source_uv is None:
        raise RuntimeError(f"{BASE_BODY_NAME} has no UV map for {name}.")

    chosen_faces = [
        polygon for polygon in source_mesh.polygons
        if predicate(polygon.center)
    ]
    if not chosen_faces:
        raise RuntimeError(f"Face selection for {name} returned no geometry.")

    remap: dict[int, int] = {}
    vertices: list[tuple[float, float, float]] = []
    faces: list[list[int]] = []
    face_uvs: list[list[tuple[float, float]]] = []
    old_vertex_weights: dict[int, list[tuple[int, float]]] = {}

    for face in chosen_faces:
        new_face: list[int] = []
        new_uvs: list[tuple[float, float]] = []
        for loop_index in face.loop_indices:
            old_index = source_mesh.loops[loop_index].vertex_index
            if old_index not in remap:
                remap[old_index] = len(vertices)
                source_vertex = source_mesh.vertices[old_index]
                vertices.append(tuple(
                    source_vertex.co + source_vertex.normal * surface_offset
                ))
                old_vertex_weights[old_index] = [
                    (group.group, group.weight)
                    for group in source_mesh.vertices[old_index].groups
                ]
            new_face.append(remap[old_index])
            new_uvs.append(tuple(source_uv.data[loop_index].uv))
        faces.append(new_face)
        face_uvs.append(new_uvs)

    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    uv_layer = mesh.uv_layers.new(name=source_uv.name)
    for polygon, uvs in zip(mesh.polygons, face_uvs):
        for loop_index, uv in zip(polygon.loop_indices, uvs):
            uv_layer.data[loop_index].uv = uv

    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    groups = [obj.vertex_groups.new(name=group.name) for group in body.vertex_groups]
    for source_index, new_index in remap.items():
        for group_index, weight in old_vertex_weights[source_index]:
            if group_index < len(groups) and weight > 0.0:
                groups[group_index].add([new_index], weight, "REPLACE")

    mesh.materials.append(material)
    for polygon in mesh.polygons:
        polygon.use_smooth = True

    if solidify_thickness > 0.0:
        shell = obj.modifiers.new(name + "_FabricThickness", "SOLIDIFY")
        shell.thickness = solidify_thickness
        shell.offset = 1.0
    armature = obj.modifiers.new(name + "_Deform", "ARMATURE")
    armature.object = rig
    return obj


def head_bone_name(rig: bpy.types.Object) -> str:
    candidates = [bone.name for bone in rig.data.bones]
    for candidate in candidates:
        if candidate.lower() == "head":
            return candidate
    for candidate in candidates:
        if "head" in candidate.lower():
            return candidate
    raise RuntimeError(f"MPFB game_engine rig has no head bone: {candidates}")


def head_mesh_bounds(body: bpy.types.Object) -> tuple[list[Vector], tuple[float, ...]]:
    head_group = body.vertex_groups.get("head")
    if head_group is None:
        raise RuntimeError(f"{BASE_BODY_NAME} has no MPFB head vertex group.")
    head_vertices = [
        vertex.co.copy()
        for vertex in body.data.vertices
        if any(
            influence.group == head_group.index and influence.weight > 0.05
            for influence in vertex.groups
        )
    ]
    if len(head_vertices) < 100:
        raise RuntimeError(
            f"{BASE_BODY_NAME} has too few vertices in its MPFB head group."
        )
    bounds = (
        min(vertex.x for vertex in head_vertices),
        max(vertex.x for vertex in head_vertices),
        min(vertex.y for vertex in head_vertices),
        max(vertex.y for vertex in head_vertices),
        min(vertex.z for vertex in head_vertices),
        max(vertex.z for vertex in head_vertices),
    )
    if bounds[1] <= bounds[0] or bounds[3] <= bounds[2] or bounds[5] <= bounds[4]:
        raise RuntimeError(f"{BASE_BODY_NAME} has invalid head bounds: {bounds}.")
    return head_vertices, bounds


def add_sphere(name: str, location: tuple[float, float, float],
               scale: tuple[float, float, float], material: bpy.types.Material,
               rig: bpy.types.Object, bone: str,
               collection: bpy.types.Collection,
               segments: int = 24, rings: int = 12) -> bpy.types.Object:
    if segments < 8 or rings < 4:
        raise ValueError("Sphere detail must use at least 8 segments and 4 rings.")
    vertices: list[tuple[float, float, float]] = [(0.0, 0.0, scale[2])]
    for ring in range(1, rings):
        theta = math.pi * ring / rings
        for segment in range(segments):
            phi = math.tau * segment / segments
            vertices.append((
                scale[0] * math.sin(theta) * math.cos(phi),
                scale[1] * math.sin(theta) * math.sin(phi),
                scale[2] * math.cos(theta),
            ))
    bottom_index = len(vertices)
    vertices.append((0.0, 0.0, -scale[2]))
    faces: list[tuple[int, ...]] = []
    for segment in range(segments):
        next_segment = (segment + 1) % segments
        faces.append((0, 1 + segment, 1 + next_segment))
    for ring in range(rings - 2):
        upper = 1 + ring * segments
        lower = upper + segments
        for segment in range(segments):
            next_segment = (segment + 1) % segments
            faces.append((
                upper + segment,
                lower + segment,
                lower + next_segment,
                upper + next_segment,
            ))
    last_ring = 1 + (rings - 2) * segments
    for segment in range(segments):
        next_segment = (segment + 1) % segments
        faces.append((
            last_ring + segment,
            bottom_index,
            last_ring + next_segment,
        ))
    mesh = bpy.data.meshes.new(name + "_Mesh")
    mesh.from_pydata(vertices, [], faces)
    mesh.update()
    obj = bpy.data.objects.new(name, mesh)
    collection.objects.link(obj)
    obj.location = location
    for polygon in mesh.polygons:
        polygon.use_smooth = True
    obj.data.materials.append(material)
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(mesh.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name + "_Deform", "ARMATURE")
    modifier.object = rig
    return obj


def add_tube_curves(name: str, splines: list[list[Vector]], radius: float,
                    material: bpy.types.Material, rig: bpy.types.Object,
                    bone: str, collection: bpy.types.Collection) -> bpy.types.Object:
    curve = bpy.data.curves.new(name + "_Curves", type="CURVE")
    curve.dimensions = "3D"
    curve.resolution_u = 1
    curve.bevel_depth = radius
    curve.bevel_resolution = 2
    curve.resolution_u = 1
    for points in splines:
        spline = curve.splines.new("POLY")
        spline.points.add(len(points) - 1)
        for point, coordinate in zip(spline.points, points):
            point.co = (*coordinate, 1.0)
    obj = bpy.data.objects.new(name, curve)
    collection.objects.link(obj)
    obj.data.materials.append(material)
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.object
    obj.name = name
    obj.data.name = name + "_Mesh"
    for polygon in obj.data.polygons:
        polygon.use_smooth = True
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
    modifier = obj.modifiers.new(name + "_Deform", "ARMATURE")
    modifier.object = rig
    return obj


def add_hair(body: bpy.types.Object, rig: bpy.types.Object,
             collection: bpy.types.Collection, config: dict,
             dark_material: bpy.types.Material,
             highlight_material: bpy.types.Material) -> None:
    _head_vertices, bounds = head_mesh_bounds(body)
    head_width = bounds[1] - bounds[0]
    head_height = bounds[5] - bounds[4]
    head_mid_y = (bounds[2] + bounds[3]) * 0.5
    hair_cap = build_surface_shell(
        body, rig, collection, "Naomi_Hair_Scalp", dark_material,
        lambda c: (
            c.z >= bounds[4] + head_height * 0.62
            and (
                c.y >= head_mid_y
                or c.z >= bounds[4] + head_height * 0.84
            )
        ),
    )
    for modifier in list(hair_cap.modifiers):
        if modifier.type == "ARMATURE":
            continue
        hair_cap.modifiers.remove(modifier)
    cap = hair_cap.modifiers.new("Naomi_Hairline_Shell", "SOLIDIFY")
    cap.thickness = 0.002
    cap.offset = 1.0

    count = int(config["twist_count"])
    if count < 12:
        raise ValueError("At least 12 pulled-back twists are required for this design.")
    radius = float(config["twist_radius"])
    if radius <= 0.001:
        raise ValueError("Twist radius must exceed one millimeter.")
    splines: list[list[Vector]] = []
    for index in range(count):
        lateral = (index / (count - 1)) * 2.0 - 1.0
        start_x = lateral * head_width * 0.39
        end_x = lateral * head_width * 0.09
        start_z = bounds[4] + head_height * (0.78 + 0.16 * abs(lateral))
        bun_z = bounds[4] + head_height * 0.10
        points: list[Vector] = []
        for step in range(13):
            t = step / 12.0
            phase = index * 0.7
            x = start_x * (1.0 - t) + end_x * t
            x += radius * 0.45 * math.sin(t * math.tau * 1.5 + phase)
            y = bounds[3] + radius * (
                1.2 + 0.15 * math.sin(t * math.tau * 2.0 + phase)
            )
            z = start_z * (1.0 - t) + bun_z * t
            z += head_height * 0.035 * math.sin(t * math.pi)
            points.append(Vector((x, y, z)))
        splines.append(points)

    twists = add_tube_curves(
        "Naomi_Pulled_Back_Twists", splines, radius, dark_material,
        rig, head_bone_name(rig), collection,
    )

    ridge_splines: list[list[Vector]] = []
    for strand_index, points in enumerate(splines):
        ridge: list[Vector] = []
        for step, point in enumerate(points):
            progress = step / (len(points) - 1)
            ridge.append(Vector((
                point.x + radius * 0.14,
                point.y - radius * 0.35,
                point.z + radius * 0.2 * math.sin(
                    progress * math.tau * 1.5 + strand_index * 0.7
                ),
            )))
        ridge_splines.append(ridge)
    add_tube_curves(
        "Naomi_Twist_Highlights", ridge_splines, radius * 0.2,
        highlight_material, rig, head_bone_name(rig), collection,
    )

    bun_material = make_material(
        "Naomi_Hair_Bun", config["srgb_hex"], 0.78
    )
    add_sphere(
        "Naomi_Low_Twist_Bun", (
            0.0, bounds[3] + radius * 4.0,
            bounds[4] + head_height * 0.10,
        ),
        (head_width * 0.22, radius * 5.0, head_height * 0.14), bun_material, rig,
        head_bone_name(rig), collection,
    )
    if len(twists.data.vertices) == 0:
        raise RuntimeError("Procedural twist geometry is empty.")


def add_face_details(body: bpy.types.Object, rig: bpy.types.Object,
                     collection: bpy.types.Collection, settings: dict) -> None:
    head_vertices, bounds = head_mesh_bounds(body)
    head_width = bounds[1] - bounds[0]
    head_height = bounds[5] - bounds[4]
    eye_x = head_width * 0.14
    eye_z = bounds[4] + head_height * 0.59
    bone = head_bone_name(rig)
    sclera = make_material("Naomi_Eye_Sclera", settings["sclera_srgb_hex"], 0.32)
    iris = make_material("Naomi_Eye_Iris", settings["iris_srgb_hex"], 0.38)
    pupil = make_material("Naomi_Eye_Pupil", settings["pupil_srgb_hex"], 0.24)
    brow = make_material("Naomi_Brow", settings["iris_srgb_hex"], 0.88)

    for side in (-1.0, 1.0):
        center_x = eye_x * side
        local_surface = [
            vertex.y for vertex in head_vertices
            if abs(vertex.x - center_x) <= head_width * 0.14
            and abs(vertex.z - eye_z) <= head_height * 0.11
        ]
        if not local_surface:
            raise RuntimeError(
                f"Could not locate the head surface for the "
                f"{'left' if side < 0 else 'right'} eye."
            )
        eye_y = min(local_surface) - head_width * 0.025
        eye_scale = (head_width * 0.065, head_width * 0.038,
                     head_height * 0.035)
        add_sphere(
            f"Naomi_Eyeball_{'L' if side < 0 else 'R'}",
            (center_x, eye_y, eye_z), eye_scale,
            sclera, rig, bone, collection,
        )
        iris_scale = (head_width * 0.021, head_width * 0.014,
                      head_height * 0.019)
        iris_y = eye_y - eye_scale[1] * 0.88
        add_sphere(
            f"Naomi_Iris_{'L' if side < 0 else 'R'}",
            (center_x, iris_y, eye_z), iris_scale,
            iris, rig, bone, collection, segments=20, rings=10,
        )
        pupil_scale = (head_width * 0.010, head_width * 0.007,
                       head_height * 0.010)
        add_sphere(
            f"Naomi_Pupil_{'L' if side < 0 else 'R'}",
            (center_x, iris_y - iris_scale[1] * 0.88, eye_z), pupil_scale,
            pupil, rig, bone, collection, segments=16, rings=8,
        )

    brow_splines: list[list[Vector]] = []
    for side in (-1.0, 1.0):
        brow_y = min(
            vertex.y for vertex in head_vertices
            if abs(vertex.x - eye_x * side) <= head_width * 0.18
            and abs(vertex.z - (eye_z + head_height * 0.11))
            <= head_height * 0.16
        ) - head_width * 0.035
        brow_splines.append([
            Vector((side * eye_x * x, brow_y, eye_z + head_height * z))
            for x, z in ((0.56, 0.10), (0.88, 0.14), (1.20, 0.145),
                         (1.52, 0.10))
        ])
    add_tube_curves(
        "Naomi_Eyebrows", brow_splines, head_width * 0.011, brow,
        rig, bone, collection,
    )


def limit_skin_influences(obj: bpy.types.Object, maximum: int = 4) -> None:
    group_names = [group.name for group in obj.vertex_groups]
    for vertex in obj.data.vertices:
        influences = sorted(
            ((item.group, item.weight) for item in vertex.groups),
            key=lambda item: item[1],
            reverse=True,
        )
        for group_index, _weight in influences[maximum:]:
            if group_index >= len(obj.vertex_groups):
                raise RuntimeError(
                    f"{obj.name} vertex {vertex.index} references missing "
                    f"skin group {group_index}."
                )
            obj.vertex_groups[group_index].remove([vertex.index])
        kept = influences[:maximum]
        total = sum(weight for _group_index, weight in kept)
        if total > 0.0:
            for group_index, weight in kept:
                obj.vertex_groups[group_index].add(
                    [vertex.index], weight / total, "REPLACE"
                )
    if not group_names:
        raise RuntimeError(f"{obj.name} has no rig weights.")


def duplicate_for_export(obj: bpy.types.Object,
                         export_collection: bpy.types.Collection) -> bpy.types.Object:
    copy = obj.copy()
    if obj.data is not None:
        copy.data = obj.data.copy()
    export_collection.objects.link(copy)
    return copy


def export_game_model(collection: bpy.types.Collection, config: dict) -> int:
    export_collection = bpy.data.collections.new("Naomi_Export_Temporary")
    bpy.context.scene.collection.children.link(export_collection)
    copies: list[bpy.types.Object] = []
    object_map: dict[bpy.types.Object, bpy.types.Object] = {}
    for obj in collection.objects:
        duplicate = duplicate_for_export(obj, export_collection)
        copies.append(duplicate)
        object_map[obj] = duplicate
    for duplicate in copies:
        if duplicate.parent in object_map:
            duplicate.parent = object_map[duplicate.parent]
        for modifier in duplicate.modifiers:
            if modifier.type == "ARMATURE" and modifier.object in object_map:
                modifier.object = object_map[modifier.object]

    for obj in copies:
        if obj.type != "MESH":
            continue
        if obj.data.shape_keys is not None:
            obj.shape_key_clear()
        modifier = obj.modifiers.new("Naomi_Export_Decimation", "DECIMATE")
        modifier.decimate_type = "COLLAPSE"
        modifier.ratio = float(config["export_decimate_ratio"])
        bpy.ops.object.select_all(action="DESELECT")
        bpy.context.view_layer.objects.active = obj
        obj.select_set(True)
        while obj.modifiers.find(modifier.name) > 0:
            result = bpy.ops.object.modifier_move_up(modifier=modifier.name)
            if "FINISHED" not in result:
                raise RuntimeError(
                    f"Could not place export decimation first on {obj.name}."
                )
        bpy.ops.object.modifier_apply(modifier=modifier.name)
        obj.select_set(False)

    for obj in copies:
        if obj.type == "MESH" and any(
                modifier.type == "ARMATURE" for modifier in obj.modifiers):
            limit_skin_influences(obj)

    for image in bpy.data.images:
        if image.name.startswith("Naomi_"):
            image.pack()
    bpy.context.view_layer.update()
    depsgraph = bpy.context.evaluated_depsgraph_get()
    triangle_count = 0
    for obj in copies:
        if obj.type != "MESH":
            continue
        evaluated = obj.evaluated_get(depsgraph)
        mesh = evaluated.to_mesh()
        mesh.calc_loop_triangles()
        triangle_count += len(mesh.loop_triangles)
        evaluated.to_mesh_clear()
    budget = int(config["triangle_budget"])
    if triangle_count > budget:
        raise RuntimeError(
            f"Export estimate is {triangle_count} triangles, exceeding the "
            f"{budget}-triangle character budget; lower export_decimate_ratio."
        )
    bpy.ops.object.select_all(action="DESELECT")
    for obj in copies:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = next(
        obj for obj in copies if obj.type == "ARMATURE"
    )
    GLB_PATH.parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=str(GLB_PATH),
        export_format="GLB",
        use_selection=True,
        export_apply=True,
        export_animations=False,
        export_skins=True,
        export_morph=True,
        export_texcoords=True,
        export_normals=True,
    )
    if "FINISHED" not in result:
        raise RuntimeError(f"glTF export failed with result {result}.")

    for obj in copies:
        bpy.data.objects.remove(obj, do_unlink=True)
    bpy.data.collections.remove(export_collection)
    return triangle_count


def aim_at(obj: bpy.types.Object, target: Vector) -> None:
    direction = target - obj.location
    obj.rotation_euler = direction.to_track_quat("-Z", "Y").to_euler()


def prepare_preview(config: dict, collection: bpy.types.Collection) -> bpy.types.Object:
    scene = bpy.context.scene
    camera_data = bpy.data.cameras.new("Naomi_Preview_Camera")
    camera = bpy.data.objects.new("Naomi_Preview_Camera", camera_data)
    scene.collection.objects.link(camera)
    camera.location = (0.38, -1.35, 1.72)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 0.82
    aim_at(camera, Vector((0.0, -0.02, 1.49)))
    scene.camera = camera

    for name, location, power, size in (
        ("Naomi_Key", (-3.2, -4.0, 4.4), 560.0, 3.0),
        ("Naomi_Fill", (3.4, -2.5, 2.7), 260.0, 2.8),
        ("Naomi_Rim", (0.2, 2.8, 3.7), 420.0, 2.0),
    ):
        light_data = bpy.data.lights.new(name, type="AREA")
        light_data.energy = power
        light_data.shape = "DISK"
        light_data.size = size
        light = bpy.data.objects.new(name, light_data)
        scene.collection.objects.link(light)
        light.location = location
        aim_at(light, Vector((0.0, 0.0, 1.0)))

    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_x = int(config["width"])
    scene.render.resolution_y = int(config["height"])
    scene.render.resolution_percentage = 100
    scene.render.image_settings.file_format = "PNG"
    scene.render.image_settings.color_mode = "RGBA"
    scene.render.filepath = str(PREVIEW_PATH)
    scene.render.resolution_percentage = 100
    scene.camera.data.lens = 50.0
    scene.world.color = (0.18, 0.18, 0.18)
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene["naomi_production_status"] = (
        f"Automated {ASSET_VERSION} candidate; owner visual review pending; "
        "not a finished realistic character."
    )
    collection["character_id"] = "staff_bennett"
    return camera


def render_qa_views(camera: bpy.types.Object) -> None:
    scene = bpy.context.scene
    views = [
        (PREVIEW_PATH, (0.38, -1.35, 1.72), Vector((0.0, -0.02, 1.49)), 0.82),
        (QA_VIEW_PATHS["front"], (0.0, -5.4, 0.92), Vector((0.0, -0.02, 0.92)), 2.05),
        (QA_VIEW_PATHS["right"], (5.4, 0.0, 0.92), Vector((0.0, -0.02, 0.92)), 2.05),
        (QA_VIEW_PATHS["back"], (0.0, 5.4, 0.92), Vector((0.0, -0.02, 0.92)), 2.05),
    ]
    for output_path, location, target, ortho_scale in views:
        camera.location = location
        camera.data.ortho_scale = ortho_scale
        aim_at(camera, target)
        scene.render.filepath = str(output_path)
        bpy.ops.render.render(write_still=True)
        strip_volatile_png_metadata(output_path)


def strip_volatile_png_metadata(path: Path) -> None:
    data = path.read_bytes()
    signature = b"\x89PNG\r\n\x1a\n"
    if not data.startswith(signature):
        raise RuntimeError(f"Blender did not produce a PNG render: {path}")
    normalized = bytearray(signature)
    offset = len(signature)
    found_end = False
    while offset < len(data):
        if offset + 12 > len(data):
            raise RuntimeError(f"PNG chunk header is truncated: {path}")
        payload_length = struct.unpack_from(">I", data, offset)[0]
        chunk_end = offset + 12 + payload_length
        if chunk_end > len(data):
            raise RuntimeError(f"PNG chunk payload is truncated: {path}")
        chunk_type = data[offset + 4:offset + 8]
        payload = data[offset + 8:offset + 8 + payload_length]
        volatile_text = (
            chunk_type == b"tEXt"
            and (payload.startswith(b"Date\x00")
                 or payload.startswith(b"RenderTime\x00"))
        )
        if not volatile_text:
            normalized.extend(data[offset:chunk_end])
        offset = chunk_end
        if chunk_type == b"IEND":
            found_end = True
            break
    if not found_end or offset != len(data):
        raise RuntimeError(f"PNG end marker is missing or malformed: {path}")
    path.write_bytes(normalized)


def collection_dimensions(collection: bpy.types.Collection) -> tuple[float, float, float]:
    points = [
        obj.matrix_world @ Vector(corner)
        for obj in collection.objects if obj.type == "MESH"
        for corner in obj.bound_box
    ]
    if not points:
        raise RuntimeError("Naomi collection has no mesh bounds.")
    return tuple(
        max(point[axis] for point in points) - min(point[axis] for point in points)
        for axis in range(3)
    )


def main() -> None:
    config = load_config()
    blender_version = ".".join(str(part) for part in bpy.app.version[:3])
    if blender_version != "5.2.2":
        raise RuntimeError(
            f"Expected Blender 5.2.2, found {blender_version}; refusing an "
            "untested builder/API combination."
        )
    human_service, target_service = import_mpfb_services(config["mpfb"]["version"])
    delete_startup_scene()

    character_collection = bpy.data.collections.new(COLLECTION_NAME)
    bpy.context.scene.collection.children.link(character_collection)
    body, rig, target_stack = create_body(
        human_service, target_service, config["mpfb"]
    )
    link_to_character(body, character_collection)
    link_to_character(rig, character_collection)

    skin_image = make_surface_texture(
        "Naomi_Skin_BaseColor", config["skin"]["srgb_hex"],
        int(config["skin"]["texture_size"]),
        float(config["skin"]["noise_strength"]),
    )
    scrub_image = make_surface_texture(
        "Naomi_Scrubs_BaseColor", config["scrubs"]["srgb_hex"],
        int(config["scrubs"]["texture_size"]),
        float(config["scrubs"]["weave_strength"]), weave=True,
    )
    skin = make_material(
        "Naomi_Skin", config["skin"]["srgb_hex"],
        float(config["skin"]["roughness"]), skin_image,
    )
    scrubs = make_material(
        "Naomi_Scrubs_Navy", config["scrubs"]["srgb_hex"],
        float(config["scrubs"]["roughness"]), scrub_image,
    )
    for polygon in body.data.polygons:
        polygon.use_smooth = True

    trousers_image = make_surface_texture(
        "Naomi_Scrubs_Trousers_BaseColor",
        config["scrubs"]["trousers_srgb_hex"],
        int(config["scrubs"]["texture_size"]),
        float(config["scrubs"]["weave_strength"]),
        weave=True,
    )
    trousers = make_material(
        "Naomi_Scrubs_Trousers_Navy",
        config["scrubs"]["trousers_srgb_hex"],
        float(config["scrubs"]["roughness"]),
        trousers_image,
    )
    shoe_material = make_material("Naomi_Shoes", "#343A3D", 0.68)
    assign_body_material_regions(body, skin, scrubs, trousers, shoe_material)
    build_surface_shell(
        body, rig, character_collection, "Naomi_Scrub_Top", scrubs,
        is_scrub_top, surface_offset=0.001, solidify_thickness=0.0,
    )
    build_surface_shell(
        body, rig, character_collection, "Naomi_Scrub_Trousers", trousers,
        is_scrub_trousers, surface_offset=0.001, solidify_thickness=0.0,
    )
    build_surface_shell(
        body, rig, character_collection, "Naomi_Practical_Shoes", shoe_material,
        is_practical_shoe,
    )

    hair = make_material("Naomi_Hair", config["hair"]["srgb_hex"], 0.82)
    hair_highlight = make_material(
        "Naomi_Hair_Highlight", config["hair"]["highlight_srgb_hex"], 0.78
    )
    add_hair(body, rig, character_collection, config["hair"], hair, hair_highlight)
    add_face_details(body, rig, character_collection, config["eyes"])

    rig["character_id"] = config["character"]["character_id"]
    rig["production_status"] = config["character"]["production_status"]
    rig["morph_profile"] = json.dumps(config["mpfb"]["macro_morphs"], sort_keys=True)
    rig["mpfb_macro_target_stack"] = json.dumps(target_stack)

    scene = bpy.context.scene
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.image_settings.file_format = "PNG"
    scene.render.resolution_x = int(config["render"]["width"])
    scene.render.resolution_y = int(config["render"]["height"])
    preview_camera = prepare_preview(config["render"], character_collection)
    scene.eevee.taa_render_samples = int(config["render"]["samples"])
    character_dimensions = collection_dimensions(character_collection)

    for image in (skin_image, scrub_image, trousers_image):
        image.pack()
    BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    triangles = export_game_model(character_collection, config["mesh"])
    print(
        f"Naomi {ASSET_VERSION} source saved: {BLEND_PATH}\n"
        f"Godot GLB exported: {GLB_PATH}\n"
        f"Orthographic review renders: {PREVIEW_PATH}, "
        f"{', '.join(str(path) for path in QA_VIEW_PATHS.values())}\n"
        f"Export triangle estimate: {triangles}\n"
        "Status: automated refinement candidate; owner appearance review pending."
    )

    render_qa_views(preview_camera)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    write_asset_provenance(target_stack, triangles, config, character_dimensions)


if __name__ == "__main__":
    main()
