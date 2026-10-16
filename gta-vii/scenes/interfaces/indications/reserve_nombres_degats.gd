extends Node

@export_range(0, 512, 16) var capacite_inactive := 192
var disponibles: Dictionary = {}
var nombre_inactifs := 0

func prendre(modele: Label3D) -> Label3D:
	# Une réserve par scène et modèle d’ennemi conserve les variantes de présentation.
	var police := modele.font.get_instance_id() if modele.font != null else 0
	var cle := "%s:%s:%s:%s" % [modele.get_parent().scene_file_path, modele.name, police, modele.pixel_size]
	var liste: Array = disponibles.get(cle, [])
	var nombre: Label3D
	if not liste.is_empty():
		nombre = liste.pop_back()
		nombre_inactifs -= 1
	else:
		nombre = modele.duplicate() as Label3D
		nombre.set_meta("style_reserve", cle)
	disponibles[cle] = liste
	return nombre

func rendre(nombre: Label3D) -> void:
	nombre.hide()
	if nombre_inactifs >= capacite_inactive:
		nombre.queue_free()
		return
	var cle: String = nombre.get_meta("style_reserve")
	disponibles[cle].append(nombre)
	nombre_inactifs += 1
