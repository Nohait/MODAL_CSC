@tool
extends Resource
class_name AmenagementPiece

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")
const ARMOIRE = preload("res://assets/modeles/appartements/modern_wooden_cabinet/modern_wooden_cabinet_1k.gltf")
const CHAISE = preload("res://assets/modeles/interieurs/dining_chair_02/dining_chair_02_1k.gltf")
const ETAGERE = preload("res://assets/modeles/interieurs/worn_metal_rack/worn_metal_rack_1k.gltf")
const COMPTEUR = preload("res://assets/modeles/interieurs/utility_box_02/utility_box_02_1k.gltf")

@export_range(3.0, 6.0, 0.2) var espacement_mobilier := 4.8
@export_range(1, 6) var ensembles_par_piece := 4
@export_range(0.0, 1.0, 0.05) var chance_objets_abandonnes := 0.85
@export var compositions: Array[Resource] = []
@export_range(0.1, 1.0, 0.05) var marge_mobilier := 0.4
@export var objets_abandonnes: Array[PackedScene] = [preload("res://scenes/decors/interieurs/evacuation_valise.tscn"), preload("res://scenes/decors/interieurs/evacuation_sac.tscn"), preload("res://scenes/decors/interieurs/evacuation_chaise.tscn")]

func remplir(parent: Node3D, zone: Rect2, mobilier: Array, indice: int, hasard: RandomNumberGenerator) -> Array[Node3D]:
	var ensembles: Array[Node3D] = []
	var piece := Node3D.new()
	# Ces noms décrivent la mise en scène dans l'arbre, sans ajouter de texte dans le jeu.
	piece.name = ["DepartPrecipite", "RepasInterrompu", "MobilierBouscule"][indice % 3]
	parent.add_child(piece)
	var colonnes := maxi(1, floori(zone.size.x / espacement_mobilier))
	var lignes := maxi(1, floori(zone.size.y / espacement_mobilier))
	var emplacement := zone.size / Vector2(colonnes, lignes)
	if not compositions.is_empty():
		# Les grands espaces peuvent accueillir deux ensembles, les petits un seul.
		var nombre := mini(2, mini(ensembles_par_piece, maxi(1, floori(zone.get_area() / 45.0))))
		var axe := 0 if zone.size.x > zone.size.y else 1
		for i in range(nombre):
			var secteur := zone
			secteur.size[axe] /= nombre
			secteur.position[axe] += i * secteur.size[axe]
			var choix := hasard.randi_range(0, compositions.size() - 1)
			var precedent := int(parent.get_meta("composition_precedente", -1))
			if choix == precedent and compositions.size() > 1: choix = (choix + 1) % compositions.size()
			var recette = compositions[choix]
			var ensemble: Node3D = recette.construire()
			var boite: AABB = recette.limites(ensemble)
			var angle := hasard.randi_range(0, 3) * PI / 2
			var rotation := Basis(Vector3.UP, angle)
			var empreinte: AABB = Transform3D(rotation, Vector3.ZERO) * boite
			var disponible := secteur.size - Vector2.ONE * marge_mobilier * 2
			var facteur := minf(1.0, minf(disponible.x / maxf(empreinte.size.x, 0.01), disponible.y / maxf(empreinte.size.z, 0.01)))
			# Refuser un ensemble trop grand plutôt que transformer un bureau en miniature.
			if facteur < 0.8:
				ensemble.free()
				# Chercher une composition plus compacte si le premier choix ne tient pas.
				for essai in range(1, compositions.size()):
					choix = (choix + 1) % compositions.size()
					recette = compositions[choix]
					ensemble = recette.construire()
					boite = recette.limites(ensemble)
					empreinte = Transform3D(rotation, Vector3.ZERO) * boite
					facteur = minf(1.0, minf(disponible.x / maxf(empreinte.size.x, 0.01), disponible.y / maxf(empreinte.size.z, 0.01)))
					if facteur >= 0.8: break
					ensemble.free()
				if facteur < 0.8: continue
			ensemble.rotation.y = angle
			ensemble.scale = Vector3.ONE * facteur
			var centre := secteur.get_center()
			var decalage := empreinte.get_center() * facteur
			var jeu := (disponible - Vector2(empreinte.size.x, empreinte.size.z) * facteur) / 2
			ensemble.position = Vector3(centre.x - decalage.x + hasard.randf_range(-jeu.x, jeu.x), 0.1, centre.y - decalage.z + hasard.randf_range(-jeu.y, jeu.y))
			_sans_collision(ensemble)
			piece.add_child(ensemble)
			parent.set_meta("composition_precedente", choix)
			ensembles.append(ensemble)
	elif minf(emplacement.x, emplacement.y) >= 4.6 and not mobilier.is_empty():
		for i in range(mini(colonnes * lignes, ensembles_par_piece)):
			var ensemble: Node3D = mobilier[(indice + i) % mobilier.size()].instantiate()
			var centre := zone.position + (Vector2(i % colonnes, i / colonnes) + Vector2.ONE * 0.5) * emplacement
			ensemble.position = Vector3(centre.x, 0.1, centre.y)
			ensemble.rotation.y = PI if i % 2 == 1 else 0.0
			_sans_collision(ensemble)
			piece.add_child(ensemble)
			ensembles.append(ensemble)
	else:
		# Les bandes étroites deviennent des rangements, pas de grands salons miniaturisés.
		var rangement: PackedScene = ARMOIRE
		for scene: PackedScene in mobilier:
			if scene.resource_path.ends_with("stockage_technique.tscn"): rangement = ETAGERE
			if scene.resource_path.ends_with("poste_electrique.tscn"):
				rangement = COMPTEUR
				break
		for i in range(maxi(1, floori(zone.size.y / 3.0))):
			var support := Node3D.new()
			support.position = Vector3(zone.position.x + 0.85, 0.1, zone.position.y + (i + 0.5) * zone.size.y / maxi(1, floori(zone.size.y / 3.0)))
			piece.add_child(support)
			var modele: Node3D = (rangement if i % 2 == 0 else CHAISE).instantiate()
			support.add_child(modele)
			GEOMETRIE.normaliser(modele, 1.3 if i % 2 == 0 else 0.95, true)
	if not objets_abandonnes.is_empty() and hasard.randf() < chance_objets_abandonnes:
		# Une valise près du passage, des papiers ou une chaise tombée racontent la fuite.
		var objet: Node3D = objets_abandonnes[indice % objets_abandonnes.size()].instantiate()
		objet.position = Vector3(zone.get_center().x + minf(0.9, zone.size.x / 2 - 1.1), 0.1, zone.end.y - 1.0)
		objet.rotation.y = hasard.randf_range(-0.7, 0.7)
		piece.add_child(objet)
	return ensembles

func _sans_collision(ensemble: Node3D) -> void:
	for collision in ensemble.find_children("*", "CollisionShape3D", true, false): collision.disabled = true
	var corps: Array = ensemble.find_children("*", "CollisionObject3D", true, false)
	if ensemble is CollisionObject3D: corps.append(ensemble)
	for element in corps:
		element.collision_layer = 0
		element.collision_mask = 0
		element.remove_from_group("collider")
