extends "res://scenes/jeu/main.gd"

const ETAPE = preload("res://scenes/modes/tutoriel/etape_tutoriel.gd")
@export_group("Rencontre")
@export_range(1.0, 5.0, 0.1) var distance_conversation := 3.2
@export_range(0.5, 4.0, 0.1) var vitesse_superieur := 1.7
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
	Reglages.chargement.terminer()

func _creer_superieur() -> void:
	# Réutiliser exactement le modèle et les animations du collègue, sans copier l'arme active.
	modele_superieur = $player.get_node("visual/pompier").duplicate()
	superieur.add_child(modele_superieur)
	modele_superieur.collision_layer = 0
	modele_superieur.collision_mask = 0
	modele_superieur.get_node("visual/Armature/AnimationPlayer").stop()
	arbre_superieur = modele_superieur.get_node("visual/Armature/AnimationTree")
	arbre_superieur.active = true
	arbre_superieur["parameters/blend_position"] = Vector2.ZERO
	modele_superieur.get_node("visual/Armature/Skeleton3D/Right_Hand_Holder/extincteur0").hide()

func _process(delta: float) -> void:
	var destination: Vector3 = $Intervention/PositionBriefing.global_position
	if not arrive:
		var direction := destination - superieur.global_position
		if direction.length() <= vitesse_superieur * delta:
			superieur.global_position = destination
			arrive = true
		else:
			superieur.global_position += direction.normalized() * vitesse_superieur * delta
			superieur.look_at(superieur.global_position + direction, Vector3.UP)
		arbre_superieur["parameters/blend_position"] = Vector2(0, 0.45) if not arrive else Vector2.ZERO
	elif superieur.global_position.distance_to($player.global_position) < distance_conversation:
		var regard: Vector3 = $player.global_position
		regard.y = superieur.global_position.y
		if regard.distance_squared_to(superieur.global_position) > 0.01: superieur.look_at(regard, Vector3.UP)
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
		invitation.text = "E · " + ("Afficher la phrase" if dialogue.visible and not dialogue.revelee() else ("Continuer la conversation" if not progression.replique().is_empty() else "Parler au chef"))
	else:
		invitation.text = "Approchez-vous du chef pour lui parler" if not progression.dialogue_termine else ""
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
	dialogue.afficher(actuelle.consigne if progression.dialogue_termine else progression.replique())
	_actualiser_proximite()

func _entrer() -> void:
	if changement: return
	changement = true
	$player.extincteur.stop_primary_attack()
	# La suite reste provisoire : la préparation est fixe, le parcours intérieur viendra ensuite.
	Reglages.chargement.chargement_echoue.connect(func(): changement = false, CONNECT_ONE_SHOT)
	Reglages.chargement.ouvrir("res://scenes/modes/tutoriel/parcours_tutoriel.tscn")
