extends CharacterBody2D

signal movement_started(velocity)
signal movement_stopped()
signal stats_updated(health, stamina)

const SPEED := 220.0
const STAMINA_MAX := 100.0
const STAMINA_RECOVERY_RATE := 15.0
const STAMINA_DRAIN_RATE := 12.0
const HEALTH_MAX := 100.0

const MOVEMENT_BLEND_NAME := "MovementBlend"
const BLEND_PATH := "parameters/MovementBlend/blend_position"
const ATTACK_HITBOX_SCENE := preload("res://scenes/combat/Hitbox.tscn")

var health := HEALTH_MAX
var stamina := STAMINA_MAX
var blend_root: AnimationNodeBlendSpace2D
@export var attack_damage := 30.0
@export var attack_range := 48.0
@export var attack_cooldown := 0.5
var interact_key: int = KEY_E
var attack_timer := 0.0
var last_move_direction := Vector2(0, -1)

@onready var sprite: Sprite2D = $Sprite
@onready var animation_tree: AnimationTree = $AnimationTree
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var camera: Camera2D = $Camera2D
@onready var hurtbox: Area2D = $Hurtbox
@onready var interact_area: Area2D = $InteractArea

func _ready():
    camera.smoothing_enabled = true
    camera.smoothing_speed = 12.0
    _build_animation_tree()
    animation_tree.active = true
    animation_tree.set("anim_player", animation_player.get_path())
    animation_tree.set_tree_root(blend_root)
    animation_tree.set(BLEND_PATH, Vector2.ZERO)
    GameState.update_player_stats(health, stamina)
    hurtbox.damaged.connect(_on_player_damaged)
    hurtbox.died.connect(_on_player_died)
    add_to_group("player")
    if interact_area:
        interact_area.monitoring = true
        interact_area.monitorable = true
        interact_area.add_to_group("player_interact")

func _input(event):
    if health <= 0.0:
        return
    if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
        _attempt_attack()
    elif event is InputEventKey and event.pressed and event.keycode == interact_key:
        _attempt_interact()

func _physics_process(delta):
    if health <= 0.0:
        return
    var direction = _get_input_direction()
    attack_timer = max(attack_timer - delta, 0.0)
    if direction != Vector2.ZERO:
        last_move_direction = direction
    if direction != Vector2.ZERO:
        direction = direction.normalized()
        velocity = direction * SPEED
        if not is_moving():
            emit_signal("movement_started", velocity)
        _update_stamina(-STAMINA_DRAIN_RATE * delta)
    else:
        if is_moving():
            emit_signal("movement_stopped")
        velocity = Vector2.ZERO
        _update_stamina(STAMINA_RECOVERY_RATE * delta)
    move_and_slide()
    _apply_animation(direction)
    _sync_stats()

func is_moving() -> bool:
    return velocity.length_squared() > 0.1

func _get_input_direction() -> Vector2:
    var input_vec = Vector2.ZERO
    if Input.is_key_pressed(KEY_W):
        input_vec.y -= 1
    if Input.is_key_pressed(KEY_S):
        input_vec.y += 1
    if Input.is_key_pressed(KEY_A):
        input_vec.x -= 1
    if Input.is_key_pressed(KEY_D):
        input_vec.x += 1
    return input_vec

func _apply_animation(direction: Vector2) -> void:
    animation_tree.set(BLEND_PATH, direction)

func _update_stamina(delta_value: float) -> void:
    stamina = clamp(stamina + delta_value, 0.0, STAMINA_MAX)

func _sync_stats() -> void:
    emit_signal("stats_updated", health, stamina)
    GameState.update_player_stats(health, stamina)

func _attempt_attack() -> void:
    if attack_timer > 0.0:
        return
    attack_timer = attack_cooldown
    _spawn_attack_hitbox(last_move_direction)

func _spawn_attack_hitbox(direction: Vector2) -> void:
    var dir = direction
    if dir == Vector2.ZERO:
        dir = Vector2.DOWN
    var hitbox = ATTACK_HITBOX_SCENE.instantiate()
    hitbox.damage = attack_damage
    hitbox.target_groups = ["hurtbox_enemy", "resource"]
    hitbox._owner = self
    var offset = dir.normalized() * attack_range * 0.75
    hitbox.position = offset
    add_child(hitbox)
    hitbox.activate(attack_range, dir)

func _attempt_interact() -> void:
    if not interact_area:
        return
    for area in interact_area.get_overlapping_areas():
        if area.is_in_group("resource") and area.has_method("interact"):
            area.interact(self)
            return

func _on_player_damaged(amount: float, remaining_health: float, source: Node) -> void:
    health = remaining_health
    _sync_stats()

func _on_player_died(source: Node) -> void:
    print("Player down", source)
    set_process_input(false)
    set_physics_process(false)

func _build_animation_tree() -> void:
    blend_root = AnimationNodeBlendSpace2D.new()
    blend_root.name = MOVEMENT_BLEND_NAME
    blend_root.min_space = Vector2(-1, -1)
    blend_root.max_space = Vector2(1, 1)
    var definitions = {
        "idle": Vector2.ZERO,
        "move_north": Vector2(0, -1),
        "move_south": Vector2(0, 1),
        "move_west": Vector2(-1, 0),
        "move_east": Vector2(1, 0)
    }
    for name in definitions.keys():
        var animation = Animation.new()
        animation.length = 0.4
        animation.loop_mode = Animation.LOOP_PINGPONG
        var track = animation.add_track(Animation.TYPE_VALUE)
        animation.track_set_path(track, NodePath("Sprite:modulate"))
        animation.track_insert_key(track, 0.0, Color(1 if name == "idle" else 0.7, 0.7 if name.ends_with("north") else 1, 1, 1))
        animation.track_insert_key(track, animation.length, Color(1, 1, 1, 1))
        animation_player.add_animation(name, animation)
        var animation_node = AnimationNodeAnimation.new()
        animation_node.animation = name
        blend_root.add_blend_point(animation_node, definitions[name])
