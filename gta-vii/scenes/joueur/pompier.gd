extends CharacterBody3D

@onready var anim_tree = $Armature/AnimationTree

const SPEED = 5.0
var current_blend = Vector2.ZERO

func _ready():
	anim_tree.active = true

func _physics_process(delta):
	var input_dir = Input.get_vector("move_left", "move_right", "move_forward", "move_backward")
	var direction = (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if direction:
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0
		velocity.z = 0

	move_and_slide()

	# Lissage de la transition pour éviter les à-coups
	current_blend = current_blend.lerp(input_dir, delta * 10.0)
	anim_tree["parameters/blend_position"] = current_blend
