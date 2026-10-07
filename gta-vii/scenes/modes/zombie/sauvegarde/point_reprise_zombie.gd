extends Node

var noeuds_figes: Array[Dictionary] = []

const ETAT = preload("res://scenes/systemes/sauvegarde/etat_sauvegarde.gd")
const CHAMPS_JOUEUR = ["rotation", "last_direction", "dash_cooldown_left", "protection_secours"]
const CHAMPS_ARME = ["charge", "is_overheated", "attente_recharge", "attack_timer"]
const CHAMPS_REFUGE = ["victimes", "sirene_restante", "rayon_sirene"]
const CHAMPS_SCORE = ["score", "serie", "restant", "dernier_palier"]
const CHAMPS_SUCCES = ["eliminations", "elites", "boss", "vagues_intactes", "touche"]

func enregistrer(vagues: Node, composition: CompositionVague, graine: int) -> bool:
	var niveau := get_parent()
	var joueur = niveau.get_node("player")
	var etat_joueur := ETAT.lire_champs(joueur, CHAMPS_JOUEUR)
	etat_joueur.position = joueur.global_position
	etat_joueur.vie = joueur.BarreDeVie.value
	etat_joueur.arme = ETAT.lire_champs(joueur.extincteur, CHAMPS_ARME)
	var point := {"version": SauvegardeZombie.VERSION, "vague": vagues.vague_actuelle,
		"vagues_terminees": vagues.vagues_terminees, "map": vagues.map.resource_path,
		"composition": composition.resource_path, "graine": graine,
		"joueur": etat_joueur, "pieces": niveau.get_node("Monnaie").solde,
		"ameliorations": niveau.get_node("UpgradeManager").capturer_sauvegarde(),
		"escorte": niveau.get_node("VictimManager").capturer_sauvegarde(),
		"refuge": ETAT.lire_champs(vagues.refuge, CHAMPS_REFUGE),
		"equipements": _capturer_equipements(vagues.salle_actuelle),
		"statistiques": StatistiquesZombie.compteurs.duplicate(true),
		"score": ETAT.lire_champs(niveau.get_node("ScoreComboManager"), CHAMPS_SCORE),
		"succes": ETAT.lire_champs(niveau.get_node("SuccesZombie"), CHAMPS_SUCCES),
		"arene": niveau.get_node("ArenaEventManager").capturer_sauvegarde()}
	return SauvegardeZombie.enregistrer(point)

func restaurer(vagues: Node, point: Dictionary) -> void:
	var niveau := get_parent()
	var joueur = niveau.get_node("player")
	# Reconstruire les bonus sans racheter les cartes ni redonner les soins immédiats.
	ETAT.appliquer_champs(vagues.refuge, point.refuge)
	niveau.get_node("UpgradeManager").restaurer_sauvegarde(point.ameliorations)
	niveau.get_node("VictimManager").restaurer_sauvegarde(point.escorte, vagues.salle_actuelle)
	ETAT.appliquer_champs(joueur, point.joueur, CHAMPS_JOUEUR)
	joueur.global_position = point.joueur.position
	joueur.velocity = Vector3.ZERO
	joueur.is_dashing = false
	joueur.BarreDeVie.value = point.joueur.vie
	ETAT.appliquer_champs(joueur.extincteur, point.joueur.arme)
	joueur.extincteur.vider_jet()
	var monnaie = niveau.get_node("Monnaie")
	monnaie.solde = int(point.pieces)
	monnaie.compteur.text = str(monnaie.solde)
	# Restaurer le solde avant les statistiques évite de compter ces pièces comme un butin.
	monnaie.solde_change.emit(monnaie.solde)
	StatistiquesZombie.compteurs = point.statistiques.duplicate(true)
	StatistiquesZombie.solde_precedent = monnaie.solde
	ETAT.appliquer_champs(niveau.get_node("ScoreComboManager"), point.score)
	ETAT.appliquer_champs(niveau.get_node("SuccesZombie"), point.succes)
	niveau.get_node("ArenaEventManager").restaurer_sauvegarde(point.arene, vagues.salle_actuelle)
	for etat in point.get("equipements", []):
		var objet: Node = vagues.salle_actuelle.get_node_or_null(NodePath(etat.chemin))
		if objet != null and objet.has_method("restaurer_sauvegarde"):
			objet.restaurer_sauvegarde(etat.etat)
	vagues.refuge.actualiser()
	vagues.vague_actuelle = int(point.vague) - 1
	vagues.vagues_terminees = int(point.vagues_terminees)
	niveau.get_node("CameraRig").recentrer()

func _capturer_equipements(salle: Node) -> Array[Dictionary]:
	var resultat: Array[Dictionary] = []
	for groupe in ["sprinkler", "extincteur_mural"]:
		for objet in get_tree().get_nodes_in_group(groupe):
			if salle.is_ancestor_of(objet) and objet.has_method("capturer_sauvegarde"):
				resultat.append({"chemin": str(salle.get_path_to(objet)), "etat": objet.capturer_sauvegarde()})
	return resultat

func figer_pendant_fondu(vagues: Node) -> void:
	# La reprise apparaît déjà à la bonne place ; ses réserves ne bougent pas pendant le fondu.
	var noeuds: Array[Node] = [vagues.joueur, vagues.refuge, get_parent().get_node("ScoreComboManager")]
	for groupe in ["sprinkler", "extincteur_mural"]:
		for objet in get_tree().get_nodes_in_group(groupe):
			if vagues.salle_actuelle.is_ancestor_of(objet): noeuds.append(objet)
	for noeud in noeuds:
		noeuds_figes.append({"noeud": noeud, "mode": noeud.process_mode})
		noeud.process_mode = Node.PROCESS_MODE_DISABLED
	StatistiquesZombie.actif = false

func reprendre() -> void:
	for etat in noeuds_figes:
		if is_instance_valid(etat.noeud): etat.noeud.process_mode = etat.mode
	noeuds_figes.clear()
	StatistiquesZombie.actif = true

