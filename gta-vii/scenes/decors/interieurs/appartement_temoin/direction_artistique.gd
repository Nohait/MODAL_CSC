extends Node

@export var harmonisation_active := true
@export var details: CompositionMobilier = preload("res://scenes/decors/interieurs/appartement_temoin/details_habites.tres")
@export_group("Matières du témoin")
@export_range(0.0, 1.0, 0.05) var rugosite_mobilier := 0.8
@export_range(0.0, 1.0, 0.05) var reflets_mobilier := 0.2
@export_range(0.0, 1.0, 0.05) var saturation_teintes := 0.65
@export var teinte_canape := Color(0.58, 0.72, 0.78)
@export_group("Dimensions du mobilier")
@export_range(0.5, 1.2, 0.05) var hauteur_canape := 0.85
@export_range(0.3, 0.6, 0.01) var hauteur_table_basse := 0.42
@export_range(0.4, 0.9, 0.01) var hauteur_chevet := 0.58
@export_group("Éclairage du témoin")
@export var couleur_ambiante := Color(0.68, 0.75, 0.82)
@export_range(0.0, 1.0, 0.01) var energie_ambiante := 0.3
@export var couleur_lumiere_generale := Color(0.86, 0.9, 0.95)
@export_range(0.0, 1.0, 0.01) var energie_generale := 0.36

func _enter_tree() -> void:
	# Réutiliser l'isolation du tutoriel : F6 ne remplace pas sa sauvegarde réelle.
	Engine.set_meta("tutoriel_debug_actif", true)

func _ready() -> void:
	get_parent().salle_prete.connect(_preparer, CONNECT_ONE_SHOT)

func _preparer() -> void:
	var niveau := get_parent()
	var victime = niveau.get_node("VictimeTemoin")
	niveau.get_node("VictimManager").surveiller_victime(victime)
	victime.set_ennemis_container(niveau.get_node("SalleFixe/Ennemis"))
	if not harmonisation_active:
		return
	var decor: Node3D = niveau.get_node("SalleFixe")
	var accessoires := details.construire()
	accessoires.add_to_group("details_decor")
	decor.add_child(accessoires)
	for objet: Node in decor.get_children():
		if objet.scene_file_path.ends_with("/loungeSofa.glb"):
			objet.position.z = 8.2
			_dimensionner(objet, hauteur_canape)
			for surface: MeshInstance3D in objet.find_children("*", "MeshInstance3D", true, false):
				for i in surface.mesh.get_surface_count():
					var original := surface.get_active_material(i) as StandardMaterial3D
					if original == null: continue
					var mat := original.duplicate() as StandardMaterial3D
					mat.albedo_color *= teinte_canape
					surface.set_surface_override_material(i, mat)
		elif objet.scene_file_path.ends_with("/tableCoffee.glb"):
			objet.position.z = 8.2
			_dimensionner(objet, hauteur_table_basse)
		elif objet.scene_file_path.ends_with("/cabinetBed.glb"):
			_dimensionner(objet, hauteur_chevet)
	var copies := {}
	for surface: MeshInstance3D in decor.find_children("*", "MeshInstance3D", true, false):
		# Les acteurs et leurs matériaux de dégâts restent intacts, même sous SalleFixe.
		if _appartient_acteur(surface, decor) or surface.mesh == null:
			continue
		for i in surface.mesh.get_surface_count():
			var original := surface.get_active_material(i) as StandardMaterial3D
			if original == null or original.transparency != BaseMaterial3D.TRANSPARENCY_DISABLED or original.emission_enabled:
				continue
			if not copies.has(original):
				var mat := original.duplicate() as StandardMaterial3D
				var couleur := mat.albedo_color
				mat.albedo_color = Color.from_hsv(couleur.h, couleur.s * saturation_teintes, couleur.v, couleur.a)
				# Conserver les métaux, les normales et les textures ; calmer les autres surfaces.
				if mat.metallic < 0.5:
					mat.roughness = maxf(mat.roughness, rugosite_mobilier)
					mat.metallic_specular = minf(mat.metallic_specular, reflets_mobilier)
				copies[original] = mat
			surface.set_surface_override_material(i, copies[original])
	var ambiance: WorldEnvironment = niveau.get_node("Eclairage/Ambiance")
	ambiance.environment = ambiance.environment.duplicate()
	ambiance.environment.ambient_light_color = couleur_ambiante
	ambiance.environment.ambient_light_energy = energie_ambiante
	var soleil: DirectionalLight3D = niveau.get_node("Eclairage/Soleil")
	soleil.light_color = couleur_lumiere_generale
	soleil.light_energy = energie_generale

func _dimensionner(objet: Node3D, hauteur: float) -> void:
	var emplacement := objet.position
	var orientation := Basis.from_euler(objet.rotation)
	preload("res://scenes/decors/interieurs/geometrie_decorative.gd").normaliser(objet, hauteur, true)
	objet.position = emplacement + orientation * objet.position

func _appartient_acteur(noeud: Node, limite: Node) -> bool:
	while noeud != limite:
		if noeud is CharacterBody3D:
			return true
		noeud = noeud.get_parent()
	return false
