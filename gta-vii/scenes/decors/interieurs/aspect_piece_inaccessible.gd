@tool
extends Resource
class_name AspectPieceInaccessible

@export var ombres_mobilier := false
@export_range(0.1, 1.0, 0.05) var detail_mobilier := 0.35
@export var teinte_sols := Color(0.43, 0.47, 0.52)
@export var teinte_murs := Color(0.65, 0.68, 0.72)
@export var teinte_mobilier := Color(0.7, 0.73, 0.77)
@export_range(0.0, 1.0, 0.05) var intensite_lumieres := 0.4
@export_range(0.0, 1.0, 0.05) var intensite_braises := 0.2

func appliquer(piece: Node3D) -> void:
	var copies := {}
	# Appelé après le ready des meubles : leurs scripts ont déjà installé leurs matériaux.
	for surface in piece.find_children("*", "MeshInstance3D", true, false):
		var sol: bool = surface.name.begins_with("Sol")
		var mur: bool = surface.name.begins_with("Mur") or surface.name.begins_with("Cloison") or surface.name.begins_with("Facade") or surface.name.begins_with("Linteau")
		# Les LOD importés réduisent les triangles du mobilier secondaire, sans changer ses textures.
		if not sol and not mur: surface.lod_bias = detail_mobilier
		if not sol and not mur and not ombres_mobilier:
			surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var teinte := teinte_sols if sol else (teinte_murs if mur else teinte_mobilier)
		for i in range(surface.mesh.get_surface_count()):
			var original: Material = surface.get_active_material(i)
			if original == null: continue
			var cle := str(original.get_instance_id()) + str(teinte)
			if not copies.has(cle):
				var mat: Material = original.duplicate()
				if mat is StandardMaterial3D:
					mat.albedo_color *= teinte
					if sol: mat.roughness = maxf(mat.roughness, 0.9)
				elif mat is ShaderMaterial:
					var couleur = mat.get_shader_parameter("teinte")
					if couleur is Color: mat.set_shader_parameter("teinte", couleur * teinte)
					var braises = mat.get_shader_parameter("intensite_braises")
					if braises is float: mat.set_shader_parameter("intensite_braises", braises * intensite_braises)
				copies[cle] = mat
			surface.set_surface_override_material(i, copies[cle])
	for lumiere in piece.find_children("*", "Light3D", true, false):
		var foyer := lumiere.get_parent()
		if foyer.scene_file_path.ends_with("foyer_incendie.tscn"):
			# Le vacillement utilise energie à chaque image : modifier sa source, pas sa valeur instantanée.
			foyer.energie *= intensite_lumieres
		else:
			lumiere.light_energy *= intensite_lumieres
		lumiere.shadow_enabled = false
