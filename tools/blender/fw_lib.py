"""The Forensic Ward: Blender asset-pipeline core.

Shared by every build script in tools/blender/. Provides:
  * the project material library (PBR values that export to glTF 2.0),
  * MeshBuilder: composes boxes/cylinders/spheres into one multi-material
    mesh with a transform stack (no bpy.ops, so it runs headless),
  * object, marker, camera and preview-light helpers,
  * export of one asset root (+ descendants) to .glb at the origin,
  * the asset manifest writer.

Conventions (see docs/ENVIRONMENT_PIPELINE.md):
  * metres, Blender Z-up (glTF/Godot convert to Y-up automatically),
  * shared 0.5 m grid, 2.0 m primary module, 3.0 m floor-to-ceiling,
    0.2 m walls centred on grid lines,
  * Godot import suffixes: "-colonly" = collision-only static body,
  * markers: CAM_* (glTF cameras), MARK_* (empties), LIGHTMARK_* (empties
    where Godot should place lights; lights are never baked).
"""

import json
import math
import os

import bmesh
import bpy
from mathutils import Euler, Matrix, Vector

WALL_H = 3.0
WALL_T = 0.2
DOOR_H = 2.2
GRID = 0.5

# --------------------------------------------------------------------------
# Materials
# --------------------------------------------------------------------------

# name: (sRGB hex, roughness, metallic, extra)
PALETTE = {
    "M_Wall_WarmWhite": ("#D9D3C7", 0.85, 0.0, {}),
    "M_Wall_InterviewBlueGrey": ("#A9B4B8", 0.85, 0.0, {}),
    "M_Wall_OfficeSage": ("#B9C2B0", 0.85, 0.0, {}),
    "M_Wall_Protection_Green": ("#6E8C7A", 0.55, 0.0, {}),
    "M_Skirting_Coved": ("#4A4F4F", 0.6, 0.0, {}),
    "M_Floor_Vinyl_Corridor": ("#7C8582", 0.35, 0.0, {}),
    "M_Floor_Vinyl_Interview": ("#6F7A80", 0.4, 0.0, {}),
    "M_Floor_Vinyl_WoodOffice": ("#8A6E52", 0.45, 0.0, {}),
    "M_Ceiling_Tile": ("#E8E6E1", 0.95, 0.0, {}),
    "M_Ceiling_Grid": ("#D5D5D2", 0.5, 0.3, {}),
    "M_Steel_Brushed": ("#A7AAAD", 0.3, 1.0, {}),
    "M_Steel_Painted_Grey": ("#5E6468", 0.5, 0.4, {}),
    "M_Steel_Painted_White": ("#E3E3DE", 0.45, 0.2, {}),
    "M_Door_Secure_SteelBlue": ("#5B6E7C", 0.42, 0.5, {}),
    "M_Door_Laminate_Wood": ("#9C7A57", 0.5, 0.0, {}),
    "M_Wood_Laminate_Desk": ("#A68462", 0.5, 0.0, {}),
    "M_Upholstery_Teal": ("#3E6B6E", 0.9, 0.0, {}),
    "M_Upholstery_Charcoal": ("#3A3D40", 0.9, 0.0, {}),
    "M_Polyurethane_Interview": ("#5C7C8A", 0.6, 0.0, {}),
    "M_Plastic_Black": ("#141516", 0.4, 0.0, {}),
    "M_Plastic_OffWhite": ("#DAD7CF", 0.45, 0.0, {}),
    "M_Rubber_Dark": ("#2B2E30", 0.8, 0.0, {}),
    "M_Acoustic_Fabric": ("#7E8A8C", 1.0, 0.0, {}),
    "M_Paper": ("#EEEBE2", 0.9, 0.0, {}),
    "M_Binder_Navy": ("#2C3E5C", 0.5, 0.0, {}),
    "M_Binder_Grey": ("#6B6E70", 0.5, 0.0, {}),
    "M_Binder_Maroon": ("#6A2E33", 0.5, 0.0, {}),
    "M_Folder_Manila": ("#C9AE78", 0.8, 0.0, {}),
    "M_Safety_Red": ("#A3221B", 0.5, 0.0, {}),
    "M_Paint_Historic_Green": ("#4F6B57", 0.7, 0.1, {}),
    "M_Paint_Historic_Cream": ("#CFC3A3", 0.8, 0.0, {}),
    "M_Wall_NurseStation": ("#C9D2CC", 0.85, 0.0, {}),
    "M_Wall_PatientRoom": ("#D6CDB8", 0.85, 0.0, {}),
    "M_Wall_Archive": ("#BDBAB0", 0.85, 0.0, {}),
    "M_Clock_Face": ("#F2F0EA", 0.6, 0.0, {}),
    "M_Signage_Panel": ("#E9E7E1", 0.5, 0.0, {}),
    "M_Signage_Blue": ("#2D5876", 0.5, 0.0, {}),
    "M_Glass_Clear": ("#DCE8EA", 0.05, 0.0, {"alpha": 0.18}),
    "M_Glass_Wired": ("#C9D6D8", 0.1, 0.0, {"alpha": 0.32}),
    "M_Glass_OneWay_Observer": ("#1C2226", 0.05, 0.0, {"alpha": 0.45}),
    "M_Mirror_OneWay_Room": ("#9AA1A4", 0.04, 1.0, {}),
    "M_Emissive_LightPanel": ("#FFF4E5", 0.5, 0.0, {"emission": ("#FFF4E5", 6.0)}),
    "M_Emissive_Screen": ("#1E3B3E", 0.3, 0.0, {"emission": ("#2E6F73", 1.5)}),
    "M_Emissive_LED_Green": ("#2CCB5A", 0.3, 0.0, {"emission": ("#2CCB5A", 4.0)}),
    "M_Emissive_LED_Red": ("#D23A2E", 0.3, 0.0, {"emission": ("#D23A2E", 4.0)}),
    "M_Exterior_Backdrop": ("#5D7084", 1.0, 0.0, {"emission": ("#6E829A", 1.2)}),
    # Stage 3: clinical, linen and emergency equipment.
    "M_Plastic_MedCart_Blue": ("#3D6A93", 0.45, 0.0, {}),
    "M_Plastic_Sharps_Yellow": ("#E3B81E", 0.5, 0.0, {}),
    "M_Plastic_AED_Green": ("#1F8A4C", 0.45, 0.0, {}),
    "M_Linen_White": ("#ECECE6", 0.95, 0.0, {}),
    "M_Fabric_LaundryBag_Blue": ("#4F6F9A", 0.95, 0.0, {}),
    "M_Collision": ("#FF00FF", 1.0, 0.0, {}),
}


def srgb_to_linear(hex_color):
    hex_color = hex_color.lstrip("#")
    out = []
    for i in range(0, 6, 2):
        c = int(hex_color[i:i + 2], 16) / 255.0
        out.append(c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4)
    return (*out, 1.0)


def get_mat(name):
    if name in bpy.data.materials:
        return bpy.data.materials[name]
    hex_color, rough, metal, extra = PALETTE[name]
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    bsdf = mat.node_tree.nodes.get("Principled BSDF")
    bsdf.inputs["Base Color"].default_value = srgb_to_linear(hex_color)
    bsdf.inputs["Roughness"].default_value = rough
    bsdf.inputs["Metallic"].default_value = metal
    mat.diffuse_color = srgb_to_linear(hex_color)  # Viewport colour.
    if "alpha" in extra:
        bsdf.inputs["Alpha"].default_value = extra["alpha"]
        for attr, value in (("surface_render_method", "BLENDED"), ("blend_method", "BLEND")):
            if hasattr(mat, attr):
                try:
                    setattr(mat, attr, value)
                except (TypeError, AttributeError):
                    pass
    if "emission" in extra:
        color, strength = extra["emission"]
        bsdf.inputs["Emission Color"].default_value = srgb_to_linear(color)
        bsdf.inputs["Emission Strength"].default_value = strength
    return mat


# --------------------------------------------------------------------------
# MeshBuilder
# --------------------------------------------------------------------------

AXES = {
    "+x": Vector((1, 0, 0)), "-x": Vector((-1, 0, 0)),
    "+y": Vector((0, 1, 0)), "-y": Vector((0, -1, 0)),
    "+z": Vector((0, 0, 1)), "-z": Vector((0, 0, -1)),
}
_CYL_AXIS_ROT = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}


def _rot(rot):
    return Euler(rot).to_matrix().to_4x4()


class MeshBuilder:
    """Accumulates primitives into one bmesh. Use `with mb.at(loc, rot):`
    to work in a local frame (e.g. a wall rotated 90 degrees)."""

    def __init__(self):
        self.bm = bmesh.new()
        self.mats = []
        self.stack = [Matrix.Identity(4)]

    @property
    def M(self):
        return self.stack[-1]

    class _Frame:
        def __init__(self, mb, m):
            self.mb, self.m = mb, m

        def __enter__(self):
            self.mb.stack.append(self.m)
            return self.mb

        def __exit__(self, *exc):
            self.mb.stack.pop()

    def at(self, loc=(0, 0, 0), rot=(0, 0, 0)):
        return MeshBuilder._Frame(self, self.M @ Matrix.Translation(loc) @ _rot(rot))

    def _mi(self, mat):
        if mat not in self.mats:
            self.mats.append(mat)
        return self.mats.index(mat)

    def _faces(self, verts):
        return {f for v in verts for f in v.link_faces}

    def box(self, size, center=(0, 0, 0), mat="M_Steel_Painted_Grey", rot=(0, 0, 0), face_mats=None):
        """Axis-aligned (in the current frame) box. face_mats maps a local
        face direction ("-y", "+z", ...) to a different material."""
        local = Matrix.Translation(center) @ _rot(rot)
        m = self.M @ local @ Matrix.Diagonal((size[0], size[1], size[2], 1.0))
        verts = bmesh.ops.create_cube(self.bm, size=1.0, matrix=m)["verts"]
        faces = self._faces(verts)
        base = self._mi(mat)
        lookup = []
        if face_mats:
            r = (self.M @ local).to_3x3()
            for key, fm in face_mats.items():
                lookup.append(((r @ AXES[key]).normalized(), self._mi(fm)))
        for f in faces:
            f.normal_update()
            f.smooth = False
            f.material_index = base
            for axis, idx in lookup:
                if f.normal.dot(axis) > 0.9:
                    f.material_index = idx
        return faces

    def cyl(self, r, h, center=(0, 0, 0), mat="M_Steel_Brushed", axis="Z", segs=16, r2=None, rot=(0, 0, 0),
            cap_mat=None):
        m = self.M @ Matrix.Translation(center) @ _rot(rot) @ _rot(_CYL_AXIS_ROT[axis])
        verts = bmesh.ops.create_cone(self.bm, cap_ends=True, cap_tris=False, segments=segs, radius1=r,
                                      radius2=r if r2 is None else r2, depth=h, matrix=m)["verts"]
        faces = self._faces(verts)
        axis_w = (m.to_3x3() @ Vector((0, 0, 1))).normalized()
        idx = self._mi(mat)
        cap_idx = self._mi(cap_mat) if cap_mat else idx
        for f in faces:
            f.normal_update()
            is_side = abs(f.normal.dot(axis_w)) < 0.5
            f.smooth = is_side
            f.material_index = idx if is_side else cap_idx
        for f in faces:
            for e in f.edges:
                if len({lf.smooth for lf in e.link_faces}) > 1:
                    e.smooth = False
        return faces

    def sphere(self, r, center=(0, 0, 0), mat="M_Plastic_Black", segs=16, rings=8, scale=(1, 1, 1)):
        m = self.M @ Matrix.Translation(center) @ Matrix.Diagonal((*scale, 1.0))
        verts = bmesh.ops.create_uvsphere(self.bm, u_segments=segs, v_segments=rings, radius=r, matrix=m)["verts"]
        idx = self._mi(mat)
        for f in self._faces(verts):
            f.smooth = True
            f.material_index = idx

    def build(self, name, collection, parent=None, loc=(0, 0, 0), rot=(0, 0, 0), bevel=0.0):
        me = bpy.data.meshes.new(name)
        bmesh.ops.remove_doubles(self.bm, verts=self.bm.verts, dist=1e-5)
        self.bm.to_mesh(me)
        self.bm.free()
        for mat in self.mats:
            me.materials.append(get_mat(mat))
        me.validate()
        ob = bpy.data.objects.new(name, me)
        collection.objects.link(ob)
        if parent is not None:
            ob.parent = parent
        ob.location = loc
        ob.rotation_euler = rot
        if bevel > 0.0:
            mod = ob.modifiers.new("Bevel", "BEVEL")
            mod.width = bevel
            mod.segments = 2
            mod.limit_method = "ANGLE"
            mod.angle_limit = math.radians(35)
        return ob


# --------------------------------------------------------------------------
# Scene / object helpers
# --------------------------------------------------------------------------

def reset_scene():
    bpy.ops.wm.read_factory_settings(use_empty=True)
    scene = bpy.context.scene
    scene.unit_settings.system = "METRIC"
    scene.unit_settings.scale_length = 1.0
    return scene


def collection(name, parent=None):
    coll = bpy.data.collections.get(name) or bpy.data.collections.new(name)
    target = parent or bpy.context.scene.collection
    if coll.name not in target.children:
        target.children.link(coll)
    return coll


def empty(name, coll, parent=None, loc=(0, 0, 0), rot=(0, 0, 0), display="PLAIN_AXES", size=0.2, props=None):
    ob = bpy.data.objects.new(name, None)
    ob.empty_display_type = display
    ob.empty_display_size = size
    coll.objects.link(ob)
    if parent is not None:
        ob.parent = parent
    ob.location = loc
    ob.rotation_euler = rot
    for k, v in (props or {}).items():
        ob[k] = v
    return ob


def instance(src, name, coll, parent=None, loc=(0, 0, 0), rot=(0, 0, 0)):
    """Linked duplicate: shares mesh data (exported once in glTF)."""
    ob = bpy.data.objects.new(name, src.data)
    coll.objects.link(ob)
    for mod in src.modifiers:
        new = ob.modifiers.new(mod.name, mod.type)
        for attr in ("width", "segments", "limit_method", "angle_limit"):
            if hasattr(mod, attr):
                setattr(new, attr, getattr(mod, attr))
    if parent is not None:
        ob.parent = parent
    ob.location = loc
    ob.rotation_euler = rot
    return ob


def collision_box(name, coll, parent, size, center, rot=(0, 0, 0)):
    """Collision-only proxy. Godot turns '-colonly' nodes into StaticBody3D."""
    mb = MeshBuilder()
    mb.box(size, center, "M_Collision", rot)
    ob = mb.build(name + "-colonly", coll, parent)
    ob.display_type = "WIRE"
    ob.hide_render = True
    return ob


def look_at_rotation(eye, target):
    direction = Vector(target) - Vector(eye)
    return direction.to_track_quat("-Z", "Y").to_euler()


def camera_marker(name, coll, parent, eye, target, lens_mm=35.0, props=None):
    """A real camera (exported as a glTF camera -> Godot Camera3D, not current).
    It is a framing reference only: no cuts are authored in Blender."""
    data = bpy.data.cameras.new(name)
    data.lens = lens_mm
    data.sensor_width = 36.0
    data.clip_start = 0.05
    ob = bpy.data.objects.new(name, data)
    coll.objects.link(ob)
    ob.parent = parent
    ob.location = eye
    ob.rotation_euler = look_at_rotation(eye, target)
    ob["marker_type"] = "camera"
    ob["lens_mm"] = lens_mm
    for k, v in (props or {}).items():
        ob[k] = v
    return ob


def light_marker(name, coll, parent, loc, kind="omni", energy_hint=1.0, color="#FFF4E5", range_m=6.0,
                 preview_coll=None, preview_size=(0.5, 1.0), preview_watts=60.0):
    """Exported empty telling Godot where to put a light, plus (optionally)
    an unexported area light so Blender preview renders are lit."""
    marker = empty(name, coll, parent, loc, display="SPHERE", size=0.08,
                   props={"marker_type": "light", "light_kind": kind, "energy_hint": energy_hint,
                          "color": color, "range_m": range_m})
    if preview_coll is not None:
        data = bpy.data.lights.new(name + "_preview", "AREA")
        data.shape = "RECTANGLE"
        data.size, data.size_y = preview_size
        data.energy = preview_watts
        data.color = srgb_to_linear(color)[:3]
        light = bpy.data.objects.new(name + "_preview", data)
        preview_coll.objects.link(light)
        light["preview_only"] = True  # Not parented to an asset root: never exported.
        bpy.context.view_layer.update()
        light.location = marker.matrix_world.translation + Vector((0, 0, 0.05))
    return marker


def planar_uv(ob, axes=("x", "z")):
    """Normalised planar UVs (0..1) over the object's bounds, for surfaces
    Godot will texture at runtime (screens, sign faces)."""
    me = ob.data
    if not me.uv_layers:
        me.uv_layers.new(name="UVMap")
    uv = me.uv_layers.active.data
    ia, ib = "xyz".index(axes[0]), "xyz".index(axes[1])
    coords = [v.co for v in me.vertices]
    amin, amax = min(c[ia] for c in coords), max(c[ia] for c in coords)
    bmin, bmax = min(c[ib] for c in coords), max(c[ib] for c in coords)
    for loop in me.loops:
        co = me.vertices[loop.vertex_index].co
        uv[loop.index].uv = ((co[ia] - amin) / max(amax - amin, 1e-6), (co[ib] - bmin) / max(bmax - bmin, 1e-6))


def descendants(root):
    return [root] + list(root.children_recursive)


def world_bounds(root):
    """World-space AABB of all mesh descendants (excluding collision)."""
    bpy.context.view_layer.update()
    lo = Vector((1e9, 1e9, 1e9))
    hi = Vector((-1e9, -1e9, -1e9))
    found = False
    for ob in descendants(root):
        if ob.type != "MESH" or ob.name.endswith("-colonly"):
            continue
        for corner in ob.bound_box:
            p = ob.matrix_world @ Vector(corner)
            lo = Vector(map(min, lo, p))
            hi = Vector(map(max, hi, p))
            found = True
    return (lo, hi) if found else (Vector(), Vector())


# --------------------------------------------------------------------------
# Export + manifest
# --------------------------------------------------------------------------

def export_glb(root, filepath):
    """Exports root and its descendants with root moved to the origin."""
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    saved = root.matrix_world.copy()
    root.matrix_world = Matrix.Identity(4)
    bpy.context.view_layer.update()
    for ob in bpy.context.view_layer.objects:
        ob.select_set(False)
    for ob in descendants(root):
        ob.hide_set(False)
        ob.select_set(True)
    bpy.context.view_layer.objects.active = root
    bpy.ops.export_scene.gltf(
        filepath=filepath, export_format="GLB", use_selection=True, export_apply=True,
        export_cameras=True, export_lights=False, export_extras=True, export_yup=True,
    )
    root.matrix_world = saved
    bpy.context.view_layer.update()
    if not os.path.isfile(filepath) or os.path.getsize(filepath) < 100:
        raise RuntimeError("Export failed: " + filepath)
    return os.path.getsize(filepath)


def asset_record(root, source_file, export_file, location, collision, notes, status, repo_root):
    lo, hi = world_bounds(root)
    saved = root.matrix_world.copy()
    root.matrix_world = Matrix.Identity(4)
    lo, hi = world_bounds(root)
    root.matrix_world = saved
    bpy.context.view_layer.update()
    mats = sorted({slot.material.name for ob in descendants(root) if ob.type == "MESH"
                   for slot in ob.material_slots if slot.material and slot.material.name != "M_Collision"})
    tris = 0
    for ob in descendants(root):
        if ob.type == "MESH" and not ob.name.endswith("-colonly"):
            ob.data.calc_loop_triangles()
            tris += len(ob.data.loop_triangles)
    markers = sorted(ob.name for ob in descendants(root)
                     if ob.name.startswith(("CAM_", "MARK_", "LIGHTMARK_")))
    return {
        "asset_id": root.name,
        "asset_name": root.get("display_name", root.name),
        "category": root.get("category", ""),
        "source_file": os.path.relpath(source_file, repo_root),
        "export_file": os.path.relpath(export_file, repo_root),
        "dimensions_m": [round(hi[i] - lo[i], 3) for i in range(3)],
        "dimensions_axes": "Blender X (width), Y (depth), Z (height)",
        "intended_location": location,
        "collision": collision,
        "materials": mats,
        "triangles_base": tris,
        "markers": markers,
        "implementation_notes": notes,
        "status": status,
    }


def write_manifest(records, path):
    """Merges records into the manifest JSON (keyed by asset_id) and writes
    a Markdown table beside it."""
    os.makedirs(os.path.dirname(path), exist_ok=True)
    data = {"schema_version": "1.0", "assets": {}}
    if os.path.isfile(path):
        with open(path) as fh:
            data = json.load(fh)
    for rec in records:
        data["assets"][rec["asset_id"]] = rec
    with open(path, "w") as fh:
        json.dump(data, fh, indent=2, sort_keys=True)
    rows = ["| Asset ID | Category | Size (m, W×D×H) | Collision | Export | Status |", "|---|---|---|---|---|---|"]
    for asset_id in sorted(data["assets"]):
        rec = data["assets"][asset_id]
        d = rec["dimensions_m"]
        rows.append("| `%s` | %s | %.2f × %.2f × %.2f | %s | `%s` | %s |" % (
            asset_id, rec["category"], d[0], d[1], d[2], rec["collision"], rec["export_file"], rec["status"]))
    with open(path.replace(".json", ".md"), "w") as fh:
        fh.write("# Asset manifest\n\nGenerated by `tools/blender/*.py`; do not edit by hand.\n"
                 "Full details (materials, triangle counts, markers, notes) are in `asset_manifest.json`.\n\n")
        fh.write("\n".join(rows) + "\n")


def save_blend(path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=path, compress=True)
    if not os.path.isfile(path):
        raise RuntimeError("Save failed: " + path)


# --------------------------------------------------------------------------
# Preview rendering
# --------------------------------------------------------------------------

def setup_render(scene, width=1280, height=720, samples=48):
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = samples
    scene.cycles.use_denoising = True
    scene.render.resolution_x = width
    scene.render.resolution_y = height
    scene.render.image_settings.file_format = "PNG"
    scene.view_settings.view_transform = "AgX"
    world = bpy.data.worlds.new("FW_PreviewWorld")
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.02, 0.022, 0.025, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.3
    scene.world = world


def render_from(scene, camera_obj, filepath):
    os.makedirs(os.path.dirname(filepath), exist_ok=True)
    scene.camera = camera_obj
    scene.render.filepath = filepath
    bpy.ops.render.render(write_still=True)
    if not os.path.isfile(filepath):
        raise RuntimeError("Render failed: " + filepath)
