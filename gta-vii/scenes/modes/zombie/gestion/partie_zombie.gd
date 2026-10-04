extends "res://scenes/jeu/main.gd"

func afficher_ecran_mort() -> void:
	# Transmettre uniquement le résultat ; la scène de combat sera ensuite détruite.
	var vagues = $Salles/RoomManager
	get_tree().set_meta("bilan_zombie", {"atteinte": vagues.vague_actuelle, "terminees": vagues.vagues_terminees})
	get_tree().change_scene_to_file("res://scenes/modes/zombie/interfaces/fin/fin_zombie.tscn")
