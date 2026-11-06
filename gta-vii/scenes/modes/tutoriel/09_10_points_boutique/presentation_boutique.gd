extends CanvasLayer

const ETAPES = [
	["Bienvenue dans la boutique", "Après chaque salle, vous pourrez faire une halte ici pour préparer la suite de l’intervention.", ""],
	["Votre escorte vous rapporte des points", "À chaque fin de salle, chaque victime encore en vie qui vous suit vous rapporte un point. Les points non dépensés sont perdus en quittant la boutique.", "points"],
	["Choisissez vos améliorations", "Dépensez vos points pour acheter des boosters. Ouvrez-en un, puis choisissez une amélioration parmi les cartes proposées. Les pochettes plus lumineuses sont celles que vous pouvez acheter.", "boosters"],
	["Pensez aux soins", "Les boosters Intervention peuvent proposer des soins et des protections. Pensez-y lorsque votre vie ou celle des victimes commence à baisser !", "intervention"],
	["Vérifiez la santé du groupe", "Votre santé et celle des victimes escortées sont affichées ici. Si l’escorte est nombreuse, « Afficher plus » permet de consulter tout le groupe. Vous pouvez maintenant choisir vos achats.", "sante"]
]

var boutique: Control
var indice := 0
var voile: Control
var panneau: PanelContainer
var titre: Label
var texte: Label
var suivant: Button
var precedent: Button
var cible: Control
var focus_precedent: Control

func _ready() -> void:
	layer = 85
	process_mode = Node.PROCESS_MODE_ALWAYS
	focus_precedent = get_viewport().gui_get_focus_owner()
	voile = Control.new()
	add_child(voile)
	voile.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	voile.mouse_filter = Control.MOUSE_FILTER_STOP
	voile.draw.connect(_dessiner)
	panneau = PanelContainer.new()
	panneau.theme = preload("res://scenes/interfaces/theme_intervention/theme.tres")
	voile.add_child(panneau)
	var marge := MarginContainer.new()
	for cote in ["left", "right", "top", "bottom"]:
		marge.add_theme_constant_override("margin_" + cote, 18)
	panneau.add_child(marge)
	var colonne := VBoxContainer.new()
	colonne.add_theme_constant_override("separation", 12)
	marge.add_child(colonne)
	titre = Label.new()
	titre.add_theme_font_size_override("font_size", 23)
	titre.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(titre)
	texte = Label.new()
	texte.add_theme_font_size_override("font_size", 19)
	texte.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	colonne.add_child(texte)
	var boutons := HBoxContainer.new()
	boutons.alignment = BoxContainer.ALIGNMENT_END
	colonne.add_child(boutons)
	precedent = Button.new()
	precedent.text = "Précédent"
	precedent.pressed.connect(func(): _afficher(indice - 1))
	boutons.add_child(precedent)
	suivant = Button.new()
	suivant.pressed.connect(_suivant)
	boutons.add_child(suivant)
	_afficher(0)

func _afficher(numero: int) -> void:
	indice = clampi(numero, 0, ETAPES.size() - 1)
	titre.text = "%d / %d · %s" % [indice + 1, ETAPES.size(), ETAPES[indice][0]]
	texte.text = ETAPES[indice][1]
	cible = boutique.reperes_formation.get(ETAPES[indice][2]) as Control
	if is_instance_valid(cible):
		var parent := cible.get_parent()
		while parent != null and not parent is ScrollContainer:
			parent = parent.get_parent()
		if parent is ScrollContainer:
			parent.ensure_control_visible(cible)
	precedent.disabled = indice == 0
	suivant.text = "Voir les offres" if indice == ETAPES.size() - 1 else "Suivant"
	suivant.grab_focus()

func _process(_delta: float) -> void:
	if not is_instance_valid(boutique) or not boutique.is_visible_in_tree():
		queue_free()
		return
	var dimensions := get_viewport().get_visible_rect().size
	panneau.size.x = minf(620.0, dimensions.x - 48.0)
	# Le texte reste à l'opposé de l'élément expliqué.
	var en_bas := not is_instance_valid(cible) or cible.get_global_rect().get_center().y < dimensions.y * 0.5
	panneau.position = Vector2((dimensions.x - panneau.size.x) * 0.5, dimensions.y - panneau.size.y - 24.0 if en_bas else 24.0)
	voile.queue_redraw()

func _dessiner() -> void:
	var ecran := get_viewport().get_visible_rect()
	var sombre := Color(0.062745, 0.062745, 0.062745, 0.72)
	if not is_instance_valid(cible):
		voile.draw_rect(ecran, sombre)
		return
	var trou := cible.get_global_rect().grow(6.0).intersection(ecran)
	voile.draw_rect(Rect2(0, 0, ecran.size.x, trou.position.y), sombre)
	voile.draw_rect(Rect2(0, trou.end.y, ecran.size.x, ecran.size.y - trou.end.y), sombre)
	voile.draw_rect(Rect2(0, trou.position.y, trou.position.x, trou.size.y), sombre)
	voile.draw_rect(Rect2(trou.end.x, trou.position.y, ecran.size.x - trou.end.x, trou.size.y), sombre)
	voile.draw_rect(trou, Color("f5f5f0"), false, 2.0)

func _input(event: InputEvent) -> void:
	# La présentation est modale : aucun raccourci ne doit acheter ou fermer derrière.
	if event is InputEventKey or event is InputEventJoypadButton or event is InputEventJoypadMotion:
		if event.is_action_pressed("ui_accept") and not event.is_echo(): _suivant()
		elif event.is_action_pressed("ui_left") and not event.is_echo(): _afficher(indice - 1)
		get_viewport().set_input_as_handled()

func _suivant() -> void:
	if indice < ETAPES.size() - 1:
		_afficher(indice + 1)
	else:
		if is_instance_valid(focus_precedent) and focus_precedent.is_visible_in_tree(): focus_precedent.grab_focus()
		queue_free()
