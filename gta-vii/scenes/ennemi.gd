extends CharacterBody3D
var cible = null
@export var vie_max := 100.0
var vie := vie_max

@export var distance_attaque = 1.0
@export var distance_detection = 10.0
@export var distance_lacher = 20.0

@export var attaque_cooldown = 1.0
@export var attaque_timer = 0.0 #temps initialisé à 0
@export var degats_ennemi = 10.0

@export var vitesse_ennemi = 6


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	
	var detection_shape: CollisionShape3D = $SurfaceDetection/CollisionShape3D
	detection_shape.shape.radius = distance_detection  #On met à jour la distance de detection en fonction de la valeur choisie en variable
	
	position = Vector3(randi_range(-20,20),0.7,randi_range(-20,20)) #On place l'ennemi aléatoirment dans la map # /!\ à modifier pour s'adapter à la taille de la map (peut être prendre un rayon graine de la map en input ?)
	
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
			velocity = direction * vitesse_ennemi
			move_and_slide()	
			
		else: #comportement dans la portée d'attaque
			velocity = Vector3.ZERO 
			
			if attaque_timer < 0.0:
				attaque()
			
func prendre_degats(degats: float) -> void:
	vie -= degats
	vie = max(vie, 0)
	print( self.name, " Touché : -", degats)
	afficher_degats(degats)
	
	if vie <= 0:
		mourir()
		
func mourir():
	print("Bravo, vous avez tué l'ennemi")
	queue_free()

func attaque() -> void:
	if cible != null:
		var multiplier = randf_range(0.9,1.1)
		cible.prendre_degats(round(multiplier * degats_ennemi *100.0)/100.0)
		
	attaque_timer = attaque_cooldown

func couleur_degats(degats: float) -> Color:
	
	var t = clamp((degats - 0.9*degats_ennemi) / 1.0, 0.0, 1.0)
	
	var blanc = Color(0.998, 1.0, 0.29, 1.0)
	var orange = Color(1.0, 0.388, 0.0, 1.0)
	
	return blanc.lerp(orange, t)
	
#On affiche les dégats
func afficher_degats(degats: float) -> void:
	$PopUpDegats.text = "-" + str(degats)
	$PopUpDegats.modulate = couleur_degats(degats)
	$PopUpDegats.position = Vector3(0,2.5,0)
	$PopUpDegats.font_size = 50
	$PopUpDegats.visible = true
	
	
	var position_depart = Vector3(0,2.5,0)
	var position_fin = position_depart + Vector3(0, 1, 0)
	var taille_fin = 120
	var tween = create_tween() #Fonction qui permet de faire un gradient

	tween.parallel().tween_property($PopUpDegats,"position",position_fin,0.2)
	tween.parallel().tween_property($PopUpDegats,"font_size",taille_fin,0.2)
	tween.parallel().tween_property($PopUpDegats,"modulate:a",0.0,0.4)

	await tween.finished

	$PopUpDegats.visible = false
	$PopUpDegats.position = position_depart
	$PopUpDegats.modulate.a = 1.0
