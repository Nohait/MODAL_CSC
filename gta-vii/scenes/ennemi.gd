extends CharacterBody3D
var cible = null
var distance_attaque = 1.0
var distance_lacher = 10.0
var attaque_cooldown = 2.0
var attaque_timer = 0.0
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass # Replace with function body.

func _on_surface_detection_body_entered(body: Node3D) -> void:
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
			velocity = direction * 2.0
			move_and_slide()	
			
		else: #comportement dans la portée d'attaque
			velocity = Vector3.ZERO 
			
			if attaque_timer < 0.0:
				attaque()
			
			
func attaque():
	print("Le joueur est attaqué")
	if cible != null:
		pass
	attaque_timer = attaque_cooldown
	
	
