extends "res://scenes/jeu/main.gd"

const ETAPE = preload("res://scenes/modes/tutoriel/00_03_parvis/etapes/etape_tutoriel.gd")
const ANIMATIONS_FIGURANT = preload("res://scenes/modes/tutoriel/commun/figurants/animations_figurant.gd")
@export_group("Rencontre")
@export_range(1.0, 5.0, 0.1) var distance_conversation := 3.2
@export_range(0.5, 4.0, 0.1) var vitesse_superieur := 1.2
@export_range(0.2, 2.0, 0.1) var duree_fondu_interface := 1.0
@export_group("Ambiance")
@export_range(0.0, 1.0, 0.05) var lumiere_ambiante := 0.25

@onready var progression = $Progression
@onready var superieur: Node3D = $Intervention/Superieur
@onready var objectif: Label = $Briefing/Objectif/Marge/Disposition/Consigne
@onready var titre: Label = $Briefing/Objectif/Marge/Disposition/Titre
@onready var dialogue: PanelContainer = $Briefing/Dialogue
@onready var invitation: Label = $Briefing/Invitation
var modele_superieur: Node3D
var arbre_superieur: AnimationTree
var allure_superieur := 0.0
var arrive := false
var changement := false

func _ready() -> void:
	# Garder les composants communs, mais ne pas lancer le générateur du classique dehors.
	$Salles/RoomManager.process_mode = Node.PROCESS_MODE_DISABLED
	$Salles/RoomManager/InterfaceSalle.hide()
	$InterfaceTest.hide()
	$MenuDebug.process_mode = Node.PROCESS_MODE_DISABLED
	$player.died.connect(_on_player_died, CONNECT_ONE_SHOT)
	$player.global_position = $Intervention/Depart.global_position
	$CameraRig.recentrer()
	$Eclairage.process_mode = Node.PROCESS_MODE_DISABLED
	$Eclairage/Ambiance.environment = $Eclairage/Ambiance.environment.duplicate()
	$Eclairage/Ambiance.environment.ambient_light_energy = lumiere_ambiante
	$Eclairage/Soleil.light_energy = 0.25
	# La bouche est teasée au briefing ; son apprentissage viendra après celui de la mousse.
	var secondaire = $player.get_node("SecondaryAttack")
	secondaire.process_mode = Node.PROCESS_MODE_DISABLED
	var attaque = secondaire.get_child(0)
	if is_instance_valid(attaque.icone): attaque.icone.hide()
	_creer_superieur()
	dialogue.acteur = superieur
	dialogue.camera = $CameraRig/Camera3D
	var foyers: Array[Node] = [$Intervention/FoyerExercice1/Extinction, $Intervention/FoyerExercice2/Extinction]
	progression.etat_change.connect(_actualiser_briefing)
	progression.preparation_terminee.connect(_entrer)
	progression.preparer($player, foyers, $Intervention/RepereDash)
	Input.set_custom_mouse_cursor(preload("res://assets/textures/interfaces/curseurs/curseur_lance.svg"), Input.CURSOR_POINTING_HAND, Vector2(3, 3))
	# Le fondu introduit le décor, sans immobiliser le personnage.
	for panneau in [$Briefing/Objectif, $Briefing/Dialogue, $Briefing/Invitation]:
		panneau.modulate.a = 0.0
		create_tween().tween_property(panneau, "modulate:a", 1.0, duree_fondu_interface)
	await get_tree().physics_frame
	await get_tree().physics_frame
	await preload("res://scenes/modes/tutoriel/debug/menu_tutoriel.gd").installer(self)
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).installer(self, &"parvis")
	Reglages.chargement.terminer()

func debug_contexte() -> Dictionary:
	var actuelle = progression.etape()
	var conditions := {"Conversation terminée": progression.dialogue_termine}
	if actuelle != null:
		match actuelle.objectif:
			ETAPE.Objectif.FOYERS: conditions["Foyers éteints"] = progression.foyers_eteints() == progression.foyers.size()
			ETAPE.Objectif.RESERVE:
				conditions["Réserve sollicitée"] = progression.reserve_sollicitee
				conditions["Réserve récupérée"] = $player.extincteur.charge >= $player.extincteur.max_charge * progression.seuil_recharge
			ETAPE.Objectif.DASH: conditions["Dash dans le repère"] = progression.dash_reussi
			ETAPE.Objectif.ENTREE: conditions["Proximité de l’entrée"] = _pres_entree()
	var resultat := {"salle": "Parvis", "etape": actuelle.titre if actuelle != null else "Entrée", "objectif": actuelle.consigne if actuelle != null else "Entrer", "joueur": $player, "escorte": $VictimManager, "foyers": progression.foyers, "restart_etape": "parvis:" + str(progression.indice), "restart_salle": "parvis", "reperes": [$Intervention/Depart.global_position, $Intervention/RepereDash.global_position, $Intervention/Entree.global_position]}
	resultat.merge(preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd").conditions(conditions))
	resultat["foyers_exercice"] = progression.foyers if actuelle != null and actuelle.objectif == ETAPE.Objectif.FOYERS else []
	return resultat

func debug_reconstruire(identifiant: String) -> void:
	if identifiant.get_slice_count(":") < 2: return
	var indice := clampi(int(identifiant.get_slice(":", 1)), 0, progression.etapes.size() - 1)
	if indice == 0: return
	if indice >= 2:
		for foyer in progression.foyers: foyer.recevoir_mousse(foyer.duree_extinction + 0.01)
	progression.indice = indice
	progression.indice_replique = -1
	progression.dialogue_termine = false
	arrive = true
	allure_superieur = 0
	superieur.global_position = $Intervention/PositionBriefing.global_position
	$player.global_position = superieur.global_position + Vector3(0, 0, 2)
	$CameraRig.recentrer()
	progression.etat_change.emit()
	$Intervention/TeasingSauvetage.jouer($player)

func _creer_superieur() -> void:
	# Le modèle reste commun ; la marche et le repos sont propres à ce figurant.
	modele_superieur = $player.get_node("visual/pompier").duplicate()
	superieur.add_child(modele_superieur)
	modele_superieur.collision_layer = 0
	modele_superieur.collision_mask = 0
	arbre_superieur = ANIMATIONS_FIGURANT.installer(modele_superieur, true)
	modele_superieur.get_node("visual/Armature/Skeleton3D/Right_Hand_Holder/extincteur0").hide()

func _process(delta: float) -> void:
	var destination: Vector3 = $Intervention/PositionBriefing.global_position
	if not arrive:
		var direction := destination - superieur.global_position
		allure_superieur = move_toward(allure_superieur, minf(vitesse_superieur, direction.length() * 4.0), delta * 3.0)
		if direction.length() <= maxf(allure_superieur * delta, 0.005):
			superieur.global_position = destination
			arrive = true
		else:
			superieur.global_position += direction.normalized() * allure_superieur * delta
			ANIMATIONS_FIGURANT.orienter(superieur, superieur.get_parent().global_basis.inverse() * direction, delta)
	elif superieur.global_position.distance_to($player.global_position) < distance_conversation:
		var regard: Vector3 = $player.global_position
		regard.y = superieur.global_position.y
		ANIMATIONS_FIGURANT.orienter(superieur, superieur.get_parent().global_basis.inverse() * (regard - superieur.global_position), delta)
	ANIMATIONS_FIGURANT.actualiser(arbre_superieur, 0.0 if arrive else allure_superieur, delta)
	_actualiser_proximite()
	$Intervention/ZoneDash.visible = progression.etape() != null and progression.etape().objectif == ETAPE.Objectif.DASH and progression.dialogue_termine

func _unhandled_input(event: InputEvent) -> void:
	if changement or get_tree().paused or not event.is_action_pressed("interact") or event.is_echo(): return
	if _pres_entree() and progression.dialogue_termine:
		progression.entrer()
	elif arrive and _pres_superieur():
		if dialogue.visible and not dialogue.revelee():
			dialogue.terminer_phrase()
		else:
			progression.parler()
	else: return
	get_viewport().set_input_as_handled()

func _pres_superieur() -> bool:
	# Comparer au sol : la hauteur de la capsule ne doit pas réduire la portée de conversation.
	var ecart: Vector3 = $player.global_position - superieur.global_position
	ecart.y = 0.0
	return ecart.length() <= distance_conversation

func _pres_entree() -> bool:
	return progression.etape() != null and progression.etape().objectif == ETAPE.Objectif.ENTREE and $player.global_position.distance_to($Intervention/Entree.global_position) <= distance_conversation

func _actualiser_proximite() -> void:
	var pres := arrive and _pres_superieur()
	dialogue.visible = pres and progression.indice_replique >= 0
	if _pres_entree() and progression.dialogue_termine:
		invitation.text = "E · Entrer dans le bâtiment"
	elif pres:
		invitation.text = "E · " + ("Écouter la suite" if dialogue.visible and not dialogue.revelee() else ("Continuer la conversation" if not progression.replique().is_empty() else "Parler au chef"))
	else:
		invitation.text = "Approchez-vous du chef pour lui parler" if not progression.dialogue_termine else ""
	invitation.visible = not (dialogue.visible and not progression.dialogue_termine)
	$Intervention/Superieur/Invite.visible = pres and not dialogue.visible

func _actualiser_briefing() -> void:
	var actuelle = progression.etape()
	if actuelle == null: return
	titre.text = actuelle.titre
	objectif.text = actuelle.consigne if progression.dialogue_termine else "Parlez au chef d’intervention · E"
	if progression.indice == 0 and not progression.dialogue_termine:
		objectif.text = "Déplacez-vous avec ZQSD / WASD, puis parlez au chef · E"
	if progression.dialogue_termine and actuelle.objectif == ETAPE.Objectif.FOYERS:
		objectif.text += "  (%d / %d)" % [progression.foyers_eteints(), progression.foyers.size()]
	elif progression.dialogue_termine and actuelle.objectif == ETAPE.Objectif.RESERVE and progression.reserve_sollicitee:
		objectif.text = "Relâchez le clic gauche et laissez la réserve se reconstituer."
	dialogue.dialogue_interactif = not progression.dialogue_termine
	dialogue.afficher(actuelle.consigne if progression.dialogue_termine else progression.replique())
	if progression.indice == 0 and progression.indice_replique >= 1:
		$Intervention/TeasingSauvetage.jouer($player)
	_actualiser_proximite()

func _entrer() -> void:
	if changement: return
	changement = true
	$player.extincteur.stop_primary_attack()
	Reglages.chargement.chargement_echoue.connect(func(): changement = false, CONNECT_ONE_SHOT)
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).ouvrir_salle(self, &"sauvetage")

func afficher_ecran_mort() -> void:
	preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).afficher_echec(self, "Recommencez la préparation de votre intervention.")

func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_R:
		preload("res://scenes/modes/tutoriel/reprise/reprise_tutoriel.gd").obtenir(get_tree()).recommencer()
