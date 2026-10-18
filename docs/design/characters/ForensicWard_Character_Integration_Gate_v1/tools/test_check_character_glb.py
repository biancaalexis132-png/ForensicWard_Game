import json
import struct
import tempfile
import unittest
from pathlib import Path
from check_character_glb import inspect_glb

def glb(payload):
    body=json.dumps(payload).encode()
    body += b" " * ((-len(body)) % 4)
    chunk=struct.pack("<II",len(body),0x4E4F534A)+body
    return struct.pack("<4sII",b"glTF",2,12+len(chunk))+chunk

class TestGLB(unittest.TestCase):
    def test_minimal_mesh(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"test.glb"
            p.write_bytes(glb({"asset":{"version":"2.0"},"meshes":[{"primitives":[{"attributes":{"POSITION":0}}]}]}))
            self.assertEqual(inspect_glb(p)["mesh_count"],1)
    def test_reject_empty_mesh(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"test.glb"
            p.write_bytes(glb({"asset":{"version":"2.0"},"meshes":[]}))
            with self.assertRaisesRegex(ValueError,"no drawable"):
                inspect_glb(p)
    def test_reject_bad_header(self):
        with tempfile.TemporaryDirectory() as d:
            p=Path(d)/"test.glb"
            p.write_bytes(b"nope")
            with self.assertRaises(ValueError): inspect_glb(p)

if __name__ == "__main__": unittest.main()
