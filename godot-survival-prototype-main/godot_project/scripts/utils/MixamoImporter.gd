@tool
extends EditorScript
class_name MixamoImporter
## Utility to process Mixamo FBX files for Godot integration
##
## USAGE:
## 1. Download characters and animations from Mixamo (https://mixamo.com)
##    - For characters: Download as FBX with "T-Pose" and "With Skin"
##    - For animations: Download as FBX "Without Skin" (saves file size)
## 2. Place FBX files in the mixamo folder (characters/ and animations/ subdirs)
## 3. Run this script from the editor (Script > Run)
##
## The script will:
## - Convert to Godot-compatible scenes
## - Extract animations as reusable AnimationLibrary
## - Create character variants ready for Player3D

const MIXAMO_BASE_DIR := "res://assets/mixamo/"
const MIXAMO_RAW_DIR := "res://assets/mixamo/raw/"
const MIXAMO_CHAR_DIR := "res://assets/mixamo/characters/"
const ANIMATION_LIB_DIR := "res://assets/mixamo/animations/"

# Standard survival game animations to look for
const EXPECTED_ANIMATIONS := [
	"idle",
	"walk",
	"run", 
	"sprint",
	"jump",
	"attack_melee",
	"attack_swing",
	"attack_stab",
	"hit_react",
	"death",
	"crouch_idle",
	"crouch_walk",
	"pickup",
	"interact",
	"walk_forward",
	"walk_back",
	"walk_left",
	"walk_right",
	"run_forward",
	"run_back",
	"run_left",
	"run_right",
	"turn_left",
	"turn_right"
]


func _run() -> void:
	print("=== Mixamo Importer ===")
	_ensure_directories()
	_process_all_directories()
	print("=== Import Complete ===")


func _ensure_directories() -> void:
	for dir_path in [MIXAMO_RAW_DIR, MIXAMO_CHAR_DIR, ANIMATION_LIB_DIR]:
		var dir = DirAccess.open("res://")
		var relative_path = dir_path.replace("res://", "")
		if not dir.dir_exists(relative_path):
			dir.make_dir_recursive(relative_path)
			print("Created directory: ", dir_path)


func _process_all_directories() -> void:
	# Process all directories that may contain FBX files
	var dirs_to_scan := [MIXAMO_RAW_DIR, MIXAMO_CHAR_DIR, ANIMATION_LIB_DIR]
	var total_processed := 0
	
	for scan_dir in dirs_to_scan:
		var dir := DirAccess.open(scan_dir)
		if not dir:
			continue
		
		dir.list_dir_begin()
		var file_name := dir.get_next()
		
		while file_name != "":
			if file_name.to_lower().ends_with(".fbx"):
				_process_fbx(scan_dir + file_name)
				total_processed += 1
			file_name = dir.get_next()
		
		dir.list_dir_end()
	
	print("Processed ", total_processed, " FBX files")


func _process_fbx(fbx_path: String) -> void:
	print("Processing: ", fbx_path)
	
	# Load the FBX as a PackedScene
	var scene := ResourceLoader.load(fbx_path) as PackedScene
	if not scene:
		push_error("Failed to load: " + fbx_path)
		return
	
	var instance := scene.instantiate()
	var file_name := fbx_path.get_file().get_basename()
	
	# Determine if this is a character or just an animation
	var has_mesh := _find_mesh_instance(instance) != null
	var animation_player := _find_animation_player(instance)
	
	if has_mesh:
		# This is a character with skin - save as character scene
		_save_character(instance, file_name)
	
	if animation_player and animation_player.has_animation_library(""):
		# Extract animations to shared library
		_extract_animations(animation_player, file_name)
	
	instance.queue_free()


func _find_mesh_instance(node: Node) -> MeshInstance3D:
	if node is MeshInstance3D:
		return node
	for child in node.get_children():
		var result = _find_mesh_instance(child)
		if result:
			return result
	return null


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result = _find_animation_player(child)
		if result:
			return result
	return null


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result = _find_skeleton(child)
		if result:
			return result
	return null


func _save_character(root: Node, name: String) -> void:
	var output_path := MIXAMO_CHAR_DIR + name + ".tscn"
	
	# Clean up the node name
	root.name = name
	
	# Find and configure skeleton
	var skeleton := _find_skeleton(root)
	if skeleton:
		print("  Found skeleton with ", skeleton.get_bone_count(), " bones")
	
	# Pack and save
	var packed := PackedScene.new()
	packed.pack(root)
	
	var err := ResourceSaver.save(packed, output_path)
	if err == OK:
		print("  Saved character: ", output_path)
	else:
		push_error("  Failed to save character: " + str(err))


func _extract_animations(anim_player: AnimationPlayer, source_name: String) -> void:
	# Get or create the master animation library
	var lib_path := ANIMATION_LIB_DIR + "mixamo_animations.tres"
	var library: AnimationLibrary
	
	if ResourceLoader.exists(lib_path):
		library = ResourceLoader.load(lib_path) as AnimationLibrary
	else:
		library = AnimationLibrary.new()
	
	# Get animations from the source
	var source_lib := anim_player.get_animation_library("")
	if not source_lib:
		return
	
	for anim_name in source_lib.get_animation_list():
		var animation := source_lib.get_animation(anim_name)
		if animation:
			# Clean up animation name (Mixamo uses long names)
			var clean_name := _clean_animation_name(anim_name, source_name)
			
			# Clone and add to library
			var anim_copy := animation.duplicate(true)
			
			# Fix track paths for Godot's expected structure
			_fix_animation_tracks(anim_copy)
			
			library.add_animation(clean_name, anim_copy)
			print("  Extracted animation: ", clean_name)
	
	# Save the library
	var err := ResourceSaver.save(library, lib_path)
	if err == OK:
		print("  Updated animation library: ", lib_path)


func _clean_animation_name(raw_name: String, source: String) -> String:
	# Mixamo names are like "mixamo.com|Layer0" - clean them up
	var clean := raw_name.to_lower()
	clean = clean.replace("mixamo.com|", "")
	clean = clean.replace("mixamorig:", "")
	
	# Try to match to expected animation names
	for expected in EXPECTED_ANIMATIONS:
		if expected in source.to_lower() or expected in clean:
			return expected
	
	# Use source filename as base if no match
	return source.to_lower().replace(" ", "_")


func _fix_animation_tracks(animation: Animation) -> void:
	# Mixamo uses specific bone naming - convert to Godot-friendly paths
	for i in range(animation.get_track_count()):
		var track_path := animation.track_get_path(i)
		var path_str := str(track_path)
		
		# Mixamo skeleton naming: mixamorig:Hips -> Hips
		path_str = path_str.replace("mixamorig:", "")
		
		# Update the track path
		animation.track_set_path(i, NodePath(path_str))


## Static utility to get animation library for use in player scripts
static func get_animation_library() -> AnimationLibrary:
	var lib_path := "res://assets/mixamo/animations/mixamo_animations.tres"
	if ResourceLoader.exists(lib_path):
		return ResourceLoader.load(lib_path) as AnimationLibrary
	return null


## Static utility to list available characters
static func get_character_scenes() -> Array[String]:
	var result: Array[String] = []
	var char_dir := "res://assets/mixamo/characters/"
	var dir := DirAccess.open(char_dir)
	if dir:
		dir.list_dir_begin()
		var file_name := dir.get_next()
		while file_name != "":
			if file_name.ends_with(".tscn"):
				result.append(char_dir + file_name)
			file_name = dir.get_next()
		dir.list_dir_end()
	return result
