extends Node3D
class_name HomeBase
## Home Base scene - safe zone with storage, map station, crafting

@onready var storage_ui: Control = $UILayer/StorageUI
@onready var zone_map_ui: Control = $UILayer/ZoneMapUI

var storage_box: StaticBody3D
var map_station: StaticBody3D

func _ready() -> void:
	print("[HomeBase] Initializing...")
	
	# Find props
	storage_box = $Props/StorageBox
	map_station = $Props/MapStation
	
	# Spawn player at marker
	var player := $Player3D
	var spawn_point := $PlayerSpawn as Marker3D
	if player and spawn_point:
		player.global_position = spawn_point.global_position
	
	# Connect prop interactions
	if storage_box:
		storage_box.storage_opened.connect(_on_storage_opened)
	
	if map_station:
		map_station.map_opened.connect(_on_map_opened)
	
	# Connect UI signals
	if zone_map_ui:
		zone_map_ui.travel_requested.connect(_on_travel_requested)
		zone_map_ui.closed.connect(_on_ui_closed)
	
	if storage_ui:
		storage_ui.closed.connect(_on_ui_closed)
	
	print("[HomeBase] Ready")


func _on_storage_opened() -> void:
	if storage_ui:
		storage_ui.open()


func _on_map_opened() -> void:
	if zone_map_ui:
		zone_map_ui.open()


func _on_travel_requested(zone_id: String) -> void:
	if GameManager:
		GameManager.travel_to(zone_id)


func _on_ui_closed() -> void:
	# Resume game input if needed
	pass
