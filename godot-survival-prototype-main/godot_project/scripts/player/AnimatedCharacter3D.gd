extends Node3D
class_name AnimatedCharacter3D
## Wrapper for rigged characters with animation support
## Works with Mixamo FBX imports directly - no preprocessing needed

signal animation_changed(animation_name: String)
signal footstep

@export var character_scene: PackedScene
## Optional: Additional animation FBX files to load
@export var animation_scenes: Array[PackedScene] = []

# Movement thresholds
@export var walk_speed_threshold := 0.1
@export var run_speed_threshold := 4.0
@export var sprint_speed_threshold := 7.0

var skeleton: Skeleton3D
var mesh_instances: Array[MeshInstance3D] = []
var animation_player: AnimationPlayer
var current_state := "idle"
var current_speed := 0.0
var is_action_playing := false

# Animation name mapping (game action -> possible Mixamo names)
var anim_map := {
	"idle": ["Idle", "idle", "standing idle 01", "breathing_idle", "Standing Idle"],
	"walk": ["Walking", "walk", "standing walk forward", "Walk"],
	"run": ["Running", "run", "standing run forward", "Run", "jog", "Jogging"],
	"attack": ["Stable Sword Inward Slash", "Sword Slash", "attack", "slash", "punch", "Punching"],
	"hit": ["Hit Reaction", "hit", "take_damage", "hurt"],
	"death": ["Dying", "death", "Dead", "die"],
}


func _ready() -> void:
	if character_scene:
		call_deferred("_deferred_load")


func _deferred_load() -> void:
	load_character(character_scene)


func load_character(scene: PackedScene) -> void:
	if not scene:
		push_error("AnimatedCharacter3D: No character scene provided")
		return
	
	# Clear existing children
	for child in get_children():
		child.queue_free()
	
	# Instantiate character
	var character := scene.instantiate()
	if not character:
		push_error("AnimatedCharacter3D: Failed to instantiate character scene")
		return
	
	add_child(character)
	
	# Find components
	skeleton = _find_skeleton(character)
	mesh_instances = _find_mesh_instances(character)
	animation_player = _find_animation_player(character)
	
	# Load additional animation files and merge them
	for anim_scene in animation_scenes:
		_import_animations_from_scene(anim_scene)
	
	# Start with idle if available
	if animation_player:
		var idle_anim := _find_animation("idle")
		if idle_anim:
			animation_player.play(idle_anim)
		print("AnimatedCharacter3D: ", animation_player.get_animation_list())
	
	print("AnimatedCharacter3D loaded: meshes=", mesh_instances.size(), " skeleton=", skeleton != null)


func _import_animations_from_scene(scene: PackedScene) -> void:
	if not animation_player or not scene:
		return
	
	var temp := scene.instantiate()
	var temp_anim_player := _find_animation_player(temp)
	
	if temp_anim_player:
		for anim_name in temp_anim_player.get_animation_list():
			if not animation_player.has_animation(anim_name):
				var anim := temp_anim_player.get_animation(anim_name)
				if anim:
					# Get or create default library
					if not animation_player.has_animation_library(""):
						animation_player.add_animation_library("", AnimationLibrary.new())
					var lib := animation_player.get_animation_library("")
					if lib:
						lib.add_animation(anim_name, anim.duplicate())
						print("  Imported animation: ", anim_name)
	
	temp.queue_free()


func _find_skeleton(node: Node) -> Skeleton3D:
	if node is Skeleton3D:
		return node
	for child in node.get_children():
		var result := _find_skeleton(child)
		if result:
			return result
	return null


func _find_mesh_instances(node: Node, results: Array[MeshInstance3D] = []) -> Array[MeshInstance3D]:
	if node is MeshInstance3D:
		results.append(node)
	for child in node.get_children():
		_find_mesh_instances(child, results)
	return results


func _find_animation_player(node: Node) -> AnimationPlayer:
	if node is AnimationPlayer:
		return node
	for child in node.get_children():
		var result := _find_animation_player(child)
		if result:
			return result
	return null


## Find an animation by checking our mapping
func _find_animation(action: String) -> String:
	if not animation_player:
		return ""
	
	var available := animation_player.get_animation_list()
	
	# Check mapped names
	if action in anim_map:
		for possible_name in anim_map[action]:
			for anim in available:
				if anim.to_lower().contains(possible_name.to_lower()):
					return anim
	
	# Direct match
	for anim in available:
		if anim.to_lower() == action.to_lower():
			return anim
	
	return ""


func _play_mapped_animation(action: String, blend: float = 0.2) -> bool:
	var anim_name := _find_animation(action)
	if anim_name and animation_player:
		animation_player.play(anim_name, blend)
		return true
	return false


## Call this each frame with current velocity
func update_movement(velocity: Vector3) -> void:
	if is_action_playing:
		return
	
	current_speed = Vector2(velocity.x, velocity.z).length()
	
	# Determine state based on speed
	var new_state := "idle"
	if current_speed > run_speed_threshold:
		new_state = "run"
	elif current_speed > walk_speed_threshold:
		new_state = "walk"
	
	if new_state != current_state:
		current_state = new_state
		_play_mapped_animation(current_state)
		animation_changed.emit(current_state)


## Play attack animation
func play_attack() -> void:
	if is_action_playing:
		return
	
	if _play_mapped_animation("attack", 0.1):
		is_action_playing = true
		# Connect to animation finished to reset
		if animation_player and not animation_player.animation_finished.is_connected(_on_action_finished):
			animation_player.animation_finished.connect(_on_action_finished, CONNECT_ONE_SHOT)


## Play hit reaction
func play_hit() -> void:
	if _play_mapped_animation("hit", 0.05):
		is_action_playing = true
		if animation_player and not animation_player.animation_finished.is_connected(_on_action_finished):
			animation_player.animation_finished.connect(_on_action_finished, CONNECT_ONE_SHOT)


## Play death animation
func play_death() -> void:
	_play_mapped_animation("death", 0.1)
	is_action_playing = true  # Don't return to movement after death


func play_pickup() -> void:
	# Use attack as fallback for now
	play_attack()


func _on_action_finished(_anim_name: String) -> void:
	is_action_playing = false
	# Return to movement state
	_play_mapped_animation(current_state)


## Rotate character to face direction (Y rotation only)
func face_direction(direction: Vector3, delta: float, speed: float = 10.0) -> void:
	if direction.length_squared() < 0.01:
		return
	
	var target_rotation := atan2(direction.x, direction.z)
	rotation.y = lerp_angle(rotation.y, target_rotation, delta * speed)


## Get the skeleton for attachment points (weapons, etc)
func get_skeleton() -> Skeleton3D:
	return skeleton


## Get bone position for attachments
func get_bone_global_position(bone_name: String) -> Vector3:
	if skeleton:
		var bone_idx := skeleton.find_bone(bone_name)
		if bone_idx >= 0:
			return skeleton.global_transform * skeleton.get_bone_global_pose(bone_idx).origin
	return global_position


## Attach a node to a bone (for weapons, equipment)
func attach_to_bone(node: Node3D, bone_name: String) -> void:
	if skeleton:
		var attachment := BoneAttachment3D.new()
		attachment.bone_name = bone_name
		skeleton.add_child(attachment)
		attachment.add_child(node)


## List all available animations (for debugging)
func get_available_animations() -> PackedStringArray:
	if animation_player:
		return animation_player.get_animation_list()
	return PackedStringArray()
