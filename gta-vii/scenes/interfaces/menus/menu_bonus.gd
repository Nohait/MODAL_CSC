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
@onready var papier: TextureRect = $Menu/Panneau/Papier
var temps_braises := 0.0
var souris_avant: int
var animation: Tween
var animation_raccourci: Tween
var accent_survol := 0.0
var temps_booster := 0.0
@onready var ouverture_booster: Control = $OuvertureBooster


func _ready() -> void:
	# Process Mode = Always dans la scène : le menu et son animation vivent en pause.
	raccourci.get_node("Fond").material = raccourci.get_node("Fond").material.duplicate()
	raccourci.pressed.connect(ouvrir_menu)
	raccourci.mouse_entered.connect(_animer_raccourci.bind(true))
	raccourci.mouse_exited.connect(_animer_raccourci.bind(false))
	fermer.pressed.connect(fermer_menu)
	upgrades.ameliorations_changees.connect(actualiser_affichage)
	papier.material = papier.material.duplicate()
	papier.resized.connect(_actualiser_taille_papier)
	_actualiser_taille_papier.call_deferred()
	actualiser_affichage()


func _actualiser_taille_papier() -> void:
	papier.material.set_shader_parameter("taille", papier.size)


func _process(delta: float) -> void:
	temps_booster += delta
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
	elif event.is_action_pressed("menu_bonus") and not get_tree().paused:
		ouvrir_menu()
		get_viewport().set_input_as_handled()


func ouvrir_menu() -> void:
	# Ne pas suspendre la préparation de la navigation pendant un changement de salle.
	if get_parent().get_node("Salles/RoomManager").transition_en_cours:
		return
	# Ne pas superposer ce menu à celui d'évacuation, qui possède déjà la pause.
	if menu.visible or get_tree().paused or not is_instance_valid(gestionnaire.player):
		return
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
	fermer.grab_focus()


func fermer_menu() -> void:
	# Seul le menu qui a ouvert la pause a le droit de la retirer.
	if not menu.visible:
		return
	if animation:
		animation.kill()
	ouverture_booster.masquer()
	menu.hide()
	raccourci.show()
	fermer.release_focus()
	Input.mouse_mode = souris_avant
	get_tree().paused = false


func actualiser_affichage() -> void:
	# Les signaux arrivent après le recalcul des effets. Le menu ne les applique jamais.
	var joueur = gestionnaire.player
	if not is_instance_valid(joueur):
		return
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
	raccourci.tooltip_text = "Ouvrir les bonus (%s)" % touche

	_vider_cartes(cartes_permanents)
	# Chaque carte acquise conserve sa rareté et le gain réellement obtenu.
	for acquisition in upgrades.acquisitions:
		for proposition in upgrades.POOL:
			if proposition.id != acquisition.id:
				continue
			_ajouter_carte(cartes_permanents, proposition.id, proposition.titre,
				proposition.description, upgrades.formater_effet(proposition.id, acquisition.gain),
				"EXTINCTEUR · " + upgrades.CATALOGUE.NOMS[acquisition.rarete].to_upper(),
				"ACQUISE POUR CETTE PARTIE", null, acquisition.rarete)
	vide_permanents.visible = cartes_permanents.get_child_count() == 0


func _vider_cartes(conteneur: Container) -> void:
	# Retirer immédiatement évite de compter les cartes en attente de queue_free().
	for carte in conteneur.get_children():
		conteneur.remove_child(carte)
		carte.queue_free()


func _ajouter_carte(conteneur: Container, identifiant: StringName, titre: String,
		description: String, effet: String, categorie: String, statut: String,
		illustration: Texture2D = null, rarete: StringName = &"aucune") -> void:
	var carte = CARTE.instantiate()
	carte.lecture_seule = true
	carte.rarete = rarete
	carte.identifiant = identifiant
	carte.titre = titre
	carte.description = description
	carte.effet_affiche = effet
	carte.categorie = categorie
	carte.statut = statut
	if illustration != null:
		carte.illustration = illustration
	# Aucun signal selected connecté : consulter une carte n'octroie rien.
	conteneur.add_child(carte)

func _animer_raccourci(survole: bool) -> void:
	if animation_raccourci:
		animation_raccourci.kill()
	# Le reflet métallisé glisse progressivement au survol.
	animation_raccourci = create_tween()
	animation_raccourci.tween_property(self, "accent_survol",
		1.0 if survole else 0.0, 0.15)
