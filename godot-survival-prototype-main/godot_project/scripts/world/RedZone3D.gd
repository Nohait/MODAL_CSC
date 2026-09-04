extends ZoneScene3D

# Red Zone - Hardest zone, rare resources
# Many strong enemies, dangerous environment

func _init() -> void:
	zone_name = "Red Zone"
	zone_difficulty = 3
	enemy_count = 6
	zone_size = Vector2(80, 80)
	ground_color = Color(0.45, 0.35, 0.3)  # Barren/rocky
	ambient_light_color = Color(0.9, 0.85, 0.85)
	ambient_light_energy = 0.4
	fog_enabled = true
	fog_color = Color(0.5, 0.4, 0.4)
	fog_density = 0.01
	
	# Resource layout - lots of rocks with ore
	resource_layout = [
		{"scene": "tree", "offset": Vector2(-20, 15)},
		{"scene": "tree", "offset": Vector2(22, -8)},
		{"scene": "rock", "offset": Vector2(10, 10)},
		{"scene": "rock", "offset": Vector2(-12, 8)},
		{"scene": "rock", "offset": Vector2(15, -15)},
		{"scene": "rock", "offset": Vector2(-18, -10)},
		{"scene": "rock", "offset": Vector2(5, 20)},
		{"scene": "rock", "offset": Vector2(-8, -22)},
		{"scene": "rock", "offset": Vector2(25, 5)},
		{"scene": "rock", "offset": Vector2(-25, 0)},
		{"scene": "bush", "offset": Vector2(0, 12)},
	]
