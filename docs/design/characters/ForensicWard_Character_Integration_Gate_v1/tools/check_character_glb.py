#!/usr/bin/env python3
"""Read-only GLB 2.0 structural preflight. stdlib only; not a visual/rig validation."""
import argparse
import json
import struct
import sys
from pathlib import Path

MAGIC = b"glTF"
JSON_CHUNK = 0x4E4F534A
BIN_CHUNK = 0x004E4942

def inspect_glb(path):
    data = Path(path).read_bytes()
    if len(data) < 20:
        raise ValueError("GLB too small for header and JSON chunk")
    magic, version, total = struct.unpack_from("<4sII", data, 0)
    if magic != MAGIC or version != 2 or total != len(data):
        raise ValueError("invalid GLB magic/version/declared length")
    offset, chunks = 12, []
    while offset < len(data):
        if offset + 8 > len(data):
            raise ValueError("truncated chunk header")
        size, kind = struct.unpack_from("<II", data, offset)
        offset += 8
        if size % 4 != 0 or offset + size > len(data):
            raise ValueError("invalid chunk alignment or length")
        chunks.append((kind, data[offset:offset+size]))
        offset += size
    if not chunks or chunks[0][0] != JSON_CHUNK:
        raise ValueError("first chunk must be JSON")
    if len(chunks) > 2 or (len(chunks) == 2 and chunks[1][0] != BIN_CHUNK):
        raise ValueError("unexpected GLB chunk order/type")
    try:
        gltf = json.loads(chunks[0][1].decode("utf-8").rstrip(" \x00"))
    except (ValueError, UnicodeDecodeError) as exc:
        raise ValueError("malformed glTF JSON") from exc
    if gltf.get("asset", {}).get("version") != "2.0":
        raise ValueError("glTF asset.version is not 2.0")
    meshes = gltf.get("meshes", [])
    if not meshes or not any(m.get("primitives") for m in meshes):
        raise ValueError("no drawable mesh primitives")
    buffers = gltf.get("buffers", [])
    bin_size = len(chunks[1][1]) if len(chunks) > 1 else 0
    if any("uri" not in b for b in buffers) and bin_size == 0:
        raise ValueError("embedded buffer declared but BIN chunk missing")
    for b in buffers:
        if "uri" not in b and int(b.get("byteLength", 0)) > bin_size:
            raise ValueError("embedded BIN chunk shorter than buffer.byteLength")
    nodes = gltf.get("nodes", [])
    return {
        "path": str(path), "valid_glb_structure": True,
        "mesh_count": len(meshes), "node_count": len(nodes),
        "skin_count": len(gltf.get("skins", [])),
        "animation_count": len(gltf.get("animations", [])),
        "material_count": len(gltf.get("materials", [])),
        "texture_count": len(gltf.get("textures", [])),
        "bin_bytes": bin_size,
        "warnings": [x for x in [
            "No glTF skin definitions; review if this character is intended to be rigged" if not gltf.get("skins") else None,
            "No animation clips embedded; external AnimationLibrary may be intended" if not gltf.get("animations") else None,
            "External buffer/texture URIs present; self-contained export must be verified" if any("uri" in b for b in buffers) or any("uri" in i for i in gltf.get("images", [])) else None,
        ] if x]
    }

def main():
    p = argparse.ArgumentParser(description=__doc__)
    p.add_argument("glb", help="GLB file to check")
    p.add_argument("--json-out", help="optional report output file")
    args = p.parse_args()
    try:
        report = inspect_glb(args.glb)
        code = 0
    except (OSError, ValueError, TypeError, KeyError) as exc:
        report = {"path": args.glb, "valid_glb_structure": False, "error": str(exc)}
        code = 1
    output = json.dumps(report, indent=2)
    print(output)
    if args.json_out:
        Path(args.json_out).write_text(output + "\n")
    return code

if __name__ == "__main__":
    sys.exit(main())
