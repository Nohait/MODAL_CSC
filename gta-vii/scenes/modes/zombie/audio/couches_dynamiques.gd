extends "res://scenes/systemes/audio/playlist_adaptative.gd"

@onready var vagues = get_node("../Salles/RoomManager")

func _contexte_musical() -> Dictionary:
	return {
		"combat": vagues.vague_actuelle > 0 and vagues.phase == "combat",
		"salle": vagues.salle_actuelle,
		"palier": vagues.vague_actuelle,
		"evenement": vagues.composition_actuelle.evenement if vagues.composition_actuelle != null else ""
	}
