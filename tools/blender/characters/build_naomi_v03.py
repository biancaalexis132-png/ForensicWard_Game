"""Build Naomi Bennett v03 from the MPFB body stored in the v02 source file.

Diagnosis behind v03 (see NAOMI_V03_NOTES.md): the v02 body was created with
MPFB's helper geometry unmasked, so the skirt/tights/hair/eye helpers and joint
cubes rendered as navy "skirt" panels and skin-coloured strips. v02's clothing was
the body surface painted navy, its eyes and brows were stretched spheres, and its
rig sat 0.89 m below the mesh. Underneath, the MPFB anatomy is plausible, so v03
keeps that body and rebuilds everything around it:

* deletes helper geometry and joint cubes, and aligns the rig with the mesh;
* poses the arms into a relaxed stance and makes that the rest pose;
* builds a separate scrub top and straight-leg scrub trousers as offset shells,
  plus shoes and a blank ID badge;
* places anatomically sized eyeballs in the MPFB eye sockets;
* builds pulled-back two-strand twists that follow the scalp into a low bun;
* bakes a skin texture (tone variation, lips, brows, lash line, nails).

It needs no add-on and no downloads: run it with Blender 5.2.2 (or the bpy 5.2.2
module) from the repository root. Outputs are new v03 files; v01 and v02 are
left untouched.

    /Applications/Blender.app/Contents/MacOS/Blender --background \
        --python-exit-code 1 --python tools/blender/characters/build_naomi_v03.py
"""
from __future__ import annotations

import hashlib
import json
import math
import os
import struct
import sys
from pathlib import Path

import bpy  # noqa: I001  (bpy must load before bmesh in the standalone module)
import bmesh
import numpy as np
from mathutils import Matrix, Quaternion, Vector
from mathutils.bvhtree import BVHTree

ROOT = Path(__file__).resolve().parents[3] if "__file__" in globals() else Path.cwd()
if not (ROOT / "project.godot").exists():
    ROOT = Path.cwd()
CONFIG_PATH = ROOT / "tools/blender/characters/naomi_v03.json"
CONFIG = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))
VERSION = CONFIG["character"]["asset_version"]
BLEND_OUT = ROOT / f"assets/blender/characters/Naomi_Bennett_{VERSION}.blend"
GLB_OUT = ROOT / f"assets/exports/characters/Naomi_Bennett_{VERSION}.glb"
RENDER_DIR = ROOT / "assets/renders/characters"
MANIFEST_OUT = ROOT / f"assets/asset_manifest/naomi_character_manifest_{VERSION}.json"
RENDER_VIEWS = ("front", "three_quarter", "right", "back", "face")
PREFIX = "Naomi_"


# --------------------------------------------------------------------------- utils

def srgb_to_linear(c: float) -> float:
    return c / 12.92 if c <= 0.04045 else ((c + 0.055) / 1.055) ** 2.4


def hex_rgb(value: str, linear: bool = True) -> tuple[float, float, float]:
    value = value.lstrip("#")
    rgb = tuple(int(value[i:i + 2], 16) / 255.0 for i in (0, 2, 4))
    return tuple(srgb_to_linear(c) for c in rgb) if linear else rgb


def select_only(obj: bpy.types.Object) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    bpy.context.view_layer.objects.active = obj
    obj.select_set(True)


def vertex_weights(obj: bpy.types.Object) -> tuple[np.ndarray, list[str]]:
    """Dense (vertex, group) weight matrix."""
    names = [g.name for g in obj.vertex_groups]
    weights = np.zeros((len(obj.data.vertices), len(names)), dtype=np.float32)
    for v in obj.data.vertices:
        for g in v.groups:
            weights[v.index, g.group] = g.weight
    return weights, names


def smooth_noise(points: np.ndarray, scale: float, seed: int) -> np.ndarray:
    """Cheap deterministic 3D value noise (sum of sines) in roughly [-1, 1]."""
    rng = np.random.default_rng(seed)
    out = np.zeros(len(points))
    for _ in range(6):
        direction = rng.normal(size=3)
        direction /= np.linalg.norm(direction)
        phase = rng.uniform(0, math.tau)
        out += np.sin(points @ direction / scale + phase)
    return out / 6.0 * 1.6


def link(obj: bpy.types.Object, collection: bpy.types.Collection) -> None:
    for c in list(obj.users_collection):
        c.objects.unlink(obj)
    collection.objects.link(obj)


def parent_to_rig(obj: bpy.types.Object, rig: bpy.types.Object) -> None:
    obj.parent = rig
    obj.matrix_parent_inverse = rig.matrix_world.inverted()
    mod = obj.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


def rigid_weight(obj: bpy.types.Object, bone: str) -> None:
    group = obj.vertex_groups.new(name=bone)
    group.add(list(range(len(obj.data.vertices))), 1.0, "REPLACE")


def copy_weights_from(target: bpy.types.Object, source: bpy.types.Object) -> None:
    """Nearest-surface weight transfer, so clothing follows the body's skinning."""
    select_only(target)
    for g in source.vertex_groups:
        if g.name not in target.vertex_groups:
            target.vertex_groups.new(name=g.name)
    mod = target.modifiers.new("WeightTransfer", "DATA_TRANSFER")
    mod.object = source
    mod.use_vert_data = True
    mod.data_types_verts = {"VGROUP_WEIGHTS"}
    mod.vert_mapping = "POLYINTERP_NEAREST"
    mod.layers_vgroup_select_src = "ALL"
    mod.layers_vgroup_select_dst = "NAME"
    bpy.ops.object.modifier_apply(modifier=mod.name)


def limit_influences(obj: bpy.types.Object, maximum: int = 4) -> None:
    for v in obj.data.vertices:
        groups = sorted(((g.group, g.weight) for g in v.groups), key=lambda x: -x[1])
        for gi, _ in groups[maximum:]:
            obj.vertex_groups[gi].remove([v.index])
        kept = [x for x in groups[:maximum] if x[1] > 0]
        total = sum(w for _, w in kept)
        for gi, w in kept:
            obj.vertex_groups[gi].add([v.index], w / total if total else 0.0, "REPLACE")


def make_image(name: str, pixels: np.ndarray) -> bpy.types.Image:
    """pixels: (h, w, 4) float in sRGB space for colour images."""
    h, w = pixels.shape[:2]
    image = bpy.data.images.new(name, w, h, alpha=True)
    image.pixels.foreach_set(pixels.astype(np.float32).ravel())
    image.pack()
    return image


def principled(name: str, color=None, roughness=0.5, image=None, normal=None,
               subsurface=0.0, specular=0.5, coat=0.0) -> bpy.types.Material:
    mat = bpy.data.materials.new(name)
    mat.use_nodes = True
    nodes = mat.node_tree.nodes
    bsdf = nodes["Principled BSDF"]
    bsdf.inputs["Roughness"].default_value = roughness
    bsdf.inputs["Specular IOR Level"].default_value = specular
    if color is not None:
        bsdf.inputs["Base Color"].default_value = (*color, 1.0)
    if image is not None:
        tex = nodes.new("ShaderNodeTexImage")
        tex.image = image
        mat.node_tree.links.new(tex.outputs["Color"], bsdf.inputs["Base Color"])
    if normal is not None:
        ntex = nodes.new("ShaderNodeTexImage")
        ntex.image = normal
        ntex.image.colorspace_settings.name = "Non-Color"
        nmap = nodes.new("ShaderNodeNormalMap")
        nmap.inputs["Strength"].default_value = 0.6
        mat.node_tree.links.new(ntex.outputs["Color"], nmap.inputs["Color"])
        mat.node_tree.links.new(nmap.outputs["Normal"], bsdf.inputs["Normal"])
    if subsurface:
        bsdf.inputs["Subsurface Weight"].default_value = subsurface
        bsdf.inputs["Subsurface Radius"].default_value = (1.0, 0.35, 0.2)
        bsdf.inputs["Subsurface Scale"].default_value = 0.004
    if coat:
        bsdf.inputs["Coat Weight"].default_value = coat
        bsdf.inputs["Coat Roughness"].default_value = 0.05
    return mat


# ---------------------------------------------------------------- source and rig

def load_source() -> tuple[bpy.types.Object, bpy.types.Object, list[np.ndarray], str]:
    src = ROOT / CONFIG["source"]["blend"]
    digest = hashlib.sha256(src.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(src))
    body = bpy.data.objects[CONFIG["source"]["body"]]
    rig = bpy.data.objects[CONFIG["source"]["rig"]]
    for obj in list(bpy.data.objects):
        if obj not in (body, rig):
            bpy.data.objects.remove(obj, do_unlink=True)
    for block in (bpy.data.materials, bpy.data.images, bpy.data.meshes, bpy.data.lights,
                  bpy.data.cameras, bpy.data.curves):
        for item in list(block):
            if item.users == 0:
                block.remove(item)
    select_only(body)
    if body.data.shape_keys:
        bpy.ops.object.shape_key_remove(all=True, apply_mix=True)

    weights, names = vertex_weights(body)
    eye_sockets = find_eye_helpers(body, weights[:, names.index("HelperGeometry")] > 0)

    # Delete helpers and joint cubes.
    bm = bmesh.new()
    bm.from_mesh(body.data)
    layer = bm.verts.layers.deform.active
    hi, ji = names.index("HelperGeometry"), names.index("JointCubes")
    kill = [v for v in bm.verts if v[layer].get(hi, 0) > 0 or v[layer].get(ji, 0) > 0]
    bmesh.ops.delete(bm, geom=kill, context="VERTS")
    bm.to_mesh(body.data)
    bm.free()
    for gname in ("HelperGeometry", "JointCubes"):
        body.vertex_groups.remove(body.vertex_groups[gname])
    body.data.materials.clear()

    return body, rig, eye_sockets, digest


def find_eye_helpers(body: bpy.types.Object, helper: np.ndarray) -> list:
    """MPFB's eye helper is a closed sphere in each socket: use it to place eyeballs."""
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.verts.ensure_lookup_table()
    scale = float(CONFIG["eyes"]["helper_radius_scale"])
    data = []
    for side in (1, -1):
        seeds = [v.index for v in bm.verts if helper[v.index] and 0.01 < v.co.x * side < 0.06
                 and 1.52 < v.co.z < 1.60 and v.co.y < -0.05]
        seen: set[int] = set()
        best = None
        for seed in seeds:
            if seed in seen:
                continue
            comp, stack = [], [seed]
            seen.add(seed)
            while stack:
                i = stack.pop()
                comp.append(i)
                for e in bm.verts[i].link_edges:
                    o = e.other_vert(bm.verts[i]).index
                    if o not in seen and helper[o]:
                        seen.add(o)
                        stack.append(o)
            pts = np.array([bm.verts[i].co[:] for i in comp])
            ext = (pts.max(axis=0) - pts.min(axis=0)) / 2
            if len(comp) >= 40 and ext.max() / max(ext.min(), 1e-6) < 1.3 and ext.max() < 0.02:
                best = ((pts.max(axis=0) + pts.min(axis=0)) / 2, float(ext.mean()))
        if best is None:
            raise RuntimeError("Could not find MPFB's eye helper sphere.")
        data.extend([tuple(best[0]), best[1] * scale])
    bm.free()
    return data


def align_rig_to_mesh(body: bpy.types.Object, rig: bpy.types.Object) -> float:
    """v02's armature sits below the mesh; shift every bone by the median offset."""
    weights, names = vertex_weights(body)
    co = np.array([v.co[:] for v in body.data.vertices])
    offsets = []
    for bone in rig.data.bones:
        if bone.name not in names or bone.name.startswith(("index", "middle", "ring", "pinky", "thumb")):
            continue
        w = weights[:, names.index(bone.name)]
        sel = w > 0.7
        if sel.sum() < 30:
            continue
        mid = (Vector(bone.head_local) + Vector(bone.tail_local)) / 2.0
        offsets.append(co[sel].mean(axis=0)[2] - mid.z)
    dz = float(np.median(offsets))
    select_only(rig)
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in rig.data.edit_bones:
        eb.head.z += dz
        eb.tail.z += dz
    bpy.ops.object.mode_set(mode="OBJECT")
    return dz


def relax_pose(body: bpy.types.Object, rig: bpy.types.Object) -> None:
    """Bring the arms down into a relaxed stance and make it the rest pose."""
    pose = CONFIG["pose"]
    select_only(rig)
    bpy.ops.object.mode_set(mode="POSE")
    fwd = math.sin(math.radians(pose["upperarm_forward_degrees"]))
    out = math.cos(math.radians(pose["upperarm_down_degrees"]))
    bend = math.radians(pose["elbow_bend_degrees"])

    def aim_bone(pbone, direction: Vector) -> None:
        """Rotate a pose bone so it points along an armature-space direction."""
        bpy.context.view_layer.update()
        current = (pbone.tail - pbone.head).normalized()
        rot = current.rotation_difference(direction.normalized()).to_matrix()
        m = pbone.matrix.to_3x3().normalized()
        pbone.rotation_mode = "QUATERNION"
        delta = (m.inverted() @ rot @ m).to_quaternion()
        pbone.rotation_quaternion = pbone.rotation_quaternion @ delta
        bpy.context.view_layer.update()

    for side, sign in (("l", 1.0), ("r", -1.0)):
        aim_bone(rig.pose.bones[f"upperarm_{side}"], Vector((sign * out * 0.42, -fwd, -1.0)))
        aim_bone(rig.pose.bones[f"lowerarm_{side}"],
                 Vector((sign * 0.05, -math.sin(bend), -math.cos(bend))))
        lower = rig.pose.bones[f"lowerarm_{side}"]
        aim_bone(rig.pose.bones[f"hand_{side}"], (lower.tail - lower.head).normalized()
                 + Vector((-sign * 0.15, 0.0, 0.0)))
    bpy.ops.object.mode_set(mode="OBJECT")
    # Bake the pose into the mesh, then make the pose the new rest pose.
    select_only(body)
    arm_mod = next(m for m in body.modifiers if m.type == "ARMATURE")
    bpy.ops.object.modifier_apply(modifier=arm_mod.name)
    select_only(rig)
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    mod = body.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


# ---------------------------------------------------------------------- clothing

def dominant_bones(body: bpy.types.Object) -> np.ndarray:
    weights, names = vertex_weights(body)
    bone_cols = [i for i, n in enumerate(names) if n not in (
        "Left", "Mid", "Right", "body", "nippleTip", "nipple", "lips", "fingernails",
        "toenails", "ears", "scalp", "genitals")]
    dom = np.array([names[bone_cols[j]] for j in weights[:, bone_cols].argmax(axis=1)])
    return dom


def shell_from_faces(name: str, body: bpy.types.Object, face_mask: np.ndarray,
                     offset_fn, smooth_iterations: int, thickness: float,
                     material: bpy.types.Material) -> bpy.types.Object:
    """Duplicate the selected body faces, smooth away anatomy and push outward."""
    mesh = body.data.copy()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.matrix_world = body.matrix_world
    obj.modifiers.clear()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not face_mask[f.index]], context="FACES")
    loose = [v for v in bm.verts if not v.link_faces]
    bmesh.ops.delete(bm, geom=loose, context="VERTS")
    # Smooth away breasts, navel, knees and toes: cloth spans these.
    boundary = {v.index for v in bm.verts if v.is_boundary}
    for _ in range(smooth_iterations):
        bmesh.ops.smooth_vert(bm, verts=[v for v in bm.verts if v.index not in boundary],
                              factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
    # Relax open edges (hems, neckline, sleeve ends) so they are smooth curves.
    for _ in range(25):
        moves = {}
        for v in bm.verts:
            if not v.is_boundary:
                continue
            nbrs = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
            if len(nbrs) == 2:
                moves[v] = (nbrs[0].co + nbrs[1].co) / 2
        for v, target in moves.items():
            v.co = v.co.lerp(target, 0.6)
    bm.normal_update()
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())

    def push_out():
        for v in bm.verts:
            offset = offset_fn(v.co)
            location, normal, _i, _d = tree.find_nearest(v.co)
            if location is None:
                continue
            # Never inside the body: start from the nearest body point, then offset.
            outward = (v.co - location)
            if outward.dot(normal) < offset or outward.length > offset + 0.05:
                v.co = location + normal * offset

    # Alternate smoothing and pushing out: cloth bridges hollows (between the
    # breasts, around the toes) and only rests on the high points.
    push_out()
    for _ in range(6 if smooth_iterations > 1 else 0):
        for _ in range(4):
            bmesh.ops.smooth_vert(bm, verts=[v for v in bm.verts if v.index not in boundary],
                                  factor=0.5, use_axis_x=True, use_axis_y=True, use_axis_z=True)
        for _ in range(3):
            for v in bm.verts:
                if v.is_boundary:
                    nbrs = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
                    if len(nbrs) == 2:
                        v.co = v.co.lerp((nbrs[0].co + nbrs[1].co) / 2, 0.5)
        push_out()
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.clear()
    mesh.materials.append(material)
    for poly in mesh.polygons:
        poly.use_smooth = True
    select_only(obj)
    if thickness:
        sol = obj.modifiers.new("Thickness", "SOLIDIFY")
        sol.thickness = thickness
        sol.offset = 1.0
        bpy.ops.object.modifier_apply(modifier=sol.name)
    return obj


def build_clothing(body: bpy.types.Object, rig: bpy.types.Object,
                   mats: dict) -> tuple[list[bpy.types.Object], np.ndarray]:
    sc = CONFIG["scrubs"]
    dom = dominant_bones(body)
    co = np.array([v.co[:] for v in body.data.vertices])
    faces = body.data.polygons
    centres = np.array([f.center[:] for f in faces])
    face_dom = np.array([dom[f.vertices[0]] for f in faces])
    shoulder_l = Vector(rig.data.bones["upperarm_l"].head_local)
    shoulder_r = Vector(rig.data.bones["upperarm_r"].head_local)
    neck = Vector(rig.data.bones["neck_01"].head_local)
    arm_bones = {"upperarm_l", "upperarm_r", "lowerarm_l", "lowerarm_r"}
    hand_like = np.array([d.startswith(("hand", "index", "middle", "ring", "pinky", "thumb"))
                          for d in face_dom])

    def dist_to_shoulder(c):
        return min((Vector(c) - shoulder_l).length, (Vector(c) - shoulder_r).length)

    # Scrub top: torso from the neckline to below the hips, short sleeves.
    torso = np.isin(face_dom, ["pelvis", "spine_01", "spine_02", "spine_03",
                               "clavicle_l", "clavicle_r", "neck_01"])
    sleeve = np.array([d in ("upperarm_l", "upperarm_r") and dist_to_shoulder(c) < 0.19
                       for d, c in zip(face_dom, centres)])
    below_neck = centres[:, 2] < neck.z - 0.005
    x, y, z = centres[:, 0], centres[:, 1], centres[:, 2]
    v_neck = (y < 0) & (z > neck.z - 0.16 + np.abs(x) * 1.25)
    hem = z > 0.80
    legs_dom = np.isin(face_dom, ["thigh_l", "thigh_r"])
    top_mask = ((torso & below_neck & ~v_neck) | sleeve) & (z > 0.86) & ~hand_like
    del legs_dom
    top_off = sc["top_offset"]

    def top_offset(p):
        # Looser over the belly and hem, close at the shoulders.
        return top_off + max(0.0, 1.12 - p.z) * 0.13 + (0.004 if p.z < 1.2 else 0.0)

    top = shell_from_faces(PREFIX + "Scrub_Top", body, top_mask, top_offset, 40, 0.0022,
                           mats["top"])

    # Trousers: waist to just above the ankle, each leg its own tube.
    waist = 1.0
    leg_region = np.isin(face_dom, ["pelvis", "thigh_l", "thigh_r", "calf_l", "calf_r",
                                    "spine_01"]) | ((face_dom == "foot_l") | (face_dom == "foot_r")) & (z > 0.10)
    trouser_mask = leg_region & (z < waist) & (z > 0.085) & ~hand_like
    trouser_mask &= ~np.isin(face_dom, list(arm_bones))
    hem_r = sc["trouser_hem_radius"]
    knee_z = Vector(rig.data.bones["calf_l"].head_local).z

    def trouser_offset(p):
        return sc["trouser_offset"] + max(0.0, knee_z - p.z) * 0.02

    trousers = shell_from_faces(PREFIX + "Scrub_Trousers", body, trouser_mask, trouser_offset, 14,
                                0.0022, mats["trousers"])
    # Straight-cut legs: below mid-thigh, push each leg out to a near-cylinder.
    calf_l = rig.data.bones["calf_l"]
    calf_r = rig.data.bones["calf_r"]
    thigh_l = rig.data.bones["thigh_l"]
    thigh_r = rig.data.bones["thigh_r"]
    for v in trousers.data.vertices:
        p = v.co
        side_l = p.x > 0
        thigh = thigh_l if side_l else thigh_r
        calf = calf_l if side_l else calf_r
        a, b = Vector(thigh.head_local), Vector(calf.tail_local)
        mid_thigh = (Vector(thigh.head_local) + Vector(thigh.tail_local)) / 2
        if p.z > mid_thigh.z:
            continue
        t = (p.z - b.z) / (a.z - b.z)
        axis_pt = b.lerp(a, t)
        axis_pt.y += 0.012
        radial = Vector((p.x - axis_pt.x, p.y - axis_pt.y, 0.0))
        r = radial.length
        blend = min(1.0, (mid_thigh.z - p.z) / 0.18)
        target_r = hem_r + max(0.0, p.z - knee_z) * 0.035
        if r < target_r and r > 1e-5:
            v.co = p + radial.normalized() * ((target_r - r) * blend)

    # Shoes: feet and toes, slightly inflated and smoothed into a clog shape.
    feet = np.isin(face_dom, ["foot_l", "foot_r", "ball_l", "ball_r"]) & (z < 0.115)
    shoes = shell_from_faces(PREFIX + "Practical_Shoes", body, feet,
                             lambda p: 0.007 + max(0.0, 0.035 - p.z) * 0.12, 60, 0.003, mats["shoes"])

    # Hide body faces that are fully covered so nothing pokes through.
    covered = (top_mask & (z < neck.z - 0.07) & ~v_neck) | (trouser_mask & (z < 0.95)) | feet
    sleeve_inner = sleeve & np.array([dist_to_shoulder(c) < 0.15 for c in centres])
    covered = (covered & ~sleeve) | sleeve_inner
    covered &= ~np.array([(c[2] > neck.z - 0.12) and (c[1] < 0) for c in centres])
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if covered[f.index]], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(body.data)
    bm.free()

    for obj in (top, trousers, shoes):
        parent_to_rig(obj, rig)
    return [top, trousers, shoes], covered


def build_badge(body: bpy.types.Object, rig: bpy.types.Object, top: bpy.types.Object,
                mats: dict) -> bpy.types.Object:
    """Blank clip-on ID card on the left chest. No name or logo is invented."""
    tree = BVHTree.FromObject(top, bpy.context.evaluated_depsgraph_get())
    origin = Vector((0.085, -0.5, 1.255))
    hit, normal, _i, _d = tree.ray_cast(origin, Vector((0, 1, 0)))
    if hit is None:
        raise RuntimeError("Could not place the ID badge on the scrub top.")
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=(0.054, 0.003, 0.085), verts=bm.verts)
    mesh = bpy.data.meshes.new(PREFIX + "ID_Badge")
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mats["badge"])
    # UV the front face so the stripe texture shows.
    mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            p = mesh.vertices[mesh.loops[li].vertex_index].co
            mesh.uv_layers[0].data[li].uv = (p.x / 0.054 + 0.5, p.z / 0.085 + 0.5)
    obj = bpy.data.objects.new(PREFIX + "ID_Badge", mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.location = hit - Vector((0, 0.004, 0))
    rot = Vector((0, -1, 0)).rotation_difference(-normal)
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = rot
    bpy.context.view_layer.update()
    select_only(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    rigid_weight(obj, "spine_03")
    parent_to_rig(obj, rig)
    return obj


# --------------------------------------------------------------------------- eyes

def build_eyes(rig: bpy.types.Object, eye_data: list, mats: dict) -> list[bpy.types.Object]:
    objs = []
    for idx, side in ((0, "L"), (2, "R")):
        centre = Vector(eye_data[idx])
        radius = float(eye_data[idx + 1])
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=20, v_segments=14, radius=radius)
        mesh = bpy.data.meshes.new(f"{PREFIX}Eye_{side}")
        bm.to_mesh(mesh)
        bm.free()
        mesh.uv_layers.new(name="UVMap")
        uv = mesh.uv_layers[0].data
        for poly in mesh.polygons:
            poly.use_smooth = True
            for li in poly.loop_indices:
                p = mesh.vertices[mesh.loops[li].vertex_index].co / radius
                # Planar projection along -Y puts the iris at the image centre.
                uv[li].uv = (0.5 + p.x * 0.5, 0.5 + p.z * 0.5) if p.y < 0 else (0.02, 0.02)
        mesh.materials.append(mats["eye"])
        obj = bpy.data.objects.new(f"{PREFIX}Eye_{side}", mesh)
        bpy.context.scene.collection.objects.link(obj)
        obj.location = centre
        select_only(obj)
        bpy.ops.object.transform_apply(location=True)
        rigid_weight(obj, "head")
        parent_to_rig(obj, rig)
        objs.append(obj)
    return objs


def eye_texture() -> bpy.types.Image:
    n = 256
    yy, xx = np.mgrid[0:n, 0:n]
    u = (xx + 0.5) / n - 0.5
    v = (yy + 0.5) / n - 0.5
    r = np.sqrt(u * u + v * v) * 2.0  # 0 centre, 1 edge of eyeball silhouette
    ang = np.arctan2(v, u)
    sclera = np.array(hex_rgb(CONFIG["eyes"]["sclera_srgb_hex"], linear=False))
    iris = np.array(hex_rgb(CONFIG["eyes"]["iris_srgb_hex"], linear=False))
    limbal = np.array(hex_rgb(CONFIG["eyes"]["limbal_srgb_hex"], linear=False))
    img = np.ones((n, n, 4))
    img[..., :3] = sclera
    # Faint vessels / warmth towards the corners of the sclera.
    img[..., 0] += (r > 0.55) * 0.04 * (1 + np.sin(ang * 23)) * 0.5
    iris_r, pupil_r = 0.47, 0.16
    fib = 0.85 + 0.15 * np.sin(ang * 61) * np.sin(ang * 17 + r * 9)
    in_iris = r < iris_r
    shade = np.clip((r - pupil_r) / (iris_r - pupil_r), 0, 1)
    iris_col = iris[None, None, :] * (fib[..., None] * (1.15 - 0.5 * shade[..., None]))
    img[..., :3] = np.where(in_iris[..., None], iris_col, img[..., :3])
    ring = (r > iris_r - 0.06) & (r < iris_r + 0.015)
    img[..., :3] = np.where(ring[..., None], limbal, img[..., :3])
    img[..., :3] = np.where((r < pupil_r)[..., None], np.array([0.02, 0.015, 0.012]), img[..., :3])
    return make_image(PREFIX + "Eye_BaseColor", np.clip(img, 0, 1))


# --------------------------------------------------------------------------- hair

def build_hair(body: bpy.types.Object, rig: bpy.types.Object, mats: dict) -> list[bpy.types.Object]:
    hair = CONFIG["hair"]
    co = np.array([v.co[:] for v in body.data.vertices])
    weights, names = vertex_weights(body)
    head_w = weights[:, names.index("head")]
    head_pts = co[head_w > 0.5]
    centre = Vector(((head_pts[:, 0].min() + head_pts[:, 0].max()) / 2,
                     (head_pts[:, 1].min() + head_pts[:, 1].max()) / 2 + 0.01,
                     head_pts[:, 2].max() - 0.105))
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    top_z = head_pts[:, 2].max()

    def on_scalp(direction: Vector, lift: float) -> Vector:
        hit, normal, _i, _d = tree.ray_cast(centre + direction * 0.3, -direction)
        if hit is None:
            hit, normal, _i, _d = tree.find_nearest(centre + direction * 0.1)
        return hit + normal * lift

    # Hairline: an ellipse-ish curve over the forehead, temples and behind the ears.
    count = int(hair["twist_count"])
    bun = Vector(hair["bun_center"])
    curves = bpy.data.curves.new(PREFIX + "Twists", "CURVE")
    curves.dimensions = "3D"
    curves.bevel_depth = hair["twist_strand_radius"]
    curves.bevel_resolution = 1
    curves.use_fill_caps = True
    strand_r = hair["twist_strand_radius"] * 0.95
    pitch = hair["twist_pitch"]
    rng = np.random.default_rng(7)
    for i in range(count):
        # Angle around the head from the left nape, over the forehead, to the right nape.
        a = math.radians(-140 + 280 * i / (count - 1))
        elev = math.radians(10 + 24 * math.cos(math.radians(-140 + 280 * i / (count - 1)) * 0.5) ** 2)
        start_dir = Vector((math.sin(a) * math.cos(elev), -math.cos(a) * math.cos(elev), math.sin(elev)))
        # Sample a path over the scalp towards the bun.
        n_samples = 26
        pts = []
        for k in range(n_samples):
            t = k / (n_samples - 1)
            end_dir = (bun - centre).normalized()
            # Arc over the top: blend directions and lift towards the crown for front twists.
            front = max(0.0, math.cos(a))
            mid_lift = Vector((0, 0, 1)) * (0.9 * front * math.sin(math.pi * t))
            d = (start_dir.lerp(end_dir, t) + mid_lift).normalized()
            p = on_scalp(d, 0.0045 + 0.004 * math.sin(math.pi * t))
            if t > 0.9:
                p = p.lerp(bun + (p - bun).normalized() * hair["bun_radius"] * 0.7, (t - 0.9) / 0.1)
            pts.append(p)
        # Two strands twisting around the path.
        jitter = rng.uniform(0, math.tau)
        for strand in range(2):
            spline = curves.splines.new("POLY")
            dense = []
            length = sum((pts[k + 1] - pts[k]).length for k in range(len(pts) - 1))
            steps = max(10, int(length / pitch * 2.2))
            acc = [0.0]
            for k in range(len(pts) - 1):
                acc.append(acc[-1] + (pts[k + 1] - pts[k]).length)
            for s in range(steps + 1):
                dist = length * s / steps
                k = max(0, min(len(pts) - 2, int(np.searchsorted(acc, dist) - 1)))
                seg_t = (dist - acc[k]) / max(1e-6, acc[k + 1] - acc[k])
                p = pts[k].lerp(pts[k + 1], seg_t)
                tangent = (pts[k + 1] - pts[k]).normalized()
                normal = (p - centre).normalized()
                binormal = tangent.cross(normal).normalized()
                phase = dist / pitch * math.tau + strand * math.pi + jitter
                dense.append(p + (normal * math.cos(phase) + binormal * math.sin(phase)) * strand_r)
            spline.points.add(len(dense) - 1)
            last = len(dense) - 1
            for j, p in enumerate(dense):
                spline.points[j].co = (*p, 1.0)
                # Taper at the hairline so twists grow out of the scalp, not off a blunt edge.
                spline.points[j].radius = min(1.0, 0.25 + j / max(1, last * 0.12) * 0.75)
    # Low bun: coiled twists.
    for ring in range(6):
        spline = curves.splines.new("POLY")
        turns = 1.6
        steps = 44
        spline.points.add(steps)
        rad0 = hair["bun_radius"] * (0.25 + ring * 0.14)
        for s in range(steps + 1):
            t = s / steps
            ang = t * turns * math.tau + ring * 1.3
            rad = rad0 + 0.006 * math.sin(t * math.tau * 9 + ring)
            local = Vector((math.cos(ang) * rad, 0.022 - 0.0035 * ring, math.sin(ang) * rad * 0.8))
            spline.points[s].co = (*(bun + local), 1.0)
    curves.bevel_depth = hair["twist_strand_radius"] * 1.25
    twist_obj = bpy.data.objects.new(PREFIX + "Natural_Twists", curves)
    bpy.context.scene.collection.objects.link(twist_obj)
    select_only(twist_obj)
    bpy.ops.object.convert(target="MESH")
    twist_obj = bpy.context.view_layer.objects.active
    twist_obj.data.materials.clear()
    twist_obj.data.materials.append(mats["hair"])
    for poly in twist_obj.data.polygons:
        poly.use_smooth = True

    # Scalp cap under the twists so no skin shows between them.
    head_faces = np.array([head_w[list(f.vertices)].mean() > 0.6 for f in body.data.polygons])
    centres = np.array([f.center[:] for f in body.data.polygons])
    rel = centres - np.array(centre[:])
    # Hairline: above the brow at the front, above the ears at the side, nape at the back.
    ang = np.degrees(np.arctan2(rel[:, 0], -rel[:, 1]))
    hairline_z = centre.z + 0.045 - 0.075 * np.clip((np.abs(ang) - 40) / 110, 0, 1)
    cap_mask = head_faces & (centres[:, 2] > hairline_z) & ~((np.abs(ang) > 70) & (np.abs(ang) < 120) & (centres[:, 2] < centre.z + 0.02))
    cap = shell_from_faces(PREFIX + "Hair_Cap", body, cap_mask, lambda p: 0.0025, 1, 0.0, mats["hair_cap"])
    rigid_weight(twist_obj, "head")
    parent_to_rig(twist_obj, rig)
    copy_weights_from(cap, body)
    parent_to_rig(cap, rig)
    return [cap, twist_obj]


# ---------------------------------------------------------------------- textures

def bake_skin_texture(body: bpy.types.Object, eye_data: list) -> bpy.types.Image:
    """Bake per-vertex skin colour (computed on a subdivided copy) into the UVs."""
    sk = CONFIG["skin"]
    size = int(sk["texture_size"])
    tmp = body.copy()
    tmp.data = body.data.copy()
    bpy.context.scene.collection.objects.link(tmp)
    tmp.modifiers.clear()
    select_only(tmp)
    sub = tmp.modifiers.new("Subdiv", "SUBSURF")
    sub.levels = 2
    sub.render_levels = 2
    sub.uv_smooth = "PRESERVE_BOUNDARIES"
    bpy.ops.object.modifier_apply(modifier=sub.name)
    mesh = tmp.data
    co = np.array([v.co[:] for v in mesh.vertices])
    weights, names = vertex_weights(tmp)

    base = np.array(hex_rgb(sk["base_srgb_hex"], linear=False))
    shadow = np.array(hex_rgb(sk["shadow_srgb_hex"], linear=False))
    warm = np.array(hex_rgb(sk["warm_srgb_hex"], linear=False))
    lip = np.array(hex_rgb(sk["lip_srgb_hex"], linear=False))
    brow = np.array(hex_rgb(sk["brow_srgb_hex"], linear=False))
    nail = np.array(hex_rgb(sk["nail_srgb_hex"], linear=False))

    n1 = smooth_noise(co, 0.06, 1)
    n2 = smooth_noise(co, 0.012, 2)
    n3 = smooth_noise(co, 0.003, 3)
    col = base[None, :] * (1.0 + 0.05 * n1[:, None] + 0.03 * n2[:, None] + 0.025 * n3[:, None])
    # Slightly deeper tone on hands, feet, elbows and knees; warmer cheeks.
    for g, amt in (("hand_l", 0.08), ("hand_r", 0.08), ("foot_l", 0.06), ("foot_r", 0.06)):
        if g in names:
            w = weights[:, names.index(g)][:, None]
            col = col * (1 - w * amt) + shadow[None, :] * (w * amt)
    eye_l, eye_r = Vector(eye_data[0]), Vector(eye_data[2])
    face_mid = (eye_l + eye_r) / 2
    for eye in (eye_l, eye_r):
        cheek = np.array((eye + Vector((0.012 * (1 if eye.x > 0 else -1), -0.01, -0.035)))[:])
        d = np.linalg.norm(co - cheek, axis=1)
        w = np.clip(1 - d / 0.03, 0, 1)[:, None] * 0.35
        col = col * (1 - w) + warm[None, :] * w
        # Under-eye and lid darkening.
        e = np.array(eye[:])
        rel = co - e
        lid = (np.abs(rel[:, 0]) < 0.02) & (rel[:, 2] > -0.016) & (rel[:, 2] < 0.017) & (rel[:, 1] < 0.0)
        dist = np.sqrt((rel[:, 0] / 0.019) ** 2 + (rel[:, 2] / 0.012) ** 2)
        w = (lid * np.clip(1.2 - dist, 0, 1) * 0.3)[:, None]
        col = col * (1 - w) + shadow[None, :] * w
        # Lash line: a thin dark rim along the upper lid only.
        rim = lid & (dist > 0.86) & (dist < 0.98) & (rel[:, 2] > 0.002)
        col[rim] = col[rim] * 0.5 + brow * 0.5
        # Brows: an arc above the eye with hair-like streaks.
        side = 1 if eye.x > 0 else -1
        bx = rel[:, 0] * side  # 0 at the eye centre, positive towards the temple
        arc_z = 0.019 + 0.006 * np.cos(np.clip(bx / 0.03, -1.5, 1.5)) - 0.004 * np.clip(bx / 0.03, 0, 1) ** 2
        thick = 0.0052 * np.clip(1.15 - np.clip(bx + 0.012, 0, None) / 0.04, 0.35, 1.0)
        in_brow = (bx > -0.016) & (bx < 0.03) & (np.abs(rel[:, 2] - arc_z) < thick) & (rel[:, 1] < 0.0)
        streak = 0.65 + 0.35 * np.sin(bx * 2400 + rel[:, 2] * 900) * np.sin(bx * 900)
        fade = np.clip(1 - np.abs(rel[:, 2] - arc_z) / thick, 0, 1) * np.clip((0.03 - bx) / 0.012, 0, 1)
        w = (in_brow * fade * np.clip(streak, 0, 1) * 0.85)[:, None]
        col = col * (1 - w) + brow[None, :] * w
    if "lips" in names:
        w = np.clip(weights[:, names.index("lips")] * 1.2, 0, 1)[:, None] * 0.85
        col = col * (1 - w) + lip[None, :] * w
    for g in ("fingernails", "toenails"):
        if g in names:
            w = weights[:, names.index(g)][:, None] * 0.8
            col = col * (1 - w) + nail[None, :] * w
    del face_mid
    col = np.clip(col, 0, 1)

    attr = mesh.color_attributes.new("SkinPaint", "FLOAT_COLOR", "POINT")
    rgba = np.concatenate([np.vectorize(srgb_to_linear)(col), np.ones((len(col), 1))], axis=1)
    attr.data.foreach_set("color", rgba.astype(np.float32).ravel())

    image = bpy.data.images.new(PREFIX + "Skin_BaseColor", size, size, alpha=False)
    mat = bpy.data.materials.new("Naomi_Skin_Bake")
    mat.use_nodes = True
    nt = mat.node_tree
    nt.nodes.clear()
    out = nt.nodes.new("ShaderNodeOutputMaterial")
    emit = nt.nodes.new("ShaderNodeEmission")
    attr_node = nt.nodes.new("ShaderNodeVertexColor")
    attr_node.layer_name = "SkinPaint"
    nt.links.new(attr_node.outputs["Color"], emit.inputs["Color"])
    nt.links.new(emit.outputs["Emission"], out.inputs["Surface"])
    img_node = nt.nodes.new("ShaderNodeTexImage")
    img_node.image = image
    nt.nodes.active = img_node
    mesh.materials.clear()
    mesh.materials.append(mat)
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.samples = 1
    scene.cycles.device = "CPU"
    select_only(tmp)
    bpy.ops.object.bake(type="EMIT", margin=12, use_clear=True)
    image.pack()
    bpy.data.objects.remove(tmp, do_unlink=True)
    bpy.data.materials.remove(mat)
    return image


def fabric_textures(color_hex: str, name: str, size: int) -> tuple[bpy.types.Image, bpy.types.Image]:
    """Fine twill weave colour and normal maps that tile across the UVs."""
    base = np.array(hex_rgb(color_hex, linear=False))
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float64)
    period = size / 128.0
    twill = np.sin((xx + yy) / period * math.pi) * 0.5 + 0.5
    weft = np.sin(yy / period * math.pi * 2) * 0.5 + 0.5
    rng = np.random.default_rng(len(name))
    grain = rng.normal(0, 1, (size, size))
    grain = (grain + np.roll(grain, 1, 0) + np.roll(grain, 1, 1)) / 3
    shade = 1.0 + 0.06 * (twill - 0.5) + 0.03 * (weft - 0.5) + 0.025 * grain
    col = np.ones((size, size, 4))
    col[..., :3] = np.clip(base[None, None, :] * shade[..., None], 0, 1)
    height = 0.6 * twill + 0.3 * weft + 0.1 * grain
    gx = np.roll(height, -1, 1) - np.roll(height, 1, 1)
    gy = np.roll(height, -1, 0) - np.roll(height, 1, 0)
    nrm = np.ones((size, size, 4))
    nrm[..., 0] = 0.5 - gx * 0.25
    nrm[..., 1] = 0.5 - gy * 0.25
    nrm[..., 2] = 1.0
    return make_image(PREFIX + name + "_BaseColor", col), make_image(PREFIX + name + "_Normal", np.clip(nrm, 0, 1))


def project_fabric_uvs(obj: bpy.types.Object, scale: float = 6.0) -> None:
    """Simple cylindrical-ish box UVs in world space so the weave tiles evenly."""
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv = mesh.uv_layers.active.data
    for poly in mesh.polygons:
        n = poly.normal
        for li in poly.loop_indices:
            p = mesh.vertices[mesh.loops[li].vertex_index].co
            if abs(n.z) > 0.7:
                uv[li].uv = (p.x * scale, p.y * scale)
            elif abs(n.x) > abs(n.y):
                uv[li].uv = (p.y * scale, p.z * scale)
            else:
                uv[li].uv = (p.x * scale, p.z * scale)


def hair_textures() -> tuple[bpy.types.Image, bpy.types.Image]:
    base = np.array(hex_rgb(CONFIG["hair"]["srgb_hex"], linear=False))
    size = 256
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float64)
    fibres = 0.75 + 0.25 * np.sin(xx / 2.3 + np.sin(yy / 11.0) * 3)
    col = np.ones((size, size, 4))
    col[..., :3] = np.clip(base * fibres[..., None] * 1.1, 0, 1)
    gx = np.roll(fibres, -1, 1) - np.roll(fibres, 1, 1)
    nrm = np.ones((size, size, 4))
    nrm[..., 0] = 0.5 - gx * 0.8
    nrm[..., 1] = 0.5
    nrm[..., 2] = 1.0
    return make_image(PREFIX + "Hair_BaseColor", col), make_image(PREFIX + "Hair_Normal", np.clip(nrm, 0, 1))


def badge_texture() -> bpy.types.Image:
    card = np.array(hex_rgb(CONFIG["badge"]["card_srgb_hex"], linear=False))
    stripe = np.array(hex_rgb(CONFIG["badge"]["stripe_srgb_hex"], linear=False))
    size = 128
    img = np.ones((size, size, 4))
    img[..., :3] = card
    img[int(size * 0.78):int(size * 0.92), :, :3] = stripe
    # Blank photo area (grey) — no face, name or logo is invented.
    img[int(size * 0.38):int(size * 0.7), int(size * 0.3):int(size * 0.7), :3] = card * 0.78
    return make_image(PREFIX + "Badge_BaseColor", img)


def build_materials(skin_image: bpy.types.Image | None) -> dict:
    sc = CONFIG["scrubs"]
    top_col, top_nrm = fabric_textures(sc["top_srgb_hex"], "Scrubs_Top", sc["texture_size"])
    tr_col, tr_nrm = fabric_textures(sc["trousers_srgb_hex"], "Scrubs_Trousers", sc["texture_size"])
    hair_col, hair_nrm = hair_textures()
    mats = {
        "skin": principled("Naomi_Skin", roughness=CONFIG["skin"]["roughness"], image=skin_image,
                           subsurface=0.18, specular=0.45),
        "top": principled("Naomi_Scrubs_Top", roughness=sc["roughness"], image=top_col, normal=top_nrm,
                          specular=0.25),
        "trousers": principled("Naomi_Scrubs_Trousers", roughness=sc["roughness"], image=tr_col,
                               normal=tr_nrm, specular=0.25),
        "shoes": principled("Naomi_Shoes", color=hex_rgb(CONFIG["shoes"]["srgb_hex"]),
                            roughness=CONFIG["shoes"]["roughness"]),
        "hair": principled("Naomi_Hair", roughness=0.55, image=hair_col, normal=hair_nrm, specular=0.4),
        "hair_cap": principled("Naomi_Hair_Cap", color=hex_rgb(CONFIG["hair"]["srgb_hex"]), roughness=0.75,
                               specular=0.3),
        "eye": principled("Naomi_Eye", roughness=0.08, image=eye_texture(), coat=0.6, specular=0.6),
        "badge": principled("Naomi_ID_Badge", roughness=0.35, image=badge_texture(), specular=0.5),
    }
    return mats


# ------------------------------------------------------------------ export/render

def triangle_count(objs) -> int:
    depsgraph = bpy.context.evaluated_depsgraph_get()
    total = 0
    for obj in objs:
        if obj.type != "MESH":
            continue
        ev = obj.evaluated_get(depsgraph)
        m = ev.to_mesh()
        m.calc_loop_triangles()
        total += len(m.loop_triangles)
        ev.to_mesh_clear()
    return total


def decimate(obj: bpy.types.Object, ratio: float, protect: str = "") -> None:
    """Collapse-decimate a mesh, optionally keeping one vertex group (the face) at full detail."""
    select_only(obj)
    mod = obj.modifiers.new("Decimate", "DECIMATE")
    mod.decimate_type = "COLLAPSE"
    mod.ratio = ratio
    if protect and protect in obj.vertex_groups:
        mod.vertex_group = protect
        mod.invert_vertex_group = True
        mod.vertex_group_factor = 1.0
    while obj.modifiers.find(mod.name) > 0:
        bpy.ops.object.modifier_move_up(modifier=mod.name)
    bpy.ops.object.modifier_apply(modifier=mod.name)


def export_glb(rig: bpy.types.Object, meshes: list[bpy.types.Object]) -> None:
    bpy.ops.object.select_all(action="DESELECT")
    rig.select_set(True)
    for obj in meshes:
        obj.select_set(True)
    bpy.context.view_layer.objects.active = rig
    GLB_OUT.parent.mkdir(parents=True, exist_ok=True)
    result = bpy.ops.export_scene.gltf(
        filepath=str(GLB_OUT), export_format="GLB", use_selection=True, export_apply=False,
        export_animations=False, export_skins=True, export_morph=False, export_texcoords=True,
        export_normals=True, export_image_format="AUTO")
    if "FINISHED" not in result:
        raise RuntimeError(f"glTF export failed: {result}")


def strip_png_metadata(path: Path) -> None:
    data = path.read_bytes()
    out = bytearray(data[:8])
    off = 8
    while off < len(data):
        length = struct.unpack_from(">I", data, off)[0]
        end = off + 12 + length
        ctype = data[off + 4:off + 8]
        payload = data[off + 8:off + 8 + length]
        if not (ctype == b"tEXt" and (payload.startswith(b"Date\x00") or payload.startswith(b"RenderTime\x00"))):
            out.extend(data[off:end])
        off = end
    path.write_bytes(out)


def aim(obj, target: Vector) -> None:
    obj.rotation_euler = (target - obj.location).to_track_quat("-Z", "Y").to_euler()


def render_views(collection_objs) -> list[Path]:
    scene = bpy.context.scene
    r = CONFIG["render"]
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = int(r["samples"])
    scene.cycles.use_denoising = True
    scene.cycles.seed = 3
    scene.render.resolution_x = int(r["width"])
    scene.render.resolution_y = int(r["height"])
    scene.render.film_transparent = False
    scene.view_settings.view_transform = "AgX"
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.16, 0.17, 0.18, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    for name, loc, power, size in (("Key", (-2.4, -3.2, 3.2), 380.0, 2.5),
                                   ("Fill", (2.8, -2.2, 2.0), 140.0, 3.0),
                                   ("Rim", (0.6, 2.8, 3.0), 260.0, 1.8)):
        ld = bpy.data.lights.new(PREFIX + name, "AREA")
        ld.energy = power
        ld.size = size
        lo = bpy.data.objects.new(PREFIX + name, ld)
        scene.collection.objects.link(lo)
        lo.location = loc
        aim(lo, Vector((0, 0, 1.1)))
    cam_data = bpy.data.cameras.new(PREFIX + "Review_Camera")
    cam = bpy.data.objects.new(PREFIX + "Review_Camera", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    views = {
        "front": ((0, -4.6, 1.0), (0, 0, 0.86), 72),
        "three_quarter": ((-2.6, -3.8, 1.2), (0, 0, 0.88), 72),
        "right": ((-4.6, 0, 1.0), (0, 0, 0.86), 72),
        "back": ((0, 4.6, 1.0), (0, 0, 0.86), 72),
        "face": ((-0.32, -0.95, 1.6), (0, -0.04, 1.53), 85),
    }
    RENDER_DIR.mkdir(parents=True, exist_ok=True)
    paths = []
    for view in RENDER_VIEWS:
        loc, target, lens = views[view]
        cam.location = loc
        cam_data.lens = lens
        aim(cam, Vector(target))
        path = RENDER_DIR / f"Naomi_Bennett_{VERSION}_{view}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        strip_png_metadata(path)
        paths.append(path)
    return paths


def main() -> None:
    body, rig, eye_data, source_digest = load_source()
    dz = align_rig_to_mesh(body, rig)
    relax_pose(body, rig)
    skin_image = bake_skin_texture(body, eye_data)
    mats = build_materials(skin_image)
    body.data.materials.append(mats["skin"])
    for poly in body.data.polygons:
        poly.use_smooth = True
    clothing, _covered = build_clothing(body, rig, mats)
    for obj in clothing:
        project_fabric_uvs(obj)
        copy_weights_from(obj, body)
    badge = build_badge(body, rig, clothing[0], mats)
    eyes = build_eyes(rig, eye_data, mats)
    hair = build_hair(body, rig, mats)
    meshes = [body, *clothing, badge, *eyes, *hair]
    for obj in meshes:
        if obj is not body:
            limit_influences(obj)
    limit_influences(body)
    # Remove empty vertex groups that are not bones (Godot only needs bone weights).
    bone_names = {b.name for b in rig.data.bones}
    for obj in meshes:
        for g in list(obj.vertex_groups):
            if g.name not in bone_names:
                obj.vertex_groups.remove(g)
    body.name = PREFIX + "Bennett_Body"
    rig.name = PREFIX + "Bennett_Rig"
    decimate(body, CONFIG["mesh"]["body_ratio"], protect="head")
    for obj, key in ((clothing[0], "clothing_ratio"), (clothing[1], "clothing_ratio"),
                     (clothing[2], "shoe_ratio")):
        decimate(obj, CONFIG["mesh"][key])
    for obj in meshes:
        print(f"  {obj.name}: {triangle_count([obj])} triangles")
    tris = triangle_count(meshes)
    budget = int(os.environ.get("NAOMI_TRIANGLE_BUDGET", CONFIG["mesh"]["triangle_budget"]))
    if tris > budget:
        raise RuntimeError(f"{tris} triangles exceeds the {budget} budget")
    collection = bpy.data.collections.new(PREFIX + "Bennett_" + VERSION)
    bpy.context.scene.collection.children.link(collection)
    for obj in [rig, *meshes]:
        link(obj, collection)
    collection["character_id"] = "staff_bennett"
    collection["production_status"] = CONFIG["character"]["production_status"]
    export_glb(rig, meshes)
    renders = render_views(meshes)
    for image in bpy.data.images:
        if image.name.startswith(PREFIX) and not image.packed_file and image.has_data:
            image.pack()
    BLEND_OUT.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(BLEND_OUT), compress=True)
    manifest = {
        "asset_id": f"CHR_NaomiBennett_{VERSION}",
        "character_id": "staff_bennett",
        "version": VERSION,
        "production_status": CONFIG["character"]["production_status"],
        "approved": False,
        "builder": "tools/blender/characters/build_naomi_v03.py",
        "config": "tools/blender/characters/naomi_v03.json",
        "blender_version": bpy.app.version_string,
        "inputs": [{
            "path": CONFIG["source"]["blend"],
            "sha256": source_digest,
            "used": "MPFB2 2.0.18 body mesh, UVs, skin weights and game_engine rig only; "
                    "provenance in assets/asset_manifest/naomi_character_manifest_v02.json",
        }],
        "external_assets": [],
        "generated": ["skin, eye, fabric, hair and badge textures (procedural, this script)",
                      "scrub top, trousers, shoes, badge, eyes, twists and bun geometry"],
        "rig_alignment_offset_z_m": round(dz, 4),
        "triangle_count": tris,
        "outputs": {
            "blend": str(BLEND_OUT.relative_to(ROOT)),
            "glb": str(GLB_OUT.relative_to(ROOT)),
            "renders": [str(p.relative_to(ROOT)) for p in renders],
        },
        "known_limitations": [
            "No animation clips, facial blend shapes or LODs.",
            "Skin texture is baked from procedural colour; no pore-level or photographic detail.",
            "Twists are tube geometry, not groomed hair; no flyaways or edge detail.",
            "Clothing is an offset shell of the body, not a simulated garment; no seams or pockets.",
            "Not measured on the target Mac.",
        ],
    }
    MANIFEST_OUT.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"NAOMI {VERSION} OK: {tris} triangles, rig offset {dz:.3f} m, {len(renders)} renders")


if __name__ == "__main__" or os.environ.get("NAOMI_BUILD") == "1":
    try:
        main()
    finally:
        sys.stdout.flush()
