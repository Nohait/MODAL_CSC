extends "res://scenes/jeu/main.gd"

signal salle_prete
@export_range(1.5, 4.0, 0.1) var distance_ouverture_sortie := 1.8
@onready var progression = $ProgressionSauvetage
@onready var salle: Node3D = $SalleFixe
@onready var victime: CharacterBody3D = $SalleFixe/Victimes/Habitant
var releve: Node3D
var passage_salle_suivante := false
var porte_suivante: StaticBody3D
var repere_sortie: Node3D

func _ready() -> void:
	# Le socle commun est conservé, mais aucun parcours ni point de reprise classique n’est lancé.
	session_tutoriel = true
	var gestion = $Salles/RoomManager
	gestion.process_mode = Node.PROCESS_MODE_DISABLED
	gestion.get_node("InterfaceSalle").hide()
	gestion.salle_actuelle = salle
	$Salles/RoomGenerator.process_mode = Node.PROCESS_MODE_DISABLED
	$InterfaceTest.hide()
	$MenuDebug.process_mode = Node.PROCESS_MODE_DISABLED
	$player.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	$player.global_position = $SalleFixe/Depart.global_position
	$CameraRig.recentrer()
	$player/SecondaryAttack.process_mode = Node.PROCESS_MODE_DISABLED
	var attaque = $player/SecondaryAttack.get_child(0)
	if is_instance_valid(attaque.icone): attaque.icone.hide()
	victime.set_ennemis_container($SalleFixe/Ennemis)
	$VictimManager.surveiller_victime(victime)
	victime.died.connect(func(_victime): preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).afficher_echec(self, "L’habitant n’a pas survécu."), CONNECT_ONE_SHOT)
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).installer(self, &"sauvetage")
	_preparer_navigation()
	var decor = preload("res://scenes/modes/tutoriel/04_premier_sauvetage/appartements_mitoyens.gd").new()
	salle.add_child(decor)
	preload("res://scenes/modes/tutoriel/04_premier_sauvetage/habillage_sauvetage.gd").installer(salle)
	progression.consigne_changee.connect(_actualiser_consigne)
	progression.preparer($player, victime, $VictimManager, $SalleFixe/Passage, $SalleFixe/Arrivee)
	releve = preload("res://scenes/modes/tutoriel/04_premier_sauvetage/prise_en_charge_victime.gd").new()
	add_child(releve)
	releve.preparer($player, $SalleFixe/Arrivee)
	_preparer_porte_suivante()
	progression.premier_sauvetage_reussi.connect(_prendre_relais)
	releve.prise_en_charge_terminee.connect(_confirmer_relais)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await preload("res://scenes/modes/tutoriel/debug/menu_tutoriel.gd").installer(self)
	Reglages.chargement.terminer()
	salle_prete.emit()

func debug_contexte() -> Dictionary:
	var disponible: bool = is_instance_valid(victime) and not victime.est_morte
	var conditions := {"Joueur vivant": $player.BarreDeVie.value > 0, "Victime libérée": disponible and victime.is_freed, "Passage dégagé": progression.passage.degage, "Joueur dans la zone": progression._dans_repere($player), "Victime dans la zone": disponible and progression._dans_repere(victime), "Prise en charge terminée": releve.terminee}
	var actuelle: String = progression.etat()
	var identifiant := "liberation" if actuelle == "liberation" else ("passage" if actuelle == "extinction" else "escorte")
	var foyers: Array = []
	for foyer in progression.passage.foyers.get_children(): foyers.append(foyer.get_node("Extinction"))
	var resultat := {"salle": "Sauvetage", "etape": actuelle, "objectif": progression.consigne(), "joueur": $player, "victime": victime, "escorte": $VictimManager, "foyers": foyers, "prises_en_charge": int(releve.terminee), "passage": "dégagé" if progression.passage.degage else "bloqué", "sortie": "accessible" if releve.terminee else "attend la prise en charge", "restart_etape": identifiant, "restart_salle": "liberation", "reperes": [$SalleFixe/Depart.global_position, $SalleFixe/Arrivee.global_position, progression.passage.global_position]}
	resultat.merge(preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd").conditions(conditions))
	resultat["foyers_exercice"] = foyers if actuelle == "extinction" else []
	return resultat

func debug_reconstruire(identifiant: String) -> void:
	if identifiant == "liberation": return
	victime.free_victim()
	$player.global_position = Vector3(0, 1, -2.5)
	victime.global_position = Vector3(-0.5, 0.75, -1.5)
	if identifiant == "escorte":
		for foyer in progression.passage.foyers.get_children():
			var extinction = foyer.get_node("Extinction")
			extinction.recevoir_mousse(extinction.duree_extinction + 0.01)
		$player.global_position = Vector3(0, 1, -12.3)
		victime.global_position = Vector3(0, 0.75, -11.8)
	$CameraRig.recentrer()
	_actualiser_consigne()

func _preparer_navigation() -> void:
	# Le couloir est interrompu au brasier ; son lien s'active seulement à l'ouverture.
	var navigation := NavigationMesh.new()
	navigation.vertices = PackedVector3Array([
		Vector3(-3.4, 0, 3.4), Vector3(3.4, 0, 3.4), Vector3(3.4, 0, -3.4),
		Vector3(1.05, 0, -3.4), Vector3(-1.05, 0, -3.4), Vector3(-3.4, 0, -3.4),
		Vector3(1.05, 0, -12.6), Vector3(-1.05, 0, -12.6),
		Vector3(3.4, 0, -12.6), Vector3(3.4, 0, -17.4),
		Vector3(-3.4, 0, -17.4), Vector3(-3.4, 0, -12.6),
		Vector3(1.05, 0, -5.5), Vector3(-1.05, 0, -5.5),
		Vector3(-1.05, 0, -6.5), Vector3(1.05, 0, -6.5)])
	navigation.add_polygon(PackedInt32Array([0, 1, 2, 3, 4, 5]))
	navigation.add_polygon(PackedInt32Array([4, 3, 12, 13]))
	navigation.add_polygon(PackedInt32Array([14, 15, 6, 7]))
	navigation.add_polygon(PackedInt32Array([7, 6, 8, 9, 10, 11]))
	$SalleFixe/Navigation.navigation_mesh = navigation

func _actualiser_consigne() -> void:
	$Briefing/Panneau/Marge/Disposition/Consigne.text = progression.consigne()
	$Briefing/Panneau/Marge/Disposition/Rappel.text = progression.rappel()
	$Briefing/Panneau/Marge/Disposition/Rappel.visible = not progression.rappel().is_empty()

func _prendre_relais() -> void:
	releve.prendre_en_charge(victime, $VictimManager)
	$Briefing/Panneau/Marge/Disposition/Consigne.text = "Le pompier accueille l’habitant dans la zone sécurisée."

func _confirmer_relais() -> void:
	releve.parler("Je m’occupe de la victime. Continue, il reste du monde à l’intérieur.", $player, $CameraRig/Camera3D)
	$Briefing/Panneau/Marge/Disposition/Consigne.text = "L’habitant est pris en charge. Continuez la recherche."
	$Briefing/Panneau/Marge/Disposition/Rappel.text = "Ouvrez la porte au fond du palier · E."
	$Briefing/Panneau/Marge/Disposition/Rappel.show()
	repere_sortie.show()

func _preparer_porte_suivante() -> void:
	# Ouvrir une véritable embrasure dans le fond du palier, sans changer la scène commune.
	var fond = salle.get_node("PalierFond")
	var materiau = fond.get_node("Visuel").mesh.material
	fond.queue_free()
	for cote in [-1, 1]:
		var mur := StaticBody3D.new()
		mur.position = Vector3(cote * 3.05, 1.8, -18.15)
		var visuel := MeshInstance3D.new()
		var mesh := BoxMesh.new()
		mesh.size = Vector3(2.5, 3.6, 0.3)
		mesh.material = materiau
		visuel.mesh = mesh
		mur.add_child(visuel)
		var collision := CollisionShape3D.new()
		var forme := BoxShape3D.new()
		forme.size = mesh.size
		collision.shape = forme
		mur.add_child(collision)
		salle.add_child(mur)
	porte_suivante = preload("res://scenes/modes/tutoriel/commun/decors/double_porte.tscn").instantiate()
	porte_suivante.position = Vector3(0, 1.8, -18.15)
	salle.add_child(porte_suivante)
	repere_sortie = preload("res://scenes/modes/tutoriel/commun/decors/repere_passage.tscn").instantiate()
	repere_sortie.position = Vector3(0, 0, -16.45)
	repere_sortie.hide()
	salle.add_child(repere_sortie)

func _process(_delta: float) -> void:
	if not is_instance_valid(releve) or not releve.terminee or passage_salle_suivante: return
	if $player.global_position.distance_to(Vector3(0, 1, -17)) < distance_ouverture_sortie and Input.is_action_just_pressed("interact"):
		passage_salle_suivante = true
		repere_sortie.hide()
		porte_suivante.ouvrir()
		if not porte_suivante.ouverte: await porte_suivante.ouverture_terminee
		if $player.BarreDeVie.value <= 0: return
		preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).ouvrir_salle(self, &"combat")

func afficher_ecran_mort() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).afficher_echec(self, "Vous êtes tombé pendant le sauvetage.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).recommencer()
