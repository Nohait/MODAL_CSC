@tool
extends Node3D

@export var teinte: Color = Color(0.55, 0.48, 0.4):
	set(valeur):
		teinte = valeur
		if is_node_ready():
			_appliquer_teinte()

func _ready() -> void:
	_appliquer_teinte()

func _appliquer_teinte() -> void:
	# Copier les matériaux : assombrir ces cartons ne modifie pas le modèle importé.
	for noeud in get_node("Modele").find_children("*", "MeshInstance3D", true, false):
		for surface in noeud.mesh.get_surface_count():
			var origine = noeud.mesh.surface_get_material(surface)
			if origine is StandardMaterial3D:
				var materiau = origine.duplicate() as StandardMaterial3D
				materiau.albedo_color = origine.albedo_color * teinte
				noeud.set_surface_override_material(surface, materiau)
