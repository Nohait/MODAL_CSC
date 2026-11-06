extends HBoxContainer

const POLICE = preload("res://assets/fonts/rubik/accent.tres")
const APERCU = preload("res://scenes/systemes/ennemis/apercu_ennemi.gd")
@export_range(0.05, 0.5, 0.05) var marge_cadrage := 0.15
var catalogue: Node
var liste: VBoxContainer
var versions: HFlowContainer
var titre: Label
var description: Label
var question: Label
var pivot: Node3D
var viewport: SubViewport
var camera: Camera3D
var centre_apercu := Vector3.ZERO
var rayon_apercu := 1.0
var revision_apercu := 0
var couches_apercu := 0
var fiche_actuelle: Dictionary = {}
var version_actuelle := "normal"
var boutons_versions: Dictionary = {}

func _ready() -> void:
	add_to_group("debug_glossaire")
	catalogue = get_node("/root/CatalogueEnnemis")
	add_theme_constant_override("separation", 24)
	add_theme_font_override("font", POLICE)
	add_theme_color_override("font_color", Color("efd9b5"))
	var colonne := VBoxContainer.new()
	colonne.custom_minimum_size.x = 230
	add_child(colonne)
	var defilement := ScrollContainer.new()
	defilement.size_flags_vertical = Control.SIZE_EXPAND_FILL
	defilement.custom_minimum_size.x = 230
	defilement.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	colonne.add_child(defilement)
	liste = VBoxContainer.new()
	liste.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	liste.add_theme_constant_override("separation", 8)
	defilement.add_child(liste)
	var fiche := VBoxContainer.new()
	fiche.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	fiche.add_theme_constant_override("separation", 12)
	add_child(fiche)
	titre = _texte("Rencontrez un ennemi pour découvrir sa fiche.", 28)
	fiche.add_child(titre)
	versions = HFlowContainer.new()
	versions.add_theme_constant_override("h_separation", 8)
	versions.add_theme_constant_override("v_separation", 8)
	fiche.add_child(versions)
	var cadre := PanelContainer.new()
	cadre.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var fond := StyleBoxFlat.new()
	fond.bg_color = Color(0.07, 0.09, 0.11, 0.85)
	fond.border_color = Color("936443")
	fond.set_border_width_all(1)
	fond.set_corner_radius_all(12)
	cadre.add_theme_stylebox_override("panel", fond)
	fiche.add_child(cadre)
	var affichage := SubViewportContainer.new()
	affichage.stretch = true
	affichage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_child(affichage)
	viewport = SubViewport.new()
	viewport.size = Vector2i(700, 350)
	viewport.own_world_3d = true
	viewport.transparent_bg = true
	viewport.render_target_update_mode = SubViewport.UPDATE_WHEN_VISIBLE
	affichage.add_child(viewport)
	var environnement := WorldEnvironment.new()
	environnement.environment = Environment.new()
	environnement.environment.background_mode = Environment.BG_COLOR
	environnement.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environnement.environment.ambient_light_color = Color(0.85, 0.8, 0.75)
	environnement.environment.ambient_light_energy = 0.7
	viewport.add_child(environnement)
	camera = Camera3D.new()
	couches_apercu = camera.cull_mask
	camera.position = Vector3(0, 1.8, 6)
	camera.fov = 38
	viewport.add_child(camera)
	camera.look_at(Vector3(0, 1.4, 0))
	viewport.size_changed.connect(_cadrer_camera)
	var lumiere := DirectionalLight3D.new()
	lumiere.rotation_degrees = Vector3(-40, -35, 0)
	lumiere.light_color = Color(1, 0.8, 0.55)
	lumiere.light_energy = 1.3
	viewport.add_child(lumiere)
	pivot = Node3D.new()
	viewport.add_child(pivot)
	question = _texte("?", 100)
	question.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	question.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	question.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cadre.add_child(question)
	description = _texte("Les découvertes sont conservées entre les parties.", 18)
	description.custom_minimum_size.y = 70
	fiche.add_child(description)
	catalogue.rencontre_ajoutee.connect(actualiser)
	actualiser()

func _texte(texte: String, taille: int) -> Label:
	var label := Label.new()
	label.text = texte
	label.add_theme_font_size_override("font_size", taille)
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return label

func _bouton(texte: String, couleur := Color("efd9b5")) -> Button:
	var bouton := preload("res://scenes/interfaces/menus/glossaire/bouton_glossaire.gd").new()
	bouton.accent = couleur
	bouton.text = texte
	bouton.custom_minimum_size.y = 40
	bouton.add_theme_color_override("font_color", couleur)
	bouton.add_theme_color_override("font_disabled_color", Color("88786f"))
	return bouton

func actualiser() -> void:
	_vider(liste)
	for fiche in catalogue.CATALOGUE.ENNEMIS:
		var connue: bool = catalogue.a_rencontre(fiche.id)
		var bouton := _bouton(fiche.nom if connue else "? — Non rencontré")
		bouton.disabled = not connue
		bouton.pressed.connect(_ouvrir_fiche.bind(fiche))
		liste.add_child(bouton)
	if is_visible_in_tree() and not fiche_actuelle.is_empty():
		var precedente := version_actuelle
		_ouvrir_fiche(fiche_actuelle)
		if catalogue.a_rencontre(fiche_actuelle.id, precedente): _afficher_version(precedente)

func _ouvrir_fiche(fiche: Dictionary) -> void:
	fiche_actuelle = fiche
	titre.text = fiche.nom
	_vider(versions)
	boutons_versions.clear()
	_ajouter_version("normal", "Classique", Color("efd9b5"))
	_ajouter_version("doree", "Dorée", Color("f7c443"))
	if fiche.get("elite_possible", false):
		for mod in catalogue.MODIFICATEURS:
			_ajouter_version(mod.identifiant, mod.titre, mod.couleur)
	var premiere: String = catalogue.rencontres[fiche.id][0]
	_afficher_version(premiere)

func _ajouter_version(id: String, nom: String, couleur: Color) -> void:
	var connue: bool = catalogue.a_rencontre(fiche_actuelle.id, id)
	var bouton := _bouton(nom if connue else "?", couleur if connue else Color("88786f"))
	bouton.disabled = not connue
	bouton.toggle_mode = true
	boutons_versions[id] = bouton
	bouton.pressed.connect(_afficher_version.bind(id))
	versions.add_child(bouton)

func _afficher_version(id: String) -> void:
	revision_apercu += 1
	var revision := revision_apercu
	version_actuelle = id
	for variante in boutons_versions:
		boutons_versions[variante].set_pressed_no_signal(variante == id)
	_vider(pivot)
	var visuel := APERCU.creer(load(fiche_actuelle.scene), viewport)
	camera.cull_mask = 0
	pivot.add_child(visuel)
	APERCU.preparer_pose(visuel)
	# Le rendu doit recevoir les matrices des os avant de mesurer leur pose.
	await RenderingServer.frame_post_draw
	if revision != revision_apercu or not is_instance_valid(visuel): return
	var boite: AABB = APERCU.mesurer(visuel)
	var habillage: Node3D
	if boite.size.y > 0.01:
		visuel.scale = Vector3.ONE * minf(2.6 / boite.size.y, 3.2 / maxf(boite.size.x, boite.size.z))
		visuel.position = Vector3(-boite.get_center().x, -boite.position.y, -boite.get_center().z) * visuel.scale
	question.hide()
	description.text = "Version classique.
Les variantes inconnues restent marquées d’un ?."
	if id == "doree":
		var effet_dore = preload("res://scenes/systemes/ennemis/ennemi_dore.gd").new()
		visuel.add_child(effet_dore)
		description.text = "Version dorée — rapporte cinq fois son butin habituel."
	for mod in catalogue.MODIFICATEURS:
		if mod.identifiant != id: continue
		var effet = catalogue.ELITE.new()
		effet.definition = mod
		effet.presentation = true
		effet.process_mode = Node.PROCESS_MODE_ALWAYS
		visuel.add_child(effet)
		habillage = effet
		description.text = "%s — %s" % [mod.titre, mod.description]
		break
	# Tenir compte aussi du Colosse, puis laisser une marge pendant toute la rotation.
	var boite_cadrage := boite
	if habillage != null:
		for element in habillage.find_children("*", "GeometryInstance3D", true, false):
			if element is MeshInstance3D or element is Label3D:
				var limites: AABB = (visuel.global_transform.affine_inverse() * element.global_transform) * element.get_aabb()
				boite_cadrage = boite_cadrage.merge(limites)
	centre_apercu = Vector3(0, visuel.position.y + boite_cadrage.get_center().y * visuel.scale.y, 0)
	rayon_apercu = 0.1
	for coin in range(8):
		var position_coin := visuel.position + boite_cadrage.get_endpoint(coin) * visuel.scale
		rayon_apercu = maxf(rayon_apercu, position_coin.distance_to(centre_apercu))
	_cadrer_camera()
	camera.cull_mask = couches_apercu
	if not Input.get_connected_joypads().is_empty() and not versions.get_children().has(get_viewport().gui_get_focus_owner()):
		# Rester dans la fiche après avoir activé un bouton du catalogue.
		for bouton in versions.get_children():
			if not bouton.disabled:
				bouton.focus_mode = Control.FOCUS_ALL
				bouton.grab_focus()
				break

func _cadrer_camera() -> void:
	if camera == null or viewport.size.y <= 0: return
	var angle_vertical := deg_to_rad(camera.fov * 0.5)
	var aspect := float(viewport.size.x) / float(viewport.size.y)
	var angle_horizontal := atan(tan(angle_vertical) * aspect)
	var distance := rayon_apercu * (1.0 + marge_cadrage) / sin(minf(angle_vertical, angle_horizontal))
	camera.position = centre_apercu + Vector3(0, 0.12, 1).normalized() * distance
	camera.look_at(centre_apercu)

func _process(delta: float) -> void:
	if is_visible_in_tree(): pivot.rotate_y(delta * 0.22)

func _vider(parent: Node) -> void:
	for enfant in parent.get_children():
		parent.remove_child(enfant)
		enfant.queue_free()

func debug_contextuel() -> bool:
	if not is_visible_in_tree(): return false
	catalogue.debloquer_tout()
	return true
