extends CanvasLayer

@export_range(0.0, 1.0, 0.05) var attente_degats := 0.25
@export_range(0.1, 1.0, 0.05) var duree_retard := 0.45
@export_range(0.5, 4.0, 0.1) var duree_presentation := 1.5
@export_range(0.0, 2.0, 0.05) var intensite_braises := 0.65
@export_range(0.0, 2.0, 0.05) var vitesse_braises := 0.35

var boss: Node3D
var presente := false
var termine := false
var animation_retard: Tween
var animation_vie: Tween
var animation_entree: Tween
var feu: ShaderMaterial
var informations: Array[Node] = []
@onready var panneau: Control = $Interface/Panneau
@onready var titre: Label = $Interface/Panneau/Titre
@onready var vie: ProgressBar = $Interface/Panneau/Vie
@onready var retard: ProgressBar = $Interface/Panneau/Retard
@onready var flammes: ColorRect = $Interface/Panneau/Incandescence

func _ready() -> void:
	panneau.hide()
	feu = ShaderMaterial.new()
	feu.shader = preload("res://assets/shaders/interfaces/barre_boss.gdshader")
	feu.set_shader_parameter("intensite", intensite_braises)
	feu.set_shader_parameter("vitesse", vitesse_braises)
	flammes.material = feu

func suivre(ennemi: Node3D) -> void:
	boss = ennemi
	titre.text = boss.nom_boss.to_upper()
	vie.value = clampf(boss.vie / maxf(boss.vie_max, 1.0), 0.0, 1.0)
	retard.value = vie.value
	boss.degats_subis.connect(_actualiser_vie)
	boss.died.connect(_fermer)
	# Une suppression de salle ou de debug doit aussi retirer la jauge.
	boss.tree_exiting.connect(_fermer)
	boss.get_node("PhaseBoss").colere_commencee.connect(_annoncer_colere)

func _process(_delta: float) -> void:
	if not termine and is_instance_valid(boss):
		var joueur = get_tree().get_first_node_in_group("player")
		if is_instance_valid(joueur) and joueur.est_mort:
			_fermer()
		elif not presente and boss.is_visible_in_tree() and not boss.est_mort:
			_presenter()
	feu.set_shader_parameter("progression", vie.value)

func _presenter() -> void:
	presente = true
	# Les compteurs continuent de fonctionner derrière la jauge du boss.
	informations = get_tree().get_nodes_in_group("informations_combat")
	for interface in informations:
		interface.masquer_pour_boss(self)
	panneau.show()
	panneau.modulate.a = 0.0
	panneau.position.y -= 12.0
	titre.add_theme_font_size_override("font_size", 28)
	animation_entree = create_tween().set_parallel(true)
	animation_entree.tween_property(panneau, "modulate:a", 1.0, 0.3)
	animation_entree.tween_property(panneau, "position:y", panneau.position.y + 12.0, 0.4).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	# Le nom prend brièvement de l'ampleur puis laisse une jauge compacte pendant le combat.
	animation_entree.chain().tween_interval(duree_presentation)
	animation_entree.chain().tween_method(func(taille: float): titre.add_theme_font_size_override("font_size", roundi(taille)), 28.0, 18.0, 0.25)

func _actualiser_vie(_degats: float) -> void:
	var proportion := clampf(boss.vie / maxf(boss.vie_max, 1.0), 0.0, 1.0)
	if animation_vie: animation_vie.kill()
	animation_vie = create_tween()
	animation_vie.tween_property(vie, "value", proportion, 0.1)
	if animation_retard: animation_retard.kill()
	animation_retard = create_tween()
	# L'orange garde les dégâts récents visibles avant de rejoindre le feu des PV actuels.
	animation_retard.tween_interval(attente_degats)
	animation_retard.tween_property(retard, "value", proportion, duree_retard).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _fermer() -> void:
	if termine: return
	termine = true
	if animation_entree: animation_entree.kill()
	var fermeture := create_tween()
	fermeture.tween_property(panneau, "modulate:a", 0.0, 0.5)
	fermeture.tween_callback(queue_free)

func _exit_tree() -> void:
	# Ne pas réafficher un HUD caché par la mort ou la fermeture de la partie.
	for interface in informations:
		if is_instance_valid(interface):
			interface.retablir_apres_boss(self)

func _annoncer_colere() -> void:
	titre.text = "%s · ENRAGÉ" % boss.nom_boss.to_upper()
