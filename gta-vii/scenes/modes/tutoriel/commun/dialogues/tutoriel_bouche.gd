extends PanelContainer

var pause_avant := false
var souris_avant := Input.MOUSE_MODE_VISIBLE
var fermeture_en_cours := false
@onready var demonstration: AnimatedSprite2D = $Marge/AnimatedSprite2D
@onready var commandes: AnimationPlayer = $Marge/Disposition/AnimationPlayer
@onready var bouton_fermer: Button = $Marge/Disposition/Fermer
@onready var voile: ColorRect = $"../FondBouche"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	bouton_fermer.pressed.connect(fermer)
	resized.connect(_ajuster_demonstration)
	$Marge/Disposition.sort_children.connect(_ajuster_demonstration.call_deferred)
	_ajuster_demonstration.call_deferred()

func ouvrir() -> void:
	if visible: return
	pause_avant = get_tree().paused
	souris_avant = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	voile.show()
	show()
	demonstration.play(&"default")
	commandes.play(&"new_animation")
	bouton_fermer.grab_focus()

func fermer() -> void:
	if not visible or fermeture_en_cours: return
	fermeture_en_cours = true
	# Ne pas transmettre le clic ou Échap au jeu pendant la même propagation d'entrée.
	get_viewport().set_input_as_handled()
	_terminer_fermeture.call_deferred()

func _terminer_fermeture() -> void:
	demonstration.stop()
	commandes.stop()
	voile.hide()
	hide()
	Input.mouse_mode = souris_avant
	get_tree().paused = pause_avant
	fermeture_en_cours = false

func _input(event: InputEvent) -> void:
	if visible and not event.is_echo() and event.is_action_pressed("ui_cancel"):
		fermer()

func _ajuster_demonstration() -> void:
	var image := demonstration.sprite_frames.get_frame_texture(&"default", 0)
	var dimensions := image.get_size()
	# Conserver la démonstration à droite et son rapport d'image d'origine (800 × 450).
	demonstration.position = Vector2(size.x - 212.0, size.y * 0.5)
	demonstration.scale = Vector2.ONE * (352.0 / dimensions.x)
	var espace: Control = $Marge/Disposition/EspaceCommandes
	$Marge/Disposition/Manette.position = espace.position + Vector2(espace.size.x * 0.5 - 48.0, 32.0)
	$Marge/Disposition/ClicDroit.position = espace.position + Vector2(espace.size.x * 0.5 + 48.0, 32.0)
