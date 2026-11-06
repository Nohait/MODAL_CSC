extends Node



@export var vitesse := 1000.0
@export var sensibilite_x := 1.8
@export var sensibilite_y := 1.0
@export_range(0.0, 0.5, 0.01) var zone_morte := 0.15

var position_curseur := Vector2.ZERO

var curseur_texture = preload("res://assets/textures/interfaces/curseurs/curseur_lance.svg")

var manette_active := false

func _ready() -> void:
	Input.set_custom_mouse_cursor(
		curseur_texture,
		Input.CURSOR_POINTING_HAND,
		Vector2(3, 3)
	)
	position_curseur = get_viewport().get_mouse_position()

# Dans CursorManager (ou le script du viseur)
'''
func _process(_d):
	if joueur.usingController:
		position_curseur = joueur.camera.unproject_position(joueur.aim_position)
	else:
	'	position_curseur = get_viewport().get_mouse_position()
'''
func updateCursorVisibility() -> void:
	pass



func _input(event: InputEvent) -> void:
	# Détection de l'utilisation de la manette
	if event is InputEventJoypadMotion:
		if event.axis in [JOY_AXIS_RIGHT_X, JOY_AXIS_RIGHT_Y]:
			if absf(event.axis_value) > 0.15:
				manette_active = true

	# Détection de l'utilisation de la souris
	if event is InputEventMouseButton and event.pressed:
		manette_active = false

	if event is InputEventMouseMotion and not manette_active:
		position_curseur = event.position
		manette_active = false
