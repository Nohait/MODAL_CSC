extends Node3D

@export var voiture: NodePath
@export var modele_intact: PackedScene = preload("res://assets/modeles/parking/berline.glb")
@export_range(2.0, 7.0, 0.1) var longueur_voiture := 4.6
@export_range(6.0, 20.0, 0.5) var taille_explosion := 18.0
@export_range(0.05, 1.0, 0.01) var instant_remplacement := 0.24
@export_range(-20.0, 6.0, 1.0) var volume_db := 0.0
@export_range(10.0, 100.0, 1.0) var portee_son := 80.0
@export_range(0.0, 1.5, 0.05) var force_secousse := 0.55
@export_range(0.1, 2.0, 0.05) var duree_secousse := 0.65
@export var explosion_haute_definition := true
@export_range(24, 128, 8) var precision_explosion := 80
@export_range(10.0, 100.0, 5.0) var densite_fumee := 65.0
@export_range(0.5, 8.0, 0.1) var luminosite_explosion := 3.6
var explose := false
var berline: Node3D
var carcasse: Node3D
var decor: Node3D

func _ready() -> void:
	var reglages := get_node_or_null("/root/Reglages")
	var detaille: bool = explosion_haute_definition and (reglages == null or reglages.graphismes.indice != 0)
	preload("res://scenes/effets/combat/explosion_essence.gd").preparer_volumes(detaille)
	decor = get_node(voiture)
	carcasse = decor.get_node("Modele")
	berline = modele_intact.instantiate()
	berline.name = "VoitureAvantExplosion"
	decor.add_child(berline)
	# Ajuster une échelle uniforme : la carrosserie conserve ses proportions.
	var limites := AABB()
	var premiere := true
	for morceau: MeshInstance3D in berline.find_children("*", "MeshInstance3D", true, false):
		if morceau.mesh == null: continue
		var boite: AABB = (berline.global_transform.affine_inverse() * morceau.global_transform) * morceau.get_aabb()
		limites = boite if premiere else limites.merge(boite)
		premiere = false
		# Dupliquer les matériaux évite de noircir les voitures du Parking.
		for i in morceau.mesh.get_surface_count():
			var original := morceau.get_active_material(i)
			if original is StandardMaterial3D:
				var sale: StandardMaterial3D = original.duplicate()
				sale.albedo_color *= Color(0.6, 0.55, 0.5)
				sale.roughness = maxf(sale.roughness, 0.65)
				morceau.set_surface_override_material(i, sale)
	if not premiere:
		var facteur := longueur_voiture / maxf(limites.size.x, limites.size.z)
		berline.scale = Vector3.ONE * facteur
		berline.position = -Vector3(limites.get_center().x, limites.position.y, limites.get_center().z) * facteur
	carcasse.hide()

func declencher() -> void:
	if explose: return
	explose = true
	decor.get_node("Flammes").hide()
	var effet := preload("res://scenes/effets/combat/explosion_essence.gd").new()
	effet.taille = taille_explosion
	effet.volume_db = volume_db
	effet.portee_son = portee_son
	effet.haute_definition = explosion_haute_definition
	effet.qualite_volume = precision_explosion
	effet.densite_fumee = densite_fumee
	effet.luminosite_feu = luminosite_explosion
	effet.instant_remplacement = instant_remplacement
	# L'effet annonce les instants de changement, synchronisés avec ses volumes.
	effet.remplacement_demande.connect(_montrer_carcasse)
	# L'effet reste dans le monde, indépendamment de l'orientation de la voiture.
	get_parent().add_child(effet)
	effet.global_position = decor.global_position
	var camera := get_viewport().get_camera_3d()
	if camera != null:
		for joueur in get_tree().get_nodes_in_group("player"):
			if joueur.has_method("secouer_camera"): joueur.secouer_camera(force_secousse, duree_secousse)

func _montrer_carcasse() -> void:
	berline.hide()
	carcasse.show()
	# L'incendie persistant reprend dès le remplacement, sous l'explosion encore active.
	decor.get_node("Flammes").show()

func restaurer_palier() -> void:
	# Une reprise après la vague 10 montre directement l'épave, sans rejouer le son.
	explose = true
	_montrer_carcasse()
