extends Node3D
## PlayableLoop - Minimal playable loop test scene
## Player moves, attacks zombie, picks up loot

const PLAYER_SCENE := preload("res://scenes/Player3D.tscn")
const ZOMBIE_SCENE := preload("res://scenes/enemies/Zombie.tscn")
const LOOT_SCENE := preload("res://scenes/resources/LootDrop.tscn")

var player: CharacterBody3D
var zombie: CharacterBody3D


func _ready() -> void:
	print("=== PLAYABLE LOOP TEST ===")
	print("Controls:")
	print("  WASD - Move")
	print("  Mouse - Look")
	print("  Left Click - Attack")
	print("  Spacebar - Dodge")
	print("  Escape - Toggle mouse capture")
	print("==========================")
	
	# Spawn player
	_spawn_player()
	
	# Spawn zombie
	_spawn_zombie()
	
	print("[PlayableLoop] Ready!")


func _spawn_player() -> void:
	player = PLAYER_SCENE.instantiate()
	$Entities.add_child(player)
	player.global_position = Vector3(0, 0.5, 0)
	
	# Connect signals
	player.died.connect(_on_player_died)
	
	print("[PlayableLoop] Player spawned")


func _spawn_zombie() -> void:
	zombie = ZOMBIE_SCENE.instantiate()
	$Entities.add_child(zombie)
	zombie.global_position = Vector3(5, 0.5, 5)
	
	# Connect death signal
	zombie.died.connect(_on_zombie_died)
	
	print("[PlayableLoop] Zombie spawned at ", zombie.global_position)


func _on_zombie_died(dead_zombie: CharacterBody3D) -> void:
	print("[PlayableLoop] Zombie killed!")
	
	# Spawn loot at death position
	var loot: Area3D = LOOT_SCENE.instantiate()
	loot.item_id = "scrap"
	loot.quantity = 3
	$Entities.add_child(loot)
	loot.global_position = dead_zombie.global_position + Vector3(0, 0.3, 0)
	
	# Connect loot signal
	loot.picked_up.connect(_on_loot_picked_up)
	
	print("[PlayableLoop] Loot spawned!")


func _on_loot_picked_up(item_id: String, quantity: int) -> void:
	print("[PlayableLoop] VICTORY! Collected: ", item_id, " x", quantity)
	print("[PlayableLoop] Minimal playable loop complete!")
	
	# Show win message
	$UILayer/WinLabel.visible = true


func _on_player_died() -> void:
	print("[PlayableLoop] Player died - Game Over")
	$UILayer/GameOverLabel.visible = true


func _input(event: InputEvent) -> void:
	# Restart on R
	if event is InputEventKey and event.pressed and event.keycode == KEY_R:
		get_tree().reload_current_scene()
