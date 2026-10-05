extends "res://scenes/interfaces/menus/menu_debug.gd"

var choix_vagues: Control

func _ready() -> void:
	menu.hide()
	# Reprendre la scène et les commandes communes, remplacer seulement la navigation.
	points_boutique.show()
	points_boutique.toggled.connect(_changer_points_boutique)
	for bouton in [invincibilite, degats, points_boutique, suivant, %LibererSalle, %Fermer]:
		_styliser_selection(bouton)
	invincibilite.toggled.connect(_changer_invincibilite)
	degats.toggled.connect(_changer_degats)
	%LibererSalle.text = "Terminer la vague actuelle"
	%LibererSalle.tooltip_text = "Supprime aussi les ennemis et annonces encore à venir."
	%LibererSalle.pressed.connect(_liberer_salle)
	suivant.text = "Passer à la vague suivante"
	suivant.pressed.connect(_etage_suivant)
	%Fermer.pressed.connect(fermer)
	for numero in [1, 5, 10]:
		var bouton := Button.new()
		_styliser_selection(bouton)
		bouton.text = "Vague %d" % numero
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.pressed.connect(_aller_etage.bind(numero))
		etages.add_child(bouton)
	_preparer_choix_ennemis()
	_preparer_choix_vagues()
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(menu)
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(choix_ennemis)
	_actualiser_raccourci()

func ouvrir() -> void:
	if get_tree().paused or salles.transition_en_cours or joueur.est_mort:
		return
	invincibilite.set_pressed_no_signal(joueur.invincible)
	degats.set_pressed_no_signal(joueur.extincteur.degats_colossaux_test)
	points_boutique.set_pressed_no_signal(ameliorations.points_abondants_test)
	situation.text = "Mode zombie · Vague %d · %d ennemis restants" % [salles.vague_actuelle, salles.remaining_enemies]
	%LibererSalle.disabled = not salles.vague_en_cours
	_actualiser_choix_ennemis()
	joueur.extincteur.stop_primary_attack()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
	get_tree().paused = true

func _actualiser_raccourci() -> void:
	raccourci.text = "I : menu de test"
	if joueur.invincible:
		raccourci.text += " · Invincible"
	if joueur.extincteur.degats_colossaux_test:
		raccourci.text += " · Dégâts colossaux"

func _etage_suivant() -> void:
	_aller_etage(salles.vague_actuelle + 1)

func _aller_etage(numero: int) -> void:
	fermer()
	# Différer les suppressions et apparitions hors du traitement du clic.
	salles.call_deferred("aller_vague_debug", numero)

func _liberer_salle() -> void:
	fermer()
	salles.call_deferred("liberer_salle_debug")

func _preparer_choix_vagues() -> void:
	choix_vagues = preload("res://scenes/modes/zombie/interfaces/debug/choix_vagues.tscn").instantiate()
	add_child(choix_vagues)
	var bouton := Button.new()
	bouton.name = "ChoisirVague"
	bouton.text = "Choisir une vague…"
	_styliser_selection(bouton)
	var contenu := %Fermer.get_parent()
	contenu.add_child(bouton)
	contenu.move_child(bouton, %Fermer.get_index())
	bouton.pressed.connect(_ouvrir_choix_vagues)
	var retour: Button = choix_vagues.get_node("%Retour")
	_styliser_selection(retour)
	retour.pressed.connect(_retour_debug)
	# Utiliser les ressources d'équilibrage : les futurs types apparaîtront ici automatiquement.
	var compositions: Array[CompositionVague] = [salles.difficulte.composition_classique]
	compositions.append_array(salles.difficulte.compositions_speciales)
	compositions.append(salles.difficulte.composition_boss)
	for composition in compositions:
		if composition == null: continue
		var option := Button.new()
		option.text = composition.titre
		option.tooltip_text = "Disponible à partir de la vague %d." % composition.premiere_vague
		option.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		option.custom_minimum_size.y = 44
		_styliser_selection(option)
		option.pressed.connect(_lancer_composition.bind(composition))
		choix_vagues.get_node("%ListeVagues").add_child(option)
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(choix_vagues)

func _ouvrir_choix_vagues() -> void:
	$Menu/Centre.hide()
	choix_vagues.show()

func _lancer_composition(composition: CompositionVague) -> void:
	# Garder la difficulté actuelle, sauf si ce type demande une vague plus avancée.
	var numero: int = maxi(maxi(1, salles.vague_actuelle), composition.premiere_vague)
	fermer()
	# Reprendre la physique avant de remplacer les ennemis et leur calendrier.
	salles.call_deferred("aller_vague_debug", numero, composition)

func _retour_debug() -> void:
	choix_vagues.hide()
	super._retour_debug()

func fermer() -> void:
	choix_vagues.hide()
	super.fermer()

func _input(event: InputEvent) -> void:
	if choix_vagues.visible and event.is_action_pressed("ui_cancel"):
		_retour_debug()
		get_viewport().set_input_as_handled()
		return
	super._input(event)
