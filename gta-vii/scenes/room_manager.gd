extends Node

var remaining_victims: int = 0

func _ready() -> void:
	var victims := get_tree().get_nodes_in_group("victims")
	remaining_victims = victims.size()

	for victim in victims:
		victim.freed.connect(_on_victim_freed)

	print("Victimes à libérer : ", remaining_victims)


func _on_victim_freed(_victim: CharacterBody3D) -> void:
	remaining_victims -= 1

	print("Victimes restantes à libérer : ", remaining_victims)
