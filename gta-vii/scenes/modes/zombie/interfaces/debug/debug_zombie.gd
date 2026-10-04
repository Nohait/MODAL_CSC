extends "res://scenes/interfaces/menus/menu_debug.gd"

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
	_actualiser_raccourci()

func ouvrir() -> void:
	if get_tree().paused or salles.transition_en_cours or joueur.est_mort:
		return
	invincibilite.set_pressed_no_signal(joueur.invincible)
	degats.set_pressed_no_signal(joueur.extincteur.degats_colossaux_test)
	points_boutique.set_pressed_no_signal(ameliorations.points_abondants_test)
	situation.text = "Mode zombie · Vague %d · %d ennemis restants" % [salles.vague_actuelle, salles.remaining_enemies]
	%LibererSalle.disabled = not salles.vague_en_cours
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
