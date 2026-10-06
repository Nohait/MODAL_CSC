extends RefCounted

static func habiller(titre: Label3D, nom: String) -> Label3D:
	# Deux niveaux de lecture, avec les mêmes polices que les menus du jeu.
	titre.text = nom
	titre.font = preload("res://assets/fonts/Almendra-Bold.ttf")
	titre.font_size = 25
	titre.pixel_size = 0.006
	titre.modulate = Color("e8d6b5")
	titre.outline_modulate = Color("171b20")
	titre.outline_size = 5
	var etat := Label3D.new()
	etat.name = "DetailEquipement"
	etat.font = preload("res://assets/fonts/Oswald-SemiBold.ttf")
	etat.font_size = 20
	etat.pixel_size = titre.pixel_size
	etat.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	etat.outline_modulate = Color("171b20")
	etat.outline_size = 4
	etat.position.y = -0.19
	titre.add_child(etat)
	return etat
