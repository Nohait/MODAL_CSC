@tool
extends Resource
class_name EnveloppeBatiment

const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")
const FENETRE = preload("res://scenes/decors/hall_incendie/fenetre_hall.tscn")
const FOYER = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn")
const ESPACE = preload("res://scenes/decors/interieurs/espace_decoratif.gd")
const PLAFONNIER = preload("res://assets/modeles/appartements/modern_ceiling_lamp_01/modern_ceiling_lamp_01_1k.gltf")
const PORTE_CLOISON = preload("res://scenes/decors/interieurs/porte_cloison.tscn")

@export_range(2, 5) var marge_en_cellules := 2
@export_range(5.0, 15.0, 0.5) var largeur_piece_max := 10.0
@export_range(5.0, 15.0, 0.5) var profondeur_piece_max := 10.0
@export_range(0.0, 0.5, 0.05) var proportion_espaces_ouverts := 0.25
@export_range(0.0, 45.0, 1.0) var ouverture_portes_max := 25.0
@export var amenagement: AmenagementPiece = preload("res://scenes/salles/amenagement_pieces.tres")
@export var aspect: AspectPieceInaccessible = preload("res://scenes/salles/aspect_pieces_inaccessibles.tres")
@export var incendie: IncendieSalle
@export_range(0, 5) var nombre_incendies := 3
@export_range(3.0, 15.0, 0.5) var distance_entre_foyers := 8.0
@export_range(0, 6) var nombre_plafonniers := 3
@export_range(0.0, 3.0, 0.1) var energie_plafonniers := 1.2
@export_range(2.0, 8.0, 0.5) var portee_plafonniers := 4.0
@export var couleur_plafonniers := Color(1.0, 0.76, 0.42)
@export_range(0.0, 4.0, 0.1) var emission_plafonniers := 1.2
@export var finitions: FinitionsHabitees = preload("res://scenes/salles/finitions_habitees.tres")

func limites(generateur: Node3D) -> Rect2:
	# Même enveloppe pour toutes les grilles de cette taille, quelle que soit leur découpe.
	var cote: int = maxi(generateur.roomSize.x, generateur.roomSize.y)
	var origine := Vector2(-marge_en_cellules, -marge_en_cellules) * 5.0 - Vector2.ONE * 2.5
	return Rect2(origine, Vector2.ONE * (cote + marge_en_cellules * 2) * 5.0)

func construire(generateur: Node3D, decor: Node3D, mobilier: Array, hasard: RandomNumberGenerator, etage: int, plan: PlanEspacesDecoratifs) -> void:
	var cadre := limites(generateur)
	plan.actualiser_obstacles(generateur)
	var remplissage := Node3D.new()
	remplissage.set_script(ESPACE)
	remplissage.aspect = aspect
	remplissage.volume_foyers = -20.0
	remplissage.set_meta("type_espace_decoratif", "procedural")
	remplissage.name = "EspacesInaccessibles"
	decor.add_child(remplissage)
	var meubles := 0
	var incendies := 0
	var positions_foyers: Array[Vector3] = []
	var plafonniers := 0
	var pieces: Array[Rect2] = []
	var cloisons: Array[Rect2] = []
	var portes: Array[Transform3D] = []
	for libre in plan.espaces_restants():
		_decouper(libre, pieces, cloisons, portes, hasard)
	for cloison in cloisons:
		if finitions != null:
			finitions.cloison(remplissage, cloison, etage, hasard)
			continue
		var centre := cloison.get_center()
		GEOMETRIE.bloc(remplissage, "Cloison", Vector3(centre.x, 1.6, centre.y), Vector3(cloison.size.x, 3, cloison.size.y), generateur.murs_actuels)
	for emplacement in portes:
		var porte = PORTE_CLOISON.instantiate()
		# Le modèle place son encadrement à Z = 0.14 : le recentrer sur la cloison.
		porte.transform = emplacement.translated_local(Vector3(0, 0, -0.14))
		porte.get_node("Charniere").rotation_degrees.y = hasard.randf_range(0.0, ouverture_portes_max)
		porte.remove_from_group("collider")
		remplissage.add_child(porte)
		var taille := emplacement.basis * Vector3(1.8, 0.5, 0.12)
		taille = taille.abs()
		GEOMETRIE.bloc(remplissage, "LinteauCloison", emplacement.origin + Vector3.UP * 2.75, taille, generateur.murs_actuels)
	for zone in pieces:
		plan.reserver("procedural", [zone])
		var centre := zone.get_center()
		var sol := GEOMETRIE.bloc(remplissage, "SolAnnexe", Vector3(centre.x, 0, centre.y), Vector3(zone.size.x, 0.2, zone.size.y), generateur.sol_actuel)
		if minf(zone.size.x, zone.size.y) < 3.0: continue
		if amenagement == null: continue
		if plafonniers < nombre_plafonniers and meubles % 3 == 0:
			var support := Node3D.new()
			support.name = "Plafonnier"
			support.position = Vector3(centre.x, 2.45, centre.y)
			remplissage.add_child(support)
			var modele: Node3D = PLAFONNIER.instantiate()
			support.add_child(modele)
			GEOMETRIE.normaliser(modele, 0.55, true)
			# L'émission rend le verre lumineux ; la lumière locale éclaire les objets autour.
			for surface: MeshInstance3D in modele.find_children("*", "MeshInstance3D", true, false):
				for indice in range(surface.mesh.get_surface_count()):
					var materiau := surface.get_active_material(indice)
					if not materiau is StandardMaterial3D or not "glass" in materiau.resource_name.to_lower(): continue
					var verre: StandardMaterial3D = materiau.duplicate()
					verre.emission_enabled = true
					verre.emission = couleur_plafonniers
					verre.emission_energy_multiplier = emission_plafonniers
					surface.set_surface_override_material(indice, verre)
			var lumiere := OmniLight3D.new()
			lumiere.position.y = 0.12
			lumiere.light_color = couleur_plafonniers
			lumiere.light_energy = energie_plafonniers
			lumiere.omni_range = portee_plafonniers
			support.add_child(lumiere)
			plafonniers += 1
		var ensembles := amenagement.remplir(remplissage, zone, mobilier, meubles, hasard)
		if not ensembles.is_empty() and ensembles[0].has_meta("revetement_sol"):
			sol.material_override = ensembles[0].get_meta("revetement_sol")
		for ensemble in ensembles:
			if incendies >= nombre_incendies or not ensemble.has_method("position_foyer"): continue
			var position_feu: Vector3 = ensemble.position + ensemble.basis * ensemble.position_foyer()
			var trop_proche := false
			# Espacer les foyers donne des zones contrastées, plutôt qu'un coin uniformément en feu.
			for autre in positions_foyers:
				if position_feu.distance_to(autre) < distance_entre_foyers: trop_proche = true
			if trop_proche: continue
			positions_foyers.append(position_feu)
			var feu = FOYER.instantiate()
			feu.position = position_feu
			feu.get_node("Extinction").mobilier = ensemble
			feu.taille = 0.65
			feu.energie = 1.2
			if incendie != null: incendie.appliquer(feu)
			feu.get_node("Lumiere").shadow_enabled = false
			feu.get_node("Crepitement").volume_db = -20
			remplissage.add_child(feu)
			# La suie reste autour de ce qui brûle, avec une taille propre à chaque foyer.
			var trace = preload("res://scenes/decors/hall_incendie/trace_incendie.tscn").instantiate()
			trace.position = Vector3(feu.position.x, 0.101, feu.position.z)
			trace.rotation.y = hasard.randf_range(-PI, PI)
			trace.scale = Vector3.ONE * hasard.randf_range(0.5, 0.8)
			remplissage.add_child(trace)
			incendies += 1
		meubles += 1
	# La façade appartient au bâtiment, jamais au contour aléatoire de la zone jouable.
	for axe in range(2):
		for signe in [-1, 1]:
			var centre := cadre.get_center()
			var position := Vector3(centre.x, 1.6, centre.y)
			if axe == 0: position.z += signe * cadre.size.y / 2
			else: position.x += signe * cadre.size.x / 2
			var segments := roundi(cadre.size.x / 5.0)
			for i in range(segments):
				var emplacement := position + (Vector3.RIGHT if axe == 0 else Vector3.BACK) * ((i + 0.5) * 5 - cadre.size.x / 2)
				var normale := Vector3(0, 0, signe) if axe == 0 else Vector3(signe, 0, 0)
				var tangente := Vector3.RIGHT if axe == 0 else Vector3.BACK
				if i % 2 == 0:
					GEOMETRIE.bloc(remplissage, "Facade", emplacement, Vector3(5, 3, 0.2) if axe == 0 else Vector3(0.2, 3, 5), generateur.murs_actuels)
					continue
				for bord in [-1, 1]:
					GEOMETRIE.bloc(remplissage, "MontantFenetre", emplacement + tangente * bord * 1.6, Vector3(1.8, 3, 0.2) if axe == 0 else Vector3(0.2, 3, 1.8), generateur.murs_actuels)
				for bande in [Vector2(0.5, 0.8), Vector2(2.9, 0.4)]:
					var point := emplacement
					point.y = bande.x
					GEOMETRIE.bloc(remplissage, "AllègeFenetre", point, Vector3(1.4, bande.y, 0.2) if axe == 0 else Vector3(0.2, bande.y, 1.4), generateur.murs_actuels)
				var fenetre = FENETRE.instantiate()
				fenetre.position = Vector3(emplacement.x, 0.1, emplacement.z) - normale * 0.12
				fenetre.rotation.y = atan2(-normale.x, -normale.z)
				fenetre.vue_exterieure = true
				fenetre.get_node("LumiereExterieure").shadow_enabled = false
				fenetre.get_node("LumiereExterieure").visible = false
				remplissage.add_child(fenetre)

func _decouper(zone: Rect2, pieces: Array[Rect2], cloisons: Array[Rect2], portes: Array[Transform3D], hasard: RandomNumberGenerator) -> void:
	if minf(zone.size.x, zone.size.y) < 3.0 or (zone.size.x <= largeur_piece_max and zone.size.y <= profondeur_piece_max):
		pieces.append(zone)
		return
	var axe := 0 if zone.size.x / largeur_piece_max > zone.size.y / profondeur_piece_max else 1
	# Une proportion différente à chaque séparation évite les rangées de cellules identiques.
	var distance := zone.size[axe] * hasard.randf_range(0.38, 0.62)
	var premiere := zone
	premiere.size[axe] = distance
	var seconde := zone
	seconde.position[axe] += distance
	seconde.size[axe] -= distance
	if hasard.randf() >= proportion_espaces_ouverts:
		var autre_axe := 1 - axe
		var passage := 1.8
		var debut_passage := zone.size[autre_axe] * hasard.randf_range(0.35, 0.65) - passage / 2
		# Mémoriser la porte au moment où la séparation réserve son ouverture.
		var centre_porte := zone.position
		centre_porte[axe] += distance
		centre_porte[autre_axe] += debut_passage + passage / 2
		var rotation := Basis(Vector3.UP, PI / 2 if axe == 0 else 0.0)
		portes.append(Transform3D(rotation, Vector3(centre_porte.x, 0.1, centre_porte.y)))
		for intervalle in [Vector2(0, debut_passage), Vector2(debut_passage + passage, zone.size[autre_axe])]:
			var position := zone.position
			position[axe] += distance - 0.06
			position[autre_axe] += intervalle.x
			var taille := Vector2.ONE * 0.12
			taille[autre_axe] = intervalle.y - intervalle.x
			cloisons.append(Rect2(position, taille))
	_decouper(premiere, pieces, cloisons, portes, hasard)
	_decouper(seconde, pieces, cloisons, portes, hasard)

