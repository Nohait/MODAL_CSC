extends "res://scenes/interfaces/menus/navigation_menus.gd"

func _ready() -> void:
	super._ready()
	var bilan: Dictionary = get_tree().get_meta("bilan_zombie", {"atteinte": 0, "terminees": 0})
	if get_tree().has_meta("bilan_zombie"):
		get_tree().remove_meta("bilan_zombie")
	$Centre/Panneau/Contenu/Surtitre.text = "MODE ZOMBIE"
	$Centre/Panneau/Contenu/Description.text = "Vague atteinte : %d · Vagues terminées : %d" % [bilan.atteinte, bilan.terminees]
	%NouvellePartie.text = "Rejouer le mode zombie"

func nouvelle_partie() -> void:
	changer_scene("res://scenes/modes/zombie/mode_zombie.tscn")
