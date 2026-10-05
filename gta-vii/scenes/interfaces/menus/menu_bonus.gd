extends CanvasLayer

# Ce menu appartient au niveau et lit le gestionnaire ; il ne calcule aucun bonus.
@onready var gestionnaire = get_parent().get_node("VictimManager")
@onready var raccourci: Button = $Raccourci
@onready var menu: Control = $Menu
@onready var panneau: Control = %Panneau
@onready var fermer: Button = %Fermer
const CARTE = preload("res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn")

@onready var upgrades = get_parent().get_node("UpgradeManager")
@onready var cartes_permanents: HFlowContainer = %CartesPermanents
@onready var vide_permanents: Label = %VidePermanents
@onready var cartes_temporaires: HFlowContainer = %CartesTemporaires
@onready var vide_temporaires: Label = %VideTemporaires
@onready var papier: TextureRect = $Menu/Panneau/Papier
var temps_braises := 0.0
var souris_avant: int
var pause_avant := false
@onready var statistiques = %Statistiques
var animation: Tween
var animation_raccourci: Tween
var accent_survol := 0.0
var temps_booster := 0.0
@onready var onglet_bonus: Button = %OngletBonus
@onready var onglet_glossaire: Button = %OngletGlossaire
@onready var glossaire: Control = %Glossaire
@onready var contenu_bonus: Control = $Menu/Panneau/Marge/Disposition/Defilement
@onready var ouverture_booster: Control = $OuvertureBooster


func _ready() -> void:
	for onglet in [onglet_bonus, onglet_glossaire]:
		var papier_onglet: TextureRect = onglet.get_node("Papier")
		papier_onglet.material = papier_onglet.material.duplicate()
		papier_onglet.material.set_shader_parameter("selection", 0.0)
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(menu)
	# Process Mode = Always dans la scène : le menu et son animation vivent en pause.
	raccourci.get_node("Fond").material = raccourci.get_node("Fond").material.duplicate()
	raccourci.pressed.connect(ouvrir_menu)
	raccourci.mouse_entered.connect(_animer_raccourci.bind(true))
	raccourci.mouse_exited.connect(_animer_raccourci.bind(false))
	fermer.pressed.connect(fermer_menu)
	%Options.pressed.connect(Reglages.ouvrir)
	onglet_bonus.pressed.connect(_choisir_onglet.bind(false))
	onglet_glossaire.pressed.connect(_choisir_onglet.bind(true))
	_choisir_onglet(false)
	upgrades.ameliorations_changees.connect(actualiser_affichage)
	papier.material = papier.material.duplicate()
	papier.resized.connect(_actualiser_taille_papier)
	_actualiser_taille_papier.call_deferred()
	actualiser_affichage()


func _actualiser_taille_papier() -> void:
	papier.material.set_shader_parameter("taille", papier.size)


func _process(delta: float) -> void:
	temps_booster += delta
	for onglet in [onglet_bonus, onglet_glossaire]:
		var fond_onglet: TextureRect = onglet.get_node("Papier")
		var cible := 1.0 if onglet.button_pressed else (0.45 if onglet.is_hovered() or onglet.has_focus() else 0.0)
		var accent: float = fond_onglet.material.get_shader_parameter("selection")
		# Éclaircir progressivement le papier au survol et sur l'onglet actif.
		fond_onglet.material.set_shader_parameter("selection", lerpf(accent, cible, 1.0 - exp(-12.0 * delta)))
		fond_onglet.material.set_shader_parameter("horloge", temps_booster)
		fond_onglet.material.set_shader_parameter("taille", onglet.size)
	var fond: TextureRect = raccourci.get_node("Fond")
	fond.material.set_shader_parameter("horloge", temps_booster)
	fond.material.set_shader_parameter("taille", raccourci.size)
	fond.material.set_shader_parameter("survol", accent_survol)
	if menu.visible:
		# Même horloge que les cartes : les braises restent animées pendant la pause.
		temps_braises += delta
		papier.material.set_shader_parameter("horloge", temps_braises)


func _input(event: InputEvent) -> void:
	# _input reçoit B/Échap même si un bouton du menu possède le focus clavier.
	if event.is_echo():
		return
	if menu.visible:
		if event.is_action_pressed("menu_bonus") or event.is_action_pressed("ui_cancel"):
			fermer_menu()
			get_viewport().set_input_as_handled()
	elif event.is_action_pressed("menu_bonus") and peut_ouvrir():
		ouvrir_menu()
		get_viewport().set_input_as_handled()


func peut_ouvrir() -> bool:
	if menu.visible or not is_instance_valid(gestionnaire.player) or gestionnaire.player.est_mort:
		return false
	# La boutique permet la consultation, mais pas pendant l'ouverture d'un booster.
	var en_boutique: bool = upgrades.boutique_ouverte and not upgrades.choix_ouverts and upgrades.boutique.visible
	if get_tree().paused: return en_boutique
	return not get_parent().get_node("Salles/RoomManager").transition_en_cours

func ouvrir_menu() -> void:
	if not peut_ouvrir(): return
	_choisir_onglet(false)
	pause_avant = get_tree().paused
	fermer.text = "Retour à la boutique" if pause_avant else "Reprendre"
	gestionnaire.player.extincteur.stop_primary_attack()
	actualiser_affichage()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	menu.show()
	ouverture_booster.lancer(raccourci)
	raccourci.hide()
	# Interrompre le fondu précédent si le menu est rouvert rapidement.
	if animation:
		animation.kill()
	menu.modulate.a = 0.0
	# On place le pivot au centre pour faire un agrandissement depuis le centre
	panneau.pivot_offset = panneau.size / 2.0
	panneau.scale = Vector2(0.94, 0.94)
	animation = create_tween().set_parallel(true)
	# Le fondu et l'agrandissement se jouent EN MÊME TEMPS, malgré la pause.
	# Le menu apparaît après le début de la déchirure, sans attendre la fin du fondu.
	animation.tween_property(menu, "modulate:a", 1.0, 0.18).set_delay(0.22)
	animation.tween_property(panneau, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT).set_delay(0.22)


func fermer_menu() -> void:
	# Restaurer la pause précédente : la boutique doit rester en pause au retour.
	if not menu.visible:
		return
	if animation:
		animation.kill()
	ouverture_booster.masquer()
	menu.hide()
	raccourci.show()
	fermer.release_focus()
	Input.mouse_mode = souris_avant
	get_tree().paused = pause_avant


func actualiser_affichage() -> void:
	# Les signaux arrivent après le recalcul des effets. Le menu ne les applique jamais.
	var joueur = gestionnaire.player
	if not is_instance_valid(joueur):
		return
	statistiques.actualiser(joueur, upgrades)
	# Compter seulement les améliorations acquises pour cette partie.
	var nombre := 0
	for niveau in upgrades.niveaux.values():
		nombre += int(niveau)
	var touches := InputMap.action_get_events("menu_bonus")
	var touche := touches[0].as_text() if not touches.is_empty() else "B"
	if not touches.is_empty() and touches[0] is InputEventKey:
		var evenement: InputEventKey = touches[0]
		touche = OS.get_keycode_string(evenement.physical_keycode if evenement.physical_keycode else evenement.keycode)
	raccourci.get_node("Touche").text = "[%s]" % touche
	raccourci.get_node("Nombre").text = "%d amélioration%s" % [nombre, "s" if nombre > 1 else ""]
	raccourci.tooltip_text = "Ouvrir le carnet (%s)" % touche

	_vider_cartes(cartes_permanents)
	_vider_cartes(cartes_temporaires)
	for acquisition in upgrades.acquisitions:
		var definition: Amelioration = acquisition.definition
		var temporaire := definition.type_bonus == "temporaire"
		var carte = CARTE.instantiate()
		carte.lecture_seule = true
		carte.identifiant = definition.identifiant
		carte.titre = definition.titre
		carte.description = definition.description
		carte.illustration = definition.pictogramme
		carte.rarete = acquisition.rarete
		carte.categorie = definition.type_bonus.to_upper()
		carte.effet_affiche = upgrades.formater_effet(definition.identifiant, acquisition.gain)
		if definition.effet in ["bouclier_camion", "bouclier_joueur"]:
			carte.effet_affiche = "Bouclier : %d / %d PV" % [ceili(acquisition.bouclier_restant), ceili(acquisition.gain)]
		carte.duree_affichee = upgrades.texte_duree(acquisition.restant) if temporaire else ""
		carte.statut = "1 SECOURS DISPONIBLE" if definition.effet == "reserve_secours" else ("ACTIF" if temporaire else "ACQUIS POUR CETTE PARTIE")
		var destination := cartes_temporaires if temporaire else cartes_permanents
		destination.add_child(carte)
	vide_permanents.visible = cartes_permanents.get_child_count() == 0
	vide_temporaires.visible = cartes_temporaires.get_child_count() == 0


func _vider_cartes(conteneur: Container) -> void:
	# Retirer immédiatement évite de compter les cartes en attente de queue_free().
	for carte in conteneur.get_children():
		conteneur.remove_child(carte)
		carte.queue_free()


func _animer_raccourci(survole: bool) -> void:
	if animation_raccourci:
		animation_raccourci.kill()
	# Le reflet métallisé glisse progressivement au survol.
	animation_raccourci = create_tween()
	animation_raccourci.tween_property(self, "accent_survol",
		1.0 if survole else 0.0, 0.15)

func _choisir_onglet(ouvrir_glossaire: bool) -> void:
	contenu_bonus.visible = not ouvrir_glossaire
	glossaire.visible = ouvrir_glossaire
	onglet_bonus.set_pressed_no_signal(not ouvrir_glossaire)
	onglet_glossaire.set_pressed_no_signal(ouvrir_glossaire)
	if ouvrir_glossaire: glossaire.actualiser()
