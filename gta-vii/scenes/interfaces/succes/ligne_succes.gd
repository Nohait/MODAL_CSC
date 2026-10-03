extends PanelContainer

func afficher(succes: Dictionary, obtenu: bool) -> void:
	$Marge/Ligne/Textes/Titre.text = succes.titre
	$Marge/Ligne/Textes/Description.text = succes.description
	$Marge/Ligne/Etat.text = succes.rarete + ("\nOBTENU" if obtenu else "\nÀ OBTENIR")
	$Marge/Ligne/Etat.modulate = succes.couleur if obtenu else Color("423c36")
	$Marge/Ligne/Medaille.modulate = succes.couleur if obtenu else Color("77736d")
	var mat: ShaderMaterial = $Papier.material
	mat.set_shader_parameter("rarete_coloree", obtenu)
	mat.set_shader_parameter("teinte_rarete", succes.couleur)
	mat.set_shader_parameter("intensite_braises", 0.5 if obtenu else 0.0)
	$Papier.modulate = Color.WHITE if obtenu else Color(0.64, 0.64, 0.64)
