extends RefCounted

var liberee := false
var porte_ouverte := false
var vaincu := false
var reussi := false
var perdu := false

func dans_zone(position: Vector3) -> bool:
	return Vector2(position.x - 10, position.z + 64).length() <= 2.4

func verifier(joueur, victime, escorte) -> bool:
	if reussi or perdu or not liberee or not vaincu: return false
	if joueur.est_mort or not is_instance_valid(victime) or victime.est_morte or victime.vie <= 0: return false
	if not escorte.freed_victims.has(victime): return false
	if not dans_zone(joueur.global_position) or not dans_zone(victime.global_position): return false
	reussi = true
	return true

func consigne() -> String:
	if perdu: return "L’habitant n’a pas survécu."
	if reussi: return "La victime est à l’abri et la menace est écartée. Ouvrez la porte de sortie."
	if not liberee: return "Aidez l’habitant à se dégager, puis accompagnez-le à l’abri."
	if not porte_ouverte: return "La personne vous suit. Ouvrez la porte pour poursuivre."
	if not vaincu: return "Gardez la créature à distance de l’habitant."
	return "Accompagnez l’habitant jusqu’à la zone sécurisée."
