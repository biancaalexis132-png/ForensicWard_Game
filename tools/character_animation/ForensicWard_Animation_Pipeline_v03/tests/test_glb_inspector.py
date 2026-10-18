import json,struct,tempfile,unittest
from pathlib import Path
from tools.inspect_glb import inspect
class TestGLB(unittest.TestCase):
 def make(self,data):
  body=json.dumps(data).encode();body+=b' ' *((-len(body))%4)
  raw=struct.pack('<4sII',b'glTF',2,20+len(body))+struct.pack('<II',len(body),0x4e4f534a)+body
  f=Path(tempfile.mktemp(suffix='.glb'));f.write_bytes(raw);self.addCleanup(f.unlink);return f
 def test_valid(self):
  x=self.make({'meshes':[{}],'skins':[{'joints':[0]}],'nodes':[{'name':'head'}],'animations':[{'name':'idle_neutral','channels':[{'target':{'node':0,'path':'rotation'}}]}]})
  r=inspect(x);self.assertEqual(r['animations'][0]['channels'],1)
 def test_empty(self):
  x=self.make({});self.assertEqual(inspect(x)['animations'],[])
 def test_truncated(self):
  x=Path(tempfile.mktemp());x.write_bytes(b'x');self.addCleanup(x.unlink)
  with self.assertRaises(ValueError):inspect(x)
if __name__=='__main__':unittest.main()
