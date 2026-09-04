extends CharacterBody3D


@onready var camera: Camera3D = $Camera3D

const SPEED = 5.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity += get_gravity() * delta

#On récupère l'input du joueur
#Vecteur à deux dimensions : +x c'est droite
#Et +y c'est l'arrière
	var input_dir := Input.get_vector(
		"move_left",
		"move_right",
		"move_forward",
		"move_backward"
	)

#On veut des mouvements intuitifs, qui suivent la direction de la caméra
#Et pas celle du monde
#Le +z de la caméra est l'arrière
#Le +x de la caméra est la droite

	var camera_forward := -camera.global_transform.basis.z
	var camera_right := camera.global_transform.basis.x

#La caméra pointe vers le bas, mais on ne veut pas que le joueur rentre dans le sol
	camera_forward.y = 0.0
	camera_right.y = 0.0

#On renormalise
	camera_forward = camera_forward.normalized()
	camera_right = camera_right.normalized()

#On récupère la direction du joueur, par rapport à la caméra
	var direction := camera_right * input_dir.x + camera_forward * (-input_dir.y)

#On normalise pour ne pas aller plus vite en diagonale
	if direction.length() > 0.0:
		direction = direction.normalized()
		velocity.x = direction.x * SPEED
		velocity.z = direction.z * SPEED
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()
