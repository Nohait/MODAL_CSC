extends Node3D

## Main3D - Main game scene controller for 3D version
## Handles initialization and coordination of game systems

@onready var inventory: Node = $Inventory
@onready var crafting_manager: Node = $CraftingManager
@onready var zone_manager: ZoneManager3D = $ZoneManager3D
@onready var world: Node3D = $World3D
@onready var ui_layer: CanvasLayer = $UILayer
@onready var fade_rect: ColorRect = $UILayer/FadeRect

var _is_paused := false

func _ready() -> void:
	# Configure zone manager
	zone_manager.set_world(world)
	zone_manager.set_zone_holder($ZoneManager3D/ZoneContainer)
	
	# Connect zone signals
	zone_manager.zone_loading.connect(_on_zone_loading)
	zone_manager.zone_loaded.connect(_on_zone_loaded)
	
	# Hide cursor for gameplay (optional)
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	
	# Load default zone
	await get_tree().process_frame
	zone_manager.load_zone("green", true)
	
	print("[Main3D] Game initialized")

func _input(event: InputEvent) -> void:
	# Toggle pause
	if event.is_action_pressed("ui_cancel"):
		toggle_pause()
	
	# Toggle inventory
	if event.is_action_pressed("inventory"):
		_toggle_ui($UILayer/InventoryUI)
	
	# Toggle crafting
	if event.is_action_pressed("crafting"):
		_toggle_ui($UILayer/CraftingUI)
	
	# Toggle map
	if event.is_action_pressed("map"):
		_toggle_ui($UILayer/MapUI)

func _toggle_ui(ui_node: Control) -> void:
	if not ui_node:
		return
	ui_node.visible = not ui_node.visible
	
	# Pause when UI is open
	if ui_node.visible:
		_pause_gameplay()
	else:
		_resume_gameplay()

func toggle_pause() -> void:
	_is_paused = not _is_paused
	get_tree().paused = _is_paused
	
	if _is_paused:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	else:
		# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
		pass

func _pause_gameplay() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	# Could pause the tree here if needed

func _resume_gameplay() -> void:
	# Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	pass

func _on_zone_loading(zone_key: String) -> void:
	# Fade to black
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 1.0, 0.3)

func _on_zone_loaded(zone_key: String) -> void:
	# Fade back in
	var tween = create_tween()
	tween.tween_property(fade_rect, "color:a", 0.0, 0.3)

func change_zone(zone_key: String) -> void:
	zone_manager.load_zone(zone_key)

func get_player() -> CharacterBody3D:
	if world and world.has_method("get_player"):
		return world.get_player()
	return null

func get_inventory() -> Node:
	return inventory

func get_crafting_manager() -> Node:
	return crafting_manager
