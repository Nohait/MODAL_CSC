extends CharacterBody3D


signal freed(victim: CharacterBody3D)

## Signal créé par nous.
## Émis juste avant la suppression définitive de la victime.
signal died(victim: CharacterBody3D)


@onready var interaction_label: Label3D = $InteractionLabel
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var visuel: MeshInstance3D = $MeshInstance3D

@onready var materiau := (
	visuel.get_active_material(0).duplicate()
	as StandardMaterial3D
)


# ------------------------------------------------------------------
# BARRE DE VIE
# ------------------------------------------------------------------

## SubViewport qui dessine l'interface 2D de la barre.
@onready var health_bar_viewport: SubViewport = $HealthBarViewport

## Vraie ProgressBar Godot.
@onready var health_bar: ProgressBar = $HealthBarViewport/HealthBar

## Sprite 3D qui affiche dans le monde ce que produit le SubViewport.
@onready var health_bar_sprite: Sprite3D = $HealthBarSprite


# ------------------------------------------------------------------
# VIE
# ------------------------------------------------------------------

@export_group("Défi — victime fragile")
@export var defi_fragile := false
# Une victime normale vaut un point ; celle du défi en vaut deux.
@export_range(1, 10) var points_boutique := 1

@export_group("Vie")

## Nombre maximal de points de vie de la victime.
@export_range(1.0, 1000.0, 1.0, "or_greater")
var vie_max: float = 100.0


## La valeur est initialisée après le chargement des propriétés exportées.
## Une nouvelle victime commence donc réellement à vie_max.
@onready var vie: float = vie_max


## Quantité totale de dégâts que le compte à rebours a déjà infligée.
##
## Cette valeur permet d'avoir une diminution mathématiquement exacte :
## à 50 % du timer, exactement 50 % de vie_max auront été retirés
## par le timer, indépendamment du framerate.
var degats_sauvetage_appliques: float = 0.0


var est_morte := false


# ------------------------------------------------------------------
# FUITE
# ------------------------------------------------------------------

@export_group("Fuite")

## Poids maximal du vecteur de fuite face aux ennemis mobiles.
@export_range(0.0, 10.0, 0.1, "or_greater")
var force_fuite_max: float = 2.5


# ------------------------------------------------------------------
# ANCIEN SYSTÈME DE BONUS
# ------------------------------------------------------------------

@export_group("Bonus d'escorte")

## Ancien système conservé dans le projet.
@export var bonus_dash: bool = false

## Ancien système conservé dans le projet.
@export var bonus_degats: bool = false


# ------------------------------------------------------------------
# SUIVI
# ------------------------------------------------------------------

@export_group("Suivi")

## Vitesse de déplacement de la victime.
@export_range(0.0, 20.0, 0.1, "or_greater")
var speed: float = 6.0

## Distance à laquelle la victime s'arrête de suivre sa cible.
@export_range(0.0, 10.0, 0.1, "or_greater")
var stop_distance: float = 2.0


var stop_distance_player: float

var arret := true

var follow_target: Node3D = null

var player_nearby := false

var is_freed := false


# Le conteneur Ennemis de la salle actuellement occupée.
#
# Il ne faut surtout plus utiliser uniquement $"../../Ennemis",
# car une victime libérée est reparentée sous Escorte et change de salle.
var ennemis: Node = null


func _ready() -> void:
	stop_distance_player = stop_distance

	# Chaque victime possède son propre matériau.
	# Sinon le flash rouge pourrait modifier plusieurs victimes
	# partageant la même ressource.
	visuel.material_override = materiau
	if defi_fragile:
		visuel.scale = Vector3.ONE * 0.65
		materiau.albedo_color = Color("b789db")


	# --------------------------------------------------------------
	# ANCIEN SYSTÈME DE TYPES
	# --------------------------------------------------------------

	$BonusLabel.hide()

	if bonus_dash:
		materiau.albedo_color = Color(
			1.0,
			0.65,
			0.12,
			1.0
		)

		visuel.set_surface_override_material(
			0,
			materiau
		)

		$BonusLabel.text = (
			"SPORTIVE \nDash : cooldown -20 %"
		)

		$BonusLabel.show()

	elif bonus_degats:
		materiau.albedo_color = Color(
			0.15,
			0.65,
			1.0,
			1.0
		)

		visuel.set_surface_override_material(
			0,
			materiau
		)

		$BonusLabel.modulate = Color(
			0.4,
			0.8,
			1.0
		)

		$BonusLabel.text = (
			"SPÉCIALISTE\nDégâts +25 %"
		)

		$BonusLabel.show()


	# --------------------------------------------------------------
	# BARRE DE VIE
	# --------------------------------------------------------------

	# Le Sprite3D affiche directement la texture générée par le SubViewport.
	health_bar_sprite.texture = (
		health_bar_viewport.get_texture()
	)

	# La barre occupe automatiquement toute la surface du SubViewport.
	health_bar.set_anchors_and_offsets_preset(
		Control.PRESET_FULL_RECT
	)

	health_bar.mouse_filter = (
		Control.MOUSE_FILTER_IGNORE
	)

	# On utilise directement les PV comme valeurs de la ProgressBar.
	health_bar.min_value = 0.0
	health_bar.max_value = vie_max

	actualiser_barre_vie()

	update_interaction_label()


func _physics_process(_delta: float) -> void:
	if est_morte:
		return


	if player_nearby and not is_freed:
		if Input.is_action_just_pressed(
			"interact"
		):
			free_victim()


	if (
		is_freed
		and is_instance_valid(
			follow_target
		)
	):
		follow_target_node()


# ------------------------------------------------------------------
# INTERACTION
# ------------------------------------------------------------------

func _on_detection_body_entered(
	body: Node3D
) -> void:

	if body.is_in_group("player"):
		player_nearby = true

		if not is_freed:
			interaction_label.visible = true


func _on_detection_body_exited(
	body: Node3D
) -> void:

	if body.is_in_group("player"):
		player_nearby = false
		interaction_label.visible = false


func free_victim() -> void:
	if est_morte or is_freed:
		return

	is_freed = true
	arret = false

	interaction_label.visible = false

	freed.emit(self)

	print(
		"Victime libérée avec ",
		vie,
		" / ",
		vie_max,
		" PV"
	)


func set_ennemis_container(
	conteneur: Node
) -> void:

	# Fonction créée par nous.
	#
	# Le RoomManager appelle cette fonction à chaque changement de salle
	# afin que les victimes libérées fuient les ennemis de la bonne salle.
	ennemis = conteneur


# ------------------------------------------------------------------
# ANCIEN NOM / TYPE
# ------------------------------------------------------------------

func get_nom_affiche() -> String:
	if bonus_dash and bonus_degats:
		return (
			"%s (dash -20 %%, dégâts +25 %%)"
			% name
		)

	if bonus_degats:
		return (
			"%s (spécialiste : dégâts +25 %%)"
			% name
		)

	if bonus_dash:
		return (
			"%s (sportive : dash -20 %%)"
			% name
		)

	return str(name)


# ------------------------------------------------------------------
# SUIVI
# ------------------------------------------------------------------

func follow_target_node() -> void:
	if (
		NavigationServer3D.map_get_iteration_id(
			navigation_agent.get_navigation_map()
		)
		== 0
	):
		return


	var to_target := (
		follow_target.global_position
		- global_position
	)

	to_target.y = 0.0


	velocity.x = 0.0
	velocity.z = 0.0


	if follow_target.is_in_group("fleche"):
		stop_distance = 0.1
	else:
		stop_distance = stop_distance_player


	if to_target.length() > stop_distance:
		arret = false


		var point_sol := (
			NavigationServer3D.map_get_closest_point(
				navigation_agent.get_navigation_map(),
				global_position
			)
		)

		navigation_agent.path_height_offset = (
			point_sol.y
			- global_position.y
		)

		navigation_agent.target_position = (
			follow_target.global_position
		)


		var next_position := (
			navigation_agent.get_next_path_position()
		)


		var direction := (
			next_position
			- global_position
		)

		direction.y = 0.0


		if direction.length() > 0.01:
			direction = direction.normalized()

			direction += vecteur_fuite()

			direction = direction.normalized()

			velocity.x = (
				direction.x
				* speed
			)

			velocity.z = (
				direction.z
				* speed
			)

	else:
		if follow_target.is_in_group(
			"fleche"
		):
			arret = true


	move_and_slide()


# ------------------------------------------------------------------
# DÉGÂTS NORMAUX
# ------------------------------------------------------------------

func prendre_degats(
	degats: float
) -> void:

	if est_morte:
		return


	vie = maxf(
		vie - degats,
		0.0
	)


	actualiser_barre_vie()

	flash_degats()


	print(
		"Victime : -",
		degats,
		" PV (",
		vie,
		" / ",
		vie_max,
		")"
	)


	if vie <= 0.0:
		mourir()


# ------------------------------------------------------------------
# DÉGÂTS DU TIMER
# ------------------------------------------------------------------

func actualiser_degats_sauvetage(
	proportion_ecoulee: float
) -> void:

	# Une victime libérée n'est plus touchée par le compte à rebours.
	if est_morte or is_freed:
		return


	# Exemple avec 100 PV :
	#
	# proportion = 0.25 -> le timer doit avoir retiré 25 PV au total.
	# proportion = 0.50 -> 50 PV au total.
	# proportion = 1.00 -> 100 PV au total.
	var nouveaux_degats_sauvetage: float = (
		vie_max
		* clampf(
			proportion_ecoulee,
			0.0,
			1.0
		)
	)


	# On retire uniquement ce qui n'a pas encore été appliqué.
	var difference: float = (
		nouveaux_degats_sauvetage
		- degats_sauvetage_appliques
	)


	if difference <= 0.0:
		return


	degats_sauvetage_appliques = (
		nouveaux_degats_sauvetage
	)


	vie = maxf(
		vie - difference,
		0.0
	)


	actualiser_barre_vie()


	if vie <= 0.0:
		mourir()


# ------------------------------------------------------------------
# BARRE DE VIE
# ------------------------------------------------------------------

func actualiser_barre_vie() -> void:
	if not is_instance_valid(
		health_bar
	):
		return


	health_bar.max_value = vie_max

	# Aucun calcul graphique supplémentaire :
	# la ProgressBar reçoit directement les vrais PV.
	health_bar.value = clampf(
		vie,
		0.0,
		vie_max
	)


# ------------------------------------------------------------------
# MORT
# ------------------------------------------------------------------

func mourir() -> void:
	if est_morte:
		return


	est_morte = true

	vie = 0.0

	actualiser_barre_vie()


	died.emit(self)

	queue_free()


# ------------------------------------------------------------------
# FEEDBACK DE DÉGÂTS
# ------------------------------------------------------------------

func flash_degats() -> void:
	var tween_degats := create_tween()

	var couleur_init := (
		materiau.albedo_color
	)


	tween_degats.tween_property(
		materiau,
		"albedo_color",
		Color(
			1.0,
			0.0,
			0.0,
			1.0
		),
		0.1
	)


	tween_degats.tween_property(
		materiau,
		"albedo_color",
		Color(
			1.0,
			1.0,
			1.0,
			1.0
		),
		0.2
	)


	tween_degats.tween_property(
		materiau,
		"albedo_color",
		couleur_init,
		0.1
	)


# ------------------------------------------------------------------
# FUITE
# ------------------------------------------------------------------

func force_fuite(
	distance_ennemi: float
) -> float:

	if force_fuite_max <= 0.0:
		return 0.0


	return clampf(
		(5.0 - distance_ennemi)
		* force_fuite_max
		/ 5.0,
		0.0,
		force_fuite_max
	)


func vecteur_fuite() -> Vector3:
	var fuite := Vector3.ZERO


	if not is_instance_valid(
		ennemis
	):
		return fuite


	for ennemi in ennemis.get_children():
		if not ennemi.is_in_group(
			"mobiles"
		):
			continue


		var direction := (
			global_position.direction_to(
				ennemi.global_position
			)
		)


		var distance_ennemi := (
			global_position.distance_to(
				ennemi.global_position
			)
		)


		fuite -= (
			direction
			* force_fuite(
				distance_ennemi
			)
		)


	return fuite


# ------------------------------------------------------------------
# TEXTE D'INTERACTION
# ------------------------------------------------------------------

func update_interaction_label() -> void:
	var events := (
		InputMap.action_get_events(
			"interact"
		)
	)


	if events.is_empty():
		interaction_label.text = "Libérer"
		return


	var event := events[0]


	if event is InputEventKey:
		interaction_label.text = (
			"["
			+ event.as_text_physical_keycode()
			+ "] Libérer"
		)
