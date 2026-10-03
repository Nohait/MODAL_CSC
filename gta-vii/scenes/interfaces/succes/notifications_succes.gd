extends CanvasLayer

var attente: Array[Dictionary] = []
var animation: Tween

func _ready() -> void:
	$Notification.hide()
	get_parent().succes_obtenu.connect(_ajouter)
	get_parent().succes_reinitialises.connect(_reinitialiser)

func _ajouter(succes: Dictionary) -> void:
	attente.append(succes)
	if not $Notification.visible:
		_afficher_suivante()

func _afficher_suivante() -> void:
	if attente.is_empty():
		$Notification.hide()
		return
	var succes: Dictionary = attente.pop_front()
	var panneau: Control = $Notification
	panneau.get_node("Marge/Ligne/Textes/Titre").text = succes.titre
	panneau.get_node("Marge/Ligne/Medaille").modulate = succes.couleur
	panneau.get_node("Papier").material.set_shader_parameter("teinte_rarete", succes.couleur)
	panneau.show()
	panneau.modulate.a = 0.0
	# Les offsets sont relatifs au coin inférieur droit, même si la fenêtre change.
	panneau.offset_left = -368.0
	panneau.offset_right = -8.0
	animation = create_tween()
	# Ces trois mouvements commencent ensemble : arrivée discrète en 0,22 seconde.
	animation.tween_property(panneau, "offset_left", -386.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.parallel().tween_property(panneau, "offset_right", -26.0, 0.22)
	animation.parallel().tween_property(panneau, "modulate:a", 1.0, 0.22)
	animation.tween_interval(3.0)
	animation.tween_property(panneau, "modulate:a", 0.0, 0.25)
	# La suivante ne commence qu'après la disparition de celle-ci.
	animation.tween_callback(_afficher_suivante)

func _reinitialiser() -> void:
	attente.clear()
	if animation:
		animation.kill()
	$Notification.hide()
