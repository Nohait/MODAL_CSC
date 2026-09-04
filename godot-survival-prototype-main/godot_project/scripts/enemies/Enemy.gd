extends CharacterBody2D

const ATTACK_HITBOX_SCENE := preload("res://scenes/combat/Hitbox.tscn")

enum State { IDLE, WANDER, CHASE, ATTACK, HIT, DEAD }

@export var move_speed := 90.0
@export var detection_radius := 220.0
@export var attack_range := 44.0
@export var damage := 15.0
@export var attack_speed := 1.4
@export var wander_interval := 2.0

var state := State.WANDER
var attack_cooldown := 0.0
var wander_timer := 0.0
var wander_direction := Vector2.RIGHT
var player: Node2D
var rng := RandomNumberGenerator.new()

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var hurtbox: Node = $Hurtbox

func _ready() -> void:
    rng.randomize()
    _build_animation_player()
    animation_player.play("idle")
    hurtbox.damaged.connect(_on_hurt)
    hurtbox.died.connect(_on_death)

func assign_target(node: Node2D) -> void:
    player = node

func _physics_process(delta: float) -> void:
    if state == State.DEAD:
        return
    attack_cooldown = max(attack_cooldown - delta, 0.0)
    if player:
        var distance = global_position.distance_to(player.global_position)
        if state != State.HIT:
            if distance <= attack_range:
                _enter_attack()
            elif distance <= detection_radius:
                _enter_chase()
            else:
                _enter_wander(delta)
        else:
            _enter_wander(delta)
    else:
        _enter_wander(delta)
    velocity = velocity.limit_length(move_speed)
    move_and_slide()

func _enter_wander(delta: float) -> void:
    if state != State.WANDER:
        state = State.WANDER
        animation_player.play("walk")
    wander_timer -= delta
    if wander_timer <= 0.0:
        wander_direction = Vector2(rng.randf_range(-1, 1), rng.randf_range(-1, 1))
        if wander_direction == Vector2.ZERO:
            wander_direction = Vector2.RIGHT
        wander_timer = wander_interval + rng.randf_range(0.4, 1.2)
    velocity = wander_direction.normalized() * move_speed

func _enter_chase() -> void:
    if state != State.CHASE:
        state = State.CHASE
        animation_player.play("walk")
    if player:
        velocity = (player.global_position - global_position).normalized() * move_speed

func _enter_attack() -> void:
    state = State.ATTACK
    animation_player.play("attack")
    velocity = Vector2.ZERO
    if attack_cooldown <= 0.0:
        attack_cooldown = attack_speed
        _perform_attack()

func _perform_attack() -> void:
    if not player:
        return
    var direction = (player.global_position - global_position)
    if direction == Vector2.ZERO:
        direction = Vector2.DOWN
    var hitbox = ATTACK_HITBOX_SCENE.instantiate()
    hitbox.damage = damage
    hitbox.target_groups = ["hurtbox_player"]
    hitbox.owner = self
    var offset = direction.normalized() * attack_range * 0.6
    hitbox.position = offset
    add_child(hitbox)
    hitbox.activate(attack_range, direction)

func _on_hurt(amount: float, remaining_health: float, source: Node) -> void:
    state = State.HIT
    animation_player.play("hit")
    velocity = Vector2.ZERO
    if source and source is Node2D:
        var knockback = (global_position - source.global_position)
        if knockback != Vector2.ZERO:
            velocity = knockback.normalized() * (move_speed * 0.5)

func _on_death(source: Node) -> void:
    state = State.DEAD
    animation_player.play("death")
    velocity = Vector2.ZERO
    set_physics_process(false)
    var timer = get_tree().create_timer(1.2)
    timer.connect("timeout", Callable(self, "queue_free"))

func _build_animation_player() -> void:
    var definitions = {
        "idle": Color(1, 1, 1, 1),
        "walk": Color(0.8, 0.8, 1, 1),
        "attack": Color(1, 0.7, 0.6, 1),
        "hit": Color(1, 0.4, 0.4, 1),
        "death": Color(0.5, 0.5, 0.5, 1)
    }
    for name in definitions.keys():
        var animation = Animation.new()
        animation.length = 0.4
        animation.loop_mode = Animation.LOOP_PINGPONG
        var track = animation.add_track(Animation.TYPE_VALUE)
        animation.track_set_path(track, NodePath("Sprite:modulate"))
        animation.track_insert_key(track, 0.0, definitions[name])
        animation.track_insert_key(track, animation.length, Color(1, 1, 1, 1))
        animation_player.add_animation(name, animation)
