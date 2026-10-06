@tool
extends Control

## La carte annonce un choix. Le gestionnaire applique l'effet et change de salle.
## Le signal existant est conservé sans argument : le gestionnaire pourra utiliser bind(carte).
signal selected
signal revelee(rarete_obtenue: StringName)

@export_group("Consultation")
## Mode utilisé dans le menu des bonus : aucune sélection ni récompense au clic.
@export var lecture_seule := false
@export var statut := "ACQUISE POUR CETTE PARTIE"

@export_group("Contenu")
const CATALOGUE = preload("res://scenes/interfaces/menus/boutique/catalogue_boutique.gd")
@export_enum("aucune", "commun", "rare", "epique", "legendaire", "temporaire") var rarete: String = "aucune":
	set(valeur):
		rarete = valeur
		if is_node_ready():
			actualiser_contenu()
## Identifiant stable utilisé par le pool ; aucun effet de jeu n'est appliqué ici.
@export var identifiant: StringName = &"pression"
@export var titre := "Sous pression":
	set(valeur):
		titre = valeur
		if is_node_ready():
			actualiser_contenu()
@export_multiline var description := "Un jet plus puissant pour repousser les flammes.":
	set(valeur):
		description = valeur
		if is_node_ready():
			actualiser_contenu()
@export var effet_affiche := "+20 % de dégâts":
	set(valeur):
		effet_affiche = valeur
		if is_node_ready():
			actualiser_contenu()
@export var categorie := "EXTINCTEUR":
	set(valeur):
		categorie = valeur
		if is_node_ready():
			actualiser_contenu()
@export var illustration: Texture2D = preload("res://assets/textures/interfaces/ameliorations/pictogrammes/pression.svg"):
	set(valeur):
		illustration = valeur
		if is_node_ready():
			actualiser_contenu()

# Texte visible en grand pour distinguer une durée d’un soin instantané.
@export var duree_affichee := "":
	set(valeur):
		duree_affichee = valeur
		if is_node_ready(): actualiser_contenu()

@export_group("Animation")
## Agrandissement du visuel seulement : le rectangle cliquable et les containers restent stables.
@export_range(1.0, 1.15, 0.01) var hover_scale := 1.035
@export_range(0.05, 1.0, 0.01) var hover_duration := 0.18
## Mettre zéro pour conserver uniquement les bordures carbonisées.
@export_range(0.0, 2.0, 0.05) var intensite_braises := 0.8

@onready var visuel: Control = $Visuel
@onready var papier: TextureRect = $Visuel/TextureCarte
@onready var image: TextureRect = $Visuel/Contenu/Organisation/Illustration/Image
@onready var invitation: Label = $Visuel/Contenu/Organisation/Invitation
var materiau_papier: ShaderMaterial
var hover_tween: Tween
var souris_dessus := false
var accent := 0.0
var temps_animation := 0.0
var en_revelation := false
var revelation_tween: Tween
var dos_carte: TextureRect
var intensite_repos := 0.8
var niveau_rarete := 0

# Le dos utilise le papier existant ; le contenu reste caché jusqu'au retournement.
func preparer_revelation() -> void:
	en_revelation = true
	intensite_repos = intensite_braises
	set_meta("revelation_bloquee", true)
	focus_mode = Control.FOCUS_NONE
	release_focus()
	$Visuel/Contenu.hide()
	dos_carte = TextureRect.new()
	dos_carte.texture = preload("res://assets/textures/interfaces/ameliorations/dos_carte.svg")
	var lave := ShaderMaterial.new()
	lave.shader = preload("res://scenes/interfaces/menus/ameliorations/dos_carte.gdshader")
	lave.set_shader_parameter("decalage", randf() * 20.0)
	dos_carte.material = lave
	dos_carte.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	dos_carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	visuel.add_child(dos_carte)
	dos_carte.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	materiau_papier.set_shader_parameter("rarete_coloree", false)
	materiau_papier.set_shader_parameter("braises_personnalisees", false)
	visuel.modulate = Color(0.82, 0.76, 0.65, 1.0)
	visuel.scale = Vector2(0.94, 0.94)
	visuel.modulate.a = 0.0

func sortir_du_paquet(origine: Vector2, delai: float) -> Tween:
	actualiser_dimensions()
	visuel.position = get_global_transform().affine_inverse() * origine - size / 2.0
	visuel.scale = Vector2.ONE * 0.45
	visuel.rotation = deg_to_rad(-8.0 + delai * 60.0)
	var sortie := create_tween().set_parallel(true)
	# Seul le visuel bouge : le GridContainer conserve les trois places de sélection.
	sortie.tween_property(visuel, "position", Vector2.ZERO, 0.4).set_delay(delai).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	sortie.tween_property(visuel, "scale", Vector2.ONE * 0.94, 0.4).set_delay(delai).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	sortie.tween_property(visuel, "rotation", 0.0, 0.4).set_delay(delai)
	sortie.tween_property(visuel, "modulate:a", 1.0, 0.2).set_delay(delai)
	return sortie

func reveler() -> void:
	var puissance := maxi(0, ["commun", "rare", "epique", "legendaire"].find(rarete))
	actualiser_dimensions()
	revelation_tween = create_tween()
	SonsInterface.preparer_carte(puissance)
	# La carte se soulève avant de basculer ; une légendaire garde un bref suspense.
	revelation_tween.tween_property(visuel, "position:y", -10.0 - puissance * 4.0, 0.13 + puissance * 0.045).set_ease(Tween.EASE_OUT)
	revelation_tween.parallel().tween_property(self, "intensite_braises", intensite_repos + 0.3 + puissance * 0.25, 0.13 + puissance * 0.045)
	if puissance == 3:
		revelation_tween.tween_interval(0.18)
	# Réduire la largeur jusqu'à zéro simule une rotation vue de face.
	revelation_tween.tween_property(visuel, "scale:x", 0.0, 0.16 + puissance * 0.04).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	revelation_tween.tween_callback(_montrer_face.bind(puissance))
	# La carte réapparaît avec un léger dépassement, puis retrouve sa taille normale.
	revelation_tween.tween_property(visuel, "scale", Vector2.ONE * (1.03 + puissance * 0.025), 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	revelation_tween.tween_property(visuel, "scale", Vector2.ONE, 0.18)
	revelation_tween.parallel().tween_property(visuel, "position", Vector2.ZERO, 0.18)
	await revelation_tween.finished

func _montrer_face(puissance: int) -> void:
	revelee.emit(StringName(rarete))
	dos_carte.hide()
	actualiser_contenu()
	$Visuel/Contenu.show()
	visuel.modulate = Color.WHITE
	var intensite_avant := intensite_repos
	intensite_braises += puissance * 0.45
	# Une flambée brève à la découverte, puis retour aux braises habituelles.
	create_tween().tween_property(self, "intensite_braises", intensite_avant, 0.8)
	var eclat := preload("res://scenes/interfaces/menus/ameliorations/eclat_revelation.gd").new()
	eclat.teinte = CATALOGUE.COULEURS.get(StringName(rarete), Color("e5ce9f"))
	eclat.puissance = puissance
	eclat.size = size
	visuel.add_child(eclat)
	visuel.move_child(eclat, 0) # Placer la lueur derrière le papier, sans cacher les textes.
	if puissance == 3:
		SonsInterface.celebrer_legendaire()
		return
	# Cordes Kenney pour commun / rare, puis la montée « Up » pour l'épique.
	var sons := [preload("res://assets/sounds/design/jingles/jingles_PIZZI04.ogg"), preload("res://assets/sounds/design/jingles/jingles_PIZZI00.ogg"), preload("res://assets/sounds/interfaces/revelation_epique.wav")]
	var son := AudioStreamPlayer.new()
	son.stream = sons[puissance]
	son.bus = "Effets"
	# « Up » est enregistré plus doucement : compenser sans changer les autres raretés.
	var volumes := [-18.0, -16.0, -2.0]
	son.volume_db = volumes[puissance]
	# La résonance continue même si la carte est choisie et son menu refermé.
	SonsInterface.add_child(son)
	son.finished.connect(son.queue_free)
	son.play()

func terminer_revelation() -> void:
	en_revelation = false
	set_meta("revelation_bloquee", false)
	actualiser_survol()

func confirmer_acquisition(centre: Vector2) -> Tween:
	en_revelation = true
	if hover_tween:
		hover_tween.kill()
	z_index = 5
	var son := AudioStreamPlayer.new()
	son.stream = preload("res://assets/sounds/design/menus/confirmation_004.ogg")
	son.bus = "Effets"
	son.volume_db = -20.0
	add_child(son)
	son.finished.connect(son.queue_free)
	son.play()
	var confirmation := create_tween().set_parallel(true)
	var destination := get_global_transform().affine_inverse() * centre - size / 2.0
	confirmation.tween_property(visuel, "position", destination, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	confirmation.tween_property(visuel, "scale", Vector2.ONE * 1.16, 0.35).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	confirmation.chain().tween_property(visuel, "modulate:a", 0.0, 0.2).set_delay(0.15)
	return confirmation

func consumer() -> void:
	en_revelation = true
	if hover_tween:
		hover_tween.kill()
	var disparition := create_tween().set_parallel(true)
	# Retirer aussi le panneau d'ombre pour ne pas laisser un rectangle noir sous les cendres.
	disparition.tween_property($Visuel/Ombre, "modulate:a", 0.0, 0.15)
	disparition.tween_property($Visuel/Contenu, "modulate:a", 0.0, 0.2)
	disparition.tween_method(func(valeur): materiau_papier.set_shader_parameter("disparition", valeur), 0.0, 1.0, 0.55)
	disparition.chain().tween_property(visuel, "modulate:a", 0.0, 0.08)


# Chaque carte possède son matériau et ses interactions.
func _ready() -> void:
	# Sans duplicate(), survoler une carte changerait aussi ses voisines.
	materiau_papier = papier.material.duplicate() as ShaderMaterial
	# Les pictogrammes gardent leur transparence et leurs proportions.
	var metal := ShaderMaterial.new()
	metal.shader = preload("res://scenes/interfaces/menus/ameliorations/pictogramme_metal.gdshader")
	image.material = metal
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	papier.material = materiau_papier

	if lecture_seule:
		preparer_consultation()
	resized.connect(actualiser_dimensions)
	image.resized.connect(actualiser_dimensions)
	actualiser_contenu()
	actualiser_dimensions.call_deferred()
	if Engine.is_editor_hint():
		return
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	gui_input.connect(_on_gui_input)
	focus_entered.connect(actualiser_survol)
	focus_exited.connect(actualiser_survol)


# L’affichage lit les exports ; les effets appartiennent au gestionnaire.
func actualiser_contenu() -> void:
	var coloree := CATALOGUE.COULEURS.has(StringName(rarete))
	var teinte: Color = CATALOGUE.COULEURS.get(StringName(rarete), Color.WHITE)
	materiau_papier.set_shader_parameter("rarete_coloree", coloree)
	materiau_papier.set_shader_parameter("teinte_rarete", teinte)
	materiau_papier.set_shader_parameter("braises_personnalisees", coloree)
	materiau_papier.set_shader_parameter("teinte_braises", teinte)
	niveau_rarete = maxi(0, ["commun", "rare", "epique", "legendaire"].find(rarete))
	materiau_papier.set_shader_parameter("niveau_rarete", float(niveau_rarete))
	var marque: Label = $Visuel/Contenu/Organisation/Entete/Marque
	marque.text = CATALOGUE.NOMS.get(StringName(rarete), "✦").to_upper()
	marque.add_theme_color_override("font_color", teinte.lightened(0.3))
	$Visuel/Contenu/Organisation/Entete/Categorie.add_theme_color_override("font_color", Color("d7c7ac"))
	image.material.set_shader_parameter("teinte", teinte.lightened(0.25))
	$Visuel/Contenu/Organisation/Titre.text = titre
	$Visuel/Contenu/Organisation/Description.text = description
	$Visuel/Contenu/Organisation/Effet.text = effet_affiche
	$Visuel/Contenu/Organisation/Entete/Categorie.text = categorie
	image.texture = illustration
	$Visuel/Contenu/Organisation/Duree.text = duree_affichee
	$Visuel/Contenu/Organisation/Duree.visible = not duree_affichee.is_empty()
	if lecture_seule:
		invitation.text = statut


# Même carte et mêmes shaders, dans un format plus compact pour le récapitulatif.
func preparer_consultation() -> void:
	custom_minimum_size = Vector2(240, 365)
	size = custom_minimum_size
	focus_mode = Control.FOCUS_NONE
	mouse_filter = Control.MOUSE_FILTER_PASS
	mouse_default_cursor_shape = Control.CURSOR_ARROW
	hover_scale = 1.0 # Éviter de déborder sur les voisines dans le défilement.
	$Visuel/Contenu/Organisation/Illustration.custom_minimum_size.y = 80
	$Visuel/Contenu/Organisation.add_theme_constant_override("separation", 8)
	if not duree_affichee.is_empty():
		# Réserver la durée dans le même format, au lieu d'allonger la carte temporaire.
		$Visuel/Contenu/Organisation/Illustration.custom_minimum_size.y = 45
		$Visuel/Contenu/Organisation/Duree.add_theme_font_size_override("font_size", 18)
		$Visuel/Contenu/Organisation.add_theme_constant_override("separation", 6)
	for cote in ["left", "top", "right", "bottom"]:
		$Visuel/Contenu.add_theme_constant_override("margin_" + cote, 18)
	$Visuel/Contenu/Organisation/Titre.add_theme_font_size_override("font_size", 22)
	$Visuel/Contenu/Organisation/Entete/Marque.add_theme_font_size_override("font_size", 11)
	$Visuel/Contenu/Organisation/Description.add_theme_font_size_override("font_size", 13)
	$Visuel/Contenu/Organisation/Effet.add_theme_font_size_override("font_size", 15)
	# Réserver deux lignes même pour un effet court garde les illustrations alignées.
	$Visuel/Contenu/Organisation/Effet.custom_minimum_size.y = 54
	$Visuel/Contenu/Organisation/Effet.vertical_alignment = VERTICAL_ALIGNMENT_CENTER


## Donne les tailles en pixels aux shaders pour conserver des bordures régulières.
func actualiser_dimensions() -> void:
	visuel.pivot_offset = size / 2.0
	materiau_papier.set_shader_parameter("taille", papier.size)


## Anime les braises même si le jeu est en pause : la scène est en mode Always.
func _process(delta: float) -> void:
	if not is_visible_in_tree():
		return
	temps_animation += delta
	if is_instance_valid(dos_carte) and dos_carte.visible:
		# Utiliser notre horloge fait vivre la lave même pendant la pause du jeu.
		dos_carte.material.set_shader_parameter("horloge", temps_animation)
	var lumiere := Vector2(0.25, 0.15)
	if souris_dessus and size.x > 0.0 and size.y > 0.0:
		# Position relative dans la carte : déplace le reflet simulé sous la souris.
		lumiere = get_local_mouse_position() / size
	materiau_papier.set_shader_parameter("horloge", temps_animation)
	materiau_papier.set_shader_parameter("survol", accent)
	materiau_papier.set_shader_parameter("point_lumiere", lumiere)
	materiau_papier.set_shader_parameter("intensite_braises", intensite_braises)
	# Lire la vraie place de l'illustration fonctionne aussi avec les cartes compactes du Carnet.
	var illustration_zone: Control = image.get_parent()
	var centre := papier.get_global_transform().affine_inverse() * illustration_zone.get_global_transform() * (illustration_zone.size / 2.0)
	materiau_papier.set_shader_parameter("centre_illustration", centre / papier.size.max(Vector2.ONE))
	materiau_papier.set_shader_parameter("rayon_illustration", minf(illustration_zone.size.x, illustration_zone.size.y) * 0.44)
	var titre_zone: Control = $Visuel/Contenu/Organisation/Titre
	# Une durée temporaire fait partie des informations lisibles sur le parchemin.
	if $Visuel/Contenu/Organisation/Duree.visible:
		titre_zone = $Visuel/Contenu/Organisation/Duree
	var debut_titre := papier.get_global_transform().affine_inverse() * titre_zone.global_position
	materiau_papier.set_shader_parameter("limite_metal", (debut_titre.y - 6.0) / maxf(papier.size.y, 1.0))
	image.material.set_shader_parameter("survol", accent)
	# Le pictogramme devient un emblème : conserver une marge à l'intérieur du médaillon.
	var marge := illustration_zone.size * 0.15
	image.offset_left = marge.x
	image.offset_right = -marge.x
	image.offset_top = marge.y
	image.offset_bottom = -marge.y


## Le survol souris et le focus manette partagent la même mise en évidence.
func _on_mouse_entered() -> void:
	souris_dessus = true
	actualiser_survol()


func _on_mouse_exited() -> void:
	souris_dessus = false
	actualiser_survol()


## Anime le visuel et les braises ensemble, sans agrandir la zone qui reçoit la souris.
func actualiser_survol() -> void:
	if en_revelation:
		return
	var actif := souris_dessus or has_focus()
	if not lecture_seule:
		invitation.text = "CHOISIR CETTE AMÉLIORATION" if actif else "CLIQUER POUR CHOISIR"
	if hover_tween:
		hover_tween.kill()
	z_index = 1 if actif else 0
	hover_tween = create_tween().set_parallel(true)
	# Les deux pistes avancent EN MÊME TEMPS : taille du panneau et accent lumineux.
	# EASE_OUT ralentit à l'arrivée ; une nouvelle interaction interrompt l'ancien Tween.
	hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	var agrandissement := hover_scale + (niveau_rarete * 0.008 if not lecture_seule else 0.0)
	hover_tween.tween_property(visuel, "scale", Vector2.ONE * (agrandissement if actif else 1.0), hover_duration)
	if not lecture_seule:
		hover_tween.tween_property(visuel, "position:y", -3.0 - niveau_rarete * 2.0 if actif else 0.0, hover_duration)
	hover_tween.tween_property(self, "accent", 1.0 if actif else 0.0, hover_duration)


## Le clic ou la validation de la manette confirme la carte qui possède le focus.
func _on_gui_input(event: InputEvent) -> void:
	if lecture_seule or en_revelation or event.is_echo():
		return
	var clic: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clic or event.is_action_pressed("ui_accept"):
		accept_event()
		selected.emit()
