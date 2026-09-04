extends ResourceNode3D
class_name RockNode3D
## 3D Rock resource node - drops stone/ore when harvested

func _init() -> void:
	max_hp = 5
	loot_type = "stone"
	loot_amount = 2
	hit_flash_color = Color(0.8, 0.8, 0.7, 1)
	model_name = "rock_boulder_00"
	can_respawn = true
	respawn_time = 180.0


func _ready() -> void:
	# Randomize rock variant
	var rock_variants := [
		"rock_boulder_00", "rock_boulder_01", "rock_boulder_02",
		"rock_boulder_03", "rock_boulder_04",
		"rock_small_05", "rock_small_06", "rock_small_07",
		"rock_slab_08", "rock_slab_09", "rock_slab_10"
	]
	
	# Pick random variant if not specified
	if model_name == "rock_boulder_00" or model_name.is_empty():
		model_name = rock_variants[randi() % rock_variants.size()]
	
	# Ore nodes have different loot
	if "ore" in model_name:
		loot_type = "iron_ore"
		loot_amount = 3
	
	super._ready()
	add_to_group("rocks")
