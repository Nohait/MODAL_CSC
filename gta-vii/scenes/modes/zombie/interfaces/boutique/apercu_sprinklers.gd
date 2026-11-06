extends Control

var selection: Node3D

func montrer(sprinkler: Node3D) -> void:
	selection = sprinkler
	queue_redraw()

func _point(position_monde: Vector3) -> Vector2:
	# Reporter le hall de 40 mètres sur le petit plan, en conservant ses proportions.
	var cote := minf(size.x, size.y) - 24.0
	return (size - Vector2.ONE * cote) / 2.0 + Vector2(position_monde.x + 20, position_monde.z + 20) / 40.0 * cote

func _draw() -> void:
	var debut := _point(Vector3(-20, 0, -20))
	var fin := _point(Vector3(20, 0, 20))
	draw_rect(Rect2(debut, fin - debut), Color("bdbdbd"))
	draw_rect(Rect2(debut, fin - debut), Color("565656"), false, 2.0)
	for x in [-10, 10]:
		for segment in [Vector2(-20, -12), Vector2(-8, 8), Vector2(12, 20)]:
			draw_line(_point(Vector3(x, 0, segment.x)), _point(Vector3(x, 0, segment.y)), Color("565656"), 3.0)
	# Le camion est au centre ; les marques rouges sont les trois entrées terrestres.
	draw_rect(Rect2(_point(Vector3(-1.5, 0, -3)), Vector2(15, 25)), Color("c52d2f"))
	for entree in [Vector3(0, 0, -20), Vector3(-20, 0, -3), Vector3(-20, 0, 17)]:
		draw_circle(_point(entree), 4.0, Color("c52d2f"))
	if is_instance_valid(selection):
		var centre := _point(selection.get_node("Zone").global_position)
		var rayon: float = selection.rayon * (minf(size.x, size.y) - 24.0) / 40.0
		draw_circle(centre, rayon, Color(0, 0.556863, 0.368627, 0.3))
		draw_arc(centre, rayon, 0, TAU, 48, Color("008e5e"), 2.0, true)
		draw_circle(_point(selection.global_position), 4.0, Color("f5f5f0"))
