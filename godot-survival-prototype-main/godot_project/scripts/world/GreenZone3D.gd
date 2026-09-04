extends ZoneScene3D

# Green Zone - Easiest zone, lots of trees and bushes
# Low enemy count, good for resource gathering

var exit_button: Button

func _init() -> void:
	zone_name = "Green Zone"
	zone_difficulty = 1
	enemy_count = 2
	zone_size = Vector2(60, 60)
	ground_color = Color(0.35, 0.55, 0.25)  # Grassy green
	ambient_light_color = Color(0.95, 1.0, 0.9)
	ambient_light_energy = 0.6
	fog_enabled = false
	
	# Resource layout with Vector3 positions
	resource_layout = [
		{"scene": "tree", "offset": Vector2(-14, 8)},
		{"scene": "tree", "offset": Vector2(11, 4)},
		{"scene": "tree", "offset": Vector2(6, -11)},
		{"scene": "tree", "offset": Vector2(-8, -15)},
		{"scene": "tree", "offset": Vector2(18, -5)},
		{"scene": "rock", "offset": Vector2(11, 4)},
		{"scene": "rock", "offset": Vector2(-12, -8)},
		{"scene": "bush", "offset": Vector2(14, -3)},
		{"scene": "bush", "offset": Vector2(-5, 12)},
		{"scene": "bush", "offset": Vector2(3, -18)},
		{"scene": "bush", "offset": Vector2(-16, 5)},
	]


func _ready() -> void:
	super._ready() if has_method("_ready") else null
	_setup_player()
	_setup_exit_button()
	print("[GreenZone3D] Ready")


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
	style.bg_color = Color(0.25, 0.35, 0.25, 0.9)
	style.corner_radius_top_left = 6
	style.corner_radius_top_right = 6
	style.corner_radius_bottom_left = 6
	style.corner_radius_bottom_right = 6
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.4, 0.55, 0.4)
	exit_button.add_theme_stylebox_override("normal", style)
	
	var hover := style.duplicate()
	hover.bg_color = Color(0.35, 0.45, 0.35, 0.95)
	exit_button.add_theme_stylebox_override("hover", hover)
	
	ui_layer.add_child(exit_button)
	exit_button.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	if GameManager:
		GameManager.return_home()
	else:
		push_error("[GreenZone3D] GameManager not found!")
