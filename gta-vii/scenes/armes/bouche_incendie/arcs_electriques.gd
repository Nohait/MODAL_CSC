extends MeshInstance3D

# Quelques rubans irréguliers suffisent : aucune simulation ni lumière supplémentaire.
@export_range(1, 12, 1) var nombre_arcs := 6
@export_range(0.005, 0.05, 0.005) var epaisseur := 0.015
@export_range(0.03, 0.2, 0.01) var intervalle := 0.06
var onde := false
var rayon := 2.5
var duree := 0.55
var temps := 0.0
var attente := 0.0
var hauteur := 1.2
var aleatoire := RandomNumberGenerator.new()
var mat: StandardMaterial3D

func _ready() -> void:
	aleatoire.randomize()
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat = StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(0.62, 0.86, 1.0)
	mat.emission_enabled = true
	mat.emission = Color(0.18, 0.5, 1.0)
	mat.emission_energy_multiplier = 2.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	material_override = mat

func actualiser(taille: float, hauteur_modele: float) -> void:
	rayon = taille
	hauteur = hauteur_modele

func _process(delta: float) -> void:
	temps += delta
	attente -= delta
	if onde and temps >= duree:
		queue_free()
		return
	if attente > 0.0: return
	attente = intervalle
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in range(nombre_arcs):
		var angle := TAU * i / nombre_arcs + aleatoire.randf_range(-0.2, 0.2)
		var direction := Vector3(cos(angle), 0, sin(angle))
		var tangent := Vector3(-direction.z, 0, direction.x) * epaisseur
		var dernier := direction * rayon * 0.3 + Vector3.UP * 0.12
		for j in range(1, 9):
			var p := float(j) / 8.0
			var point: Vector3
			if onde:
				point = direction * lerpf(0.3, rayon * clampf(temps / duree, 0.0, 1.0), p)
				point.y = 0.08 + sin(p * PI) * 0.12
			else:
				point = direction * rayon
				point.y = p * hauteur
			point += Vector3(aleatoire.randf_range(-0.07, 0.07), aleatoire.randf_range(-0.04, 0.04), aleatoire.randf_range(-0.07, 0.07))
			for sommet in [dernier - tangent, dernier + tangent, point - tangent, point - tangent, dernier + tangent, point + tangent]:
				surface.add_vertex(sommet)
			dernier = point
	mesh = surface.commit()
