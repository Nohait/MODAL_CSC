extends Area3D

@export var vitesse := 20.0
@export var degats := 25.0
var flaque_scene = preload("res://scenes/flaque_de_feu.tscn")
@onready var flaques = get_tree().current_scene.get_node("Ennemis/FlaquesDeFeu")
var direction := Vector3.ZERO

func _ready() -> void:
	body_entered.connect(_on_body_entered)

func _physics_process(delta: float) -> void:
	position += direction * vitesse * delta
	if position.y <= 0.3:
		var flaque = flaque_scene.instantiate()
		flaques.add_child(flaque)
		flaque.position = self.position
		var rd_scale = randf_range(1,2)
		flaque.scale *= rd_scale
		flaque.get_node("PopUpDegats").scale /= rd_scale
		queue_free()

func _on_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		var multiplier = randf_range(0.9,1.1)
		body.prendre_degats(round(multiplier * degats *100.0)/100.0)
		queue_free()
