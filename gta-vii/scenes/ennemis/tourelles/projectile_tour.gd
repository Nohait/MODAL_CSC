extends Area3D

@export var vitesse := 20.0
@export var degats := 25.0
var flaque_scene = preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn")
# Projectile -> ProjectilesTour -> Salle : ses flaques restent dans cette salle.
@onready var flaques = get_parent().get_parent().get_node("FlaquesDeFeu")
var direction := Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * vitesse * delta #le projectile bouge
	#on crée la flaque quand le projectile touche le sol
	if position.y <= 0.4:
		var flaque = flaque_scene.instantiate()
		flaques.add_child(flaque)
		# Les deux conteneurs peuvent être décalés : conserver la position dans le monde.
		flaque.global_position = global_position
		flaque.position.y = 0.2
		
		#On randomise les caractéristiques de la flaque
		var rd_scale = randf_range(1,2)
		flaque.scale *= rd_scale
		flaque.get_node("PopUpDegats").scale /= rd_scale
		flaque.hitbox_radius *= rd_scale
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"): #si c'est un joueur, il prend des degats
		var multiplier = randf_range(0.9,1.1)
		body.prendre_degats(round(multiplier * degats *100.0)/100.0)
		queue_free()
	if body.is_in_group("collider"): #si on rencontre un mur, le projectile disparaît
		queue_free()
		return
