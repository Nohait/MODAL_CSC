extends CanvasLayer

var joueur: Node3D
var upgrades: Node
var temps := 0.0
var contour: TextureRect
var secours: PanelContainer
var nombre_secours: Label
var eclat: MeshInstance3D
var animation_eclat: Tween
var animation_secours: Tween
var animation_message: Tween
var victimes_perdues_message := 0

func _ready() -> void:
	# Un second cadre peut pulser sans interrompre le flash habituel des dégâts.
	contour = TextureRect.new()
	contour.texture = joueur.BarreDeVie.get_node("Cadre").texture
	contour.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	contour.mouse_filter = Control.MOUSE_FILTER_IGNORE
	joueur.BarreDeVie.add_child(contour)
	contour.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	contour.hide()

	secours = PanelContainer.new()
	secours.mouse_filter = Control.MOUSE_FILTER_IGNORE
	secours.position = Vector2(348, 28)
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color("241d18")
	fond.border_color = Color("b8a17a")
	fond.set_border_width_all(1)
	fond.set_corner_radius_all(5)
	fond.set_content_margin_all(7)
	secours.add_theme_stylebox_override("panel", fond)
	joueur.get_node("Interface").add_child(secours)
	var ligne := HBoxContainer.new()
	secours.add_child(ligne)
	var icone := TextureRect.new()
	icone.texture = preload("res://assets/textures/interfaces/ameliorations/pictogrammes/reserve_secours.svg")
	icone.modulate = Color(2.6, 2.5, 2.2)
	icone.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icone.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icone.custom_minimum_size = Vector2(28, 28)
	ligne.add_child(icone)
	nombre_secours = Label.new()
	nombre_secours.add_theme_font_override("font", preload("res://assets/fonts/Oswald-SemiBold.ttf"))
	ligne.add_child(nombre_secours)
	upgrades.ameliorations_changees.connect(actualiser_secours)
	actualiser_secours()

	eclat = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 1.15
	sphere.height = 3.2
	eclat.mesh = sphere
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/effets/combat/eclat_bouclier.gdshader")
	eclat.material_override = mat
	joueur.add_child(eclat)
	eclat.position.y = 0.7
	eclat.hide()

func _process(delta: float) -> void:
	if not is_instance_valid(joueur): return
	temps += delta
	var arme = joueur.extincteur
	var actif: bool = arme.bonus_dernier_souffle > 0.0 and joueur.BarreDeVie.value <= joueur.BarreDeVie.max_value * arme.seuil_dernier_souffle / 100.0
	contour.visible = actif
	if actif:
		# Un cycle par seconde, discret ; la jauge conserve ses vraies valeurs.
		contour.self_modulate = Color(2.0, 0.5, 0.4, 0.25 + 0.2 * (sin(temps * TAU) + 1.0))

func actualiser_secours() -> void:
	var nombre := 0
	for acquisition in upgrades.acquisitions:
		if acquisition.definition.effet == "reserve_secours": nombre += 1
	secours.visible = nombre > 0
	nombre_secours.text = str(nombre)
	secours.tooltip_text = "Secours disponibles : %d" % nombre

func afficher_impact_bouclier() -> void:
	joueur.flash_degats(Color("59bde8"))
	if animation_eclat: animation_eclat.kill()
	eclat.show()
	eclat.scale = Vector3.ONE
	eclat.transparency = 0.0
	animation_eclat = create_tween().set_parallel(true)
	# Le contour s'élargit pendant qu'il s'efface, sans masquer le pompier.
	animation_eclat.tween_property(eclat, "scale", Vector3.ONE * 1.15, 0.25)
	animation_eclat.tween_property(eclat, "transparency", 1.0, 0.25)
	animation_eclat.chain().tween_callback(eclat.hide)

func afficher_secours() -> void:
	_afficher_message("Secours utilisé", preload("res://assets/textures/interfaces/ameliorations/pictogrammes/reserve_secours.svg"))
	if animation_secours: animation_secours.kill()
	$FlashSecours.show()
	$FlashSecours.color.a = 0.14
	animation_secours = create_tween()
	animation_secours.tween_property($FlashSecours, "color:a", 0.0, 0.35)
	animation_secours.tween_callback($FlashSecours.hide)

func afficher_victime_perdue() -> void:
	# Regrouper les pertes rapprochées évite d'empiler des notifications.
	victimes_perdues_message = victimes_perdues_message + 1 if $Message.visible and $Message/Marge/Ligne/Texte.text.begins_with("Victime perdue") else 1
	var texte := "Victime perdue" if victimes_perdues_message == 1 else "Victime perdue ×%d" % victimes_perdues_message
	_afficher_message(texte, preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg"))

func _afficher_message(texte: String, icone: Texture2D) -> void:
	if animation_message: animation_message.kill()
	$Message/Marge/Ligne/Texte.text = texte
	$Message/Marge/Ligne/Icone.texture = icone
	$Message.show()
	$Message.modulate.a = 0.0
	animation_message = create_tween()
	# Un petit parchemin sous le bouton Bonus : fondu court, une seconde de lecture.
	animation_message.tween_property($Message, "modulate:a", 1.0, 0.12)
	animation_message.tween_interval(1.0)
	animation_message.tween_property($Message, "modulate:a", 0.0, 0.25)
	animation_message.tween_callback($Message.hide)
