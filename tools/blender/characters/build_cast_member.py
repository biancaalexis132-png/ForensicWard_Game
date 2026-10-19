"""Build a draft cast member from the MPFB base bodies already in the repository.

Every Forensic Ward character shares Naomi's MPFB base mesh, game_engine rig and
UVs (`Naomi_Bennett_Base_v01.blend` is the male base, `_v02` the female). This
builder reuses `build_naomi_v03.py`'s proven steps (rig alignment, relaxed rest
pose, offset-shell clothing, eyes, decimation with the face protected) and adds
what the rest of the cast needs, all driven by `cast/<character_id>.json`:

* a new body from the base's own macro shape keys (sex, age, ethnicity blend,
  muscle and weight), with every bone moved with the surrounding flesh and the
  whole character scaled to the configured height;
* layered garments: tops with short, long or no sleeves, crew, V or open-front
  necklines (blazer, cardigan), shirt and polo collars, tucked shirts, trousers,
  shoes, belt, radio, key reel, ID badge, reading glasses;
* hair styles for the cast: short crop, low chignon and low ponytail, with grey;
* a skin bake without v03's crease-height lash line (the v06 defect), with
  optional beard shadow.

It also writes the profiles for the next pipeline steps
(`tools/character_animation/profiles/<id>_v01*.json`): the shared clips and face
shapes (build_animated_character.py), Naomi's MPFB face shapes carried over
(transfer_face_shapes.py) and the lid and hem refinements (refine_character.py).

Everything is procedural or from the MPFB2 base already recorded in
`assets/asset_manifest/naomi_character_manifest_v02.json`; nothing is downloaded.
Run from the repository root:

    /Applications/Blender.app/Contents/MacOS/Blender --background --python-exit-code 1 \
        --python tools/blender/characters/build_cast_member.py -- \
        --config tools/blender/characters/cast/staff_voss.json
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import math
import sys
from pathlib import Path

import bpy  # noqa: I001  (bpy must load before bmesh in the standalone module)
import bmesh
import numpy as np
from mathutils import Matrix, Vector
from mathutils.bvhtree import BVHTree
from mathutils.kdtree import KDTree

ROOT = Path.cwd()
if not (ROOT / "project.godot").exists():
    raise SystemExit("Run from the repository root (project.godot not found).")


def _load(name: str, path: str):
    spec = importlib.util.spec_from_file_location(name, ROOT / path)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


v3 = _load("naomi_v03", "tools/blender/characters/build_naomi_v03.py")
anim = _load("animated_builder", "tools/character_animation/build_animated_character.py")
cards_mod = _load("cast_hair_cards", "tools/blender/characters/cast_hair_cards.py")
detail_mod = _load("cast_garment_detail", "tools/blender/characters/cast_garment_detail.py")

# Naomi's height: build_naomi_v03's body-region thresholds assume it, so every body
# is built at this height and scaled to its own height at the end.
NOMINAL_HEIGHT_M = 1.665
BUILD_DIR = ROOT / "build/cast"
BUILD_REL = "build/cast"
ARM_PREFIXES = ("upperarm", "lowerarm", "hand", "index", "middle", "ring", "pinky", "thumb")
HAND_PREFIXES = ("hand", "index", "middle", "ring", "pinky", "thumb")
CFG: dict = {}
PREFIX = ""


def parse_args() -> argparse.Namespace:
    argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
    p = argparse.ArgumentParser()
    p.add_argument("--config", required=True)
    p.add_argument("--no-render", action="store_true")
    return p.parse_args(argv)


def hex_rgb(value: str, linear: bool = False):
    return v3.hex_rgb(value, linear=linear)


# ------------------------------------------------------------------ body and rig

def macro_weights(base_keys: list[str], macro: dict) -> dict[str, float]:
    """MPFB macro key weights for one sex from age, ethnicity, muscle and weight.

    The base files carry young and old universal keys and young ethnicity keys
    (African also has an old key). Old weight is the share of the way from 25 to
    90 years; the young ethnicity keys take their full share at any age, as the
    base files have no old Caucasian or Asian key.
    """
    old = float(np.clip((macro["age_years"] - 25.0) / 65.0, 0.0, 1.0))
    young = 1.0 - old
    eth = macro["ethnicity"]
    total = sum(eth.values())
    e = {k: v / total for k, v in eth.items()}
    m_min = float(macro.get("min_muscle", 0.075))
    w_max = float(macro.get("max_weight", 0.035))
    weights = {}
    for name in base_keys:
        if name == "Basis":
            continue
        if "universal" in name:
            if "-$yn-min$mu" in name:
                weights[name] = young * m_min
            elif "-$yn-$av$mu-max$wg" in name:
                weights[name] = young * w_max
            elif "-$yn-$av$mu" in name:
                weights[name] = young * (1.0 - m_min - w_max)
            elif "-old-min$mu" in name:
                weights[name] = old * m_min
            elif "-old-$av$mu" in name:
                weights[name] = old * (1.0 - m_min)
        elif "-$af-" in name:
            weights[name] = e.get("african", 0.0) * (old if name.endswith("old") else young)
        elif "-$ca-" in name:
            weights[name] = e.get("caucasian", 0.0)
        elif "-$as-" in name:
            weights[name] = e.get("asian", 0.0)
    missing = [k for k in base_keys if k != "Basis" and k not in weights]
    if missing:
        raise RuntimeError(f"Unrecognised MPFB macro keys: {missing}")
    return weights


def key_mix(body: bpy.types.Object, values: dict[str, float]) -> np.ndarray:
    blocks = body.data.shape_keys.key_blocks
    n = len(body.data.vertices)

    def arr(block):
        a = np.zeros(n * 3)
        block.data.foreach_get("co", a)
        return a.reshape(-1, 3)

    basis = arr(blocks["Basis"])
    out = basis.copy()
    for name, w in values.items():
        out += w * (arr(blocks[name]) - basis)
    return out


def load_body() -> tuple[bpy.types.Object, bpy.types.Object, list, dict]:
    """Open the base, apply this character's macro mix, refit the rig, scale to nominal."""
    src = ROOT / CFG["source"]["blend"]
    digest = hashlib.sha256(src.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(src))
    body = bpy.data.objects[CFG["source"]["body"]]
    rig = bpy.data.objects[CFG["source"]["rig"]]
    for obj in list(bpy.data.objects):
        if obj not in (body, rig):
            bpy.data.objects.remove(obj, do_unlink=True)
    for block in (bpy.data.materials, bpy.data.images, bpy.data.meshes, bpy.data.lights,
                  bpy.data.cameras, bpy.data.curves):
        for item in list(block):
            if item.users == 0:
                block.remove(item)
    if body.matrix_world != Matrix.Identity(4) or rig.matrix_world != Matrix.Identity(4):
        raise RuntimeError("Base body and rig must have identity object transforms.")
    blocks = body.data.shape_keys.key_blocks
    stored = {k.name: k.value for k in blocks if k.name != "Basis"}
    new = macro_weights([k.name for k in blocks], CFG["macro"])
    ref_co = key_mix(body, stored)
    new_co = key_mix(body, new)
    for name, w in new.items():
        blocks[name].value = w
    v3.select_only(body)
    bpy.ops.object.shape_key_remove(all=True, apply_mix=True)

    weights, names = v3.vertex_weights(body)
    helper = (weights[:, names.index("HelperGeometry")] > 0) | (weights[:, names.index("JointCubes")] > 0)

    # The stored rig sits below the mesh (see build_naomi_v03.align_rig_to_mesh): fit it to
    # the stored mix first, then move each bone end with the flesh around it.
    offsets = []
    for bone in rig.data.bones:
        if bone.name not in names or bone.name.startswith(ARM_PREFIXES[3:]):
            continue
        sel = weights[:, names.index(bone.name)] > 0.7
        if sel.sum() < 30:
            continue
        mid = (Vector(bone.head_local) + Vector(bone.tail_local)) / 2.0
        offsets.append(ref_co[sel].mean(axis=0)[2] - mid.z)
    dz = float(np.median(offsets))
    skin = np.where(~helper)[0]
    tree = KDTree(len(skin))
    for j, i in enumerate(skin):
        tree.insert(ref_co[i], j)
    tree.balance()
    delta = new_co - ref_co

    def moved(p: Vector) -> Vector:
        near = tree.find_n(p, 24)
        d = np.array([delta[skin[j]] for _co, j, _dist in near])
        return p + Vector(d.mean(axis=0))

    lowest = new_co[skin, 2].min()
    height = new_co[skin, 2].max() - lowest
    scale = NOMINAL_HEIGHT_M / height
    v3.select_only(rig)
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in rig.data.edit_bones:
        head = moved(Vector((eb.head.x, eb.head.y, eb.head.z + dz)))
        tail = moved(Vector((eb.tail.x, eb.tail.y, eb.tail.z + dz)))
        eb.head = Vector((head.x * scale, head.y * scale, (head.z - lowest) * scale))
        eb.tail = Vector((tail.x * scale, tail.y * scale, (tail.z - lowest) * scale))
    bpy.ops.object.mode_set(mode="OBJECT")
    co = np.array([v.co[:] for v in body.data.vertices])
    co[:, 2] -= lowest
    co *= scale
    body.data.vertices.foreach_set("co", co.ravel())
    body.data.update()
    refit = refit_limb_joints(rig, co, weights, names, helper)

    eye_sockets = v3.find_eye_helpers(body, weights[:, names.index("HelperGeometry")] > 0)
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
    info = {
        "source_sha256": digest,
        "macro_weights": {k: round(v, 4) for k, v in new.items()},
        "base_height_m": round(float(height), 4),
        "base_floor_z_m": float(lowest),
        "normalise_scale": float(scale),
        "stored_rig_offset_z_m": round(dz, 4),
        "limb_joints_refit_m": refit,
    }
    return body, rig, eye_sockets, info


LIMB_JOINTS = (("thigh", "calf"), ("calf", "foot"), ("foot", "ball"), ("upperarm", "lowerarm"),
               ("lowerarm", "hand"))


def refit_limb_joints(rig, co: np.ndarray, weights: np.ndarray, names: list[str], helper: np.ndarray) -> dict:
    """Put knees, ankles, toes, elbows and wrists where the mesh bends.

    The stored rigs fit Naomi's mix; on the male base the shins and feet sit several
    centimetres high. The skin that blends between two bones is a ring around the
    joint, so its centroid is the joint. Children of a moved bone move with it.
    """
    moved = {}
    v3.select_only(rig)
    bpy.ops.object.mode_set(mode="EDIT")
    ebs = rig.data.edit_bones
    for side in ("l", "r"):
        for parent, child in LIMB_JOINTS:
            p, c = f"{parent}_{side}", f"{child}_{side}"
            ring = ~helper & (weights[:, names.index(p)] > 0.2) & (weights[:, names.index(c)] > 0.2)
            if ring.sum() < 12:
                continue
            target = Vector(co[ring].mean(axis=0).tolist())
            shift = target - ebs[c].head
            moved[c] = round(shift.length, 4)
            ebs[p].tail = target
            ebs[c].head = target
            if child in ("ball",):
                ebs[c].tail = ebs[c].tail + shift
            if child == "hand":
                ebs[c].tail = ebs[c].tail + shift
                for eb in ebs:
                    if eb.name.endswith(f"_{side}") and eb.name.startswith(HAND_PREFIXES[1:]):
                        eb.head = eb.head + shift
                        eb.tail = eb.tail + shift
    bpy.ops.object.mode_set(mode="OBJECT")
    return moved


def seat_pose(body, rig, spec: dict) -> None:
    """Thighs forward, shins down: a seated rest pose baked like relax_pose's arms."""
    v3.select_only(rig)
    bpy.ops.object.mode_set(mode="POSE")

    def aim_bone(pbone, direction: Vector) -> None:
        bpy.context.view_layer.update()
        current = (pbone.tail - pbone.head).normalized()
        rot = current.rotation_difference(direction.normalized()).to_matrix()
        m = pbone.matrix.to_3x3().normalized()
        pbone.rotation_mode = "QUATERNION"
        pbone.rotation_quaternion = pbone.rotation_quaternion @ (m.inverted() @ rot @ m).to_quaternion()
        bpy.context.view_layer.update()

    drop = math.radians(float(spec.get("thigh_drop_deg", 6.0)))
    spread = float(spec.get("knee_spread", 0.08))
    back = math.radians(float(spec.get("shin_back_deg", 4.0)))
    for side, sign in (("l", 1.0), ("r", -1.0)):
        aim_bone(rig.pose.bones[f"thigh_{side}"], Vector((sign * spread, -math.cos(drop), -math.sin(drop))))
        aim_bone(rig.pose.bones[f"calf_{side}"], Vector((0.0, math.sin(back), -math.cos(back))))
    bpy.ops.object.mode_set(mode="OBJECT")
    v3.select_only(body)
    arm_mod = next(m for m in body.modifiers if m.type == "ARMATURE")
    bpy.ops.object.modifier_apply(modifier=arm_mod.name)
    v3.select_only(rig)
    bpy.ops.object.mode_set(mode="POSE")
    bpy.ops.pose.armature_apply(selected=False)
    bpy.ops.object.mode_set(mode="OBJECT")
    mod = body.modifiers.new("Armature", "ARMATURE")
    mod.object = rig


def lower_character(rig, meshes, dz: float) -> None:
    m = Matrix.Translation((0.0, 0.0, -dz))
    for obj in meshes:
        obj.data.transform(m)
        obj.data.update()
    v3.select_only(rig)
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in rig.data.edit_bones:
        eb.head.z -= dz
        eb.tail.z -= dz
    bpy.ops.object.mode_set(mode="OBJECT")


def scale_character(rig: bpy.types.Object, meshes: list[bpy.types.Object], s: float) -> None:
    m = Matrix.Scale(s, 4)
    for obj in meshes:
        if obj.matrix_world != Matrix.Identity(4):
            v3.select_only(obj)
            bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
        obj.data.transform(m)
        obj.data.update()
    v3.select_only(rig)
    bpy.ops.object.mode_set(mode="EDIT")
    for eb in rig.data.edit_bones:
        eb.head = eb.head * s
        eb.tail = eb.tail * s
    bpy.ops.object.mode_set(mode="OBJECT")


# ------------------------------------------------------------------ face metrics

def face_metrics(body: bpy.types.Object, eye_data: list) -> dict:
    """Mouth landmarks for the animation profile, from MPFB's lips group."""
    weights, names = v3.vertex_weights(body)
    co = np.array([v.co[:] for v in body.data.vertices])
    lips = co[weights[:, names.index("lips")] > 0.5]
    eye_l, eye_r = np.array(eye_data[0]), np.array(eye_data[2])
    mid = (eye_l + eye_r) / 2
    half_ipd = abs(eye_l[0] - eye_r[0]) / 2
    front = lips[lips[:, 1] < np.percentile(lips[:, 1], 60)]
    return {
        "mouth_line_z_below_eyes_m": round(float(mid[2] - np.median(front[:, 2])), 4),
        "mouth_corner_x_of_eye_x": round(float(np.abs(lips[:, 0]).max() / half_ipd * 0.97), 3),
        "interpupillary_m": round(float(half_ipd * 2), 4),
    }


# ---------------------------------------------------------------------- textures

def bake_skin(body: bpy.types.Object, eye_data: list) -> bpy.types.Image:
    """build_naomi_v03.bake_skin_texture without the crease lash line, plus beard shadow."""
    sk = CFG["skin"]
    size = int(sk["texture_size"])
    tmp = body.copy()
    tmp.data = body.data.copy()
    bpy.context.scene.collection.objects.link(tmp)
    tmp.modifiers.clear()
    v3.select_only(tmp)
    sub = tmp.modifiers.new("Subdiv", "SUBSURF")
    sub.levels = 2
    sub.uv_smooth = "PRESERVE_BOUNDARIES"
    bpy.ops.object.modifier_apply(modifier=sub.name)
    mesh = tmp.data
    co = np.array([v.co[:] for v in mesh.vertices])
    weights, names = v3.vertex_weights(tmp)
    base = np.array(hex_rgb(sk["base_srgb_hex"]))
    shadow = np.array(hex_rgb(sk["shadow_srgb_hex"]))
    warm = np.array(hex_rgb(sk["warm_srgb_hex"]))
    lip = np.array(hex_rgb(sk["lip_srgb_hex"]))
    brow = np.array(hex_rgb(sk["brow_srgb_hex"]))
    nail = np.array(hex_rgb(sk["nail_srgb_hex"]))
    n1 = v3.smooth_noise(co, 0.06, 1)
    n2 = v3.smooth_noise(co, 0.012, 2)
    n3 = v3.smooth_noise(co, 0.003, 3)
    col = base[None, :] * (1.0 + 0.05 * n1[:, None] + 0.03 * n2[:, None] + 0.025 * n3[:, None])
    for g, amt in (("hand_l", 0.08), ("hand_r", 0.08), ("foot_l", 0.06), ("foot_r", 0.06)):
        w = weights[:, names.index(g)][:, None]
        col = col * (1 - w * amt) + shadow[None, :] * (w * amt)
    eye_l, eye_r = Vector(eye_data[0]), Vector(eye_data[2])
    mid = np.array(((eye_l + eye_r) / 2)[:])
    for eye in (eye_l, eye_r):
        side = 1 if eye.x > 0 else -1
        cheek = np.array((eye + Vector((0.012 * side, -0.01, -0.035)))[:])
        d = np.linalg.norm(co - cheek, axis=1)
        w = np.clip(1 - d / 0.03, 0, 1)[:, None] * float(sk.get("cheek_warmth", 0.35))
        col = col * (1 - w) + warm[None, :] * w
        rel = co - np.array(eye[:])
        lid = (np.abs(rel[:, 0]) < 0.02) & (rel[:, 2] > -0.016) & (rel[:, 2] < 0.017) & (rel[:, 1] < 0.0)
        dist = np.sqrt((rel[:, 0] / 0.019) ** 2 + (rel[:, 2] / 0.012) ** 2)
        w = (lid * np.clip(1.2 - dist, 0, 1) * float(sk.get("lid_shadow", 0.3)))[:, None]
        col = col * (1 - w) + shadow[None, :] * w
        bx = rel[:, 0] * side
        arc_z = 0.019 + 0.006 * np.cos(np.clip(bx / 0.03, -1.5, 1.5)) - 0.004 * np.clip(bx / 0.03, 0, 1) ** 2
        thick = 0.0052 * np.clip(1.15 - np.clip(bx + 0.012, 0, None) / 0.04, 0.35, 1.0)
        in_brow = (bx > -0.016) & (bx < 0.03) & (np.abs(rel[:, 2] - arc_z) < thick) & (rel[:, 1] < 0.0)
        streak = 0.65 + 0.35 * np.sin(bx * 2400 + rel[:, 2] * 900) * np.sin(bx * 900)
        fade = np.clip(1 - np.abs(rel[:, 2] - arc_z) / thick, 0, 1) * np.clip((0.03 - bx) / 0.012, 0, 1)
        w = (in_brow * fade * np.clip(streak, 0, 1) * float(sk.get("brow_strength", 0.85)))[:, None]
        col = col * (1 - w) + brow[None, :] * w
    lips_w = weights[:, names.index("lips")]
    beard = sk.get("beard_shadow")
    if beard:
        # Jaw, chin and upper lip below the cheekbones, fading into the neck and ears.
        rel = co - mid
        head_w = weights[:, names.index("head")]
        jaw = (rel[:, 2] < -0.035) & (rel[:, 2] > -0.16) & (np.abs(rel[:, 0]) < 0.075)
        cheek_line = rel[:, 2] < -0.04 - 0.25 * np.clip(0.06 - np.abs(rel[:, 0]), 0, None)
        fade = np.clip(head_w * 1.5 - 0.3, 0, 1) * np.clip((rel[:, 1] + 0.02) / -0.03 + 1.0, 0, 1)
        speck = np.clip(0.75 + 0.25 * v3.smooth_noise(co, 0.0012, 9), 0, 1)
        w = (jaw & cheek_line) * fade * speck * (1 - np.clip(lips_w * 2, 0, 1)) * float(beard["strength"])
        bc = np.array(hex_rgb(beard["srgb_hex"]))
        col = col * (1 - w[:, None]) + bc[None, :] * w[:, None]
    w = np.clip(lips_w * 1.2, 0, 1)[:, None] * float(sk.get("lip_strength", 0.85))
    col = col * (1 - w) + lip[None, :] * w
    for g in ("fingernails", "toenails"):
        w = weights[:, names.index(g)][:, None] * 0.8
        col = col * (1 - w) + nail[None, :] * w
    col = np.clip(col, 0, 1)
    attr = mesh.color_attributes.new("SkinPaint", "FLOAT_COLOR", "POINT")
    rgba = np.concatenate([np.vectorize(v3.srgb_to_linear)(col), np.ones((len(col), 1))], axis=1)
    attr.data.foreach_set("color", rgba.astype(np.float32).ravel())
    image = bpy.data.images.new(PREFIX + "Skin_BaseColor", size, size, alpha=False)
    mat = bpy.data.materials.new(PREFIX + "Skin_Bake")
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
    v3.select_only(tmp)
    bpy.ops.object.bake(type="EMIT", margin=12, use_clear=True)
    image.pack()
    bpy.data.objects.remove(tmp, do_unlink=True)
    bpy.data.materials.remove(mat)
    return image


def fabric_textures(color_hex: str, name: str, size: int, period: float, rib: float) -> tuple:
    """Twill (rib 0) or knit rib (rib > 0) colour and normal maps."""
    base = np.array(hex_rgb(color_hex))
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float64)
    p = size / period
    twill = np.sin((xx + yy) / p * math.pi) * 0.5 + 0.5
    weft = np.sin(yy / p * math.pi * 2) * 0.5 + 0.5
    ribs = np.abs(np.sin(xx / (p * 1.5) * math.pi))
    rng = np.random.default_rng(len(name))
    grain = rng.normal(0, 1, (size, size))
    grain = (grain + np.roll(grain, 1, 0) + np.roll(grain, 1, 1)) / 3
    height = (1 - rib) * (0.6 * twill + 0.3 * weft) + rib * ribs + 0.1 * grain
    shade = 1.0 + 0.07 * (height - 0.5) + 0.02 * grain
    col = np.ones((size, size, 4))
    col[..., :3] = np.clip(base[None, None, :] * shade[..., None], 0, 1)
    gx = np.roll(height, -1, 1) - np.roll(height, 1, 1)
    gy = np.roll(height, -1, 0) - np.roll(height, 1, 0)
    nrm = np.ones((size, size, 4))
    nrm[..., 0] = 0.5 - gx * 0.25
    nrm[..., 1] = 0.5 - gy * 0.25
    return (v3.make_image(PREFIX + name + "_BaseColor", col),
            v3.make_image(PREFIX + name + "_Normal", np.clip(nrm, 0, 1)))


def hair_textures(hair: dict) -> tuple:
    """Strand streaks along V, with a share of grey strands."""
    base = np.array(hex_rgb(hair["srgb_hex"]))
    grey = np.array(hex_rgb(hair.get("grey_srgb_hex", "#9a958f")))
    size = 512
    yy, xx = np.mgrid[0:size, 0:size].astype(np.float64)
    rng = np.random.default_rng(11)
    wave = np.sin(yy / 23.0) * 2.5
    fibres = 0.9 + 0.1 * np.sin((xx + wave) / 1.7) * np.sin((xx + wave) / 5.3 + 1.1)
    strand = ((xx + wave).astype(int) // 2) % size
    is_grey = rng.random(size) < float(hair.get("grey_fraction", 0.0))
    g = is_grey[strand][..., None]
    tone = rng.uniform(0.88, 1.06, size)[strand][..., None]
    colour = np.where(g, grey[None, None, :], base[None, None, :]) * tone
    col = np.ones((size, size, 4))
    col[..., :3] = np.clip(colour * fibres[..., None] * 1.08, 0, 1)
    gx = np.roll(fibres, -1, 1) - np.roll(fibres, 1, 1)
    nrm = np.ones((size, size, 4))
    nrm[..., 0] = 0.5 - gx * 0.8
    nrm[..., 1] = 0.5
    return (v3.make_image(PREFIX + "Hair_BaseColor", col),
            v3.make_image(PREFIX + "Hair_Normal", np.clip(nrm, 0, 1)))


def badge_texture(badge: dict) -> bpy.types.Image:
    card = np.array(hex_rgb(badge["card_srgb_hex"]))
    stripe = np.array(hex_rgb(badge["stripe_srgb_hex"]))
    size = 128
    img = np.ones((size, size, 4))
    img[..., :3] = card
    img[int(size * 0.78):int(size * 0.92), :, :3] = stripe
    # Blank photo area: no face, name or logo is invented.
    img[int(size * 0.38):int(size * 0.7), int(size * 0.3):int(size * 0.7), :3] = card * 0.78
    return v3.make_image(PREFIX + "Badge_BaseColor", img)


def build_materials(skin_image) -> dict:
    mats = {
        "skin": v3.principled(PREFIX + "Skin", roughness=CFG["skin"]["roughness"], image=skin_image,
                              subsurface=0.18, specular=0.45),
        "eye": v3.principled(PREFIX + "Eye", roughness=0.08, image=v3.eye_texture(), coat=0.6, specular=0.6),
    }
    for g in CFG["garments"] + CFG.get("accessories", []):
        if g.get("kind") in ("top", "trousers", "collar"):
            tex = g.get("texture", {})
            col, nrm = fabric_textures(g["srgb_hex"], g["name"], int(tex.get("size", 1024)),
                                       float(tex.get("period", 128)), float(tex.get("rib", 0.0)))
            mats[g["name"]] = v3.principled(PREFIX + g["name"], roughness=float(tex.get("roughness", 0.86)),
                                            image=col, normal=nrm, specular=float(tex.get("specular", 0.25)))
        else:
            mats[g["name"]] = v3.principled(PREFIX + g["name"], color=hex_rgb(g["srgb_hex"], linear=True),
                                            roughness=float(g.get("roughness", 0.45)),
                                            specular=float(g.get("specular", 0.4)))
    hair = CFG["hair"]
    if hair.get("cards") is not None:
        # v02: a dark, stripe-free scalp base under alpha-scissor hair cards.
        cfg = hair_card_config(hair)
        atlas = cards_mod.strand_atlas(hair, PREFIX + "Hair_Strands_BaseColor", int(cfg["atlas_size"]),
                                       int(cfg["seed"]))
        mats["hair"] = cards_mod.base_material(
            PREFIX + "Hair_Base", cards_mod.base_texture(hair, PREFIX + "Hair_Base_BaseColor", int(cfg["seed"]),
                                                         atlas.get("mean_srgb")),
            roughness=0.8)
        mats["hair_cards"] = cards_mod.card_material(PREFIX + "Hair_Cards", atlas,
                                                     roughness=float(hair.get("card_roughness", 0.68)),
                                                     specular=float(hair.get("card_specular", 0.22)))
        mats["hair_tie"] = v3.principled(PREFIX + "Hair_Tie", color=hex_rgb(hair.get("tie_srgb_hex", "#151414"), linear=True),
                                         roughness=0.5, specular=0.3)
    else:
        hcol, hnrm = hair_textures(hair)
        # No normal map: at game distances the fine strand normals alias into bright ribs.
        bpy.data.images.remove(hnrm)
        mats["hair"] = v3.principled(PREFIX + "Hair", roughness=float(hair.get("roughness", 0.62)), image=hcol,
                                     specular=float(hair.get("specular", 0.22)))
    for key in ("badge",):
        if CFG.get(key):
            mats[key] = v3.principled(PREFIX + "ID_Badge", roughness=0.35, image=badge_texture(CFG[key]),
                                      specular=0.5)
    return mats


# ---------------------------------------------------------------------- clothing

class BodyRegions:
    """Face-level lookups on the posed full body that every garment is cut from."""

    def __init__(self, body: bpy.types.Object, rig: bpy.types.Object):
        self.body = body
        self.rig = rig
        dom = v3.dominant_bones(body)
        polys = body.data.polygons
        self.centres = np.array([f.center[:] for f in polys])
        self.dom = np.array([dom[f.vertices[0]] for f in polys])
        self.hand = np.array([d.startswith(HAND_PREFIXES) for d in self.dom])
        self.neck = Vector(rig.data.bones["neck_01"].head_local)
        # Height of the soles: 0 standing, the knee drop when seated.
        feet = np.isin(self.dom, ["foot_l", "foot_r", "ball_l", "ball_r"])
        self.sole_z = float(self.centres[feet, 2].min())
        self.bone = {b.name: (Vector(b.head_local), Vector(b.tail_local)) for b in rig.data.bones}
        bm = bmesh.new()
        bm.from_mesh(body.data)
        bm.faces.ensure_lookup_table()
        self.adjacent = [[o.index for e in f.edges for o in e.link_faces if o.index != f.index] for f in bm.faces]
        bm.free()

    def shoulder_distance(self) -> np.ndarray:
        sl, sr = self.bone["upperarm_l"][0], self.bone["upperarm_r"][0]
        c = self.centres
        return np.minimum(np.linalg.norm(c - np.array(sl), axis=1), np.linalg.norm(c - np.array(sr), axis=1))

    def sleeve(self, length: str, cuff_gap: float = 0.02) -> np.ndarray:
        if length == "none":
            return np.zeros(len(self.dom), dtype=bool)
        upper = np.isin(self.dom, ["upperarm_l", "upperarm_r"])
        if length == "short":
            return upper & (self.shoulder_distance() < 0.19)
        lower = np.zeros(len(self.dom), dtype=bool)
        for side in ("l", "r"):
            head, tail = self.bone[f"lowerarm_{side}"]
            axis = tail - head
            t = ((self.centres - np.array(head)) @ np.array(axis)) / axis.length_squared
            lower |= (self.dom == f"lowerarm_{side}") & (t < 1.0 - cuff_gap / axis.length)
        return upper | lower

    def neckline(self, spec: dict) -> np.ndarray:
        x, y, z = self.centres.T
        nz = self.neck.z
        kind = spec["type"]
        depth = float(spec.get("depth_m", 0.03))
        if kind == "v":
            return (y < 0) & (z > nz - depth + np.abs(x) * float(spec.get("slope", 1.25)))
        if kind == "crew":
            half = float(spec.get("half_width_m", 0.07))
            return (y < 0) & (z > nz - depth + (np.abs(x) / half) ** 2 * depth)
        if kind == "open_front":
            # Blazer or cardigan: a V from the collar to the button, then closed or a narrow gap.
            gap = float(spec.get("gap_m", 0.0))
            button = float(spec["button_z_m"])
            half = gap + np.clip(z - button, 0, None) * float(spec.get("slope", 0.25))
            return (y < 0) & (np.abs(x) < half) & ((z > button) | (gap > 0))
        raise ValueError(f"Unknown neckline {kind!r}")

    def interior(self, mask: np.ndarray, margin: float) -> np.ndarray:
        """Faces of mask further than margin from its edge (hem, cuff, neckline)."""
        edge = [i for i in np.where(mask)[0] if any(not mask[o] for o in self.adjacent[i])]
        if not edge:
            return mask.copy()
        tree = KDTree(len(edge))
        for j, i in enumerate(edge):
            tree.insert(self.centres[i], j)
        tree.balance()
        out = np.zeros(len(mask), dtype=bool)
        for i in np.where(mask)[0]:
            _co, _j, d = tree.find(self.centres[i])
            out[i] = d > margin
        return out


def top_offset_fn(g: dict, under=None):
    drape = g.get("drape", {"from_z_m": 1.12, "per_m": 0.03})
    base_off = float(g.get("offset_m", 0.011))
    gap = float(g.get("layer_gap_m", 0.007))

    def fn(p):
        own = base_off + max(0.0, drape["from_z_m"] - p.z) * drape["per_m"]
        if under is not None:
            return max(own, under(p) + gap)
        return own
    return fn


def cloth_proxy(body: bpy.types.Object, iterations: int = 40, round_iterations: int = 30) -> bpy.types.Object:
    """A copy of the body with a cloth-like torso for tops to be cut from and pushed out of.

    Tops are pushed out from the nearest body point, so a shell over the bare
    body repeats the nipples, the point of the breasts and the navel. Cloth
    tents over hollows and rounds over points instead. First each torso vertex
    moves outward (never inward) toward its neighbours' mean, which fills the
    hollows; then volume-preserving (Taubin) smoothing rounds the points. The
    skin under a top is removed, so the few millimetres the rounding takes off a
    point never show through.
    """
    mesh = body.data.copy()
    proxy = bpy.data.objects.new(body.name + "_ClothProxy", mesh)
    bpy.context.scene.collection.objects.link(proxy)
    proxy.matrix_world = body.matrix_world
    dom = v3.dominant_bones(body)
    torso = {"pelvis", "spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r"}
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.verts.ensure_lookup_table()
    verts = [v for v in bm.verts if dom[v.index] in torso and not v.is_boundary]
    nbrs = [[e.other_vert(v) for e in v.link_edges] for v in verts]
    for _ in range(iterations):
        bm.normal_update()
        moves = []
        for v, ns in zip(verts, nbrs):
            avg = sum((n.co for n in ns), Vector()) / len(ns)
            d = (avg - v.co).dot(v.normal)
            if d > 0:
                moves.append((v, v.normal * d * 0.5))
        for v, m in moves:
            v.co += m
    for _ in range(round_iterations):
        for factor in (0.5, -0.53):
            avgs = [sum((n.co for n in ns), Vector()) / len(ns) for ns in nbrs]
            for v, avg in zip(verts, avgs):
                v.co += (avg - v.co) * factor
    moved = max(((v.co - mesh.vertices[v.index].co).length for v in verts), default=0.0)
    print(f"  cloth proxy: {len(verts)} torso vertices, largest change {moved * 1000:.1f} mm")
    bm.to_mesh(mesh)
    bm.free()
    return proxy


def build_clothing(body, rig, mats) -> tuple[list[bpy.types.Object], dict]:
    reg = BodyRegions(body, rig)
    x, y, z = reg.centres.T
    built: dict[str, tuple[bpy.types.Object, np.ndarray, object]] = {}
    covered = np.zeros(len(z), dtype=bool)
    objs = []
    shell_loops: dict[str, list] = {}
    proxy = cloth_proxy(body)
    torso_bones = ["pelvis", "spine_01", "spine_02", "spine_03", "clavicle_l", "clavicle_r", "neck_01"]
    for g in CFG["garments"]:
        kind = g["kind"]
        if kind == "top":
            collar = g.get("collar")
            top_limit = reg.neck.z + (float(collar["rise_m"]) if collar else -0.005)
            torso = np.isin(reg.dom, torso_bones + ["head"]) & (z < top_limit)
            mask = ((torso & ~reg.neckline(g["neckline"])) | reg.sleeve(g["sleeves"])) & ~reg.hand
            mask &= z > float(g["hem_z_m"])
            under = built[g["over"]][2] if g.get("over") else None
            fn = top_offset_fn(g, under)
            if collar:
                # A collar that stands up the neck and turns outward toward its edge.
                def fn(p, inner=fn, nz=top_limit - float(collar.get("height_m", 0.035)),
                       flare=float(collar["flare"])):
                    return inner(p) + max(0.0, p.z - nz) * flare
            obj, loops = detail_mod.garment_shell(v3, PREFIX + g["name"], proxy, mask, fn, int(g.get("smooth", 40)),
                                                  float(g.get("thickness_m", 0.0022)), mats[g["name"]],
                                                  decimate_ratio=detail_ratio(g))
            shell_loops[g["name"]] = loops
            covered |= reg.interior(mask, float(g.get("skin_margin_m", 0.04)))
        elif kind == "trousers":
            waist = float(g.get("waist_z_m", 1.0))
            legs = np.isin(reg.dom, ["pelvis", "thigh_l", "thigh_r", "calf_l", "calf_r", "spine_01"]) | (
                np.isin(reg.dom, ["foot_l", "foot_r"]) & (z > 0.10 + reg.sole_z))
            mask = legs & (z < waist) & (z > 0.085 + reg.sole_z) & ~reg.hand
            mask &= ~np.array([d.startswith(ARM_PREFIXES) for d in reg.dom])
            knee_z = reg.bone["calf_l"][0].z
            off = float(g.get("offset_m", 0.012))
            band = float(g.get("waistband_extra_m", 0.0))
            tucked = [built[n][2] for n in g.get("over", [])]

            ease = float(g.get("detail", {}).get("hip_ease_m", 0.0))

            def fn(p, off=off, knee_z=knee_z, band=band, waist=waist, tucked=tucked, ease=ease):
                own = off + max(0.0, knee_z - p.z) * 0.02
                if ease:
                    # A little room over the hips and thighs, so cloth does not cling
                    # and the hanging hand does not meet the leg.
                    rise = min(1.0, max(0.0, (p.z - knee_z - 0.04) / 0.14))
                    fall = min(1.0, max(0.0, (waist - 0.03 - p.z) / 0.09))
                    own += ease * rise * fall
                if p.z > waist - 0.08:
                    own += band
                    for t in tucked:
                        own = max(own, t(p) + 0.004)
                return own
            hem_r = float(g.get("hem_radius_m", 0.074))
            # Straighten the legs before thickening: straightening both walls to one radius
            # made them coincide and fight below the knee.
            legs_fn = None if CFG.get("seated") else (lambda o, r=hem_r: straight_legs(o, rig, r))
            obj, loops = detail_mod.garment_shell(v3, PREFIX + g["name"], body, mask, fn, 14, 0.0022, mats[g["name"]],
                                                  before_thicken=legs_fn if g.get("detail") is not None else None,
                                                  decimate_ratio=detail_ratio(g))
            shell_loops[g["name"]] = loops
            if not CFG.get("seated") and g.get("detail") is None:
                straight_legs(obj, rig, hem_r)
            covered |= reg.interior(mask, 0.04) & (z < waist - 0.03)
        elif kind == "shoes":
            mask = np.isin(reg.dom, ["foot_l", "foot_r", "ball_l", "ball_r"]) & (
                z < float(g.get("top_z_m", 0.115)) + reg.sole_z)
            obj = v3.shell_from_faces(PREFIX + g["name"], body, mask,
                                      lambda p, s=reg.sole_z: 0.007 + max(0.0, 0.035 - (p.z - s)) * 0.12, 60, 0.003,
                                      mats[g["name"]])
            covered |= mask
        elif kind == "collar":
            obj = collar_band(body, reg, g, built[g["of"]][2], mats[g["name"]])
            fn = None
        elif kind == "belt":
            waist = float(g["z_m"])
            width = float(g.get("width_m", 0.035))
            mask = np.isin(reg.dom, ["pelvis", "spine_01", "thigh_l", "thigh_r"]) & (z < waist) & \
                (z > waist - width) & ~reg.hand & ~np.array([d.startswith(ARM_PREFIXES) for d in reg.dom])
            trousers = built[g["over"]][2]
            obj = v3.shell_from_faces(PREFIX + g["name"], body, mask, lambda p, t=trousers: t(p) + 0.004,
                                      4, 0.004, mats[g["name"]])
            fn = None
        else:
            continue
        built[g["name"]] = (obj, mask, fn if kind in ("top", "trousers") else None)
        if kind in ("top", "trousers"):
            # Later layers read this garment's offset to sit outside it.
            built[g["name"]] = (obj, mask, fn)
        objs.append(obj)

    details = {}
    skin_weights = detail_mod.SkinWeights(v3, body) if any(g.get("detail") is not None for g in CFG["garments"]) else None
    for g in CFG["garments"]:
        if g.get("detail") is not None and g["name"] in built:
            details[g["name"]] = finish_garment(g, built[g["name"]][0], shell_loops.get(g["name"], []), reg, mats,
                                                skin_weights)
    # Keep skin near the neckline visible under open fronts and V necks.
    bm = bmesh.new()
    bm.from_mesh(body.data)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if covered[f.index]], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(body.data)
    bm.free()
    for obj in objs:
        v3.parent_to_rig(obj, rig)
    bpy.data.objects.remove(proxy, do_unlink=True)
    return objs, {"covered_faces": int(covered.sum()), "garment_detail": details}


def detail_ratio(g: dict) -> float | None:
    """v02 garments are decimated as single surfaces, before they are thickened."""
    return float(CFG["mesh"]["clothing_ratio"]) if g.get("detail") is not None else None


def darker_hex(value: str, k: float) -> str:
    r, g, b = (int(value.lstrip("#")[i:i + 2], 16) for i in (0, 2, 4))
    return "#" + "".join(f"{max(0, min(255, int(round(c * k)))):02x}" for c in (r, g, b))


def finish_garment(g: dict, obj, loops: list[dict], reg: "BodyRegions", mats: dict, skin_weights) -> dict:
    """v02 detail on one garment: decimate, unique UVs, baked folds, trims joined in."""
    spec = dict(g["detail"])
    spec.setdefault("sleeves", g.get("sleeves"))
    kind = g["kind"]
    tucked_into = [t for t in CFG["garments"] if t.get("kind") == "trousers" and g["name"] in t.get("over", [])]
    if kind == "top" and tucked_into:
        spec.setdefault("tucked", True)
    obj["cast_detail"] = True  # decimated in garment_shell, before thickening
    inner_faces = detail_mod.smart_uvs(v3, obj, reg.body)
    sk = detail_mod.Skeleton(reg.rig)
    seated = bool(CFG.get("seated"))
    hem_z = float(g["hem_z_m"]) if "hem_z_m" in g else None

    bones = [f"{b}_{s}" for b in ("upperarm", "lowerarm", "hand", "thigh", "calf", "foot", "clavicle") for s in "lr"]
    bones += ["pelvis", "spine_01", "spine_02", "spine_03", "neck_01"]

    def h_fn(P):
        return detail_mod.fold_height(P, skin_weights.at(P, bones), kind, spec, sk, anim.value_noise, seated, hem_z)
    tex = g.get("texture", {})
    size = int(spec.get("texture_size", 1024))
    base = np.array(hex_rgb(g["srgb_hex"]))
    ci, ni, info = detail_mod.bake_fold_maps(anim, obj, h_fn, base, size, PREFIX + g["name"] + "_Folds",
                                            shade=float(spec.get("fold_shade", 22.0)), v3=v3)
    main = detail_mod.fabric_material(PREFIX + g["name"], ci, ni, float(tex.get("roughness", 0.86)),
                                      float(tex.get("specular", 0.25)), float(spec.get("normal_strength", 1.0)))
    old = obj.data.materials[0]
    obj.data.materials[0] = main
    mats[g["name"]] = main
    if old is not None and old.users == 0:
        bpy.data.materials.remove(old)
    # Trim material: the garment's cloth, tiled, a touch darker; rib knit when asked.
    trim = spec.get("trim", {})
    tcol, tnrm = fabric_textures(darker_hex(g["srgb_hex"], float(trim.get("tone", 0.94))), g["name"] + "_Trim",
                                 256, float(trim.get("period", 24)), float(trim.get("rib", 0.0)))
    trim_mat = v3.principled(PREFIX + g["name"] + "_Trim", roughness=float(tex.get("roughness", 0.86)), image=tcol,
                             normal=tnrm, specular=float(tex.get("specular", 0.25)))
    button_mat = None
    if spec.get("buttons") or spec.get("placket", {}).get("buttons"):
        bh = spec.get("button_srgb_hex", darker_hex(g["srgb_hex"], 0.55))
        button_mat = v3.principled(PREFIX + g["name"] + "_Buttons", color=hex_rgb(bh, linear=True), roughness=0.35,
                                   specular=0.5)
    obj.data.materials.append(trim_mat)
    obj.data.materials.append(button_mat or trim_mat)
    tree = BVHTree.FromObject(obj, bpy.context.evaluated_depsgraph_get())
    parts = []
    built_report = []
    hand_z = reg.bone["hand_l"][0].z

    def loop_role(lp):
        c = Vector(lp["centre"].tolist())
        if kind == "trousers":
            return "waist" if c.z > reg.bone["thigh_l"][0].z - 0.02 else "leg"
        ua = reg.bone["upperarm_l"][0]
        if abs(c.x) > abs(ua.x) * 0.8 and c.z < ua.z - 0.03:
            return "sleeve"
        if c.z > reg.neck.z - 0.12:
            return "neck"
        return "hem"
    roles = [loop_role(lp) for lp in loops]
    for lp, role in zip(loops, roles):
        cfg = None
        if role == "sleeve" and spec.get("cuff"):
            cfg = spec["cuff"]
        elif role == "hem" and spec.get("hem_band"):
            cfg = spec["hem_band"]
        elif role == "neck" and spec.get("neck_band"):
            cfg = spec["neck_band"]
        elif role == "waist" and spec.get("waistband"):
            cfg = spec["waistband"]
        elif role in ("neck", "hem") and spec.get("front_band"):
            cfg = spec["front_band"]
        if cfg is None and not (role == "neck" and spec.get("lapel")):
            continue
        pts, nrm, length = detail_mod.resample_loop(lp["pts"], lp["nrm"], 0.008)
        if role == "neck" and spec.get("lapel"):
            parts.append(lapel_band(g, spec["lapel"], pts, nrm, tree))
            built_report.append({"trim": "lapels_and_collar", "length_m": round(length, 3)})
            if cfg is None:
                continue
        parts.append(detail_mod.band(PREFIX + g["name"] + "_" + role, pts, nrm, float(cfg["width_m"]), tree,
                                     float(cfg.get("lift_m", 0.0016)), True, 1, overhang=float(cfg.get("overhang_m", 0.003))))
        built_report.append({"trim": role, "width_m": cfg["width_m"], "length_m": round(length, 3)})
    neck = reg.neck
    if spec.get("placket"):
        pk = spec["placket"]
        top = float(pk.get("top_z_m", neck.z - float(g.get("neckline", {}).get("depth_m", 0.05)) - 0.005))
        bottom = float(pk.get("bottom_z_m", (hem_z or 0.95) + 0.01))
        w = float(pk.get("width_m", 0.026))
        patch = detail_mod.front_patch(PREFIX + g["name"] + "_Placket", tree, -w / 2, w / 2, bottom, top,
                                       float(pk.get("lift_m", 0.0013)), 1, nx=2, nz=max(2, int((top - bottom) / 0.03)))
        if patch:
            parts.append(patch)
        n = int(pk.get("buttons", 0))
        for k in range(n):
            z = top - 0.02 - k * float(pk.get("button_spacing_m", 0.085))
            if z < bottom + 0.01:
                break
            b = detail_mod.button(PREFIX + g["name"] + f"_Button{k}", tree, 0.0, z, float(pk.get("button_radius_m", 0.0055)),
                                  float(pk.get("lift_m", 0.0013)), 2)
            if b:
                parts.append(b)
        built_report.append({"trim": "placket", "buttons": n})
    for k, pocket in enumerate(spec.get("pockets", [])):
        x, z = pocket["centre_m"]
        w, hgt = pocket["size_m"]
        if pocket.get("patch", True):
            pp = detail_mod.front_patch(PREFIX + g["name"] + f"_Pocket{k}", tree, x - w / 2, x + w / 2, z - hgt / 2,
                                        z + hgt / 2, 0.0013, 1)
            if pp:
                parts.append(pp)
        if pocket.get("flap_m"):
            fh = float(pocket["flap_m"])
            top_z = z + hgt / 2 + 0.004
            fp = detail_mod.front_patch(PREFIX + g["name"] + f"_Flap{k}", tree, x - w / 2 - 0.003, x + w / 2 + 0.003,
                                        top_z - fh, top_z, 0.0028, 1, nx=4, nz=2,
                                        taper=lambda u, v: 1.0 + 0.5 * (1 - v))
            if fp:
                parts.append(fp)
            if pocket.get("button"):
                b = detail_mod.button(PREFIX + g["name"] + f"_PocketButton{k}", tree, x, top_z - fh + 0.012, 0.0055,
                                      0.0045, 2)
                if b:
                    parts.append(b)
        built_report.append({"trim": "pocket", "centre_m": [x, z]})
    for k, (x, z) in enumerate(spec.get("buttons", [])):
        b = detail_mod.button(PREFIX + g["name"] + f"_FrontButton{k}", tree, float(x), float(z),
                              float(spec.get("button_radius_m", 0.0085)), float(spec.get("button_lift_m", 0.0025)), 2)
        if b:
            parts.append(b)
    if spec.get("buttons"):
        built_report.append({"trim": "buttons", "count": len(spec["buttons"])})
    uv_name = obj.data.uv_layers.active.name
    for part in parts:
        if not part.name.split("_")[-1].startswith(("Button", "FrontButton", "PocketButton")) and "Button" not in part.name:
            detail_mod.thicken(v3, part, float(spec.get("trim_thickness_m", 0.0012)))
        part.data.uv_layers.active.name = uv_name
        part.data.materials.clear()
        for m in obj.data.materials:
            part.data.materials.append(m)
    if parts:
        bpy.ops.object.select_all(action="DESELECT")
        for part in parts:
            part.select_set(True)
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.join()
    return {"folds": info, "inner_wall_faces": inner_faces, "trims": built_report, "loops": roles}


def lapel_band(g: dict, spec: dict, pts: np.ndarray, nrm: np.ndarray, tree) -> bpy.types.Object:
    """Blazer lapels and collar: one strip round the neckline, turned back onto the jacket.

    Width follows the opening: nothing at the top button, widening up the chest to
    `width_m`, a notch at the gorge, then `collar_m` round the back of the neck.
    """
    button = float(g["neckline"]["button_z_m"])
    neck_y = float(np.median(pts[:, 1]))
    top_front = pts[pts[:, 1] < neck_y][:, 2].max() if (pts[:, 1] < neck_y).any() else pts[:, 2].max()
    lapel_w = float(spec.get("width_m", 0.065))
    collar_w = float(spec.get("collar_m", 0.035))
    gorge = float(spec.get("gorge_drop_m", 0.07))
    notch_z = top_front - gorge
    widths = []
    for p in pts:
        z = p[2]
        front = p[1] < neck_y - 0.015
        if not front:
            widths.append(collar_w)
            continue
        rise = float(_smooth_s((z - button) / max(0.02, (notch_z - button) * 0.75)))
        w = lapel_w * rise
        if z > notch_z - 0.006:
            # The notch: the lapel steps in, then the collar carries on round the neck.
            t = float(_smooth_s((z - notch_z + 0.006) / 0.012))
            w = w * (1 - t) + (collar_w * 0.75) * t
        widths.append(max(0.0, w))
    return detail_mod.band(PREFIX + g["name"] + "_Lapels", pts, nrm, np.array(widths), tree,
                           float(spec.get("lift_m", 0.0028)), True, 1, roll=float(spec.get("roll_m", 0.003)),
                           overhang=0.004, rows=4)


def _smooth_s(x: float) -> float:
    x = min(1.0, max(0.0, x))
    return x * x * (3 - 2 * x)


def collar_band(body, reg: "BodyRegions", g: dict, under, mat) -> bpy.types.Object:
    """A shirt or polo collar: a band around the neck, open at the front, flaring outward."""
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    head, tail = reg.bone["neck_01"]
    base_z = head.z + float(g.get("base_z_offset_m", -0.01))
    height = float(g.get("height_m", 0.035))
    gap = math.radians(float(g.get("front_gap_deg", 28)))
    flare = float(g.get("flare", 0.15))
    rows = []
    n = 36
    angles = [gap + (math.tau - 2 * gap) * k / n for k in range(n + 1)]
    for lvl, dz in enumerate((0.0, height * 0.5, height)):
        z = base_z + dz
        t = (z - head.z) / max(1e-6, tail.z - head.z)
        axis = head.lerp(tail, t)
        row = []
        for a in angles:
            d = Vector((math.sin(a), -math.cos(a), 0.0))
            hit, _n, _i, _d = tree.ray_cast(Vector((axis.x, axis.y, z)), d, 0.09)
            if hit is None:
                hit = Vector((axis.x, axis.y, z)) + d * 0.06
            front = max(0.0, -d.y)
            # The collar points sit lower and further out at the front, like a turned collar.
            lift = -front * dz * 0.35
            row.append(hit + d * (under(hit) + 0.004 + dz * flare) + Vector((0, 0, lift)))
        rows.append(row)
    bm = bmesh.new()
    verts = [[bm.verts.new(p) for p in row] for row in rows]
    for r in range(len(rows) - 1):
        for k in range(n):
            bm.faces.new((verts[r][k], verts[r][k + 1], verts[r + 1][k + 1], verts[r + 1][k]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    mesh = bpy.data.meshes.new(PREFIX + g["name"])
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
    obj = bpy.data.objects.new(PREFIX + g["name"], mesh)
    bpy.context.scene.collection.objects.link(obj)
    v3.select_only(obj)
    sol = obj.modifiers.new("Thickness", "SOLIDIFY")
    sol.thickness = 0.0025
    sol.offset = 0.0
    bpy.ops.object.modifier_apply(modifier=sol.name)
    return obj


def straight_legs(obj, rig, hem_r: float) -> None:
    """build_naomi_v03's straight-cut legs: below mid-thigh, push each leg to a near-cylinder."""
    bones = rig.data.bones
    knee_z = Vector(bones["calf_l"].head_local).z
    for v in obj.data.vertices:
        p = v.co
        side = "l" if p.x > 0 else "r"
        thigh, calf = bones[f"thigh_{side}"], bones[f"calf_{side}"]
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
        if target_r > r > 1e-5:
            v.co = p + radial.normalized() * ((target_r - r) * blend)


# ------------------------------------------------------------------- accessories

def box(name: str, size: tuple, centre: Vector, mat, bevel: float = 0.0) -> bpy.types.Object:
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    bmesh.ops.scale(bm, vec=size, verts=bm.verts)
    if bevel:
        bmesh.ops.bevel(bm, geom=list(bm.edges), offset=bevel, segments=2, affect="EDGES")
    bmesh.ops.translate(bm, vec=centre, verts=bm.verts)
    mesh = bpy.data.meshes.new(name)
    bm.to_mesh(mesh)
    bm.free()
    mesh.materials.append(mat)
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    return obj


def surface_hit(target: bpy.types.Object, origin: Vector, direction: Vector):
    tree = BVHTree.FromObject(target, bpy.context.evaluated_depsgraph_get())
    hit, normal, _i, _d = tree.ray_cast(origin, direction.normalized())
    if hit is None:
        raise RuntimeError(f"Ray from {tuple(origin)} missed {target.name}")
    return hit, normal


def build_badge(rig, garment: bpy.types.Object, mats) -> bpy.types.Object:
    spec = CFG["badge"]
    o = Vector(spec.get("ray_origin", (0.085, -0.5, 1.255)))
    hit, normal = surface_hit(garment, o, Vector((0, 1, 0)))
    obj = box(PREFIX + "ID_Badge", (0.054, 0.003, 0.085), Vector((0, 0, 0)), mats["badge"])
    mesh = obj.data
    mesh.uv_layers.new(name="UVMap")
    for poly in mesh.polygons:
        for li in poly.loop_indices:
            p = mesh.vertices[mesh.loops[li].vertex_index].co
            mesh.uv_layers[0].data[li].uv = (p.x / 0.054 + 0.5, p.z / 0.085 + 0.5)
    obj.location = hit - Vector((0, 0.004, 0))
    obj.rotation_mode = "QUATERNION"
    obj.rotation_quaternion = Vector((0, -1, 0)).rotation_difference(-normal)
    bpy.context.view_layer.update()
    v3.select_only(obj)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    v3.rigid_weight(obj, "spine_03")
    v3.parent_to_rig(obj, rig)
    return obj


def build_belt_kit(rig, belt: bpy.types.Object, mats) -> list[bpy.types.Object]:
    """Radio on the right hip and a key reel on the left front, clipped to the belt."""
    spec = CFG["belt_kit"]
    zc = float(spec["z_m"])
    out = []
    mat = mats[spec["material"]]
    hit, _n = surface_hit(belt, Vector((-0.5, 0.0, zc)), Vector((1, 0, 0)))
    radio = box(PREFIX + "Radio", (0.03, 0.058, 0.105), hit + Vector((-0.017, 0.0, -0.035)), mat, 0.004)
    antenna = box(PREFIX + "Radio_Antenna", (0.009, 0.009, 0.045), hit + Vector((-0.017, 0.017, 0.038)), mat, 0.002)
    hit2, _n2 = surface_hit(belt, Vector((0.11, -0.5, zc)), Vector((0, 1, 0)))
    reel = box(PREFIX + "Key_Reel", (0.034, 0.012, 0.034), hit2 + Vector((0.0, -0.007, -0.01)),
               mats[spec["reel_material"]], 0.008)
    keys = box(PREFIX + "Keys", (0.022, 0.006, 0.05), hit2 + Vector((0.004, -0.012, -0.05)),
               mats[spec["keys_material"]], 0.002)
    for obj in (radio, antenna, reel, keys):
        v3.rigid_weight(obj, "pelvis")
        v3.parent_to_rig(obj, rig)
        out.append(obj)
    return out


def curve_object(name: str, polylines: list[list[Vector]], radius: float, mat, closed=None,
                 radii: list[list[float]] | None = None, resolution: int = 2) -> bpy.types.Object:
    cu = bpy.data.curves.new(name, "CURVE")
    cu.dimensions = "3D"
    cu.bevel_depth = radius
    cu.bevel_resolution = resolution
    cu.use_fill_caps = True
    for k, pts in enumerate(polylines):
        sp = cu.splines.new("POLY")
        sp.points.add(len(pts) - 1)
        for j, p in enumerate(pts):
            sp.points[j].co = (*p, 1.0)
            if radii:
                sp.points[j].radius = radii[k][j]
        sp.use_cyclic_u = bool(closed and closed[k])
    obj = bpy.data.objects.new(name, cu)
    bpy.context.scene.collection.objects.link(obj)
    v3.select_only(obj)
    bpy.ops.object.convert(target="MESH")
    obj = bpy.context.view_layer.objects.active
    obj.data.materials.clear()
    obj.data.materials.append(mat)
    for poly in obj.data.polygons:
        poly.use_smooth = True
    return obj


def build_glasses(body, rig, eye_data, mats) -> bpy.types.Object:
    spec = CFG["glasses"]
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    rx, rz = spec["lens_half_m"]
    forward = float(spec.get("forward_m", 0.021))
    lift = float(spec.get("lift_m", -0.002))
    lines, closed = [], []
    rims = {}
    for idx in (0, 2):
        e = Vector(eye_data[idx])
        side = 1 if e.x > 0 else -1
        c = Vector((e.x + side * 0.002, e.y - eye_data[idx + 1] - forward, e.z + lift))
        ring = []
        for k in range(28):
            a = math.tau * k / 28
            # Soft rectangle: superellipse rim, slightly flatter at the top.
            cx, cz = math.cos(a), math.sin(a)
            px = math.copysign(abs(cx) ** 0.6, cx) * rx
            pz = math.copysign(abs(cz) ** 0.7, cz) * rz * (0.95 if cz > 0 else 1.0)
            # The outer edges wrap back slightly toward the temples.
            ring.append(c + Vector((px, 0.003 * max(0.0, px * side / rx) ** 2, pz)))
        lines.append(ring)
        closed.append(True)
        rims[side] = (c, ring)
    cl, cr = rims[1][0], rims[-1][0]
    inner_l = cl + Vector((-rx * 0.95, 0, rz * 0.35))
    inner_r = cr + Vector((rx * 0.95, 0, rz * 0.35))
    bridge = [inner_l.lerp(inner_r, t) + Vector((0, -0.002 * math.sin(math.pi * t), 0.004 * math.sin(math.pi * t)))
              for t in np.linspace(0, 1, 9)]
    lines.append(bridge)
    closed.append(False)
    for side in (1, -1):
        c = rims[side][0]
        start = c + Vector((side * rx * 1.02, 0.003, rz * 0.45))
        hit, _n, _i, _d = tree.ray_cast(Vector((side * 0.3, c.y + 0.085, start.z)), Vector((-side, 0, 0)))
        if hit is None:
            raise RuntimeError("Could not find the side of the head for the glasses.")
        ear = hit + Vector((side * 0.004, 0, 0))
        pts = []
        for t in np.linspace(0, 1, 10):
            p = start.lerp(ear, t)
            loc, nrm, _i, dist = tree.find_nearest(p)
            if loc is not None and (p - loc).dot(nrm) < 0.004:
                p = loc + nrm * 0.004
            pts.append(p)
        pts.append(ear + Vector((0, 0.012, -0.012)))
        pts.append(ear + Vector((0, 0.018, -0.03)))
        lines.append(pts)
        closed.append(False)
    obj = curve_object(PREFIX + "Reading_Glasses", lines, float(spec.get("wire_radius_m", 0.0013)),
                       mats[spec["material"]], closed=closed)
    if spec.get("lens"):
        # Thin, faintly tinted lenses (alpha blend) inside the rims, joined to the frame.
        lmat = detail_mod.lens_material(PREFIX + "Glasses_Lens", tuple(spec["lens"].get("tint_srgb", (0.93, 0.95, 1.0))),
                                        float(spec["lens"].get("alpha", 0.12)))
        lenses = [detail_mod.lens(PREFIX + f"Lens_{side}", c, ring, lmat) for side, (c, ring) in rims.items()]
        obj.data.materials.append(lmat)
        bpy.ops.object.select_all(action="DESELECT")
        for ln in lenses:
            ln.data.materials.clear()
            for m in obj.data.materials:
                ln.data.materials.append(m)
            for poly in ln.data.polygons:
                poly.material_index = 1
            if not ln.data.uv_layers:
                ln.data.uv_layers.new(name="UVMap")
            ln.select_set(True)
        obj.select_set(True)
        bpy.context.view_layer.objects.active = obj
        bpy.ops.object.join()
    v3.rigid_weight(obj, "head")
    v3.parent_to_rig(obj, rig)
    return obj


# --------------------------------------------------------------------------- hair

def head_frame(body):
    co = np.array([v.co[:] for v in body.data.vertices])
    weights, names = v3.vertex_weights(body)
    head_w = weights[:, names.index("head")]
    pts = co[head_w > 0.5]
    centre = Vector(((pts[:, 0].min() + pts[:, 0].max()) / 2, (pts[:, 1].min() + pts[:, 1].max()) / 2 + 0.01,
                     pts[:, 2].max() - 0.105))
    return centre, head_w, float(pts[:, 2].max())


def hairline_mask(body, centre: Vector, head_w: np.ndarray, spec: dict) -> np.ndarray:
    polys = body.data.polygons
    head_faces = np.array([head_w[list(f.vertices)].mean() > 0.45 for f in polys])
    centres = np.array([f.center[:] for f in polys])
    rel = centres - np.array(centre[:])
    ang = np.degrees(np.arctan2(rel[:, 0], -rel[:, 1]))
    front, nape = float(spec["front_z_m"]), float(spec["nape_z_m"])
    t = np.clip((np.abs(ang) - float(spec.get("temple_deg", 40))) / float(spec.get("drop_deg", 110)), 0, 1)
    line = front + (nape - front) * t * t * (3 - 2 * t)
    ears = (np.abs(ang) > 68) & (np.abs(ang) < 122) & (rel[:, 2] < float(spec.get("ear_top_z_m", 0.02)))
    return head_faces & (rel[:, 2] > line) & ~ears


def spherical_uvs(obj, centre: Vector, scale: float = 3.0) -> None:
    mesh = obj.data
    if not mesh.uv_layers:
        mesh.uv_layers.new(name="UVMap")
    uv = mesh.uv_layers.active.data
    for poly in mesh.polygons:
        us = []
        for li in poly.loop_indices:
            p = mesh.vertices[mesh.loops[li].vertex_index].co - centre
            az = math.atan2(p.x, -p.y)
            el = math.atan2(p.z, math.hypot(p.x, p.y))
            us.append((li, az, el))
        # Keep each face on one side of the seam at the back.
        if max(a for _l, a, _e in us) - min(a for _l, a, _e in us) > math.pi:
            us = [(li, a + math.tau if a < 0 else a, e) for li, a, e in us]
        for li, a, e in us:
            uv[li].uv = (a / math.tau * scale * 4, e / math.pi * scale)


def scalp_shell(name: str, body, mask: np.ndarray, offset_fn, mat) -> bpy.types.Object:
    """Copy the scalp faces, subdivide once and lift each point off the scalp.

    Unlike shell_from_faces this does not relax the open edge, which on the coarse
    scalp pulls the hairline up off the forehead and temples.
    """
    mesh = body.data.copy()
    obj = bpy.data.objects.new(name, mesh)
    bpy.context.scene.collection.objects.link(obj)
    obj.modifiers.clear()
    bm = bmesh.new()
    bm.from_mesh(mesh)
    bm.faces.ensure_lookup_table()
    bmesh.ops.delete(bm, geom=[f for f in bm.faces if not mask[f.index]], context="FACES")
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if not v.link_faces], context="VERTS")
    bm.to_mesh(mesh)
    bm.free()
    for g in list(obj.vertex_groups):
        obj.vertex_groups.remove(g)
    v3.select_only(obj)
    sub = obj.modifiers.new("Subdiv", "SUBSURF")
    sub.levels = 1
    sub.boundary_smooth = "PRESERVE_CORNERS"
    bpy.ops.object.modifier_apply(modifier=sub.name)
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    # Smooth the stair-stepped face edge along the scalp; reprojection keeps it on the head.
    bm = bmesh.new()
    bm.from_mesh(mesh)
    for _ in range(8):
        moves = {}
        for v in bm.verts:
            if v.is_boundary:
                nbrs = [e.other_vert(v) for e in v.link_edges if e.is_boundary]
                if len(nbrs) == 2:
                    moves[v] = (nbrs[0].co + nbrs[1].co) / 2
        for v, target in moves.items():
            loc, _n, _i, _d = tree.find_nearest(v.co.lerp(target, 0.5))
            v.co = loc
    edge = [v.co.copy() for v in bm.verts if v.is_boundary]
    bm.to_mesh(mesh)
    bm.free()
    edge_tree = KDTree(len(edge))
    for j, co in enumerate(edge):
        edge_tree.insert(co, j)
    edge_tree.balance()
    for v in mesh.vertices:
        loc, nrm, _i, _d = tree.find_nearest(v.co)
        if loc is not None:
            v.co = loc + nrm * offset_fn(loc, edge_tree.find(loc)[2])
    mesh.materials.clear()
    mesh.materials.append(mat)
    for poly in mesh.polygons:
        poly.use_smooth = True
    return obj


def paint_hairline(body, cap, image: bpy.types.Image, spec: dict) -> int:
    """Paint hair colour on the scalp under the cap and a soft fringe just outside it.

    The cap ends in a hard edge; a few millimetres of hair-coloured, strand-broken
    shading on the skin beyond it reads as a hairline instead of a helmet rim.
    """
    size = image.size[0]
    pos, valid = anim.bake_positions(body, size, 0)
    co = np.array([v.co[:] for v in cap.data.vertices])
    lo, hi = co.min(0) - 0.012, co.max(0) + 0.012
    flat = pos.reshape(-1, 3)
    idx = np.flatnonzero(valid.ravel() & np.all((flat > lo) & (flat < hi), axis=1))
    bm = bmesh.new()
    bm.from_mesh(cap.data)
    boundary = np.array([v.is_boundary for v in bm.verts])
    bm.free()
    tree = KDTree(len(co))
    for i, c in enumerate(co):
        tree.insert(c, i)
    tree.balance()
    rim = np.flatnonzero(boundary)
    rim_tree = KDTree(len(rim))
    for j, i in enumerate(rim):
        rim_tree.insert(co[i], j)
    rim_tree.balance()
    reach = float(spec.get("fringe_m", 0.005))
    hair = np.array(hex_rgb(spec["srgb_hex"]))
    rng = np.random.default_rng(5)
    strands = rng.random(4096)
    px = np.empty(size * size * 4, dtype=np.float32)
    image.pixels.foreach_get(px)
    px = px.reshape(-1, 4)
    painted = 0
    for t in idx:
        p = flat[t]
        _c, _i, d_all = tree.find(p)
        _c, _j, d_rim = rim_tree.find(p)
        if d_all > 0.015:
            continue
        if d_all + 0.0008 < d_rim:
            a = 1.0  # under the cap: no skin shows between strands
        elif d_rim < reach + 0.0015:
            strand = strands[int(p[0] * 4000 + p[2] * 2500) % 4096]
            a = (1.0 - max(0.0, d_rim - 0.0015) / reach) * (0.25 + 0.55 * strand)
        else:
            continue
        px[t, :3] = px[t, :3] * (1 - a) + hair * a
        painted += 1
    image.pixels.foreach_set(px.ravel())
    image.pack()
    return painted


def hair_card_config(spec: dict) -> dict:
    cfg = dict(cards_mod.STYLE_DEFAULTS[spec["style"]])
    cfg.update({"seed": 3, "atlas_size": 1024})
    cfg.update(spec.get("cards") or {})
    return cfg


def build_hair_cards(body, rig, mats) -> list[bpy.types.Object]:
    """v02 hair: thin scalp base, layered cards along the style's flow, bun or tail of cards."""
    spec = CFG["hair"]
    cfg = hair_card_config(spec)
    rng = np.random.default_rng(int(cfg["seed"]))
    centre, head_w, top_z = head_frame(body)
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    mask = hairline_mask(body, centre, head_w, spec)
    vol_top = float(spec.get("volume_top_m", 0.006))
    vol_side = float(spec.get("volume_side_m", 0.003))
    taper = float(spec.get("hairline_taper_m", 0.02))
    base_off = float(cfg["base_offset_m"])

    def offset(p: Vector, edge_distance: float) -> float:
        t = min(1.0, edge_distance / taper)
        edge = t * t * (3 - 2 * t)
        up = min(1.0, max(0.0, (p.z - centre.z) / (top_z - centre.z)))
        return 0.0004 + edge * (base_off - 0.0004 + 0.25 * (vol_side + (vol_top - vol_side) * up))
    cap = scalp_shell(PREFIX + "Hair", body, mask, offset, mats["hair"])
    spherical_uvs(cap, centre, 1.0)
    # Paint the skin under and just beyond the base in the strands' average colour.
    mean = mats["hair_cards"].node_tree.nodes["Image Texture"].image.get("mean_srgb")
    paint_spec = dict(spec, srgb_hex="#" + "".join(f"{int(round(c * 0.92 * 255)):02x}" for c in mean)) if mean else spec
    print("  hairline texels painted:", paint_hairline(body, cap, mats["skin"].node_tree.nodes["Image Texture"].image,
                                                      paint_spec))
    style = spec["style"]
    tie = None
    out = None
    if style in ("chignon", "ponytail"):
        d = Vector(spec.get("tie_direction", (0.0, 1.0, -0.42))).normalized()
        hit, normal, _i, _dd = tree.ray_cast(centre + d * 0.3, -d)
        tie = hit + normal * (vol_side + 0.002)
        out = Vector((normal.x, normal.y, 0)).normalized()
    cards = cards_mod.scalp_cards(body, cap, centre, top_z, spec, cfg, tie, mask, rng)
    objs = [cap]
    extra_cards = []
    tail_obj = []
    if style == "chignon":
        r = spec["bun_radii_m"]
        bun_centre = tie + out * (r[1] * 0.55)
        bm = bmesh.new()
        bmesh.ops.create_uvsphere(bm, u_segments=14, v_segments=10, radius=1.0)
        for v in bm.verts:
            v.co = Vector((v.co.x * r[0], v.co.y * r[1], v.co.z * r[2])) * 0.9
        bmesh.ops.translate(bm, vec=bun_centre, verts=bm.verts)
        mesh = bpy.data.meshes.new(PREFIX + "Hair_Chignon")
        bm.to_mesh(mesh)
        bm.free()
        mesh.materials.append(mats["hair"])
        bun = bpy.data.objects.new(PREFIX + "Hair_Chignon", mesh)
        bpy.context.scene.collection.objects.link(bun)
        for poly in mesh.polygons:
            poly.use_smooth = True
        spherical_uvs(bun, bun_centre, 1.0)
        objs.append(bun)
        # The bun's local axes: x across the head, y outward, z up.
        extra_cards = cards_mod.bun_cards(bun_centre, out, (r[0] * 0.95, r[1] * 0.95, r[2] * 0.95),
                                          int(cfg["bun_cards"]), rng)
    elif style == "ponytail":
        length = float(spec["tail_length_m"])
        r0, r1 = spec["tail_radius_m"]
        pts, radii = [], []
        n = 14
        for k in range(n):
            t = k / (n - 1)
            # Gathered just off the head, arcing back then falling.
            p = tie + out * (r0 * 0.7 + 0.022 * math.sin(math.pi * min(1.0, t * 1.6) * 0.5)) + \
                Vector((0, 0, -length * t))
            loc, nrm, _i, _dd = tree.find_nearest(p)
            rad = r0 + (r1 - r0) * t ** 0.8
            if loc is not None and (p - loc).dot(nrm) < rad + 0.004:
                p = loc + nrm * (rad + 0.004)
            pts.append(p)
            radii.append(rad)
        core = curve_object(PREFIX + "Hair_Ponytail", [pts], r0 * 0.8,
                            mats["hair"], radii=[[0.6 if k == 0 else radii[k] / r0 for k in range(n)]], resolution=2)
        spherical_uvs(core, tie, 1.0)
        objs.append(core)
        tail_obj.append(core)
        extra_cards = cards_mod.tail_cards(pts, radii, int(cfg["tail_cards"]), rng)
        # The elastic wraps round the tail, just below where the cards gather.
        axis = (pts[2] - pts[0]).normalized()
        e1 = (Vector((1, 0, 0)) - axis * axis.x).normalized()
        e2 = axis.cross(e1).normalized()
        ring_c = pts[0] + axis * 0.012
        ring_r = (r0 + (r1 - r0) * (0.012 / length) ** 0.8) * 1.12
        band = curve_object(PREFIX + "Hair_Tie", [[ring_c + (e1 * math.cos(a) + e2 * math.sin(a)) * ring_r
                                                   for a in np.linspace(0, math.tau, 17)[:-1]]],
                            0.0026, mats["hair_tie"], closed=[True])
        objs.append(band)
    card_obj = cards_mod.cards_object(PREFIX + "Hair_Cards", cards, mats["hair_cards"])
    objs.append(card_obj)
    if extra_cards:
        name = PREFIX + ("Hair_Bun_Cards" if style == "chignon" else "Hair_Tail_Cards")
        extra = cards_mod.cards_object(name, extra_cards, mats["hair_cards"])
        objs.append(extra)
        if style == "ponytail":
            tail_obj.append(extra)
    print(f"  hair cards: {len(cards)} scalp + {len(extra_cards)} {style} cards")
    for obj in objs:
        v3.rigid_weight(obj, "head")
        v3.parent_to_rig(obj, rig)
    for tail in tail_obj:
        # The tail rests on the upper back: blend its lower half toward the chest bone.
        zs = [v.co.z for v in tail.data.vertices]
        z_top, z_bot = tie.z, min(zs)
        chest = tail.vertex_groups.new(name="spine_03")
        head = tail.vertex_groups["head"]
        for v in tail.data.vertices:
            t = (z_top - v.co.z) / max(1e-6, z_top - z_bot)
            w = 0.6 * max(0.0, min(1.0, (t - 0.3) / 0.7))
            head.add([v.index], 1.0 - w, "REPLACE")
            chest.add([v.index], w, "REPLACE")
    return objs


def build_hair(body, rig, mats) -> list[bpy.types.Object]:
    spec = CFG["hair"]
    if spec.get("cards") is not None:
        return build_hair_cards(body, rig, mats)
    centre, head_w, top_z = head_frame(body)
    tree = BVHTree.FromObject(body, bpy.context.evaluated_depsgraph_get())
    mask = hairline_mask(body, centre, head_w, spec)
    vol_top = float(spec.get("volume_top_m", 0.006))
    vol_side = float(spec.get("volume_side_m", 0.003))
    taper = float(spec.get("hairline_taper_m", 0.02))

    def offset(p: Vector, edge_distance: float) -> float:
        # Thin at the hairline, fuller over the crown.
        t = min(1.0, edge_distance / taper)
        edge = t * t * (3 - 2 * t)
        up = min(1.0, max(0.0, (p.z - centre.z) / (top_z - centre.z)))
        return 0.0012 + edge * (vol_side + (vol_top - vol_side) * up)
    cap = scalp_shell(PREFIX + "Hair", body, mask, offset, mats["hair"])
    spherical_uvs(cap, centre, float(spec.get("uv_scale", 2.0)))
    print("  hairline texels painted:", paint_hairline(body, cap, mats["skin"].node_tree.nodes["Image Texture"].image, spec))
    objs = [cap]
    style = spec["style"]
    if style in ("chignon", "ponytail"):
        d = Vector(spec.get("tie_direction", (0.0, 1.0, -0.42))).normalized()
        hit, normal, _i, _dd = tree.ray_cast(centre + d * 0.3, -d)
        tie = hit + normal * (vol_side + 0.002)
        if style == "chignon":
            r = spec["bun_radii_m"]
            bm = bmesh.new()
            bmesh.ops.create_uvsphere(bm, u_segments=18, v_segments=12, radius=1.0)
            for v in bm.verts:
                # Rolled chignon: horizontal ridges from the twist.
                ridge = 1.0 + 0.06 * math.sin(v.co.z * 9.0) + 0.03 * math.sin(math.atan2(v.co.y, v.co.x) * 3)
                v.co = Vector((v.co.x * r[0], v.co.y * r[1], v.co.z * r[2])) * ridge
            out = Vector((normal.x, normal.y, 0)).normalized()
            bmesh.ops.translate(bm, vec=tie + out * (r[1] * 0.55), verts=bm.verts)
            mesh = bpy.data.meshes.new(PREFIX + "Hair_Chignon")
            bm.to_mesh(mesh)
            bm.free()
            mesh.materials.append(mats["hair"])
            bun = bpy.data.objects.new(PREFIX + "Hair_Chignon", mesh)
            bpy.context.scene.collection.objects.link(bun)
            for poly in mesh.polygons:
                poly.use_smooth = True
            spherical_uvs(bun, tie + out * (r[1] * 0.55), 2.0)
            objs.append(bun)
        else:
            length = float(spec["tail_length_m"])
            r0, r1 = spec["tail_radius_m"]
            pts, radii = [], []
            n = 14
            for k in range(n):
                t = k / (n - 1)
                p = tie + Vector((0, 0.012 * math.sin(math.pi * t * 0.8), -length * t))
                loc, nrm, _i, _dd = tree.find_nearest(p)
                rad = r0 + (r1 - r0) * t ** 0.8
                if loc is not None and (p - loc).dot(nrm) < rad + 0.004:
                    p = loc + nrm * (rad + 0.004)
                pts.append(p)
                radii.append(1.0 if k == 0 else rad / r0)
            tail = curve_object(PREFIX + "Hair_Ponytail", [pts], r0, mats["hair"], radii=[radii], resolution=3)
            m = tail.data
            m.uv_layers.new(name="UVMap")
            for poly in m.polygons:
                for li in poly.loop_indices:
                    p = m.vertices[m.loops[li].vertex_index].co - tie
                    m.uv_layers[0].data[li].uv = (math.atan2(p.x, p.y - 0.02) / math.tau * 3, p.z * 4)
            objs.append(tail)
            band = curve_object(PREFIX + "Hair_Tie", [[tie + Vector((math.cos(a) * r0 * 0.75, 0.004,
                                                                     math.sin(a) * r0 * 0.75))
                                                       for a in np.linspace(0, math.tau, 13)[:-1]]],
                                0.0025, mats["hair"], closed=[True])
            objs.append(band)
    for obj in objs:
        v3.rigid_weight(obj, "head")
        v3.parent_to_rig(obj, rig)
    if style == "ponytail":
        # The tail rests on the upper back: blend its lower half toward the chest bone.
        tail = objs[1]
        zs = [v.co.z for v in tail.data.vertices]
        z_top, z_bot = max(zs), min(zs)
        chest = tail.vertex_groups.new(name="spine_03")
        head = tail.vertex_groups["head"]
        for v in tail.data.vertices:
            t = (z_top - v.co.z) / max(1e-6, z_top - z_bot)
            w = 0.6 * max(0.0, (t - 0.3) / 0.7)
            head.add([v.index], 1.0 - w, "REPLACE")
            chest.add([v.index], w, "REPLACE")
    return objs


# ------------------------------------------------------------------ review/render

def render_review(meshes, height: float, centre: Vector, out_dir: Path, version: str) -> list[Path]:
    scene = bpy.context.scene
    scene.render.engine = "CYCLES"
    scene.cycles.device = "CPU"
    scene.cycles.samples = 24
    scene.cycles.use_denoising = True
    scene.cycles.seed = 3
    scene.render.resolution_x = 600
    scene.render.resolution_y = 800
    scene.render.resolution_percentage = 100
    scene.view_settings.view_transform = "AgX"
    world = scene.world or bpy.data.worlds.new("World")
    scene.world = world
    world.use_nodes = True
    world.node_tree.nodes["Background"].inputs["Color"].default_value = (0.16, 0.17, 0.18, 1)
    world.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.6
    k = height / NOMINAL_HEIGHT_M
    lights = []
    for name, loc, power, size in (("Key", (-2.4, -3.2, 3.2), 380.0, 2.5), ("Fill", (2.8, -2.2, 2.0), 140.0, 3.0),
                                   ("Rim", (0.6, 2.8, 3.0), 260.0, 1.8)):
        ld = bpy.data.lights.new(PREFIX + "Review_" + name, "AREA")
        ld.energy = power
        ld.size = size
        lo = bpy.data.objects.new(PREFIX + "Review_" + name, ld)
        scene.collection.objects.link(lo)
        lo.location = loc
        v3.aim(lo, Vector((0, 0, 1.1 * k)))
        lights.append(lo)
    cam_data = bpy.data.cameras.new(PREFIX + "Review_Camera")
    cam = bpy.data.objects.new(PREFIX + "Review_Camera", cam_data)
    scene.collection.objects.link(cam)
    scene.camera = cam
    face_t = Vector((0, centre.y - 0.04, centre.z + 0.0))
    views = {
        "front": ((0, -4.6, 1.0 * k), (0, 0, 0.86 * k), 70),
        "three_quarter": ((-2.6, -3.8, 1.2 * k), (0, 0, 0.88 * k), 70),
        "right": ((-4.6, 0, 1.0 * k), (0, 0, 0.86 * k), 70),
        "back": ((0, 4.6, 1.0 * k), (0, 0, 0.86 * k), 70),
        "face": (tuple(face_t + Vector((-0.34, -0.95, 0.06))), tuple(face_t), 85),
        "face_side": (tuple(face_t + Vector((-1.0, -0.12, 0.04))), tuple(face_t + Vector((0, 0.03, 0))), 85),
    }
    out_dir.mkdir(parents=True, exist_ok=True)
    paths = []
    tmp_dir = Path(bpy.app.tempdir or "/tmp")
    for view, (loc, target, lens) in views.items():
        cam.location = loc
        cam_data.lens = lens
        v3.aim(cam, Vector(target))
        path = tmp_dir / f"{CFG['character']['file_stem']}_{version}_{view}.png"
        scene.render.filepath = str(path)
        bpy.ops.render.render(write_still=True)
        paths.append(path)
    sheet = out_dir / f"{CFG['character']['file_stem']}_{version}_sheet.png"
    anim.contact_sheet(paths, sheet)
    # The camera and lights stay in the .blend: refine_character.py renders with them.
    return [sheet]


# ---------------------------------------------------------------- next profiles

def write_profiles(metrics: dict, names: dict, scale_final: float, garments: dict) -> list[str]:
    ch = CFG["character"]
    cid, stem, ver = ch["character_id"], ch["file_stem"], ch["asset_version"]
    tpl = json.loads((ROOT / "tools/character_animation/profiles/staff_bennett_v06.json").read_text())
    face = dict(tpl["face"])
    face["mouth_line_z_below_eyes_m"] = round(metrics["mouth_line_z_below_eyes_m"] * scale_final, 4)
    face["mouth_corner_x_of_eye_x"] = metrics["mouth_corner_x_of_eye_x"]
    face["jaw_pivot_offset_from_eye_mid_m"] = [round(c * scale_final, 4) for c in face["jaw_pivot_offset_from_eye_mid_m"]]
    face["lashes"] = dict(face["lashes"], material=PREFIX + "Lash", color_srgb_hex=CFG["face"]["lash_srgb_hex"],
                          length_m=CFG["face"].get("lash_length_m", 0.0045))
    brows = dict(face["brows"], color_srgb_hex=CFG["face"]["brow_srgb_hex"])
    brows.update(CFG["face"].get("brows", {}))
    for k in ("inner_m", "outer_m", "height_m"):
        brows[k] = round(brows[k] * scale_final, 4)
    face["brows"] = brows
    base = f"{stem}_{ver}"
    animated = {
        "character_id": cid, "display_name": ch["name"], "version": f"{ver}_anim",
        "production_status": ch["production_status"],
        "source_blend": f"{BUILD_REL}/{base}.blend",
        "objects": names, "forward": [0.0, -1.0, 0.0], "up": [0.0, 0.0, 1.0],
        "bones": tpl["bones"], "eye_bones": tpl["eye_bones"], "face": face, "skin": tpl["skin"],
        "clothing_tidy": {"shoes": garments["shoes"]},
        "outputs": {
            "blend": f"{BUILD_REL}/{base}_anim.blend",
            "glb": f"{BUILD_REL}/{base}_anim.glb",
            "renders": "assets/renders/characters",
            "manifest": f"{BUILD_REL}/{cid}_character_manifest_{ver}_anim.json",
            "report": f"tools/character_animation/reports/{cid}_{ver}_anim_rig_report.json",
        },
    }
    face_cfg = {
        "character_id": cid, "display_name": ch["name"], "version": f"{ver}_face",
        "production_status": ch["production_status"],
        "source_blend": animated["outputs"]["blend"],
        "objects": names,
        "face_source": {"blend": "assets/blender/characters/Naomi_Bennett_v07.blend",
                        "body": "Naomi_Bennett_Body",
                        "base_blend": "assets/blender/characters/Naomi_Bennett_Base_v02.blend",
                        "base_body": "Naomi_Bennett_Body"},
        "target_base": {"blend": CFG["source"]["blend"], "body": CFG["source"]["body"],
                        "cast_config": f"tools/blender/characters/cast/{cid}.json"},
        "outputs": {
            "blend": f"{BUILD_REL}/{base}_face.blend",
            "glb": f"{BUILD_REL}/{base}_face.glb",
            "report": f"tools/character_animation/reports/{cid}_{ver}_face_report.json",
        },
    }
    lash_material = PREFIX + "Lash"
    final = final_version()
    approval = ch.get("approval")
    if approval:
        for data in (animated, face_cfg):
            data["approved"] = bool(approval.get("approved"))
            data["approval"] = approval
    refine = {
        "character_id": cid, "display_name": ch["name"], "version": final,
        "production_status": ch["production_status"],
        "source_blend": face_cfg["outputs"]["blend"], "objects": names,
        "refine": {
            "lashes": {"lash_material": lash_material, "shapes": ["blink", "blink_L", "blink_R"],
                       "clearance_m": 0.0006, "smoothing_iterations": 4, "smoothing_factor": 0.5,
                       "push_out": False},
            "trousers": {"object": garments["trousers"], "cut_m": round(0.17 * scale_final, 4),
                         "hem_m": round(0.085 * scale_final, 4), "flare": 0.03, "inner_wall_tuck_m": 0.003,
                         "fold_depth_m": 0.006, "fold_height_m": 0.012},
            "shoes": {"object": garments["shoes"], "iterations": 30, "factor": 0.5, "keep_sole_below_m": 0.004},
        },
        "expected": {"clips": [], "morph_targets": 32},
        "outputs": {
            "blend": f"assets/blender/characters/{stem}_{final}.blend",
            "glb": f"assets/exports/characters/{stem}_{final}.glb",
            "renders": "assets/renders/characters",
            "manifest": f"assets/asset_manifest/{cid}_character_manifest_{final}.json",
            "report": f"tools/character_animation/reports/{cid}_{final}_refine_report.json",
        },
        "known_limitations": CFG.get("known_limitations", []),
    }
    if approval:
        refine["approved"] = bool(approval.get("approved"))
        refine["approval"] = approval
    if CFG.get("clip_adjustments"):
        animated["clip_adjustments"] = CFG["clip_adjustments"]
    if CFG.get("seated"):
        # The hem rebuild assumes straight vertical legs.
        del refine["refine"]["trousers"]
    lib = json.loads((ROOT / "tools/character_animation/clip_library.json").read_text())
    refine["expected"]["clips"] = [c["name"] for c in lib["clips"]]
    paths = []
    for suffix, data in ((f"{ver}_anim", animated), (f"{ver}_face", face_cfg), (final, refine)):
        p = ROOT / f"tools/character_animation/profiles/{cid}_{suffix}.json"
        p.write_text(json.dumps(data, indent=2) + "\n", encoding="utf-8")
        paths.append(str(p.relative_to(ROOT)))
    return paths


def final_version() -> str:
    """v01 shipped as `v01_draft`; later versions are named by their asset version alone."""
    ver = CFG["character"]["asset_version"]
    return CFG["character"].get("final_version", "v01_draft" if ver == "v01" else ver)


# --------------------------------------------------------------------------- main

def main() -> None:
    global CFG, PREFIX
    args = parse_args()
    config_path = ROOT / args.config
    CFG = json.loads(config_path.read_text(encoding="utf-8"))
    PREFIX = CFG["character"]["prefix"]
    v3.CONFIG = {**v3.CONFIG, **{k: CFG[k] for k in ("pose", "eyes") if k in CFG}}
    v3.PREFIX = PREFIX
    ch = CFG["character"]
    stem, ver = ch["file_stem"], ch["asset_version"]
    # Intermediate stages go to the git-ignored build folder; only the finished draft
    # (refine_character.py) is committed. Each stage is reproducible from these scripts.
    BUILD_DIR.mkdir(parents=True, exist_ok=True)
    (BUILD_DIR / ".gdignore").touch()
    blend_out = BUILD_DIR / f"{stem}_{ver}.blend"
    glb_out = BUILD_DIR / f"{stem}_{ver}.glb"
    manifest_out = BUILD_DIR / f"{ch['character_id']}_character_manifest_{ver}.json"
    v3.GLB_OUT = glb_out

    body, rig, eye_data, info = load_body()
    dz = v3.align_rig_to_mesh(body, rig)
    v3.relax_pose(body, rig)
    if CFG.get("seated"):
        seat_pose(body, rig, CFG["seated"])
    metrics = face_metrics(body, eye_data)
    weight_source = body.copy()
    weight_source.data = body.data.copy()
    bpy.context.scene.collection.objects.link(weight_source)
    skin_image = bake_skin(body, eye_data)
    mats = build_materials(skin_image)
    body.data.materials.append(mats["skin"])
    for poly in body.data.polygons:
        poly.use_smooth = True
    clothing, cloth_info = build_clothing(body, rig, mats)
    by_name = {o.name[len(PREFIX):]: o for o in clothing}
    kinds = {g["kind"]: g["name"] for g in CFG["garments"]}
    for obj in clothing:
        if not obj.get("cast_detail"):
            v3.project_fabric_uvs(obj)
        v3.copy_weights_from(obj, weight_source)
    extras = []
    if CFG.get("badge"):
        extras.append(build_badge(rig, by_name[CFG["badge"]["on"]], mats))
    if CFG.get("belt_kit"):
        extras.extend(build_belt_kit(rig, by_name[kinds["belt"]], mats))
    eyes = v3.build_eyes(rig, eye_data, mats)
    if CFG.get("glasses"):
        extras.append(build_glasses(body, rig, eye_data, mats))
    hair = build_hair(body, rig, mats)
    head_centre = head_frame(body)[0]
    bpy.data.objects.remove(weight_source, do_unlink=True)
    meshes = [body, *clothing, *extras, *eyes, *hair]
    for obj in meshes:
        v3.limit_influences(obj)
    bone_names = {b.name for b in rig.data.bones}
    for obj in meshes:
        for g in list(obj.vertex_groups):
            if g.name not in bone_names:
                obj.vertex_groups.remove(g)
    body.name = f"{stem}_Body"
    rig.name = f"{stem}_Rig"
    rig.data.name = f"{stem}_Rig"
    for obj in meshes:
        obj.data.name = obj.name
    mcfg = CFG["mesh"]
    v3.decimate(body, mcfg["body_ratio"], protect="head")
    for obj in clothing:
        g = next(g for g in CFG["garments"] if PREFIX + g["name"] == obj.name)
        ratio = mcfg["shoe_ratio"] if g["kind"] == "shoes" else mcfg["clothing_ratio"]
        if obj.get("cast_detail"):
            continue  # decimated before its folds were baked
        if ratio < 1.0:
            v3.decimate(obj, ratio)
    scale_final = float(ch["height_m"]) / NOMINAL_HEIGHT_M
    scale_character(rig, meshes, scale_final)
    drop = 0.0
    if CFG.get("seated"):
        # Seated: lower everything until the soles rest on the floor.
        drop = min(min((o.matrix_world @ v.co).z for v in o.data.vertices) for o in meshes)
        lower_character(rig, meshes, drop)
    rig["cast_offset_z_m"] = -drop
    # transfer_face_shapes.py matches the face to the base mesh with these.
    rig["cast_base_scale"] = info["normalise_scale"] * scale_final
    rig["cast_base_floor_z_m"] = info["base_floor_z_m"]
    rig["cast_macro_weights"] = json.dumps(info["macro_weights"])
    tris = v3.triangle_count(meshes)
    for obj in meshes:
        print(f"  {obj.name}: {v3.triangle_count([obj])} triangles")
    if tris > int(mcfg["triangle_budget"]):
        raise RuntimeError(f"{tris} triangles exceeds the {mcfg['triangle_budget']} budget")
    collection = bpy.data.collections.new(f"{stem}_{ver}")
    bpy.context.scene.collection.children.link(collection)
    for obj in [rig, *meshes]:
        v3.link(obj, collection)
    collection["character_id"] = ch["character_id"]
    collection["production_status"] = ch["production_status"]
    v3.export_glb(rig, meshes)
    renders = [] if args.no_render else render_review(meshes, float(ch["height_m"]), head_centre * scale_final - Vector((0, 0, drop)),
                                                     ROOT / "assets/renders/characters", ver)
    for image in bpy.data.images:
        if image.name.startswith(PREFIX) and not image.packed_file and image.has_data:
            image.pack()
    blend_out.parent.mkdir(parents=True, exist_ok=True)
    bpy.ops.wm.save_as_mainfile(filepath=str(blend_out), compress=True)
    names = {"rig": rig.name, "face_mesh": body.name, "eye_l": PREFIX + "Eye_L", "eye_r": PREFIX + "Eye_R"}
    profiles = write_profiles(metrics, names, scale_final,
                              {"trousers": PREFIX + kinds["trousers"], "shoes": PREFIX + kinds["shoes"]})
    manifest = {
        "asset_id": f"CHR_{ch['name'].replace(' ', '').replace('.', '')}_{ver}",
        "character_id": ch["character_id"],
        "version": ver,
        "production_status": ch["production_status"],
        "approved": bool(ch.get("approval", {}).get("approved", False)),
        **({"approval": ch["approval"]} if ch.get("approval") else {}),
        "canon_basis": ch.get("canon_basis", ""),
        "draft_choices_not_canon": ch.get("draft_choices", []),
        "builder": "tools/blender/characters/build_cast_member.py",
        "config": str(config_path.relative_to(ROOT)),
        "config_sha256": hashlib.sha256(config_path.read_bytes()).hexdigest(),
        "blender_version": bpy.app.version_string,
        "inputs": [{
            "path": CFG["source"]["blend"],
            "sha256": info["source_sha256"],
            "used": "MPFB2 2.0.18 base mesh, its macro shape keys, UVs, skin weights and game_engine rig; "
                    "provenance in assets/asset_manifest/naomi_character_manifest_v02.json",
        }],
        "external_assets": [],
        "generated": ["skin, eye, fabric, hair and badge textures (procedural, this script)",
                      "garment, shoe, hair and accessory geometry (procedural, this script)"],
        "body": {**{k: v for k, v in info.items() if k != "source_sha256"}, "height_m": ch["height_m"],
                 "final_scale": scale_final, "rig_alignment_offset_z_m": round(dz, 4)},
        "face_metrics": metrics,
        "clothing": cloth_info,
        "triangle_count": tris,
        "next_profiles": profiles,
        "outputs": {"blend": str(blend_out.relative_to(ROOT)), "glb": str(glb_out.relative_to(ROOT)),
                    "renders": [str(p.relative_to(ROOT)) for p in renders]},
        "known_limitations": CFG.get("known_limitations", []),
    }
    manifest_out.parent.mkdir(parents=True, exist_ok=True)
    manifest_out.write_text(json.dumps(manifest, indent=2) + "\n", encoding="utf-8")
    print(f"CAST {ch['character_id']} {ver} OK: {tris} triangles, height {ch['height_m']} m, {len(renders)} sheets")


if __name__ == "__main__":
    try:
        main()
    finally:
        sys.stdout.flush()
