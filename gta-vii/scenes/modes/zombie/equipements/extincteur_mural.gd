extends Node3D

signal etat_change
@export_range(1, 100, 1) var prix_recharge := 10
var disponible := true
var joueur_proche: Node3D
@onready var indication: Label3D = $Indication
@onready var voyant: MeshInstance3D = $Voyant

func _ready() -> void:
	add_to_group("extincteur_mural")
	voyant.material_override = voyant.material_override.duplicate()
	$Detection.body_entered.connect(_entree)
	$Detection.body_exited.connect(_sortie)
	_actualiser()

func _entree(corps: Node3D) -> void:
	if corps.is_in_group("player"):
		joueur_proche = corps
		_actualiser()

func _sortie(corps: Node3D) -> void:
	if corps == joueur_proche:
		joueur_proche = null
		indication.hide()

func _unhandled_input(event: InputEvent) -> void:
	if event.is_echo() or get_tree().paused or not is_instance_valid(joueur_proche):
		return
	if event.is_action_pressed("interact"):
		utiliser(joueur_proche)
		get_viewport().set_input_as_handled()

func utiliser(joueur: Node3D) -> bool:
	if not disponible or joueur.est_mort or joueur.entree_automatique:
		return false
	var arme = joueur.extincteur
	if arme.charge >= arme.max_charge - 0.01:
		indication.text = "Mousse déjà pleine"
		return false
	# Remplir la réserve effective inclut les améliorations de capacité du joueur.
	arme.charge = arme.max_charge
	disponible = false
	_actualiser()
	etat_change.emit()
	return true

func recharger() -> void:
	# Seule la boutique paie ; l'objet s'occupe uniquement de son état.
	disponible = true
	_actualiser()
	etat_change.emit()

func _actualiser() -> void:
	var teinte := Color("81dba7") if disponible else Color("e57357")
	voyant.material_override.albedo_color = teinte
	voyant.material_override.emission = teinte
	indication.visible = is_instance_valid(joueur_proche)
	if disponible:
		var touches := InputMap.action_get_events("interact")
		var touche := touches[0].as_text() if not touches.is_empty() else "Interagir"
		indication.text = "[%s] Refaire le plein de mousse" % touche
	else:
		indication.text = "Vide · Recharge en boutique"
