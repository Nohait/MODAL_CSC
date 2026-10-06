extends Area3D

@export var vitesse := 20.0
@export var degats := 25.0
var flaque_scene = preload("res://scenes/ennemis/dangers/flaque_de_feu.tscn")
# Projectile -> ProjectilesTour -> Salle : ses flaques restent dans cette salle.
@onready var flaques = get_parent().get_parent().get_node("FlaquesDeFeu")
var direction := Vector3.ZERO
# Transmis par la tourelle aux flaques issues de ses projectiles.
var etage := 1

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * vitesse * delta #le projectile bouge
	#on crée la flaque quand le projectile touche le sol
	if position.y <= 0.4:
		var flaque = flaque_scene.instantiate()
		flaque.etage = etage
		# Régler l'emplacement et la taille AVANT que _ready démarre les flammes.
		# to_local convertit la position du projectile dans le conteneur des flaques.
		flaque.position = flaques.to_local(global_position)
		flaque.position.y = 0.2
		# Même tirage de taille que les flaques présentes au début d'une salle.
		flaque.choisir_taille_aleatoire()
		flaques.add_child(flaque)
		preload("res://scenes/effets/combat/trace_combat.gd").sur_sol(flaques, global_position, Color(0.045, 0.025, 0.015, 0.7), 1.5, 8.0)
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player") or body.is_in_group("victime") : #si c'est un joueur, il prend des degats
		var multiplier = randf_range(0.9,1.1)
		body.prendre_degats(round(multiplier * degats *100.0)/100.0)
		queue_free()
	if body.is_in_group("collider"): #si on rencontre un mur, le projectile disparaît
		var rayon := PhysicsRayQueryParameters3D.create(global_position - direction * 0.8, global_position + direction * 0.8, 1)
		var impact := get_world_3d().direct_space_state.intersect_ray(rayon)
		if not impact.is_empty():
			preload("res://scenes/effets/combat/trace_combat.gd").creer(flaques, impact.position, impact.normal, Color(0.045, 0.025, 0.015, 0.7), 1.0, 8.0)
		queue_free()
		return
