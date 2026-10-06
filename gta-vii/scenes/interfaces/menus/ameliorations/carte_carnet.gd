extends Control

const CARTE = preload("res://scenes/interfaces/menus/ameliorations/carte_amelioration.tscn")
const ECHELLE_VIGNETTE := 0.5
var carte: Control
var agrandie: Control
var couche: CanvasLayer
var souris_dans_fenetre := true

func _ready() -> void:
	carte.scale = Vector2.ONE * ECHELLE_VIGNETTE
	custom_minimum_size = carte.size * ECHELLE_VIGNETTE
	carte.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Les enfants non réduits ont encore de grands rectangles : aucun ne doit capter la souris.
	for enfant in carte.find_children("*", "Control", true, false):
		enfant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	get_window().mouse_exited.connect(_sortir_fenetre)
	get_window().mouse_entered.connect(_entrer_fenetre)

func _sortir_fenetre() -> void:
	souris_dans_fenetre = false
	_fermer_apercu()

func _entrer_fenetre() -> void:
	souris_dans_fenetre = true

func _agrandir() -> void:
	if is_instance_valid(couche):
		return
	# Une copie au-dessus du défilement évite que la grande carte soit coupée par ses bords.
	couche = CanvasLayer.new()
	couche.layer = 31
	add_child(couche)
	agrandie = CARTE.instantiate()
	for propriete in ["lecture_seule", "identifiant", "titre", "description", "illustration", "rarete", "categorie", "effet_affiche", "duree_affichee", "statut"]:
		agrandie.set(propriete, carte.get(propriete))
	couche.add_child(agrandie)
	# Ignorer la souris sur la copie conserve le survol de la vignette située dessous.
	agrandie.mouse_filter = Control.MOUSE_FILTER_IGNORE
	for enfant in agrandie.find_children("*", "Control", true, false):
		enfant.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dimensions := agrandie.size * 1.25
	var limite := get_viewport_rect().size - dimensions - Vector2(16, 16)
	agrandie.position = (global_position - (dimensions - size) / 2.0).clamp(Vector2(16, 72), limite)
	agrandie.scale = Vector2.ONE
	agrandie.modulate.a = 0.0
	var animation := create_tween().set_parallel(true)
	animation.tween_property(agrandie, "scale", Vector2.ONE * 1.25, 0.18).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	animation.tween_property(agrandie, "modulate:a", 1.0, 0.12)

func _fermer_apercu() -> void:
	if is_instance_valid(couche):
		couche.hide()
		couche.queue_free()
	couche = null

func _survol_valide(souris: Vector2) -> bool:
	if not souris_dans_fenetre or not is_visible_in_tree() or not get_global_rect().has_point(souris):
		return false
	# Une vignette peut être visible dans l'arbre mais coupée par le défilement.
	var parent := get_parent()
	while parent:
		if parent is Control and parent.clip_contents and not parent.get_global_rect().has_point(souris):
			return false
		parent = parent.get_parent()
	return true

func _process(_delta: float) -> void:
	# Une zone fixe décide du survol ; les animations et leurs copies ne changent jamais cette zone.
	if _survol_valide(get_global_mouse_position()):
		_agrandir()
	else:
		_fermer_apercu()
