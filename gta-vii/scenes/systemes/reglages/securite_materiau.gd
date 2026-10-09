extends MeshInstance3D

func _notification(quoi: int) -> void:
	if quoi != NOTIFICATION_PREDELETE: return
	# Godot peut garder une référence de rendu périmée lors de la destruction
	# d'un maillage avec des remplacements de matériaux. Les détacher avant celle-ci.
	for i in range(get_surface_override_material_count()):
		set_surface_override_material(i, null)
	material_override = null
	material_overlay = null
