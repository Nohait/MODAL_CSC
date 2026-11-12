extends Node3D
const COMMANDE = preload("res://scenes/interfaces/libelle_commande.gd")

@export var action: StringName = &"interact"
@export var verbe := "Ouvrir"
@export_range(0.1, 1.0, 0.05) var intervalle_actualisation := 0.25
var attente_actualisation := 0.0

func _ready() -> void:
	_actualiser_texte()

func _process(delta: float) -> void:
	if not is_visible_in_tree(): return
	attente_actualisation -= delta
	if attente_actualisation > 0.0: return
	attente_actualisation = intervalle_actualisation
	_actualiser_texte()

func _actualiser_texte() -> void:
	COMMANDE.afficher_3d($Indication, "%s - [%s]" % [verbe, _nom_commande()], action, get_tree().get_first_node_in_group("player"))

func _nom_commande() -> String:
	var joueur := get_tree().get_first_node_in_group("player")
	return COMMANDE.nom(action, joueur)
