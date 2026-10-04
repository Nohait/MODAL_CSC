@tool
extends StaticBody3D

const SHADER = preload("res://assets/shaders/decors/banc_incandescent.gdshader")

@export_range(0.0, 1.0, 0.05) var brulure := 0.75:
	set(valeur):
		brulure = valeur
		if is_node_ready():
			_actualiser_braises()
@export_range(0.0, 6.0, 0.1) var intensite_braises := 3.2:
	set(valeur):
		intensite_braises = valeur
		if is_node_ready():
			_actualiser_braises()

func _ready() -> void:
	_actualiser_braises()

func _actualiser_braises() -> void:
	for morceau in $Modele.find_children("*", "MeshInstance3D", true, false):
		for surface in range(morceau.mesh.get_surface_count()):
			var original = morceau.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D:
				continue
			# Reprendre les textures du modèle, sans modifier le matériau importé.
			var materiau := ShaderMaterial.new()
			materiau.shader = SHADER
			materiau.set_shader_parameter("bois", original.albedo_texture)
			materiau.set_shader_parameter("normale", original.normal_texture)
			materiau.set_shader_parameter("rugosite", original.roughness_texture)
			materiau.set_shader_parameter("teinte", original.albedo_color)
			materiau.set_shader_parameter("rugosite_de_base", original.roughness)
			# Les textures PBR importées peuvent ranger la rugosité dans différents canaux.
			var canal := Vector4.ZERO
			if original.roughness_texture_channel < 4:
				canal[original.roughness_texture_channel] = 1.0
			else:
				canal = Vector4(0.333, 0.333, 0.333, 0.0)
			materiau.set_shader_parameter("canal_rugosite", canal)
			materiau.set_shader_parameter("brulure", brulure)
			materiau.set_shader_parameter("intensite_braises", intensite_braises)
			morceau.set_surface_override_material(surface, materiau)
	# L'émission colore le banc ; cette lumière éclaire réellement le sol à côté.
	$LumiereBraises.light_energy = intensite_braises * brulure * 0.25
	$LumiereBraises.visible = intensite_braises > 0.0 and brulure > 0.0
