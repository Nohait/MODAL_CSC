extends "res://scenes/ennemis/mobiles/sbire.gd"

func choisir_cible() -> void:
	var refuge = get_tree().get_first_node_in_group("refuge_zombie")
	if is_instance_valid(refuge) and refuge.attire(self):
		cible = refuge
		en_idle = false
		return
	# Un refuge vide ne doit pas conserver l’aggro de sa dernière victime.
	if is_instance_valid(cible) and cible.is_in_group("victime") and not cible.is_freed:
		cible = null
	super.choisir_cible()

func _physics_process(delta: float) -> void:
	var refuge = get_tree().get_first_node_in_group("refuge_zombie")
	if is_instance_valid(refuge) and refuge.attire(self):
		cible = refuge
		en_idle = false
	var portee_normale: float = distance_attaque
	# Le refuge est plus large qu’un personnage : frapper depuis son bord.
	if is_instance_valid(cible) and cible.name == "Refuge":
		distance_attaque += cible.distance_au_bord(global_position)
	super._physics_process(delta)
	distance_attaque = portee_normale
