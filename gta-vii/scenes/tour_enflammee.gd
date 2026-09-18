extends CharacterBody3D

# Annonce une vraie mort au RoomManager, avant la suppression du nœud.
signal died
var est_mort := false

var cible = null

@export var vie_max := 200.0
var vie := vie_max
var hitbox_radius = 1.5

@export_group('Portée')
@export var distance_attaque = 1.3
@export var distance_detection = 25.0
@export var distance_lacher = 30.0

@export_group("Attaque")
@export var attaque_cooldown = 3.0
var attaque_timer = 0.0 #temps initialisé à 0
@export var degats_ennemi = 30.0

var projectile_scene = preload("res://scenes/projectile_tour.tscn")
@onready var muzzle: Marker3D = $Muzzle
@onready var projectiles_tour = get_tree().current_scene.get_node("Ennemis/ProjectilesTour")
@onready var player = $"../../player"

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	
	var detection_shape: CollisionShape3D = $"SurfaceDetection/CollisionShape3D"
	detection_shape.shape.radius = distance_detection  #On met à jour la distance de detection en fonction de la valeur choisie en variable
	
	position = Vector3(randi_range(-20,20),0,randi_range(-20,20)) #On place l'ennemi aléatoirment dans la map # /!\ à modifier pour s'adapter à la taille de la map (peut être prendre un rayon graine de la map en input ?)
	
	pass # Replace with function body.

func _on_surface_de_detection_body_entered(body: Node3D) -> void:
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
		else:
			if attaque_timer <0 :
				tirer_projectile()


func prendre_degats(degats: float) -> void:
	# queue_free attend la fin de l'image : ignorer les impacts reçus entre-temps.
	if est_mort:
		return
	vie -= degats
	vie = max(vie, 0)
	print( self.name, " Touché : -", degats)
	
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

func tirer_projectile() -> void:
	if cible != null:
		var projectile = projectile_scene.instantiate()
		projectiles_tour.add_child(projectile)

		projectile.global_position = muzzle.global_position
		var dir : Vector3 = (cible.global_position - muzzle.global_position)
		
		projectile.direction = (dir + player.velocity.normalized()*dir.length()*player.speed/projectile.vitesse  ).normalized() 
	attaque_timer = attaque_cooldown

	


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
	$PopUpDegats.position = Vector3(rd1,3.4+rd2 ,0+rd3)
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
