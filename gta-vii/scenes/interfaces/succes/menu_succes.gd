extends Control

const LIGNE = preload("res://scenes/interfaces/succes/ligne_succes.tscn")
var animation: Tween

func _ready() -> void:
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(self)
	%Fermer.pressed.connect(fermer)
	%Reinitialiser.visible = OS.is_debug_build()
	%Reinitialiser.pressed.connect(_reinitialiser)
	hide()

func actualiser_liste() -> void:
	for enfant in %Liste.get_children():
		%Liste.remove_child(enfant)
		enfant.queue_free()
	for succes in SuccesManager.CATALOGUE.SUCCES:
		var ligne = LIGNE.instantiate()
		%Liste.add_child(ligne)
		ligne.afficher(succes, SuccesManager.est_obtenu(succes.id))
	var nombre := SuccesManager.obtenus.size()
	var total := SuccesManager.CATALOGUE.SUCCES.size()
	%Progression.max_value = total
	%Progression.value = nombre
	%Compteur.text = "%d / %d succès obtenus" % [nombre, total]

func ouvrir() -> void:
	actualiser_liste()
	show()
	if animation:
		animation.kill()
	modulate.a = 0.0
	# Fondu court : le catalogue arrive sans déplacer ni déformer ses textes.
	animation = create_tween()
	animation.tween_property(self, "modulate:a", 1.0, 0.2)

func fermer() -> void:
	if animation:
		animation.kill()
	hide()
	%Fermer.release_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()

func _reinitialiser() -> void:
	SuccesManager.reinitialiser()
	actualiser_liste()
