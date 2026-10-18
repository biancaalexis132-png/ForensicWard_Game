"""Optional Blender 5.2 animation experiment. Operates on already-open .blend; saves NEW file only.
The script does not export GLB; owner/Claude must validate rig deformation and use Blender's
verified glTF exporter for this build, then inspect exported GLB. Never modify rest pose.
Run: blender -b INPUT.blend -P create_animation_actions.py -- --out NEW_FILE.blend --rig RIG_NAME --map CONFIG.json
"""
import argparse,json,math,sys
from pathlib import Path
import bpy
from mathutils import Quaternion
argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
p=argparse.ArgumentParser();p.add_argument('--out',required=True);p.add_argument('--rig',required=True);p.add_argument('--map',required=True);ns=p.parse_args(argv)
cfg=json.loads(Path(ns.map).read_text());rig=bpy.data.objects.get(ns.rig)
if rig is None or rig.type!='ARMATURE':raise RuntimeError('Missing rig: '+ns.rig)
src=Path(bpy.data.filepath).resolve() if bpy.data.filepath else None;out=Path(ns.out).resolve()
if not src or src==out:raise RuntimeError('Output must be a different .blend file')
if out.exists():raise RuntimeError('Refusing to overwrite existing output: '+str(out))
for role,name in cfg['bones'].items():
    if name not in rig.pose.bones:raise RuntimeError('Missing mapped bone '+role+': '+name)
if rig.animation_data is None:rig.animation_data_create()
scene=bpy.context.scene
for spec in cfg['clips']:
    # Preserve pre-existing actions; do not alter mesh bind pose or armature rest configuration.
    name=spec['name']
    if bpy.data.actions.get(name):raise RuntimeError('Refusing to replace action '+name)
    act=bpy.data.actions.new(name);rig.animation_data.action=act
    bones=[rig.pose.bones[cfg['bones'][role]] for role in spec['degrees']]
    initial={b.name:b.rotation_quaternion.copy() for b in bones}
    for b in bones:b.rotation_mode='QUATERNION'
    # Optional per-clip length in frames (default 25 keeps the original 1 s test loop).
    # Breathing and idle loops need several seconds to read as natural at 24 fps.
    last=int(spec.get('frames',25))
    if last<3:raise RuntimeError('Clip '+name+' needs at least 3 frames')
    for frame,multiplier in ((1,0.0),(1+(last-1)//2,1.0),(last,0.0)):
        scene.frame_set(frame)
        for role,deg in spec['degrees'].items():
            b=rig.pose.bones[cfg['bones'][role]]
            from mathutils import Euler
            delta=Euler(tuple(math.radians(v*multiplier) for v in deg),'XYZ').to_quaternion()
            b.rotation_quaternion=initial[b.name] @ delta
            b.keyframe_insert(data_path='rotation_quaternion',frame=frame,group=b.name)
    for b in bones:b.rotation_quaternion=initial[b.name]
    # Preserve clip as fake-user asset until export policy is reviewed.
    act.use_fake_user=True
rig.animation_data.action=None
scene.frame_set(1)
out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.wm.save_as_mainfile(filepath=str(out))
print('Saved animation test source:',out)
print('IMPORTANT: validate deformation; export with version-compatible Blender glTF action settings; verify channels in exported GLB.')
