"""Original procedural campus, hospital facade and optional apartment review assets.
Run: blender -b --python tools/blender/build_stage7_exterior.py -- --render
Uses only repository primitives and generated textures. No external art inputs.
"""
import bpy, json, math, os, sys, hashlib, struct, zlib
import numpy as np
from mathutils import Vector
sys.path.insert(0, os.path.dirname(__file__))
import fw_lib as L
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), '../..'))
OUT = os.path.join(ROOT, 'assets/exports/exterior')
SRC = os.path.join(ROOT, 'assets/blender/exterior')
TEX = os.path.join(ROOT, 'assets/textures/environment_finish')
RENDER = os.path.join(ROOT, 'assets/renders/stage7')
for folder in [OUT,SRC,TEX,RENDER]: os.makedirs(folder, exist_ok=True)
COLORS = {'Brick':'#8b6553','Stone':'#c1b8a3','Asphalt':'#454b4e','Grass':'#59664d','Wood':'#84664d','Plaster':'#d0c9b7','Metal':'#4c5960','Glass':'#617d86','Leaves':'#465d40','Bark':'#665043','Paint':'#e6dfcb','Sofa':'#526b72','Lamp':'#ffe5b8','CarBlue':'#425c70','CarRed':'#7c4d43','Rubber':'#24272a'}
for name, color in COLORS.items(): L.PALETTE['M_Finish_'+name] = (color, 0.82 if name not in ['Glass','Metal'] else 0.35, 0.6 if name=='Metal' else 0, {})

def textures():
    rng=np.random.default_rng(70620)
    grain=rng.random((256,256)).astype(np.float32)
    for name in ['grain','roughness','normal']:
        arr=np.ones((256,256,4),np.float32)
        if name=='grain': arr[:,:,:3]=(0.86+grain[:,:,None]*0.14)
        elif name=='roughness': arr[:,:,:3]=(0.7+grain[:,:,None]*0.25)
        else:
            arr[:,:,0]=0.5+(grain-0.5)*0.10;arr[:,:,1]=0.5+(np.roll(grain,1,axis=0)-0.5)*0.10;arr[:,:,2]=1
        image=bpy.data.images.new('Finish_'+name,256,256,alpha=True)
        image.pixels.foreach_set(arr.ravel());image.filepath_raw=os.path.join(TEX,name+'.png');image.file_format='PNG';image.save()
textures()

def png(path, pixels):
    raw=(np.clip(pixels,0,1)*255).astype(np.uint8)
    h,w,_=raw.shape
    def chunk(kind,data): return struct.pack('!I',len(data))+kind+data+struct.pack('!I',zlib.crc32(kind+data)&0xffffffff)
    rows=b''.join(b'\0'+row.tobytes() for row in raw)
    with open(path,'wb') as f: f.write(b'\x89PNG\r\n\x1a\n'+chunk(b'IHDR',struct.pack('!2I5B',w,h,8,6,0,0,0))+chunk(b'IDAT',zlib.compress(rows))+chunk(b'IEND',b''))

def finish_materials():
    for mat in bpy.data.materials:
        if not mat.name.startswith('M_Finish_'): continue
        mat.use_nodes=True; nodes=mat.node_tree.nodes; links=mat.node_tree.links
        shader=nodes.get('Principled BSDF')
        key=mat.name.removeprefix('M_Finish_')
        color=COLORS[key].lstrip('#')
        rgb=np.array([int(color[i:i+2],16)/255 for i in [0,2,4]],np.float32)
        rng=np.random.default_rng(70620)
        grain=.88+rng.random((256,256,1))*.12
        pixels=np.ones((256,256,4),np.float32);pixels[:,:,:3]=rgb*grain
        yy,xx=np.indices((256,256))
        if key=='Brick':
            mortar=(yy%12<1)|((xx+(yy//12%2)*15)%30<1)
            pixels[mortar,:3]=np.array([.60,.58,.54])
        elif key=='Stone':
            joints=(yy%64<1)|(xx%64<1);pixels[joints,:3]*=.72
        elif key=='Wood':
            wave=.94+.06*np.sin(xx*.15+np.sin(yy*.05));pixels[:,:,:3]*=wave[:,:,None]
        path=os.path.join(TEX,key.lower()+'.png');png(path,pixels)
        tex=nodes.new('ShaderNodeTexImage');tex.image=bpy.data.images.load(path,check_existing=True)
        links.new(tex.outputs['Color'],shader.inputs['Base Color'])
        rough=nodes.new('ShaderNodeTexImage');rough.image=bpy.data.images.load(os.path.join(TEX,'roughness.png'),check_existing=True);rough.image.colorspace_settings.name='Non-Color'
        if key!='Glass': links.new(rough.outputs['Color'],shader.inputs['Roughness'])
        else: shader.inputs['Roughness'].default_value=.18
        normal=nodes.new('ShaderNodeTexImage');normal.image=bpy.data.images.load(os.path.join(TEX,'normal.png'),check_existing=True);normal.image.colorspace_settings.name='Non-Color'
        bump=nodes.new('ShaderNodeNormalMap');bump.inputs['Strength'].default_value=0.18;links.new(normal.outputs['Color'],bump.inputs['Color']);links.new(bump.outputs['Normal'],shader.inputs['Normal'])
    for image in bpy.data.images:
        if image.source=='FILE': image.pack()

def box(builder,size,center,material): builder.box(size,center,mat='M_Finish_'+material)
def building(b,x,y,w,d,h=7):
    box(b,(w,d,h),(x,y,h/2),'Brick');box(b,(w+.4,d+.4,.22),(x,y,h+.08),'Stone')
    for z in [1.8,4.8]:
        for xx in np.arange(x-w/2+1,x+w/2,2.0):
            box(b,(1.0,.04,1.35),(float(xx),y-d/2-.03,z),'Glass')

def campus(root,coll):
    b=L.MeshBuilder();box(b,(104,126,.2),(0,3,-.25),'Grass')
    box(b,(58,32,.08),(0,-25,-.06),'Asphalt')
    box(b,(4,44,.08),(0,-26,0),'Stone')
    for y in [-10,-39]:
        box(b,(58,.25,.17),(0,y,.04),'Stone')
        for x in range(-26,29,3): box(b,(.08,5,.012),(x,y+3 if y==-39 else y-3,.0),'Paint')
    for x in [-30,30]:
        box(b,(.22,40,.25),(x,-26,.03),'Stone')
        for y in [-9,-23,-40]:
            b.cyl(.065,4,(x,y,2),mat='M_Finish_Metal',segs=10)
            box(b,(1.2,.08,.08),(x+.5,y,3.9),'Metal');box(b,(.5,.32,.12),(x+1,y,3.82),'Lamp')
    for number,(x,y) in enumerate([(-22,-13),(-12,-13),(12,-13),(21,-36),(-18,-36),(9,-36)]):
        car=L.MeshBuilder();material='M_Finish_CarBlue' if x<0 else 'M_Finish_CarRed'
        rings=[]
        for yy,width,height in [(-2.05,.7,.7),(-1.35,.94,.86),(-.65,.82,1.4),(.65,.82,1.4),(1.35,.94,.86),(2.05,.7,.7)]:
            rings.append([car.bm.verts.new((xx+x,yy+y,zz)) for xx,zz in [(-width,.36),(width,.36),(width,height),(-width,height)]])
        for ring in [rings[0],rings[-1]]:
            face=car.bm.faces.new(ring);face.material_index=car._mi(material)
        for first,second in zip(rings,rings[1:]):
            for i in range(4):
                face=car.bm.faces.new([first[i],second[i],second[(i+1)%4],first[(i+1)%4]])
                face.material_index=car._mi('M_Finish_Glass' if i==2 and first in [rings[1],rings[3]] else material)
        for dx in [-.84,.84]:
            box(car,(.02,1.15,.4),(x+dx,y,1.12),'Glass')
        for dx in [-.94,.94]:
            for dy in [-1.2,1.2]:
                car.cyl(.32,.2,(x+dx,y+dy,.32),mat='M_Finish_Rubber',axis='X',segs=16)
                car.cyl(.16,.215,(x+dx,y+dy,.32),mat='M_Finish_Metal',axis='X',segs=12)
        for dx in [-.5,.5]:
            box(car,(.4,.05,.12),(x+dx,y-2.05,.59),'Lamp')
            box(car,(.35,.05,.12),(x+dx,y+2.05,.59),'CarRed')
        car.build('ParkedCar_%d'%number,coll,root,bevel=.06)
        L.collision_box('ParkedCar_%d'%number,coll,root,(1.9,4.1,1.5),(x,y,.75))
    for x in [-33,33]:
        for y in [-7,-19,-33,-44]:
            b.cyl(.17,3.4,(x,y,1.7),mat='M_Finish_Bark',segs=10)
            for dx,dy,z,r in [(0,0,4.2,1.8),(.8,.4,3.7,1.3),(-.7,-.4,3.9,1.4)]: b.sphere(r,(x+dx,y+dy,z),mat='M_Finish_Leaves',segs=10,rings=6,scale=(1,1,1.2))
    for x in [-40,40]:
        building(b,x,23,12,23)
        L.collision_box('DistantBuilding'+str(x),coll,root,(12,23,7),(x,23,3.5))
    b.build('Campus_SurfaceAndPlanting',coll,root,bevel=.025)
    L.collision_box('CampusGround',coll,root,(104,126,.2),(0,3,-.25))
    L.empty('MARK_Campus_Entry',coll,root,loc=(0,-30,.1))

def facade(root,coll):
    b=L.MeshBuilder()
    box(b,(15,47,.3),(0,23,-.2),'Stone')
    for x in [-7,7]:
        for z,h in [(.5,1),(3.3,1.2),(6.3,1)]: box(b,(.3,46,h),(x,23,z),'Brick')
        for y in np.arange(0,46.1,3.8): box(b,(.4,.55,6.7),(x,float(y),3.35),'Brick')
        for y in np.arange(1.9,46,3.8):
            for z in [1.9,4.9]:
                box(b,(.1,3.1,1.5),(x,float(y),z),'Glass')
                box(b,(.17,3.25,.12),(x,float(y),z-.8),'Stone')
                box(b,(.15,.06,1.5),(x,float(y),z),'Metal')
    for y in [0,46]:
        box(b,(14,.3,6.7),(0,y,3.35),'Brick')
        for x in [-5,-2.5,2.5,5]:
            for z in [1.9,4.9]: box(b,(1.5,.08,1.5),(x,y-.17,z),'Glass')
    box(b,(14.7,46.7,.3),(0,23,6.85),'Stone')
    for x in [-7.25,7.25]:
        box(b,(.16,46.8,.15),(x,23,6.9),'Metal')
        for y in [.4,23,45.6]: b.cyl(.055,6.8,(x,y,3.4),mat='M_Finish_Metal',segs=10)
    for y in [10,27,39]:
        box(b,(1.6,2.0,.8),(0,y,7.4),'Metal');box(b,(2.0,2.4,.12),(0,y,7.85),'Stone')
    box(b,(3,.08,2.45),(0,-.25,1.22),'Metal');box(b,(2.65,.06,2.1),(0,-.32,1.25),'Glass')
    box(b,(4.8,3.8,.2),(0,-1.3,2.85),'Stone')
    for x in [-2.1,2.1]: b.cyl(.09,2.7,(x,-2.8,1.35),mat='M_Finish_Metal',segs=12)
    b.build('Hospital_Facade',coll,root,bevel=.025)
    L.collision_box('HospitalGround',coll,root,(15,47,.2),(0,23,-.2))
    for x in [-7,7]: L.collision_box('ExteriorWall_'+str(x),coll,root,(.3,46,6.7),(x,23,3.35))
    for y in [0,46]: L.collision_box('ExteriorWall_'+str(y),coll,root,(14,.3,6.7),(0,y,3.35))
    L.empty('MARK_Hospital_Entrance',coll,root,loc=(0,-2,0))

def apartment(root,coll):
    b=L.MeshBuilder();box(b,(10,8,.2),(0,0,-.1),'Wood')
    box(b,(10,8,.15),(0,0,3.08),'Plaster')
    walls=[((10,.18,3),(0,4,1.5)),((.18,8,3),(-5,0,1.5)),((.18,8,3),(5,0,1.5)),((4.2,.18,3),(-2.9,-4,1.5)),((4.2,.18,3),(2.9,-4,1.5)),((.15,3,3),(1,2.5,1.5))]
    for i,(size,center) in enumerate(walls):
        box(b,size,center,'Plaster');L.collision_box('ApartmentWall%d'%i,coll,root,size,center)
    for y in [-2,1.7]: box(b,(.025,1.8,1.5),(-4.9,y,1.8),'Glass')
    # Ordinary furnishings, no biographical or medical claims.
    box(b,(2.7,1.0,.4),(-2,1,.45),'Sofa');box(b,(2.7,.2,.9),(-2,1.5,.8),'Sofa')
    for x in [-3.3,-.7]: box(b,(.22,1.15,.55),(x,1,.75),'Sofa')
    for x in [-2.85,-2,-1.15]: box(b,(.78,.85,.17),(x,1,.73),'Sofa')
    box(b,(1.6,.8,.1),(-2,-.6,.5),'Wood')
    for x in [-2.6,-1.4]:
        for y in [-.85,-.35]: box(b,(.07,.07,.48),(x,y,.24),'Metal')
    box(b,(1.7,2.1,.4),(3,2,.35),'Wood');box(b,(1.65,2,.25),(3,2,.67),'Plaster');box(b,(1.7,.15,1.1),(3,3.1,.8),'Wood')
    box(b,(2.1,.6,2.0),(3.2,-2,1),'Wood')
    for z in [.2,.85,1.5,2.0]: box(b,(2.1,.6,.08),(3.2,-2,z),'Wood')
    for i in range(11): box(b,(.1,.3,.45),(2.3+i*.16,-2,1.1),'Sofa' if i%2 else 'Brick')
    box(b,(3.5,.65,.9),(-2.7,-3.55,.45),'Plaster');box(b,(3.6,.72,.07),(-2.7,-3.55,.95),'Stone')
    box(b,(.75,.55,.04),(-3.5,-3.55,1.0),'Metal')
    for x in [-1.75,-1.45]:
        for y in [-3.75,-3.4]: b.cyl(.09,.02,(x,y,1.0),mat='M_Finish_Metal',segs=12)
    b.build('Apartment_Interior',coll,root,bevel=.035)
    L.collision_box('ApartmentFloor',coll,root,(10,8,.2),(0,0,-.1))
    L.collision_box('ApartmentCeiling',coll,root,(10,8,.15),(0,0,3.08))
    for name,size,center in [('Sofa',(2.9,1.2,1.2),(-2,1,.6)),('CoffeeTable',(1.6,.8,.6),(-2,-.6,.3)),('Bed',(1.7,2.25,1),(3,2,.5)),('Bookcase',(2.1,.6,2),(3.2,-2,1)),('KitchenCounter',(3.6,.72,1),(-2.7,-3.55,.5))]:
        L.collision_box('Apartment'+name,coll,root,size,center)
    L.light_marker('LIGHTMARK_Apartment_Ceiling',coll,root,(0,0,2.8),kind='omni',energy_hint=1.2,color='#FFF2DE',range_m=8)
    L.empty('MARK_Apartment_Entry',coll,root,loc=(0,-3.2,0))

def uv_and_pack(root):
    for ob in L.descendants(root):
        if ob.type!='MESH' or ob.name.endswith('-colonly'): continue
        bpy.ops.object.select_all(action='DESELECT');ob.select_set(True);bpy.context.view_layer.objects.active=ob
        ob.data.uv_layers.new(name='SurfaceUV');bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.cube_project(cube_size=2);bpy.ops.object.mode_set(mode='OBJECT')
        ob.data.uv_layers.new(name='LightmapUV');ob.data.uv_layers.active_index=1
        bpy.ops.object.mode_set(mode='EDIT');bpy.ops.mesh.select_all(action='SELECT');bpy.ops.uv.smart_project(island_margin=.025);bpy.ops.object.mode_set(mode='OBJECT');ob.data.uv_layers.active_index=0
    finish_materials()

def preview(root,name):
    scene=bpy.context.scene;scene.render.engine='CYCLES';scene.cycles.samples=32;scene.cycles.device='CPU';scene.cycles.use_denoising=False
    scene.render.resolution_x=960;scene.render.resolution_y=640;scene.render.resolution_percentage=100
    world=bpy.data.worlds.new('Daylight');world.use_nodes=True;world.node_tree.nodes['Background'].inputs['Color'].default_value=(.6,.72,.85,1);world.node_tree.nodes['Background'].inputs['Strength'].default_value=.6;scene.world=world
    light=bpy.data.lights.new('Sun','SUN');light.energy=3;sun=bpy.data.objects.new('Sun',light);scene.collection.objects.link(sun);sun.rotation_euler=(.5,-.4,-.6)
    if name=='Apartment':
        light=bpy.data.lights.new('Apartment ceiling softbox','AREA');light.energy=550;light.shape='DISK';light.size=5
        lamp=bpy.data.objects.new('Apartment ceiling softbox',light);scene.collection.objects.link(lamp);lamp.location=(0,0,2.9)
    camera=bpy.data.objects.new('Camera',bpy.data.cameras.new('Camera'));scene.collection.objects.link(camera)
    if name=='CampusGrounds': camera.location=(52,-66,38);target=Vector((0,-20,0));camera.data.lens=40
    elif name=='HospitalExterior': camera.location=(32,-36,22);target=Vector((0,17,2.7));camera.data.lens=35
    else: camera.location=(-3.9,-2.9,2.3);target=Vector((1.6,1.5,1.1));camera.data.lens=18
    camera.rotation_euler=(target-camera.location).to_track_quat('-Z','Y').to_euler();scene.camera=camera
    scene.render.filepath=os.path.join(RENDER,name+'.png');bpy.ops.render.render(write_still=True)

records=[]
for name,builder in [('CampusGrounds',campus),('HospitalExterior',facade),('Apartment',apartment)]:
    L.reset_scene();coll=L.collection(name);root=L.empty('ENV_'+name,coll,props={'category':'environment','display_name':name,'approval_status':'OWNER_APPROVED_2026-10-21'})
    builder(root,coll)
    eye,target=((10,-35,1.7),(0,-12,1.6)) if name=='CampusGrounds' else (((12,-8,1.7),(0,8,2.0)) if name=='HospitalExterior' else ((-3.9,-2.9,1.7),(1.6,1.5,1.1)))
    L.camera_marker('CAM_'+name+'_Review',coll,root,eye,target)
    uv_and_pack(root)
    blend=os.path.join(SRC,'FW_'+name+'.blend');glb=os.path.join(OUT,'ENV_'+name+'.glb')
    L.save_blend(blend);L.export_glb(root,glb)
    rec=L.asset_record(root,blend,glb,name,True,'Original procedural Stage 7 candidate. Surface UV and nonoverlapping secondary UV included.','OWNER_APPROVED_2026-10-21',ROOT)
    rec.update({'authoring_tool':'Blender '+bpy.app.version_string,'generator':'tools/blender/build_stage7_exterior.py','seed':70620,'license':'Original project asset; rights retained by project owner','third_party_art_inputs':[],'sha256':hashlib.sha256(open(glb,'rb').read()).hexdigest()})
    rec['collision']='Box collider proxies (-colonly)'
    records.append(rec)
    if '--render' in sys.argv: preview(root,name)
manifest={'schema_version':1,'assets':records,'textures':{n:hashlib.sha256(open(os.path.join(TEX,n),'rb').read()).hexdigest() for n in sorted(os.listdir(TEX)) if n.endswith('.png')}}
with open(os.path.join(ROOT,'assets/asset_manifest/stage7_environment_manifest.json'),'w') as f: json.dump(manifest,f,indent=2)
central_path=os.path.join(ROOT,'assets/asset_manifest/asset_manifest.json')
with open(central_path) as f: central=json.load(f)
for record in records: central['assets'][record['asset_id']]=record
with open(central_path,'w') as f: f.write(json.dumps(central,indent=2,ensure_ascii=False)+'\n')
print('STAGE7_COMPLETE',[(r['asset_id'],r['triangles_base']) for r in records])
