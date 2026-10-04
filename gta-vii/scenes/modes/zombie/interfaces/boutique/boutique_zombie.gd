extends "res://scenes/interfaces/menus/ameliorations/upgrade_manager.gd"

signal boutique_fermee

func _ready() -> void:
	super._ready()
	# Adapter les textes sans modifier la boutique du mode principal.
	for noeud in boutique.find_children("*", "Label", true, false):
		if noeud.text.begins_with("Chaque victime vivante"):
			noeud.text = "Chaque victime abritée rapporte un point par vague terminée."
	boutique.panneau_defis.hide()
	for noeud in boutique.find_children("*", "Button", true, false):
		if noeud.text == "Continuer vers la prochaine salle":
			noeud.text = "Préparer la prochaine vague"

func ouvrir_choix(_nombre_victimes: int) -> void:
	if boutique_ouverte or choix_ouverts: return
	if points_abondants_test: points = POINTS_BOUTIQUE_TEST
	boutique_ouverte = true
	extincteur.stop_primary_attack()
	souris_avant = Input.mouse_mode
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	get_tree().paused = true
	_actualiser_boutique()
	boutique.show()
	boutique.modulate.a = 0
	animation = create_tween()
	animation.tween_property(boutique, "modulate:a", 1.0, 0.2)

func _actualiser_boutique(message: String = "") -> void:
	if message.is_empty():
		message = "Chaque victime abritée rapporte un point par vague terminée. Vos points sont conservés."
	var liste_vide: Array[Dictionary] = []
	boutique.actualiser_boutique(points, liste_vide, liste_vide, 0, message)

func _continuer() -> void:
	if not boutique_ouverte or choix_ouverts: return
	boutique_ouverte = false
	if animation: animation.kill()
	boutique.hide()
	Input.mouse_mode = souris_avant
	get_tree().paused = false
	# Le gestionnaire reprend son compte à rebours ; aucun changement de salle.
	boutique_fermee.emit()
