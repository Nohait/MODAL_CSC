extends Node3D

@export_range(0.2, 1.5, 0.05) var duree := 0.55
@export_range(0, 40, 1) var nombre_braises := 18
const CERCLE = preload("res://scenes/effets/apparition/cercle_apparition.tscn")
const SHADER = preload("res://scenes/effets/apparition/apparition_sbire.gdshader")
var surfaces: Array[Dictionary] = []
var feux: Array[Dictionary] = []
var animation: Tween
var physique_active := false
var termine := false
@onready var sbire = get_parent()

func _ready() -> void:
	physique_active = sbire.is_physics_processing()
	sbire.set_physics_process(false)
	var maillages: Array[Node] = sbire.get_node("Sketchfab_Scene").find_children("*", "MeshInstance3D", true, false)
	var goutte := sbire.get_node_or_null("droplet")
	if goutte is MeshInstance3D: maillages.append(goutte)
	var bas := INF
	var haut := -INF
	for maillage in maillages:
		if maillage.mesh == null: continue
		var volume: AABB = maillage.global_transform * maillage.mesh.get_aabb()
		bas = minf(bas, volume.position.y)
		haut = maxf(haut, volume.end.y)
	for maillage in maillages:
		if maillage.mesh == null: continue
		var remplacement: Material = maillage.material_override
		for i in range(maillage.mesh.get_surface_count()):
			var original: Material = maillage.get_active_material(i)
			var mat := ShaderMaterial.new()
			mat.shader = SHADER
			mat.set_shader_parameter("bas", bas)
			mat.set_shader_parameter("hauteur", maxf(haut - bas, 0.1))
			if original is StandardMaterial3D:
				mat.set_shader_parameter("teinte", original.albedo_color)
				mat.set_shader_parameter("utilise_texture", original.albedo_texture != null)
				mat.set_shader_parameter("texture_corps", original.albedo_texture)
				mat.set_shader_parameter("emission_initiale", original.emission * original.emission_energy_multiplier)
				mat.set_shader_parameter("utilise_emission", original.emission_texture != null)
				mat.set_shader_parameter("texture_emission", original.emission_texture)
			surfaces.append({"maillage": maillage, "surface": i, "original": maillage.get_surface_override_material(i), "mat": mat, "remplacement": remplacement})
			maillage.set_surface_override_material(i, mat)
		maillage.material_override = null
	var flammes: Array[Node3D] = []
	for feu in sbire.feux_mains: flammes.append(feu)
	var feu_corps := sbire.get_node_or_null("Flammes")
	if feu_corps is Node3D: flammes.append(feu_corps)
	for feu in flammes:
		feux.append({"noeud": feu, "echelle": feu.scale})
		feu.scale *= 0.05
	var cercle = CERCLE.instantiate()
	add_child(cercle)
	cercle.top_level = true
	var rayon := PhysicsRayQueryParameters3D.create(sbire.global_position + Vector3.UP, sbire.global_position - Vector3.UP * 5.0, 1)
	var sol := get_world_3d().direct_space_state.intersect_ray(rayon)
	var pied: Vector3 = sol.position if not sol.is_empty() else Vector3(sbire.global_position.x, bas, sbire.global_position.z)
	cercle.global_position = pied + Vector3.UP * 0.035
	cercle.charger(1.0)
	_creer_braises(pied)
	animation = create_tween().set_parallel(true)
	# Former le corps et ses flammes ensemble ; ne déplacer ni collision ni agent.
	animation.tween_method(_former, 0.0, 1.0, duree)
	animation.tween_method(cercle.attenuer, 1.0, 0.0, duree)
	animation.chain().tween_callback(terminer)
	animation.chain().tween_interval(0.65)
	animation.chain().tween_callback(queue_free)

func _former(progression: float) -> void:
	for surface in surfaces:
		surface.mat.set_shader_parameter("progression", progression)
	for feu in feux:
		feu.noeud.scale = feu.echelle * lerpf(0.05, 1.0, progression)

func terminer() -> void:
	if termine: return
	termine = true
	# Restaurer les matériaux exacts : textures, gel et effets de mort restent indépendants.
	for surface in surfaces:
		if is_instance_valid(surface.maillage):
			surface.maillage.set_surface_override_material(surface.surface, surface.original)
			surface.maillage.material_override = surface.remplacement
	for feu in feux:
		if is_instance_valid(feu.noeud): feu.noeud.scale = feu.echelle
	if not sbire.est_mort: sbire.set_physics_process(physique_active)

func annuler() -> void:
	if animation: animation.kill()
	terminer()
	queue_free()

func _creer_braises(pied: Vector3) -> void:
	if nombre_braises == 0: return
	var braises := CPUParticles3D.new()
	braises.amount = nombre_braises
	braises.lifetime = 0.65
	braises.one_shot = true
	braises.explosiveness = 0.9
	braises.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	braises.emission_sphere_radius = 0.55
	braises.direction = Vector3.UP
	braises.spread = 25.0
	braises.initial_velocity_min = 1.2
	braises.initial_velocity_max = 2.8
	braises.gravity = Vector3(0, -1.0, 0)
	braises.scale_amount_min = 0.6
	braises.scale_amount_max = 1.0
	var grain := SphereMesh.new()
	grain.radius = 0.025
	grain.height = 0.05
	grain.radial_segments = 6
	grain.rings = 3
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.45, 0.06)
	mat.emission_enabled = true
	mat.emission = mat.albedo_color
	grain.material = mat
	braises.mesh = grain
	braises.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(braises)
	braises.global_position = pied + Vector3.UP * 0.1
	braises.restart()
