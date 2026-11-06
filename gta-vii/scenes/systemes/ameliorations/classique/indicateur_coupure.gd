extends Control

var reserve: Node

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _draw() -> void:
	var carte = reserve.definition(&"coupure_nette")
	if carte == null: return
	# Deux repères sur la jauge existante ; aucun panneau supplémentaire.
	for seuil in [carte.seuil_reserve, carte.seuil_rearmement]:
		var x: float = size.x * seuil / 100.0
		draw_line(Vector2(x, 0), Vector2(x, 6), Color(0.06, 0.08, 0.08), 3.0)
		draw_line(Vector2(x, 0), Vector2(x, 5), Color.WHITE, 1.0)
	var couleur := Color(0.35, 0.38, 0.38)
	if reserve.armee: couleur = Color(0.1, 0.65, 0.35) if reserve.proportion() * 100.0 <= carte.seuil_reserve else Color.WHITE
	var x: float = size.x * carte.seuil_reserve / 100.0
	draw_circle(Vector2(x, -5), 4.0, Color(0.06, 0.08, 0.08))
	draw_circle(Vector2(x, -5), 2.5, couleur)
