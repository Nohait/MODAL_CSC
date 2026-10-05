extends Node

const FICHIER_RECORDS = "user://records_zombie.cfg"
const RECORDS = ["vagues_terminees", "ennemis_elimines", "victimes_liberees", "victimes_abritees", "pieces_collectees"]
var actif := false
var session := 0
var niveau: Node
var compteurs: Dictionary = {}
var dernier_bilan: Dictionary = {}
var records: Dictionary = {}
var ennemis_suivis: Dictionary = {}
var victimes_suivies: Dictionary = {}
var solde_precedent := 0

func _ready() -> void:
	var fichier := ConfigFile.new()
	if fichier.load(FICHIER_RECORDS) == OK:
		for id in RECORDS: records[id] = maxf(0.0, float(fichier.get_value("records", id, 0.0)))
	CatalogueEnnemis.ennemi_enregistre.connect(_suivre_ennemi)
	get_tree().node_added.connect(_noeud_ajoute)

func demarrer(partie: Node) -> void:
	# Cet appel appartient au mode zombie : une partie classique ne lance aucun suivi.
	session += 1
	actif = true
	niveau = partie
	compteurs = bilan_vide()
	dernier_bilan.clear()
	ennemis_suivis.clear()
	victimes_suivies.clear()
	var monnaie := partie.get_node("Monnaie")
	solde_precedent = monnaie.solde
	monnaie.solde_change.connect(_solde_change.bind(session))
	partie.get_node("player").degats_recus.connect(_degats_recus.bind(session))
	partie.get_node("Salles/RoomManager").partie_prete.connect(_brancher_refuge, CONNECT_ONE_SHOT)
	partie.tree_exiting.connect(_partie_retiree.bind(session), CONNECT_ONE_SHOT)
	# Le catalogue peut encore contenir une référence de la scène qui vient de fermer.
	for ennemi in CatalogueEnnemis.ennemis:
		if is_instance_valid(ennemi): _suivre_ennemi(ennemi)
	for victime in get_tree().get_nodes_in_group("victime"): _suivre_victime(victime)

func bilan_vide() -> Dictionary:
	return {"temps": 0.0, "vague_atteinte": 0, "vagues_terminees": 0,
		"ennemis_elimines": 0, "victimes_liberees": 0, "victimes_perdues": 0,
		"victimes_abritees": 0, "victimes_escorte": 0, "degats_infliges": 0.0,
		"degats_recus": 0.0, "pieces_collectees": 0, "points_depenses": 0,
		"ameliorations_choisies": 0}

func _process(delta: float) -> void:
	# Process Mode hérité : les pauses de boutique, Carnet et Options ne comptent pas.
	if actif and not get_tree().paused and is_instance_valid(niveau): compteurs.temps += delta

func _noeud_ajoute(noeud: Node) -> void:
	if actif and noeud is CharacterBody3D:
		# Attendre les groupes et les signaux initialisés dans _ready().
		_suivre_victime_differee.call_deferred(noeud.get_instance_id(), session)

func _suivre_victime_differee(id: int, numero: int) -> void:
	if not actif or numero != session: return
	var victime = instance_from_id(id)
	if is_instance_valid(victime): _suivre_victime(victime)

func _suivre_victime(victime: Node) -> void:
	if not actif or not victime.is_in_group("victime") or not victime.has_signal("freed"): return
	if not is_instance_valid(niveau) or not niveau.is_ancestor_of(victime): return
	var id := victime.get_instance_id()
	if victimes_suivies.has(id): return
	victimes_suivies[id] = true
	victime.freed.connect(_victime_liberee.bind(session), CONNECT_ONE_SHOT)
	victime.died.connect(_victime_morte.bind(session), CONNECT_ONE_SHOT)

func _suivre_ennemi(ennemi: Node3D) -> void:
	if not actif or not is_instance_valid(ennemi) or not is_instance_valid(niveau): return
	if not niveau.is_ancestor_of(ennemi): return
	var id := ennemi.get_instance_id()
	if ennemis_suivis.has(id): return
	ennemis_suivis[id] = true
	# Seul died compte ; les copies visuelles et les nettoyages de scène sont exclus.
	ennemi.died.connect(_ennemi_mort.bind(session), CONNECT_ONE_SHOT)
	if ennemi.has_signal("degats_subis"):
		ennemi.degats_subis.connect(_degats_infliges.bind(session))

func _brancher_refuge() -> void:
	if not actif or not is_instance_valid(niveau): return
	var refuge = niveau.get_node("Salles/RoomManager").refuge
	refuge.victime_perdue.connect(_occupant_perdu.bind(session))

func _ennemi_mort(numero: int) -> void:
	if actif and numero == session: compteurs.ennemis_elimines += 1

func _victime_liberee(_victime: Node, numero: int) -> void:
	if actif and numero == session: compteurs.victimes_liberees += 1

func _victime_morte(_victime: Node, numero: int) -> void:
	_occupant_perdu(numero)

func _occupant_perdu(numero: int) -> void:
	if actif and numero == session: compteurs.victimes_perdues += 1

func _degats_infliges(quantite: float, numero: int) -> void:
	if actif and numero == session: compteurs.degats_infliges += maxf(quantite, 0.0)

func _degats_recus(quantite: float, numero: int) -> void:
	if actif and numero == session: compteurs.degats_recus += maxf(quantite, 0.0)

func _solde_change(solde: int, numero: int) -> void:
	if not actif or numero != session: return
	compteurs.pieces_collectees += maxi(0, solde - solde_precedent)
	solde_precedent = solde

func noter_achat(points: int) -> void:
	if actif: compteurs.points_depenses += maxi(0, points)

func noter_amelioration() -> void:
	if actif: compteurs.ameliorations_choisies += 1

func terminer() -> void:
	if not actif or not is_instance_valid(niveau): return
	var vagues = niveau.get_node("Salles/RoomManager")
	compteurs.vague_atteinte = vagues.vague_actuelle
	compteurs.vagues_terminees = vagues.vagues_terminees
	if is_instance_valid(vagues.refuge): compteurs.victimes_abritees = vagues.refuge.victimes.size()
	for victime in niveau.get_node("VictimManager").freed_victims:
		if is_instance_valid(victime) and not victime.est_morte:
			compteurs.victimes_escorte += 1
	# La scène de combat va disparaître. Garder uniquement des nombres pour le bilan.
	dernier_bilan = compteurs.duplicate(true)
	actif = false
	_enregistrer_records()

func _enregistrer_records() -> void:
	var nouveaux: Array[String] = []
	var fichier := ConfigFile.new()
	for id in RECORDS:
		var valeur: float = dernier_bilan[id]
		if valeur > float(records.get(id, 0.0)):
			records[id] = valeur
			nouveaux.append(id)
		fichier.set_value("records", id, records.get(id, 0.0))
	dernier_bilan["nouveaux_records"] = nouveaux
	var erreur := fichier.save(FICHIER_RECORDS)
	if erreur != OK: push_warning("Impossible de sauvegarder les records : %s" % error_string(erreur))

func _partie_retiree(numero: int) -> void:
	# Une ancienne scène ne doit pas arrêter le suivi d'une nouvelle partie.
	if numero == session:
		actif = false
		niveau = null

func formater_duree(secondes: float) -> String:
	var total := maxi(0, int(secondes))
	if total >= 3600: return "%d h %02d min %02d s" % [total / 3600, (total / 60) % 60, total % 60]
	return "%d min %02d s" % [total / 60, total % 60]
