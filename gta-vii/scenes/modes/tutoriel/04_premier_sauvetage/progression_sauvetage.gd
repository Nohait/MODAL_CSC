extends Node

signal consigne_changee
signal premier_sauvetage_reussi

@export_range(0.5, 4.0, 0.1) var rayon_arrivee := 2.4
@export_range(3.0, 60.0, 1.0) var delai_rappel := 12.0
var joueur: CharacterBody3D
var victime: CharacterBody3D
var escorte: Node
var passage: Node
var repere: Node3D
var termine := false
var temps_sans_progres := 0.0
var etat_precedent := ""
var intensite_precedente := 0.0
var rappel_precedent := ""

func preparer(personnage: CharacterBody3D, habitant: CharacterBody3D, file: Node, obstacle: Node, arrivee: Node3D) -> void:
	joueur = personnage
	victime = habitant
	escorte = file
	passage = obstacle
	repere = arrivee
	intensite_precedente = passage.intensite_totale()
	etat_precedent = etat()
	consigne_changee.emit()

func etat() -> String:
	if termine: return "reussi"
	if not is_instance_valid(victime) or victime.est_morte or victime.vie <= 0.0: return "victime_perdue"
	if not victime.is_freed or not escorte.freed_victims.has(victime): return "liberation"
	if not passage.degage: return "extinction"
	return "escorte"

func consigne() -> String:
	match etat():
		"liberation": return "L’habitant est coincé. Approchez-vous pour l’aider · « Libérer »."
		"extinction": return "Il vous suit. Éteignez les flammes qui barrent le passage."
		"escorte": return "Accompagnez l’habitant jusqu’à la zone sécurisée."
		"victime_perdue": return "L’habitant n’a pas survécu."
	return "L’habitant est à l’abri. Le pompier prend le relais."

func rappel() -> String:
	if termine or temps_sans_progres < delai_rappel: return ""
	match etat():
		"liberation": return "Rapprochez-vous jusqu’à voir l’indication « Libérer », puis utilisez la touche indiquée."
		"extinction":
			var arme = joueur.extincteur
			if arme.charge < arme.max_charge * 0.25 or arme.is_overheated:
				return "Relâchez le clic gauche pour récupérer de la mousse."
			return "Approchez du passage et visez la base des flammes ; le jet doit atteindre chaque foyer."
		"escorte":
			if _dans_repere(joueur) and not _dans_repere(victime):
				return "Attendez l’habitant dans la zone sécurisée. Ne le laissez pas derrière vous."
			return "Rejoignez la zone sécurisée sans distancer l’habitant."
	return ""

func _dans_repere(corps: Node3D) -> bool:
	var ecart := corps.global_position - repere.global_position
	return Vector2(ecart.x, ecart.z).length() <= rayon_arrivee

func _physics_process(delta: float) -> void:
	if not is_instance_valid(joueur) or termine: return
	var actuelle := etat()
	var intensite: float = passage.intensite_totale()
	if actuelle != etat_precedent or intensite < intensite_precedente:
		temps_sans_progres = 0.0
		etat_precedent = actuelle
		consigne_changee.emit()
	intensite_precedente = intensite
	temps_sans_progres += delta
	var nouveau_rappel := rappel()
	if nouveau_rappel != rappel_precedent:
		rappel_precedent = nouveau_rappel
		consigne_changee.emit()
	if actuelle == "escorte" and _dans_repere(joueur) and _dans_repere(victime):
		# La mise en scène prend ensuite le relais, sans attribuer de victoire classique.
		termine = true
		consigne_changee.emit()
		premier_sauvetage_reussi.emit()
