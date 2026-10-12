extends MeshInstance3D

@export_range(0.5, 10.0, 0.1) var rayon := 2.5
@export_range(0.1, 1.5, 0.05) var hauteur := 0.55
@export_range(0.1, 2.0, 0.05) var duree := 0.55
@export_range(32, 128, 8) var segments := 80
@export_range(0, 48, 1) var nombre_eclaboussures := 18
@export_range(0.2, 1.5, 0.05) var taille_eclaboussures := 0.7
var retour := false
var temps := 0.0
var materiaux_eclaboussures: Array[ShaderMaterial] = []

func _ready() -> void:
	# Une vraie surface verticale forme la nappe d'eau, sans sprite face à la caméra.
	var sommets := PackedVector3Array()
	var uvs := PackedVector2Array()
	var indices := PackedInt32Array()
	for i in range(segments + 1):
		var angle := TAU * i / segments
		for bord in range(2):
			sommets.append(Vector3(cos(angle), bord, sin(angle)))
			uvs.append(Vector2(float(i) / segments, bord))
		if i < segments:
			var debut := i * 2
			indices.append_array(PackedInt32Array([debut, debut + 1, debut + 2, debut + 1, debut + 3, debut + 2]))
	var donnees := []
	donnees.resize(Mesh.ARRAY_MAX)
	donnees[Mesh.ARRAY_VERTEX] = sommets
	donnees[Mesh.ARRAY_TEX_UV] = uvs
	donnees[Mesh.ARRAY_INDEX] = indices
	var nappe := ArrayMesh.new()
	nappe.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, donnees)
	mesh = nappe
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/armes/bouche_incendie/couronne_eau.gdshader")
	mat.set_shader_parameter("rayon", rayon)
	mat.set_shader_parameter("hauteur", hauteur)
	material_override = mat
	custom_aabb = AABB(Vector3(-rayon - 1, -0.1, -rayon - 1), Vector3((rayon + 1) * 2, hauteur * 2 + 0.2, (rayon + 1) * 2))
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_ajouter_eclaboussures()

func _process(delta: float) -> void:
	temps += delta
	material_override.set_shader_parameter("progression", (1.0 - clampf(temps / duree, 0.0, 1.0)) if retour else clampf(temps / duree, 0.0, 1.0))
	for mat in materiaux_eclaboussures:
		mat.set_shader_parameter("time", (1.0 - clampf(temps / duree, 0.0, 1.0)) if retour else clampf(temps / duree, 0.0, 1.0))
	if temps >= duree:
		queue_free()

func _ajouter_eclaboussures() -> void:
	if nombre_eclaboussures == 0:
		return
	for mode in range(2):
		var surface := MeshInstance3D.new()
		surface.name = "Ondulations" if mode == 0 else "Eclaboussures"
		surface.mesh = preload("res://assets/effets/nimblux/nimblux_meshes.gd").quads(nombre_eclaboussures)
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://scenes/armes/bouche_incendie/eclaboussures_nimblux.gdshader")
		mat.set_shader_parameter("mode", mode)
		mat.set_shader_parameter("seed", 137 + mode)
		mat.set_shader_parameter("area_center", global_position)
		mat.set_shader_parameter("ground_height", global_position.y + 0.035)
		mat.set_shader_parameter("radius", rayon)
		mat.set_shader_parameter("size", taille_eclaboussures)
		mat.set_shader_parameter("color", Color(0.8, 0.92, 1.0, 0.65))
		mat.set_shader_parameter("emission", 0.0)
		surface.material_override = mat
		surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		surface.custom_aabb = custom_aabb
		add_child(surface)
		materiaux_eclaboussures.append(mat)
