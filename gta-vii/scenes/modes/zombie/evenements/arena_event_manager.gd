extends Node

signal palier_declenche(definition: PalierArene)
@export var paliers: Array[PalierArene] = []
@onready var vagues = get_node("../Salles/RoomManager")
var effectues: Dictionary = {}

func _ready() -> void:
	vagues.salle_commencee.connect(_actualiser)

func _actualiser(salle: Node3D) -> void:
	for palier in paliers:
		if vagues.vague_actuelle < palier.vague or (palier.unique and effectues.has(palier)): continue
		if randf() * 100.0 >= palier.probabilite: continue
		var cible := salle.get_node_or_null(palier.cible)
		if cible == null: continue
		_appliquer(palier, cible)
		effectues[palier] = true
		palier_declenche.emit(palier)

func _appliquer(palier: PalierArene, cible: Node3D) -> void:
	match palier.evenement:
		"ouvrir_entree": cible.premiere_vague = palier.vague
		"eteindre_lumiere": cible.hide()
		"allumer_lumiere": cible.show()

func capturer_sauvegarde() -> Dictionary:
	var chemins: Array[String] = []
	for palier in effectues: chemins.append(palier.resource_path)
	return {"paliers": chemins}

func restaurer_sauvegarde(etat: Dictionary, salle: Node3D) -> void:
	effectues.clear()
	for palier in paliers:
		if not etat.paliers.has(palier.resource_path): continue
		var cible := salle.get_node_or_null(palier.cible) as Node3D
		if cible == null: continue
		_appliquer(palier, cible)
		effectues[palier] = true
