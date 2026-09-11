extends CharacterBody3D
var cible = null
@export var distance_attaque = 1.0
@export var distance_detection = 5.0
@export var distance_lacher = 10.0
@export var attaque_cooldown = 2.0
@export var attaque_timer = 0.0 #temps initialisé à 0
@export var vitesse_ennemi = 5.5

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var detection_shape: CollisionShape3D = $SurfaceDetection/CollisionShape3D
	detection_shape.shape.radius = distance_detection  #On met à jour la distance de detection en fonction de la valeur choisie en variable
	
	
	position = Vector3(randi_range(-50,50),0.7,randi_range(-50,50)) #On place l'ennemi aléatoirment dans la map
	# /!\ à modifier pour s'adapter à la taille de la map (peut être prendre un rayon graine de la map en input ?)
	pass # Replace with function body.

func _on_surface_detection_body_entered(body: Node3D) -> void:
	print("Quelque chose est entré dans ma zone : ", body.name)

	if body.is_in_group("player"):
		cible = body
		
func _physics_process(delta):
	
	attaque_timer -= delta 	#A chaque frame, le cooldown réduit
	
	if cible != null:	#Une fois que le joueur est pris pour cible
		var distance = global_position.distance_to(cible.global_position)
		
		
		if distance > distance_lacher: #calcul de sortie de range
			cible = null
			velocity = Vector3.ZERO
			move_and_slide()	
			
		elif distance > distance_attaque: # comportement dans la range
			var direction = global_position.direction_to(cible.global_position)
			velocity = direction * vitesse_ennemi
			move_and_slide()	
			
		else: #comportement dans la portée d'attaque
			velocity = Vector3.ZERO 
			
			if attaque_timer < 0.0:
				attaque()
			
			
func attaque() -> void:
	if cible != null:
		print("La cible est : ", cible.name)
	attaque_timer = attaque_cooldown
	
	
