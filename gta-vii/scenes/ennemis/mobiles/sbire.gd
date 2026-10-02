extends CharacterBody3D

const RETOUR_COMBAT = preload("res://scenes/effets/combat/retour_combat.gd")
@export_group("Retour visuel — mort")
@export var afficher_cendres := true
@export_range(0.2, 2.0, 0.05) var duree_cendres := 0.7

@export_group("Progression par étage")
## Pourcentage ajouté à la valeur de base par étage après le premier.
@export_range(0.0, 200.0, 1.0) var pv_par_etage_pourcent := 20.0
@export_range(0.0, 200.0, 1.0) var degats_par_etage_pourcent := 10.0
# Fourni par le créateur AVANT add_child, donc avant _ready.
var etage := 1


# Annonce une vraie mort au RoomManager, avant la suppression du nœud.
signal died
var est_mort := false

# L'agent calcule le chemin ; ce CharacterBody3D réalise le déplacement.
@onready var navigation_agent: NavigationAgent3D = $NavigationAgent
@onready var detection_shape: CollisionShape3D = $SurfaceDetection/CollisionShape3D
@onready var SurfaceDetection: Area3D = $"SurfaceDetection"
@onready var exclamationRouge: Node3D = $"PointExclamationRouge"
@onready var player = get_tree().get_first_node_in_group("player")
var cible = null



@export_group("Statistiques de base")
@export var vie_max := 100.0
var vie := vie_max

@export var vitesse_sbire = 7

var hitbox_radius = 0.9 #Définit comment l'extincteur va implémenter la largueur de le sbire dans son cône d'attaque

@export_group('Portée')
@export var distance_attaque = 1.3
@export var distance_detection = 10.0
@export var distance_lacher = 20.0
var distance_min = 1000.0 #Pour définir qui est la cible

@export_group("Attaque")
@export var attaque_cooldown = 1.0
var attaque_timer = 0.0 #temps initialisé à 0
@export var degats_sbire = 10.0
@export var repos_apres_attaque := 0.3
var timer_apres_attaque := 0.0

@export_group("Idle")
@export var rayon_idle := 10.0
@export var temps_idle_min := 1.0
@export var temps_idle_max := 5
var idle_timer := 0.0
var en_idle := true
@onready var cible_idle = Marker3D.new()


@export_group("Cible_manager")
@export var chgt_cible_cooldown = 1.3 #On reste 3s sur la meme cible avant de se demander si on change
@export var aggro_cooldown = chgt_cible_cooldown*3
var chgt_cible_timer = 0.0 #temps initialisé à 0

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	cible_idle.name = "Cible " + self.name
	get_parent().add_child(cible_idle)
	
	# Appliquer une seule fois à l'apparition, à partir des valeurs de l'Inspecteur.
	# Étage 1 = base ; étage 3 avec +20 % = base × 1.4 (progression linéaire).
	var paliers := maxi(etage - 1, 0)
	vie_max *= 1.0 + paliers * pv_par_etage_pourcent / 100.0
	vie = vie_max
	degats_sbire *= 1.0 + paliers * degats_par_etage_pourcent / 100.0
	detection_shape.shape.radius = distance_detection  #On met à jour la distance de detection en fonction de la valeur choisie en variable
	
	# Le RoomManager choisit un emplacement libre : ne pas remplacer sa position ici.
	
	pass # Replace with function body.

		
func _physics_process(delta):
	attaque_timer -= delta 	#A chaque frame, le cooldown réduit
	timer_apres_attaque -= delta
	
	#On définit la cible.
	#Il y a un timer pour eviter que le sbire soit indécis
	if cible == null:
		chgt_cible_timer = 0.0
	chgt_cible_timer -= delta
	if chgt_cible_timer < 0:
		choisir_cible()
	
	if cible == null or en_idle:
		idle_timer -= delta
		if idle_timer <0 :
			cible_idle.position =  choisir_destination_idle()
			cible = cible_idle
			idle_timer = randf_range(temps_idle_min,temps_idle_max)
	
	if timer_apres_attaque > 0.0:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	# Le joueur peut avoir été supprimé après sa mort : ne plus lire sa position.
	if not is_instance_valid(cible):
		cible = null
		velocity = Vector3.ZERO
		return
	
	if cible != null :	#Une fois que le joueur est pris pour cible
		var distance = global_position.distance_to(cible.global_position)
		
		#On tourne le sbire et sa hitbox vers la cible
		var direction = global_position.direction_to(cible.global_position)
		var theta = atan2(direction.x, direction.z) - rotation.y	
		self.rotate(Vector3(0,1,0),theta)
		detection_shape.rotate(Vector3(0,1,0),theta)
		
		
		if distance > distance_lacher: #calcul de sortie de range
			cible = null
			en_idle = true
			velocity = Vector3.ZERO
			move_and_slide()	
			
		elif distance > distance_attaque: # comportement dans la range
			# Suivre les étapes d'un chemin au lieu de foncer directement vers le joueur.
			suivre_cible_navigation()
			
		else: #comportement dans la portée d'attaque
			velocity = Vector3.ZERO 
			
			if attaque_timer < 0.0:
				if cible.is_in_group("player") or cible.is_in_group("victime"):
					attaque()
			
#On detecte pour bypass le cooldown de changer de cible dans choisir_cible() pour sortir instantanément de l'idle
func _on_surface_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		cible = body
		en_idle = false
		$SbireRepere.play("PopUp")

	elif body.is_in_group("victime") and body.is_freed:
		cible = body
		en_idle = false
		$SbireRepere.play("PopUp")

func choisir_destination_idle():
	var destination = Vector3.ZERO
	var map_rid := navigation_agent.get_navigation_map()
	for i in range(10):
		var rand_x = randf_range(-rayon_idle, rayon_idle)
		var rand_z = randf_range(-rayon_idle, rayon_idle)
		destination = Vector3(rand_x,0.0,rand_z) + global_position
		var position_nav := NavigationServer3D.map_get_closest_point(map_rid,destination)
		position_nav.y = 0.0
		destination.y = 0.0
		if destination.distance_to(position_nav) < 0.1:
			return destination
	return global_position

func suivre_cible_navigation() -> void:
	# Arrêt par défaut si la carte n'est pas prête ou si aucun chemin n'est trouvé.
	velocity = Vector3.ZERO
	# Au démarrage, Godot synchronise la carte de navigation avec le monde physique.
	# Une itération à 0 indique qu'il faut attendre le prochain delta.
	if NavigationServer3D.map_get_iteration_id(navigation_agent.get_navigation_map()) == 0:
		return

	# La destination est actualisée car le joueur peut bouger pendant la poursuite.
	navigation_agent.target_position = cible.global_position
	if en_idle:
		navigation_agent.target_position = cible_idle.position
	
	var prochaine_position := navigation_agent.get_next_path_position()

	# Ce point peut être intermédiaire.
	var direction := prochaine_position - global_position
	direction.y = 0.0 # Déplacement horizontal
	if direction.length() > 0.01:
		# Normaliser conserve uniquement la direction.
		velocity = direction.normalized() * vitesse_sbire
	
	# L'agent ne déplace rien lui-même : appliquer la vitesse avec les collisions.
	
	move_and_slide()

func choisir_cible():
	var cible_avant = cible #on sauvegardde la cible
	var bodies = SurfaceDetection.get_overlapping_bodies()
	if cible != null and !en_idle:
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
		en_idle = false
		$SbireRepere.play("PopUp")
		print("J'ai changé de cible de cible")
		print("Cible avant: ", cible_avant)
		print("Cible mtn: ", cible)

func animation_enerve():
	var tween_enerve = create_tween()
	var scale_origine = Vector3(0.16,0.16,0.16)
	#var couleur_origine = exclamation.modulate
	exclamationRouge.scale = Vector3(0.0,0.0,0.0)
	exclamationRouge.visible = true
	#exclamation.modulate= Color(0.546, 0.0, 0.016, 1.0)
	tween_enerve.tween_property(exclamationRouge, "scale", scale_origine, 0.2)
	tween_enerve.tween_property(exclamationRouge, "scale",  Vector3(0.0,0.0,0.0), aggro_cooldown-0.2)
	#await tween_enerve.finished
	#exclamation.visible = false
	#exclamation.modulate =couleur_origine



func prendre_degats(degats: float) -> void:
	# queue_free attend la fin de l'image : ignorer les impacts reçus entre-temps.
	if est_mort:
		return
	vie -= degats
	vie = max(vie, 0)
	
	#Le joueur prends l'aggro
	if cible != player:
		animation_enerve()
		
		cible = player
		chgt_cible_timer = aggro_cooldown #On veut que la cible ait le temps de "s'echapper"
	
	afficher_degats(degats)

	
	if vie <= 0:
		mourir()
		
func mourir():
	# Une mort ne doit émettre le signal qu'une seule fois.
	if est_mort:
		return
	est_mort = true
	
	#On joue le son de mort dans un parent de l'ennemi pour qu'il reste après la mort
	var steam_death=  AudioStreamPlayer3D.new()
	get_parent().add_child(steam_death)
	steam_death.stream = preload("res://assets/sounds/ennemis/steam_death.wav")
	steam_death.global_position = global_position
	steam_death.play()
	
	# Une copie du visuel termine l’animation ; le vrai sbire meurt immédiatement.
	if afficher_cendres:
		RETOUR_COMBAT.creer_cendres(self, [$Sketchfab_Scene, $droplet], duree_cendres)
	died.emit()
	print("Bravo, vous avez tué le sbire")
	queue_free()

func attaque() -> void:
	if cible != null:
		var multiplier = randf_range(0.9,1.1)
		cible.prendre_degats(round(multiplier * degats_sbire *100.0)/100.0)

	attaque_timer = attaque_cooldown
	timer_apres_attaque = repos_apres_attaque

	


func couleur_degats(degats: float) -> Color:
	
	var t = clamp((degats - 0.9*degats_sbire) / 1.0, 0.0, 1.0)
	
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
