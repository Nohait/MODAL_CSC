extends Control

const TEXTE_DECHIRE = preload("res://scenes/interfaces/menus/texte_booster_dechire.gdshader")
const DECHIRURE = preload("res://scenes/interfaces/menus/booster_bonus.gdshader")
var morceaux: Array[Control] = []
var materiaux: Array[ShaderMaterial] = []
var temps := 0.0
var animation: Tween

func lancer(source: Control) -> Tween:
	masquer()
	# La déchirure accompagne le départ des deux moitiés, boutique et Carnet compris.
	SonsInterface.ouvrir_booster()
	show()
	var gauche := _creer_moitie(source, -1.0)
	var droite := _creer_moitie(source, 1.0)
	animation = create_tween().set_parallel(true)
	# Déplacement, rotation et disparition se jouent ensemble, même pendant la pause.
	for i in range(2):
		var morceau := gauche if i == 0 else droite
		var sens := -1.0 if i == 0 else 1.0
		var distance := 12.0 if i == 1 and source is Button else 42.0
		animation.tween_property(morceau, "position:x", morceau.position.x + sens * distance, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		# La chute accélère vers le bas, tandis que chaque moitié bascule vers l’extérieur.
		animation.tween_property(morceau, "position:y", morceau.position.y + 65.0, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		animation.tween_property(morceau, "rotation", sens * deg_to_rad(18.0), 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
		animation.tween_property(morceau, "modulate:a", 0.0, 0.2).set_delay(0.15)
	# Nettoyer sans tuer le Tween permet à la boutique d’attendre son signal finished.
	animation.chain().tween_callback(_nettoyer)
	return animation

func _creer_moitie(source: Control, cote: float) -> Control:
	var morceau := Control.new()
	morceau.mouse_filter = Control.MOUSE_FILTER_IGNORE
	morceau.size = source.size
	morceau.position = source.global_position - global_position
	morceau.scale = source.get_global_transform().get_scale()
	morceau.pivot_offset = source.size / 2.0
	# Le pivot central ne doit pas décaler les petits boosters déjà mis à l’échelle.
	morceau.position -= morceau.pivot_offset * (Vector2.ONE - morceau.scale)
	add_child(morceau)
	if source.has_node("Visuel"):
		var visuel: Control = source.get_node("Visuel").duplicate()
		morceau.add_child(visuel)
		_decouper_fond(visuel.get_node("Papier"), cote)
		# Le texte suit la même déchirure que le métal, même lorsque les morceaux pivotent.
		var original: Control = source.get_node("Visuel")
		for etiquette in visuel.find_children("*", "Label", true, false):
			var modele: Control = original.get_node(visuel.get_path_to(etiquette))
			var mat := ShaderMaterial.new()
			mat.shader = TEXTE_DECHIRE
			mat.set_shader_parameter("taille", source.size)
			mat.set_shader_parameter("decalage", (original.get_global_transform().affine_inverse() * modele.get_global_transform()).origin)
			mat.set_shader_parameter("cote_dechirure", cote)
			etiquette.material = mat
	else:
		var fond: TextureRect = source.get_node("Fond").duplicate()
		morceau.add_child(fond)
		_decouper_fond(fond, cote)
		for nom in (["Icone", "Titre", "Nombre"] if cote < 0 else ["Touche"]):
			morceau.add_child(source.get_node(nom).duplicate())
	morceaux.append(morceau)
	return morceau

func _decouper_fond(fond: TextureRect, cote: float) -> void:
	var original := fond.material as ShaderMaterial
	var mat := ShaderMaterial.new()
	mat.shader = DECHIRURE
	# Conserver la couleur, le reflet et les braises du booster acheté.
	for uniforme in original.shader.get_shader_uniform_list():
		mat.set_shader_parameter(uniforme.name, original.get_shader_parameter(uniforme.name))
	mat.set_shader_parameter("cote_dechirure", cote)
	fond.material = mat
	materiaux.append(mat)

func _process(delta: float) -> void:
	if not visible:
		return
	temps += delta
	for mat in materiaux:
		mat.set_shader_parameter("horloge", temps)

func masquer() -> void:
	if animation:
		animation.kill()
	_nettoyer()

func _nettoyer() -> void:
	hide()
	for morceau in morceaux:
		morceau.queue_free()
	morceaux.clear()
	materiaux.clear()
