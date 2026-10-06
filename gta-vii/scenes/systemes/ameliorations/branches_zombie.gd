extends Node

var gestion: Node
var effets: Node
var joueur: CharacterBody3D
var depuis_degats := 100.0
var depuis_soin_dash := 100.0

func _ready() -> void:
	effets = gestion.effets_cartes
	joueur = gestion.joueur
	joueur.dash_commence.connect(_dash)
	joueur.degats_recus.connect(func(_quantite): depuis_degats = 0.0)
	gestion.room_manager.salle_terminee.connect(_fin_vague)
	CatalogueEnnemis.ennemi_enregistre.connect(_suivre)

func _physics_process(delta: float) -> void:
	depuis_degats += delta
	depuis_soin_dash += delta

func definition(id: StringName) -> Amelioration:
	return gestion.catalogue_ameliorations.trouver(id)

func valeur(id: StringName) -> float:
	return effets.valeur(id)

func _dash(_direction: Vector3) -> void:
	if valeur("dash_sauvetage") > 0 and depuis_soin_dash >= definition("dash_sauvetage").intervalle:
		depuis_soin_dash = 0.0
		_soigner_escorte(valeur("dash_sauvetage"), definition("dash_sauvetage").rayon)

func _soigner_escorte(quantite: float, rayon: float) -> void:
	var proches: Array = []
	for victime in gestion.escorte.freed_victims:
		if not is_instance_valid(victime) or victime.est_morte: continue
		if victime.global_position.distance_to(joueur.global_position) > rayon: continue
		if not effets.visible_depuis(joueur.global_position + Vector3.UP, victime): continue
		proches.append(victime)
	gestion.repartir_soins(proches, quantite, effets.valeur("priorite_blesses") > 0)
	for victime in proches: victime.actualiser_barre_vie()

func multiplicateur_jet() -> float:
	var facteur := 1.0 + (valeur("verre_ardent") + valeur("jet_lourd")) / 100.0
	if Vector2(joueur.velocity.x, joueur.velocity.z).length() > 0.1: facteur *= 1.0 + valeur("jet_mobile") / 100.0
	if valeur("revanche") > 0 and depuis_degats < definition("revanche").duree_effet:
		facteur *= 1.0 + valeur("revanche") / 100.0
	return facteur

func multiplicateur_recharge() -> float:
	return 1.0 + (valeur("ancrage") / 100.0 if Vector2(joueur.velocity.x, joueur.velocity.z).length() < 0.1 else 0.0)

func multiplicateur_marche() -> float:
	return 1.0 - definition("jet_lourd").contrepartie / 100.0 if valeur("jet_lourd") > 0 and gestion.extincteur.emission_effective else 1.0

func multiplicateur_cible(ennemi: Node3D) -> float:
	if valeur("predateur_elites") <= 0: return 1.0
	return 1.0 + valeur("predateur_elites") / 100.0 if ennemi.has_node("Elite") else 1.0 - definition("predateur_elites").contrepartie / 100.0

func toucher(ennemi: Node3D, delta: float) -> void:
	if valeur("mise_a_distance") > 0:
		effets.etat(ennemi).repousser(ennemi.global_position - joueur.global_position, valeur("mise_a_distance") * delta * Engine.physics_ticks_per_second)

func _suivre(ennemi: Node3D) -> void:
	if not gestion.get_parent().is_ancestor_of(ennemi) or not ennemi.has_signal("died"): return
	# Une flaque ne rapporte ni mousse ni soin : aucune boucle de farm sur les feux.
	if ennemi.is_in_group("flaque"): return
	ennemi.died.connect(_mort.bind(ennemi), CONNECT_ONE_SHOT)

func _mort(ennemi: Node3D) -> void:
	var quantite := valeur("recyclage")
	if ennemi.has_node("Elite"): quantite += gestion.extincteur.max_charge * valeur("reserve_elite") / 100.0
	gestion.extincteur.charge = minf(gestion.extincteur.max_charge, gestion.extincteur.charge + quantite)
	if valeur("synergie_samu") > 0:
		_soigner_escorte(valeur("synergie_samu"), definition("synergie_samu").rayon)

func _fin_vague(_salle: Node) -> void:
	joueur.BarreDeVie.value = minf(joueur.BarreDeVie.max_value, joueur.BarreDeVie.value + valeur("soin_victoire"))
