extends ZoneScene3D

# Yellow Zone - Medium difficulty, mixed resources
# More enemies, some tougher variants

var exit_button: Button

func _init() -> void:
	zone_name = "Yellow Zone"
	zone_difficulty = 2
	enemy_count = 4
	zone_size = Vector2(70, 70)
	ground_color = Color(0.6, 0.55, 0.35)  # Sandy/dry grass
	ambient_light_color = Color(1.0, 0.95, 0.85)
	ambient_light_energy = 0.5
	fog_enabled = true
	fog_color = Color(0.7, 0.65, 0.5)
	fog_density = 0.005
	
	# Resource layout - more rocks for ore
	resource_layout = [
		{"scene": "tree", "offset": Vector2(-18, 10)},
		{"scene": "tree", "offset": Vector2(15, -12)},
		{"scene": "tree", "offset": Vector2(-8, -20)},
		{"scene": "rock", "offset": Vector2(12, 6)},
		{"scene": "rock", "offset": Vector2(-15, -5)},
		{"scene": "rock", "offset": Vector2(8, -15)},
		{"scene": "rock", "offset": Vector2(-5, 18)},
		{"scene": "rock", "offset": Vector2(20, 3)},
		{"scene": "bush", "offset": Vector2(5, 8)},
		{"scene": "bush", "offset": Vector2(-10, -12)},
	]


func _ready() -> void:
	super._ready() if has_method("_ready") else null
	_setup_player()
	_setup_exit_button()
	print("[YellowZone3D] Ready")


func _setup_player() -> void:
	var player := get_node_or_null("Player3D")
	var spawn_point := get_node_or_null("PlayerSpawn") as Marker3D
	if not spawn_point:
		spawn_point = get_node_or_null("SpawnPoint") as Marker3D
	if player and spawn_point:
		player.global_position = spawn_point.global_position


func _setup_exit_button() -> void:
	var ui_layer := get_node_or_null("UILayer") as CanvasLayer
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		ui_layer.layer = 10
		add_child(ui_layer)
	
	exit_button = Button.new()
	exit_button.name = "ExitButton"
	exit_button.text = "🏠 EXIT"
	exit_button.custom_minimum_size = Vector2(100, 50)
	exit_button.position = Vector2(20, 20)
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.5, 0.4, 0.2, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.6, 0.5, 0.3)
	exit_button.add_theme_stylebox_override("normal", style)
	
	var hover := style.duplicate()
	hover.bg_color = Color(0.6, 0.5, 0.3, 0.95)
	exit_button.add_theme_stylebox_override("hover", hover)
	
	ui_layer.add_child(exit_button)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	if GameManager:
		GameManager.return_home()
	else:
		push_error("[YellowZone3D] GameManager not found!")
