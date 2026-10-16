extends Node3D

signal consigne_changee
signal ravitaillement_effectue
signal carte_acquise
signal salle_reussie
var progression = preload("res://scenes/modes/tutoriel/07_ravitaillement/progression_ravitaillement.gd").new()
var actif := false
var termine: bool:
	get: return progression.termine
var carte: StringName:
	get: return progression.carte
var joueur
var gestion
var pompier
var sortie
var sortie_ouverte := false
const POSITION_POSTE := Vector3(-2, 1, -34)

func _ready() -> void:
	var decor = preload("res://scenes/modes/tutoriel/07_ravitaillement/decor_ravitaillement.gd").new()
	add_child(decor)
	sortie = decor.sortie
	sortie.ouverte.connect(func(): sortie_ouverte = true)

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
	pompier.parler("Souffle un peu, je m’occupe de ton matériel. On a aussi quelques renforts pour ton extincteur : regarde ce qui te convient, mais tu ne peux en emporter qu’un.", joueur, camera)
	consigne_changee.emit()

func interagir() -> void:
	if not actif or joueur.est_mort: return
	joueur.BarreDeVie.value = joueur.BarreDeVie.max_value
	joueur.extincteur.stop_primary_attack()
	joueur.extincteur.vider_jet()
	joueur.extincteur.charge = joueur.extincteur.max_charge
	joueur.extincteur.is_overheated = false
	ravitaillement_effectue.emit()
	pompier.parler("Voilà, tu es prêt à repartir. Choisis ton renfort. Tu peux l’essayer sur le mannequin avant de reprendre la recherche.", joueur, get_viewport().get_camera_3d())
	if carte == &"": gestion.ouvrir_booster_formation()
	consigne_changee.emit()

func _sur_acquisition(identifiant: StringName) -> void:
	if not progression.acquerir(identifiant): return
	preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
	sortie.ouvrir()
	carte_acquise.emit()
	consigne_changee.emit()

func consigne() -> String:
	if termine: return "La voie est libre. L’équipe prend le relais."
	if carte == &"": return "E · Parlez au pompier pour choisir votre amélioration."
	return "Essayez votre amélioration sur le mannequin, puis rejoignez la porte."

func _process(_delta: float) -> void:
	if not actif or termine or joueur.est_mort: return
	var ecart: Vector3 = joueur.global_position - POSITION_POSTE
	ecart.y = 0
	if ecart.length() < 2.5 and Input.is_action_just_pressed("interact"): interagir()
	if progression.verifier_sortie(joueur.global_position, sortie_ouverte):
		preload("res://scenes/modes/tutoriel/commun/interface/validation_objectif.gd").jouer(get_tree())
		consigne_changee.emit()
		salle_reussie.emit()
