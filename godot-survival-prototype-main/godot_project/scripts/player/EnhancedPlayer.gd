extends CharacterBody2D

## EnhancedPlayer - Full player controller with survival mechanics, equipment, and progression integration
## Addresses LDOE complaints: better mechanics, rewarding progression, meaningful combat

class_name EnhancedPlayer

# ============================================================================
# SIGNALS
# ============================================================================

signal movement_started(velocity: Vector2)
signal movement_stopped()
signal stats_updated(stats: Dictionary)
signal health_changed(current: float, maximum: float)
signal stamina_changed(current: float, maximum: float)
signal hunger_changed(current: float, maximum: float)
signal thirst_changed(current: float, maximum: float)
signal radiation_changed(current: float)
signal level_up(new_level: int)
signal xp_gained(amount: int)
signal item_picked_up(item_id: String, count: int)
signal equipment_changed(slot: String, item: Dictionary)
signal attacked(target: Node, damage: float)
signal took_damage(amount: float, source: Node)
signal died()
signal revived()
signal zone_entered(zone_name: String)
signal interacted(target: Node)

# ============================================================================
# CONSTANTS
# ============================================================================

# Movement
const BASE_SPEED := 220.0
const SPRINT_MULTIPLIER := 1.5
const CROUCH_MULTIPLIER := 0.5

# Survival stats
const STAT_MAX := 100.0
const HUNGER_DECAY_RATE := 0.5  # Per minute
const THIRST_DECAY_RATE := 0.8  # Per minute
const STAMINA_RECOVERY_RATE := 15.0
const STAMINA_SPRINT_DRAIN := 20.0
const HEALTH_REGEN_RATE := 1.0  # Per second when well-fed
const RADIATION_DECAY_RATE := 0.1  # Per second

# Combat
const BASE_MELEE_DAMAGE := 5.0
const BASE_ATTACK_COOLDOWN := 0.6
const INVINCIBILITY_DURATION := 0.5
const CRITICAL_HIT_MULTIPLIER := 2.0
const BASE_CRITICAL_CHANCE := 0.05

# Animation
const MOVEMENT_BLEND_NAME := "MovementBlend"
const BLEND_PATH := "parameters/%s/blend_position" % MOVEMENT_BLEND_NAME

# Input keys
const KEY_SPRINT := KEY_SHIFT
const KEY_CROUCH := KEY_CTRL
const KEY_INTERACT := KEY_E
const KEY_INVENTORY := KEY_TAB
const KEY_MAP := KEY_M

# ============================================================================
# EXPORTS
# ============================================================================

@export_group("Base Stats")
@export var base_health: float = 100.0
@export var base_stamina: float = 100.0
@export var base_hunger: float = 100.0
@export var base_thirst: float = 100.0

@export_group("Combat")
@export var base_melee_damage: float = 5.0
@export var attack_range: float = 48.0
@export var attack_cooldown: float = 0.6

@export_group("Movement")
@export var base_move_speed: float = 220.0

# ============================================================================
# STATE VARIABLES
# ============================================================================

# Survival stats
var health: float = 100.0
var max_health: float = 100.0
var stamina: float = 100.0
var max_stamina: float = 100.0
var hunger: float = 100.0
var max_hunger: float = 100.0
var thirst: float = 100.0
var max_thirst: float = 100.0
var radiation: float = 0.0

# Movement state
var is_sprinting: bool = false
var is_crouching: bool = false
var last_move_direction: Vector2 = Vector2.DOWN
var current_speed: float = BASE_SPEED

# Combat state
var attack_timer: float = 0.0
var invincibility_timer: float = 0.0
var is_attacking: bool = false
var current_weapon: Dictionary = {}
var combo_count: int = 0
var combo_timer: float = 0.0

# Equipment
var equipped_items: Dictionary = {
	"head": {},
	"torso": {},
	"legs": {},
	"feet": {},
	"hands": {},
	"weapon": {},
	"offhand": {}
}

# Progression (cached from ProgressionSystem)
var player_level: int = 1
var attributes: Dictionary = {
	"strength": 10,
	"agility": 10,
	"vitality": 10,
	"intelligence": 10,
	"luck": 10
}
var skill_bonuses: Dictionary = {}

# World state
var current_zone: String = "green"
var is_in_safe_zone: bool = false
var nearby_interactables: Array[Node] = []

# Status effects
var active_effects: Array[Dictionary] = []

# Misc
var player_name: String = "Survivor"
var is_dead: bool = false

# ============================================================================
# REFERENCES
# ============================================================================

@onready var sprite: Sprite2D = $Sprite2D if has_node("Sprite2D") else $Sprite
@onready var animation_tree: AnimationTree = $AnimationTree if has_node("AnimationTree") else null
@onready var animation_player: AnimationPlayer = $AnimationPlayer if has_node("AnimationPlayer") else null
@onready var camera: Camera2D = $Camera2D if has_node("Camera2D") else null
@onready var hurtbox: Area2D = $Hurtbox if has_node("Hurtbox") else null
@onready var interact_area: Area2D = $InteractArea if has_node("InteractArea") else null
@onready var hitbox_scene = preload("res://scenes/combat/Hitbox.tscn")

# System references (set in _ready)
var game_state: Node = null
var inventory: Node = null
var progression: Node = null
var quest_system: Node = null
var weapon_system: WeaponSystem = null
var weight_system: Node = null
var spoilage_system: Node = null

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready() -> void:
	add_to_group("player")
	
	_initialize_systems()
	_initialize_stats()
	_setup_camera()
	_setup_hurtbox()
	_setup_interact_area()
	_build_animation_tree()
	
	# Report initial stats
	_sync_all_stats()

func _initialize_systems() -> void:
	# Get global system references
	if has_node("/root/GameState"):
		game_state = get_node("/root/GameState")
	if has_node("/root/WeightSystem"):
		weight_system = get_node("/root/WeightSystem")
	if has_node("/root/SpoilageSystem"):
		spoilage_system = get_node("/root/SpoilageSystem")
		spoilage_system.set_player(self)
	
	inventory = get_tree().get_first_node_in_group("inventory")
	progression = get_tree().get_first_node_in_group("progression")
	quest_system = get_tree().get_first_node_in_group("quest_system")
	
	# Initialize weapon system
	_setup_weapon_system()

func _setup_weapon_system() -> void:
	weapon_system = WeaponSystem.new()
	weapon_system.name = "WeaponSystem"
	add_child(weapon_system)
	weapon_system.initialize(self)
	
	# Connect weapon signals
	weapon_system.attack_hit.connect(_on_weapon_hit)
	weapon_system.weapon_broke.connect(_on_weapon_broke)
	weapon_system.combo_advanced.connect(_on_combo_advanced)

func _on_weapon_hit(target: Node, damage: int) -> void:
	attacked.emit(target, float(damage))

func _on_weapon_broke(weapon_id: String) -> void:
	equipped_items["weapon"] = {}
	equipment_changed.emit("weapon", {})

func _on_combo_advanced(step: int) -> void:
	combo_count = step

func _initialize_stats() -> void:
	max_health = _calculate_max_health()
	max_stamina = _calculate_max_stamina()
	max_hunger = base_hunger
	max_thirst = base_thirst
	
	health = max_health
	stamina = max_stamina
	hunger = max_hunger
	thirst = max_thirst
	radiation = 0.0

func _setup_camera() -> void:
	if camera:
		camera.smoothing_enabled = true
		camera.smoothing_speed = 12.0

func _setup_hurtbox() -> void:
	if hurtbox:
		if hurtbox.has_signal("damaged"):
			hurtbox.connect("damaged", _on_damaged)
		if hurtbox.has_signal("died"):
			hurtbox.connect("died", _on_died)

func _setup_interact_area() -> void:
	if interact_area:
		interact_area.monitoring = true
		interact_area.monitorable = true
		interact_area.add_to_group("player_interact")
		interact_area.area_entered.connect(_on_interact_area_entered)
		interact_area.area_exited.connect(_on_interact_area_exited)

# ============================================================================
# MAIN LOOP
# ============================================================================

func _input(event: InputEvent) -> void:
	if is_dead:
		return
	
	# Attack input
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			_attempt_attack()
	
	# Key inputs
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_INTERACT:
				_attempt_interact()
			KEY_INVENTORY:
				_toggle_inventory()
			KEY_MAP:
				_toggle_map()

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	# Update timers
	_update_timers(delta)
	
	# Process survival needs
	_process_survival(delta)
	
	# Process status effects
	_process_effects(delta)
	
	# Handle movement
	var direction := _get_input_direction()
	_handle_movement(direction, delta)
	
	# Update animation
	_apply_animation(direction)
	
	# Sync stats
	_sync_all_stats()

func _update_timers(delta: float) -> void:
	attack_timer = max(attack_timer - delta, 0.0)
	invincibility_timer = max(invincibility_timer - delta, 0.0)
	combo_timer = max(combo_timer - delta, 0.0)
	
	if combo_timer <= 0.0:
		combo_count = 0

# ============================================================================
# MOVEMENT
# ============================================================================

func _get_input_direction() -> Vector2:
	var input_vec := Vector2.ZERO
	
	if Input.is_key_pressed(KEY_W):
		input_vec.y -= 1
	if Input.is_key_pressed(KEY_S):
		input_vec.y += 1
	if Input.is_key_pressed(KEY_A):
		input_vec.x -= 1
	if Input.is_key_pressed(KEY_D):
		input_vec.x += 1
	
	return input_vec

func _handle_movement(direction: Vector2, delta: float) -> void:
	# Check sprint/crouch
	is_sprinting = Input.is_key_pressed(KEY_SPRINT) and stamina > 10.0
	is_crouching = Input.is_key_pressed(KEY_CROUCH)
	
	if direction != Vector2.ZERO:
		last_move_direction = direction
		direction = direction.normalized()
		
		# Calculate speed
		current_speed = _calculate_move_speed()
		velocity = direction * current_speed
		
		if not _is_moving():
			movement_started.emit(velocity)
		
		# Stamina drain for sprinting
		if is_sprinting:
			_change_stamina(-STAMINA_SPRINT_DRAIN * delta)
	else:
		if _is_moving():
			movement_stopped.emit()
		velocity = Vector2.ZERO
		
		# Stamina recovery
		_change_stamina(STAMINA_RECOVERY_RATE * delta)
	
	move_and_slide()

func _calculate_move_speed() -> float:
	var speed := base_move_speed
	
	# Attribute bonus (agility)
	speed += (attributes.get("agility", 10) - 10) * 2.0
	
	# Sprint/crouch modifiers
	if is_sprinting and not is_crouching:
		speed *= SPRINT_MULTIPLIER
	elif is_crouching:
		speed *= CROUCH_MULTIPLIER
	
	# Equipment weight penalty
	var weight_penalty := _get_equipment_weight_penalty()
	speed *= (1.0 - weight_penalty)
	
	# Status effects
	for effect in active_effects:
		if effect.type == "speed_boost":
			speed *= (1.0 + effect.value)
		elif effect.type == "slow":
			speed *= (1.0 - effect.value)
	
	return speed

func _get_equipment_weight_penalty() -> float:
	var total_weight := 0.0
	for slot in equipped_items:
		var item: Dictionary = equipped_items[slot]
		if item and not item.is_empty():
			total_weight += item.get("weight", 0.0)
	
	# Max weight before penalty starts
	var weight_threshold := 20.0 + attributes.get("strength", 10) * 2.0
	
	if total_weight <= weight_threshold:
		return 0.0
	
	# Each point over threshold = 1% speed loss
	return clamp((total_weight - weight_threshold) / 100.0, 0.0, 0.5)

func _is_moving() -> bool:
	return velocity.length_squared() > 0.1

# ============================================================================
# COMBAT
# ============================================================================

func _attempt_attack() -> void:
	if attack_timer > 0.0 or is_attacking:
		return
	
	is_attacking = true
	
	# Calculate attack stats
	var weapon: Dictionary = equipped_items.get("weapon", {})
	var damage := _calculate_attack_damage(weapon)
	var cooldown := _calculate_attack_cooldown(weapon)
	var range := weapon.get("range", attack_range)
	
	attack_timer = cooldown
	
	# Combo tracking
	if combo_timer > 0.0:
		combo_count = min(combo_count + 1, 3)
		damage *= 1.0 + (combo_count * 0.15)  # 15% bonus per combo hit
	combo_timer = 0.8
	
	# Spawn hitbox
	_spawn_attack_hitbox(last_move_direction, damage, range)
	
	# Weapon durability
	_damage_equipped_weapon()
	
	is_attacking = false

func _calculate_attack_damage(weapon: Dictionary) -> float:
	var base_dmg := weapon.get("damage", base_melee_damage)
	
	# Strength bonus
	base_dmg += (attributes.get("strength", 10) - 10) * 0.5
	
	# Skill bonus
	var skill_type := "melee_combat" if weapon.is_empty() or weapon.get("type") == ExtendedItemDatabase.ItemType.WEAPON_MELEE else "ranged_combat"
	var skill_bonus: float = skill_bonuses.get(skill_type, 0.0)
	base_dmg *= (1.0 + skill_bonus / 100.0)
	
	# Critical hit check
	var crit_chance := BASE_CRITICAL_CHANCE + (attributes.get("luck", 10) - 10) * 0.01
	if randf() < crit_chance:
		base_dmg *= CRITICAL_HIT_MULTIPLIER
	
	return base_dmg

func _calculate_attack_cooldown(weapon: Dictionary) -> float:
	var cooldown := weapon.get("attack_cooldown", BASE_ATTACK_COOLDOWN) if weapon else BASE_ATTACK_COOLDOWN
	
	# Agility reduces cooldown
	cooldown *= 1.0 - ((attributes.get("agility", 10) - 10) * 0.01)
	
	return max(cooldown, 0.2)

func _spawn_attack_hitbox(direction: Vector2, damage: float, range_val: float) -> void:
	if direction == Vector2.ZERO:
		direction = Vector2.DOWN
	
	var hitbox := hitbox_scene.instantiate()
	hitbox.damage = damage
	hitbox.target_groups = ["hurtbox_enemy", "resource"]
	hitbox.owner = self
	
	var offset := direction.normalized() * range_val * 0.75
	hitbox.position = offset
	
	add_child(hitbox)
	hitbox.activate(range_val, direction)
	
	attacked.emit(null, damage)

func _damage_equipped_weapon() -> void:
	var weapon: Dictionary = equipped_items.get("weapon", {})
	if weapon.is_empty() or weapon.get("durability", -1) == -1:
		return
	
	weapon["durability"] = weapon.get("durability", 100) - 1
	
	if weapon["durability"] <= 0:
		# Weapon broke
		equipped_items["weapon"] = {}
		equipment_changed.emit("weapon", {})

# ============================================================================
# SURVIVAL MECHANICS
# ============================================================================

func _process_survival(delta: float) -> void:
	# Hunger decay
	_change_hunger(-HUNGER_DECAY_RATE * delta / 60.0)
	
	# Thirst decay
	_change_thirst(-THIRST_DECAY_RATE * delta / 60.0)
	
	# Radiation decay
	if radiation > 0:
		radiation = max(radiation - RADIATION_DECAY_RATE * delta, 0.0)
		radiation_changed.emit(radiation)
	
	# Health regeneration when well-fed
	if hunger >= 50.0 and thirst >= 50.0 and health < max_health:
		_change_health(HEALTH_REGEN_RATE * delta)
	
	# Starvation/dehydration damage
	if hunger <= 0.0:
		_change_health(-1.0 * delta)
	if thirst <= 0.0:
		_change_health(-2.0 * delta)
	
	# Radiation damage
	if radiation >= 80.0:
		_change_health(-3.0 * delta)
	elif radiation >= 50.0:
		_change_health(-1.0 * delta)

# ============================================================================
# STATUS EFFECTS
# ============================================================================

func _process_effects(delta: float) -> void:
	var to_remove: Array[int] = []
	
	for i in range(active_effects.size()):
		var effect: Dictionary = active_effects[i]
		effect["remaining_time"] = effect.get("remaining_time", 0) - delta
		
		# Apply ongoing effects
		match effect.type:
			"regen":
				_change_health(effect.value * delta)
			"poison":
				_change_health(-effect.value * delta)
			"burn":
				_change_health(-effect.value * delta)
		
		if effect["remaining_time"] <= 0:
			to_remove.append(i)
	
	# Remove expired effects
	for i in range(to_remove.size() - 1, -1, -1):
		active_effects.remove_at(to_remove[i])

func add_effect(effect_type: String, value: float, duration: float) -> void:
	# Check for existing effect of same type
	for effect in active_effects:
		if effect.type == effect_type:
			# Refresh duration, take higher value
			effect["remaining_time"] = max(effect.get("remaining_time", 0), duration)
			effect["value"] = max(effect.value, value)
			return
	
	active_effects.append({
		"type": effect_type,
		"value": value,
		"duration": duration,
		"remaining_time": duration
	})

func remove_effect(effect_type: String) -> void:
	for i in range(active_effects.size() - 1, -1, -1):
		if active_effects[i].type == effect_type:
			active_effects.remove_at(i)
			return

func clear_all_effects() -> void:
	active_effects.clear()

# ============================================================================
# STAT MANAGEMENT
# ============================================================================

func _calculate_max_health() -> float:
	var hp := base_health
	
	# Vitality bonus
	hp += (attributes.get("vitality", 10) - 10) * 5.0
	
	# Equipment bonus
	for slot in equipped_items:
		var item: Dictionary = equipped_items[slot]
		if item:
			hp += item.get("health_bonus", 0)
	
	return hp

func _calculate_max_stamina() -> float:
	var stam := base_stamina
	
	# Agility bonus
	stam += (attributes.get("agility", 10) - 10) * 3.0
	
	return stam

func _change_health(amount: float) -> void:
	var old_health := health
	health = clamp(health + amount, 0.0, max_health)
	
	if health != old_health:
		health_changed.emit(health, max_health)
		
		if health <= 0.0:
			_die()

func _change_stamina(amount: float) -> void:
	var old_stamina := stamina
	stamina = clamp(stamina + amount, 0.0, max_stamina)
	
	if stamina != old_stamina:
		stamina_changed.emit(stamina, max_stamina)

func _change_hunger(amount: float) -> void:
	var old_hunger := hunger
	hunger = clamp(hunger + amount, 0.0, max_hunger)
	
	if hunger != old_hunger:
		hunger_changed.emit(hunger, max_hunger)

func _change_thirst(amount: float) -> void:
	var old_thirst := thirst
	thirst = clamp(thirst + amount, 0.0, max_thirst)
	
	if thirst != old_thirst:
		thirst_changed.emit(thirst, max_thirst)

func set_health(value: float) -> void:
	health = clamp(value, 0.0, max_health)
	health_changed.emit(health, max_health)

# ============================================================================
# DAMAGE & DEATH
# ============================================================================

func take_damage(amount: float, source: Node = null) -> void:
	if is_dead or invincibility_timer > 0.0:
		return
	
	# Calculate damage reduction from armor
	var armor := _calculate_total_armor()
	var damage_reduction := armor / (armor + 100.0)
	var actual_damage := amount * (1.0 - damage_reduction)
	
	_change_health(-actual_damage)
	invincibility_timer = INVINCIBILITY_DURATION
	
	# Damage armor durability
	_damage_armor()
	
	took_damage.emit(actual_damage, source)

func _calculate_total_armor() -> float:
	var total := 0.0
	for slot in ["head", "torso", "legs", "feet", "hands"]:
		var item: Dictionary = equipped_items.get(slot, {})
		if item:
			total += item.get("armor", 0)
	return total

func _damage_armor() -> void:
	for slot in ["head", "torso", "legs", "feet", "hands"]:
		var item: Dictionary = equipped_items.get(slot, {})
		if item and item.get("durability", -1) > 0:
			item["durability"] = item.get("durability", 100) - 1
			if item["durability"] <= 0:
				equipped_items[slot] = {}
				equipment_changed.emit(slot, {})

func _die() -> void:
	if is_dead:
		return
	
	is_dead = true
	died.emit()
	
	# Disable processing
	set_process_input(false)
	set_physics_process(false)
	
	# Could trigger death screen, drop loot, etc.

func revive(health_percent: float = 0.5) -> void:
	if not is_dead:
		return
	
	is_dead = false
	health = max_health * health_percent
	stamina = max_stamina * 0.5
	hunger = max(hunger, 50.0)
	thirst = max(thirst, 50.0)
	
	set_process_input(true)
	set_physics_process(true)
	
	revived.emit()

# ============================================================================
# EQUIPMENT
# ============================================================================

func equip_item(slot: String, item: Dictionary) -> Dictionary:
	if not slot in equipped_items:
		return {}
	
	var previous := equipped_items[slot]
	equipped_items[slot] = item
	
	# Recalculate stats
	max_health = _calculate_max_health()
	max_stamina = _calculate_max_stamina()
	
	equipment_changed.emit(slot, item)
	
	return previous

func unequip_item(slot: String) -> Dictionary:
	return equip_item(slot, {})

func get_equipped(slot: String) -> Dictionary:
	return equipped_items.get(slot, {})

# ============================================================================
# INTERACTION
# ============================================================================

func _attempt_interact() -> void:
	if nearby_interactables.is_empty():
		return
	
	# Get closest interactable
	var closest: Node = null
	var closest_dist := INF
	
	for node in nearby_interactables:
		var dist := global_position.distance_squared_to(node.global_position)
		if dist < closest_dist:
			closest_dist = dist
			closest = node
	
	if closest and closest.has_method("interact"):
		closest.interact(self)
		interacted.emit(closest)

func _on_interact_area_entered(area: Area2D) -> void:
	if area.is_in_group("interactable") or area.is_in_group("resource"):
		if not area in nearby_interactables:
			nearby_interactables.append(area)

func _on_interact_area_exited(area: Area2D) -> void:
	nearby_interactables.erase(area)

# ============================================================================
# CONSUMABLE USE
# ============================================================================

func use_consumable(item: Dictionary) -> bool:
	if item.is_empty():
		return false
	
	# Apply effects
	if item.get("health_restore", 0) > 0:
		_change_health(item.health_restore)
	if item.get("stamina_restore", 0) > 0:
		_change_stamina(item.stamina_restore)
	if item.get("hunger_restore", 0) > 0:
		_change_hunger(item.hunger_restore)
	if item.get("thirst_restore", 0) > 0:
		_change_thirst(item.thirst_restore)
	
	# Apply status effects
	var effects: Array = item.get("effects", [])
	for effect in effects:
		add_effect(effect.type, effect.get("value", 1.0), effect.get("duration", 30.0))
	
	return true

# ============================================================================
# PROGRESSION INTEGRATION
# ============================================================================

func add_xp(amount: int) -> void:
	if progression and progression.has_method("add_xp"):
		progression.add_xp(amount)
	
	xp_gained.emit(amount)

func get_level() -> int:
	if progression and "level" in progression:
		return progression.level
	return player_level

func update_attributes(new_attributes: Dictionary) -> void:
	attributes = new_attributes.duplicate()
	
	# Recalculate derived stats
	max_health = _calculate_max_health()
	max_stamina = _calculate_max_stamina()

func update_skill_bonuses(new_bonuses: Dictionary) -> void:
	skill_bonuses = new_bonuses.duplicate()

# ============================================================================
# UI TOGGLES
# ============================================================================

func _toggle_inventory() -> void:
	var inventory_ui := get_tree().get_first_node_in_group("inventory_ui")
	if inventory_ui and inventory_ui.has_method("toggle"):
		inventory_ui.toggle()

func _toggle_map() -> void:
	var map_ui := get_tree().get_first_node_in_group("map_ui")
	if map_ui and map_ui.has_method("toggle"):
		map_ui.toggle()

# ============================================================================
# SYNC & CALLBACKS
# ============================================================================

func _sync_all_stats() -> void:
	var stats := {
		"health": health,
		"max_health": max_health,
		"stamina": stamina,
		"max_stamina": max_stamina,
		"hunger": hunger,
		"max_hunger": max_hunger,
		"thirst": thirst,
		"max_thirst": max_thirst,
		"radiation": radiation,
		"level": get_level()
	}
	
	stats_updated.emit(stats)
	
	if game_state and game_state.has_method("update_player_stats"):
		game_state.update_player_stats(health, stamina)

func _on_damaged(amount: float, remaining: float, source: Node) -> void:
	take_damage(amount, source)

func _on_died(source: Node) -> void:
	_die()

# ============================================================================
# ANIMATION
# ============================================================================

func _apply_animation(direction: Vector2) -> void:
	if animation_tree:
		animation_tree.set(BLEND_PATH, direction)

func _build_animation_tree() -> void:
	if not animation_tree or not animation_player:
		return
	
	var blend_root := AnimationNodeBlendSpace2D.new()
	blend_root.name = MOVEMENT_BLEND_NAME
	blend_root.min_space = Vector2(-1, -1)
	blend_root.max_space = Vector2(1, 1)
	
	var definitions := {
		"idle": Vector2.ZERO,
		"move_north": Vector2(0, -1),
		"move_south": Vector2(0, 1),
		"move_west": Vector2(-1, 0),
		"move_east": Vector2(1, 0)
	}
	
	for anim_name in definitions.keys():
		var animation := Animation.new()
		animation.length = 0.4
		animation.loop_mode = Animation.LOOP_MODE_PING_PONG
		
		var track := animation.add_track(Animation.TYPE_VALUE)
		animation.track_set_path(track, NodePath("Sprite2D:modulate"))
		
		var color := Color(1, 1, 1, 1)
		if anim_name != "idle":
			color = Color(0.9, 0.9, 1, 1)
		
		animation.track_insert_key(track, 0.0, color)
		animation.track_insert_key(track, animation.length, Color(1, 1, 1, 1))
		
		animation_player.add_animation(anim_name, animation)
		
		var animation_node := AnimationNodeAnimation.new()
		animation_node.animation = anim_name
		blend_root.add_blend_point(animation_node, definitions[anim_name])
	
	animation_tree.set_tree_root(blend_root)
	animation_tree.active = true

# ============================================================================
# ZONE MANAGEMENT
# ============================================================================

func enter_zone(zone_name: String) -> void:
	current_zone = zone_name
	zone_entered.emit(zone_name)
	
	# Check if safe zone
	is_in_safe_zone = zone_name == "base" or zone_name == "safe"

# ============================================================================
# SERIALIZATION
# ============================================================================

func get_save_data() -> Dictionary:
	return {
		"name": player_name,
		"position": {"x": global_position.x, "y": global_position.y},
		"current_zone": current_zone,
		"health": health,
		"stamina": stamina,
		"hunger": hunger,
		"thirst": thirst,
		"radiation": radiation,
		"equipped_items": equipped_items.duplicate(true),
		"active_effects": active_effects.duplicate(true)
	}

func load_save_data(data: Dictionary) -> void:
	player_name = data.get("name", "Survivor")
	
	if data.has("position"):
		global_position = Vector2(data.position.x, data.position.y)
	
	current_zone = data.get("current_zone", "green")
	health = data.get("health", max_health)
	stamina = data.get("stamina", max_stamina)
	hunger = data.get("hunger", max_hunger)
	thirst = data.get("thirst", max_thirst)
	radiation = data.get("radiation", 0.0)
	equipped_items = data.get("equipped_items", equipped_items).duplicate(true)
	active_effects = data.get("active_effects", []).duplicate(true)
	
	_sync_all_stats()
