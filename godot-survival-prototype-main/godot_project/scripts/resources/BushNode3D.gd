extends ResourceNode3D
class_name BushNode3D
## 3D Bush resource node - drops berries/fiber when harvested

func _init() -> void:
	max_hp = 2
	loot_type = "fiber"
	loot_amount = 2
	hit_flash_color = Color(0.6, 0.9, 0.6, 1)
	model_name = "bush_normal_00"
	can_respawn = true
	respawn_time = 60.0


func _ready() -> void:
	# Randomize bush variant
	var bush_variants := [
		"bush_normal_00", "bush_normal_04",
		"bush_berry_01", "bush_berry_05",
		"bush_dead_02", "bush_dead_06",
		"bush_flowering_03", "bush_flowering_07"
	]
	
	# Pick random variant
	if model_name == "bush_normal_00" or model_name.is_empty():
		model_name = bush_variants[randi() % bush_variants.size()]
	
	# Berry bushes give food
	if "berry" in model_name:
		loot_type = "berries"
		loot_amount = 3
	
	super._ready()
	add_to_group("bushes")
