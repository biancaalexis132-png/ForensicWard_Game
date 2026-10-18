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
from pathlib import Path
import sys

import bpy
import numpy as np
from mathutils import Vector


ROOT = Path(__file__).resolve().parents[3]
CONFIG_PATH = Path(__file__).with_name("naomi_appearance.json")
MANIFEST_PATH = ROOT / "assets/asset_manifest/naomi_character_manifest.json"
BLEND_PATH = ROOT / "assets/blender/characters/Naomi_Bennett_Base_v01.blend"
GLB_PATH = ROOT / "assets/exports/characters/Naomi_Bennett_Base_v01.glb"
PREVIEW_PATH = ROOT / "assets/exports/characters/Naomi_Bennett_Base_v01_preview.png"
QA_VIEW_PATHS = {
    "front": ROOT / "assets/exports/characters/Naomi_Bennett_Base_v01_front.png",
    "right": ROOT / "assets/exports/characters/Naomi_Bennett_Base_v01_right.png",
    "back": ROOT / "assets/exports/characters/Naomi_Bennett_Base_v01_back.png",
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
    color = tuple(srgb_to_linear(channel) for channel in hex_rgb(color_hex))
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
                           config: dict) -> None:
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))
    mpfb_input = next(
        item for item in manifest["external_inputs"]
        if item["source"] == "makehumancommunity/mpfb2 v2.0.18"
    )
    target_paths = sorted({
        f"src/mpfb/data/targets/{target_name}.target"
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
            "asset": f"src/mpfb/data/targets/{target_name}.target",
            "weight": round(float(weight), 6),
        }
        for target_name, weight in target_stack
    ]

    for output in manifest["outputs"]:
        output_path = ROOT / output["path"]
        if not output_path.is_file():
            raise RuntimeError(f"Cannot record missing generated output: {output_path}")
        output["source_status"] = "Generated by tools/blender/characters/build_naomi.py."
        output["size_bytes"] = output_path.stat().st_size
    manifest["build_metrics"] = {
        "glb_triangles": triangle_count,
        "triangle_budget": int(config["mesh"]["triangle_budget"]),
    }
    MANIFEST_PATH.write_text(
        json.dumps(manifest, indent=2) + "\n",
        encoding="utf-8",
    )


def build_surface_shell(body: bpy.types.Object, rig: bpy.types.Object,
                        collection: bpy.types.Collection, name: str,
                        material: bpy.types.Material, predicate,
                        surface_offset: float = 0.003) -> bpy.types.Object:
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

    shell = obj.modifiers.new(name + "_FabricThickness", "SOLIDIFY")
    shell.thickness = 0.002
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


def add_sphere(name: str, location: tuple[float, float, float],
               scale: tuple[float, float, float], material: bpy.types.Material,
               rig: bpy.types.Object, bone: str,
               collection: bpy.types.Collection,
               segments: int = 24, rings: int = 12) -> bpy.types.Object:
    bpy.ops.object.select_all(action="DESELECT")
    bpy.ops.mesh.primitive_uv_sphere_add(
        segments=segments, ring_count=rings, radius=1.0, location=location
    )
    obj = bpy.context.object
    obj.name = name
    obj.data.name = name + "_Mesh"
    obj.scale = scale
    bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
    link_to_character(obj, collection)
    mesh = obj.data
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
    hair_cap = build_surface_shell(
        body, rig, collection, "Naomi_Hair_Scalp", dark_material,
        lambda c: c.z >= (1.605 if c.y < -0.115 else 1.535),
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
    splines: list[list[Vector]] = []
    for index in range(count):
        lateral = (index / (count - 1)) * 2.0 - 1.0
        points: list[Vector] = []
        for step in range(13):
            t = step / 12.0
            if t <= 0.84:
                progress = t / 0.84
                y = -0.08 + 0.13 * progress
                side_radius = 0.064 * math.sqrt(
                    max(0.16, 1.0 - ((y + 0.052) / 0.122) ** 2)
                )
                x = lateral * side_radius * (1.0 - 0.32 * progress)
                normalized = min(
                    0.94,
                    (x / 0.092) ** 2 + ((y + 0.052) / 0.122) ** 2,
                )
                z = 1.548 + 0.115 * math.sqrt(max(0.06, 1.0 - normalized))
            else:
                progress = (t - 0.84) / 0.16
                x = lateral * side_radius * (1.0 - progress)
                y = 0.05 + 0.035 * progress
                z = 1.60 - 0.085 * progress
            points.append(Vector((x, y, z)))
        splines.append(points)

    twists = add_tube_curves(
        "Naomi_Pulled_Back_Twists", splines, radius, dark_material,
        rig, head_bone_name(rig), collection,
    )

    # A few offset ridges keep the bundled ropes visually distinct in close views.
    ridge_splines: list[list[Vector]] = []
    for strand_index, points in enumerate(splines):
        ridge: list[Vector] = []
        phase = 1.0 if strand_index % 2 == 0 else -1.0
        for step, point in enumerate(points):
            progress = step / (len(points) - 1)
            ridge.append(Vector((
                point.x + phase * radius * 0.42,
                point.y - radius * 0.32,
                point.z + radius * math.sin(progress * math.tau * 2.0),
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
        "Naomi_Low_Twist_Bun", (0.0, 0.087, 1.515),
        (0.046, 0.032, 0.031), bun_material, rig,
        head_bone_name(rig), collection,
    )
    del twists


def add_face_details(rig: bpy.types.Object, collection: bpy.types.Collection,
                     settings: dict) -> None:
    bone = head_bone_name(rig)
    sclera = make_material("Naomi_Eye_Sclera", settings["sclera_srgb_hex"], 0.32)
    iris = make_material("Naomi_Eye_Iris", settings["iris_srgb_hex"], 0.38)
    pupil = make_material("Naomi_Eye_Pupil", settings["pupil_srgb_hex"], 0.24)
    brow = make_material("Naomi_Brow", settings["iris_srgb_hex"], 0.88)

    for side in (-1.0, 1.0):
        center_x = 0.031 * side
        add_sphere(
            f"Naomi_Eyeball_{'L' if side < 0 else 'R'}",
            (center_x, -0.124, 1.558), (0.014, 0.008, 0.0085),
            sclera, rig, bone, collection,
        )
        add_sphere(
            f"Naomi_Iris_{'L' if side < 0 else 'R'}",
            (center_x, -0.131, 1.558), (0.0045, 0.003, 0.005),
            iris, rig, bone, collection, segments=20, rings=10,
        )
        add_sphere(
            f"Naomi_Pupil_{'L' if side < 0 else 'R'}",
            (center_x, -0.1332, 1.558), (0.0022, 0.0015, 0.0028),
            pupil, rig, bone, collection, segments=16, rings=8,
        )

    brow_splines: list[list[Vector]] = []
    for side in (-1.0, 1.0):
        brow_splines.append([
            Vector((side * x, -0.125, z))
            for x, z in ((0.018, 1.575), (0.029, 1.581), (0.041, 1.582),
                         (0.053, 1.577))
        ])
    add_tube_curves(
        "Naomi_Eyebrows", brow_splines, 0.0024, brow,
        rig, bone, collection,
    )


def add_badge(rig: bpy.types.Object, collection: bpy.types.Collection) -> None:
    badge_material = make_material("Naomi_ID_Badge", "#E6E3DC", 0.48)
    clip_material = make_material("Naomi_Badge_Clip", "#66717A", 0.35)
    spine_bone = next(
        (bone.name for bone in rig.data.bones if bone.name == "spine_02"),
        next((bone.name for bone in rig.data.bones if bone.name.startswith("spine")),
             head_bone_name(rig)),
    )
    positions = (
        ("Naomi_Badge_Clip", (0.075, -0.137, 1.317), (0.007, 0.002, 0.012),
         clip_material),
        ("Naomi_ID_Card", (0.075, -0.139, 1.276), (0.030, 0.003, 0.040),
         badge_material),
    )
    for name, location, scale, material in positions:
        bpy.ops.object.select_all(action="DESELECT")
        bpy.ops.mesh.primitive_cube_add(size=1.0, location=location)
        obj = bpy.context.object
        obj.name = name
        obj.data.name = name + "_Mesh"
        obj.scale = scale
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        link_to_character(obj, collection)
        obj.data.materials.append(material)
        for polygon in obj.data.polygons:
            polygon.use_smooth = False
        obj.parent = rig
        obj.matrix_parent_inverse = rig.matrix_world.inverted()
        group = obj.vertex_groups.new(name=spine_bone)
        group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")
        modifier = obj.modifiers.new(name + "_Deform", "ARMATURE")
        modifier.object = rig


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
    camera.location = (2.6, -5.4, 2.1)
    camera_data.type = "ORTHO"
    camera_data.ortho_scale = 2.05
    aim_at(camera, Vector((0.0, -0.02, 0.92)))
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
    scene.render.resolution_percentage = 75
    scene.camera.data.lens = 50.0
    scene.world.color = (0.18, 0.18, 0.18)
    scene.render.image_settings.color_depth = "8"
    scene.render.film_transparent = False
    scene.render.filepath = str(PREVIEW_PATH)
    scene.render.engine = "BLENDER_EEVEE"
    scene.render.resolution_percentage = 75
    scene["naomi_production_status"] = (
        "Automated base. Review render and manual refinement required; "
        "not a finished realistic character."
    )
    collection["character_id"] = "staff_bennett"
    return camera


def render_qa_views(camera: bpy.types.Object) -> None:
    scene = bpy.context.scene
    target = Vector((0.0, -0.02, 0.92))
    views = [
        (PREVIEW_PATH, (2.6, -5.4, 2.1)),
        (QA_VIEW_PATHS["front"], (0.0, -5.4, 0.92)),
        (QA_VIEW_PATHS["right"], (5.4, 0.0, 0.92)),
        (QA_VIEW_PATHS["back"], (0.0, 5.4, 0.92)),
    ]
    for output_path, location in views:
        camera.location = location
        aim_at(camera, target)
        scene.render.filepath = str(output_path)
        bpy.ops.render.render(write_still=True)


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
    body.data.materials.clear()
    body.data.materials.append(skin)
    for polygon in body.data.polygons:
        polygon.material_index = 0
        polygon.use_smooth = True

    build_surface_shell(
        body, rig, character_collection, "Naomi_Scrub_Top", scrubs,
        lambda c: (
            0.92 <= c.z <= 1.43
            and (
                abs(c.x) <= 0.29
                or (1.15 <= c.z <= 1.39 and 0.20 <= abs(c.x) <= 0.43)
            )
            and not (c.y < -0.11 and c.z > 1.36 and abs(c.x) < 0.045)
        ),
    )
    build_surface_shell(
        body, rig, character_collection, "Naomi_Scrub_Trousers", scrubs,
        lambda c: 0.075 <= c.z <= 1.015 and abs(c.x) <= 0.25,
    )
    shoe_material = make_material("Naomi_Shoes", "#343A3D", 0.68)
    build_surface_shell(
        body, rig, character_collection, "Naomi_Practical_Shoes", shoe_material,
        lambda c: c.z <= 0.15 and c.z >= -0.02,
    )

    hair = make_material("Naomi_Hair", config["hair"]["srgb_hex"], 0.82)
    hair_highlight = make_material(
        "Naomi_Hair_Highlight", config["hair"]["highlight_srgb_hex"], 0.78
    )
    add_hair(body, rig, character_collection, config["hair"], hair, hair_highlight)
    add_face_details(rig, character_collection, config["eyes"])
    add_badge(rig, character_collection)

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

    for image in (skin_image, scrub_image):
        image.pack()
    BLEND_PATH.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    triangles = export_game_model(character_collection, config["mesh"])
    print(
        f"Naomi base saved: {BLEND_PATH}\n"
        f"Godot GLB exported: {GLB_PATH}\n"
        f"Orthographic review renders: {PREVIEW_PATH}, "
        f"{', '.join(str(path) for path in QA_VIEW_PATHS.values())}\n"
        f"Export triangle estimate: {triangles}\n"
        "Status: automated base; visual/manual refinement remains required."
    )

    render_qa_views(preview_camera)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_PATH))
    write_asset_provenance(target_stack, triangles, config)


if __name__ == "__main__":
    main()
