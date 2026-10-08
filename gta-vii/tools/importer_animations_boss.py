import bpy,re,json,zipfile,tempfile,sys
from pathlib import Path
from mathutils import Matrix,Vector
root=Path(__file__).resolve().parents[1]
downloads=Path.home()/'Downloads'
scratch=Path(sys.argv[sys.argv.index('--')+1]) if '--' in sys.argv else Path(tempfile.mkdtemp(prefix='animations_boss_'))
scratch.mkdir(parents=True,exist_ok=True)
with zipfile.ZipFile(downloads/'Creature Pack.zip') as archive:
 (scratch/'mutant jump attack.fbx').write_bytes(archive.read('mutant jump attack.fbx'))
 (scratch/'mutant dying.fbx').write_bytes(archive.read('mutant dying.fbx'))
 (scratch/'mutant roaring.fbx').write_bytes(archive.read('mutant roaring.fbx'))
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=str(root/'assets/modeles/ennemis/mini_boss/monstre_lave.glb'))
rig=next(o for o in bpy.context.scene.objects if o.type=='ARMATURE'); rig.name='SqueletteBoss'
base_pose={pb.name:pb.matrix_basis.copy() for pb in rig.pose.bones}
baseline={pb.name:(rig.matrix_world@pb.matrix).to_quaternion() for pb in rig.pose.bones}
meshes=[o for o in bpy.context.scene.objects if o.type=='MESH' and any(m.type=='ARMATURE' for m in o.modifiers)]
for o in meshes:
 bpy.context.view_layer.objects.active=o
 dec=o.modifiers.new('Optimisation','DECIMATE');dec.ratio=.15
 bpy.ops.object.modifier_apply(modifier=dec.name)
def hauteur_sol(contact_corps=False):
 deps=bpy.context.evaluated_depsgraph_get()
 objets=[m.evaluated_get(deps) for m in meshes]
 if contact_corps:
  # Couché, une pointe isolée peut toucher le sol tandis que tout le corps flotte.
  hauteurs=sorted((o.matrix_world@v.co).z for o in objets for v in o.data.vertices)
  return hauteurs[int(len(hauteurs)*.05)]
 return min((o.matrix_world@Vector(v)).z for o in objets for v in o.bound_box)
bpy.context.view_layer.update()
sol_initial=hauteur_sol()
# Correspondances anatomiques : les trois vertèbres du monstre sont nommées à l'envers.
mapping={}
for b in rig.data.bones:
 name=re.sub(r'_0\d+$','',b.name)
 name={'Spine02':'Spine','Spine01':'Spine1','Spine':'Spine2','neck':'Neck'}.get(name,name)
 if name not in ['_rootJoint','head_end','headfront']: mapping[b.name]='mixamorig:'+name

def importer(path):
 before=set(bpy.data.objects)
 bpy.ops.import_scene.fbx(filepath=str(path))
 objs=list(set(bpy.data.objects)-before)
 src=next(o for o in objs if o.type=='ARMATURE')
 return src,objs
src,objs=importer(downloads/'Orc Idle.fbx')
bpy.context.scene.frame_set(1)
reference={n:(src.matrix_world@src.pose.bones[n].matrix).to_quaternion() for n in mapping.values()}
for o in objs:bpy.data.objects.remove(o,do_unlink=True)
rest={n:baseline[n] for n in mapping}
clips=[('attente',downloads/'Orc Idle.fbx'),('marche',downloads/'Orc Walk.fbx'),('coup_sol',scratch/'mutant jump attack.fbx'),('salve',downloads/'Standing 2H Magic Attack 03.fbx'),('mort',scratch/'mutant dying.fbx'),('invocation',downloads/'Standing 2H Magic Area Attack 02 (1).fbx'),('colere',scratch/'mutant roaring.fbx')]
lengths={}
rig.animation_data_create()
for label,path in clips:
 src,objs=importer(path)
 source_action=src.animation_data.action
 for tr in rig.animation_data.nla_tracks:tr.mute=True
 start,end=map(int,source_action.frame_range)
 # Garder l'élan, le saut et la réception, pas seulement les jambes en plein vol.
 if label=='coup_sol':end=91
 action=bpy.data.actions.new(label);rig.animation_data_create();rig.animation_data.action=action
 for pb in rig.pose.bones: pb.rotation_mode='QUATERNION';pb.matrix_basis=base_pose[pb.name]
 for f in range(start,end+1):
  bpy.context.scene.frame_set(f)
  rig.pose.bones['Hips_00'].location=base_pose['Hips_00'].to_translation()
  rotations={n:((src.matrix_world@src.pose.bones[sn].matrix).to_quaternion()@reference[sn].inverted()@rest[n]) for n,sn in mapping.items()}
  for pb in rig.pose.bones:
   if pb.name not in rotations:continue
   # Transférer la rotation globale, puis la convertir dans le repère local du squelette cible.
   desired=rig.matrix_world.to_quaternion().inverted()@rotations[pb.name]
   parent_pose=pb.parent.matrix.to_quaternion() if pb.parent else Matrix.Identity(4).to_quaternion()
   parent_rest=pb.parent.bone.matrix_local.to_quaternion() if pb.parent else Matrix.Identity(4).to_quaternion()
   local_rest=parent_rest.inverted()@pb.bone.matrix_local.to_quaternion()
   pb.rotation_quaternion=local_rest.inverted()@parent_pose.inverted()@desired
   bpy.context.view_layer.update()
   pb.keyframe_insert('rotation_quaternion',frame=f-start+1,group=pb.name)
  # Reposer les pieds sur le sol sans faire avancer la collision avec le clip.
  bpy.context.view_layer.update()
  contact=hauteur_sol()
  if label=='mort':
   # Passer doucement du contact des pieds au contact du corps pendant la chute.
   progression=(f-start)/max(end-start,1)
   appui=max(0,min(1,(progression-.35)/.25))
   appui=appui*appui*(3-2*appui)
   contact+=(hauteur_sol(True)-contact)*appui
  ecart=sol_initial-contact
  hips=rig.pose.bones['Hips_00']
  local_rest=hips.parent.bone.matrix_local.inverted()@hips.bone.matrix_local
  repere=rig.matrix_world@hips.parent.matrix@local_rest
  hips.location+=repere.to_3x3().inverted()@Vector((0,0,ecart))
  hips.keyframe_insert('location',frame=f-start+1,group=hips.name)
 lengths[label]=(end-start)/30
 # Chaque piste NLA devient un clip glTF autonome.
 track=rig.animation_data.nla_tracks.new();track.name=label
 strip=track.strips.new(label,1,action);strip.action_frame_start=1;strip.action_frame_end=end-start+1
 rig.animation_data.action=None
 for o in objs:bpy.data.objects.remove(o,do_unlink=True)
rig.animation_data.action=None
for tr in rig.animation_data.nla_tracks:tr.mute=True
for pb in rig.pose.bones:pb.matrix_basis=base_pose[pb.name]
bpy.context.scene.render.fps=30
bpy.context.scene.frame_set(1)
# Exporter uniquement le monstre et sa hiérarchie, sans les personnages de référence.
bpy.ops.object.select_all(action='DESELECT')
for o in [rig]+meshes:
 o.select_set(True)
 p=o.parent
 while p:p.select_set(True);p=p.parent
# Exporter les pistes individuellement.
out=root/'assets/modeles/ennemis/mini_boss/monstre_lave_anime.glb'
bpy.ops.export_scene.gltf(filepath=str(out),export_format='GLB',use_selection=True,export_animations=True,export_animation_mode='NLA_TRACKS',export_force_sampling=True,export_anim_slide_to_zero=True)
(scratch/'durees.json').write_text(json.dumps(lengths))
print('DUREES',lengths)





