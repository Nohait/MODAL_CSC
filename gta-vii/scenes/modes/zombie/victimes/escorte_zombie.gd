extends "res://scenes/victimes/victim_manager.gd"

var refuge: Node3D
# Le dépôt concerne seulement les victimes présentes lors du clic sur le camion.
var victimes_en_depot: Array[CharacterBody3D] = []

func diriger_victime(fleche) -> void:
	victimes_en_depot.clear()
	if is_instance_valid(refuge) and refuge.survole:
		victimes_en_depot.assign(freed_victims)
		cible_deplacement = null
		reorganiser_file()
	else:
		if is_instance_valid(refuge): refuge.depot_demande = false
		super.diriger_victime(fleche)

func retour_nav_auto() -> void:
	victimes_en_depot.clear()
	if is_instance_valid(refuge): refuge.depot_demande = false
	super.retour_nav_auto()

func register_victim(victim: CharacterBody3D) -> void:
	if freed_victims.has(victim): return
	ordre_liberation += 1
	victim.set_meta("ordre_liberation", ordre_liberation)
	super.register_victim(victim)
	# Une nouvelle libération ne reçoit jamais l'ancien ordre de dépôt.
	var cible: Node3D = player
	for precedente in freed_victims:
		if precedente == victim: break
		if is_instance_valid(precedente) and not victimes_en_depot.has(precedente):
			cible = precedente
	victim.follow_target = cible

func reorganiser_file() -> void:
	if not is_instance_valid(refuge):
		super.reorganiser_file()
		return
	# Retirer les victimes déposées ou mortes sans modifier l'ordre des survivantes.
	for victime in victimes_en_depot.duplicate():
		if not is_instance_valid(victime) or not freed_victims.has(victime):
			victimes_en_depot.erase(victime)
	refuge.depot_demande = not victimes_en_depot.is_empty()
	if not refuge.depot_demande:
		super.reorganiser_file()
		return
	var cible: Node3D = player
	for victime in freed_victims:
		if not is_instance_valid(victime): continue
		if victimes_en_depot.has(victime):
			victime.follow_target = refuge
		else:
			victime.follow_target = cible
			cible = victime

func _est_en_depot(victime: CharacterBody3D) -> bool:
	return victimes_en_depot.has(victime)

func _restaurer_depot(victime: CharacterBody3D) -> void:
	victimes_en_depot.append(victime)
