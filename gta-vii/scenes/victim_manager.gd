extends Node

@onready var player: CharacterBody3D = $"../player"

var freed_victims: Array[CharacterBody3D] = []

func _ready() -> void:
	var victims := get_tree().get_nodes_in_group("victims")

	for victim in victims:
		##On connecte le signal freed à la fonction qui enregistre une victime libérée
		victim.freed.connect(register_victim)


func register_victim(victim: CharacterBody3D) -> void:
	if freed_victims.is_empty():
		victim.follow_target = player
	else:
		victim.follow_target = freed_victims[-1]

	freed_victims.append(victim)
