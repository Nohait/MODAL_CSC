extends Node3D

signal etat_change
@export_range(1, 100, 1) var prix_recharge := 5
var disponible := true
var temps_voyant := 0.0
var detail_etat: Label3D
var joueur_proche: Node3D
@onready var indication: Label3D = $Indication
@onready var voyant: MeshInstance3D = $Voyant

func _ready() -> void:
	detail_etat = preload("res://scenes/interfaces/indications/indication_equipement.gd").habiller(indication, "Extincteur mural")
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
		detail_etat.text = "RÉSERVE DÉJÀ PLEINE"
		return false
	# Remplir la réserve effective inclut les améliorations de capacité du joueur.
	arme.charge = arme.max_charge
	disponible = false
	preload("res://scenes/effets/retours/impulsion_visuelle.gd").jouer(get_parent(), global_position + Vector3.UP * 0.15, Color("8de6ff"), 1.2)
	if is_instance_valid(joueur.ameliorations): joueur.ameliorations.effets_cartes.plein_mural()
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
	detail_etat.modulate = Color("9cd5b3") if disponible else Color("b6aaa0")
	indication.visible = is_instance_valid(joueur_proche)
	if disponible:
		var touches := InputMap.action_get_events("interact")
		var touche := touches[0].as_text() if not touches.is_empty() else "Interagir"
		detail_etat.text = "[%s]  REFAIRE LE PLEIN" % touche
	else:
		detail_etat.text = "VIDE · RECHARGE EN BOUTIQUE"

func _process(delta: float) -> void:
	temps_voyant += delta
	voyant.material_override.emission_energy_multiplier = 0.7 + (sin(temps_voyant * 3.0) + 1.0) * 0.4 if disponible else 0.3

func capturer_sauvegarde() -> Dictionary:
	return preload("res://scenes/systemes/sauvegarde/etat_sauvegarde.gd").lire_champs(self, ["disponible"])

func restaurer_sauvegarde(etat: Dictionary) -> void:
	preload("res://scenes/systemes/sauvegarde/etat_sauvegarde.gd").appliquer_champs(self, etat)
	_actualiser()
	etat_change.emit()
