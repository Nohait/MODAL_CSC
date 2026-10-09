@tool
extends Resource
class_name HabillageSalle

# Une ressource par ambiance permet de régler le décor sans toucher au découpage des salles.
@export var actif := true
@export_group("Identités de salles")
@export var identites_actives := true
@export var identites: Array[IdentiteSalle] = [preload("res://scenes/salles/identites/salon.tres"), preload("res://scenes/salles/identites/cuisine.tres"), preload("res://scenes/salles/identites/bureau.tres"), preload("res://scenes/salles/identites/reserve.tres"), preload("res://scenes/salles/identites/atelier.tres"), preload("res://scenes/salles/identites/humide.tres"), preload("res://scenes/salles/identites/electrique.tres"), preload("res://scenes/salles/identites/technique.tres"), preload("res://scenes/salles/identites/sinistre.tres")]
@export_group("Intensité des incendies")
@export var variations_incendie_actives := true
@export var niveaux_incendie: Array[NiveauIncendie] = [preload("res://scenes/salles/incendies/niveaux/epargne.tres"), preload("res://scenes/salles/incendies/niveaux/actif.tres"), preload("res://scenes/salles/incendies/niveaux/embrase.tres")]
@export_group("Étage 1 — appartements")
@export_range(0, 8) var nombre_fenetres := 3
@export_range(0, 10) var nombre_appliques := 5
@export_range(0, 6) var nombre_meubles_en_feu := 2
@export_range(0, 6) var nombre_tuyauteries := 2
@export_range(0, 6) var nombre_portes_decoratives := 2
@export_range(0.0, 5.0, 0.1) var energie_appliques := 1.5
@export_range(0.0, 5.0, 0.1) var energie_foyers := 1.8
@export_range(0.0, 1.0, 0.05) var opacite_suie := 0.4
@export_range(0.0, 1.0, 0.05) var intensite_reflets := 0.45
@export_group("Extérieurs et finitions")
@export var batiment: EnveloppeBatiment = preload("res://scenes/salles/enveloppe_batiment.tres")
@export var exterieurs: Array[ExterieurEtage] = [preload("res://scenes/salles/exterieur_etage_1.tres"), preload("res://scenes/salles/exterieur_etage_2.tres"), preload("res://scenes/salles/exterieur_etage_3.tres")]
@export var finitions_parcours: FinitionsParcours = preload("res://scenes/salles/finitions_parcours.tres")
@export var details_interieurs: DetailsInterieurs = preload("res://scenes/salles/details_interieurs.tres")
@export var retombees_incendie: HabillageIncendie = preload("res://scenes/salles/incendies/habillage_incendie.tres")
@export_group("Variations des incendies")
@export_range(0.0, 1.0, 0.05) var chance_foyer_couvant := 0.3
@export_range(0.2, 1.0, 0.05) var variation_taille_min := 0.65
@export_range(1.0, 1.5, 0.05) var variation_taille_max := 1.25
@export_group("Mobilier des appartements")
@export var ensembles_appartements: Array[PackedScene] = [preload("res://scenes/decors/appartements/salon_abandonne.tscn"), preload("res://scenes/decors/appartements/salon_bouscule.tscn"), preload("res://scenes/decors/appartements/salon_incendie.tscn"), preload("res://scenes/decors/interieurs/coin_repas.tscn"), preload("res://scenes/decors/interieurs/coin_cuisine.tscn")]
@export_group("Ambiances des étages supérieurs")
@export var ambiance_etage_2: AmbianceEtage = preload("res://scenes/salles/ambiance_etage_2.tres")
@export var ambiance_etage_3: AmbianceEtage = preload("res://scenes/salles/ambiance_etage_3.tres")
@export_group("Portes condamnées — tous les étages")
@export var portes_decoratives: Array[PackedScene] = [preload("res://scenes/decors/interieurs/porte_entrouverte.tscn"), preload("res://scenes/decors/interieurs/porte_enfumee.tscn"), preload("res://scenes/decors/interieurs/porte_bloquee.tscn"), preload("res://scenes/decors/interieurs/placard_entretien.tscn")]
@export_group("Pièces derrière les portes")
@export var incendie_pieces: PieceEmbrasee = preload("res://scenes/salles/incendies/piece_embrasee.tres")
@export var pieces_etage_1: Array[PackedScene] = [preload("res://scenes/decors/interieurs/pieces/appartement_incendie.tscn"), preload("res://scenes/decors/interieurs/pieces/cuisine_incendie.tscn"), preload("res://scenes/decors/interieurs/pieces/appartement_en_l.tscn")]
@export var pieces_etage_2: Array[PackedScene] = [preload("res://scenes/decors/interieurs/pieces/reserve_incendie.tscn"), preload("res://scenes/decors/interieurs/pieces/atelier_entretien_incendie.tscn"), preload("res://scenes/decors/interieurs/pieces/reserve_en_l.tscn")]
@export var pieces_etage_3: Array[PackedScene] = [preload("res://scenes/decors/interieurs/pieces/atelier_incendie.tscn"), preload("res://scenes/decors/interieurs/pieces/local_installations_incendie.tscn"), preload("res://scenes/decors/interieurs/pieces/atelier_en_l.tscn")]
@export_group("Détails des entrées")
@export var porte_manteaux: Array[PackedScene] = [preload("res://scenes/decors/interieurs/porte_manteau_noir.tscn"), preload("res://scenes/decors/interieurs/porte_manteau_chapeau.tscn")]
@export_range(0.0, 1.0, 0.05) var chance_porte_manteau := 0.7
@export_range(0.0, 1.0, 0.05) var chance_tapis := 0.75
@export_group("Ambiances sonores locales")
@export var sons_structurels: ProfilAmbiance = preload("res://scenes/systemes/audio/profils/structure_classique.tres")
@export var sons_etage_1: Array[ProfilAmbiance] = [preload("res://scenes/systemes/audio/profils/radio_classique.tres")]
@export var sons_etage_2: Array[ProfilAmbiance] = [preload("res://scenes/systemes/audio/profils/debris_classique.tres")]
@export var sons_etage_3: Array[ProfilAmbiance] = [preload("res://scenes/systemes/audio/profils/etincelles_classique.tres")]
@export_group("Fissures — nombre maximal par salle")
@export_range(0, 12) var fissures_etage_1 := 1
@export_range(0, 12) var fissures_etage_2 := 5
@export_range(0, 12) var fissures_etage_3 := 7

const FENETRE = preload("res://scenes/decors/hall_incendie/fenetre_hall.tscn")
const APPLIQUE = preload("res://scenes/decors/hall_incendie/applique_murale.tscn")
const TUYAUX = preload("res://scenes/decors/hall_incendie/tuyaux_muraux.tscn")
const CARTONS = preload("res://scenes/decors/hall_incendie/mobilier/cartons.tscn")
const BANC = preload("res://scenes/decors/hall_incendie/banc_hall.tscn")
const FOYER = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn")
const TRACE = preload("res://scenes/decors/hall_incendie/trace_incendie.tscn")
const ARMOIRE = preload("res://scenes/decors/hall_incendie/mobilier/tableau_electrique.tscn")
const GRAVATS = preload("res://scenes/decors/hall_incendie/gravats_beton.tscn")
const EAU = preload("res://scenes/decors/hall_incendie/flaque_eau.tscn")
const TAPIS = preload("res://scenes/decors/interieurs/tapis_use.tscn")
const AMBIANCE_LOCALE = preload("res://scenes/systemes/audio/ambiance_locale.tscn")
const COORDINATION_AMBIANCES = preload("res://scenes/systemes/audio/coordination_ambiances.gd")
const VILLE = preload("res://scenes/decors/interieurs/ville_etage.gd")
const FISSURES = [preload("res://scenes/decors/decals/fissure_02.tscn"), preload("res://scenes/decors/decals/fissure_03.tscn"), preload("res://scenes/decors/decals/fissure_07.tscn"), preload("res://scenes/decors/decals/fissure_09.tscn")]

func appliquer(generateur: Node3D, etage: int) -> void:
	if not actif: return
	var salle: Node3D = generateur.salle_en_creation
	var decor := Node3D.new()
	decor.name = "Habillage"
	salle.add_child(decor)
	# Ce tirage indépendant ne change pas l'aléatoire des ennemis ou des victimes.
	# Une même grille donne les mêmes détails, y compris après une reprise de partie.
	var hasard := RandomNumberGenerator.new()
	hasard.seed = hash(var_to_str(generateur.grid) + str(etage))
	var bords: Array = generateur.bords_habillage.duplicate()
	_melanger(bords, hasard)
	var profil: AmbianceEtage = null if etage == 1 else (ambiance_etage_2 if etage == 2 else ambiance_etage_3)
	var identite := choisir_identite(generateur.grid, etage)
	var niveau := choisir_niveau_incendie(generateur.grid, etage) if identite != null else null
	if niveau != null:
		identite = niveau.adapter(identite)
		salle.set_meta("niveau_incendie", niveau.titre)
		salle.set_meta("ambiance_incendie", niveau)
	if identite != null:
		profil = identite
		salle.set_meta("identite_salle", identite.titre)
		decor.set_meta("identite_salle", identite.titre)
	var plan := PlanEspacesDecoratifs.new()
	var cadre := batiment.limites(generateur) if batiment != null else EnveloppeBatiment.new().limites(generateur)
	plan.initialiser(generateur, cadre)
	_meubler(generateur, decor, bords, hasard, plan, profil, etage)
	_reflets(generateur, decor, intensite_reflets if profil == null else profil.intensite_reflets)
	_fissurer(generateur, decor, bords, etage, hasard)
	if retombees_incendie != null:
		var retombees := retombees_incendie
		if niveau != null:
			retombees = retombees_incendie.duplicate()
			retombees.nombre_foyers = niveau.foyers_supplementaires
			retombees.nombre_braises = niveau.braises
			retombees.force_vent = niveau.force_vent
			retombees.force_rafales = niveau.force_rafales
		retombees.appliquer(generateur, decor, bords, hasard, identite.incendie if identite != null else null)
	_sonoriser(generateur, decor, bords, etage)
	if details_interieurs != null:
		details_interieurs.appliquer(generateur, decor, bords, etage, hasard)
	var exterieur := _exterieur(etage)
	if batiment != null:
		var mobilier: Array = ensembles_appartements if profil == null else profil.meubles_incendies
		var enveloppe := batiment
		if identite != null and batiment.amenagement != null and not identite.compositions_annexes.is_empty():
			# Copier les réglages évite de modifier les autres salles qui partagent la ressource.
			enveloppe = batiment.duplicate()
			enveloppe.amenagement = batiment.amenagement.duplicate()
			enveloppe.amenagement.compositions = identite.compositions_annexes
			enveloppe.couleur_plafonniers = identite.couleur_appliques
			enveloppe.incendie = identite.incendie
			if niveau != null: enveloppe.nombre_incendies = niveau.foyers_annexes
		enveloppe.construire(generateur, decor, mobilier, hasard, etage, plan)
	salle.set_meta("espaces_decoratifs", plan.reservations.duplicate(true))
	if exterieur != null: VILLE.construire(generateur, decor, exterieur, hasard)
	preload("res://scenes/salles/murs_sans_doublons.gd").nettoyer(salle)
	if finitions_parcours != null:
		var finitions := finitions_parcours
		if identite != null:
			finitions = finitions_parcours.duplicate()
			finitions.teintes = finitions_parcours.teintes.duplicate()
			if etage <= finitions.teintes.size(): finitions.teintes[etage - 1] = identite.couleur_soubassement
		finitions.appliquer(generateur, decor, etage)

func choisir_niveau_incendie(grille: Array, etage: int) -> NiveauIncendie:
	if not variations_incendie_actives: return null
	var total := 0.0
	for niveau in niveaux_incendie:
		if niveau != null: total += maxf(0, niveau.poids)
	if total <= 0: return null
	var hasard := RandomNumberGenerator.new()
	# Ce tirage indépendant ne change ni l'identité, ni les tirages de combat.
	hasard.seed = hash(var_to_str(grille) + "intensite_incendie" + str(etage))
	var tirage := hasard.randf() * total
	for niveau in niveaux_incendie:
		if niveau == null or niveau.poids <= 0: continue
		tirage -= niveau.poids
		if tirage < 0: return niveau
	return null

func choisir_identite(grille: Array, etage: int) -> IdentiteSalle:
	if not identites_actives: return null
	var candidates: Array[IdentiteSalle] = []
	var total := 0.0
	for identite in identites:
		if identite == null or identite.etage != etage or identite.poids <= 0.0: continue
		candidates.append(identite)
		total += identite.poids
	if candidates.is_empty(): return null
	# Un tirage séparé conserve les tirages de placement et la reprise d'une même salle.
	var hasard := RandomNumberGenerator.new()
	hasard.seed = hash(var_to_str(grille) + "identite" + str(etage))
	var tirage := hasard.randf() * total
	for identite in candidates:
		tirage -= identite.poids
		if tirage < 0.0: return identite
	return candidates.back()

func _exterieur(etage: int) -> ExterieurEtage:
	if exterieurs.is_empty(): return null
	return exterieurs[clampi(etage - 1, 0, exterieurs.size() - 1)]

func _meubler(generateur: Node3D, decor: Node3D, bords: Array, hasard: RandomNumberGenerator, plan: PlanEspacesDecoratifs, profil: AmbianceEtage = null, etage: int = 1) -> void:
	var incendie: IncendieSalle = profil.incendie if profil is IdentiteSalle else null
	var max_fenetres := nombre_fenetres if profil == null else profil.nombre_fenetres
	var max_appliques := nombre_appliques if profil == null else profil.nombre_appliques
	var max_meubles := nombre_meubles_en_feu if profil == null else profil.nombre_meubles_en_feu
	var max_tuyaux := nombre_tuyauteries if profil == null else profil.nombre_tuyauteries
	var max_armoires := 0 if profil == null else profil.nombre_armoires
	var max_gravats := 0 if profil == null else profil.nombre_gravats
	var max_eau := 0 if profil == null else profil.nombre_zones_humides
	var max_portes := nombre_portes_decoratives if profil == null else profil.nombre_portes_decoratives
	var opacite := opacite_suie if profil == null else profil.opacite_suie
	# Un bord n'accueille qu'un ensemble : pas de fenêtre derrière un meuble ou une applique.
	var fenetres := 0
	var appliques := 0
	var meubles := 0
	var tuyaux := 0
	var armoires := 0
	var gravats := 0
	var eaux := 0
	var portes := 0
	var variantes_pieces: Array[PackedScene] = [pieces_etage_1, pieces_etage_2, pieces_etage_3][clampi(etage - 1, 0, 2)]
	if profil is IdentiteSalle and not profil.pieces.is_empty(): variantes_pieces = profil.pieces
	var variantes_portes: Array = portes_decoratives.duplicate()
	_melanger(variantes_portes, hasard)
	var cellules_meublees: Array[Vector2i] = []
	var variantes: Array = ensembles_appartements.duplicate() if profil == null else profil.meubles_incendies.duplicate()
	_melanger(variantes, hasard)
	for bord in bords:
		var cellule: Vector2i = bord[0]
		var direction: Vector2i = bord[1]
		var normale := Vector3(direction.x, 0, direction.y)
		var centre: Vector3 = generateur.position_cellule(cellule) + normale * 2.5
		var angle := atan2(-normale.x, -normale.z)
		var applique_placee := false
		if fenetres < max_fenetres and (direction == Vector2i.UP or direction == Vector2i.LEFT) and VILLE.bord_expose(generateur, cellule, direction):
			var fenetre = FENETRE.instantiate()
			fenetre.position = centre - normale * 0.12 + Vector3.UP * 0.1
			fenetre.rotation.y = angle
			fenetre.lumiere_incendie = profil != null and profil.fenetres_incendie
			# Le vitrage transparent révèle la ville ; la collision du mur reste intacte.
			fenetre.vue_exterieure = _exterieur(etage) != null and generateur.ouvrir_mur_fenetre(cellule, direction)
			decor.add_child(fenetre)
			fenetre.get_node("LumiereExterieure").shadow_enabled = false
			fenetres += 1
		elif appliques < max_appliques:
			var applique = APPLIQUE.instantiate()
			applique.position = centre - normale * 0.13 + Vector3.UP * 2.55
			applique.rotation.y = angle
			applique.energie = energie_appliques if profil == null else profil.energie_appliques
			if profil != null: applique.couleur = profil.couleur_appliques
			applique.vacillante = appliques == 0
			decor.add_child(applique)
			applique.get_node("FixationDeformee/Lumiere").shadow_enabled = false
			appliques += 1
			applique_placee = true
		elif meubles < max_meubles and cellule in generateur.cellules_disponibles and cellule not in cellules_meublees and generateur.cellules_disponibles.size() > 12:
			var modele: PackedScene = BANC if meubles % 2 == 0 else CARTONS
			if not variantes.is_empty(): modele = variantes[meubles % variantes.size()]
			var meuble = modele.instantiate()
			var est_ensemble := meuble.has_method("position_foyer")
			# L'ensemble reste dans sa case, même contre deux murs perpendiculaires.
			meuble.position = centre - normale * (1.65 if est_ensemble else 0.85) + Vector3.UP * 0.1
			meuble.rotation.y = angle if est_ensemble else angle + hasard.randf_range(-0.12, 0.12)
			generateur.salle_en_creation.get_node("Navigation/Decor").add_child(meuble)
			cellules_meublees.append(cellule)
			# Ne jamais faire apparaître un personnage dans le mobilier.
			generateur.cellules_disponibles.erase(cellule)
			var feu = FOYER.instantiate()
			feu.get_node("Extinction").mobilier = meuble
			feu.position = meuble.transform * meuble.position_foyer() if est_ensemble else meuble.position + Vector3.UP * 0.45
			feu.taille = meuble.taille_foyer if est_ensemble else (0.7 if profil == null else profil.taille_foyers)
			feu.energie = energie_foyers if profil == null else profil.energie_foyers
			feu.densite_fumee = 0.35 if profil == null else profil.densite_fumee
			_varier_incendie(feu, hasard, incendie)
			decor.add_child(feu)
			_suie(decor, meuble.position + Vector3.UP * 0.017, Vector3(-PI / 2, hasard.randf_range(-PI, PI), 0), Vector2(2.5, 2.1), hasard, opacite)
			_suie(decor, centre - normale * 0.112 + Vector3.UP * 1.4, Vector3(0, angle, 0), Vector2(2.0, 2.5), hasard, opacite)
			meubles += 1
		elif tuyaux < max_tuyaux:
			var tube = TUYAUX.instantiate()
			tube.position = centre - normale * 0.11 + Vector3.UP * 0.1
			tube.rotation.y = angle
			# Le modèle du Hall mesure huit mètres ; le tronçon tient ici sur un mur de cinq mètres.
			tube.scale.x = 0.55
			decor.add_child(tube)
			tuyaux += 1
		elif armoires < max_armoires and cellule in generateur.cellules_disponibles and generateur.cellules_disponibles.size() > 12:
			var armoire = ARMOIRE.instantiate()
			armoire.position = centre - normale * 0.85 + Vector3.UP * 0.1
			armoire.rotation.y = angle
			generateur.salle_en_creation.get_node("Navigation/Decor").add_child(armoire)
			generateur.cellules_disponibles.erase(cellule)
			_voyant(armoire, profil)
			armoires += 1
		elif gravats < max_gravats and cellule in generateur.cellules_disponibles and generateur.cellules_disponibles.size() > 12:
			# Ne reprendre que le modèle : ces petits morceaux restent traversables.
			var source = GRAVATS.instantiate()
			var modele: Node3D = source.get_node("Modele")
			modele.owner = null
			source.remove_child(modele)
			var debris := Node3D.new()
			debris.name = "PetitsGravats"
			debris.add_child(modele)
			source.free()
			debris.scale = Vector3.ONE * 0.65
			debris.position = centre - normale * 0.8 + Vector3.UP * 0.1
			debris.rotation.y = angle + hasard.randf_range(-0.2, 0.2)
			decor.add_child(debris)
			gravats += 1
		elif portes < max_portes and not variantes_portes.is_empty() and cellule in generateur.cellules_disponibles and generateur.cellules_disponibles.size() > 12:
			var porte: Node3D = variantes_portes[portes % variantes_portes.size()].instantiate()
			porte.position = centre - normale * 0.115 + Vector3.UP * 0.1
			porte.rotation.y = angle
			# Refuser la porte si sa pièce n'a pas réellement la place derrière ce mur.
			if not _installer_piece(generateur, decor, porte, cellule, direction, variantes_pieces, plan, hasard, incendie):
				porte.free()
				continue
			porte.avec_piece_derriere = true
			generateur.salle_en_creation.get_node("Navigation/Decor").add_child(porte)
			# Le buffet éventuel doit être évité par la navigation et les points de spawn.
			generateur.cellules_disponibles.erase(cellule)
			_habiller_entree(generateur, decor, porte, hasard, portes)
			portes += 1
		# Les zones humides se placent sous les lumières, pas au hasard au milieu du sol.
		if profil != null and eaux < max_eau and applique_placee:
			var eau = EAU.instantiate()
			eau.position = centre - normale * 1.65 + Vector3.UP * 0.075
			eau.rotation.y = angle + hasard.randf_range(-0.2, 0.2)
			decor.add_child(eau)
			eaux += 1

func _varier_incendie(feu: Node3D, hasard: RandomNumberGenerator, incendie: IncendieSalle = null) -> void:
	var couvant := hasard.randf() < (chance_foyer_couvant if incendie == null else incendie.chance_couvant)
	var variation := hasard.randf_range(variation_taille_min, variation_taille_max)
	feu.taille = clampf(feu.taille * variation * (0.55 if couvant else 1.0), 0.2, 2.0)
	feu.energie *= 0.45 if couvant else variation
	feu.densite_fumee = 0.55 if couvant else feu.densite_fumee
	feu.get_node("Flammes").amount = 8 if couvant else 24
	feu.get_node("Braises").amount = 5 if couvant else 12
	feu.get_node("Lumiere").shadow_enabled = false
	if incendie != null: incendie.appliquer(feu, couvant)

func _installer_piece(generateur: Node3D, decor: Node3D, porte: Node3D, cellule: Vector2i, direction: Vector2i, variantes: Array[PackedScene], plan: PlanEspacesDecoratifs, hasard: RandomNumberGenerator, incendie: IncendieSalle = null) -> bool:
	if variantes.is_empty(): return false
	var indice := hasard.randi_range(0, variantes.size() - 1)
	for i in range(variantes.size()):
		var modele: PackedScene = variantes[(indice + i) % variantes.size()]
		if modele == null: continue
		var piece: Node3D = modele.instantiate()
		piece.transform = porte.transform
		plan.actualiser_obstacles(generateur)
		if not plan.peut_placer(PlanEspacesDecoratifs.empreintes(piece, true)):
			piece.free()
			continue
		if not generateur.ouvrir_mur_decoratif(cellule, direction):
			piece.free()
			return false
		piece.adapter_materiaux(generateur.sol_actuel, generateur.murs_actuels)
		piece.incendie_visible = incendie_pieces
		for enfant in piece.get_children():
			if enfant.name.begins_with("Foyer"): _varier_incendie(enfant, hasard, incendie)
		# Hors de Navigation : ni spawn, ni chemins dans ces pièces inaccessibles.
		piece.add_to_group("pieces_decoratives")
		piece.set_meta("type_espace_decoratif", "prepare")
		decor.add_child(piece)
		if incendie_pieces != null: incendie_pieces.habiller_seuil(porte)
		# Réserver toute la géométrie, seuil compris, avant le remplissage procédural.
		plan.reserver("prepare", PlanEspacesDecoratifs.empreintes(piece))
		return true
	return false

func _habiller_entree(generateur: Node3D, decor: Node3D, porte: Node3D, hasard: RandomNumberGenerator, indice: int) -> void:
	if not porte_manteaux.is_empty() and hasard.randf() < chance_porte_manteau:
		# À côté du battant, dans la case déjà réservée à la porte.
		var modele: PackedScene = porte_manteaux[indice % porte_manteaux.size()]
		var meuble: Node3D = modele.instantiate()
		meuble.position = porte.transform * Vector3(1.65, 0, 0.48)
		meuble.rotation.y = porte.rotation.y
		generateur.salle_en_creation.get_node("Navigation/Decor").add_child(meuble)
	if porte.scene_file_path.ends_with("porte_bloquee.tscn") or hasard.randf() >= chance_tapis: return
	var tapis: MeshInstance3D = TAPIS.instantiate()
	# Le dessus du sol est à 0,10 m ; le tapis repose dessus, sans collision.
	tapis.position = porte.transform * Vector3(hasard.randf_range(-0.12, 0.12), 0.007, 1.25)
	tapis.rotation.y = porte.rotation.y + hasard.randf_range(-0.12, 0.12)
	decor.add_child(tapis)

func _sonoriser(generateur: Node3D, decor: Node3D, bords: Array, etage: int) -> void:
	var profils: Array[ProfilAmbiance] = [sons_etage_1, sons_etage_2, sons_etage_3][clampi(etage - 1, 0, 2)].duplicate()
	# Le profil commun remplace l'ancien bruit de débris de l'étage 2, sans le doubler.
	if sons_structurels != null:
		profils.erase(preload("res://scenes/systemes/audio/profils/debris_classique.tres"))
		profils.append(sons_structurels)
	if profils.is_empty() or bords.is_empty(): return
	var coordination := Node3D.new()
	coordination.name = "Ambiances"
	coordination.set_script(COORDINATION_AMBIANCES)
	for i in range(profils.size()):
		if profils[i] == null: continue
		var source: Node3D = AMBIANCE_LOCALE.instantiate()
		source.profil = profils[i]
		var bord: Array = bords[i % bords.size()]
		var normale := Vector3(bord[1].x, 0, bord[1].y)
		source.position = generateur.position_cellule(bord[0]) + normale * 2.25 + Vector3.UP * 1.8
		if profils[i] == sons_structurels:
			for piece in decor.get_children():
				if piece.is_in_group("pieces_decoratives"):
					source.position = piece.transform * Vector3(0, 1.5, -2)
					break
		# Au dernier étage, privilégier un véritable meuble électrique s'il existe.
		if etage == 3 and profils[i] != sons_structurels:
			for meuble in generateur.salle_en_creation.get_node("Navigation/Decor").get_children():
				if meuble.scene_file_path.ends_with("poste_electrique.tscn"):
					source.position = meuble.transform * Vector3(-1.15, 1.6, -1.3)
					break
		coordination.add_child(source)
	decor.add_child(coordination)

func _voyant(armoire: Node3D, profil: AmbianceEtage) -> void:
	# Petit voyant fixé sur la face de l'armoire, et lumière verte réellement locale.
	var voyant := MeshInstance3D.new()
	var forme := SphereMesh.new()
	forme.radius = 0.025
	forme.height = 0.05
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.18, 0.8, 0.36)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	mat.emission_energy_multiplier = 2.0
	forme.material = mat
	voyant.mesh = forme
	voyant.position = Vector3(0.25, 1.15, 0.64)
	armoire.add_child(voyant)
	var lumiere := OmniLight3D.new()
	lumiere.position = Vector3(0.25, 1.15, 0.8)
	lumiere.light_color = mat.albedo_color
	lumiere.light_energy = profil.energie_voyants
	lumiere.omni_range = profil.portee_voyants
	armoire.add_child(lumiere)

func _suie(parent: Node3D, position: Vector3, rotation: Vector3, taille: Vector2, hasard: RandomNumberGenerator, opacite: float) -> void:
	var trace = TRACE.instantiate()
	parent.add_child(trace)
	var surface: MeshInstance3D = trace.get_node("Suie")
	surface.position = position
	surface.rotation = rotation
	surface.mesh = surface.mesh.duplicate()
	surface.mesh.size = taille
	surface.material_override = surface.material_override.duplicate()
	surface.material_override.set_shader_parameter("teinte", Color(0.045, 0.033, 0.025, opacite))
	surface.material_override.set_shader_parameter("graine", hasard.randf_range(0, 100))

func _fissurer(generateur: Node3D, decor: Node3D, bords: Array, etage: int, hasard: RandomNumberGenerator) -> void:
	var nombre: int = [fissures_etage_1, fissures_etage_2, fissures_etage_3][clampi(etage - 1, 0, 2)]
	var cellules: Array = generateur.cellules_disponibles.duplicate()
	_melanger(cellules, hasard)
	for i in range(nombre):
		var fissure: Decal = FISSURES[hasard.randi_range(0, FISSURES.size() - 1)].instantiate()
		# Les derniers étages reçoivent aussi quelques fissures murales.
		if etage > 1 and i % 3 == 2 and not bords.is_empty():
			var bord: Array = bords[i % bords.size()]
			var normale := Vector3(bord[1].x, 0, bord[1].y)
			fissure.position = generateur.position_cellule(bord[0]) + normale * 2.39 + Vector3.UP * hasard.randf_range(1.3, 1.8)
			fissure.rotation = Vector3(PI / 2, atan2(-normale.x, -normale.z), 0)
			fissure.rotate_object_local(Vector3.UP, hasard.randf_range(-0.5, 0.5))
		else:
			if cellules.is_empty():
				fissure.free()
				break
			fissure.position = generateur.position_cellule(cellules.pop_back()) + Vector3(hasard.randf_range(-0.7, 0.7), 0.105, hasard.randf_range(-0.7, 0.7))
			fissure.rotation.y = hasard.randf_range(-PI, PI)
		var largeur := hasard.randf_range(1.4, 2.6)
		fissure.size = Vector3(largeur, 0.14, largeur * hasard.randf_range(0.7, 1.0))
		fissure.albedo_mix = hasard.randf_range(0.4, 0.65)
		decor.add_child(fissure)

func _reflets(generateur: Node3D, decor: Node3D, intensite: float) -> void:
	if intensite <= 0: return
	# Une capture statique du décor, pas une capture coûteuse à chaque image.
	var sonde := ReflectionProbe.new()
	sonde.name = "RefletsLocaux"
	sonde.position = Vector3((generateur.roomSize.x - 1) * 2.5, 1.6, (generateur.roomSize.y - 1) * 2.5)
	sonde.size = Vector3(generateur.roomSize.x * 5.0, 5.0, generateur.roomSize.y * 5.0)
	sonde.intensity = intensite
	sonde.interior = true
	sonde.ambient_mode = ReflectionProbe.AMBIENT_DISABLED
	sonde.enable_shadows = false
	sonde.max_distance = maxf(sonde.size.x, sonde.size.z)
	decor.add_child(sonde)

func _melanger(liste: Array, hasard: RandomNumberGenerator) -> void:
	# Fisher-Yates avec notre générateur local, sans utiliser le hasard global du combat.
	for i in range(liste.size() - 1, 0, -1):
		var autre := hasard.randi_range(0, i)
		var valeur = liste[i]
		liste[i] = liste[autre]
		liste[autre] = valeur
