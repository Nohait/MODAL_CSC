extends CharacterBody3D
# L'agent calcule le chemin ; ce CharacterBody3D réalise le déplacement.
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent

var cible = null
@export var vie_max := 100.0
var vie := vie_max

@export var distance_attaque = 1.5
@export var distance_detection = 10.0
@export var distance_lacher = 20.0

@export var attaque_cooldown = 1.0
@export var attaque_timer = 0.0 #temps initialisé à 0
@export var degats_ennemi = 10.0

@export var vitesse_ennemi = 7


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
	# Le joueur peut avoir été supprimé après sa mort : ne plus lire sa position.
	if not is_instance_valid(cible):
		cible = null
		velocity = Vector3.ZERO
		return
	
	if cible != null:	#Une fois que le joueur est pris pour cible
		var distance = global_position.distance_to(cible.global_position)
		
		
		if distance > distance_lacher: #calcul de sortie de range
			cible = null
			velocity = Vector3.ZERO
			move_and_slide()	
			
		elif distance > distance_attaque: # comportement dans la range
			# Suivre les étapes d'un chemin au lieu de foncer directement vers le joueur.
			suivre_cible_navigation()
			
		else: #comportement dans la portée d'attaque
			velocity = Vector3.ZERO 
			
			if attaque_timer < 0.0:
				attaque()
			
func suivre_cible_navigation() -> void:
	# Arrêt par défaut si la carte n'est pas prête ou si aucun chemin n'est trouvé.
	velocity = Vector3.ZERO
	# Au démarrage, Godot synchronise la carte de navigation avec le monde physique.
	# Une itération à 0 indique qu'il faut attendre le prochain delta.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	# La destination est actualisée car le joueur peut bouger pendant la poursuite.
	navigation_agent.target_position = cible.global_position
	var prochaine_position := navigation_agent.get_next_path_position()

	# Ce point peut être intermédiaire.
	var direction := prochaine_position - global_position
	direction.y = 0.0 # Déplacement horizontal
	if direction.length() > 0.01:
		# Normaliser conserve uniquement la direction.
		velocity = direction.normalized() * vitesse_ennemi

	# L'agent ne déplace rien lui-même : appliquer la vitesse avec les collisions.
	move_and_slide()


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
var popup_tween: Tween
func afficher_degats(degats: float) -> void:
	$PopUpDegats.text = "-" + str(degats)
	$PopUpDegats.modulate = couleur_degats(degats)
	$PopUpDegats.position = Vector3(0,2.5,0)
	$PopUpDegats.font_size = 100
	$PopUpDegats.visible = true
	
	if popup_tween:
		popup_tween.kill()
		
	var position_depart = Vector3(0,2.5,0)
	var position_fin = position_depart + Vector3(0, 1, 0)
	var taille_fin = 120
	popup_tween = create_tween() #Fonction qui permet de faire un gradient

	popup_tween.parallel().tween_property($PopUpDegats,"position",position_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"font_size",taille_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"modulate:a",0.0,0.4)

	await popup_tween.finished

	$PopUpDegats.visible = false
