extends Node

const CLE_BILAN := "bilan_intervention_classique"
var compteurs := bilan_vide()
var termine := false
var commence := false
var partiel := false
var suivis: Dictionary = {}
var salles_terminees: Dictionary = {}
@onready var niveau := get_parent()
@onready var gestion = niveau.get_node("Salles/RoomManager")

static func bilan_vide() -> Dictionary:
	return {"temps": 0.0, "salles_liberees": 0, "etage_atteint": 1,
		"ennemis_elimines": 0, "victimes_liberees": 0, "victimes_perdues": 0,
		"victimes_escorte": 0, "victimes_evacuees": 0, "degats_infliges": 0.0,
		"degats_recus": 0.0, "points_depenses": 0, "ameliorations_choisies": 0}

func _ready() -> void:
	if get_tree().has_meta(CLE_BILAN): get_tree().remove_meta(CLE_BILAN)
	gestion.salle_commencee.connect(_salle_commencee)
	gestion.salle_terminee.connect(_salle_terminee)
	niveau.get_node("player").degats_recus.connect(_ajouter.bind("degats_recus"))
	niveau.get_node("UpgradeManager").points_depenses.connect(_ajouter.bind("points_depenses"))
	niveau.get_node("UpgradeManager").amelioration_acquise.connect(_amelioration_acquise)
	get_tree().node_added.connect(_noeud_ajoute)
	for groupe in ["enemies", "victime"]:
		for noeud in get_tree().get_nodes_in_group(groupe): _suivre(noeud.get_instance_id())

func _process(delta: float) -> void:
	if commence and not termine and not get_tree().paused and not gestion.transition_en_cours:
		compteurs.temps += delta

func _noeud_ajoute(noeud: Node) -> void:
	if noeud is Node3D and niveau.is_ancestor_of(noeud):
		_suivre.call_deferred(noeud.get_instance_id())

func _suivre(id: int) -> void:
	var noeud := instance_from_id(id)
	if not is_instance_valid(noeud) or not niveau.is_ancestor_of(noeud) or suivis.has(id): return
	if noeud.is_in_group("enemies") and noeud.has_signal("died"):
		suivis[id] = true
		noeud.died.connect(_ennemi_mort, CONNECT_ONE_SHOT)
		if noeud.has_signal("degats_subis"):
			noeud.degats_subis.connect(_ajouter.bind("degats_infliges"))
	elif noeud.is_in_group("victime") and noeud.has_signal("freed"):
		suivis[id] = true
		noeud.freed.connect(_victime_liberee, CONNECT_ONE_SHOT)
		noeud.died.connect(_victime_perdue, CONNECT_ONE_SHOT)

func _ajouter(valeur: float, cle: String) -> void:
	if not termine: compteurs[cle] += maxf(0.0, valeur)

func _ennemi_mort() -> void:
	_ajouter(1, "ennemis_elimines")

func _victime_liberee(_victime: Node) -> void:
	_ajouter(1, "victimes_liberees")

func _victime_perdue(_victime: Node) -> void:
	_ajouter(1, "victimes_perdues")

func _amelioration_acquise(_identifiant: StringName) -> void:
	_ajouter(1, "ameliorations_choisies")

func _salle_commencee(salle: Node3D) -> void:
	commence = true
	compteurs.etage_atteint = salle.etage

func _salle_terminee(salle: Node3D) -> void:
	var id := salle.get_instance_id()
	if salles_terminees.has(id): return
	salles_terminees[id] = true
	_ajouter(1, "salles_liberees")

func capturer() -> Dictionary:
	return {"compteurs": compteurs.duplicate(true), "partiel": partiel}

func restaurer(etat: Dictionary, salles_deja_terminees: int) -> void:
	compteurs = bilan_vide()
	partiel = etat.is_empty() or bool(etat.get("partiel", false))
	# Une ancienne sauvegarde n'a pas l'historique des combats : ne pas l'inventer.
	if etat.is_empty():
		compteurs.salles_liberees = salles_deja_terminees
		return
	var valeurs: Dictionary = etat.get("compteurs", {})
	for cle in compteurs:
		var valeur: Variant = valeurs.get(cle, compteurs[cle])
		if valeur is int or valeur is float: compteurs[cle] = maxf(0.0, float(valeur))

func terminer(victoire: bool) -> void:
	if termine: return
	termine = true
	if is_instance_valid(gestion.salle_actuelle): compteurs.etage_atteint = gestion.salle_actuelle.etage
	compteurs.victimes_escorte = gestion.compter_victimes_escorte_vivantes()
	compteurs.victimes_evacuees = niveau.get_node("VictimManager").evacuated_count
	var bilan := compteurs.duplicate(true)
	bilan["victoire"] = victoire
	bilan["partiel"] = partiel
	bilan["salle_atteinte"] = gestion.indice_salle + 1
	bilan["nombre_salles"] = gestion.nombre_salles
	get_tree().set_meta(CLE_BILAN, bilan)
