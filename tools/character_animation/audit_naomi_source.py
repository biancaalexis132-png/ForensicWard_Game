"""Inspect both original v06 Blender sources without saving them.

Blender 5.2.2:
  blender -b --python-exit-code 1 --python tools/character_animation/audit_naomi_source.py -- --report work/naomi-source.json
Or run using official bpy 5.2.2 with Python 3.13. No MPFB installation needed.
Exit 1 denotes acceptance failures, including plain v06's missing visemes.
Finite sampled geometry is not a visual clipping or shadow verdict.
"""
import argparse
import hashlib
import json
import math
from pathlib import Path
import sys

import bpy
from mathutils import Vector

ROOT = Path(__file__).resolve().parents[2]


def render_diagnostics(directory):
    """CPU source stills only; no in-game/Metal or owner-approval claim."""
    bpy.ops.wm.open_mainfile(filepath=str(ROOT / 'assets/blender/characters/Naomi_Bennett_v06_mpfb.blend'),
                             load_ui=False, use_scripts=False)
    directory.mkdir(parents=True, exist_ok=True)
    scene = bpy.context.scene
    scene.render.engine = 'CYCLES'
    scene.cycles.device = 'CPU'
    scene.cycles.samples = 12
    scene.cycles.seed = 0
    scene.cycles.use_adaptive_sampling = False
    scene.cycles.use_denoising = True
    scene.render.resolution_x, scene.render.resolution_y = 512, 640
    scene.render.resolution_percentage = 100
    scene.render.threads_mode, scene.render.threads = 'FIXED', 4
    rig = bpy.data.objects['Naomi_Bennett_Rig']
    rig.animation_data.use_nla = False
    rig.animation_data.action = bpy.data.actions['idle_neutral']
    rig.animation_data.action_slot = rig.animation_data.action.slots[0]
    scene.frame_set(1)
    body = bpy.data.objects['Naomi_Bennett_Body']
    for key in body.data.shape_keys.key_blocks:
        key.value = 0

    def render(name):
        scene.render.filepath = str((directory / (name + '.png')).resolve())
        bpy.ops.render.render(write_still=True)

    render('source_face_neutral')
    body.data.shape_keys.key_blocks['blink'].value = 1
    render('source_face_blink')
    body.data.shape_keys.key_blocks['blink'].value = 0
    camera = scene.camera
    camera.location = (2.0, -3.4, 1.45)
    camera.rotation_euler = (Vector((0, 0, 0.88)) - camera.location).to_track_quat('-Z', 'Y').to_euler()
    camera.data.type, camera.data.ortho_scale = 'ORTHO', 2.0
    render('source_body_neutral')
    rig.animation_data.action = bpy.data.actions['restrained_chart_indication']
    rig.animation_data.action_slot = rig.animation_data.action.slots[0]
    scene.frame_set(30)
    render('source_body_chart')


def inspect(path):
    before = hashlib.sha256(path.read_bytes()).hexdigest()
    bpy.ops.wm.open_mainfile(filepath=str(path), load_ui=False, use_scripts=False)
    failures, warnings = [], []
    images = []
    used_images = set()
    for material in bpy.data.materials:
        if material.node_tree is None:
            continue
        for node in material.node_tree.nodes:
            if node.type == 'TEX_IMAGE':
                if node.image is None:
                    failures.append(f'{material.name}: image node {node.name} has no image')
                else:
                    used_images.add(node.image.name)
    for name in sorted(used_images):
        image = bpy.data.images[name]
        packed = bool(image.packed_file)
        external = bpy.path.abspath(image.filepath) if image.filepath else ''
        if not packed and (not external or not Path(external).is_file()):
            failures.append(f'missing unpacked texture: {name}: {external}')
        width, height = image.size
        count = len(image.pixels)
        readable = bool(width > 0 and height > 0 and count >= width * height * image.channels)
        if readable:
            readable = math.isfinite(image.pixels[0]) and math.isfinite(image.pixels[count - 1])
        if not readable:
            failures.append('texture could not be decoded: ' + name)
        images.append({'name': name, 'packed': packed, 'external_path': external,
                       'size': [width, height], 'pixel_count': count, 'decoded': readable})
    if len(used_images) != 10:
        failures.append(f'expected ten material image dependencies, found {len(used_images)}')
    for library in bpy.data.libraries:
        if not Path(bpy.path.abspath(library.filepath)).is_file():
            failures.append('missing linked library: ' + library.filepath)

    mapping = json.loads((ROOT / 'tools/character_animation/mpfb_face_mapping.json').read_text())
    expected = set(mapping['stable_shapes']) | {'viseme_' + v for v in mapping['visemes']}
    body = bpy.data.objects.get('Naomi_Bennett_Body')
    shapes = body.data.shape_keys if body else None
    names = set(shapes.key_blocks.keys()) - {'Basis'} if shapes else set()
    failures.extend('missing morph: ' + name for name in sorted(expected - names))
    maxima = {}
    if shapes:
        basis = shapes.reference_key
        for key in shapes.key_blocks:
            if key == basis:
                continue
            if len(key.data) != len(basis.data):
                failures.append('morph vertex count mismatch: ' + key.name)
                continue
            offsets = [(vertex.co - reference.co).length for vertex, reference in zip(key.data, basis.data)]
            maxima[key.name] = max(offsets, default=0.0)
            if not all(math.isfinite(value) for value in offsets):
                failures.append('nonfinite morph: ' + key.name)
            if key.name != 'viseme_sil_00' and maxima[key.name] <= 1e-7:
                failures.append('zero displacement morph: ' + key.name)

    meshes = []
    rig = bpy.data.objects.get('Naomi_Bennett_Rig')
    if rig is None or rig.type != 'ARMATURE':
        failures.append('missing armature')
    bones = {bone.name for bone in rig.data.bones} if rig else set()
    for obj in sorted(bpy.data.objects, key=lambda item: item.name):
        if obj.type != 'MESH':
            continue
        bone_groups = {group.index for group in obj.vertex_groups if group.name in bones}
        weighted = any(mod.type == 'ARMATURE' and mod.object == rig for mod in obj.modifiers)
        unweighted = nonfinite = negative = unnormalized = 0
        if weighted:
            for vertex in obj.data.vertices:
                weights = [item.weight for item in vertex.groups if item.group in bone_groups]
                total = sum(weights)
                unweighted += total <= 1e-8
                nonfinite += not all(math.isfinite(weight) for weight in weights)
                negative += any(weight < 0 for weight in weights)
                unnormalized += abs(total - 1.0) > 0.002
            if unweighted or nonfinite or negative:
                failures.append(f'{obj.name}: invalid source weights: unweighted={unweighted}, nonfinite={nonfinite}, negative={negative}')
            if unnormalized:
                warnings.append(f'{obj.name}: {unnormalized} source weight sums differ from one; compare normalized GLB export')
        meshes.append({'name': obj.name, 'vertices': len(obj.data.vertices), 'armature_bound': weighted,
                       'unweighted_vertices': unweighted, 'nonfinite_weight_vertices': nonfinite,
                       'negative_weight_vertices': negative, 'unnormalized_vertices': unnormalized})

    required_clips = {clip['name'] for clip in json.loads((ROOT / 'tools/character_animation/clip_library.json').read_text())['clips']}
    failures.extend('missing action: ' + name for name in sorted(required_clips - set(bpy.data.actions.keys())))
    actions = []
    if rig:
        rig.animation_data_create()
        # Disable NLA overlays in memory so each sampled action is tested alone.
        rig.animation_data.use_nla = False
        for action in sorted(bpy.data.actions, key=lambda item: item.name):
            if action.name not in required_clips:
                continue
            rig.animation_data.action = action
            if len(action.slots):
                rig.animation_data.action_slot = action.slots[0]
            start, end = action.frame_range
            samples = []
            first_pose = None
            max_pose_delta = 0.0
            for fraction in (0.0, 0.25, 0.5, 0.75, 1.0):
                frame = start + (end - start) * fraction
                whole = math.floor(frame)
                bpy.context.scene.frame_set(whole, subframe=frame - whole)
                depsgraph = bpy.context.evaluated_depsgraph_get()
                evaluated_rig = rig.evaluated_get(depsgraph)
                pose = [value for bone in evaluated_rig.pose.bones for row in bone.matrix for value in row]
                if first_pose is None:
                    first_pose = pose
                max_pose_delta = max(max_pose_delta, max(abs(a - b) for a, b in zip(pose, first_pose)))
                bounds = {}
                for item in meshes:
                    obj = bpy.data.objects[item['name']].evaluated_get(depsgraph)
                    mesh = obj.to_mesh()
                    try:
                        points = [obj.matrix_world @ vertex.co for vertex in mesh.vertices]
                        finite = all(math.isfinite(v) for point in points for v in point)
                        if not finite:
                            failures.append(f'{action.name} frame {frame}: nonfinite evaluated geometry in {obj.name}')
                        bounds[obj.name] = {'finite': finite, 'vertices': len(points),
                                            'min': [min(p[axis] for p in points) for axis in range(3)],
                                            'max': [max(p[axis] for p in points) for axis in range(3)]}
                    finally:
                        obj.to_mesh_clear()
                samples.append({'frame': frame, 'meshes': bounds})
            if end <= start or max_pose_delta <= 1e-6:
                failures.append('action has no sampled pose motion: ' + action.name)
            actions.append({'name': action.name, 'frame_range': [start, end],
                            'max_pose_matrix_delta': max_pose_delta, 'samples': samples})
    after = hashlib.sha256(path.read_bytes()).hexdigest()
    if before != after:
        failures.append('source bytes changed during read-only audit')
    return {'path': str(path.relative_to(ROOT)), 'sha256_before': before, 'sha256_after': after,
            'blender_version': bpy.app.version_string, 'images': images, 'meshes': meshes,
            'morph_max_offset_m': maxima, 'actions': actions, 'blocking_failures': failures,
            'significant_warnings': warnings,
            'limits': 'Five evaluated frames per clip; no visible clipping, blink closure, Mac performance, Godot placement or shadow verdict.'}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--report', type=Path, required=True)
    parser.add_argument('--summary', action='store_true', help='Keep action sample frames/results without per-frame mesh bounds')
    parser.add_argument('--render-dir', type=Path, help='Optional diagnostic CPU stills of MPFB source; never game captures')
    argv = sys.argv[sys.argv.index('--') + 1:] if '--' in sys.argv else sys.argv[1:]
    args = parser.parse_args(argv)
    reports = [inspect(ROOT / f'assets/blender/characters/Naomi_Bennett_{version}.blend') for version in ('v06', 'v06_mpfb')]
    if args.summary:
        for report in reports:
            for action in report['actions']:
                samples = action.pop('samples')
                action['sample_frames'] = [sample['frame'] for sample in samples]
                action['all_geometry_finite'] = all(mesh['finite'] for sample in samples for mesh in sample['meshes'].values())
                action['evaluated_meshes'] = sorted(samples[0]['meshes'])
    args.report.parent.mkdir(parents=True, exist_ok=True)
    args.report.write_text(json.dumps(reports, sort_keys=True, indent=2) + '\n')
    if args.render_dir:
        render_diagnostics(args.render_dir)
    for report in reports:
        print('NAOMI_SOURCE', report['path'], 'images=', len(report['images']), 'actions=', len(report['actions']),
              'morphs=', len(report['morph_max_offset_m']), 'failures=', len(report['blocking_failures']))
    return int(any(report['blocking_failures'] for report in reports))


if __name__ == '__main__':
    raise SystemExit(main())
