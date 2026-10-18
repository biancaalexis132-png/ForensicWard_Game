"""Read-only glTF 2.0 GLB inspector; validates clip channels, skin and morph names."""
import argparse,json,struct,sys
from pathlib import Path

def inspect(path):
    b=Path(path).read_bytes()
    if len(b)<20:raise ValueError('GLB truncated')
    magic,version,length=struct.unpack_from('<4sII',b)
    if magic!=b'glTF' or version!=2 or length!=len(b):raise ValueError('Invalid GLB header')
    n,kind=struct.unpack_from('<II',b,12)
    if kind!=0x4e4f534a or 20+n>len(b):raise ValueError('Invalid JSON chunk')
    d=json.loads(b[20:20+n]);nodes=d.get('nodes',[])
    clips=[]
    for anim in d.get('animations',[]):
        channels=anim.get('channels',[])
        clips.append({'name':anim.get('name',''), 'channels':len(channels), 'target_paths':sorted(set(ch.get('target',{}).get('path','') for ch in channels)), 'target_nodes':sorted(set(nodes[ch['target']['node']].get('name','') for ch in channels if ch.get('target',{}).get('node',-1) in range(len(nodes))))})
    morph=[]
    for mesh in d.get('meshes',[]):
        names=mesh.get('extras',{}).get('targetNames',[])
        if names:morph.append({'mesh':mesh.get('name',''),'names':names})
    return {'meshes':len(d.get('meshes',[])),'skins':len(d.get('skins',[])),'joints':[len(x.get('joints',[])) for x in d.get('skins',[])],'animations':clips,'morph_targets':morph}
if __name__=='__main__':
    a=argparse.ArgumentParser();a.add_argument('glb');a.add_argument('--output');a.add_argument('--require-clip',action='append',default=[]);ns=a.parse_args()
    try:
        r=inspect(ns.glb)
        if ns.output:Path(ns.output).write_text(json.dumps(r,indent=2))
        print(json.dumps(r,indent=2))
        missing=set(ns.require_clip)-{a['name'] for a in r['animations'] if a['channels']}
        if missing:raise ValueError('Missing/nonfunctional animation clips: '+', '.join(sorted(missing)))
    except Exception as e:print('FAIL:',e,file=sys.stderr);sys.exit(1)
