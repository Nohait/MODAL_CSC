extends "res://scenes/jeu/main.gd"

signal salle_prete
const SBIRE = preload("res://scenes/ennemis/mobiles/sbire.tscn")
@export var debut_autonome := false
@export var debut_ravitaillement := false
@export var debut_sauvetage_menace := false
@export_group("Rencontres du tutoriel")
@export_range(10.0, 100.0, 5.0) var vie_creature := 65.0
@export_range(1.0, 7.0, 0.1) var vitesse_creature := 2.4
@export_range(1.0, 20.0, 1.0) var degats_creature := 8.0
@export_range(1.5, 4.0, 0.1) var distance_ouverture_sortie := 2.2
@onready var salle = $SalleFixe
@onready var progression = $ProgressionCombat
var observation: CharacterBody3D
var entree_en_cours := false
var chef: Node3D
var pratique
var progression_pratique
var entree_pratique := false
var poste
var menace
var sortie_en_cours := false

func _ready() -> void:
	session_tutoriel = true
	var gestion = $Salles/RoomManager
	gestion.process_mode = Node.PROCESS_MODE_DISABLED
	gestion.get_node("InterfaceSalle").hide()
	gestion.salle_actuelle = salle
	$Salles/RoomGenerator.process_mode = Node.PROCESS_MODE_DISABLED
	$InterfaceTest.hide()
	$MenuDebug.process_mode = Node.PROCESS_MODE_DISABLED
	$player.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	$player.global_position = Vector3(0, 1, 7)
	$CameraRig.recentrer()
	$player/SecondaryAttack.process_mode = Node.PROCESS_MODE_DISABLED
	var attaque = $player/SecondaryAttack.get_child(0)
	if is_instance_valid(attaque.icone): attaque.icone.hide()
	progression.consigne_changee.connect(_actualiser_consigne)
	progression.rencontre_demandee.connect(_creer_rencontre)
	progression.sortie_autorisee.connect(salle.autoriser_sortie)
	progression.fin_provisoire = false
	progression.salle_reussie.connect(_passer_pratique)
	if debut_autonome:
		pratique = preload("res://scenes/modes/tutoriel/05_06_combat/decor_combat_autonome.gd").new()
		salle.add_child(pratique)
	if debut_ravitaillement:
		poste = preload("res://scenes/modes/tutoriel/07_ravitaillement/poste_ravitaillement.gd").new()
		salle.add_child(poste)
		poste.consigne_changee.connect(_actualiser_consigne)
	var salle_id: StringName = &"menace" if debut_sauvetage_menace else (&"poste" if debut_ravitaillement else (&"pratique" if debut_autonome else &"combat"))
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).installer(self, salle_id)
	progression.preparer($player)
	if debut_sauvetage_menace:
		$player.global_position = Vector3(0, 1, -47.5)
		$CameraRig.recentrer()
		_ouvrir_menace()
	elif debut_ravitaillement:
		$player.global_position = Vector3(0, 1, -33)
		$CameraRig.recentrer()
		_ouvrir_poste()
	elif debut_autonome:
		# Le plan fixe conserve ses propres repères de départ.
		$player.global_position = Vector3(0, 1, -13)
		$CameraRig.recentrer()
		_preparer_pratique()
	else:
		observation = _creer_sbire(true)
		chef = preload("res://scenes/modes/tutoriel/commun/figurants/figurant_pompier.gd").new()
		chef.position = Vector3(-1.8, 1, 6)
		salle.add_child(chef)
		chef.installer_modele($player)
		chef.parler("Il y a une créature derrière cette porte. La mousse peut l’arrêter, mais ne la laisse pas t’approcher. Garde assez de réserve pour te défendre. Je couvre tes arrières.", $player, $CameraRig/Camera3D)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await preload("res://scenes/modes/tutoriel/debug/menu_tutoriel.gd").installer(self)
	Reglages.chargement.terminer()
	salle_prete.emit()

func debug_contexte() -> Dictionary:
	if is_instance_valid(menace):
		var id_carte: String = String($UpgradeManager.acquisitions[0].id) if not $UpgradeManager.acquisitions.is_empty() else "pression"
		var contexte_menace := {"salle": "Sauvetage sous menace", "etape": "réussi" if menace.progression.reussi else ("échec" if menace.progression.perdu else ("combat" if menace.progression.liberee else "liberation")), "objectif": menace.progression.consigne(), "joueur": $player, "victime": menace.victime, "escorte": $VictimManager, "ennemi": menace.ennemi, "foyers": [], "sortie": "zone sûre", "restart_etape": "menace_" + id_carte, "restart_salle": "menace_" + id_carte, "reperes": [Vector3(-2, 0, -51), Vector3(3, 0, -58), Vector3(10, 0, -64)]}
		contexte_menace.merge(preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd").conditions({"Victime libérée": menace.progression.liberee, "Sbire vaincu": menace.progression.vaincu, "Arrivée ensemble vivant": menace.progression.reussi}))
		return contexte_menace
	if is_instance_valid(poste) and poste.actif:
		var resultat_poste := {"salle": "Poste de ravitaillement", "etape": "essai" if poste.carte != &"" else "ravitaillement", "objectif": poste.consigne(), "joueur": $player, "escorte": $VictimManager, "foyers": [], "sortie": "ouverte" if poste.sortie_ouverte else "attend le choix", "restart_etape": "poste" if poste.carte == &"" else "essai_" + String(poste.carte), "restart_salle": "poste", "reperes": [Vector3(-2, 1, -34), Vector3(3, 0, -37), Vector3(0, 0, -46)]}
		resultat_poste.merge(preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd").conditions({"Carte acquise": poste.carte != &"", "Sortie atteinte vivant": poste.termine}))
		return resultat_poste
	var autonome := is_instance_valid(progression_pratique)
	var actuelle = progression_pratique if autonome else progression
	var identifiant := "pratique" if autonome else "combat"
	var conditions := {"Joueur vivant": $player.BarreDeVie.value > 0, "Porte ouverte": pratique.porte_combat.ouverte if autonome else salle.porte_combat.ouverte, "Créature vaincue": actuelle.rencontres_terminees > 0, "Sortie atteinte vivant": actuelle.etat == "reussi"}
	var sortie_ouverte: bool = pratique.sortie.ouverte if autonome else salle.sortie.ouverte
	var resultat := {"salle": "Combat autonome" if autonome else "Premier combat", "etape": actuelle.etat, "objectif": actuelle.consigne(), "joueur": $player, "escorte": $VictimManager, "ennemi": actuelle.ennemi, "foyers": [], "sortie": "ouverte" if sortie_ouverte else ("autorisée" if actuelle.etat == "sortie" else "verrouillée"), "restart_etape": identifiant + ":" + actuelle.etat, "restart_salle": identifiant, "reperes": [Vector3(0, 0, -13), Vector3(0, 0, -16), Vector3(0, 0, -30)] if autonome else [Vector3(0, 0, 7), Vector3(0, 0, 3.5), Vector3(0, 0, -10)]}
	resultat.merge(preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd").conditions(conditions))
	resultat["ennemis_restants"] = int(is_instance_valid(observation) and not observation.est_mort) + int(is_instance_valid(actuelle.ennemi) and not actuelle.ennemi.est_mort)
	return resultat

func debug_reconstruire(identifiant: String) -> void:
	if identifiant.begins_with("menace_"):
		var id: StringName = StringName(identifiant.trim_prefix("menace_").get_slice(":", 0))
		$UpgradeManager.acquerir_formation_debug(id)
		menace.cartes_depart = $UpgradeManager.capturer_sauvegarde().duplicate(true)
		if identifiant.ends_with(":liberee"): menace.victime.free_victim()
		return
	if identifiant == "poste" or identifiant.begins_with("essai_"):
		if identifiant.begins_with("essai_"):
			$UpgradeManager.acquerir_formation_debug(StringName(identifiant.trim_prefix("essai_")))
		return
	var etat_depart := identifiant.get_slice(":", 1)
	if etat_depart.is_empty() or etat_depart == "observation": return
	if debut_autonome:
		await _entrer_pratique()
	else:
		await _entrer()
	if etat_depart in ["sortie", "transition", "reussi"]:
		var actuelle = progression_pratique if debut_autonome else progression
		if is_instance_valid(actuelle.ennemi): actuelle.ennemi.prendre_degats(actuelle.ennemi.vie + 1, &"mousse")

func _creer_sbire(apercu := false, conteneur: Node3D = null, emplacement := Vector3(0, 0, -2)) -> CharacterBody3D:
	var creature = SBIRE.instantiate()
	creature.position = emplacement
	creature.vitesse_sbire = vitesse_creature
	creature.vie_max = vie_creature
	creature.degats_sbire = degats_creature
	creature.rayon_idle = 2.0
	creature.distance_detection = 0.1 if apercu else 12.0
	# Le _ready du sbire adapte cette forme : isoler celle de chaque instance.
	var detection: CollisionShape3D = creature.get_node("SurfaceDetection/CollisionShape3D")
	detection.shape = detection.shape.duplicate()
	if apercu:
		creature.degats_sbire = 0
		creature.collision_layer = 0
		creature.remove_from_group("enemies")
		# Aucun corps détectable, mais get_overlapping_bodies reste utilisable par le sbire.
		creature.get_node("SurfaceDetection").monitoring = true
		creature.get_node("SurfaceDetection").collision_mask = 0
	(salle.ennemis if conteneur == null else conteneur).add_child(creature)
	if apercu: creature.set_physics_process(false)
	return creature

func _creer_rencontre(progression_cible: Node = null) -> void:
	if is_instance_valid(observation):
		# Activer le sbire déjà visible, sans disparition ni nouvelle apparition.
		observation.degats_sbire = degats_creature
		observation.collision_layer = 4
		observation.add_to_group("enemies")
		observation.distance_detection = 12
		observation.detection_shape.shape.radius = 12
		observation.SurfaceDetection.collision_mask = 31
		observation.SurfaceDetection.monitoring = true
		(progression if progression_cible == null else progression_cible).surveiller(observation)
		observation = null

func _entrer() -> void:
	entree_en_cours = true
	salle.ouvrir_palier()
	if not salle.porte_combat.ouverte: await salle.porte_combat.ouverture_terminee
	if $player.BarreDeVie.value <= 0: return
	chef.terminer_dialogue()
	progression.commencer()

func _process(_delta: float) -> void:
	if is_instance_valid(menace): return
	if is_instance_valid(poste) and poste.actif: return
	if is_instance_valid(observation) and not observation.is_physics_processing():
		if NavigationServer3D.map_get_iteration_id(observation.navigation_agent.get_navigation_map()) > 0:
			observation.set_physics_process(true)
	if is_instance_valid(progression_pratique):
		if progression_pratique.etat == "observation" and not entree_pratique:
			if $player.global_position.distance_to(Vector3(0, 1, -15.2)) < 1.8 and Input.is_action_just_pressed("interact"):
				_entrer_pratique()
		elif progression_pratique.etat == "sortie" and _porte_proche(pratique.sortie) and Input.is_action_just_pressed("interact"):
			_quitter_par_porte(progression_pratique, pratique)
	elif progression.etat == "observation" and not entree_en_cours:
		if $player.global_position.distance_to(Vector3(0, 1, 4.2)) < 1.8 and Input.is_action_just_pressed("interact"):
			_entrer()
	elif progression.etat == "sortie" and _porte_proche(salle.sortie) and Input.is_action_just_pressed("interact"):
		_quitter_par_porte(progression, salle)

func _porte_proche(porte: Node3D) -> bool:
	var ecart: Vector3 = $player.global_position - porte.global_position
	ecart.y = 0.0
	return ecart.length() < distance_ouverture_sortie

func _quitter_par_porte(progression_cible: Node, decor: Node3D) -> void:
	if sortie_en_cours or decor.sortie.ouverte: return
	sortie_en_cours = true
	decor.masquer_repere_sortie()
	decor.sortie.ouvrir()
	if not decor.sortie.ouverte: await decor.sortie.ouverture_terminee
	if $player.BarreDeVie.value <= 0: return
	progression_cible.atteindre_sortie()

func _actualiser_consigne() -> void:
	if is_instance_valid(menace):
		$Briefing/Panneau/Disposition/Consigne.text = menace.rappel if not menace.rappel.is_empty() else menace.progression.consigne()
		$Briefing/Panneau/Disposition/Rappel.hide()
		return
	if is_instance_valid(poste) and poste.actif:
		$Briefing/Panneau/Disposition/Consigne.text = poste.consigne()
		$Briefing/Panneau/Disposition/Rappel.hide()
		return
	var actuelle = progression_pratique if is_instance_valid(progression_pratique) else progression
	$Briefing/Panneau/Disposition/Consigne.text = actuelle.consigne()
	$Briefing/Panneau/Disposition/Rappel.text = actuelle.rappel
	$Briefing/Panneau/Disposition/Rappel.visible = not actuelle.rappel.is_empty()

func _preparer_pratique() -> void:
	if is_instance_valid(progression_pratique): return
	# Le joueur reste le même : vie, réserve et récupération naturelle sont conservées.
	progression_pratique = preload("res://scenes/modes/tutoriel/05_06_combat/progression_combat.gd").new()
	progression_pratique.autonome = true
	progression_pratique.name = "ProgressionPratique"
	add_child(progression_pratique)
	progression_pratique.consigne_changee.connect(_actualiser_consigne)
	progression_pratique.rencontre_demandee.connect(_creer_rencontre.bind(progression_pratique))
	progression_pratique.sortie_autorisee.connect(pratique.autoriser_sortie)
	progression_pratique.salle_reussie.connect(_passer_poste)
	observation = _creer_sbire(true, pratique.ennemis, pratique.POSITION_CREATURE)
	$Briefing/Panneau/Disposition/Titre.text = "06 · DÉGAGER LE PASSAGE"
	progression_pratique.preparer($player)

func _entrer_pratique() -> void:
	entree_pratique = true
	pratique.ouvrir_palier()
	if not pratique.porte_combat.ouverte: await pratique.porte_combat.ouverture_terminee
	if $player.BarreDeVie.value <= 0: return
	progression_pratique.commencer()

func _ouvrir_poste() -> void:
	poste.preparer($player, $UpgradeManager, $CameraRig/Camera3D)
	if not poste.salle_reussie.is_connected(_passer_menace): poste.salle_reussie.connect(_passer_menace)
	$Briefing/Panneau/Disposition/Titre.text = "07 · RAVITAILLEMENT ET ÉQUIPEMENT"
	_actualiser_consigne()

func _ouvrir_menace() -> void:
	if is_instance_valid(menace): return
	menace = preload("res://scenes/modes/tutoriel/08_sauvetage_sous_menace/08_sauvetage_sous_menace.gd").new()
	add_child(menace)
	menace.consigne_changee.connect(_actualiser_consigne)
	menace.salle_reussie.connect(_passer_points, CONNECT_ONE_SHOT)
	menace.preparer($player, $VictimManager, $UpgradeManager)
	$Briefing/Panneau/Disposition/Titre.text = "08 · SAUVETAGE SOUS MENACE"
	_actualiser_consigne()

func afficher_ecran_mort() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).afficher_echec(self, "Vous n’avez pas pu poursuivre l’intervention.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).recommencer()

func _passer_pratique() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).ouvrir_salle(self, &"pratique")

func _passer_poste() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).ouvrir_salle(self, &"poste")

func _passer_menace() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).ouvrir_salle(self, &"menace")

func _passer_points() -> void:
	# La victime précédente a été confiée à l'équipe ; cette séquence constitue une nouvelle escorte.
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).ouvrir_salle(self, &"points_1", false)
