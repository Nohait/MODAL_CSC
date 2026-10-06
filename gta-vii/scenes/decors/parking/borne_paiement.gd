@tool
extends "res://scenes/decors/parking/accessoire_parking.gd"

@export_range(0.0, 5.0, 0.1) var intensite_ecran := 1.8

func _ready() -> void:
	super._ready()
	for morceau: MeshInstance3D in find_children("*", "MeshInstance3D", true, false):
		var original := morceau.get_active_material(0) as StandardMaterial3D
		if original == null or original.albedo_texture == null: continue
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://assets/shaders/decors/borne_paiement.gdshader")
		mat.set_shader_parameter("couleur", original.albedo_texture)
		mat.set_shader_parameter("intensite_ecran", intensite_ecran)
		morceau.material_override = mat
