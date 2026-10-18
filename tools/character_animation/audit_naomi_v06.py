"""Read actual v06 GLB payloads; never rewrite source or Godot import artifacts.

Run from the repository root: python3 tools/character_animation/audit_naomi_v06.py
Exit 1 means a structural acceptance check failed, not a visual judgement.
"""
import hashlib
import json
import math
from pathlib import Path
import struct

ROOT = Path(__file__).resolve().parents[2]
FORMATS = {5120: 'b', 5121: 'B', 5122: 'h', 5123: 'H', 5125: 'I', 5126: 'f'}
WIDTHS = {'SCALAR': 1, 'VEC2': 2, 'VEC3': 3, 'VEC4': 4, 'MAT4': 16}


def inspect(path):
    raw = path.read_bytes()
    magic, version, length = struct.unpack_from('<4sII', raw)
    assert (magic, version, length) == (b'glTF', 2, len(raw))
    offset, chunks = 12, {}
    while offset < length:
        size, kind = struct.unpack_from('<II', raw, offset)
        chunks[kind] = raw[offset + 8:offset + 8 + size]
        offset += size + 8
    doc, binary = json.loads(chunks[0x4E4F534A]), chunks[0x004E4942]

    def values(index):
        accessor = doc['accessors'][index]
        fmt = '<' + FORMATS[accessor['componentType']] * WIDTHS[accessor['type']]
        size = struct.calcsize(fmt)
        def read_view(view_index, byte_offset, count, row_fmt, row_size, strided=True):
            view = doc['bufferViews'][view_index]
            assert view.get('buffer', 0) == 0
            start = view.get('byteOffset', 0) + byte_offset
            stride = view.get('byteStride', row_size) if strided else row_size
            assert count == 0 or start + (count - 1) * stride + row_size <= view.get('byteOffset', 0) + view['byteLength'] <= len(binary)
            return [struct.unpack_from(row_fmt, binary, start + i * stride) for i in range(count)]
        result = (read_view(accessor['bufferView'], accessor.get('byteOffset', 0), accessor['count'], fmt, size)
                  if 'bufferView' in accessor else [(0,) * WIDTHS[accessor['type']]] * accessor['count'])
        if 'sparse' in accessor:
            sparse = accessor['sparse']
            indices, replacements = sparse['indices'], sparse['values']
            index_fmt = '<' + FORMATS[indices['componentType']]
            locations = read_view(indices['bufferView'], indices.get('byteOffset', 0), sparse['count'], index_fmt, struct.calcsize(index_fmt), False)
            rows = read_view(replacements['bufferView'], replacements.get('byteOffset', 0), sparse['count'], fmt, size, False)
            assert all(0 <= row[0] < len(result) for row in locations)
            assert all(a[0] < b[0] for a, b in zip(locations, locations[1:]))
            for location, row in zip(locations, rows):
                result[location[0]] = row
        if accessor.get('normalized') and accessor['componentType'] in (5121, 5123):
            divisor = 255 if accessor['componentType'] == 5121 else 65535
            result = [tuple(v / divisor for v in row) for row in result]
        assert all(math.isfinite(v) for row in result for v in row)
        return result

    mapping = json.loads((ROOT / 'tools/character_animation/mpfb_face_mapping.json').read_text())
    expected = set(mapping['stable_shapes']) | {'viseme_' + v for v in mapping['visemes']}
    clips = {c['name'] for c in json.loads((ROOT / 'tools/character_animation/clip_library.json').read_text())['clips']}
    failures, meshes, images = [], [], []
    for image in doc.get('images', []):
        if 'bufferView' in image:
            view = doc['bufferViews'][image['bufferView']]
            start = view.get('byteOffset', 0)
            payload = binary[start:start + view['byteLength']]
            valid = payload.startswith(b'\x89PNG\r\n\x1a\n') or payload.startswith(b'\xff\xd8\xff')
            images.append({'name': image.get('name'), 'embedded': True, 'bytes': len(payload), 'signature_valid': valid})
            if not valid:
                failures.append('invalid image signature: ' + image.get('name', '?'))
        else:
            uri = image.get('uri', '')
            exists = uri.startswith('data:') or (path.parent / uri).is_file()
            images.append({'uri': uri, 'exists': exists})
            if not exists:
                failures.append('missing external image: ' + uri)
    for node in doc.get('nodes', []):
        if 'mesh' not in node:
            continue
        mesh = doc['meshes'][node['mesh']]
        names = mesh.get('extras', {}).get('targetNames', [])
        maxima = {name: 0.0 for name in names}
        bad_weights = bad_joints = 0
        for primitive in mesh['primitives']:
            attrs = primitive['attributes']
            assert len(primitive.get('targets', [])) == len(names), 'morph name/accessor mismatch'
            if 'skin' in node:
                joints = len(doc['skins'][node['skin']]['joints'])
                weights = values(attrs['WEIGHTS_0'])
                indices = values(attrs['JOINTS_0'])
                bad_weights += sum(any(w < 0 for w in row) or abs(sum(row) - 1) > 0.002 for row in weights)
                bad_joints += sum(any(j >= joints for j in row) for row in indices)
            for name, target in zip(names, primitive.get('targets', [])):
                maxima[name] = max(maxima[name], max((math.sqrt(sum(v*v for v in row)) for row in values(target['POSITION'])), default=0))
        if bad_weights or bad_joints:
            failures.append(f'{mesh["name"]}: invalid weights={bad_weights}, joints={bad_joints}')
        if names:
            missing = sorted(expected - set(names))
            failures.extend('missing morph: ' + name for name in missing)
            for name in expected - {'viseme_sil_00'}:
                if name in maxima and maxima[name] < 1e-7:
                    failures.append('zero displacement morph: ' + name)
        meshes.append({'name': mesh.get('name'), 'morph_max_offset_m': maxima, 'bad_weight_vertices': bad_weights, 'bad_joint_vertices': bad_joints})
    if not any(m['morph_max_offset_m'] for m in meshes):
        failures.append('no morph-bearing mesh')
    animations = [a.get('name') for a in doc.get('animations', [])]
    failures.extend('missing clip: ' + name for name in sorted(clips - set(animations)))
    for animation in doc.get('animations', []):
        for sampler in animation['samplers']:
            values(sampler['input'])
            values(sampler['output'])
    return {'path': str(path.relative_to(ROOT)), 'sha256': hashlib.sha256(raw).hexdigest(), 'images': images, 'animations': animations, 'meshes': meshes, 'blocking_failures': failures, 'limits': 'Image signatures only; Godot import must prove decode. No visual, Blender, gesture-shadow or Mac performance verdict.'}


if __name__ == '__main__':
    reports = [inspect(ROOT / f'assets/exports/characters/Naomi_Bennett_{version}.glb') for version in ('v06', 'v06_mpfb')]
    print(json.dumps(reports, indent=2, sort_keys=True))
    raise SystemExit(int(any(r['blocking_failures'] for r in reports)))
