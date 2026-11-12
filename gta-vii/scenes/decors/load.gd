extends Node3D

@onready var anim_pompier = $player/visual/Armature/AnimationPlayer
@onready var victim = $victime

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_pompier.play("crouching/crouching")
	victim.health_bar_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
