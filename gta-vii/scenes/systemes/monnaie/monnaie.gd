extends Node3D

signal solde_change(solde: int)
const PIECE = preload("res://scenes/effets/monnaie/piece.tscn")
@export var rayon_dispersion := 0.65
@export var volume_collecte_db := -12.0
var solde := 0
var delai_son := 0.0
var animation_compteur: Tween
var animation_reflet: Tween
var serie_collecte := 0
var pause_collecte := 0.0
@onready var joueur: Node3D = get_node("../player")
@onready var compteur: Label = $HUD/Compteur/Nombre
@onready var son: AudioStreamPlayer = $SonCollecte

func _ready() -> void:
	add_to_group("monnaie_partie")
	compteur.text = "0"
	var mat := ShaderMaterial.new()
	mat.shader = preload("res://scenes/interfaces/hud/reflet_piece.gdshader")
	$HUD/Compteur/Icone.material = mat

func lacher_pieces(ennemi: Node3D, valeur: int) -> void:
	if not is_instance_valid(ennemi) or ennemi.has_meta("pieces_lachees"): return
	# Les flaques peuvent être recréées par les tourelles : aucun butin à leur mort.
	if ennemi.is_in_group("flaque"): return
	ennemi.set_meta("pieces_lachees", true)
	var nombre := valeur * (2 if ennemi.has_node("Elite") else 1)
	# Cinq fois le butin habituel, donc dix fois la base pour une élite dorée.
	if ennemi.has_node("Dore"): nombre *= 5
	var origine := ennemi.global_position
	var dispersion: float = ennemi.get_meta("rayon_butin", rayon_dispersion)
	var delai: float = ennemi.get_meta("delai_butin", 0.0)
	# Capturer la position avant la suppression du boss ; les pièces arrivent à sa chute.
	if delai > 0.0:
		var sequence := create_tween()
		sequence.tween_interval(delai)
		sequence.tween_callback(_deposer_pieces.bind(origine, nombre, dispersion))
	else:
		_deposer_pieces(origine, nombre, dispersion)

func _deposer_pieces(origine: Vector3, nombre: int, dispersion: float) -> void:
	for i in range(nombre):
		var piece = PIECE.instantiate()
		piece.joueur = joueur
		piece.decalage = i * 0.04
		piece.position = to_local(origine + Vector3.UP * 0.2)
		var angle := randf() * TAU
		var ecart := Vector3(cos(angle), 0, sin(angle)) * randf_range(0.2, maxf(0.2, dispersion))
		# Chercher le sol réel : le point d'origine peut être un crâne volant.
		var cible := origine + ecart
		var requete := PhysicsRayQueryParameters3D.create(cible + Vector3.UP * 5.0, cible - Vector3.UP * 8.0, 1)
		var resultat := get_world_3d().direct_space_state.intersect_ray(requete)
		piece.point_sol = resultat.get("position", Vector3(cible.x, 0, cible.z)) + Vector3.UP * 0.2
		piece.ramassee.connect(_ramasser)
		add_child(piece)

func _ramasser() -> void:
	solde += 1
	serie_collecte += 1
	pause_collecte = 0.3
	_animer_compteur()
	compteur.text = str(solde)
	solde_change.emit(solde)
	# Éviter un bruit assourdissant lorsque beaucoup de pièces arrivent ensemble.
	if delai_son <= 0.0:
		son.volume_db = volume_collecte_db
		son.pitch_scale = minf(1.25, 1.0 + serie_collecte * 0.025)
		son.volume_db += minf(2.0, serie_collecte * 0.15)
		son.play()
		delai_son = 0.055

func _process(delta: float) -> void:
	delai_son = maxf(0.0, delai_son - delta)
	pause_collecte = maxf(0.0, pause_collecte - delta)
	if pause_collecte == 0: serie_collecte = 0


func depenser(prix: int) -> bool:
	# Vérifier avant de débiter évite un solde négatif et centralise la mise à jour du HUD.
	if prix < 0 or solde < prix:
		return false
	solde -= prix
	compteur.text = str(solde)
	solde_change.emit(solde)
	return true

func _animer_compteur() -> void:
	# Le compteur garde son rebond ; un seul reflet accompagne une série de pièces.
	if animation_reflet == null or not animation_reflet.is_running():
		var mat: ShaderMaterial = $HUD/Compteur/Icone.material
		mat.set_shader_parameter("eclat", 1.0)
		animation_reflet = create_tween()
		animation_reflet.tween_property(mat, "shader_parameter/eclat", 0.0, 0.4)
	if animation_compteur: animation_compteur.kill()
	compteur.pivot_offset = compteur.size / 2.0
	compteur.scale = Vector2.ONE * 1.16
	compteur.modulate = Color("ffe3a0")
	# Relancer le même rebond évite d'empiler les animations lors d'un gros butin.
	animation_compteur = create_tween().set_parallel(true)
	animation_compteur.tween_property(compteur, "scale", Vector2.ONE, 0.24).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	animation_compteur.tween_property(compteur, "modulate", Color.WHITE, 0.3)
