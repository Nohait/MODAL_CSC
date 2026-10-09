@tool
extends StaticBody3D

@export var avec_piece_derriere := false:
	set(valeur):
		avec_piece_derriere = valeur
		if is_node_ready(): _actualiser()

@export_range(0.0, 2.0, 0.05) var energie_lueur := 0.45:
	set(valeur):
		energie_lueur = valeur
		if is_node_ready(): _actualiser()
@export_range(1.0, 5.0, 0.1) var portee_lueur := 2.5:
	set(valeur):
		portee_lueur = valeur
		if is_node_ready(): _actualiser()
@export_range(0, 20) var nombre_particules_fumee := 8:
	set(valeur):
		nombre_particules_fumee = valeur
		if is_node_ready(): _actualiser()

var temps := 0.0

func _ready() -> void:
	_actualiser()
	set_process(energie_lueur > 0)

func _actualiser() -> void:
	# Une véritable pièce remplace le fond noir et la fausse bande incandescente.
	for nom in ["FondSombre", "LueurInterieure"]:
		var surface := get_node_or_null(nom) as Node3D
		if surface != null: surface.visible = not avec_piece_derriere
	var lumiere := get_node_or_null("Lueur") as OmniLight3D
	if lumiere != null:
		lumiere.light_energy = energie_lueur
		lumiere.omni_range = portee_lueur
		lumiere.visible = energie_lueur > 0
	var fumee := get_node_or_null("Fumee") as CPUParticles3D
	if fumee != null:
		fumee.amount = maxi(1, nombre_particules_fumee)
		fumee.emitting = nombre_particules_fumee > 0
	set_process(energie_lueur > 0)

func _process(delta: float) -> void:
	# Une variation douce suggère le feu derrière la porte, sans flash ni ombre supplémentaire.
	temps += delta
	var lumiere := get_node_or_null("Lueur") as OmniLight3D
	if lumiere != null:
		lumiere.light_energy = energie_lueur * (0.9 + 0.07 * sin(temps * 4.0) + 0.03 * sin(temps * 9.0))
