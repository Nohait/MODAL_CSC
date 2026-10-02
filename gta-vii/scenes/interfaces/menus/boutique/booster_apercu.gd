@tool
extends Control

signal selectionne

@export var titre := "Renfort"
@export var couleur := Color("72adb0")
@export var prix := 1
@export var contenu := "3 cartes communes"
@export var symbole := "I"

@onready var visuel: Control = $Visuel
@onready var papier: TextureRect = $Visuel/Papier
var materiau: ShaderMaterial
var animation: Tween
# Valeur progressive entre 0 et 1, commune au reflet et aux bordures lumineuses.
var accent_survol := 0.0
var temps := 0.0


func _ready() -> void:
	# Dupliquer évite qu'un survol recolorie ou anime les trois boosters ensemble.
	materiau = papier.material.duplicate()
	papier.material = materiau
	materiau.set_shader_parameter("teinte_pochette", couleur)
	# La pochette, ses braises et son contour de survol partagent la même couleur.
	materiau.set_shader_parameter("braises_personnalisees", true)
	materiau.set_shader_parameter("teinte_braises", couleur)
	%Titre.text = titre
	%Contenu.text = contenu
	%Symbole.text = symbole
	%Symbole.modulate = couleur.lightened(0.3)
	%Prix.text = "%d point%s" % [prix, "s" if prix > 1 else ""]
	if Engine.is_editor_hint():
		return
	mouse_entered.connect(_survol.bind(true))
	mouse_exited.connect(_survol.bind(false))
	gui_input.connect(_cliquer)


func _process(delta: float) -> void:
	if materiau == null:
		return
	temps += delta
	materiau.set_shader_parameter("horloge", temps)
	# Le rectangle cliquable reste stable ; seul le dessin de la pochette s'agrandit.
	visuel.pivot_offset = size / 2.0
	materiau.set_shader_parameter("taille", size)
	materiau.set_shader_parameter("survol", accent_survol)


func _survol(active: bool) -> void:
	# Arrêter le Tween conserve la valeur actuelle : même si la souris entre et
	# ressort vite, le reflet repart de sa position présente, sans se téléporter.
	if animation:
		animation.kill()
	animation = create_tween().set_parallel(true)
	# Les deux animations se jouent ensemble. La teinte glisse pendant 0,18 seconde
	# grâce à accent_survol ; le shader reçoit chaque valeur intermédiaire.
	animation.tween_property(self, "accent_survol", 1.0 if active else 0.0, 0.18).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Ease Out ralentit l'agrandissement à la fin pour éviter un arrêt brutal.
	animation.tween_property(visuel, "scale", Vector2.ONE * (1.035 if active else 1.0), 0.18).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _cliquer(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		selectionne.emit()
		accept_event()
