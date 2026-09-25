@tool
extends Control

## La carte annonce un choix. Le futur gestionnaire appliquera l'effet et changera de salle.
## Le signal existant est conservé sans argument : le gestionnaire pourra utiliser bind(carte).
signal selected

@export_group("Contenu")
## Identifiant stable destiné au futur pool ; aucun effet de jeu n'est appliqué ici.
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
@export var illustration: Texture2D = preload("res://assets/textures/interfaces/ameliorations/test_illustration.png"):
	set(valeur):
		illustration = valeur
		if is_node_ready():
			actualiser_contenu()

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
var materiau_image: ShaderMaterial
var hover_tween: Tween
var souris_dessus := false
var accent := 0.0
var temps_animation := 0.0


## Prépare une copie des matériaux par carte et connecte souris/clavier.
func _ready() -> void:
	# Sans duplicate(), survoler une carte changerait aussi ses voisines.
	materiau_papier = papier.material.duplicate() as ShaderMaterial
	materiau_image = image.material.duplicate() as ShaderMaterial
	papier.material = materiau_papier
	image.material = materiau_image
	resized.connect(actualiser_dimensions)
	image.resized.connect(actualiser_dimensions)
	actualiser_contenu()
	actualiser_dimensions.call_deferred()
	if Engine.is_editor_hint():
		return
	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)
	focus_entered.connect(actualiser_survol)
	focus_exited.connect(actualiser_survol)
	gui_input.connect(_on_gui_input)


## Met à jour l'affichage à partir des exports, sans modifier les statistiques du joueur.
func actualiser_contenu() -> void:
	$Visuel/Contenu/Organisation/Titre.text = titre
	$Visuel/Contenu/Organisation/Description.text = description
	$Visuel/Contenu/Organisation/Effet.text = effet_affiche
	$Visuel/Contenu/Organisation/Entete/Categorie.text = categorie
	image.texture = illustration


## Donne les tailles en pixels aux shaders pour conserver des bordures régulières.
func actualiser_dimensions() -> void:
	visuel.pivot_offset = size / 2.0
	materiau_papier.set_shader_parameter("taille", papier.size)
	materiau_image.set_shader_parameter("taille", image.size)


## Anime les braises même si le jeu est en pause : la scène est en mode Always.
func _process(delta: float) -> void:
	temps_animation += delta
	var lumiere := Vector2(0.25, 0.15)
	if souris_dessus and size.x > 0.0 and size.y > 0.0:
		# Position relative dans la carte : déplace le reflet simulé sous la souris.
		lumiere = get_local_mouse_position() / size
	for materiau in [materiau_papier, materiau_image]:
		materiau.set_shader_parameter("horloge", temps_animation)
		materiau.set_shader_parameter("survol", accent)
		materiau.set_shader_parameter("point_lumiere", lumiere)
		materiau.set_shader_parameter("intensite_braises", intensite_braises)


## Le focus clavier et le survol souris partagent exactement le même retour visuel.
func _on_mouse_entered() -> void:
	souris_dessus = true
	actualiser_survol()


func _on_mouse_exited() -> void:
	souris_dessus = false
	actualiser_survol()


## Anime le visuel et les braises ensemble, sans agrandir la zone qui reçoit la souris.
func actualiser_survol() -> void:
	var actif := souris_dessus or has_focus()
	invitation.text = "CHOISIR CETTE AMÉLIORATION" if actif else "CLIC OU ENTRÉE POUR CHOISIR"
	if hover_tween:
		hover_tween.kill()
	z_index = 1 if actif else 0
	hover_tween = create_tween().set_parallel(true)
	# Les deux pistes avancent EN MÊME TEMPS : taille du panneau et accent lumineux.
	# EASE_OUT ralentit à l'arrivée ; une nouvelle interaction interrompt l'ancien Tween.
	hover_tween.set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	hover_tween.tween_property(visuel, "scale", Vector2.ONE * (hover_scale if actif else 1.0), hover_duration)
	hover_tween.tween_property(self, "accent", 1.0 if actif else 0.0, hover_duration)


## Émet selected pour un clic gauche ou ui_accept (Entrée/manette) lorsque la carte a le focus.
func _on_gui_input(event: InputEvent) -> void:
	if event.is_echo():
		return
	var clic: bool = event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed
	if clic or (has_focus() and event.is_action_pressed("ui_accept")):
		accept_event()
		selected.emit()
