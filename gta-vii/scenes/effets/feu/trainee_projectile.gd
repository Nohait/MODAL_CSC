extends MeshInstance3D

var duree := 0.65
var largeur := 0.18
var points: Array[Vector3] = []
var instants: Array[float] = []
var distances: Array[float] = []
var temps := 0.0
var terminee := false
var ruban := ImmediateMesh.new()

func _ready() -> void:
	mesh = ruban
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/effets/feu/trainee_projectile.gdshader")
	material_override = mat
	# Les sommets sont des positions mondiales, indÃ©pendantes du projectile et de la salle.
	top_level = true
	global_transform = Transform3D.IDENTITY

func ajouter_point(position_monde: Vector3) -> void:
	if terminee: return
	var distance := 0.0
	if not points.is_empty():
		distance = distances.back() + points.back().distance_to(position_monde)
		if points.back().distance_squared_to(position_monde) < 0.0001: return
	points.append(position_monde)
	instants.append(temps)
	distances.append(distance)

func terminer() -> void:
	# Ne plus dÃ©poser de points, mais laisser les anciens finir de s'Ã©teindre.
	terminee = true

func _process(delta: float) -> void:
	temps += delta
	while not instants.is_empty() and temps - instants[0] >= duree:
		points.pop_front()
		instants.pop_front()
		distances.pop_front()
	ruban.clear_surfaces()
	if terminee and points.size() < 2:
		queue_free()
		return
	if points.size() < 2: return
	var camera := get_viewport().get_camera_3d()
	if camera == null: return
	ruban.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(points.size() - 1):
		var direction := (points[i + 1] - points[i]).normalized()
		var regard := camera.global_position - points[i]
		if camera.projection == Camera3D.PROJECTION_ORTHOGONAL:
			regard = camera.global_basis.z
		var cote := direction.cross(regard).normalized()
		if cote.length_squared() < 0.01: cote = direction.cross(Vector3.UP).normalized()
		# Chaque segment garde sa position ; seul son bord et son Ã©clat diminuent.
		for sommet in [Vector2i(i, -1), Vector2i(i, 1), Vector2i(i + 1, -1), Vector2i(i + 1, -1), Vector2i(i, 1), Vector2i(i + 1, 1)]:
			var indice: int = sommet.x
			var vie := clampf(1.0 - (temps - instants[indice]) / duree, 0.0, 1.0)
			ruban.surface_set_color(Color(1.0, 1.0, 1.0, vie))
			ruban.surface_set_uv(Vector2(distances[indice], float(sommet.y)))
			ruban.surface_add_vertex(points[indice] + cote * largeur * sqrt(vie) * sommet.y)
	ruban.surface_end()

