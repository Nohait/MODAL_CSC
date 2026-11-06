extends Control

const LIGNE = preload("res://scenes/interfaces/succes/ligne_succes.tscn")
var animation: Tween
var horloge := 0.0
var confirmation_debug: ConfirmationDialog

func _ready() -> void:
	add_to_group("debug_modal")
	preload("res://scenes/interfaces/menus/navigation_manette.gd").installer(self)
	%Fermer.pressed.connect(fermer)
	for bouton in [%Fermer]:
		var mat := ShaderMaterial.new()
		mat.shader = preload("res://scenes/interfaces/menus/onglet_carnet.gdshader")
		mat.set_shader_parameter("selection", 0.0)
		mat.set_shader_parameter("plastique", preload("res://assets/textures/interfaces/matieres/plastic_001/plastic_001_color.jpg"))
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
	for bouton in [%Fermer]:
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
	for succes in SuccesManager.CATALOGUE.liste():
		var ligne = LIGNE.instantiate()
		%Liste.add_child(ligne)
		ligne.afficher(succes, SuccesManager.est_obtenu(succes.id))
	var nombre := SuccesManager.obtenus.size()
	var total := SuccesManager.CATALOGUE.liste().size()
	%Progression.max_value = total
	%Progression.value = nombre
	%Compteur.text = "%d / %d succès obtenus" % [nombre, total]

func ouvrir() -> void:
	actualiser_liste()
	show()
	if animation:
		animation.kill()
	animation = preload("res://scenes/interfaces/menus/transition_panneau.gd").ouvrir(self, self, $Pochette)

func fermer() -> void:
	if animation:
		animation.kill()
	hide()
	%Fermer.release_focus()

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		fermer()
		get_viewport().set_input_as_handled()

func debug_contextuel() -> bool:
	if not is_visible_in_tree(): return false
	if not is_instance_valid(confirmation_debug):
		confirmation_debug = ConfirmationDialog.new()
		confirmation_debug.title = "Réinitialiser les succès"
		confirmation_debug.dialog_text = "Effacer tous les succès de ce profil ?\nLes parties et le glossaire seront conservés."
		confirmation_debug.ok_button_text = "Réinitialiser"
		confirmation_debug.cancel_button_text = "Annuler"
		confirmation_debug.theme = preload("res://scenes/interfaces/theme_intervention/theme.tres")
		add_child(confirmation_debug)
		confirmation_debug.confirmed.connect(func():
			SuccesManager.reinitialiser()
			actualiser_liste())
	confirmation_debug.popup_centered()
	confirmation_debug.get_cancel_button().grab_focus()
	return true
