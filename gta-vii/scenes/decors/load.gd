extends Node3D

@onready var anim_pompier = $player/visual/Armature/AnimationPlayer
@onready var victim = $victime

var depart_en_cours := false

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	anim_pompier.play("crouching/crouching")
	victim.health_bar_viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
	$Sbire.active = false


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass

func animer_depart(duree: float) -> void:
	var camera = $Camera3D
	depart_en_cours = true
	var animation := create_tween()
	animation.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	animation.tween_property(camera, "position", camera.position - camera.global_basis.z * 0.45, duree)
