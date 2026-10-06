@tool
extends Control

signal selectionne

@export var titre := "Renfort"
@export var couleur := Color("72adb0")
@export var prix := 1
@export var contenu := "3 cartes communes"
@export var symbole := "I"
@export_range(0, 3) var niveau_eclat := 0

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
	materiau.set_shader_parameter("niveau_eclat", float(niveau_eclat))
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
	focus_entered.connect(_survol.bind(true))
	focus_exited.connect(_survol.bind(false))


func _process(delta: float) -> void:
	if materiau == null:
		return
	temps += delta
	materiau.set_shader_parameter("horloge", temps)
	# Le rectangle cliquable reste stable ; seul le dessin de la pochette s'agrandit.
	visuel.pivot_offset = size / 2.0
	materiau.set_shader_parameter("taille", size)
	materiau.set_shader_parameter("survol", accent_survol)
	materiau.set_shader_parameter("intensite_braises", 0.8 + niveau_eclat * 0.2 + accent_survol * 0.55)
	queue_redraw()

func _draw() -> void:
	if accent_survol <= 0.001:
		return
	# Le halo est derrière les enfants : il éclaire le contour sans voiler le texte.
	var halo := StyleBoxFlat.new()
	halo.bg_color = Color.TRANSPARENT
	halo.shadow_color = Color(couleur, accent_survol * (0.2 + niveau_eclat * 0.07))
	halo.shadow_size = int(12 + niveau_eclat * 7)
	draw_style_box(halo, Rect2(Vector2.ZERO, size))


func _survol(active: bool) -> void:
	active = active or has_focus()
	# Arrêter le Tween conserve la valeur actuelle : même si la souris entre et
	# ressort vite, le reflet repart de sa position présente, sans se téléporter.
	if animation:
		animation.kill()
	animation = create_tween().set_parallel(true)
	# Les deux animations se jouent ensemble. La teinte glisse pendant 0,18 seconde
	# grâce à accent_survol ; le shader reçoit chaque valeur intermédiaire.
	animation.tween_property(self, "accent_survol", 1.0 if active else 0.0, 0.18).set_ease(Tween.EASE_IN_OUT).set_trans(Tween.TRANS_SINE)
	# Ease Out ralentit l'agrandissement à la fin pour éviter un arrêt brutal.
	animation.tween_property(visuel, "scale", Vector2.ONE * (1.055 + niveau_eclat * 0.012 if active else 1.0), 0.24).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_BACK)
	animation.tween_property(visuel, "rotation", deg_to_rad(-0.6 - niveau_eclat * 0.35) if active else 0.0, 0.24).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	# Relever la pochette sans déplacer sa zone cliquable ni ses voisines.
	animation.tween_property(visuel, "position:y", -4.0 - niveau_eclat * 2.0 if active else 0.0, 0.24).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)


func _cliquer(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		accept_event()
		selectionne.emit()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		accept_event()
		selectionne.emit()
