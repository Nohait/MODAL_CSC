extends Label

func _make_custom_tooltip(texte: String) -> Object:
	var bulle = preload("res://scenes/interfaces/menus/infobulle_metal.gd").new()
	bulle.texte = texte
	return bulle
