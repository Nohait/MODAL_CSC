@tool
extends EspaceDecoratif

@export var objet_evacuation: PackedScene = preload("res://scenes/decors/interieurs/evacuation_valise.tscn")
@export var incendie_visible: PieceEmbrasee = preload("res://scenes/salles/incendies/piece_embrasee.tres")

func _ready() -> void:
	# Le seuil reste dégagé : le bagage est abandonné sur le côté intérieur de la porte.
	if objet_evacuation != null and not has_node("ObjetAbandonne"):
		var objet: Node3D = objet_evacuation.instantiate()
		objet.name = "ObjetAbandonne"
		objet.position = Vector3(1.3, 0, -0.85)
		objet.rotation.y = 0.35
		add_child(objet)
	super._ready()
	if incendie_visible != null: incendie_visible.appliquer(self)

