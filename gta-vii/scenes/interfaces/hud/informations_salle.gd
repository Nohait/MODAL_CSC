@tool
extends Control

const ICONE_VICTIMES = preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg")

@onready var objectifs: Label = $Objectifs
@onready var ennemis: Label = $Ennemis
@onready var timer: ProgressBar = $TimerContainer/TimerBar
@onready var texte_timer: RichTextLabel = $TimerContainer/TimerText
var remplissage: StyleBoxFlat
var temps := 0.0
var victimes_a_liberer := 0

func _ready() -> void:
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

func _actualiser_timer(secondes: float) -> void:
	texte_timer.clear()
	texte_timer.push_paragraph(HORIZONTAL_ALIGNMENT_CENTER)
	if secondes > 0:
		texte_timer.add_text("SAUVETAGE · %02d s · %d " % [ceili(secondes), victimes_a_liberer])
		# L’image est insérée dans la ligne, juste après le nombre de victimes.
		texte_timer.add_image(ICONE_VICTIMES, 14, 14, Color(0.24, 0.13, 0.08), INLINE_ALIGNMENT_CENTER)
		texte_timer.add_text(" à libérer")
	else:
		texte_timer.add_text("SAUVETAGE TERMINÉ")
	texte_timer.pop()
	remplissage.bg_color = Color(0.75, 0.23, 0.12) if secondes <= 5 else Color(0.64, 0.37, 0.16)

func _process(delta: float) -> void:
	temps += delta
	# Le texte pulse doucement durant les cinq dernières secondes, puis se stabilise.
	var urgence := timer.value > 0 and timer.value <= 5
	texte_timer.modulate.a = 0.75 + sin(temps * 6.0) * 0.25 if urgence else 1.0

