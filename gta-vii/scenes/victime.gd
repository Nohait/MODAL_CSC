extends CharacterBody3D

signal freed(victim: CharacterBody3D)

@onready var interaction_label: Label3D = $InteractionLabel

@export_group("Bonus d'escorte")
## Cocher pour créer une sportive : cooldown du dash réduit de 20 % pendant l'escorte.
## Plusieurs sportives ne cumulent pas leur bonus. L'évacuation retire leur contribution.
@export var bonus_dash: bool = false

@export_group("Suivi")

## Vitesse de déplacement de la victime.
@export_range(0.0, 20.0, 0.1, "or_greater") var follow_speed: float = 3.0

# Distance à laquelle la victime s'arrête de suivre sa cible.
@export_range(0.0, 10.0, 0.1, "or_greater") var stop_distance: float = 2.0

var follow_target: Node3D = null

var player_nearby := false
var is_freed := false

func _on_detection_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = true
		if not is_freed :
			interaction_label.visible = true
		

func _on_detection_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_nearby = false
		interaction_label.visible = false
		
func _ready() -> void:
	# Chaque sportive possède sa propre copie du matériau : sa couleur orange
	# ne doit pas recolorer les victimes ordinaires qui partagent la même ressource.
	if bonus_dash:
		var visuel: MeshInstance3D = $MeshInstance3D
		var materiau := visuel.get_active_material(0).duplicate() as StandardMaterial3D
		materiau.albedo_color = Color(1.0, 0.65, 0.12, 1.0)
		visuel.set_surface_override_material(0, materiau)
		$BonusLabel.show()
	update_interaction_label()


func get_nom_affiche() -> String:
	# Le nom du nœud distingue les individus ; le suffixe explique leur type au menu.
	if bonus_dash:
		return "%s (sportive : dash -20 %%)" % name
	return str(name)

func _physics_process(_delta: float) -> void:
	if player_nearby and not is_freed:
		if Input.is_action_just_pressed("interact"):
			free_victim()

	if is_freed and follow_target != null:
		follow_target_node()

func free_victim() -> void:
	is_freed = true
	interaction_label.visible = false

	freed.emit(self)

	print("Victime libérée")
	
func follow_target_node() -> void:
	var to_target: Vector3 = follow_target.global_position - global_position
	
	to_target.y = 0.0
	
	var distance: float = to_target.length()

	if distance > stop_distance:
		var direction: Vector3 = to_target.normalized()
		
		velocity.x = direction.x * follow_speed
		velocity.z = direction.z * follow_speed
	else:
		velocity.x = 0.0
		velocity.z = 0.0

	move_and_slide()

func update_interaction_label() -> void:
	var events := InputMap.action_get_events("interact")

	if events.is_empty():
		interaction_label.text = "Libérer"
		return

	var event := events[0]

	if event is InputEventKey:
		interaction_label.text = "[" + event.as_text_physical_keycode() + "] Libérer"
