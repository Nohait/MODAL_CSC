@tool
extends Node3D

@export var lumiere_incendie := false:
	set(valeur):
		lumiere_incendie = valeur
		if is_node_ready():
			_actualiser_lumiere()

var temps := 0.0

@export var vitre_cassee := false:
	set(valeur):
		vitre_cassee = valeur
		if is_node_ready():
			_actualiser_vitrage()

func _ready() -> void:
	_actualiser_vitrage()
	_actualiser_lumiere()

func _process(delta: float) -> void:
	if not lumiere_incendie:
		return
	temps += delta
	# Variation douce et déphasée selon la position : pas de flash ni de tirage par image.
	var phase := temps + position.x * 0.3 + position.z * 0.2
	$LumiereExterieure.light_energy = 3.0 * (0.9 + 0.07 * sin(phase * 1.8) + 0.03 * sin(phase * 4.3))

func _actualiser_lumiere() -> void:
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
	materiau.set_shader_parameter("teinte", original.albedo_color)
	verre.set_surface_override_material(0, materiau)
