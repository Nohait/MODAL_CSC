@tool
extends Resource
class_name FinitionsParcours

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

@export var actif := true
@export var regrouper_finitions := true
@export var bois: Material = preload("res://assets/materiaux/appartements/bois_finitions.tres")
@export var teintes: Array[Color] = [Color(0.59, 0.62, 0.57), Color(0.48, 0.58, 0.6), Color(0.56, 0.57, 0.63)]
@export_range(0.3, 0.8, 0.05) var hauteur_soubassement := 0.7
@export_range(0.03, 0.12, 0.01) var hauteur_moulure := 0.05
@export_range(0.05, 0.2, 0.01) var hauteur_plinthe := 0.1

func appliquer(generateur: Node3D, decor: Node3D, etage: int) -> void:
	if not actif or teintes.is_empty(): return
	var peinture := StandardMaterial3D.new()
	peinture.albedo_color = teintes[clampi(etage - 1, 0, teintes.size() - 1)]
	peinture.roughness = 0.75
	var finitions := Node3D.new()
	finitions.name = "FinitionsParcours"
	decor.add_child(finitions)
	var faces_traitees: Dictionary = {}
	# Lire les morceaux réels : une porte découpée reste libre, même après le nettoyage des murs.
	for bord in generateur.bords_habillage:
		var normale := Vector3(bord[1].x, 0, bord[1].y)
		var centre: Vector3 = generateur.position_cellule(bord[0]) + normale * 2.5
		for corps in generateur.salle_en_creation.get_node("Navigation/Decor").get_children():
			if not corps.scene_file_path.is_empty(): continue
			for surface in corps.get_children():
				if not surface is MeshInstance3D or not surface.mesh is BoxMesh: continue
				var boite: AABB = corps.transform * surface.transform * surface.get_aabb()
				var axe := 0 if normale.x != 0 else 2
				var tangent := 2 if axe == 0 else 0
				if boite.size[axe] > 0.21 or absf(boite.get_center()[axe] - centre[axe]) > 0.02: continue
				if absf(boite.get_center()[tangent] - centre[tangent]) > 2.5 or boite.position.y > 0.11: continue
				# Un morceau près d'une jonction peut être trouvé depuis deux cellules voisines.
				var cle := "%d:%s" % [surface.get_instance_id(), normale]
				if faces_traitees.has(cle): continue
				faces_traitees[cle] = true
				var hauteur := minf(hauteur_soubassement, boite.size.y)
				var position := boite.get_center()
				position[axe] -= normale[axe] * (boite.size[axe] / 2 + 0.012)
				position.y = boite.position.y + (hauteur_plinthe + hauteur - hauteur_moulure) / 2
				var taille := boite.size
				taille[axe] = 0.02
				taille[tangent] = maxf(0.01, taille[tangent] - 0.004)
				taille.y = maxf(0.01, hauteur - hauteur_plinthe - hauteur_moulure - 0.004)
				GEOMETRIE.bloc(finitions, "Soubassement", position, taille, peinture)
				# Les baguettes dépassent de quelques millimètres ; aucune face ne se superpose au mur.
				taille[axe] = 0.035
				taille.y = hauteur_plinthe
				position.y = boite.position.y + hauteur_plinthe / 2
				GEOMETRIE.bloc(finitions, "Plinthe", position, taille, bois)
				if hauteur < hauteur_soubassement: continue
				taille.y = hauteur_moulure
				position.y = boite.position.y + hauteur - hauteur_moulure / 2
				GEOMETRIE.bloc(finitions, "Moulure", position, taille, bois)

	if regrouper_finitions: _regrouper(finitions)

func _regrouper(parent: Node3D) -> void:
	var groupes: Dictionary = {}
	# Un cube partagé par matériau remplace les nombreux petits meshes statiques.
	for surface: MeshInstance3D in parent.get_children():
		var materiau := surface.get_active_material(0)
		var cle := materiau.get_instance_id()
		if not groupes.has(cle): groupes[cle] = []
		groupes[cle].append(surface)
	for surfaces: Array in groupes.values():
		var instances := MultiMesh.new()
		instances.transform_format = MultiMesh.TRANSFORM_3D
		var cube := BoxMesh.new()
		cube.size = Vector3.ONE
		cube.material = surfaces[0].get_active_material(0)
		instances.mesh = cube
		instances.instance_count = surfaces.size()
		for i in range(surfaces.size()):
			var surface: MeshInstance3D = surfaces[i]
			# Le cube unitaire reprend exactement la position et les dimensions de chaque baguette.
			var dimensions := Transform3D(Basis.from_scale(surface.mesh.size), Vector3.ZERO)
			instances.set_instance_transform(i, surface.transform * dimensions)
		var lot := MultiMeshInstance3D.new()
		lot.name = "FinitionsRegroupees"
		lot.multimesh = instances
		lot.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		parent.add_child(lot)
		for surface: MeshInstance3D in surfaces:
			parent.remove_child(surface)
			surface.free()
