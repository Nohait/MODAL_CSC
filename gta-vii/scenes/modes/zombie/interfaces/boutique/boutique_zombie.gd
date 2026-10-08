extends "res://scenes/interfaces/menus/ameliorations/upgrade_manager.gd"

signal boutique_fermee
signal boutique_affichee
var sprinklers: Array[Node3D] = []

func _acheter_booster(rarete: StringName) -> void:
	var avant := points
	super._acheter_booster(rarete)
	# Un achat refusé ou un booster gratuit ne dépense aucun point.
	StatistiquesZombie.noter_achat(avant - points)

func _choisir(carte: Control) -> void:
	if not choix_ouverts or revelation_en_cours or not is_instance_valid(carte) or carte.get_parent() != cartes: return
	# Compter l'amélioration après sa confirmation, sans doubler les clics pendant l'animation.
	await super._choisir(carte)
	StatistiquesZombie.noter_amelioration()

func _ready() -> void:
	super._ready()
	boutique.sprinkler_demande.connect(_acheter_sprinkler)
	# Adapter les textes sans modifier la boutique du mode principal.
	for noeud in boutique.find_children("*", "Label", true, false):
		if noeud.text.begins_with("Chaque victime vivante"):
			noeud.text = "Chaque victime abritée rapporte un point par vague terminée."
	boutique.panneau_defis.hide()
	for noeud in boutique.find_children("*", "Button", true, false):
		if noeud.text == "Continuer vers la prochaine salle":
			noeud.text = "Préparer la prochaine vague"

func ouvrir_choix(_nombre_victimes: int) -> void:
	if boutique_ouverte or choix_ouverts: return
	if points_abondants_test: points = POINTS_BOUTIQUE_TEST
	boutique_ouverte = true
	boutique_affichee.emit()
	extincteur.stop_primary_attack()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_actualiser_boutique()
	boutique.show()
	boutique.modulate.a = 0
	animation = create_tween()
	animation.tween_property(boutique, "modulate:a", 1.0, 0.2)

func _actualiser_boutique(message: String = "") -> void:
	if message.is_empty():
		message = defis.bilan + "Chaque victime abritée rapporte un point par vague terminée. Les points non dépensés sont perdus en quittant la boutique."
	var liste_vide: Array[Dictionary] = []
	# Les défis restent masqués, mais les cadeaux de boss utilisent le compteur commun.
	boutique.actualiser_boutique(points, liste_vide, liste_vide, defis.boosters_rares_gratuits, message)
	_actualiser_pieces()

func _continuer() -> void:
	if not boutique_ouverte or choix_ouverts: return
	boutique_ouverte = false
	points = 0 # La prochaine vague attribuera un nouveau budget.
	if animation: animation.kill()
	boutique.hide()
	Input.mouse_mode = souris_avant
	get_tree().paused = false
	# Le gestionnaire reprend son compte à rebours ; aucun changement de salle.
	boutique_fermee.emit()

func _actualiser_pieces(_solde: int = 0) -> void:
	super._actualiser_pieces(_solde)
	# La map existe au premier affichage de la boutique, pas à son initialisation.
	if sprinklers.is_empty():
		for objet in get_tree().get_nodes_in_group("sprinkler"):
			if get_parent().is_ancestor_of(objet):
				sprinklers.append(objet)
				objet.etat_change.connect(_actualiser_pieces)
		if not sprinklers.is_empty(): boutique.ajouter_sprinklers(sprinklers)
	boutique.actualiser_sprinklers(monnaie.solde)

func _acheter_sprinkler(sprinkler: Node3D) -> void:
	if not boutique_ouverte or choix_ouverts or not is_instance_valid(sprinkler): return
	if not sprinklers.has(sprinkler) or sprinkler.arme or sprinkler.temps_restant > 0.0: return
	if monnaie.depenser(sprinkler.prix_activation):
		sprinkler.armer()
		boutique.retour.text = "Sprinkler armé · %s : le prochain ennemi déclenchera le jet." % sprinkler.emplacement

