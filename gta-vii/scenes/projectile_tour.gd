extends Area3D

@export var vitesse := 20.0
@export var degats := 20.0

var direction := Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * vitesse * delta
	if position.y <= 0.0:
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var multiplier = randf_range(0.9,1.1)
		body.prendre_degats(round(multiplier * degats *100.0)/100.0)
		queue_free()
