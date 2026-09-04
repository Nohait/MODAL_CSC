extends Node
## ModelManager autoload - Loads and manages all 3D game models
## Generated assets are stored in res://assets/models/

# Static instance for singleton access (set by autoload)
static var instance: Node = null

# Signals
signal models_loaded
signal model_load_progress(current: int, total: int)
signal category_loaded(category: String)

# Model categories
enum ModelCategory {
	ENVIRONMENT,
	PROPS,
	CHARACTERS,
	ENEMIES,
	ANIMALS,
	WEAPONS,
	ARMOR,
	BUILDINGS,
	VEHICLES
}

# Model storage
var _loaded_models: Dictionary = {}
var _is_loaded: bool = false
var _loading_thread: Thread

# Asset paths
const MODELS_PATH := "res://assets/models/"
const MANIFEST_PATH := "res://assets/models/manifest.json"

# Category folder names
const CATEGORY_FOLDERS := {
	ModelCategory.ENVIRONMENT: "environment",
	ModelCategory.PROPS: "props",
	ModelCategory.CHARACTERS: "characters",
	ModelCategory.ENEMIES: "enemies",
	ModelCategory.ANIMALS: "animals",
	ModelCategory.WEAPONS: "weapons",
	ModelCategory.ARMOR: "armor",
	ModelCategory.BUILDINGS: "buildings",
	ModelCategory.VEHICLES: "vehicles"
}


func _ready() -> void:
	instance = self
	# Start loading models in background
	_loading_thread = Thread.new()
	_loading_thread.start(_load_all_models)


func _exit_tree() -> void:
	if _loading_thread and _loading_thread.is_started():
		_loading_thread.wait_to_finish()


# ============================================================================
# STATIC API (for global access)
# ============================================================================

static func is_loaded() -> bool:
	return instance != null and instance._is_loaded

static func get_model(model_name: String) -> Mesh:
	if instance:
		return instance._get_model(model_name)
	return null

static func create_mesh_instance(model_name: String) -> MeshInstance3D:
	if instance:
		return instance._create_mesh_instance(model_name)
	return null

static func get_category_models(category: ModelCategory) -> Dictionary:
	if instance:
		return instance._get_category_models(category)
	return {}


# ============================================================================
# INSTANCE METHODS
# ============================================================================

## Get a model mesh by name
func _get_model(model_name: String) -> Mesh:
	# Check flat lookup first
	if _loaded_models.has(model_name):
		var val: Variant = _loaded_models[model_name]
		if val is Mesh:
			return val
	
	# Search in categories
	for category: String in _loaded_models:
		if typeof(_loaded_models[category]) == TYPE_DICTIONARY:
			if _loaded_models[category].has(model_name):
				return _loaded_models[category][model_name]
	
	push_warning("Model not found: " + model_name)
	return null


## Get a model from a specific category
func get_model_from_category(category: ModelCategory, model_name: String) -> Mesh:
	var folder: String = CATEGORY_FOLDERS.get(category, "")
	if folder.is_empty():
		return null
	
	if _loaded_models.has(folder):
		if _loaded_models[folder].has(model_name):
			return _loaded_models[folder][model_name]
	
	return null


## Get all models in a category
func _get_category_models(category: ModelCategory) -> Dictionary:
	var folder: String = CATEGORY_FOLDERS.get(category, "")
	if folder.is_empty():
		return {}
	
	return _loaded_models.get(folder, {})


## Instantiate a 3D mesh as a MeshInstance3D
func _create_mesh_instance(model_name: String) -> MeshInstance3D:
	var mesh := _get_model(model_name)
	if mesh == null:
		return null
	
	var mesh_inst := MeshInstance3D.new()
	mesh_inst.mesh = mesh
	mesh_inst.name = model_name
	return mesh_inst


## Instantiate a complete model with collision shape
func create_static_body(model_name: String) -> StaticBody3D:
	var mesh := _get_model(model_name)
	if mesh == null:
		return null
	
	var body := StaticBody3D.new()
	body.name = model_name
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	
	# Create collision shape from mesh
	var collision := CollisionShape3D.new()
	collision.shape = mesh.create_convex_shape()
	body.add_child(collision)
	
	return body


## Create a character body with the given mesh
func create_character_body(model_name: String) -> CharacterBody3D:
	var mesh := get_model(model_name)
	if mesh == null:
		return null
	
	var body := CharacterBody3D.new()
	body.name = model_name
	
	var mesh_instance := MeshInstance3D.new()
	mesh_instance.mesh = mesh
	body.add_child(mesh_instance)
	
	# Create capsule collision (better for characters)
	var collision := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius = 0.4
	capsule.height = 1.8
	collision.shape = capsule
	collision.position.y = 0.9
	body.add_child(collision)
	
	return body


## Get list of all model names
func get_all_model_names() -> Array[String]:
	var names: Array[String] = []
	for category in _loaded_models:
		if typeof(_loaded_models[category]) == TYPE_DICTIONARY:
			for name in _loaded_models[category]:
				names.append(name)
	return names


## Get models matching a pattern
func find_models(pattern: String) -> Array[String]:
	var matches: Array[String] = []
	var regex := RegEx.new()
	regex.compile(pattern)
	
	for name in get_all_model_names():
		if regex.search(name):
			matches.append(name)
	
	return matches


# ============================================================================
# LOADING SYSTEM
# ============================================================================

func _load_all_models() -> void:
	print("[ModelManager] Loading 3D models...")
	
	var start_time := Time.get_ticks_msec()
	var total_loaded := 0
	
	# Try to load from manifest first
	if FileAccess.file_exists(MANIFEST_PATH):
		_load_from_manifest()
	else:
		# Scan directory structure
		_scan_model_directories()
	
	for category in _loaded_models:
		if typeof(_loaded_models[category]) == TYPE_DICTIONARY:
			total_loaded += _loaded_models[category].size()
	
	var elapsed := (Time.get_ticks_msec() - start_time) / 1000.0
	print("[ModelManager] Loaded %d models in %.2f seconds" % [total_loaded, elapsed])
	
	_is_loaded = true
	call_deferred("emit_signal", "models_loaded")


func _load_from_manifest() -> void:
	var file := FileAccess.open(MANIFEST_PATH, FileAccess.READ)
	if file == null:
		push_error("Failed to open manifest: " + MANIFEST_PATH)
		return
	
	var json_text := file.get_as_text()
	file.close()
	
	var json := JSON.new()
	var error := json.parse(json_text)
	if error != OK:
		push_error("Failed to parse manifest JSON")
		return
	
	var manifest: Dictionary = json.data
	
	if not manifest.has("categories"):
		return
	
	var categories: Dictionary = manifest["categories"]
	var total_models := 0
	
	for category in categories:
		total_models += categories[category].size()
	
	var current := 0
	
	for category in categories:
		_loaded_models[category] = {}
		
		for model_info in categories[category]:
			var model_name: String = model_info["name"]
			var model_file: String = model_info["file"]
			var model_path := MODELS_PATH + model_file
			
			var mesh := _load_glb_mesh(model_path)
			if mesh:
				_loaded_models[category][model_name] = mesh
			
			current += 1
			call_deferred("emit_signal", "model_load_progress", current, total_models)
		
		call_deferred("emit_signal", "category_loaded", category)


func _scan_model_directories() -> void:
	var dir := DirAccess.open(MODELS_PATH)
	if dir == null:
		push_warning("Models directory not found: " + MODELS_PATH)
		return
	
	dir.list_dir_begin()
	var category_name := dir.get_next()
	
	while category_name != "":
		if dir.current_is_dir() and not category_name.begins_with("."):
			_load_category_directory(category_name)
		category_name = dir.get_next()
	
	dir.list_dir_end()


func _load_category_directory(category_name: String) -> void:
	var category_path := MODELS_PATH + category_name + "/"
	var dir := DirAccess.open(category_path)
	
	if dir == null:
		return
	
	_loaded_models[category_name] = {}
	
	dir.list_dir_begin()
	var file_name := dir.get_next()
	
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".glb"):
			var model_name := file_name.get_basename()
			var model_path := category_path + file_name
			
			var mesh := _load_glb_mesh(model_path)
			if mesh:
				_loaded_models[category_name][model_name] = mesh
		
		file_name = dir.get_next()
	
	dir.list_dir_end()
	call_deferred("emit_signal", "category_loaded", category_name)


func _load_glb_mesh(path: String) -> Mesh:
	if not FileAccess.file_exists(path):
		return null
	
	var gltf_doc := GLTFDocument.new()
	var gltf_state := GLTFState.new()
	
	var error := gltf_doc.append_from_file(path, gltf_state)
	if error != OK:
		push_warning("Failed to load GLB: " + path)
		return null
	
	var scene := gltf_doc.generate_scene(gltf_state)
	if scene == null:
		return null
	
	# Extract mesh from scene
	var mesh := _find_mesh_in_node(scene)
	
	# Clean up scene
	scene.queue_free()
	
	return mesh


func _find_mesh_in_node(node: Node) -> Mesh:
	if node is MeshInstance3D:
		return node.mesh
	
	for child in node.get_children():
		var mesh := _find_mesh_in_node(child)
		if mesh:
			return mesh
	
	return null


# ============================================================================
# MATERIAL OVERRIDES
# ============================================================================

## Apply a material override to a model instance
func apply_material(instance: MeshInstance3D, material: Material, surface_idx: int = -1) -> void:
	if surface_idx < 0:
		# Apply to all surfaces
		for i in range(instance.get_surface_override_material_count()):
			instance.set_surface_override_material(i, material)
	else:
		instance.set_surface_override_material(surface_idx, material)


## Create a StandardMaterial3D with common settings
func create_material(albedo_color: Color, roughness: float = 0.7, metallic: float = 0.0) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo_color
	mat.roughness = roughness
	mat.metallic = metallic
	return mat


## Get zone-specific material variants
func get_zone_material(base_material: Material, zone_type: String) -> Material:
	var mat := base_material.duplicate() as StandardMaterial3D
	if mat == null:
		return base_material
	
	match zone_type:
		"green":
			mat.albedo_color = mat.albedo_color.lerp(Color(0.3, 0.6, 0.3), 0.3)
		"yellow":
			mat.albedo_color = mat.albedo_color.lerp(Color(0.7, 0.6, 0.3), 0.3)
		"red":
			mat.albedo_color = mat.albedo_color.lerp(Color(0.6, 0.3, 0.3), 0.3)
			mat.roughness = min(mat.roughness + 0.1, 1.0)
	
	return mat


# ============================================================================
# PREFAB SYSTEM
# ============================================================================

## Create a resource node (tree, rock, etc.) with proper gameplay components
func create_resource_node(model_name: String, resource_type: String) -> Node3D:
	var root := Node3D.new()
	root.name = model_name
	
	# Add mesh
	var mesh_instance := create_mesh_instance(model_name)
	if mesh_instance:
		root.add_child(mesh_instance)
	
	# Add collision
	var collision_body := StaticBody3D.new()
	collision_body.name = "CollisionBody"
	
	var collision_shape := CollisionShape3D.new()
	if mesh_instance and mesh_instance.mesh:
		collision_shape.shape = mesh_instance.mesh.create_convex_shape()
	else:
		var box := BoxShape3D.new()
		box.size = Vector3(1, 1, 1)
		collision_shape.shape = box
	
	collision_body.add_child(collision_shape)
	root.add_child(collision_body)
	
	# Add resource script based on type
	match resource_type:
		"tree":
			if ResourceLoader.exists("res://scripts/resources/TreeNode.gd"):
				var script := load("res://scripts/resources/TreeNode.gd")
				root.set_script(script)
		"rock":
			if ResourceLoader.exists("res://scripts/resources/RockNode.gd"):
				var script := load("res://scripts/resources/RockNode.gd")
				root.set_script(script)
		"plant":
			if ResourceLoader.exists("res://scripts/resources/PlantNode.gd"):
				var script := load("res://scripts/resources/PlantNode.gd")
				root.set_script(script)
	
	return root


## Create an enemy with proper components
func create_enemy(model_name: String, _enemy_type: String = "zombie") -> CharacterBody3D:
	var body := create_character_body(model_name)
	if body == null:
		body = CharacterBody3D.new()
		body.name = model_name
	
	# Add enemy script
	if ResourceLoader.exists("res://scripts/enemies/Enemy.gd"):
		var script := load("res://scripts/enemies/Enemy.gd")
		body.set_script(script)
	
	return body


## Create a weapon pickup
func create_weapon_pickup(model_name: String, weapon_id: String) -> Area3D:
	var area := Area3D.new()
	area.name = model_name
	
	# Add mesh
	var mesh_instance := create_mesh_instance(model_name)
	if mesh_instance:
		area.add_child(mesh_instance)
	
	# Add collision for pickup detection
	var collision := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.5
	collision.shape = sphere
	area.add_child(collision)
	
	# Add loot item script
	if ResourceLoader.exists("res://scripts/resources/LootItem.gd"):
		var script := load("res://scripts/resources/LootItem.gd")
		area.set_script(script)
		area.set("item_id", weapon_id)
	
	return area


## Create a vehicle with proper components
func create_vehicle(model_name: String, vehicle_type: String = "car") -> VehicleBody3D:
	var mesh := get_model(model_name)
	
	var body := VehicleBody3D.new()
	body.name = model_name
	body.mass = 1500.0 if vehicle_type != "motorcycle" else 300.0
	
	if mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		body.add_child(mesh_instance)
	
	# Add collision shape
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	
	match vehicle_type:
		"car":
			box.size = Vector3(2.5, 0.8, 1.2)
		"truck":
			box.size = Vector3(3.5, 1.2, 1.4)
		"motorcycle":
			box.size = Vector3(1.8, 0.6, 0.4)
		"atv":
			box.size = Vector3(1.5, 0.6, 1.0)
		_:
			box.size = Vector3(2.0, 0.8, 1.2)
	
	collision.shape = box
	collision.position.y = box.size.y / 2 + 0.3
	body.add_child(collision)
	
	return body


## Create a building component (wall, floor, etc.)
func create_building_piece(model_name: String, piece_type: String = "wall") -> StaticBody3D:
	var mesh := get_model(model_name)
	
	var body := StaticBody3D.new()
	body.name = model_name
	
	if mesh:
		var mesh_instance := MeshInstance3D.new()
		mesh_instance.mesh = mesh
		body.add_child(mesh_instance)
	
	# Add collision shape
	var collision := CollisionShape3D.new()
	var box := BoxShape3D.new()
	
	match piece_type:
		"wall":
			box.size = Vector3(2.0, 2.0, 0.15)
		"floor":
			box.size = Vector3(2.0, 0.1, 2.0)
		"door":
			box.size = Vector3(1.0, 2.0, 0.1)
		"window":
			box.size = Vector3(0.8, 0.8, 0.1)
		_:
			box.size = Vector3(1.0, 1.0, 1.0)
	
	collision.shape = box
	collision.position.y = box.size.y / 2
	body.add_child(collision)
	
	return body
