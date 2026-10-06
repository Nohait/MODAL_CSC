extends Node3D

# Adapter la même annonce aux différents ennemis qui préparent un tir.
var etat_preparation := "preparation"
# Certains ennemis, comme le Blaze, restent menaçants pendant plusieurs tirs.
var etats_supplementaires: Array[String] = []
var propriete_duree := "preparation_tir"
var artilleur: Node3D
var angle := 0.0
var materiau: StandardMaterial3D
var support: MeshInstance3D

func _ready() -> void:
	# Une portion de cercle et un chevron remplacent la grosse flèche et le « ! ».
	top_level = true
	artilleur = get_parent()
	materiau = _materiau(Color(1.0, 0.18, 0.06, 0.8))
	materiau.emission_enabled = true
	materiau.emission = Color(1.0, 0.1, 0.02)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(20):
		var debut := deg_to_rad(-24.0 + i * 2.4)
		var fin := deg_to_rad(-24.0 + (i + 1) * 2.4)
		var a := Vector3(sin(debut), 0, -cos(debut))
		var b := Vector3(sin(fin), 0, -cos(fin))
		_triangle(mesh, a * 1.43, b * 1.43, b * 1.49)
		_triangle(mesh, a * 1.43, b * 1.49, a * 1.49)
	# Chevron creux : sa pointe donne la direction, sans remplir une grosse flèche.
	_triangle(mesh, Vector3(-0.2, 0, -1.57), Vector3(0, 0, -1.82), Vector3(0, 0, -1.74))
	_triangle(mesh, Vector3(-0.2, 0, -1.57), Vector3(0, 0, -1.74), Vector3(-0.14, 0, -1.57))
	_triangle(mesh, Vector3(0.2, 0, -1.57), Vector3(0, 0, -1.74), Vector3(0, 0, -1.82))
	_triangle(mesh, Vector3(0.2, 0, -1.57), Vector3(0.14, 0, -1.57), Vector3(0, 0, -1.74))
	mesh.surface_end()
	# Une fine silhouette sombre garde le repère lisible sur les sols lumineux.
	var contour := MeshInstance3D.new()
	contour.mesh = mesh
	contour.scale = Vector3(1.025, 1, 1.025)
	contour.material_override = _materiau(Color(0.08, 0.02, 0.01, 0.7))
	contour.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(contour)
	support = MeshInstance3D.new()
	support.mesh = mesh
	support.position.y = 0.005
	support.material_override = materiau
	support.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(support)
	hide()

func _triangle(mesh: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	mesh.surface_add_vertex(a)
	mesh.surface_add_vertex(b)
	mesh.surface_add_vertex(c)

func _materiau(couleur: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.albedo_color = couleur
	return mat

func _process(delta: float) -> void:
	var cible = artilleur.cible_attaque
	var actif: bool = not artilleur.est_mort and (artilleur.etat == etat_preparation or artilleur.etat in etats_supplementaires) and is_instance_valid(cible)
	if not actif or not cible.is_in_group("player") or cible.est_mort:
		hide()
		return
	var direction: Vector3 = artilleur.global_position - cible.global_position
	var nouveau := atan2(direction.x, direction.z)
	# Pointer immédiatement à l'apparition, puis lisser les rotations suivantes.
	angle = lerp_angle(angle, nouveau, 1.0 - exp(-12.0 * delta)) if visible else nouveau
	var avancee := 1.0 if artilleur.etat in etats_supplementaires else clampf(1.0 - artilleur.temps_etat / maxf(float(artilleur.get(propriete_duree)), 0.001), 0.0, 1.0)
	global_position = cible.global_position + Vector3.UP * 0.35
	global_rotation = Vector3(0, angle + PI, 0)
	# La pulsation devient légèrement plus marquée vers la fin de la charge.
	var pulsation := sin(avancee * TAU * 2.0) * avancee
	materiau.albedo_color.a = lerpf(0.6, 1.0, avancee)
	materiau.emission_energy_multiplier = 0.3 + avancee * 0.7 + pulsation * 0.15
	support.scale = Vector3.ONE * (1.0 + pulsation * 0.025)
	show()
