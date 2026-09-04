extends Node3D
class_name ZoneBase
## Base class for zone scenes (Green, Yellow, Red zones)

@export var zone_id := "green_zone"
@export var zone_display_name := "Green Zone"

var exit_button: Button

func _ready() -> void:
	print("[ZoneBase] Initializing: ", zone_display_name)
	
	# Spawn player at marker
	var player := get_node_or_null("Player3D")
	var spawn_point := get_node_or_null("PlayerSpawn") as Marker3D
	if player and spawn_point:
		player.global_position = spawn_point.global_position
	
	# Setup exit button
	_setup_exit_button()
	
	print("[ZoneBase] Ready: ", zone_display_name)


func _setup_exit_button() -> void:
	# Find existing or create exit button
	var ui_layer := get_node_or_null("UILayer") as CanvasLayer
	if not ui_layer:
		ui_layer = CanvasLayer.new()
		ui_layer.name = "UILayer"
		ui_layer.layer = 10
		add_child(ui_layer)
	
	exit_button = ui_layer.get_node_or_null("ExitButton")
	if not exit_button:
		exit_button = Button.new()
		exit_button.name = "ExitButton"
		exit_button.text = "🏠 EXIT"
		exit_button.custom_minimum_size = Vector2(100, 50)
		exit_button.position = Vector2(20, 20)
		
		# Style
		var style := StyleBoxFlat.new()
		style.bg_color = Color(0.3, 0.25, 0.2, 0.9)
		style.corner_radius_top_left = 6
		style.corner_radius_top_right = 6
		style.corner_radius_bottom_left = 6
		style.corner_radius_bottom_right = 6
		style.border_width_top = 2
		style.border_width_bottom = 2
		style.border_width_left = 2
		style.border_width_right = 2
		style.border_color = Color(0.5, 0.45, 0.35)
		exit_button.add_theme_stylebox_override("normal", style)
		
		var hover := style.duplicate()
		hover.bg_color = Color(0.4, 0.35, 0.3, 0.95)
		exit_button.add_theme_stylebox_override("hover", hover)
		
		ui_layer.add_child(exit_button)
	
	exit_button.pressed.connect(_on_exit_pressed)


func _on_exit_pressed() -> void:
	if GameManager:
		GameManager.return_home()
	else:
		push_error("[ZoneBase] GameManager not found!")
