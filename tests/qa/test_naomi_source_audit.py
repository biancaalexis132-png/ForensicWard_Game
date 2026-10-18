"""Run explicitly with production bpy (Python 3.13 / Blender 5.2.2).

This integration suite is separate from the dependency-free game QA runner.
It uses real source assets and a disposable corrupted source, never overwriting
the originals. It must not silently pass on a machine without bpy.
"""
import importlib.util
from pathlib import Path
import tempfile
import unittest

import bpy

ROOT = Path(__file__).resolve().parents[2]
SPEC = importlib.util.spec_from_file_location('source_audit', ROOT / 'tools/character_animation/audit_naomi_source.py')
AUDIT = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(AUDIT)


class NaomiSourceTests(unittest.TestCase):
    def test_mpfb_source_is_self_contained_and_animated(self):
        report = AUDIT.inspect(ROOT / 'assets/blender/characters/Naomi_Bennett_v06_mpfb.blend')
        self.assertEqual(report['blocking_failures'], [])
        self.assertEqual(report['sha256_before'], report['sha256_after'])
        self.assertEqual(len(report['images']), 10)
        self.assertTrue(all(i['packed'] and i['decoded'] for i in report['images']))
        self.assertEqual(len(report['morph_max_offset_m']), 32)
        self.assertEqual(len(report['actions']), 10)
        self.assertTrue(all(a['max_pose_matrix_delta'] > 1e-6 for a in report['actions']))
        self.assertTrue(all(m['finite'] for a in report['actions'] for s in a['samples'] for m in s['meshes'].values()))

    def test_plain_source_is_not_viseme_complete(self):
        report = AUDIT.inspect(ROOT / 'assets/blender/characters/Naomi_Bennett_v06.blend')
        self.assertEqual(report['sha256_before'], report['sha256_after'])
        self.assertEqual(len(report['blocking_failures']), 22)
        self.assertTrue(all(f.startswith('missing morph: viseme_') for f in report['blocking_failures']))

    def test_removed_skin_weights_are_detected(self):
        source = ROOT / 'assets/blender/characters/Naomi_Bennett_v06_mpfb.blend'
        bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
        bpy.data.objects['Naomi_Bennett_Body'].vertex_groups.clear()
        (ROOT / 'work').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / 'work') as directory:
            corrupted = Path(directory) / 'unweighted.blend'
            bpy.context.preferences.filepaths.file_preview_type = 'NONE'
            bpy.ops.wm.save_as_mainfile(filepath=str(corrupted))
            report = AUDIT.inspect(corrupted)
        self.assertTrue(any('invalid source weights: unweighted=5274' in f for f in report['blocking_failures']))

    def test_missing_external_texture_is_detected(self):
        source = ROOT / 'assets/blender/characters/Naomi_Bennett_v06_mpfb.blend'
        bpy.ops.wm.open_mainfile(filepath=str(source), load_ui=False, use_scripts=False)
        image = bpy.data.images['Naomi_Eye_BaseColor']
        image.unpack(method='REMOVE')
        image.filepath = '//missing_for_audit.png'
        (ROOT / 'work').mkdir(exist_ok=True)
        with tempfile.TemporaryDirectory(dir=ROOT / 'work') as directory:
            corrupted = Path(directory) / 'missing-texture.blend'
            bpy.context.preferences.filepaths.file_preview_type = 'NONE'
            bpy.ops.wm.save_as_mainfile(filepath=str(corrupted))
            report = AUDIT.inspect(corrupted)
        self.assertTrue(any('missing unpacked texture: Naomi_Eye_BaseColor' in f for f in report['blocking_failures']))


if __name__ == '__main__':
    unittest.main()
