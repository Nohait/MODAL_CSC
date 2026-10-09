extends Node3D

const GENERATEUR = preload("res://scenes/salles/room_generator.gd")
const GEOMETRIE = preload("res://outils/validation/controle_geometrie.gd")
const PASSAGES = preload("res://outils/validation/controle_passages.gd")

@export_range(1, 1000) var nombre_salles := 300
@export var premiere_graine := 810000
@export var tailles: Array[Vector2i] = [Vector2i(10, 8), Vector2i(6, 6), Vector2i(14, 12), Vector2i(20, 20)]
@export_range(1, 150) var nombre_arrivants := 62
@export_range(0.1, 1.0, 0.05) var rayon_personnage := 0.5
@export_range(1.0, 3.0, 0.1) var hauteur_personnage := 2.0
@export var dossier_rapports := "user://audit_generation"
@export var verifier_reproductibilite := true
@export_group("Rejouer un cas du rapport")
@export_file("*.json") var fichier_reproduction := ""
@export_range(0, 999) var indice_cas := 0

var resultats: Array[Dictionary] = []
var panneau: Label
var cas_rejoue: Dictionary = {}
var autocontrole := false

func _ready() -> void:
	# Cette scène de travail ne lance ni partie, ni combat, ni sauvegarde de progression.
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--nombre="): nombre_salles = maxi(1, argument.trim_prefix("--nombre=").to_int())
		elif argument.begins_with("--graine="): premiere_graine = argument.trim_prefix("--graine=").to_int()
		elif argument.begins_with("--rapport="): dossier_rapports = argument.trim_prefix("--rapport=")
		elif argument.begins_with("--reproduire="): fichier_reproduction = argument.trim_prefix("--reproduire=")
		elif argument.begins_with("--cas="): indice_cas = argument.trim_prefix("--cas=").to_int()
		elif argument == "--autocontrole": autocontrole = true
	if autocontrole: nombre_salles = 1
	if not fichier_reproduction.is_empty():
		var fichier := FileAccess.open(fichier_reproduction, FileAccess.READ)
		var rapport = JSON.parse_string(fichier.get_as_text()) if fichier != null else null
		if not rapport is Dictionary or not rapport.get("cas") is Array or indice_cas < 0 or indice_cas >= rapport.cas.size():
			push_error("Rapport de reproduction invalide ou indice hors limites.")
			get_tree().quit(2)
			return
		cas_rejoue = rapport.cas[indice_cas].duplicate(true)
		nombre_salles = 1
	panneau = Label.new()
	panneau.position = Vector2(24, 24)
	add_child(panneau)
	_lancer.call_deferred()

func _lancer() -> void:
	if tailles.is_empty():
		push_error("Ajouter au moins une taille de salle dans l'Inspector.")
		get_tree().quit(2)
		return
	var debut := Time.get_ticks_msec()
	for i in range(nombre_salles):
		var cas := _scenario(i) if cas_rejoue.is_empty() else cas_rejoue.duplicate(true)
		var generateur = GENERATEUR.new()
		generateur.roomSize = Vector2i(cas.largeur, cas.profondeur)
		seed(cas.graine)
		var salle: Node3D = generateur.generer_salle(cas.arrivants, cas.fin_etage, cas.etage, cas.debut_etage)
		var signature := _signature(generateur, salle)
		var reproductible := true
		if verifier_reproductibilite:
			# Recréer hors de l'arbre évite tout son ou animation pendant la comparaison.
			var autre_generateur = GENERATEUR.new()
			autre_generateur.roomSize = Vector2i(cas.largeur, cas.profondeur)
			seed(cas.graine)
			var autre_salle: Node3D = autre_generateur.generer_salle(cas.arrivants, cas.fin_etage, cas.etage, cas.debut_etage)
			reproductible = signature == _signature(autre_generateur, autre_salle)
			autre_salle.free()
			autre_generateur.free()
		# Ouvrir les portes de test pour contrôler le passage une fois la salle libérée.
		for porte in salle.get_node("Portes").get_children():
			porte.get_node("Charniere").rotation_degrees.y = porte.angle_ouverture
		add_child(salle)
		if autocontrole: _introduire_defauts(generateur, salle)
		for son in salle.find_children("*", "AudioStreamPlayer3D", true, false): son.stop()
		await get_tree().physics_frame
		await get_tree().physics_frame
		salle.cuire_navigation()
		# L'attribution du maillage et sa synchronisation sont deux étapes distinctes.
		await get_tree().process_frame
		await get_tree().physics_frame
		await get_tree().physics_frame
		# Chaque essai utilise ses propres cartes, alimentées par les vrais maillages cuits.
		# Aucune salle précédente ne peut influencer une recherche de chemin.
		var cartes: Array[RID] = []
		var regions: Array[RID] = []
		for noeud in [salle.get_node("Navigation"), salle.get_node("NavigationEnnemis")]:
			var carte := NavigationServer3D.map_create()
			NavigationServer3D.map_set_cell_size(carte, noeud.navigation_mesh.cell_size)
			NavigationServer3D.map_set_cell_height(carte, noeud.navigation_mesh.cell_height)
			NavigationServer3D.map_set_active(carte, true)
			var region := NavigationServer3D.region_create()
			NavigationServer3D.region_set_map(region, carte)
			NavigationServer3D.region_set_navigation_mesh(region, noeud.navigation_mesh)
			NavigationServer3D.region_set_transform(region, noeud.global_transform)
			NavigationServer3D.map_force_update(carte)
			cartes.append(carte)
			regions.append(region)
		var navigation_prete := false
		for tentative in range(120):
			if NavigationServer3D.map_get_iteration_id(cartes[0]) > 0 and NavigationServer3D.map_get_iteration_id(cartes[1]) > 0 and NavigationServer3D.map_get_closest_point_owner(cartes[0], salle.entree.global_position).is_valid() and NavigationServer3D.map_get_closest_point_owner(cartes[1], salle.entree.global_position).is_valid():
				navigation_prete = true
				break
			await get_tree().create_timer(0.01).timeout
		var problemes := GEOMETRIE.verifier(generateur, salle)
		if not reproductible: problemes.append({"type": "generation_non_reproductible"})
		if navigation_prete:
			problemes.append_array(PASSAGES.verifier(salle, rayon_personnage, hauteur_personnage, cartes))
		else:
			problemes.append({"type": "navigation_non_synchronisee"})
		if salle.points_arrivee.size() < cas.arrivants:
			problemes.append({"type": "arrivees_insuffisantes", "disponibles": salle.points_arrivee.size(), "demandes": cas.arrivants})
		if salle.get_node("Portes").get_child_count() == 0:
			problemes.append({"type": "aucune_sortie"})
		for debris in salle.get_node("Habillage").get_children():
			if str(debris.name).begins_with("PetitsGravats") and not debris.find_children("*", "CollisionShape3D", true, false).is_empty():
				problemes.append({"type": "petits_gravats_avec_collision"})
		cas["problemes"] = problemes
		resultats.append(cas)
		for region in regions: NavigationServer3D.free_rid(region)
		for carte in cartes: NavigationServer3D.free_rid(carte)
		salle.free()
		generateur.free()
		if (i + 1) % 10 == 0 or i == nombre_salles - 1:
			panneau.text = "Salles contrôlées : %d / %d" % [i + 1, nombre_salles]
			print(panneau.text)
		await get_tree().process_frame
	var echecs := 0
	var compteurs := {}
	for cas in resultats:
		if not cas.problemes.is_empty(): echecs += 1
		for probleme in cas.problemes:
			compteurs[probleme.type] = compteurs.get(probleme.type, 0) + 1
	var rapport := {"salles": nombre_salles, "salles_avec_problemes": echecs, "duree_secondes": (Time.get_ticks_msec() - debut) / 1000.0, "types": compteurs, "cas": resultats}
	DirAccess.make_dir_recursive_absolute(dossier_rapports)
	var fichier := FileAccess.open(dossier_rapports.path_join("rapport.json"), FileAccess.WRITE)
	if fichier == null:
		push_error("Impossible d'écrire le rapport d'audit.")
		get_tree().quit(2)
		return
	fichier.store_string(JSON.stringify(rapport, "\t"))
	fichier.close()
	print("AUDIT : %d / %d salles avec problèmes. %s" % [echecs, nombre_salles, str(compteurs)])
	print("Rapport : ", ProjectSettings.globalize_path(dossier_rapports.path_join("rapport.json")))
	if autocontrole:
		var attendus := ["meuble_dans_mur", "meubles_superposes", "spawn_obstrue", "entree_inaccessible"]
		for attendu in attendus:
			if not compteurs.has(attendu):
				push_error("Le banc n'a pas détecté le défaut volontaire : " + attendu)
				get_tree().quit(2)
				return
		print("AUTOCONTRÔLE : les quatre défauts volontaires ont bien été détectés.")
		get_tree().quit(0)
	else:
		get_tree().quit(0 if echecs == 0 else 1)

func _scenario(indice: int) -> Dictionary:
	# Alterner tailles, étages, escaliers et effectifs ; tout est inscrit dans le rapport.
	var taille := tailles[indice % tailles.size()]
	var etage := 1 + (indice / tailles.size()) % 3
	return {"graine": premiere_graine + indice, "largeur": taille.x, "profondeur": taille.y, "etage": etage, "arrivants": nombre_arrivants if indice % 2 == 0 else 10, "fin_etage": indice % 5 == 4, "debut_etage": etage > 1 and indice % 5 == 0}

func _signature(generateur: Node3D, salle: Node3D) -> String:
	var placements: Array = []
	for branche in ["Navigation/Decor", "Habillage", "Portes"]:
		var conteneur := salle.get_node_or_null(branche)
		if conteneur == null: continue
		for enfant in conteneur.get_children():
			if enfant is Node3D:
				placements.append([enfant.get_class(), enfant.scene_file_path, str(enfant.transform)])
	return var_to_str([generateur.grid, salle.points_arrivee, salle.points_spawn, placements])

func _introduire_defauts(generateur: Node3D, salle: Node3D) -> void:
	# Seulement pour tester les détecteurs : ces instances ne sont jamais utilisées en jeu.
	var bord: Array = generateur.bords_habillage[0]
	var normale := Vector3(bord[1].x, 0, bord[1].y)
	var position_mur: Vector3 = generateur.position_cellule(bord[0]) + normale * 2.5 + Vector3.UP * 0.6
	for i in range(2):
		var caisse = GENERATEUR.BOX_SCENE.instantiate()
		caisse.position = position_mur
		salle.get_node("Navigation/Decor").add_child(caisse)
	generateur.creer_bloc(salle.points_spawn[0] + Vector3.UP * 1.1, Vector3(1, 2, 1), Color.WHITE)
	# Fermer entièrement le couloir d'entrée coupe réellement les chemins, pas seulement les points.
	var taille := Vector3(2.5, 3, 0.5)
	if absf(salle.entree.rotation.y) > 0.1: taille = Vector3(0.5, 3, 2.5)
	generateur.creer_bloc(salle.entree.to_global(Vector3(0, 1.6, 0)), taille, Color.WHITE)
