extends "res://scenes/interfaces/menus/ameliorations/upgrade_manager.gd"

signal boutique_fermee
var sprinklers: Array[Node3D] = []
var ventilation: Node3D
var tuile_ventilation: Button

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
		message = "Chaque victime abritée rapporte un point par vague terminée. Les points non dépensés sont perdus en quittant la boutique."
	var liste_vide: Array[Dictionary] = []
	boutique.actualiser_boutique(points, liste_vide, liste_vide, 0, message)
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
	_actualiser_ventilation()

func _acheter_sprinkler(sprinkler: Node3D) -> void:
	if not boutique_ouverte or choix_ouverts or not is_instance_valid(sprinkler): return
	if not sprinklers.has(sprinkler) or sprinkler.arme or sprinkler.temps_restant > 0.0: return
	if monnaie.depenser(sprinkler.prix_activation):
		sprinkler.armer()
		boutique.retour.text = "Sprinkler armé · %s : le prochain ennemi déclenchera le jet." % sprinkler.emplacement

func _actualiser_ventilation() -> void:
	if not is_instance_valid(ventilation):
		for objet in get_tree().get_nodes_in_group("ventilation_zombie"):
			if get_parent().is_ancestor_of(objet):
				ventilation = objet
				ventilation.etat_change.connect(_actualiser_pieces)
				break
	if not is_instance_valid(ventilation): return
	if not is_instance_valid(tuile_ventilation):
		# Réutiliser la tuile d'équipement pour garder le même habillage.
		tuile_ventilation = boutique.recharge_murale.duplicate(0)
		tuile_ventilation.name = "Desenfumage"
		tuile_ventilation.show()
		boutique.recharge_murale.get_parent().add_child(tuile_ventilation)
		var details := tuile_ventilation.get_child(0)
		details.get_child(0).texture = load("res://assets/textures/interfaces/boutique/ventilation.svg")
		details.get_child(1).text = "Préparer le\ndésenfumage"
		tuile_ventilation.pressed.connect(_acheter_ventilation)
	var occupe: bool = ventilation.arme or ventilation.temps_restant > 0.0
	tuile_ventilation.disabled = occupe or monnaie.solde < ventilation.prix_activation
	tuile_ventilation.modulate.a = 0.55 if tuile_ventilation.disabled else 1.0
	tuile_ventilation.get_child(0).get_child(2).text = "Déjà prêt" if occupe else "%d pièces" % ventilation.prix_activation
	tuile_ventilation.tooltip_text = "Réduit la fumée proche pendant %ds au début de la prochaine vague." % roundi(ventilation.duree)

func _acheter_ventilation() -> void:
	if not boutique_ouverte or choix_ouverts or not is_instance_valid(ventilation): return
	if ventilation.arme or ventilation.temps_restant > 0.0: return
	if monnaie.depenser(ventilation.prix_activation):
		ventilation.armer()
		boutique.retour.text = "Désenfumage prêt pour la prochaine vague."
