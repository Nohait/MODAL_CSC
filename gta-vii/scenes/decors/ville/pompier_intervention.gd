@tool
extends Node3D

@export var hauteur_mains := 1.25
@export var avance_mains := 0.55

func _ready() -> void:
	# Attendre que les os du modèle importé aient calculé leur première pose.
	call_deferred("_placer_mains")

func _placer_mains() -> void:
	var squelette: Skeleton3D = $Modele/visual/Armature/Skeleton3D
	# L'origine du modèle n'est pas sous ses bottes : le poser avant de régler ses bras.
	var pied_gauche := squelette.find_bone("mixamorig_LeftFoot")
	var pied_droit := squelette.find_bone("mixamorig_RightFoot")
	var gauche := to_local(squelette.to_global(squelette.get_bone_global_pose(pied_gauche).origin))
	var droit := to_local(squelette.to_global(squelette.get_bone_global_pose(pied_droit).origin))
	$Modele.position.y += 0.075 - minf(gauche.y, droit.y)
	squelette.force_update_all_bone_transforms()
	for cote_gauche in [true, false]:
		var main := squelette.find_bone("mixamorig_LeftHand" if cote_gauche else "mixamorig_RightHand")
		var cible := Vector3(-0.1 if cote_gauche else 0.1, hauteur_mains, -avance_mains)
		cible = squelette.to_local(to_global(cible))
		# Tourner le coude puis l'épaule vers la lance, sans étirer le personnage.
		for passage in 12:
			var os := squelette.get_bone_parent(main)
			for articulation in 2:
				var pose := squelette.get_bone_global_pose(os)
				var position_main := squelette.get_bone_global_pose(main).origin
				var vers_main := (position_main - pose.origin).normalized()
				var vers_cible := (cible - pose.origin).normalized()
				var rotation := Quaternion(vers_main, vers_cible) * pose.basis.get_rotation_quaternion()
				var parent_os := squelette.get_bone_parent(os)
				var rotation_parent := squelette.get_bone_global_pose(parent_os).basis.get_rotation_quaternion()
				squelette.set_bone_pose_rotation(os, rotation_parent.inverse() * rotation)
				os = parent_os
