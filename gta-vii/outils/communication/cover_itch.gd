extends Node3D

@export_group("Capture")
@export var dossier_export := "user://covers"
@export var resolution := Vector2i(1890, 1500)
@export_range(0.0, 3.0, 0.05) var instant_pose := 0.35

@onready var titre: Label = $Titrage/Titre
@onready var aide: Label = $Commandes/Aide
var cadrage := 0
var capture_en_cours := false

func _enter_tree() -> void:
	# Neutraliser avant les _ready des scènes de jeu, sans déplacer leur composition.
	for nom in ["Decor", "Personnages", "Incendie"]:
		_neutraliser(get_node("Monde/" + nom))

func _ready() -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_window().size = resolution
	_poser($Monde/Personnages/OrientationPompier/Pompier, "Idle/Idle")
	_poser($Monde/Personnages/Sbire, "idle")
	_poser($Monde/Personnages/Victime, "idle")
	_cadrer(0)

func _neutraliser(noeud: Node) -> void:
	# La scène ne conserve que les visuels, les lumières et les particules.
	noeud.set_script(null)
	for groupe in noeud.get_groups(): noeud.remove_from_group(groupe)
	if noeud is AnimationTree: noeud.active = false
	if noeud is AudioStreamPlayer3D or noeud is AudioStreamPlayer: noeud.autoplay = false
	if noeud is CollisionObject3D:
		noeud.collision_layer = 0
		noeud.collision_mask = 0
	for enfant in noeud.get_children(): _neutraliser(enfant)

func _poser(modele: Node, animation: String) -> void:
	for lecteur in modele.find_children("*", "AnimationPlayer", true, false):
		if lecteur.has_animation(animation):
			lecteur.play(animation)
			lecteur.seek(instant_pose, true)
			lecteur.pause()

func _cadrer(indice: int) -> void:
	cadrage = indice
	var cameras := $Monde/Cameras.get_children()
	(cameras[indice] as Camera3D).make_current()
	aide.text = "Cadrage %d · 1/2/3 : caméra · T : titre · F12 : exporter les 3 vues" % (indice + 1)

func _unhandled_key_input(event: InputEvent) -> void:
	if not event is InputEventKey or not event.pressed or event.echo or capture_en_cours: return
	match event.keycode:
		KEY_1: _cadrer(0)
		KEY_2: _cadrer(1)
		KEY_3: _cadrer(2)
		KEY_T: titre.visible = not titre.visible
		KEY_F12: _exporter()

func _exporter() -> void:
	capture_en_cours = true
	aide.hide()
	var dossier := dossier_export.path_join(Time.get_datetime_string_from_system().replace(":", "-"))
	var erreur := DirAccess.make_dir_recursive_absolute(dossier)
	if erreur == OK:
		for i in range(3):
			_cadrer(i)
			await RenderingServer.frame_post_draw
			erreur = get_viewport().get_texture().get_image().save_png(dossier.path_join("gta-vii-%d.png" % (i + 1)))
			if erreur != OK: break
	aide.text = "Captures : " + ProjectSettings.globalize_path(dossier) if erreur == OK else "Échec de capture : " + error_string(erreur)
	aide.show()
	capture_en_cours = false
