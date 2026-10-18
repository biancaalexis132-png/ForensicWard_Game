"""Real-asset regressions: catch the published v06/MPFB mismatch and bad weights."""
import importlib.util
import json
from pathlib import Path
import struct
import tempfile
import unittest

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('naomi_audit', ROOT / 'tools/character_animation/audit_naomi_v06.py')
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class NaomiAuditTests(unittest.TestCase):
    def test_plain_v06_does_not_satisfy_viseme_contract(self):
        report = AUDIT.inspect(ROOT / 'assets/exports/characters/Naomi_Bennett_v06.glb')
        self.assertEqual(len(report['blocking_failures']), 22)
        self.assertTrue(all(f.startswith('missing morph: viseme_') for f in report['blocking_failures']))

    def test_mpfb_payload_has_functional_shapes_and_valid_weights(self):
        report = AUDIT.inspect(ROOT / 'assets/exports/characters/Naomi_Bennett_v06_mpfb.glb')
        self.assertEqual(report['blocking_failures'], [])
        body = next(m for m in report['meshes'] if m['morph_max_offset_m'])
        self.assertEqual(len(body['morph_max_offset_m']), 32)
        self.assertGreater(body['morph_max_offset_m']['viseme_aa_02'], 0.004)
        self.assertLess(body['morph_max_offset_m']['viseme_sil_00'], 0.0005)
        self.assertEqual(len(report['animations']), 10)
        self.assertEqual(len(report['images']), 10)

    def test_corrupt_weight_payload_is_rejected(self):
        (ROOT / 'work').mkdir(exist_ok=True)
        raw = bytearray((ROOT / 'assets/exports/characters/Naomi_Bennett_v06_mpfb.glb').read_bytes())
        json_length = struct.unpack_from('<I', raw, 12)[0]
        doc = json.loads(raw[20:20 + json_length])
        mesh = next(m for m in doc['meshes'] if 'WEIGHTS_0' in m['primitives'][0]['attributes'])
        accessor = doc['accessors'][mesh['primitives'][0]['attributes']['WEIGHTS_0']]
        self.assertEqual(accessor['componentType'], 5126)
        view = doc['bufferViews'][accessor['bufferView']]
        offset = 28 + json_length + view.get('byteOffset', 0) + accessor.get('byteOffset', 0)
        struct.pack_into('<f', raw, offset, -1.0)
        with tempfile.TemporaryDirectory(dir=ROOT / 'work') as directory:
            path = Path(directory) / 'corrupt.glb'
            path.write_bytes(raw)
            report = AUDIT.inspect(path)
        self.assertTrue(any('invalid weights=' in f for f in report['blocking_failures']))


if __name__ == '__main__':
    (ROOT / 'work').mkdir(exist_ok=True)
    unittest.main()
