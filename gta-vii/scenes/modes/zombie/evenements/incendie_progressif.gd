extends Node3D

@export_range(1.0, 10.0, 0.5) var delai_avertissement := 4.0
@export_range(0.5, 5.0, 0.1) var rayon := 2.6
@export_range(0.2, 2.0, 0.1) var taille_flammes := 2.0
@export var positions_foyers: Array[Vector3] = [Vector3(-1.4, 0.6, 0), Vector3(0, 0.95, 0), Vector3(1.4, 0.6, 0)]
@export_range(0.0, 5.0, 0.1) var energie_lumiere := 3.4
@export_range(1.0, 10.0, 0.5) var portee_lumiere := 8.0
@export_range(0.1, 3.0, 0.1) var duree_embrasement := 0.9
@export_range(0.0, 1.0, 0.05) var decalage_foyers := 0.15
var declenche := false
var actif := false
var attente := 0.0
var avertissement: MeshInstance3D

func _ready() -> void:
	set_physics_process(false)

func declencher() -> void:
	if declenche: return
	declenche = true
	attente = delai_avertissement
	# Un disque orange annonce l’embrasement décoratif, sans bloquer le passage.
	avertissement = MeshInstance3D.new()
	var disque := CylinderMesh.new()
	disque.top_radius = rayon
	disque.bottom_radius = rayon
	disque.height = 0.02
	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = Color(1.0, 0.3, 0.03, 0.25)
	disque.material = mat
	avertissement.mesh = disque
	avertissement.position.y = 0.045
	avertissement.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(avertissement)
	set_physics_process(true)

func _physics_process(delta: float) -> void:
	if not actif:
		attente -= delta
		var progression := 1.0 - maxf(attente, 0.0) / delai_avertissement
		avertissement.scale = Vector3.ONE * (0.85 + 0.15 * progression)
		if attente <= 0.0: _allumer()
		return

func _allumer() -> void:
	actif = true
	# Une fois allumé, ce décor n’a plus besoin de surveiller la physique.
	set_physics_process(false)
	avertissement.queue_free()
	for i in positions_foyers.size():
		var foyer = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn").instantiate()
		foyer.position = positions_foyers[i]
		foyer.taille = taille_flammes
		foyer.densite_fumee = 1.0 if i == 1 else 0.4
		foyer.energie = energie_lumiere if i == 1 else 0.0
		foyer.portee_lumiere = portee_lumiere
		add_child(foyer)
		# Plusieurs foyers couvrent la carrosserie, avec une seule lumière et un seul son.
		if i != 1:
			foyer.get_node("Lumiere").hide()
			foyer.get_node("Crepitement").stop()
		foyer.scale = Vector3.ONE * 0.25
		var embrasement := create_tween()
		# Le léger décalage propage les flammes du capot jusqu'à l'arrière.
		embrasement.tween_interval(i * decalage_foyers)
		embrasement.tween_property(foyer, "scale", Vector3.ONE, duree_embrasement).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
