extends CharacterBody3D

# Annonce une vraie mort au RoomManager, avant la suppression du nœud.
signal died
var est_mort := false

# L'agent calcule le chemin ; ce CharacterBody3D réalise le déplacement.
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var detection_shape: CollisionShape3D = $SurfaceDetection/CollisionShape3D
@onready var SurfaceDetection: Area3D = $"SurfaceDetection"
@onready var player = get_tree().get_first_node_in_group("player")
var cible = null

@export var vie_max := 100.0
var vie := vie_max

@export var vitesse_ennemi = 7

var hitbox_radius = 0.9 #Définit comment l'extincteur va implémenter la largueur de l'ennemi dans son cône d'attaque

@export_group('Portée')
@export var distance_attaque = 1.3
@export var distance_detection = 10.0
@export var distance_lacher = 20.0
var distance_min = 1000.0 #Pour définir qui est la cible

@export_group("Attaque")
@export var attaque_cooldown = 1.0
var attaque_timer = 0.0 #temps initialisé à 0
@export var degats_ennemi = 10.0
@export var repos_apres_attaque := 0.3
var timer_apres_attaque := 0.0

@export_group("Cible_manager")
@export var chgt_cible_cooldown = 1.3 #On reste 3s sur la meme cible avant de se demander si on change
var chgt_cible_timer = 0.0 #temps initialisé à 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	detection_shape.shape.radius = distance_detection  #On met à jour la distance de detection en fonction de la valeur choisie en variable
	
	# Le RoomManager choisit un emplacement libre : ne pas remplacer sa position ici.
	
	pass # Replace with function body.

		
func _physics_process(delta):
	attaque_timer -= delta 	#A chaque frame, le cooldown réduit
	timer_apres_attaque -= delta
	
	#On définit la cible.
	#Il y a un timer pour eviter que l'ennemi soit indécis
	if cible == null:
		chgt_cible_timer = 0.0
	chgt_cible_timer -= delta
	if chgt_cible_timer < 0:
		choisir_cible()
	
	if timer_apres_attaque > 0.0:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# Le joueur peut avoir été supprimé après sa mort : ne plus lire sa position.
	if not is_instance_valid(cible):
		cible = null
		velocity = Vector3.ZERO
		return
	
	if cible != null:	#Une fois que le joueur est pris pour cible
		var distance = global_position.distance_to(cible.global_position)
		
		#On tourne l'ennemi et sa hitbox vers la cible
		var direction = global_position.direction_to(cible.global_position)
		var theta = atan2(direction.x, direction.z) - rotation.y	
		self.rotate(Vector3(0,1,0),theta)
		detection_shape.rotate(Vector3(0,1,0),theta)
		
		
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

func choisir_cible():
	var cible_avant = cible #on sauvegardde la cible
	var bodies = SurfaceDetection.get_overlapping_bodies()
	if cible != null:
		distance_min = global_position.distance_to(cible.global_position)
	else:
		distance_min = 1000.0
		
	for body in bodies:
		#les cibles ne peuvent etre que des gentils libérés
		if body.is_in_group("player") or (body.is_in_group("victime") and body.is_freed):
			var distance_body = global_position.distance_to(body.global_position)
			print(body, " dbody: ",distance_body," dmin: ", distance_min)
			
			#La cible choisie est la plus proche
			if distance_body <= distance_min:
				distance_min = distance_body
				cible = body
		
	chgt_cible_timer = chgt_cible_cooldown
	if cible != cible_avant:
		print("J'ai changé de cible de cible")
		print("Cible avant: ", cible_avant)
		print("Cible mtn: ", cible)

func prendre_degats(degats: float) -> void:
	# queue_free attend la fin de l'image : ignorer les impacts reçus entre-temps.
	if est_mort:
		return
	vie -= degats
	vie = max(vie, 0)
	#Le joueur prends l'aggro
	if cible != player:
		cible = player
		chgt_cible_timer = chgt_cible_cooldown*5
	
	afficher_degats(degats)
	
	if vie <= 0:
		mourir()
		
func mourir():
	# Une mort ne doit émettre le signal qu'une seule fois.
	if est_mort:
		return
	est_mort = true
	died.emit()
	print("Bravo, vous avez tué l'ennemi")
	queue_free()

func attaque() -> void:
	if cible != null:
		var multiplier = randf_range(0.9,1.1)
		cible.prendre_degats(round(multiplier * degats_ennemi *100.0)/100.0)

	attaque_timer = attaque_cooldown
	timer_apres_attaque = repos_apres_attaque

	


func couleur_degats(degats: float) -> Color:
	
	var t = clamp((degats - 0.9*degats_ennemi) / 1.0, 0.0, 1.0)
	
	var blanc = Color(0.998, 1.0, 0.29, 1.0)
	var orange = Color(1.0, 0.388, 0.0, 1.0)
	
	return blanc.lerp(orange, t)
	
#On affiche les dégats
var popup_tween: Tween
func afficher_degats(degats: float) -> void:
	var rd1 = randf_range(-0.1,0.1)
	var rd2 = randf_range(-0.1,0.1)
	var rd3 = randf_range(-0.1,0.1)
	
	$PopUpDegats.text = "-" + str(degats)
	$PopUpDegats.modulate = couleur_degats(degats)
	$PopUpDegats.position = Vector3(rd1,2.5+rd2 ,0+rd3)
	$PopUpDegats.font_size = 100*(1+rd2)
	$PopUpDegats.visible = true
	
	if popup_tween:
		popup_tween.kill()
	
	var position_depart = Vector3(rd1,2.5+rd2 ,0+rd3)
	var position_fin = position_depart + Vector3(rd2, 1+ rd3, 0+ rd1)
	var taille_fin = 120*(1+rd1)
	popup_tween = create_tween() #Fonction qui permet de faire un gradient

	popup_tween.parallel().tween_property($PopUpDegats,"position",position_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"font_size",taille_fin,0.2)
	popup_tween.parallel().tween_property($PopUpDegats,"modulate:a",0.0,0.4)

	await popup_tween.finished

	$PopUpDegats.visible = false
