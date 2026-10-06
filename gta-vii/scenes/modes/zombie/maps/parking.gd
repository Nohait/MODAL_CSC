extends "res://scenes/modes/zombie/maps/hall.gd"

@export var ambiance_parking: Environment = preload("res://assets/materiaux/parking/ambiance_parking.tres")
@export_range(0.0, 0.5, 0.01) var energie_soleil := 0.08
@export var position_refuge := Vector3(0, 0, 12)
@export var paliers_arene: Array[PalierArene] = [
	preload("res://scenes/modes/zombie/evenements/paliers/parking_ventilation.tres"),
	preload("res://scenes/modes/zombie/evenements/paliers/parking_eclairage.tres"),
	preload("res://scenes/modes/zombie/evenements/paliers/parking_incendie.tres")
]

func _ready() -> void:
	# Les accès partagés conservent leurs animations, mais adoptent notre béton humide.
	for morceau: MeshInstance3D in $Navigation/Decor/EntreesEnnemis.find_children("*", "MeshInstance3D", true, false):
		if morceau.mesh == null: continue
		var materiau := morceau.get_active_material(0)
		if materiau != null and materiau.resource_path == "res://assets/materiaux/hall_incendie/sol_carrelage.tres":
			morceau.material_override = preload("res://assets/materiaux/parking/sol_humide.tres")
	super._ready()
	# La map possède sa lumière, sans modifier l'ambiance du Hall ni du mode classique.
	var niveau: Node = self
	for i in range(3):
		if niveau != null: niveau = niveau.get_parent()
	if niveau != null and niveau.has_node("Eclairage/Ambiance"):
		niveau.get_node("Eclairage/Ambiance").environment = ambiance_parking
		niveau.get_node("Eclairage/Soleil").light_energy = energie_soleil
		var arene = niveau.get_node_or_null("ArenaEventManager")
		if arene != null: arene.paliers = paliers_arene
