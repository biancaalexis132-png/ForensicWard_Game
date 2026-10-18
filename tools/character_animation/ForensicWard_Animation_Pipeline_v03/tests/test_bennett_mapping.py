import json,unittest
from pathlib import Path
HERE=Path(__file__).resolve().parents[1]
class TestBennettMapping(unittest.TestCase):
 def test_mapped_bones_exist_in_recorded_rig(self):
  cfg=json.loads((HERE/'configs'/'staff_bennett_v03_mapping.json').read_text())
  inv=json.loads((HERE/'reports'/'Naomi_Bennett_v03_rig_inventory.json').read_text())
  self.assertEqual(cfg['rig_name'],inv['rig'])
  for role,bone in cfg['bones'].items():self.assertIn(bone,inv['bone_names'],role)
  for clip in cfg['clips']:
   self.assertTrue(set(clip['degrees'])<=set(cfg['bones']),clip['name'])
   self.assertGreaterEqual(int(clip.get('frames',25)),3,clip['name'])
 def test_clip_names_are_unique(self):
  cfg=json.loads((HERE/'configs'/'staff_bennett_v03_mapping.json').read_text())
  names=[c['name'] for c in cfg['clips']];self.assertEqual(len(names),len(set(names)))
if __name__=='__main__':unittest.main()
