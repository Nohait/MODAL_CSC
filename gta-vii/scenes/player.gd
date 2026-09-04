extends CharacterBody3D


@onready var camera: Camera3D = $Camera3D

@onready var visual: Node3D = $visual

const SPEED = 5.0
const DASH_SPEED = 50.0
const DASH_DURATION = 0.2

var last_direction := Vector3.FORWARD 
var is_dashing := false
var dash_time_left := 0.0

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



	
	if Input.is_action_just_pressed("dash") and (not is_dashing):
		#initialise le dash
		is_dashing = true
		dash_time_left = DASH_DURATION

	
	if is_dashing:
		#applique le dash
		velocity.x = last_direction.x * DASH_SPEED
		velocity.z = last_direction.z * DASH_SPEED
		
		dash_time_left -= delta
		
		if dash_time_left <= 0.0:
			is_dashing = false
	else:
		#On normalise pour ne pas aller plus vite en diagonale
		if direction.length() > 0.0:
			direction = direction.normalized()
			#On update la dernière direction prise
			last_direction = direction
			velocity.x = direction.x * SPEED
			velocity.z = direction.z * SPEED
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		
	
	#VISEE DU JOUEUR
	
	#Recuperation de la position de la souris
	#Le viewport est la zone dans laquelle le jeu est rendu 
	#On récupère donc le vecteur position de la souris en 2D, sur l'écran.
	var mouse_position := get_viewport().get_mouse_position()
	
	#Pour passer de la position 2D de la souris à une position en 3D dans le monde
	#On veut créer un vecteur qui passe par la caméra et le point de l'écran désigné par la souris
	#Puis regarder en quel point le rayon dirigé par ce vecteur intercepte le sol
	
	#ray_origin donne la position de la caméra, origine du vecteur
	var ray_origin := camera.project_ray_origin(mouse_position)
	#ray_direction donne sa direction
	var ray_direction := camera.project_ray_normal(mouse_position)
	#On crée un plan horizontal en donnant sa normale et sa hauteur
	var ground_plane := Plane(Vector3.UP, 0.0)
	
	#On regarde quand est_ce que le rayon calculé précédemment
	#intercepte ce plan
	#on ne met pas de ":=" car il peut n'y avoir aucune intersection (renvoie null)
	var target_position = ground_plane.intersects_ray(ray_origin, ray_direction)
	
	if target_position != null:
		#On place la position de la cible sur la position du visuel
		#(evite de regarder vers le sol)
		target_position.y = visual.global_position.y
		
		#On s'oriente vers ce point, en gardant y comme verticale
		visual.look_at(target_position, Vector3.UP)
	
	move_and_slide()
