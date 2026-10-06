extends Control

# Un effet local à la carte : anneau et braises, sans flash sur tout l'écran.
var teinte := Color.WHITE
var puissance := 0
var progression := 0.0
var halo := StyleBoxFlat.new()

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	halo.bg_color = Color.TRANSPARENT
	halo.set_corner_radius_all(15)
	halo.shadow_size = 12 + puissance * 12
	var animation := create_tween()
	animation.tween_property(self, "progression", 1.0, 0.8 + puissance * 0.15)
	animation.finished.connect(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	var centre := size / 2.0
	var couleur := teinte
	couleur.a = pow(1.0 - progression, 2.0) * 0.75
	halo.shadow_color = couleur
	draw_style_box(halo, Rect2(Vector2.ZERO, size).grow(progression * puissance * 8.0))
	# Plus la carte est rare, plus la gerbe est fournie et s'étend loin.
	for i in range(8 + puissance * 12):
		var angle := i * 2.39996
		var direction := Vector2.from_angle(angle)
		# Partir du bord du rectangle, puis écarter les braises vers l'extérieur.
		var bord := minf(centre.x / maxf(absf(direction.x), 0.01), centre.y / maxf(absf(direction.y), 0.01))
		var distance := bord + 8.0 + progression * (30.0 + puissance * 25.0)
		var position_braise := centre + direction * distance
		draw_line(position_braise, position_braise + direction * (3 + puissance * 6), couleur, 2.0, true)
		draw_circle(position_braise, 1.5 + puissance * 0.5, couleur)
	if puissance >= 3:
		# Une onde ample accompagne la légendaire, derrière le papier et ses textes.
		draw_arc(centre, 40.0 + progression * 310.0, 0, TAU, 96, couleur, 3.0 * (1.0 - progression), true)
