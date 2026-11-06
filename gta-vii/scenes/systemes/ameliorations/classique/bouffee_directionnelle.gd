extends GPUParticles3D

@export_range(1.0, 15.0, 0.1) var distance := 5.0
@export_range(2.0, 180.0, 1.0) var demi_angle := 25.0
@export_range(0.1, 1.0, 0.05) var duree := 0.48
@export_range(16, 192, 8) var densite := 128
@export_range(0.1, 2.0, 0.05) var taille := 0.75
@export var couleur := Color(0.38, 0.88, 0.74, 0.95)

func _ready() -> void:
	one_shot = true
	emitting = false
	amount = densite
	lifetime = duree
	explosiveness = 0.9
	local_coords = false
	cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	visibility_aabb = AABB(Vector3.ONE * -(distance + taille), Vector3.ONE * (distance + taille) * 2.0)
	var simulation := ParticleProcessMaterial.new()
	simulation.direction = Vector3(0, 0, -1)
	simulation.spread = demi_angle
	simulation.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_SPHERE
	simulation.emission_sphere_radius = 0.08
	simulation.gravity = Vector3.ZERO
	simulation.initial_velocity_min = distance / duree * 0.45
	simulation.initial_velocity_max = distance / duree
	simulation.scale_min = taille * 0.65
	simulation.scale_max = taille
	simulation.angle_min = -180.0
	simulation.angle_max = 180.0
	var expansion := Curve.new()
	expansion.add_point(Vector2(0.0, 0.3))
	expansion.add_point(Vector2(0.4, 0.85))
	expansion.add_point(Vector2(1.0, 1.0))
	var courbe := CurveTexture.new()
	courbe.curve = expansion
	simulation.scale_curve = courbe
	var degrade := Gradient.new()
	degrade.offsets = PackedFloat32Array([0.0, 0.6, 1.0])
	degrade.colors = PackedColorArray([couleur, couleur, Color(couleur, 0.0)])
	var rampe := GradientTexture1D.new()
	rampe.gradient = degrade
	simulation.color_ramp = rampe
	process_material = simulation
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.albedo_texture = preload("res://assets/textures/extincteur/pulverisation.png")
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	var forme := QuadMesh.new()
	forme.material = mat
	draw_pass_1 = forme
	finished.connect(queue_free)
	# L'appelant peut orienter la buse avant l'émission en coordonnées mondiales.
	restart.call_deferred()
