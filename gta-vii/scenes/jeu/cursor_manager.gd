extends Node

var position_curseur := Vector2.ZERO
var souris_deplacee_par_joystick := false

@export var vitesse := 1000.0
@export var sensibilite_x := 1.8
@export var sensibilite_y := 1.0

func _ready() -> void:
	position_curseur = get_viewport().get_mouse_position()
	
func _process(delta: float) -> void:
	var joystick := Vector2(Input.get_joy_axis(0, JOY_AXIS_RIGHT_X),Input.get_joy_axis(0, JOY_AXIS_RIGHT_Y))
	
	
	if joystick.length() > 0.15:
		joystick.normalized()
		joystick.x *= sensibilite_x
		joystick.y *= sensibilite_y
		position_curseur += joystick * vitesse * delta

		var taille_ecran := get_viewport().get_visible_rect().size

		position_curseur.x = clamp(position_curseur.x, 0.0, taille_ecran.x)
		position_curseur.y = clamp(position_curseur.y, 0.0, taille_ecran.y)
		souris_deplacee_par_joystick = true
		Input.warp_mouse(position_curseur)

		
	
func _input(event: InputEvent) -> void:
	if event is InputEventMouseMotion:
		if souris_deplacee_par_joystick:
			souris_deplacee_par_joystick = false
			return
		position_curseur = event.position
