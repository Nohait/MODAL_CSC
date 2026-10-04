extends "res://scenes/ennemis/tourelles/tour_enflammee.gd"

func choisir_cible() -> void:
	var refuge = get_tree().get_first_node_in_group("refuge_zombie")
	if is_instance_valid(refuge) and refuge.attire(self) and global_position.distance_to(refuge.global_position) <= distance_attaque:
		cible = refuge
		return
	if is_instance_valid(cible) and cible.is_in_group("victime") and not cible.is_freed:
		cible = null
	super.choisir_cible()
