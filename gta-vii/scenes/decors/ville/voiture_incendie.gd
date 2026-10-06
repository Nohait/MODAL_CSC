@tool
extends Node3D

func _ready() -> void:
	$Foyer/Flammes.hide()
	# Chaque langue a son rythme : les plans croisés donnent du volume au feu.
	for flamme in $Flammes.get_children():
		var mat: ShaderMaterial = flamme.material_override.duplicate()
		mat.set_shader_parameter("decalage", flamme.position.x * 0.4 + flamme.position.z * 0.35)
		flamme.material_override = mat
