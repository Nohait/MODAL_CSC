extends StaticBody3D

signal passage_degage
var degage := false
@onready var foyers: Node3D = $Foyers
var presentation: Node3D
var liaison: NavigationLink3D
var ouverture_en_cours := false
var largeur := 3.2

func _ready() -> void:
	largeur = ($Collision.shape as BoxShape3D).size.x
	presentation = preload("res://scenes/modes/tutoriel/04_premier_sauvetage/presentation_passage.gd").new()
	add_child(presentation)
	presentation.preparer(largeur)
	liaison = NavigationLink3D.new()
	liaison.enabled = false
	liaison.start_position = Vector3(0, 0, 0.6)
	liaison.end_position = Vector3(0, 0, -0.6)
	add_child(liaison)
	for foyer in foyers.get_children():
		# L’extinction et ses contacts restent communs ; seul ce passage regroupe le rendu.
		foyer.get_node("Flammes").hide()
		foyer.get_node("Fumee").hide()
		foyer.set_process(false)
		foyer.get_node("Extinction").foyer_eteint.connect(_actualiser)
	_actualiser()
	_process(0.0)

func _process(delta: float) -> void:
	var intensite := intensite_totale() / maxf(1, foyers.get_child_count())
	presentation.actualiser(intensite, delta)
	for foyer in foyers.get_children():
		var lumiere: OmniLight3D = foyer.get_node("Lumiere")
		lumiere.light_energy = 0.0 if degage else foyer.energie * lerpf(0.05, 1.0, intensite)

func intensite_totale() -> float:
	var total := 0.0
	for foyer in foyers.get_children():
		total += foyer.get_node("Extinction").intensite
	return total

func _actualiser() -> void:
	if degage or ouverture_en_cours or intensite_totale() > 0.0: return
	ouverture_en_cours = true
	# Sortir du traitement physique : rendu et collision basculent ensemble.
	_ouvrir.call_deferred()

func _ouvrir() -> void:
	$Collision.disabled = true
	liaison.enabled = true
	$Rideau.hide()
	presentation.ouvrir(foyers.get_child(0), largeur)
	degage = true
	_process(0.0)
	passage_degage.emit()
