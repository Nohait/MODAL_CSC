extends CanvasLayer
class_name MiniMapSystemClass
## Handles mini-map rendering, world map display, and exploration fog-of-war

signal area_discovered(position: Vector2, area_name: String)
signal poi_marked(poi_id: String, position: Vector2)
signal waypoint_set(position: Vector2)
signal waypoint_cleared()

# ============================================================================
# CONFIGURATION
# ============================================================================

enum MapMode {
	MINI_MAP,
	WORLD_MAP,
	TACTICAL,
}

enum IconType {
	PLAYER,
	ALLY,
	ENEMY,
	HOSTILE,
	NPC,
	POI_DISCOVERED,
	POI_UNDISCOVERED,
	POI_COMPLETED,
	RESOURCE_TREE,
	RESOURCE_ROCK,
	RESOURCE_ORE,
	RESOURCE_PLANT,
	CONTAINER,
	CONTAINER_LOOTED,
	VEHICLE,
	BASE,
	WAYPOINT,
	QUEST_OBJECTIVE,
	DANGER_ZONE,
	SAFE_ZONE,
	TRADER,
	BOSS,
	AIRDROP,
}

const ICON_COLORS := {
	IconType.PLAYER: Color(0.2, 0.6, 1.0),
	IconType.ALLY: Color(0.2, 0.8, 0.2),
	IconType.ENEMY: Color(1.0, 0.2, 0.2),
	IconType.HOSTILE: Color(0.9, 0.4, 0.1),
	IconType.NPC: Color(0.9, 0.9, 0.3),
	IconType.POI_DISCOVERED: Color(0.8, 0.6, 0.2),
	IconType.POI_UNDISCOVERED: Color(0.5, 0.5, 0.5, 0.5),
	IconType.POI_COMPLETED: Color(0.3, 0.7, 0.3),
	IconType.RESOURCE_TREE: Color(0.2, 0.7, 0.2),
	IconType.RESOURCE_ROCK: Color(0.6, 0.6, 0.6),
	IconType.RESOURCE_ORE: Color(0.8, 0.5, 0.2),
	IconType.RESOURCE_PLANT: Color(0.4, 0.8, 0.3),
	IconType.CONTAINER: Color(0.9, 0.8, 0.2),
	IconType.CONTAINER_LOOTED: Color(0.4, 0.4, 0.4),
	IconType.VEHICLE: Color(0.3, 0.5, 0.9),
	IconType.BASE: Color(0.2, 0.8, 0.9),
	IconType.WAYPOINT: Color(1.0, 1.0, 1.0),
	IconType.QUEST_OBJECTIVE: Color(1.0, 0.8, 0.0),
	IconType.DANGER_ZONE: Color(0.8, 0.1, 0.1, 0.5),
	IconType.SAFE_ZONE: Color(0.1, 0.6, 0.1, 0.5),
	IconType.TRADER: Color(0.2, 0.9, 0.7),
	IconType.BOSS: Color(0.8, 0.1, 0.5),
	IconType.AIRDROP: Color(0.9, 0.9, 1.0),
}

const ICON_SIZES := {
	IconType.PLAYER: 12.0,
	IconType.ALLY: 8.0,
	IconType.ENEMY: 6.0,
	IconType.HOSTILE: 6.0,
	IconType.NPC: 8.0,
	IconType.POI_DISCOVERED: 10.0,
	IconType.POI_UNDISCOVERED: 8.0,
	IconType.POI_COMPLETED: 10.0,
	IconType.RESOURCE_TREE: 4.0,
	IconType.RESOURCE_ROCK: 4.0,
	IconType.RESOURCE_ORE: 5.0,
	IconType.RESOURCE_PLANT: 3.0,
	IconType.CONTAINER: 5.0,
	IconType.CONTAINER_LOOTED: 4.0,
	IconType.VEHICLE: 10.0,
	IconType.BASE: 14.0,
	IconType.WAYPOINT: 10.0,
	IconType.QUEST_OBJECTIVE: 8.0,
	IconType.DANGER_ZONE: 20.0,
	IconType.SAFE_ZONE: 20.0,
	IconType.TRADER: 10.0,
	IconType.BOSS: 12.0,
	IconType.AIRDROP: 12.0,
}


# ============================================================================
# SETTINGS
# ============================================================================

@export var mini_map_size := Vector2(180, 180)
@export var mini_map_zoom := 1.0
@export var mini_map_position := Vector2(10, 10)
@export var world_map_scale := 0.5
@export var fog_chunk_size := 32
@export var discovery_radius := 200.0
@export var show_resources_on_minimap := true
@export var show_enemies_on_minimap := true
@export var rotation_enabled := true


# ============================================================================
# STATE
# ============================================================================

var current_mode: MapMode = MapMode.MINI_MAP
var player_position := Vector2.ZERO
var player_rotation := 0.0
var waypoint_position: Vector2 = Vector2.INF
var current_zone_id := ""
var current_zone_size := Vector2i(64, 64)

# Fog of war - Dictionary of discovered chunk positions
var _discovered_chunks: Dictionary = {}  # zone_id -> {chunk_pos -> discovered}

# Map markers
var _markers: Dictionary = {}  # marker_id -> marker data
var _temporary_markers: Array = []  # Markers that expire

# World map data
var _zone_positions: Dictionary = {}  # zone_id -> world position
var _zone_connections: Dictionary = {}  # zone_id -> [connected_zone_ids]

# UI References
var _mini_map_container: Control
var _mini_map_viewport: SubViewport
var _mini_map_camera: Camera2D
var _world_map_panel: Control
var _is_world_map_open := false


func _ready() -> void:
	_setup_mini_map_ui()
	set_process_input(true)


func _process(_delta: float) -> void:
	if current_mode == MapMode.MINI_MAP:
		_update_mini_map()
	_process_temporary_markers()


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("toggle_map"):
		toggle_world_map()
	elif event.is_action_pressed("set_waypoint") and _is_world_map_open:
		_handle_waypoint_click(event)


# ============================================================================
# UI SETUP
# ============================================================================

func _setup_mini_map_ui() -> void:
	# Create mini-map container
	_mini_map_container = Control.new()
	_mini_map_container.name = "MiniMapContainer"
	_mini_map_container.set_anchors_preset(Control.PRESET_TOP_RIGHT)
	_mini_map_container.position = Vector2(-mini_map_size.x - mini_map_position.x, mini_map_position.y)
	_mini_map_container.size = mini_map_size
	add_child(_mini_map_container)
	
	# Mini-map background
	var bg := ColorRect.new()
	bg.name = "Background"
	bg.size = mini_map_size
	bg.color = Color(0.1, 0.1, 0.15, 0.8)
	_mini_map_container.add_child(bg)
	
	# Border
	var border := Panel.new()
	border.name = "Border"
	border.size = mini_map_size
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0, 0, 0, 0)
	style.border_width_top = 2
	style.border_width_bottom = 2
	style.border_width_left = 2
	style.border_width_right = 2
	style.border_color = Color(0.3, 0.5, 0.7, 0.8)
	border.add_theme_stylebox_override("panel", style)
	_mini_map_container.add_child(border)
	
	# Create world map panel (hidden by default)
	_create_world_map_panel()


func _create_world_map_panel() -> void:
	_world_map_panel = Control.new()
	_world_map_panel.name = "WorldMapPanel"
	_world_map_panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	_world_map_panel.visible = false
	add_child(_world_map_panel)
	
	# Dark overlay
	var overlay := ColorRect.new()
	overlay.name = "Overlay"
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.color = Color(0, 0, 0, 0.85)
	_world_map_panel.add_child(overlay)
	
	# Map container
	var map_container := Control.new()
	map_container.name = "MapContainer"
	map_container.set_anchors_preset(Control.PRESET_CENTER)
	map_container.size = Vector2(800, 600)
	map_container.position = Vector2(-400, -300)
	_world_map_panel.add_child(map_container)
	
	# Map background
	var map_bg := ColorRect.new()
	map_bg.name = "MapBackground"
	map_bg.size = Vector2(800, 600)
	map_bg.color = Color(0.15, 0.15, 0.2, 1.0)
	map_container.add_child(map_bg)
	
	# Title
	var title := Label.new()
	title.name = "Title"
	title.text = "WORLD MAP"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.position = Vector2(0, 10)
	title.size = Vector2(800, 30)
	map_container.add_child(title)
	
	# Close hint
	var hint := Label.new()
	hint.name = "CloseHint"
	hint.text = "Press M or ESC to close"
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	hint.position = Vector2(0, 560)
	hint.size = Vector2(800, 30)
	hint.modulate = Color(0.6, 0.6, 0.6)
	map_container.add_child(hint)


# ============================================================================
# MINI-MAP RENDERING
# ============================================================================

func _update_mini_map() -> void:
	if not is_instance_valid(_mini_map_container):
		return
	
	# Clear old markers
	for child in _mini_map_container.get_children():
		if child.name.begins_with("Marker_"):
			child.queue_free()
	
	# Calculate visible area
	var view_radius := (mini_map_size.x / 2.0) / mini_map_zoom
	
	# Draw terrain (simplified representation)
	_draw_mini_map_terrain()
	
	# Draw fog of war edges
	_draw_fog_edges()
	
	# Draw markers in range
	for marker_id in _markers:
		var marker: Dictionary = _markers[marker_id]
		var marker_pos: Vector2 = marker.get("position", Vector2.ZERO)
		var dist := player_position.distance_to(marker_pos)
		
		if dist <= view_radius:
			_draw_marker_on_minimap(marker)
	
	# Draw waypoint direction
	if waypoint_position != Vector2.INF:
		_draw_waypoint_indicator()
	
	# Draw player indicator (always at center)
	_draw_player_indicator()


func _draw_mini_map_terrain() -> void:
	# Simplified terrain visualization
	# In full implementation, this would render actual tile data
	pass


func _draw_fog_edges() -> void:
	# Draw edges of explored areas
	pass


func _draw_marker_on_minimap(marker: Dictionary) -> void:
	var marker_pos: Vector2 = marker.get("position", Vector2.ZERO)
	var icon_type: int = marker.get("icon_type", IconType.POI_DISCOVERED)
	var visible: bool = marker.get("visible", true)
	
	if not visible:
		return
	
	# Calculate screen position relative to player
	var offset := marker_pos - player_position
	
	# Apply rotation if enabled
	if rotation_enabled:
		offset = offset.rotated(-player_rotation)
	
	# Scale to mini-map
	offset *= mini_map_zoom
	
	# Center of mini-map
	var center := mini_map_size / 2.0
	var screen_pos := center + offset
	
	# Clamp to mini-map bounds with edge margin
	var margin := 10.0
	screen_pos.x = clampf(screen_pos.x, margin, mini_map_size.x - margin)
	screen_pos.y = clampf(screen_pos.y, margin, mini_map_size.y - margin)
	
	# Create marker visual
	var marker_node := ColorRect.new()
	marker_node.name = "Marker_" + marker.get("id", "unknown")
	
	var size: float = ICON_SIZES.get(icon_type, 6.0)
	marker_node.size = Vector2(size, size)
	marker_node.position = screen_pos - Vector2(size / 2, size / 2)
	marker_node.color = ICON_COLORS.get(icon_type, Color.WHITE)
	
	_mini_map_container.add_child(marker_node)


func _draw_player_indicator() -> void:
	var center := mini_map_size / 2.0
	
	# Player triangle/arrow
	var player_marker := ColorRect.new()
	player_marker.name = "Marker_Player"
	var size := ICON_SIZES[IconType.PLAYER]
	player_marker.size = Vector2(size, size)
	player_marker.position = center - Vector2(size / 2, size / 2)
	player_marker.color = ICON_COLORS[IconType.PLAYER]
	
	_mini_map_container.add_child(player_marker)


func _draw_waypoint_indicator() -> void:
	if waypoint_position == Vector2.INF:
		return
	
	var direction := (waypoint_position - player_position).normalized()
	var distance := player_position.distance_to(waypoint_position)
	
	# If waypoint is off-screen, show arrow at edge
	var view_radius := (mini_map_size.x / 2.0) / mini_map_zoom
	
	if distance > view_radius:
		var center := mini_map_size / 2.0
		var edge_pos := center + direction * (mini_map_size.x / 2.0 - 15)
		
		var arrow := ColorRect.new()
		arrow.name = "Marker_WaypointArrow"
		arrow.size = Vector2(8, 8)
		arrow.position = edge_pos - Vector2(4, 4)
		arrow.color = ICON_COLORS[IconType.WAYPOINT]
		
		_mini_map_container.add_child(arrow)


# ============================================================================
# WORLD MAP
# ============================================================================

func toggle_world_map() -> void:
	_is_world_map_open = not _is_world_map_open
	
	if _is_world_map_open:
		_open_world_map()
	else:
		_close_world_map()


func _open_world_map() -> void:
	current_mode = MapMode.WORLD_MAP
	_world_map_panel.visible = true
	_mini_map_container.visible = false
	
	_render_world_map()
	
	# Pause game (optional)
	# get_tree().paused = true


func _close_world_map() -> void:
	current_mode = MapMode.MINI_MAP
	_world_map_panel.visible = false
	_mini_map_container.visible = true
	
	# Resume game
	# get_tree().paused = false


func _render_world_map() -> void:
	var map_container: Control = _world_map_panel.get_node_or_null("MapContainer")
	if not map_container:
		return
	
	# Clear old zone displays
	for child in map_container.get_children():
		if child.name.begins_with("Zone_") or child.name.begins_with("Connection_"):
			child.queue_free()
	
	# Draw zone connections first (behind zones)
	for zone_id in _zone_connections:
		var connections: Array = _zone_connections[zone_id]
		for connected_id in connections:
			if zone_id < connected_id:  # Avoid duplicate lines
				_draw_zone_connection(map_container, zone_id, connected_id)
	
	# Draw zones
	for zone_id in _zone_positions:
		_draw_zone_on_world_map(map_container, zone_id)
	
	# Draw player position
	_draw_player_on_world_map(map_container)
	
	# Draw waypoint
	if waypoint_position != Vector2.INF:
		_draw_waypoint_on_world_map(map_container)


func _draw_zone_on_world_map(container: Control, zone_id: String) -> void:
	var world_pos: Vector2 = _zone_positions.get(zone_id, Vector2.ZERO)
	var screen_pos := _world_to_map_position(world_pos, container)
	
	# Zone marker
	var zone_marker := ColorRect.new()
	zone_marker.name = "Zone_" + zone_id
	zone_marker.size = Vector2(40, 40)
	zone_marker.position = screen_pos - Vector2(20, 20)
	
	# Color based on difficulty
	var is_current := zone_id == current_zone_id
	var is_discovered := _is_zone_discovered(zone_id)
	
	if not is_discovered:
		zone_marker.color = Color(0.3, 0.3, 0.3, 0.5)
	elif is_current:
		zone_marker.color = Color(0.3, 0.6, 1.0, 0.9)
	else:
		zone_marker.color = Color(0.4, 0.5, 0.4, 0.8)
	
	container.add_child(zone_marker)
	
	# Zone name label
	if is_discovered:
		var label := Label.new()
		label.name = "Zone_Label_" + zone_id
		label.text = zone_id
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.position = screen_pos - Vector2(50, 35)
		label.size = Vector2(100, 20)
		label.add_theme_font_size_override("font_size", 12)
		container.add_child(label)


func _draw_zone_connection(container: Control, zone_a: String, zone_b: String) -> void:
	var pos_a: Vector2 = _zone_positions.get(zone_a, Vector2.ZERO)
	var pos_b: Vector2 = _zone_positions.get(zone_b, Vector2.ZERO)
	
	var screen_a := _world_to_map_position(pos_a, container)
	var screen_b := _world_to_map_position(pos_b, container)
	
	# Simple line representation using a stretched ColorRect
	var line := ColorRect.new()
	line.name = "Connection_%s_%s" % [zone_a, zone_b]
	
	var direction := (screen_b - screen_a).normalized()
	var length := screen_a.distance_to(screen_b)
	var angle := direction.angle()
	
	line.size = Vector2(length, 2)
	line.position = screen_a
	line.pivot_offset = Vector2(0, 1)
	line.rotation = angle
	line.color = Color(0.4, 0.4, 0.4, 0.6)
	
	container.add_child(line)


func _draw_player_on_world_map(container: Control) -> void:
	# Use current zone position for player
	var zone_pos: Vector2 = _zone_positions.get(current_zone_id, Vector2.ZERO)
	var screen_pos := _world_to_map_position(zone_pos, container)
	
	var player_marker := ColorRect.new()
	player_marker.name = "Zone_Player"
	player_marker.size = Vector2(16, 16)
	player_marker.position = screen_pos - Vector2(8, 8)
	player_marker.color = ICON_COLORS[IconType.PLAYER]
	
	container.add_child(player_marker)


func _draw_waypoint_on_world_map(container: Control) -> void:
	var screen_pos := _world_to_map_position(waypoint_position, container)
	
	var waypoint_marker := ColorRect.new()
	waypoint_marker.name = "Zone_Waypoint"
	waypoint_marker.size = Vector2(12, 12)
	waypoint_marker.position = screen_pos - Vector2(6, 6)
	waypoint_marker.color = ICON_COLORS[IconType.WAYPOINT]
	
	container.add_child(waypoint_marker)


func _world_to_map_position(world_pos: Vector2, container: Control) -> Vector2:
	var map_center := container.size / 2.0
	var scaled_pos := world_pos * world_map_scale
	return map_center + scaled_pos


func _map_to_world_position(map_pos: Vector2, container: Control) -> Vector2:
	var map_center := container.size / 2.0
	var offset := map_pos - map_center
	return offset / world_map_scale


# ============================================================================
# FOG OF WAR
# ============================================================================

func update_player_position(position: Vector2, rotation: float = 0.0) -> void:
	player_position = position
	player_rotation = rotation
	
	# Discover nearby area
	_discover_area(position)


func _discover_area(position: Vector2) -> void:
	if current_zone_id.is_empty():
		return
	
	# Initialize zone discovery if needed
	if current_zone_id not in _discovered_chunks:
		_discovered_chunks[current_zone_id] = {}
	
	var zone_chunks: Dictionary = _discovered_chunks[current_zone_id]
	
	# Calculate chunks in discovery radius
	var chunk_radius := int(discovery_radius / fog_chunk_size) + 1
	var center_chunk := Vector2i(
		int(position.x / fog_chunk_size),
		int(position.y / fog_chunk_size)
	)
	
	for y in range(-chunk_radius, chunk_radius + 1):
		for x in range(-chunk_radius, chunk_radius + 1):
			var chunk_pos := center_chunk + Vector2i(x, y)
			var chunk_center := Vector2(
				(chunk_pos.x + 0.5) * fog_chunk_size,
				(chunk_pos.y + 0.5) * fog_chunk_size
			)
			
			if position.distance_to(chunk_center) <= discovery_radius:
				if chunk_pos not in zone_chunks:
					zone_chunks[chunk_pos] = true
					emit_signal("area_discovered", chunk_center, current_zone_id)


func is_position_discovered(position: Vector2) -> bool:
	if current_zone_id.is_empty():
		return false
	
	var zone_chunks: Dictionary = _discovered_chunks.get(current_zone_id, {})
	var chunk_pos := Vector2i(
		int(position.x / fog_chunk_size),
		int(position.y / fog_chunk_size)
	)
	
	return chunk_pos in zone_chunks


func _is_zone_discovered(zone_id: String) -> bool:
	return zone_id in _discovered_chunks


func get_discovery_percentage(zone_id: String = "") -> float:
	var target_zone := zone_id if not zone_id.is_empty() else current_zone_id
	
	if target_zone.is_empty():
		return 0.0
	
	var zone_chunks: Dictionary = _discovered_chunks.get(target_zone, {})
	var total_chunks := (current_zone_size.x / fog_chunk_size) * (current_zone_size.y / fog_chunk_size)
	
	if total_chunks <= 0:
		return 0.0
	
	return float(zone_chunks.size()) / float(total_chunks) * 100.0


# ============================================================================
# MARKERS
# ============================================================================

func add_marker(marker_id: String, position: Vector2, icon_type: int, data: Dictionary = {}) -> void:
	_markers[marker_id] = {
		"id": marker_id,
		"position": position,
		"icon_type": icon_type,
		"visible": data.get("visible", true),
		"label": data.get("label", ""),
		"zone_id": data.get("zone_id", current_zone_id),
		"persistent": data.get("persistent", false),
	}


func remove_marker(marker_id: String) -> void:
	_markers.erase(marker_id)


func update_marker_position(marker_id: String, position: Vector2) -> void:
	if marker_id in _markers:
		_markers[marker_id]["position"] = position


func set_marker_visible(marker_id: String, visible: bool) -> void:
	if marker_id in _markers:
		_markers[marker_id]["visible"] = visible


func add_temporary_marker(position: Vector2, icon_type: int, duration: float) -> String:
	var marker_id := "temp_%d" % randi()
	
	add_marker(marker_id, position, icon_type)
	
	_temporary_markers.append({
		"id": marker_id,
		"expire_time": Time.get_ticks_msec() / 1000.0 + duration,
	})
	
	return marker_id


func _process_temporary_markers() -> void:
	var current_time := Time.get_ticks_msec() / 1000.0
	var expired: Array = []
	
	for temp in _temporary_markers:
		if current_time >= temp["expire_time"]:
			expired.append(temp)
			remove_marker(temp["id"])
	
	for temp in expired:
		_temporary_markers.erase(temp)


func clear_zone_markers() -> void:
	## Clear all non-persistent markers for current zone
	var to_remove: Array = []
	
	for marker_id in _markers:
		var marker: Dictionary = _markers[marker_id]
		if marker.get("zone_id", "") == current_zone_id and not marker.get("persistent", false):
			to_remove.append(marker_id)
	
	for marker_id in to_remove:
		_markers.erase(marker_id)


# ============================================================================
# WAYPOINTS
# ============================================================================

func set_waypoint(position: Vector2) -> void:
	waypoint_position = position
	emit_signal("waypoint_set", position)


func clear_waypoint() -> void:
	waypoint_position = Vector2.INF
	emit_signal("waypoint_cleared")


func get_waypoint_distance() -> float:
	if waypoint_position == Vector2.INF:
		return -1.0
	return player_position.distance_to(waypoint_position)


func get_waypoint_direction() -> Vector2:
	if waypoint_position == Vector2.INF:
		return Vector2.ZERO
	return (waypoint_position - player_position).normalized()


func _handle_waypoint_click(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT:
		var map_container: Control = _world_map_panel.get_node_or_null("MapContainer")
		if map_container:
			var local_pos := map_container.get_local_mouse_position()
			var world_pos := _map_to_world_position(local_pos, map_container)
			set_waypoint(world_pos)


# ============================================================================
# POI INTEGRATION
# ============================================================================

func register_poi(poi_id: String, position: Vector2, state: int) -> void:
	var icon_type := IconType.POI_UNDISCOVERED
	
	match state:
		0:  # UNDISCOVERED
			icon_type = IconType.POI_UNDISCOVERED
		1, 2:  # DISCOVERED, IN_PROGRESS
			icon_type = IconType.POI_DISCOVERED
		3:  # COMPLETED
			icon_type = IconType.POI_COMPLETED
	
	add_marker("poi_" + poi_id, position, icon_type, {
		"persistent": true,
		"label": poi_id,
	})
	
	emit_signal("poi_marked", poi_id, position)


func update_poi_state(poi_id: String, state: int) -> void:
	var marker_id := "poi_" + poi_id
	
	if marker_id in _markers:
		var icon_type := IconType.POI_DISCOVERED
		
		match state:
			0:
				icon_type = IconType.POI_UNDISCOVERED
			1, 2:
				icon_type = IconType.POI_DISCOVERED
			3:
				icon_type = IconType.POI_COMPLETED
		
		_markers[marker_id]["icon_type"] = icon_type


# ============================================================================
# RESOURCE/ENEMY INTEGRATION
# ============================================================================

func register_resource(resource_id: String, position: Vector2, category: int) -> void:
	if not show_resources_on_minimap:
		return
	
	var icon_type := IconType.RESOURCE_PLANT
	
	match category:
		0:  # TREE
			icon_type = IconType.RESOURCE_TREE
		1:  # ROCK
			icon_type = IconType.RESOURCE_ROCK
		2:  # ORE
			icon_type = IconType.RESOURCE_ORE
		_:
			icon_type = IconType.RESOURCE_PLANT
	
	add_marker("res_" + resource_id, position, icon_type)


func register_enemy(enemy_id: String, position: Vector2, is_hostile: bool = true) -> void:
	if not show_enemies_on_minimap:
		return
	
	var icon_type := IconType.ENEMY if is_hostile else IconType.NPC
	add_marker("enemy_" + enemy_id, position, icon_type)


func unregister_enemy(enemy_id: String) -> void:
	remove_marker("enemy_" + enemy_id)


func register_container(container_id: String, position: Vector2, is_looted: bool = false) -> void:
	var icon_type := IconType.CONTAINER_LOOTED if is_looted else IconType.CONTAINER
	add_marker("cont_" + container_id, position, icon_type)


func update_container_state(container_id: String, is_looted: bool) -> void:
	var marker_id := "cont_" + container_id
	if marker_id in _markers:
		_markers[marker_id]["icon_type"] = IconType.CONTAINER_LOOTED if is_looted else IconType.CONTAINER


# ============================================================================
# ZONE MANAGEMENT
# ============================================================================

func set_current_zone(zone_id: String, zone_size: Vector2i) -> void:
	current_zone_id = zone_id
	current_zone_size = zone_size
	
	# Register zone if not already
	if zone_id not in _zone_positions:
		_zone_positions[zone_id] = Vector2.ZERO


func register_zone(zone_id: String, world_position: Vector2, connections: Array = []) -> void:
	_zone_positions[zone_id] = world_position
	
	if connections.size() > 0:
		_zone_connections[zone_id] = connections


func get_zone_list() -> Array:
	return _zone_positions.keys()


# ============================================================================
# PERSISTENCE
# ============================================================================

func save_data() -> Dictionary:
	var persistent_markers := {}
	for marker_id in _markers:
		if _markers[marker_id].get("persistent", false):
			persistent_markers[marker_id] = _markers[marker_id].duplicate()
	
	return {
		"discovered_chunks": _discovered_chunks.duplicate(true),
		"zone_positions": _zone_positions.duplicate(),
		"zone_connections": _zone_connections.duplicate(true),
		"persistent_markers": persistent_markers,
		"waypoint": {"x": waypoint_position.x, "y": waypoint_position.y} if waypoint_position != Vector2.INF else null,
	}


func load_data(data: Dictionary) -> void:
	_discovered_chunks = data.get("discovered_chunks", {})
	_zone_positions = data.get("zone_positions", {})
	_zone_connections = data.get("zone_connections", {})
	
	var persistent_markers: Dictionary = data.get("persistent_markers", {})
	for marker_id in persistent_markers:
		_markers[marker_id] = persistent_markers[marker_id]
	
	var wp: Dictionary = data.get("waypoint", {})
	if wp.has("x"):
		waypoint_position = Vector2(wp["x"], wp["y"])
	else:
		waypoint_position = Vector2.INF


# ============================================================================
# SETTINGS
# ============================================================================

func set_minimap_zoom(zoom: float) -> void:
	mini_map_zoom = clampf(zoom, 0.25, 4.0)


func set_minimap_size(size: Vector2) -> void:
	mini_map_size = size
	if is_instance_valid(_mini_map_container):
		_mini_map_container.size = size


func toggle_resource_icons(enabled: bool) -> void:
	show_resources_on_minimap = enabled


func toggle_enemy_icons(enabled: bool) -> void:
	show_enemies_on_minimap = enabled


func toggle_rotation(enabled: bool) -> void:
	rotation_enabled = enabled
