extends CanvasLayer

# Ce menu appartient au niveau et lit le gestionnaire ; il ne calcule aucun bonus.
@onready var gestionnaire = get_parent().get_node("VictimManager")
@onready var raccourci: Button = $Raccourci
@onready var menu: Control = $Menu
@onready var panneau: PanelContainer = %Panneau
@onready var fermer: Button = %Fermer
@onready var carte_dash: PanelContainer = %CarteDash
@onready var carte_degats: PanelContainer = %CarteDegats
@onready var etat_dash: Label = %EtatDash
@onready var etat_degats: Label = %EtatDegats
@onready var aucune_escorte: Label = %AucunBonusEscorte
var souris_avant: int
var animation: Tween


func _ready() -> void:
	# Process Mode = Always dans la scène : le menu et son animation vivent en pause.
	raccourci.pressed.connect(ouvrir_menu)
	fermer.pressed.connect(fermer_menu)
	gestionnaire.escort_changed.connect(actualiser_affichage)
	actualiser_affichage()


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
	# Ne pas superposer ce menu à celui d'évacuation, qui possède déjà la pause.
	if menu.visible or get_tree().paused or not is_instance_valid(gestionnaire.player):
		return
	actualiser_affichage()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	menu.show()
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
	animation.tween_property(menu, "modulate:a", 1.0, 0.18)
	animation.tween_property(panneau, "scale", Vector2.ONE, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	fermer.grab_focus()


func fermer_menu() -> void:
	# Seul le menu qui a ouvert la pause a le droit de la retirer.
	if not menu.visible:
		return
	if animation:
		animation.kill()
	menu.hide()
	raccourci.show()
	fermer.release_focus()
	Input.mouse_mode = souris_avant
	get_tree().paused = false


func actualiser_affichage() -> void:
	# escort_changed arrive APRÈS le recalcul des bonus dans le VictimManager.
	var joueur = gestionnaire.player
	if not is_instance_valid(joueur):
		return
	var dash_actif: bool = joueur.bonus_dash_actif
	var degats_actifs: bool = joueur.Extincteur.bonus_degats_actif
	var nombre := int(dash_actif) + int(degats_actifs)
	var touches := InputMap.action_get_events("menu_bonus")
	var touche := touches[0].as_text() if not touches.is_empty() else "B"
	raccourci.text = "[%s] Bonus · %d actif(s)" % [touche, nombre]
	# Masquer les bonus non possédés pour ne révéler ni leur nom ni leur effet.
	# Le HFlowContainer ne réserve pas de place aux cartes masquées.
	carte_dash.visible = dash_actif
	carte_degats.visible = degats_actifs
	aucune_escorte.visible = nombre == 0
	etat_dash.text = "ACTIF · délai %.2f s" % joueur.get_dash_cooldown()
	etat_degats.text = "ACTIF · dégâts de base ×1,25"
