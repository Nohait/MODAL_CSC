extends Node3D

@export var actif := true
@export_flags_3d_physics var masque_obstacles := 1048575
@export_range(0.04, 0.3, 0.01) var intervalle_detection := 0.08
var attente := 0.0
var duree_ecoulee := 0.0
var exclusions: Array[RID] = []
@onready var arme: Node3D = get_parent()

func _ready() -> void:
	var parent := get_parent()
	while parent != null:
		if parent is CollisionObject3D: exclusions.append(parent.get_rid())
		parent = parent.get_parent()

func _physics_process(delta: float) -> void:
	if not actif or arme.portions_jet.is_empty():
		duree_ecoulee = 0.0
		attente = 0.0
		return
	duree_ecoulee += delta
	attente -= delta
	if attente > 0.0: return
	attente = intervalle_detection
	var depart: Vector3 = arme.muzzle.global_position
	for cible in get_tree().get_nodes_in_group("foyers_extinguibles"):
		if not cible.extinguible or cible.intensite <= 0.0 or not cible.is_visible_in_tree(): continue
		if depart.distance_squared_to(cible.global_position) > pow(arme.portee_jet + cible.rayon_contact, 2): continue
		# Réutiliser la forme réelle du jet : portée progressive, angle et double jet compris.
		if not arme.cible_dans_jet(cible.global_position, cible.rayon_contact): continue
		var fin: Vector3 = cible.global_position
		fin.y = depart.y
		var rayon := PhysicsRayQueryParameters3D.create(depart, fin, masque_obstacles, exclusions)
		var contact := get_world_3d().direct_space_state.intersect_ray(rayon)
		if not contact.is_empty():
			var obstacle: Node = contact.collider
			# Toucher le meuble qui porte le feu est autorisé ; un autre objet bloque le jet.
			var touche_meuble: bool = is_instance_valid(cible.mobilier) and (obstacle == cible.mobilier or obstacle.is_ancestor_of(cible.mobilier))
			if not touche_meuble and not obstacle.is_ancestor_of(cible) and contact.position.distance_to(fin) > cible.rayon_contact: continue
		cible.recevoir_mousse(duree_ecoulee)
	duree_ecoulee = 0.0
