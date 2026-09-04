extends ResourceNode3D
class_name TreeNode3D
## 3D Tree resource node - drops wood when harvested

func _init() -> void:
	max_hp = 3
	loot_type = "wood"
	loot_amount = 3
	hit_flash_color = Color(0.5, 0.9, 0.5, 1)
	model_name = "tree_oak_00"
	can_respawn = true
	respawn_time = 120.0


func _ready() -> void:
	# Randomize tree variant
	var tree_variants := [
		"tree_oak_00", "tree_oak_01", "tree_oak_02",
		"tree_pine_03", "tree_pine_04", "tree_pine_05",
		"tree_birch_06", "tree_birch_07", "tree_birch_08"
	]
	
	# Pick random variant if not specified
	if model_name == "tree_oak_00" or model_name.is_empty():
		model_name = tree_variants[randi() % tree_variants.size()]
	
	super._ready()
	add_to_group("trees")
