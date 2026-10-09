extends RefCounted

const IMMEUBLES = [preload("res://assets/modeles/decors/ville/Building_Small_1.gltf"), preload("res://assets/modeles/decors/ville/Building_Medium_2_001.gltf"), preload("res://assets/modeles/decors/ville/Building_Large_2.gltf"), preload("res://assets/modeles/decors/ville/nyc_building/scene.gltf"), preload("res://assets/modeles/decors/ville/modern_building_002/scene.gltf")]
const ASPECT_RUE = preload("res://assets/materiaux/hall_incendie/asphalte_ville.tres")
const ASPECT_TROTTOIR = preload("res://assets/materiaux/hall_incendie/trottoir_ville.tres")
const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")
const ASPHALTE = preload("res://assets/shaders/decors/asphalte_lointain.gdshader")
const PROFIL_VILLE = preload("res://scenes/salles/exterieur_etage_1.tres")
const LAMPADAIRE = preload("res://assets/modeles/decors/ville/intervention/street_lamp_01.glb")

# Un plan composé à la main : la tour reste un repère unique, pas un motif répété.
const PLANS_ILOTS = [
	[3, 0, 1, 2, 1, 0], [2, 1, 0, 0, 2, 3],
	[0, 2, 1, 3, 0, 1], [1, 0, 3, 2, 1, 2],
	[2, 0, 1, 1, 3, 0], [0, 1, 2, 4, 2, 1],
	[1, 2, 0, 0, 1, 3], [3, 1, 2, 2, 0, 1]
]
const TEINTES_FACADES = [Color(0.87, 0.84, 0.8), Color(0.84, 0.9, 0.96), Color(0.97, 0.91, 0.83), Color(0.83, 0.85, 0.84)]

static func bord_expose(generateur: Node3D, cellule: Vector2i, direction: Vector2i) -> bool:
	var voisine := cellule + direction
	while voisine.x >= 0 and voisine.y >= 0 and voisine.x < generateur.roomSize.x and voisine.y < generateur.roomSize.y:
		if generateur.grid[voisine.y][voisine.x]: return false
		voisine += direction
	return true

static func construire(generateur: Node3D, decor: Node3D, profil: ExterieurEtage, _hasard: RandomNumberGenerator) -> void:
	if profil == null or generateur.habillage.batiment == null: return
	var cadre: Rect2 = generateur.habillage.batiment.limites(generateur)
	var cote := cadre.size.x
	# Le manager déplace une seule ville entre les salles ; aucune copie lors du préchargement.
	generateur.salle_en_creation.set_meta("cadre_ville", cadre)
	generateur.salle_en_creation.set_meta("hauteur_ville", profil.hauteur_sur_rue)
	# Les étages inférieurs suivent le carré du bâtiment, pas le contour du niveau.
	for axe in range(2):
		for signe in [-1, 1]:
			var position := Vector3(cadre.get_center().x, -profil.hauteur_sur_rue / 2, cadre.get_center().y)
			var taille := Vector3(cote, profil.hauteur_sur_rue, 0.25) if axe == 0 else Vector3(0.25, profil.hauteur_sur_rue, cote)
			if axe == 0: position.z += signe * cote / 2
			else: position.x += signe * cote / 2
			GEOMETRIE.bloc(decor, "FacadeEtagesInferieurs", position, taille, generateur.materiau_murs)

static func _quartier(cote: float) -> Node3D:
	var ville := Node3D.new()
	var profil := PROFIL_VILLE
	var pas: float = cote + profil.largeur_chaussee + profil.largeur_trottoir * 2
	var rue := ShaderMaterial.new()
	rue.shader = ASPHALTE
	rue.set_shader_parameter("couleur", ASPECT_RUE.albedo_texture)
	rue.set_shader_parameter("teinte", Color(0.55, 0.55, 0.55))
	rue.set_shader_parameter("taille_texture", profil.taille_texture_rue)
	var trottoir: StandardMaterial3D = ASPECT_TROTTOIR.duplicate()
	var peinture := StandardMaterial3D.new()
	peinture.albedo_color = Color(0.65, 0.63, 0.53)
	peinture.roughness = 0.95
	# Des rues réellement délimitées, au lieu d'une immense nappe d'asphalte.
	for axe in range(2):
		for signe in [-1, 1]:
			var position := Vector3(0, 0, signe * pas / 2) if axe == 0 else Vector3(signe * pas / 2, 0, 0)
			var taille := Vector3(pas * 3, 0.15, profil.largeur_chaussee) if axe == 0 else Vector3(profil.largeur_chaussee, 0.15, pas * 3)
			GEOMETRIE.bloc(ville, "Route", position, taille, rue)
			for i in range(-floori(pas * 1.5 / 8), floori(pas * 1.5 / 8)):
				# Interrompre le marquage aux carrefours, plutôt que croiser deux lignes.
				if absf(absf(i * 8.0) - pas / 2) < profil.largeur_chaussee / 2 + 2: continue
				var point := position + (Vector3.RIGHT if axe == 0 else Vector3.BACK) * (i * 8.0)
				point.y = 0.081
				GEOMETRIE.bloc(ville, "LigneDiscontinue", point, Vector3(3.5, 0.01, 0.12) if axe == 0 else Vector3(0.12, 0.01, 3.5), peinture)
	var ilot := 0
	var incendies := 0
	for y in range(-1, 2):
		for x in range(-1, 2):
			var centre := Vector3(x * pas, 0.12, y * pas)
			if x == 0 and y == 0:
				for axe in range(2):
					for signe in [-1, 1]:
						var normale := Vector3(0, 0, signe) if axe == 0 else Vector3(signe, 0, 0)
						var taille := Vector3(cote + profil.largeur_trottoir * 2, 0.18, profil.largeur_trottoir) if axe == 0 else Vector3(profil.largeur_trottoir, 0.18, cote)
						GEOMETRIE.bloc(ville, "Trottoir", centre + normale * (cote / 2 + profil.largeur_trottoir / 2), taille, trottoir)
				continue
			GEOMETRIE.bloc(ville, "Ilot", centre, Vector3(cote + profil.largeur_trottoir * 2, 0.18, cote + profil.largeur_trottoir * 2), trottoir)
			var nombre: int = profil.immeubles_par_ligne * profil.rangees_par_ilot
			for i in range(nombre):
				var indice := ((x + 1) * nombre * 3 + (y + 1) * nombre + i)
				var parcelle := _parcelle(cote, i, ilot, profil)
				var emplacement := parcelle.size
				var choix: int = PLANS_ILOTS[ilot][i % 6]
				var support := Node3D.new()
				support.name = "Immeuble%d" % indice
				support.position = centre + Vector3(parcelle.get_center().x, 0.09, parcelle.get_center().y)
				# Les façades regardent les rues ; leurs retraits varient dans chaque parcelle.
				support.rotation.y = 0.0 if y < 0 else (PI if y > 0 else (-PI / 2 if x > 0 else PI / 2))
				ville.add_child(support)
				var modele: Node3D = IMMEUBLES[choix].instantiate()
				support.add_child(modele)
				var hauteur: float = profil.hauteur_immeubles * [0.8, 1.1, 0.95, 1.25, 0.85, 1.05][(i + ilot) % 6]
				if choix == 4:
					# Retirer les dalles fournies avec ce modèle : nos trottoirs font déjà ce travail.
					for surface in modele.find_children("*", "MeshInstance3D", true, false):
						if surface.name.begins_with("material-211757343") or surface.name.begins_with("material-2117080872"):
							surface.free()
					hauteur = profil.hauteur_tour_moderne
				var dimensions := GEOMETRIE.normaliser(modele, hauteur, true)
				# Garder les proportions, sans empiéter sur la chaussée ni les voisins.
				var facteur := minf(1.0, (minf(emplacement.x, emplacement.y) - 2.0) / maxf(dimensions.x, dimensions.z))
				modele.scale *= facteur
				modele.position *= facteur
				# Une marge conservatrice reste valable après la rotation de 90° du modèle.
				var marge := emplacement - Vector2.ONE * maxf(dimensions.x, dimensions.z) * facteur
				support.position.x += minf(3.0, maxf(0, marge.x / 2 - 1)) * (-1 if i % 2 == 0 else 1)
				for surface in modele.find_children("*", "MeshInstance3D", true, false):
					# Le décor distant utilise plus tôt les LOD déjà générés à l’import.
					surface.lod_bias = profil.detail_immeubles
					surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
					for j in range(surface.mesh.get_surface_count()):
						var original: Material = surface.mesh.surface_get_material(j)
						if not original is StandardMaterial3D: continue
						var mat: StandardMaterial3D = original.duplicate()
						mat.albedo_color *= TEINTES_FACADES[(ilot + i) % TEINTES_FACADES.size()]
						# Ces matériaux correspondent aux intérieurs visibles derrière les vitres.
						if original.resource_name.begins_with("MI_FakeInterior") and (ilot + i) % 5 == 1:
							mat.emission_enabled = true
							mat.emission_texture = mat.albedo_texture
							mat.emission = Color(1.0, 0.76, 0.42)
							mat.emission_energy_multiplier = profil.intensite_fenetres_eclairees
							if incendies < profil.incendies_exterieurs and original.resource_name.ends_with("_1"):
								mat.emission = Color(1.0, 0.25, 0.035)
								var sommets = surface.mesh.surface_get_arrays(j)[Mesh.ARRAY_VERTEX]
								if sommets != null and sommets.size() >= 3:
									# Prendre une vraie fenêtre du modèle, jamais inventer sa position sur la façade.
									var transfo := Transform3D.IDENTITY
									var noeud: Node3D = surface
									while noeud != support:
										transfo = noeud.transform * transfo
										noeud = noeud.get_parent()
									var feu = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn").instantiate()
									feu.position = transfo * ((sommets[0] + sommets[1] + sommets[2]) / 3)
									feu.taille = 0.65
									feu.energie = 0.0
									feu.get_node("Crepitement").volume_db = -80
									support.add_child(feu)
									incendies += 1
						surface.set_surface_override_material(j, mat)
			ilot += 1
	for i in range(profil.nombre_lampadaires):
		var support := Node3D.new()
		var angle := i * TAU / maxi(1, profil.nombre_lampadaires)
		# Les lampadaires restent sur le trottoir de notre îlot, hors de la chaussée.
		var direction := Vector2(cos(angle), sin(angle))
		direction /= maxf(absf(direction.x), absf(direction.y))
		support.position = Vector3(direction.x, 0, direction.y) * (cote / 2 + profil.largeur_trottoir / 2)
		support.position.y = 0.21
		ville.add_child(support)
		var modele: Node3D = LAMPADAIRE.instantiate()
		support.add_child(modele)
		GEOMETRIE.normaliser(modele, profil.hauteur_lampadaires, true)
		var lumiere := OmniLight3D.new()
		lumiere.position.y = profil.hauteur_lampadaires * 0.92
		lumiere.light_color = profil.couleur_lampadaires
		lumiere.light_energy = profil.energie_lampadaires
		lumiere.omni_range = profil.portee_lampadaires
		support.add_child(lumiere)
	return ville

static func _parcelle(cote: float, indice: int, ilot: int, profil: ExterieurEtage) -> Rect2:
	# Des terrains de largeurs inégales cassent les rangées sans aucun tirage aléatoire.
	var poids: Array = [1.2, 0.85, 1.05, 0.9] if ilot % 2 == 0 else [0.85, 1.25, 0.95, 1.05]
	var somme := 0.0
	for i in range(profil.immeubles_par_ligne): somme += poids[i]
	var colonne: int = indice % profil.immeubles_par_ligne
	var debut := -cote / 2
	for i in range(colonne): debut += cote * poids[i] / somme
	var largeur: float = cote * poids[colonne] / somme
	var rangee: int = indice / profil.immeubles_par_ligne
	var profondeur: float = cote / profil.rangees_par_ilot
	var recul: float = [0.0, 2.0, -2.0][(ilot + colonne) % 3]
	# Le recul déplace la séparation entre rangées, pas le trottoir extérieur.
	var bas := -cote / 2 + rangee * profondeur + (recul if rangee > 0 else 0.0)
	var haut := -cote / 2 + (rangee + 1) * profondeur + (recul if rangee < profil.rangees_par_ilot - 1 else 0.0)
	return Rect2(Vector2(debut, bas), Vector2(largeur, haut - bas))

static func actualiser(salle: Node3D, ville: Node3D, parent: Node3D) -> Node3D:
	if not salle.has_meta("cadre_ville"):
		if is_instance_valid(ville): ville.hide()
		return ville
	var cadre: Rect2 = salle.get_meta("cadre_ville")
	if not is_instance_valid(ville):
		ville = _quartier(cadre.size.x)
		ville.name = "VilleExterieure"
		parent.add_child(ville)
	ville.show()
	ville.global_position = salle.to_global(Vector3(cadre.get_center().x, -float(salle.get_meta("hauteur_ville")), cadre.get_center().y))
	return ville
