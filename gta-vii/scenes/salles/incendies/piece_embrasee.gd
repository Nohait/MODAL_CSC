@tool
extends Resource
class_name PieceEmbrasee

@export var actif := true
@export_range(0.0, 2.0, 0.05) var renfort_lumiere := 1.6
@export_range(0, 40) var volutes_interieures := 22
@export_range(0, 20) var volutes_seuil := 12
@export_range(0.0, 0.6, 0.02) var opacite_fumee := 0.3
@export_range(1.0, 6.0, 0.1) var duree_fumee := 4.0
@export var ajouter_objets_abimes := true
@export_range(0.0, 2.0, 0.05) var braises_mobilier := 0.8

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")
const CADRE = preload("res://assets/modeles/appartements/standing_picture_frame_01/standing_picture_frame_01_1k.gltf")
const LAMPE = preload("res://assets/modeles/appartements/modern_ceiling_lamp_01/modern_ceiling_lamp_01_1k.gltf")

func appliquer(piece: Node3D) -> void:
	if not actif or piece.has_node("FumeeHaute"): return
	var foyer: Node3D = null
	for enfant in piece.get_children():
		if not enfant.name.begins_with("Foyer"): continue
		# Renforcer les sources existantes évite d'ajouter de nouvelles lumières coûteuses.
		enfant.energie *= renfort_lumiere
		if foyer == null: foyer = enfant
	if foyer != null and volutes_interieures > 0:
		var fumee := foyer.get_node("Fumee").duplicate() as CPUParticles3D
		fumee.name = "FumeeHaute"
		piece.add_child(fumee)
		fumee.position = foyer.position + Vector3.UP * 1.2
		_regler_fumee(fumee, volutes_interieures, Vector3(0, 0.35, 0.4))
		fumee.emission_box_extents = Vector3(0.65, 0.18, 0.6)
	if ajouter_objets_abimes:
		_abimer_piece(piece)
	for surface in piece.find_children("*", "MeshInstance3D", true, false):
		if not surface.name.begins_with("Mur") and not surface.name.begins_with("Sol"):
			surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		for i in range(surface.mesh.get_surface_count()):
			var mat: Material = surface.get_active_material(i)
			if mat is ShaderMaterial and mat.shader.resource_path.ends_with("mobilier_appartement.gdshader"):
				# Ces matériaux ont déjà été copiés par AspectPieceInaccessible.
				mat.set_shader_parameter("brulure", 0.9)
				mat.set_shader_parameter("intensite_braises", braises_mobilier)

func habiller_seuil(porte: Node3D) -> void:
	if not actif: return
	var fumee := porte.get_node_or_null("Fumee") as CPUParticles3D
	if fumee == null: return
	# L'air chaud déborde par le haut de l'ouverture vers la salle jouable (+Z).
	porte.nombre_particules_fumee = volutes_seuil
	fumee.position = Vector3(0, 2.05, 0.15)
	_regler_fumee(fumee, volutes_seuil, Vector3(0, 0.2, 1))
	fumee.emission_box_extents = Vector3(0.55, 0.08, 0.08)

func _regler_fumee(fumee: CPUParticles3D, nombre: int, direction: Vector3) -> void:
	fumee.amount = maxi(1, nombre)
	fumee.emitting = nombre > 0
	fumee.scale = Vector3.ONE
	fumee.lifetime = duree_fumee
	fumee.preprocess = duree_fumee
	fumee.direction = direction
	fumee.spread = 25
	fumee.gravity = Vector3(0, 0.04, 0)
	fumee.initial_velocity_min = 0.2
	fumee.initial_velocity_max = 0.45
	fumee.scale_amount_min = 0.65
	fumee.scale_amount_max = 1.15
	fumee.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	# Une rampe propre à chaque émetteur protège les ressources partagées des autres maps.
	var rampe := Gradient.new()
	rampe.offsets = PackedFloat32Array([0, 0.2, 0.65, 1])
	rampe.colors = PackedColorArray([Color(0.15, 0.14, 0.13, 0), Color(0.24, 0.22, 0.2, opacite_fumee), Color(0.2, 0.19, 0.18, opacite_fumee * 0.6), Color(0.18, 0.17, 0.16, 0)])
	fumee.color_ramp = rampe

func _abimer_piece(piece: Node3D) -> void:
	# Le premier sol donne un emplacement intérieur sûr, même dans une pièce en L.
	for sol in piece.surfaces():
		if not sol.name.begins_with("Sol"): continue
		var centre: Vector3 = sol.position
		var lampe: Node3D = LAMPE.instantiate()
		GEOMETRIE.normaliser(lampe, 0.45, false)
		lampe.position += Vector3(centre.x, 2.35, centre.z)
		lampe.rotation.z = 0.35
		piece.add_child(lampe)
		var support := Node3D.new()
		support.name = "CadreTombe"
		piece.add_child(support)
		var cadre: Node3D = CADRE.instantiate()
		GEOMETRIE.normaliser(cadre, 0.35, false)
		support.add_child(cadre)
		support.rotation = Vector3(-PI / 2, 0.55, 0)
		support.position = Vector3(centre.x + 0.7, 0.09, centre.z + 0.6)
		# Après rotation, recaler le point le plus bas évite que le cadre traverse le sol.
		var bas := INF
		for surface in support.find_children("*", "MeshInstance3D", true, false):
			var transfo := Transform3D.IDENTITY
			var parent: Node3D = surface
			while parent != piece:
				transfo = parent.transform * transfo
				parent = parent.get_parent()
			var boite: AABB = transfo * surface.get_aabb()
			bas = minf(bas, boite.position.y)
		if bas != INF: support.position.y += 0.015 - bas
		for objet in [lampe, support]:
			for surface in objet.find_children("*", "MeshInstance3D", true, false):
				for i in range(surface.mesh.get_surface_count()):
					var original: Material = surface.get_active_material(i)
					if original is StandardMaterial3D:
						var mat := original.duplicate() as StandardMaterial3D
						mat.albedo_color *= Color(0.55, 0.5, 0.45)
						mat.roughness = 0.85
						surface.set_surface_override_material(i, mat)
		break
