extends RefCounted

# Ajouter ici les exercices accessibles, jamais les étapes futures.
const ETAPES = [
	{"id": "parvis", "titre": "Parvis · exercices extérieurs", "scene": "res://scenes/modes/tutoriel/00_03_parvis/00_parvis.tscn"},
	{"id": "liberation", "titre": "Sauvetage · libération", "scene": "res://scenes/modes/tutoriel/04_premier_sauvetage/04_premier_sauvetage.tscn"},
	{"id": "passage", "titre": "Sauvetage · passage à éteindre", "scene": "res://scenes/modes/tutoriel/04_premier_sauvetage/04_premier_sauvetage.tscn"},
	{"id": "escorte", "titre": "Sauvetage · escorte et prise en charge", "scene": "res://scenes/modes/tutoriel/04_premier_sauvetage/04_premier_sauvetage.tscn"},
	{"id": "combat", "titre": "Premier combat · briefing et porte", "scene": "res://scenes/modes/tutoriel/05_06_combat/05_premier_combat.tscn"},
	{"id": "pratique", "titre": "Respiration · combat autonome", "scene": "res://scenes/modes/tutoriel/05_06_combat/06_combat_autonome.tscn"},
	{"id": "poste", "titre": "Ravitaillement · avant le choix", "scene": "res://scenes/modes/tutoriel/07_ravitaillement/07_ravitaillement.tscn"},
	{"id": "essai_pression", "titre": "Essai · Sous pression", "scene": "res://scenes/modes/tutoriel/07_ravitaillement/07_ravitaillement.tscn"},
	{"id": "essai_reserve", "titre": "Essai · Grande réserve", "scene": "res://scenes/modes/tutoriel/07_ravitaillement/07_ravitaillement.tscn"},
	{"id": "essai_recharge", "titre": "Essai · Second souffle", "scene": "res://scenes/modes/tutoriel/07_ravitaillement/07_ravitaillement.tscn"},
	{"id": "menace_pression", "titre": "Menace · Sous pression · début", "scene": "res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.tscn"},
	{"id": "menace_pression:liberee", "titre": "Menace · Sous pression · après libération", "scene": "res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.tscn"},
	{"id": "menace_reserve", "titre": "Menace · Grande réserve · début", "scene": "res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.tscn"},
	{"id": "menace_reserve:liberee", "titre": "Menace · Grande réserve · après libération", "scene": "res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.tscn"},
	{"id": "menace_recharge", "titre": "Menace · Second souffle · début", "scene": "res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.tscn"},
	{"id": "menace_recharge:liberee", "titre": "Menace · Second souffle · après libération", "scene": "res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.tscn"},
	{"id": "points_1", "titre": "Points · début de la première salle", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"},
	{"id": "points_2", "titre": "Points · début de la seconde salle", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"},
	{"id": "boutique_points:1:0", "titre": "Boutique 1 · aucune victime", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"},
	{"id": "boutique_points:1:1", "titre": "Boutique 1 · une victime", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"},
	{"id": "boutique_points:2:0", "titre": "Boutique 2 · aucune victime", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"},
	{"id": "boutique_points:2:1", "titre": "Boutique 2 · une victime", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"},
	{"id": "boutique_points:2:2", "titre": "Boutique 2 · deux victimes", "scene": "res://scenes/modes/tutoriel/09_10_points_boutique/09_10_points_boutique.tscn"}]

static func definition(identifiant: String) -> Dictionary:
	for etape in ETAPES:
		if etape.id == identifiant: return etape
	for etape in ETAPES:
		if etape.id == identifiant.get_slice(":", 0): return etape
	return {}

static func conditions(valeurs: Dictionary) -> Dictionary:
	var acquis: Array[String] = []
	var manquants: Array[String] = []
	for nom in valeurs:
		if valeurs[nom]: acquis.append(nom)
		else: manquants.append(nom)
	return {"acquis": acquis, "manquants": manquants}
