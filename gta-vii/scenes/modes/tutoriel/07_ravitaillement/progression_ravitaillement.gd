extends RefCounted

# L’essai libre ne participe pas à la validation de cette étape.
var carte: StringName = &""
var termine := false

func acquerir(identifiant: StringName) -> bool:
	if carte != &"" or identifiant not in [&"pression", &"reserve", &"recharge"]: return false
	carte = identifiant
	return true

func verifier_sortie(position_joueur: Vector3, porte_ouverte: bool) -> bool:
	if termine or carte == &"" or not porte_ouverte: return false
	if absf(position_joueur.x) >= 1.1 or position_joueur.z >= -44.5: return false
	termine = true
	return true
