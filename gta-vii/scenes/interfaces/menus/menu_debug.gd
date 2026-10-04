extends CanvasLayer

# Always dans la scène permet de recevoir I et de cliquer pendant la pause.
@onready var joueur = $"../player"
@onready var salles = $"../Salles/RoomManager"
@onready var menu: Control = $Menu
@onready var invincibilite: CheckButton = %Invincibilite
@onready var degats: CheckButton = %Degats
@onready var points_boutique: CheckButton = %PointsBoutique
@onready var ameliorations = get_node_or_null("../UpgradeManager")
@onready var etages: HBoxContainer = %Etages
@onready var suivant: Button = %Suivant
@onready var situation: Label = %Situation
@onready var raccourci: Label = $"../InterfaceTest/EtatInvincibilite"
var souris_avant: int


func _ready() -> void:
	menu.hide()
	# Un fond doré distingue le survol et les options activées du fond sombre.
	for bouton in [invincibilite, degats, points_boutique, suivant, %LibererSalle, %Fermer]:
		_styliser_selection(bouton)
	invincibilite.toggled.connect(_changer_invincibilite)
	degats.toggled.connect(_changer_degats)
	points_boutique.toggled.connect(_changer_points_boutique)
	%LibererSalle.pressed.connect(_liberer_salle)
	suivant.pressed.connect(_etage_suivant)
	%Fermer.pressed.connect(fermer)
	# Les boutons correspondent au nombre d'étages réglé dans le RoomManager.
	for numero in range(1, salles.nombre_etages + 1):
		var bouton := Button.new()
		_styliser_selection(bouton)
		bouton.text = "Étage %d" % numero
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		# bind conserve le numéro de l'étage associé à CE bouton.
		bouton.pressed.connect(_aller_etage.bind(numero))
		etages.add_child(bouton)


func _input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	if event.physical_keycode == KEY_I or event.keycode == KEY_I:
		if menu.visible:
			fermer()
		else:
			ouvrir()
		get_viewport().set_input_as_handled()
	elif menu.visible and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()


func ouvrir() -> void:
	# Une autre pause appartient à son menu. Attendre aussi la fin d'une transition
	# pour ne pas suspendre la préparation des chemins de la prochaine salle.
	if get_tree().paused or salles.transition_en_cours or joueur.est_mort:
		return
	invincibilite.set_pressed_no_signal(joueur.invincible)
	degats.set_pressed_no_signal(joueur.extincteur.degats_colossaux_test)
	points_boutique.set_pressed_no_signal(ameliorations.points_abondants_test)
	var etage: int = salles.salle_actuelle.etage
	situation.text = "Étage %d/%d — Salle %d/%d" % [etage, salles.nombre_etages,
		salles.indice_salle % salles.SALLES_PAR_ETAGE + 1, salles.SALLES_PAR_ETAGE]
	%LibererSalle.disabled = salles.salle_actuelle.liberee
	suivant.disabled = etage >= salles.nombre_etages
	for i in range(etages.get_child_count()):
		etages.get_child(i).disabled = i + 1 == etage
		etages.get_child(i).text = "Étage %d%s" % [i + 1, " · actuel" if i + 1 == etage else ""]
	joueur.extincteur.stop_primary_attack()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	menu.show()
	get_tree().paused = true


func fermer() -> void:
	if not menu.visible:
		return
	menu.hide()
	Input.mouse_mode = souris_avant
	get_tree().paused = false


func _changer_invincibilite(active: bool) -> void:
	joueur.invincible = active
	_actualiser_raccourci()


func _changer_degats(active: bool) -> void:
	joueur.extincteur.degats_colossaux_test = active
	_actualiser_raccourci()


func _changer_points_boutique(active: bool) -> void:
	# La prochaine ouverture initialise 999 points ; les achats les déduisent normalement.
	ameliorations.points_abondants_test = active
	_actualiser_raccourci()


func _actualiser_raccourci() -> void:
	raccourci.text = "I : menu de test"
	if joueur.invincible:
		raccourci.text += " · Invincible"
	if joueur.extincteur.degats_colossaux_test:
		raccourci.text += " · Dégâts colossaux"
	if ameliorations.points_abondants_test:
		raccourci.text += " · Points abondants"


func _etage_suivant() -> void:
	_aller_etage(salles.salle_actuelle.etage + 1)


func _aller_etage(numero: int) -> void:
	if salles.transition_en_cours or numero < 1 or numero > salles.nombre_etages:
		return
	# Reprendre la physique avant la téléportation. La transition habituelle conserve
	# les PV, les bonus et l'escorte, et démarre le timer de la salle d'arrivée.
	fermer()
	salles.transition_en_cours = true
	var indice: int = (numero - 1) * salles.SALLES_PAR_ETAGE
	salles.call_deferred("activer_salle", indice)


func _styliser_selection(bouton: Button) -> void:
	var accent := StyleBoxFlat.new()
	accent.bg_color = Color("493921")
	accent.border_color = Color("e7b968")
	accent.set_border_width_all(2)
	accent.set_corner_radius_all(5)
	accent.content_margin_left = 10
	accent.content_margin_right = 10
	accent.content_margin_top = 7
	accent.content_margin_bottom = 7
	for etat in ["hover", "pressed", "hover_pressed", "focus"]:
		bouton.add_theme_stylebox_override(etat, accent)
	bouton.add_theme_color_override("font_pressed_color", Color("ffe2a4"))

func _liberer_salle() -> void:
	# Reprendre le jeu permet aussi à l’animation des portes de se terminer.
	fermer()
	salles.liberer_salle_debug()
