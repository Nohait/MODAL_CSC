@tool
extends Node3D

@export var lumiere_incendie := false:
	set(valeur):
		lumiere_incendie = valeur
		if is_node_ready():
			_actualiser_lumiere()

@export var vue_exterieure := false

var temps := 0.0
var fumee: CPUParticles3D

@export var vitre_cassee := false:
	set(valeur):
		vitre_cassee = valeur
		if is_node_ready():
			_actualiser_vitrage()

func _ready() -> void:
	_actualiser_vitrage()
	_actualiser_lumiere()
	if vue_exterieure:
		$FondSombre.hide()
		# Garder le shader de cassure si cette fenêtre est déjà brisée.
		if not vitre_cassee:
			var vitre: MeshInstance3D = $Modele/Vitrage
			var mat: StandardMaterial3D = vitre.mesh.surface_get_material(0).duplicate()
			mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			mat.albedo_color.a = 0.18
			mat.roughness = 0.35
			vitre.set_surface_override_material(0, mat)
	if not Engine.is_editor_hint() and lumiere_incendie: _creer_fumee()

func _process(delta: float) -> void:
	if not lumiere_incendie:
		return
	temps += delta
	# Variation douce et déphasée selon la position : pas de flash ni de tirage par image.
	var phase := temps + position.x * 0.3 + position.z * 0.2
	$LumiereExterieure.light_energy = 3.0 * (0.9 + 0.07 * sin(phase * 1.8) + 0.03 * sin(phase * 4.3))

func _actualiser_lumiere() -> void:
	var fond := ShaderMaterial.new()
	fond.shader = preload("res://assets/shaders/decors/lueur_fenetre.gdshader")
	fond.set_shader_parameter("incendie", lumiere_incendie)
	$FondSombre.material_override = fond
	$LumiereExterieure.light_color = Color(1.0, 0.43, 0.12) if lumiere_incendie else Color(0.58, 0.72, 1.0)
	$LumiereExterieure.light_energy = 3.0

func _actualiser_vitrage() -> void:
	var verre: MeshInstance3D = $Modele/Vitrage
	if not vitre_cassee:
		verre.set_surface_override_material(0, null)
		return
	# Copier les textures dans un matériau propre à cette fenêtre ; l'import reste intact.
	var original: StandardMaterial3D = verre.mesh.surface_get_material(0)
	var materiau := ShaderMaterial.new()
	materiau.shader = preload("res://assets/shaders/decors/vitre_cassee.gdshader")
	materiau.set_shader_parameter("vitrage", original.albedo_texture)
	materiau.set_shader_parameter("normale", original.normal_texture)
	materiau.set_shader_parameter("rugosite", original.roughness_texture)
	var teinte := original.albedo_color
	if vue_exterieure:
		teinte.a = 0.18
	materiau.set_shader_parameter("teinte", teinte)
	verre.set_surface_override_material(0, materiau)

func _creer_fumee() -> void:
	# Quelques volutes dans l'ouverture, sans masquer le hall ni la silhouette des ennemis.
	fumee = CPUParticles3D.new()
	fumee.name = "FumeeFenetre"
	fumee.amount = 6
	fumee.lifetime = 3.0
	fumee.preprocess = 2.0
	fumee.position = Vector3(0, 1.35, 0.12)
	fumee.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	fumee.emission_box_extents = Vector3(0.35, 0.1, 0.01)
	fumee.direction = Vector3.UP
	fumee.spread = 8.0
	fumee.gravity = Vector3(0.03, 0.0, 0.0)
	fumee.initial_velocity_min = 0.15
	fumee.initial_velocity_max = 0.25
	var quad := QuadMesh.new()
	quad.size = Vector2(0.45, 0.5)
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://assets/shaders/decors/fumee_hall.gdshader")
	quad.material = mat
	fumee.mesh = quad
	var fondu := Gradient.new()
	fondu.offsets = PackedFloat32Array([0.0, 0.25, 0.75, 1.0])
	fondu.colors = PackedColorArray([Color(0.2, 0.17, 0.14, 0), Color(0.25, 0.22, 0.19, 0.2), Color(0.25, 0.22, 0.19, 0.14), Color(0.25, 0.22, 0.19, 0)])
	fumee.color_ramp = fondu
	fumee.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(fumee)
