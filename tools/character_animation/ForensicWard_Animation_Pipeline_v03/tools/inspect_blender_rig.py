"""Blender 5.2 rig inventory, read-only. Run: blender -b FILE.blend -P inspect_blender_rig.py -- --out report.json"""
import argparse,json,sys
from pathlib import Path
import bpy
args=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
p=argparse.ArgumentParser();p.add_argument('--out',required=True);ns=p.parse_args(args)
rigs=[]
for obj in bpy.data.objects:
    if obj.type!='ARMATURE':continue
    meshes=[m for m in bpy.data.objects if m.type=='MESH' and (any(md.type=='ARMATURE' and md.object==obj for md in m.modifiers) or m.parent==obj)]
    rigs.append({'name':obj.name,'bone_names':[b.name for b in obj.data.bones], 'pose_bones':[b.name for b in obj.pose.bones], 'rest_matrix':list(map(list,obj.matrix_world)), 'bound_meshes':[{'name':m.name,'vertex_groups':[g.name for g in m.vertex_groups],'shape_keys':list(m.data.shape_keys.key_blocks.keys()) if m.data.shape_keys else []} for m in meshes], 'actions':[a.name for a in bpy.data.actions]})
Path(ns.out).parent.mkdir(parents=True,exist_ok=True)
Path(ns.out).write_text(json.dumps({'blender':bpy.app.version_string,'rigs':rigs},indent=2))
print('Wrote rig inventory:',ns.out, 'armatures:',len(rigs))
if not rigs:sys.exit(2)
