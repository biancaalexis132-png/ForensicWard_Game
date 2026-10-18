"""Export a toolkit-authored .blend (from create_animation_actions.py) to a NEW GLB with every
fake-user action as a separate glTF animation. Read-only on the source .blend; refuses to overwrite.
Run: blender -b ANIMATED.blend -P export_animated_glb.py -- --out NEW.glb --rig RIG_NAME [--require CLIP ...]
"""
import argparse,sys
from pathlib import Path
import bpy
argv=sys.argv[sys.argv.index('--')+1:] if '--' in sys.argv else []
p=argparse.ArgumentParser();p.add_argument('--out',required=True);p.add_argument('--rig',required=True);p.add_argument('--require',action='append',default=[]);ns=p.parse_args(argv)
out=Path(ns.out).resolve()
if out.suffix.lower()!='.glb':raise RuntimeError('Output must be a .glb file')
if out.exists():raise RuntimeError('Refusing to overwrite existing output: '+str(out))
rig=bpy.data.objects.get(ns.rig)
if rig is None or rig.type!='ARMATURE':raise RuntimeError('Missing rig: '+ns.rig)

def curve_count(act):
    # Blender 4.4+ stores keys in layered/slotted actions; older builds expose act.fcurves.
    if hasattr(act,'layers') and len(act.layers):
        return sum(len(cb.fcurves) for layer in act.layers for strip in layer.strips for cb in strip.channelbags)
    return len(getattr(act,'fcurves',[]))

actions={a.name:curve_count(a) for a in bpy.data.actions}
print('Actions found:',actions)
missing=[c for c in ns.require if actions.get(c,0)==0]
if missing:raise RuntimeError('Missing or empty actions: '+', '.join(missing))
# Every action must be bindable to the rig so the exporter can bake it per clip.
if rig.animation_data is None:rig.animation_data_create()
rig.animation_data.action=None
bpy.context.scene.frame_set(1)
out.parent.mkdir(parents=True,exist_ok=True)
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=False,
    export_animations=True,export_animation_mode='ACTIONS',export_force_sampling=False,
    export_frame_range=False,export_def_bones=False,export_skins=True,export_morph=True,
    export_yup=True,export_apply=False)
print('Exported:',out)
