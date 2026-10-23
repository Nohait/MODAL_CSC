extends RefCounted

# L’essai libre ne participe pas à la validation de cette étape.
var carte: StringName = &""
var termine := false

func acquerir(identifiant: StringName) -> bool:
	if carte != &"" or identifiant not in [&"pression", &"reserve", &"recharge"]: return false
	carte = identifiant
	return true

func valider_sortie(porte_ouverte: bool) -> bool:
	if termine or carte == &"" or not porte_ouverte: return false
	termine = true
	return true
