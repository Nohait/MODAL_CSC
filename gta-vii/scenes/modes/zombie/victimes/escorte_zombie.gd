extends "res://scenes/victimes/victim_manager.gd"

var refuge: Node3D
var ordre_liberation := 0

func diriger_victime(fleche) -> void:
	if is_instance_valid(refuge) and refuge.survole:
		refuge.depot_demande = true
		# Chaque membre vise le refuge : toute la file peut y entrer.
		for victime in freed_victims:
			victime.follow_target = refuge
	else:
		if is_instance_valid(refuge): refuge.depot_demande = false
		super.diriger_victime(fleche)

func retour_nav_auto() -> void:
	if is_instance_valid(refuge): refuge.depot_demande = false
	reorganiser_file()

func register_victim(victim: CharacterBody3D) -> void:
	if not freed_victims.has(victim):
		ordre_liberation += 1
		victim.set_meta("ordre_liberation", ordre_liberation)
	super.register_victim(victim)
	if is_instance_valid(refuge) and refuge.depot_demande:
		victim.follow_target = refuge
