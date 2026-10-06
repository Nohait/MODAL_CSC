extends CanvasLayer

@export_range(0.2, 2.0, 0.05) var duree_rapprochement := 0.7
@export_range(0.1, 1.0, 0.05) var duree_apparition := 0.4
@export var son: AudioStream = preload("res://assets/sounds/interfaces/revelation_legendaire.wav")
@export_range(-40.0, 0.0, 1.0) var volume_db := -16.0
@export_range(8, 80) var nombre_braises := 32
const CARTE = preload("res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn")

func presenter(synergie: Synergie, catalogue: CatalogueAmeliorations) -> void:
	layer = 75 # Les notifications de succès restent visibles au-dessus.
	process_mode = Node.PROCESS_MODE_ALWAYS
	var fond := ColorRect.new()
	fond.color = Color(0.025, 0.035, 0.05, 0.96)
	add_child(fond)
	fond.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var titre := Label.new()
	titre.text = "SYNERGIE DÉCOUVERTE"
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_override("font", preload("res://assets/fonts/Almendra-Bold.ttf"))
	titre.add_theme_font_size_override("font_size", 42)
	titre.add_theme_color_override("font_color", Color("8ff4ef"))
	fond.add_child(titre)
	titre.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	titre.position.y = 40
	await get_tree().process_frame
	var centre := get_viewport().get_visible_rect().size / 2.0
	var cartes: Array[Control] = []
	for i in synergie.ingredients.size():
		var definition := catalogue.trouver(synergie.ingredients[i])
		if definition == null: continue
		var carte := _creer_carte(definition, fond)
		carte.scale = Vector2.ONE * 0.58
		carte.position = centre + Vector2((i - (synergie.ingredients.size() - 1) / 2.0) * 220.0 - 70.0, -100.0)
		cartes.append(carte)
	await get_tree().create_timer(0.4).timeout
	var fusion := create_tween().set_parallel(true)
	for carte in cartes:
		# Les cartes convergent ensemble ; seul leur visuel est consumé.
		fusion.tween_property(carte, "position", centre - Vector2(70, 100), duree_rapprochement).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
		fusion.tween_property(carte, "rotation", randf_range(-0.25, 0.25), duree_rapprochement)
	await fusion.finished
	var lecteur := AudioStreamPlayer.new()
	lecteur.stream = son
	lecteur.bus = "Effets"
	lecteur.volume_db = volume_db
	add_child(lecteur)
	if son != null: lecteur.play()
	var flash := ColorRect.new()
	flash.color = Color(0.5, 1.0, 0.9, 0.65)
	flash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fond.add_child(flash)
	flash.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	for carte in cartes: carte.queue_free()
	var braises := CPUParticles2D.new()
	braises.amount = nombre_braises
	braises.one_shot = true
	braises.explosiveness = 1.0
	braises.lifetime = 0.8
	braises.spread = 180.0
	braises.gravity = Vector2.ZERO
	braises.initial_velocity_min = 90.0
	braises.initial_velocity_max = 240.0
	braises.color = Color("8ff4ef")
	braises.position = centre
	var texture := GradientTexture2D.new()
	texture.width = 16
	texture.height = 16
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.5)
	texture.fill_to = Vector2(1.0, 0.5)
	texture.gradient = Gradient.new()
	texture.gradient.colors = PackedColorArray([Color.WHITE, Color(1, 1, 1, 0)])
	braises.texture = texture
	fond.add_child(braises)
	braises.restart()
	var resultat := _creer_carte(synergie.carte, fond)
	resultat.rarete = "synergie"
	resultat.position = centre - resultat.size / 2.0
	resultat.pivot_offset = resultat.size / 2.0
	resultat.scale = Vector2.ONE * 0.15
	var apparition := create_tween().set_parallel(true)
	apparition.tween_property(resultat, "scale", Vector2.ONE, duree_apparition).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	apparition.tween_property(flash, "color:a", 0.0, duree_apparition)
	await apparition.finished
	var continuer: Button = preload("res://scenes/interfaces/menus/titre/bouton_menu.tscn").instantiate()
	continuer.text = "Continuer"
	continuer.custom_minimum_size = Vector2(260, 48)
	fond.add_child(continuer)
	continuer.position = centre + Vector2(-130, 230)
	if not Input.get_connected_joypads().is_empty(): continuer.grab_focus()
	await continuer.pressed
	queue_free()

func _creer_carte(definition: Amelioration, parent: Control) -> Control:
	var carte: Control = CARTE.instantiate()
	carte.lecture_seule = true
	carte.titre = definition.titre
	carte.description = definition.description
	carte.effet_affiche = definition.texte_pour(definition.valeur)
	carte.illustration = definition.pictogramme
	carte.rarete = definition.rarete
	carte.statut = "SYNERGIE" if definition.rarete == "synergie" else "INGRÉDIENT"
	parent.add_child(carte)
	carte.preparer_consultation()
	carte.size = Vector2(240, 365)
	return carte
