extends CanvasLayer

signal profil_modifie

const PROFIL = preload("res://scenes/systemes/debug/reinitialisation_profil.gd")
const PROGRESSION = preload("res://scenes/systemes/sauvegarde/progression_interventions.gd")
@onready var confirmation: LineEdit = %Confirmation
@onready var effacer: Button = %Effacer
@onready var resultat: Label = %Resultat
var pause_avant := false
var souris_avant := Input.MOUSE_MODE_VISIBLE

func _ready() -> void:
	%Annuler.pressed.connect(fermer)
	confirmation.text_changed.connect(func(texte: String): effacer.disabled = texte != "EFFACER")
	effacer.pressed.connect(_effacer)
	%Debloquer.pressed.connect(_debloquer)
	hide()

func ouvrir() -> void:
	pause_avant = get_tree().paused
	souris_avant = Input.mouse_mode
	get_tree().paused = true
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	confirmation.clear()
	effacer.disabled = true
	resultat.text = ""
	show()
	%Annuler.grab_focus()

func _debloquer() -> void:
	if not visible: return
	if PROGRESSION.debloquer_pour_debug():
		resultat.text = "Classique sans tutoriel, mode zombie et bouche à incendie débloqués. Les parties et les succès sont conservés."
		profil_modifie.emit()
	else:
		resultat.text = "Impossible d’enregistrer les déblocages. Vérifiez l’accès à la sauvegarde."

func fermer() -> void:
	if not visible: return
	hide()
	get_tree().paused = pause_avant
	Input.mouse_mode = souris_avant

func _input(event: InputEvent) -> void:
	if visible and event.is_action_pressed("ui_cancel"):
		get_viewport().set_input_as_handled()
		fermer()

func _effacer() -> void:
	if not visible or confirmation.text != "EFFACER" or effacer.disabled: return
	effacer.disabled = true
	var erreurs := PROFIL.reinitialiser(get_tree(), %Reglages.button_pressed)
	confirmation.clear()
	if erreurs.is_empty():
		resultat.text = "Profil remis à zéro. Aucun succès, aucune découverte ni partie en cours."
	else:
		resultat.text = "Remise à zéro incomplète :\n" + "\n".join(erreurs) + "\nLes autres éléments ont été effacés. Corrigez le problème puis réessayez."
	%Annuler.grab_focus()
	profil_modifie.emit()
