extends CharacterBody3D

@onready var interaction_label: Label3D = $InteractionLabel

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
	update_interaction_label()	

func _physics_process(_delta: float) -> void:
	if player_nearby and not is_freed:
		if Input.is_action_just_pressed("interact"):
			free_victim()

func free_victim() -> void:
	is_freed = true
	interaction_label.visible = false
	print("Victime libérée")

func update_interaction_label() -> void:
	var events := InputMap.action_get_events("interact")

	if events.is_empty():
		interaction_label.text = "Libérer"
		return

	var event := events[0]

	if event is InputEventKey:
		interaction_label.text = "[" + event.as_text_physical_keycode() + "] Libérer"
