extends CharacterBody3D

@export_range(0.1, 2.0, 0.1) var duree := 2.0
@export_range(1.0, 20.0, 0.5) var rayon_attraction := 9.0
@export_range(1.0, 2.5, 0.05) var hauteur := 1.85
@export_group("Apparition")
@export_range(0.1, 0.5, 0.01) var duree_apparition := 0.22
@export_range(0.2, 1.5, 0.05) var rayon_apparition := 0.7
var effets: Node
var hitbox_radius := 0.6
var charge := false
var termine := false
var modele: Node3D

func _ready() -> void:
	add_to_group("leurres_mousse")
	# Couche dédiée : ni les joueurs ni l'escorte ne heurtent le mannequin.
	collision_layer = 32
	collision_mask = 0
	modele = preload("res://scenes/decors/ville/mobilier_annexe.gd").new()
	modele.modele_scene = preload("res://assets/tutoriel/mannequin/crash_dummy.glb")
	modele.hauteur = hauteur
	modele.suie = 0.15
	add_child(modele)
	var collision := CollisionShape3D.new()
	var forme := CapsuleShape3D.new()
	forme.radius = 0.45
	forme.height = hauteur
	collision.shape = forme
	collision.position.y = hauteur * 0.5
	add_child(collision)
	_animer_apparition()

func _animer_apparition() -> void:
	# Seul le visuel se déploie : collision, ciblage et durée restent actifs dès le dash.
	modele.scale = Vector3(0.55, 0.12, 0.55)
	var apparition := create_tween()
	apparition.tween_property(modele, "scale", Vector3(1.06, 1.04, 1.06), duree_apparition * 0.7).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	apparition.tween_property(modele, "scale", Vector3.ONE, duree_apparition * 0.3).set_trans(Tween.TRANS_SINE)
	var mousse = preload("res://scenes/systemes/ameliorations/classique/explosion_mousse.tscn").instantiate()
	mousse.rayon = rayon_apparition
	mousse.duree = 0.35
	mousse.densite = 32
	mousse.taille_nuages = 0.5
	add_child(mousse)

func _physics_process(delta: float) -> void:
	if termine: return
	if not _effets_autorises():
		annuler()
		return
	duree -= delta
	if duree <= 0.0: _disparaitre(null)

func charger() -> void:
	if charge or termine: return
	charge = true
	var mousse := StandardMaterial3D.new()
	mousse.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mousse.albedo_color = Color(0.85, 0.96, 1.0, 0.8)
	mousse.roughness = 1.0
	for mesh in modele.find_children("*", "MeshInstance3D", true, false): mesh.material_overlay = mousse
	effets.bouffee(global_position + Vector3.UP)

func recevoir_coup(auteur: Node3D) -> void:
	if not termine: _disparaitre(auteur)

func _effets_autorises() -> bool:
	return is_instance_valid(effets) and not effets.joueur.est_mort and not effets.gestion.room_manager.transition_en_cours \
		and effets.gestion.room_manager.salle_actuelle == get_parent()

func _disparaitre(auteur: Node3D) -> void:
	if termine: return
	termine = true
	if _effets_autorises():
		if effets.valeur("plastron_mousse") > 0.0 and is_instance_valid(auteur) and not auteur.is_queued_for_deletion() and auteur.is_in_group("enemies") and auteur.get("est_mort") != true:
			effets.etat(auteur).enrobage_restant = 3.0
		if charge and effets.valeur("prise_piege") > 0.0:
			effets.propager_enrobage(global_position)
			var projection = preload("res://scenes/systemes/ameliorations/classique/explosion_mousse.tscn").instantiate()
			projection.rayon = effets.valeur("reaction_chaine")
			projection.position = position
			# L'effet survit au mannequin, mais reste attaché à sa salle.
			get_parent().add_child(projection)
	queue_free()

func annuler() -> void:
	# Aucune projection lors d'une transition, d'une mort du joueur ou du nettoyage.
	termine = true
	queue_free()
