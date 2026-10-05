extends Node

var position_curseur := Vector2.ZERO


var curseur_texture = preload("res://assets/textures/interfaces/curseurs/curseur_lance.svg")

@export var vitesse := 1000.0
@export var sensibilite_x := 1.8
@export var sensibilite_y := 1.0
@export_range(0.0, 0.5, 0.01) var zone_morte := 0.15
var manette_active := -1

func _ready() -> void:
	Input.set_custom_mouse_cursor(curseur_texture, Input.CURSOR_POINTING_HAND, Vector2(3, 3))
	position_curseur = get_viewport().get_mouse_position()



func _process(delta: float) -> void:
	var joystick := _lire_stick_droit()

	if joystick.length() > zone_morte:
		# Garder l'amplitude du stick permet aussi de viser avec précision.
		joystick = joystick.normalized() * clampf((joystick.length() - zone_morte) / (1.0 - zone_morte), 0.0, 1.0)

		joystick.x *= sensibilite_x
		joystick.y *= sensibilite_y

		position_curseur += joystick * vitesse * delta

		var taille_ecran := get_viewport().get_visible_rect().size

		position_curseur.x = clamp(
			position_curseur.x,
			0.0,
			taille_ecran.x
		)

		position_curseur.y = clamp(
			position_curseur.y,
			0.0,
			taille_ecran.y
		)

		Input.warp_mouse(position_curseur)

func _input(event: InputEvent) -> void:
	if event is InputEventJoypadMotion and event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
		manette_active = event.device
	if event is InputEventMouseMotion:
		# warp_mouse génère aussi des mouvements de souris. Pendant la visée au
		# stick, ils ne doivent pas écraser notre position calculée dans le viewport.
		if _lire_stick_droit().length() <= zone_morte:
			position_curseur = event.position

func _lire_stick_droit() -> Vector2:
	var manettes := Input.get_connected_joypads()
	if manettes.is_empty(): return Vector2.ZERO
	# Après une reconnexion, la manette n'a pas forcément l'identifiant 0.
	if not manettes.has(manette_active): manette_active = manettes[0]
	return Vector2(Input.get_joy_axis(manette_active, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(manette_active, JOY_AXIS_RIGHT_Y))




'''
CURSEUR VIRTUEL (si on change d'avis)
extends Node

var position_curseur := Vector2.ZERO
var souris_deplacee_par_joystick := false

var curseur_visuel: TextureRect
var curseur_texture = preload("res://assets/textures/interfaces/curseurs/curseur_lance.svg")

@export var vitesse := 1000.0
@export var sensibilite_x := 1.8
@export var sensibilite_y := 1.0

func _ready() -> void:
	Input.set_custom_mouse_cursor(curseur_texture, Input.CURSOR_POINTING_HAND, Vector2(3, 3))
	position_curseur = get_viewport().get_mouse_position()

func creer_curseur_visuel() -> void:
	curseur_visuel = TextureRect.new()
	curseur_visuel.name = "CurseurVirtuel"
	curseur_visuel.texture = curseur_texture
	curseur_visuel.size = Vector2(32, 32)
	curseur_visuel.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	curseur_visuel.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	curseur_visuel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_tree().root.add_child(curseur_visuel)
	mettre_a_jour_curseur_visuel()

func _process(delta: float) -> void:
	var joystick := Vector2(
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),
		Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y)
	)

	if joystick.length() > 0.15:
		joystick = joystick.normalized()
		joystick.x *= sensibilite_x
		joystick.y *= sensibilite_y
		position_curseur += joystick * vitesse * delta

		var taille_ecran := get_viewport().get_visible_rect().size

		position_curseur.x = clamp(position_curseur.x, 0.0, taille_ecran.x)
		position_curseur.y = clamp(position_curseur.y, 0.0, taille_ecran.y)

		mettre_a_jour_curseur_visuel()

func mettre_a_jour_curseur_visuel() -> void:
	if curseur_visuel == null:
		return

	curseur_visuel.position = position_curseur - curseur_visuel.size / 2.0

func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		position_curseur = event.position
		mettre_a_jour_curseur_visuel()
'''
