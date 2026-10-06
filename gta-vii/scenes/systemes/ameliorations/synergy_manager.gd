extends Node

signal synergie_decouverte(definition: Synergie)
@export var catalogue: Array[Synergie] = []
var decouvertes: Dictionary = {}
var en_attente: Array[Synergie] = []

func verifier(cartes_obtenues: Dictionary, mode: String) -> void:
	var drapeau := 2 if mode == "zombie" else 1
	for definition in catalogue:
		if definition == null or definition.carte == null or definition.ingredients.is_empty(): continue
		if decouvertes.has(definition.identifiant) or (definition.modes & drapeau) == 0: continue
		var complete := true
		for ingredient in definition.ingredients:
			if not cartes_obtenues.has(ingredient): complete = false
		if not complete: continue
		# Mémoriser avant d'émettre évite un second déclenchement lors du recalcul.
		decouvertes[definition.identifiant] = true
		en_attente.append(definition)
		synergie_decouverte.emit(definition)
