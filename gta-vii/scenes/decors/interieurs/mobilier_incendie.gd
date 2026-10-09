@tool
extends StaticBody3D

const BRULURE = preload("res://assets/shaders/decors/mobilier_appartement.gdshader")

@export_range(0.0, 1.0, 0.05) var brulure := 0.35:
	set(valeur):
		brulure = valeur
		if is_node_ready(): _actualiser_materiaux()
@export_range(0.0, 6.0, 0.1) var intensite_braises := 0.5:
	set(valeur):
		intensite_braises = valeur
		if is_node_ready(): _actualiser_materiaux()
@export_range(0.2, 1.5, 0.05) var taille_foyer := 0.45
@export var point_foyer := Vector3(-1.2, 0.4, -0.8)

func _ready() -> void:
	_actualiser_materiaux()

func _actualiser_materiaux() -> void:
	# Chaque instance reçoit ses matériaux : les fichiers importés restent intacts.
	for morceau in $Mobilier.find_children("*", "MeshInstance3D", true, false):
		for surface in range(morceau.mesh.get_surface_count()):
			var original = morceau.mesh.surface_get_material(surface)
			if not original is StandardMaterial3D: continue
			var materiau := ShaderMaterial.new()
			materiau.shader = BRULURE
			materiau.set_shader_parameter("couleur", original.albedo_texture)
			materiau.set_shader_parameter("normale", original.normal_texture)
			materiau.set_shader_parameter("rugosite", original.roughness_texture)
			materiau.set_shader_parameter("metal", original.metallic_texture)
			materiau.set_shader_parameter("teinte", original.albedo_color)
			materiau.set_shader_parameter("rugosite_de_base", original.roughness)
			materiau.set_shader_parameter("metal_de_base", original.metallic)
			materiau.set_shader_parameter("relief", original.normal_scale)
			materiau.set_shader_parameter("canal_rugosite", _canal(original.roughness_texture_channel))
			materiau.set_shader_parameter("canal_metal", _canal(original.metallic_texture_channel))
			materiau.set_shader_parameter("brulure", brulure)
			materiau.set_shader_parameter("intensite_braises", intensite_braises)
			morceau.set_surface_override_material(surface, materiau)

func _canal(indice: int) -> Vector4:
	# Le glTF regroupe souvent rugosité et métal dans les canaux vert et bleu.
	var canal := Vector4.ZERO
	if indice < 4:
		canal[indice] = 1.0
	else:
		canal = Vector4(0.333, 0.333, 0.333, 0.0)
	return canal

func position_foyer() -> Vector3:
	return point_foyer
