@tool
extends Control

const ICONE_VICTIMES = preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg")

@onready var objectifs: Label = $Objectifs
@onready var ennemis: Label = $Ennemis
@onready var encart: Control = $TimerContainer
@onready var timer: ProgressBar = $TimerContainer/TimerBar
@onready var texte_timer: RichTextLabel = $TimerContainer/TimerText
var remplissage: StyleBoxFlat
var temps := 0.0
var victimes_a_liberer := 0
var salle_liberee := false
var boss_affiches: Array[int] = []
var opacite_habituelle := 1.0

func _ready() -> void:
	if not Engine.is_editor_hint():
		add_to_group("informations_combat")
	# Dupliquer le style permet de changer la couleur sans toucher aux autres barres.
	remplissage = timer.get_theme_stylebox("fill").duplicate()
	timer.add_theme_stylebox_override("fill", remplissage)
	timer.value_changed.connect(_actualiser_timer)
	_actualiser_timer(timer.value)

func mettre_a_jour(etage: int, salle: int, total: int, restants: int, a_venir: int, captives: int = 0) -> void:
	# Le compteur concerne la salle actuelle, sans compter les victimes de l’escorte.
	victimes_a_liberer = maxi(captives, 0)
	_actualiser_timer(timer.value)
	objectifs.text = "ÉTAGE %d  ·  SALLE %d / %d" % [etage, salle, total]
	ennemis.text = "%d ENNEMIS RESTANTS" % restants if restants > 0 else "PASSAGE OUVERT"
	if a_venir > 0:
		ennemis.text += "  ·  %d À VENIR" % a_venir

func _actualiser_timer(_secondes: float) -> void:
	if salle_liberee:
		return
	texte_timer.clear()
	texte_timer.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	texte_timer.push_font_size(22)
	texte_timer.add_text("%d " % victimes_a_liberer)
	texte_timer.add_image(ICONE_VICTIMES, 20, 20, Color("edf0e9"), INLINE_ALIGNMENT_CENTER)
	texte_timer.add_text(" À LIBÉRER")
	texte_timer.pop()
	texte_timer.pop()

func demarrer_timer() -> void:
	salle_liberee = false
	temps = 0.0
	encart.show()
	timer.hide()
	texte_timer.offset_top = 0.0
	texte_timer.offset_bottom = 34.0
	_actualiser_timer(timer.value)

func afficher_salle_liberee() -> void:
	salle_liberee = true
	encart.show()
	timer.hide()
	texte_timer.offset_top = 0.0
	texte_timer.offset_bottom = 34.0
	texte_timer.clear()
	texte_timer.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	texte_timer.add_text("Salle libérée !")
	texte_timer.pop()
	_reinitialiser_alerte()

func _reinitialiser_alerte() -> void:
	temps = 0.0
	encart.scale = Vector2.ONE
	encart.modulate.a = 1.0

func masquer_pour_boss(interface: Node) -> void:
	if boss_affiches.is_empty():
		opacite_habituelle = modulate.a
	if not boss_affiches.has(interface.get_instance_id()):
		boss_affiches.append(interface.get_instance_id())
	modulate.a = 0.0

func retablir_apres_boss(interface: Node) -> void:
	# Plusieurs boss de debug peuvent coexister : attendre la dernière jauge.
	boss_affiches.erase(interface.get_instance_id())
	if boss_affiches.is_empty():
		modulate.a = opacite_habituelle
