extends CanvasLayer

const ETAPES = preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd")
const COMMANDES = preload("res://scenes/modes/tutoriel/debug/commandes_debug.gd")
var commandes
var panneau: PanelContainer
var onglets: TabContainer
var disposition: VBoxContainer
var etat: Label
var historique: Label
var indicateur: Label
var boutons: Dictionary = {}
var cases: Dictionary = {}
var evenements: Array[String] = []
var pause_avant := false
var souris_avant := Input.MOUSE_MODE_VISIBLE
var prochaine_actualisation := 0
var dernier_etat := ""
var derniere_salle := ""

static func installer(scene: Node) -> void:
	if not OS.is_debug_build(): return
	if scene.has_node("DebugTutoriel"): return
	if not scene.get_tree().root.has_node("GardeDebugTutoriel"):
		var garde = preload("res://scenes/modes/tutoriel/debug/garde_debug.gd").new()
		garde.name = "GardeDebugTutoriel"
		scene.get_tree().root.add_child(garde)
	if Engine.has_meta("tutoriel_debug_depart"):
		var depart: String = Engine.get_meta("tutoriel_debug_depart")
		Engine.remove_meta("tutoriel_debug_depart")
		await scene.debug_reconstruire(depart)
	var menu = load("res://scenes/modes/tutoriel/debug/menu_tutoriel.gd").new()
	menu.name = "DebugTutoriel"
	scene.add_child(menu)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 100
	commandes = COMMANDES.new(get_parent())
	_construire()
	for evenement in Engine.get_meta("tutoriel_debug_historique", []): evenements.append(str(evenement))
	derniere_salle = commandes.contexte().salle
	_journal("Salle chargée : " + derniere_salle)
	for noeud in get_parent().find_children("*", "Node", true, false): _brancher(noeud)
	get_tree().node_added.connect(_ajout)

func _construire() -> void:
	indicateur = Label.new()
	indicateur.position = Vector2(20, 18)
	indicateur.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(indicateur)
	panneau = PanelContainer.new()
	panneau.theme = _theme_menu()
	add_child(panneau)
	var contenu := VBoxContainer.new()
	contenu.add_theme_constant_override("separation", 14)
	panneau.add_child(contenu)
	var titre := Label.new()
	titre.text = "ATELIER DU TUTORIEL"
	titre.add_theme_font_size_override("font_size", 27)
	titre.add_theme_color_override("font_color", Color(1, 0.76, 0.38))
	contenu.add_child(titre)
	var aide := Label.new()
	aide.text = "Simulation suspendue · I ou Échap pour fermer · les changements de debug ne sont pas sauvegardés"
	aide.add_theme_font_size_override("font_size", 15)
	contenu.add_child(aide)
	onglets = TabContainer.new()
	onglets.size_flags_vertical = Control.SIZE_EXPAND_FILL
	contenu.add_child(onglets)
	var acces := _page("Étapes")
	disposition = _section(acces, "REJOINDRE UN EXERCICE")
	var choix := OptionButton.new()
	choix.custom_minimum_size.y = 42
	for etape in ETAPES.ETAPES: choix.add_item(etape.titre)
	disposition.add_child(choix)
	_bouton("Rejoindre la sélection", func(): _rejoindre(ETAPES.ETAPES[choix.selected].id))
	disposition = _section(acces, "RECOMMENCER")
	_bouton("Recommencer l’étape", func(): _rejoindre(commandes.contexte().restart_etape))
	_bouton("Recommencer la salle", func(): _rejoindre(commandes.contexte().restart_salle))
	_bouton("Début du tutoriel", func(): _rejoindre("parvis"))
	var actions := _page("Aides et actions")
	var colonnes := HBoxContainer.new()
	colonnes.add_theme_constant_override("separation", 18)
	actions.add_child(colonnes)
	disposition = _section(colonnes, "PROTECTIONS ET OBSERVATION")
	_case("Joueur invulnérable", commandes.invulnerabilite)
	_case("Victimes protégées", commandes.protection_victimes)
	_case("Ennemis suspendus", commandes.activite_ennemie_suspendue)
	_case("Repères, collisions et navigation", commandes.afficher_reperes)
	_bouton("Réinitialiser les aides", _reinitialiser)
	disposition = _section(colonnes, "ACTIONS RAPIDES")
	_bouton("Restaurer vie et réserve", commandes.restaurer)
	_bouton("Éteindre les foyers", commandes.eteindre)
	_bouton("Vaincre l’ennemi", commandes.vaincre)
	_bouton("Libérer la victime", commandes.liberer)
	disposition = _section(actions, "VITESSE DE SIMULATION")
	var vitesse := HBoxContainer.new()
	disposition.add_child(vitesse)
	for valeur in [0.25, 0.5, 1.0, 2.0]:
		var bouton := Button.new()
		bouton.text = "Normale · ×1" if valeur == 1.0 else "×" + str(valeur)
		bouton.custom_minimum_size.y = 38
		bouton.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		bouton.pressed.connect(commandes.vitesse.bind(valeur))
		vitesse.add_child(bouton)
	var diagnostic := _page("Diagnostic")
	disposition = _section(diagnostic, "ÉTAT ET CONDITIONS DE RÉUSSITE")
	etat = Label.new()
	etat.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disposition.add_child(etat)
	_bouton("Copier le diagnostic", func(): DisplayServer.clipboard_set(commandes.diagnostic() + "\n\n" + "\n".join(evenements)))
	disposition = _section(diagnostic, "ÉVÉNEMENTS RÉCENTS")
	historique = Label.new()
	historique.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	disposition.add_child(historique)
	disposition = contenu
	_bouton("Fermer", fermer)
	get_viewport().size_changed.connect(_redimensionner)
	_redimensionner()
	panneau.hide()

func _page(titre: String) -> VBoxContainer:
	var scroll := ScrollContainer.new()
	scroll.name = titre
	onglets.add_child(scroll)
	var colonne := VBoxContainer.new()
	colonne.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	colonne.add_theme_constant_override("separation", 14)
	scroll.add_child(colonne)
	return colonne

func _section(parent: Control, titre: String) -> VBoxContainer:
	var cadre := PanelContainer.new()
	cadre.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cadre.add_theme_stylebox_override("panel", _style(Color(0.09, 0.12, 0.17), Color(0.2, 0.27, 0.35)))
	parent.add_child(cadre)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 8)
	cadre.add_child(colonne)
	var label := Label.new()
	label.text = titre
	label.add_theme_font_size_override("font_size", 15)
	label.add_theme_color_override("font_color", Color(0.9, 0.71, 0.4))
	colonne.add_child(label)
	return colonne

func _style(fond: Color, bord: Color) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fond
	style.border_color = bord
	style.set_border_width_all(1)
	style.set_corner_radius_all(8)
	style.content_margin_left = 16
	style.content_margin_right = 16
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	return style

func _theme_menu() -> Theme:
	var theme := Theme.new()
	theme.default_font_size = 17
	theme.set_color("font_color", "Label", Color(0.9, 0.93, 0.97))
	theme.set_stylebox("panel", "PanelContainer", _style(Color(0.045, 0.065, 0.095, 0.98), Color(0.38, 0.43, 0.5)))
	for type in ["Button", "OptionButton", "TabContainer"]:
		theme.set_stylebox("normal", type, _style(Color(0.12, 0.17, 0.23), Color(0.25, 0.32, 0.4)))
		theme.set_stylebox("hover", type, _style(Color(0.19, 0.26, 0.34), Color(0.85, 0.64, 0.3)))
		theme.set_stylebox("pressed", type, _style(Color(0.26, 0.21, 0.13), Color(1, 0.76, 0.38)))
		theme.set_color("font_color", type, Color(0.93, 0.95, 0.98))
		theme.set_color("font_hover_color", type, Color(1, 0.82, 0.52))
	theme.set_stylebox("tab_selected", "TabContainer", _style(Color(0.19, 0.26, 0.34), Color(0.85, 0.64, 0.3)))
	theme.set_stylebox("tab_unselected", "TabContainer", _style(Color(0.08, 0.11, 0.16), Color(0.25, 0.32, 0.4)))
	theme.set_stylebox("panel", "TabContainer", _style(Color(0.045, 0.065, 0.095), Color(0.2, 0.27, 0.35)))
	return theme

func _redimensionner() -> void:
	var ecran := get_viewport().get_visible_rect().size
	panneau.size = Vector2(minf(1120, ecran.x - 48), minf(760, ecran.y - 48))
	panneau.position = (ecran - panneau.size) * 0.5

func _bouton(texte: String, action: Callable) -> void:
	var bouton := Button.new()
	bouton.text = texte
	bouton.custom_minimum_size.y = 38
	bouton.focus_mode = Control.FOCUS_ALL
	bouton.pressed.connect(action)
	disposition.add_child(bouton)
	boutons[texte] = bouton

func _case(texte: String, action: Callable) -> void:
	var case := CheckButton.new()
	case.text = texte
	case.toggled.connect(action)
	disposition.add_child(case)
	cases[texte] = case

func _input(event: InputEvent) -> void:
	if commandes.transition_en_cours: return
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_I:
		if panneau.visible: fermer()
		else: ouvrir()
		get_viewport().set_input_as_handled()
	elif panneau.visible and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()

func ouvrir() -> void:
	pause_avant = get_tree().paused
	souris_avant = Input.mouse_mode
	commandes.contexte().joueur.extincteur.stop_primary_attack()
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	onglets.current_tab = 0
	panneau.show()
	boutons["Rejoindre la sélection"].grab_focus()

func fermer() -> void:
	if not panneau.visible: return
	panneau.hide()
	get_tree().paused = pause_avant
	Input.mouse_mode = souris_avant

func _rejoindre(identifiant: String) -> void:
	fermer()
	commandes.rejoindre(identifiant)

func _reinitialiser() -> void:
	commandes.reinitialiser()
	for case in cases.values(): case.set_pressed_no_signal(false)
	_journal("Aides réinitialisées ; session sans récompenses conservée")

func _process(_delta: float) -> void:
	if Time.get_ticks_msec() < prochaine_actualisation: return
	prochaine_actualisation = Time.get_ticks_msec() + 200
	commandes.actualiser_aides()
	var c: Dictionary = commandes.contexte()
	if c.salle != derniere_salle:
		derniere_salle = c.salle
		_journal("Changement de salle : " + derniere_salle)
	etat.text = commandes.diagnostic()
	indicateur.text = "DEBUG · sans récompenses · I" if Engine.get_meta("tutoriel_debug_actif", false) else "I · debug tutoriel"
	var victime = c.get("victime")
	boutons["Libérer la victime"].disabled = not is_instance_valid(victime) or victime.is_freed or victime.est_morte
	var foyers_actifs := 0
	for foyer in c.get("foyers_exercice", []):
		if foyer.intensite > 0: foyers_actifs += 1
	boutons["Éteindre les foyers"].disabled = foyers_actifs == 0
	var ennemi = c.get("ennemi")
	boutons["Vaincre l’ennemi"].disabled = not is_instance_valid(ennemi) or ennemi.est_mort
	boutons["Restaurer vie et réserve"].disabled = c.joueur.est_mort
	cases["Victimes protégées"].disabled = not is_instance_valid(victime)
	var ennemis_presents := false
	for corps in get_parent().find_children("*", "CharacterBody3D", true, false):
		if corps.has_method("choisir_cible"):
			ennemis_presents = true
			break
	cases["Ennemis suspendus"].disabled = not ennemis_presents
	cases["Joueur invulnérable"].set_pressed_no_signal(c.joueur.invincible)
	if c.etape != dernier_etat:
		dernier_etat = c.etape
		_journal("Étape : " + c.etape)
	historique.text = "\n".join(evenements)

func _journal(texte: String) -> void:
	evenements.append(texte)
	if evenements.size() > 12: evenements.pop_front()
	Engine.set_meta("tutoriel_debug_historique", evenements.duplicate())

func _ajout(noeud: Node) -> void:
	call_deferred("_brancher_id", noeud.get_instance_id())

func _brancher_id(identifiant: int) -> void:
	var noeud = instance_from_id(identifiant)
	if is_instance_valid(noeud) and get_parent().is_ancestor_of(noeud):
		_brancher(noeud)
		if noeud.has_method("choisir_cible"): _journal("Apparition d’une créature")

func _brancher(noeud: Node) -> void:
	for nom in ["freed", "foyer_eteint", "died", "prise_en_charge_terminee", "premier_sauvetage_reussi", "salle_reussie", "passage_degage", "ravitaillement_effectue", "carte_acquise"]:
		if not noeud.has_signal(nom): continue
		var libelle: String = {"freed": "Victime libérée", "foyer_eteint": "Foyer éteint", "died": "Mort : " + noeud.name, "prise_en_charge_terminee": "Victime prise en charge", "premier_sauvetage_reussi": "Sauvetage validé", "salle_reussie": "Objectif validé", "passage_degage": "Passage dégagé", "ravitaillement_effectue": "Vie et réserve restaurées", "carte_acquise": "Carte de formation acquise"}[nom]
		var nombre_arguments: int = 0
		for description in noeud.get_signal_list():
			if description.name == nom: nombre_arguments = description.args.size()
		var callback := _journal.bind(libelle)
		if nombre_arguments > 0: callback = callback.unbind(nombre_arguments)
		if not noeud.is_connected(nom, callback): noeud.connect(nom, callback)

func _exit_tree() -> void:
	if is_instance_valid(panneau) and panneau.visible:
		get_tree().paused = pause_avant
		Input.mouse_mode = souris_avant
	Engine.time_scale = 1.0
	if not is_instance_valid(commandes): return
	get_tree().debug_collisions_hint = commandes.collisions_initiales
	get_tree().debug_navigation_hint = commandes.navigation_initiale
