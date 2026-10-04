extends CharacterBody3D

# Le niveau écoute la mort pour remplacer le jeu par l'écran de défaite.
# Émis uniquement quand des PV sont réellement retirés, pour le défi sans dégâts.
signal degats_recus(quantite: float)
signal died
var est_mort := false
var ameliorations: Node
var protection_secours := 0.0
signal entree_terminee
var entree_automatique := false
var cible_entree := Vector3.ZERO

# Mode de test : activé depuis main.gd avec la touche I.
var invincible: bool = false

@export var camera : Camera3D 
@onready var visual: Node3D = $visual
@onready var extincteur = $visual/weapon_holder/Extincteur
@onready var BarreDeVie = $Interface/Vie/BarreDeVie
@onready var damage_flash: ColorRect = $CanvasLayer/DamageFlash
var flash_tween: Tween

@onready var victim_manager: Node3D = $"../VictimManager"
@onready var Effets: Node3D = $"../Effets"
@onready var fleche_victime_scene = preload("res://scenes/effets/fleche_victime/fleche.tscn")
var fleche_victime = null
var fleche_tween = null
var input_victim_control_fait := false

@export_group("Déplacement")
## Vitesse de marche, en unités par seconde.
@export_range(0.0, 100.0, 0.1, "or_greater") var speed: float = 5.0

@export_group("Dash")
## Vitesse du dash, en unités par seconde.
@export_range(0.0, 100.0, 0.1, "or_greater") var dash_speed: float = 50.0
## Durée en secondes. Vitesse × durée donne la distance approximative du dash.
@export_range(0.01, 2.0, 0.01, "or_greater") var dash_duration: float = 0.1
@export_range(0.01, 2.0, 0.01, "or_greater") var dash_cooldown: float = 0.2

@onready var anim_tree: AnimationTree = $visual/pompier/visual/Armature/AnimationTree
const PARAM_BLEND := "parameters/blend_position"
var blend_actuel := Vector2.ZERO
const INVERSER_MODELE := false

var last_direction := Vector3.FORWARD 
var is_dashing := false
var dash_time_left := 0.0
var dash_cooldown_left := 0.0

	# Le gestionnaire active ce booléen si une victime sportive est dans la file.
# Un booléen ne peut pas s'additionner : deux sportives ne doublent pas le bonus.
var bonus_dash_actif: bool = false
const REDUCTION_DASH_ESCORTE: float = 0.2 #20 % de réduction

# Secousse caméra
var camera_tremble := 0.0
var sauvegarde_position = Vector3()
var camera_retour := false
	
	
func secouer_camera() -> void:
	sauvegarde_position = camera.position
	camera_tremble = 0.15
	camera_retour = false

func get_dash_cooldown() -> float:
	# Conserver dash_cooldown comme valeur de base évite les erreurs de cumul.
	# Exemple : 0.2 seconde × (1 - 0.2) = 0.16 seconde avec le bonus.
	if bonus_dash_actif:
		return dash_cooldown * (1.0 - REDUCTION_DASH_ESCORTE)
	return dash_cooldown


func _physics_process(delta: float) -> void:
	protection_secours = maxf(0.0, protection_secours - delta)
	if entree_automatique:
		_avancer_entree(delta)
		return
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
	
	#Secousse si attaque (on a besoin de delta donc on le met dans le physique process)
	if camera_tremble > 0.0:
		camera_tremble -= delta
		camera.position += Vector3(randf_range(-0.3, 0.3),randf_range(-0.3, 0.3),0.0)
	elif not camera_retour and camera_tremble<0:
		camera_retour = true
		var tween_camera = create_tween()
		tween_camera.tween_property(camera, "position", sauvegarde_position, 0.1)
	
	
	if Input.is_action_just_pressed("dash") and (not is_dashing) and dash_cooldown_left <= 0.0:
		#initialise le dash
		is_dashing = true
		# Chaque nouveau dash utilise le délai effectif, avec ou sans escorte.
		# Un délai déjà commencé n'est pas recalculé en cours de route.
		dash_cooldown_left = get_dash_cooldown()
		dash_time_left = dash_duration
		
	if dash_cooldown_left > 0.0:
		dash_cooldown_left -= delta

	
	if is_dashing:
		#applique le dash
		velocity.x = last_direction.x * dash_speed
		velocity.z = last_direction.z * dash_speed
		
		dash_time_left -= delta
		
		if dash_time_left <= 0.0:
			is_dashing = false
	else:
		#On normalise pour ne pas aller plus vite en diagonale
		if direction.length() > 0.0:
			direction = direction.normalized()
			#On update la dernière direction prise
			last_direction = direction
			velocity.x = direction.x * speed
			velocity.z = direction.z * speed
		else:
			velocity.x = 0.0
			velocity.z = 0.0
		
	
	#VISEE DU JOUEUR
	
	#Recuperation de la position de la souris
	#Le viewport est la zone dans laquelle le jeu est rendu 
	#On récupère donc le vecteur position de la souris en 2D, sur l'écran.
	var mouse_position = CursorManager.position_curseur
	
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
	
		if Input.is_action_just_pressed("victim_control"):
			if not input_victim_control_fait:
				input_victim_control_fait = true
				bouger_victime(target_position)
		else:
			input_victim_control_fait = false
				
		if Input.is_action_just_pressed("victime_nav_auto"):
			victim_manager.retour_nav_auto()
	
	if Input.is_action_pressed("primary_attack"):
		extincteur.start_primary_attack()
	else:
		extincteur.stop_primary_attack()
	
	animate(delta)
	move_and_slide()

func animate(delta: float) -> void:
	var vitesse_h := Vector3(velocity.x, 0.0, velocity.z)
	
	var local := visual.global_transform.basis.orthonormalized().inverse() * vitesse_h

	var cible := Vector2(local.x, -local.z) / speed
	
	if INVERSER_MODELE:
		cible = -cible
	cible = cible.limit_length(1.0)
	
	blend_actuel = blend_actuel.lerp(cible, 1.0 - exp(-12.0 * delta))
	anim_tree[PARAM_BLEND] = blend_actuel
	
	

func flash_degats() -> void:
	if flash_tween:
		flash_tween.kill()
	damage_flash.visible = true
	damage_flash.color.a = 0.0
	
	flash_tween = create_tween()
	flash_tween.tween_property(damage_flash,"color:a",0.4,0.05)
	flash_tween.tween_property(damage_flash,"color:a",0.0,0.2)

func prendre_degats(degats: float) -> void:
	# Quitter la fonction avant de retirer de la vie si le mode est actif.
	if invincible or est_mort or protection_secours > 0.0:
		return
		
	if is_instance_valid(ameliorations):
		degats = ameliorations.absorber_degats_joueur(maxf(degats, 0.0))
	if degats <= 0.0: return
	flash_degats()
	secouer_camera()
	var vie_avant: float = BarreDeVie.value
	BarreDeVie.value -= maxf(degats, 0.0)
	BarreDeVie.value = max(BarreDeVie.value, 0)
	if BarreDeVie.value < vie_avant:
		degats_recus.emit(vie_avant - BarreDeVie.value)
	print( self.name, " Touché : -", degats)
	
	if BarreDeVie.value <= 0:
		if is_instance_valid(ameliorations) and ameliorations.utiliser_secours():
			# Une seconde évite qu'une salve simultanée annule immédiatement le secours.
			protection_secours = 1.0
			return
		mourir()

func mourir():
	# Plusieurs impacts peuvent arriver avant la suppression en fin d'image.
	if est_mort:
		return
	est_mort = true
	extincteur.stop_primary_attack()
	died.emit()
	queue_free()

func animation_fleche(position):
	if fleche_tween:
		fleche_tween.kill()
	if is_instance_valid(fleche_victime):
		fleche_victime.queue_free()
	
	fleche_victime = fleche_victime_scene.instantiate()
	fleche_victime.add_to_group("fleche")
	Effets.add_child(fleche_victime)
	fleche_victime.position = position
	fleche_victime.visible = true
	fleche_tween = create_tween()
	fleche_tween.tween_property(fleche_victime, "position", position + Vector3(0,-2,0),0.2)
	fleche_tween.tween_property(fleche_victime, "position", position + Vector3(0,-1.7,0),0.2)
	
	fleche_tween.tween_callback(cacher_fleche)
	
	
func cacher_fleche():
	if is_instance_valid(fleche_victime):
		fleche_victime.visible = false


func annuler_ordre_victimes() -> void:
	# Reconnecter d'abord la file : aucune victime ne doit suivre la flèche supprimée.
	victim_manager.reorganiser_file()
	# Arrêter aussi son animation pour qu'elle ne rappelle pas cacher_fleche plus tard.
	if fleche_tween:
		fleche_tween.kill()
		fleche_tween = null
	if is_instance_valid(fleche_victime):
		fleche_victime.queue_free()
	fleche_victime = null
	input_victim_control_fait = false
	
func bouger_victime(position):
	animation_fleche(position)
	victim_manager.diriger_victime(fleche_victime)
	
	
	

func commencer_entree(cible: Vector3) -> void:
	cible_entree = cible
	entree_automatique = true
	extincteur.stop_primary_attack()

func _avancer_entree(delta: float) -> void:
	var direction := cible_entree - global_position
	direction.y = 0.0
	if direction.length() <= 0.04:
		entree_automatique = false
		velocity = Vector3.ZERO
		animate(delta)
		entree_terminee.emit()
		return
	# Même vitesse et même animation que le déplacement normal, sans lire les inputs.
	var vitesse := minf(speed, direction.length() / delta)
	direction = direction.normalized()
	velocity.x = direction.x * vitesse
	velocity.z = direction.z * vitesse
	if not is_on_floor():
		velocity += get_gravity() * delta
	visual.look_at(visual.global_position + direction, Vector3.UP)
	animate(delta)
	move_and_slide()
