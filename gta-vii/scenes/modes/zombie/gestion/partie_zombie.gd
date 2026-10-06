extends "res://scenes/jeu/main.gd"

func _ready() -> void:
	StatistiquesZombie.demarrer(self)
	super._ready()

func _on_player_died() -> void:
	SauvegardeZombie.supprimer()
	super._on_player_died()

func afficher_ecran_mort() -> void:
	StatistiquesZombie.terminer()
	# Transmettre uniquement le résultat ; la scène de combat sera ensuite détruite.
	get_tree().change_scene_to_file("res://scenes/modes/zombie/interfaces/fin/fin_zombie.tscn")
