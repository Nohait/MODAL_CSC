extends Control

const LIGNE = preload("res://scenes/interfaces/succes/ligne_succes.tscn")
var animation: Tween
var horloge := 0.0

func _ready() -> void:
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(self)
	%Fermer.pressed.connect(fermer)
	%Reinitialiser.visible = OS.is_debug_build()
	%Reinitialiser.pressed.connect(_reinitialiser)
	for bouton in [%Fermer, %Reinitialiser]:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://scenes/interfaces/menus/onglet_carnet.gdshader")
		mat.set_shader_parameter("selection", 0.0)
		mat.set_shader_parameter("largeur_bord", 4.0)
		mat.set_shader_parameter("rayon_coin", 6.0)
		mat.set_shader_parameter("intensite_braises", 0.3)
		bouton.fond.texture = preload("res://assets/textures/interfaces/ameliorations/texture_carte_300x450_r16.png")
		bouton.fond.material = mat
	hide()

func _process(delta: float) -> void:
	if not visible:
		return
	horloge += delta
	for bouton in [%Fermer, %Reinitialiser]:
		var mat: ShaderMaterial = bouton.fond.material
		var cible := 0.65 if bouton.is_hovered() or bouton.has_focus() else 0.0
		var actuel: float = mat.get_shader_parameter("selection")
		mat.set_shader_parameter("selection", lerpf(actuel, cible, 1.0 - exp(-12.0 * delta)))
		mat.set_shader_parameter("horloge", horloge)
		mat.set_shader_parameter("taille", bouton.size)

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
