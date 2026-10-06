extends RefCounted

# Copier uniquement les champs déclarés par chaque système.
static func lire_champs(noeud: Node, champs: Array) -> Dictionary:
	var resultat := {}
	for champ in champs:
		var valeur = noeud.get(champ)
		resultat[champ] = valeur.duplicate(true) if valeur is Array or valeur is Dictionary else valeur
	return resultat

static func appliquer_champs(noeud: Node, etat: Dictionary, champs: Array = []) -> void:
	for champ in etat:
		if champs.is_empty() or champs.has(champ): noeud.set(champ, etat[champ])
