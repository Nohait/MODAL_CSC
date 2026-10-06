@tool
extends Node3D

@export_range(0.5, 4.0, 0.1) var hauteur := 3.3
@export var taille_flaque := Vector2(3.0, 1.9)
@export_range(4, 40, 1) var nombre_gouttes := 22
@export var teinte := Color(0.12, 0.20, 0.24, 0.55)

func _ready() -> void:
	# Une nappe fine laisse voir le béton ; elle ne gêne ni la marche ni la navigation.
	var flaque := MeshInstance3D.new()
	var plan := PlaneMesh.new()
	plan.size = taille_flaque
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/decors/flaque_eau_parking.gdshader")
	mat.set_shader_parameter("teinte", teinte)
	plan.material = mat
	flaque.mesh = plan
	flaque.position.y = 0.035
	flaque.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(flaque)
	if Engine.is_editor_hint(): return
	var gouttes := CPUParticles3D.new()
	gouttes.amount = nombre_gouttes
	gouttes.lifetime = sqrt(2.0 * hauteur / 9.8)
	gouttes.position.y = hauteur
	gouttes.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	gouttes.emission_sphere_radius = 0.06
	gouttes.direction = Vector3.DOWN
	gouttes.spread = 3.0
	gouttes.gravity = Vector3(0, -9.8, 0)
	gouttes.initial_velocity_min = 0.05
	gouttes.initial_velocity_max = 0.15
	var goutte := SphereMesh.new()
	goutte.radius = 0.018
	goutte.height = 0.09
	var eau := StandardMaterial3D.new()
	eau.albedo_color = Color(0.45, 0.67, 0.75)
	eau.roughness = 0.3
	goutte.material = eau
	gouttes.mesh = goutte
	gouttes.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(gouttes)
