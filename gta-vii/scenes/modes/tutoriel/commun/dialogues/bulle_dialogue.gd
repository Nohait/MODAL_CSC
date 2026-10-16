extends PanelContainer

@export_range(10.0, 80.0, 1.0) var caracteres_par_seconde := 36.0
@export_range(0.0, 0.5, 0.01) var pause_virgule := 0.1
@export_range(0.0, 0.8, 0.01) var pause_phrase := 0.22
@export_range(8.0, 48.0, 1.0) var ecart_bulle := 22.0
@export_range(8.0, 40.0, 1.0) var marge_ecran := 20.0
@export var dialogue_interactif := false
@onready var suite: Label = $Marge/Disposition/Suite
@onready var texte: Label = $Marge/Disposition/Texte
var acteur: Node3D
var camera: Camera3D
var attente := 0.0
var phrase := ""

func afficher(replique: String) -> void:
	if replique == phrase: return
	phrase = replique
	texte.text = replique
	texte.visible_characters = 0
	attente = 0.0
	reset_size.call_deferred()

func revelee() -> bool:
	return texte.visible_characters < 0 or texte.visible_characters >= phrase.length()

func terminer_phrase() -> void:
	texte.visible_characters = -1

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	_placer()
	suite.visible = dialogue_interactif
	suite.text = "E · Continuer" if revelee() else "E · Tout afficher"
	if revelee(): return
	attente -= delta
	while attente <= 0.0 and not revelee():
		var caractere := phrase.substr(texte.visible_characters, 1)
		texte.visible_characters += 1
		attente += 1.0 / caracteres_par_seconde
		if caractere in [",", ";", ":"]: attente += pause_virgule
		elif caractere in [".", "!", "?", "…"]: attente += pause_phrase

func _placer() -> void:
	if not is_instance_valid(acteur) or not is_instance_valid(camera): return
	# La caméra projette en pixels ; le Canvas peut être redimensionné par le stretch.
	var conversion := get_canvas_transform().affine_inverse()
	var point := conversion * camera.unproject_position(acteur.global_position + Vector3.UP * 1.3)
	var limites := conversion * get_viewport_rect().size
	var gauche := clampf(point.x - size.x * 0.5, marge_ecran, maxf(marge_ecran, limites.x - size.x - marge_ecran))
	var haut_minimum := marge_ecran
	# Réserver la place de l’objectif lorsqu’il partage la même zone de l’écran.
	for panneau in get_tree().get_nodes_in_group("briefings_tutoriel"):
		if not panneau.is_visible_in_tree(): continue
		var rectangle: Rect2 = panneau.get_global_rect()
		if gauche < rectangle.end.x and gauche + size.x > rectangle.position.x:
			haut_minimum = maxf(haut_minimum, rectangle.end.y + 12.0)
	position = Vector2(gauche, clampf(point.y - size.y - ecart_bulle, haut_minimum, maxf(haut_minimum, limites.y - size.y - marge_ecran)))
	queue_redraw()

func _draw() -> void:
	# Une petite pointe rattache visuellement la parole au personnage.
	var centre := size.x * 0.5
	var points := PackedVector2Array([Vector2(centre - 12, size.y - 1), Vector2(centre + 12, size.y - 1), Vector2(centre, size.y + 17)])
	draw_colored_polygon(points, get_theme_stylebox("panel").bg_color)
