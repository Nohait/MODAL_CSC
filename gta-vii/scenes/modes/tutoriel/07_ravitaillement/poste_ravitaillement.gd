extends Node3D

signal consigne_changee
signal ravitaillement_effectue
signal carte_acquise
signal salle_reussie
@export_range(1.5, 4.0, 0.1) var distance_conversation := 2.5
@export_range(1.5, 4.0, 0.1) var distance_ouverture_sortie := 2.2
var progression = preload("res://scenes/modes/tutoriel/07_ravitaillement/progression_ravitaillement.gd").new()
var actif := false
var termine: bool:
	get: return progression.termine
var carte: StringName:
	get: return progression.carte
var joueur
var gestion
var pompier
var repere_pompier: Node3D
var decor
var sortie
var sortie_ouverte := false
var ouverture_sortie_en_cours := false
const POSITION_POSTE := Vector3(-2, 1, -34)
var voice_player: AudioStreamPlayer3D

func _ready() -> void:
	decor = preload("res://scenes/modes/tutoriel/07_ravitaillement/decor_ravitaillement.gd").new()
	add_child(decor)
	sortie = decor.sortie
	sortie.ouverture_terminee.connect(func(): sortie_ouverte = true)

func play_voice(indice = "5"):
	var path = "res://assets/sounds/voice_line/tutoriel/Pompier%s.wav" % [indice]
	if ResourceLoader.exists(path):
		if voice_player.is_playing():
			voice_player.stop()
		voice_player.stream = load(path)
		voice_player.play()

func preparer(personnage, ameliorations, camera: Camera3D) -> void:
	if actif: return
	actif = true
	joueur = personnage
	gestion = ameliorations
	gestion.booster_formation_acquis.connect(_sur_acquisition)
	pompier = preload("res://scenes/modes/tutoriel/commun/figurants/figurant_pompier.gd").new()
	pompier.position = POSITION_POSTE
	add_child(pompier)
	pompier.installer_modele(joueur)
	repere_pompier = preload("res://scenes/modes/tutoriel/commun/decors/repere_passage.tscn").instantiate()
	repere_pompier.name = "InvitationParler"
	repere_pompier.verbe = "Parler"
	repere_pompier.position = Vector3(0, -0.8, 1.0)
	repere_pompier.hide()
	pompier.add_child(repere_pompier)
	play_voice("7_1")
	pompier.parler("Viens me parler, j’ai de quoi renforcer ton extincteur. Tu pourras choisir une amélioration avant de repartir.", joueur, camera)
	consigne_changee.emit()

func interagir() -> void:
	if not actif or joueur.est_mort: return
	joueur.BarreDeVie.value = joueur.BarreDeVie.max_value
	joueur.extincteur.stop_primary_attack()
	joueur.extincteur.vider_jet()
	joueur.extincteur.charge = joueur.extincteur.max_charge
	joueur.extincteur.is_overheated = false
	ravitaillement_effectue.emit()
	play_voice("7_2")
	pompier.parler("Voilà, tu es prêt à repartir. Choisis ton renfort. Tu peux l’essayer sur le mannequin avant de reprendre la recherche.", joueur, get_viewport().get_camera_3d())
	if carte == &"": gestion.ouvrir_booster_formation()
	consigne_changee.emit()

func _sur_acquisition(identifiant: StringName) -> void:
	if not progression.acquerir(identifiant): return
	repere_pompier.hide()
	preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
	decor.autoriser_sortie()
	carte_acquise.emit()
	consigne_changee.emit()

func consigne() -> String:
	if termine: return "La voie est libre. L’équipe prend le relais."
	if carte == &"": return "Parlez au pompier pour obtenir votre première amélioration."
	return "Essayez votre amélioration sur le mannequin, puis ouvrez la porte."

func _process(_delta: float) -> void:
	if not actif or termine or joueur.est_mort: return
	var ecart: Vector3 = joueur.global_position - pompier.global_position
	ecart.y = 0
	var a_portee := ecart.length() < distance_conversation
	repere_pompier.visible = a_portee and carte == &""
	if a_portee and Input.is_action_just_pressed("interact"): interagir()
	var ecart_sortie: Vector3 = joueur.global_position - sortie.global_position
	ecart_sortie.y = 0.0
	if carte != &"" and ecart_sortie.length() < distance_ouverture_sortie and Input.is_action_just_pressed("interact"):
		_ouvrir_sortie()

func _ouvrir_sortie() -> void:
	if ouverture_sortie_en_cours or sortie_ouverte: return
	ouverture_sortie_en_cours = true
	decor.masquer_repere_sortie()
	sortie.ouvrir()
	if not sortie.ouverte: await sortie.ouverture_terminee
	if joueur.est_mort: return
	if progression.valider_sortie(sortie_ouverte):
		preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
		consigne_changee.emit()
		salle_reussie.emit()
