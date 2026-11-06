extends PanelContainer

func afficher(succes: Dictionary, obtenu: bool) -> void:
	$Marge/Ligne/Textes/Titre.text = succes.titre
	$Marge/Ligne/Textes/Description.text = succes.description
	$Marge/Ligne/Etat.text = ("OBTENU\n" if obtenu else "À OBTENIR\n") + succes.rarete
	$Marge/Ligne/Etat.modulate = succes.couleur if obtenu else Color("969696")
	$Marge/Ligne/Medaille.modulate = succes.couleur if obtenu else Color("969696")
	var mat: ShaderMaterial = $Papier.material
	mat.set_shader_parameter("rarete_coloree", obtenu)
	mat.set_shader_parameter("teinte_rarete", succes.couleur)
	$Marge/Ligne/Textes/Titre.modulate = Color.WHITE if obtenu else Color("bdbdbd")
