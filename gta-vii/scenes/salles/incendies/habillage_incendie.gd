@tool
extends Resource
class_name HabillageIncendie

@export var actif := true
@export_range(0, 12) var nombre_depots := 7
@export_range(0.3, 1.0, 0.05) var largeur_gravats := 0.65
@export_range(0.0, 1.0, 0.05) var opacite_cendre := 0.4
@export_range(0, 100) var nombre_braises := 56
@export_range(0, 4) var nombre_foyers := 2
@export_range(0.2, 1.0, 0.05) var taille_foyers := 0.65
@export_range(1.0, 5.0, 0.25) var duree_braises := 3.5
@export_range(0.0, 2.0, 0.05) var force_vent := 0.8
@export_range(0.0, 1.5, 0.05) var force_rafales := 0.5
@export_range(3.0, 12.0, 0.5) var periode_rafales := 6.0

const FOYER = preload("res://scenes/decors/hall_incendie/foyer_incendie.tscn")
const GRAVATS = preload("res://assets/modeles/decors/hall_incendie/gravats_beton.glb")
const TRACE = preload("res://scenes/decors/hall_incendie/trace_incendie.tscn")
const GEOMETRIE = preload("res://scenes/decors/interieurs/geometrie_decorative.gd")

func appliquer(generateur: Node3D, decor: Node3D, bords: Array, hasard: RandomNumberGenerator, incendie: IncendieSalle = null) -> void:
	if not actif: return
	var parent := Node3D.new()
	parent.name = "RetombeesIncendie"
	decor.add_child(parent)
	var cellules: Array[Vector2i] = []
	var sources: Array[Node3D] = []
	for bord in bords:
		if cellules.size() >= nombre_depots: break
		var cellule: Vector2i = bord[0]
		# Réserver les arrivées, les portes et le mobilier ; les dépôts restent au pied des murs.
		if cellule not in generateur.cellules_disponibles or cellule in cellules: continue
		var normale := Vector3(bord[1].x, 0, bord[1].y)
		var tangente := Vector3(-normale.z, 0, normale.x)
		var position: Vector3 = generateur.position_cellule(cellule) + normale * 1.8 + tangente * hasard.randf_range(-0.8, 0.8)
		position.y = 0.105
		var support := Node3D.new()
		support.position = position
		support.rotation.y = hasard.randf_range(-PI, PI)
		parent.add_child(support)
		# Importer uniquement le modèle, sans le corps physique de la scène de gravats.
		var modele: Node3D = GRAVATS.instantiate()
		support.add_child(modele)
		GEOMETRIE.normaliser(modele, largeur_gravats * hasard.randf_range(0.7, 1.0), false)
		for surface: MeshInstance3D in modele.find_children("*", "MeshInstance3D", true, false):
			surface.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var trace: Node3D = TRACE.instantiate()
		trace.position = position - Vector3.UP * 0.014
		trace.rotation.y = support.rotation.y
		trace.scale = Vector3(hasard.randf_range(0.3, 0.5), 1.0, hasard.randf_range(0.3, 0.45))
		var surface: MeshInstance3D = trace.get_node("Suie")
		var mat: ShaderMaterial = surface.material_override.duplicate()
		mat.set_shader_parameter("teinte", Color(0.075, 0.07, 0.06, opacite_cendre))
		mat.set_shader_parameter("graine", hasard.randf_range(0, 100))
		surface.material_override = mat
		parent.add_child(trace)
		if cellules.size() < nombre_foyers:
			# Ces foyers au sol sont décoratifs et n'ajoutent aucun obstacle au passage.
			var feu: Node3D = FOYER.instantiate()
			feu.position = position
			feu.taille = taille_foyers
			feu.energie = 1.5
			if incendie != null: incendie.appliquer(feu)
			feu.get_node("Lumiere").shadow_enabled = false
			feu.get_node("Crepitement").volume_db = -16.0
			parent.add_child(feu)
			sources.append(feu)
		cellules.append(cellule)
	# Les braises viennent des incendies de la zone jouable, plutôt que d'un voile sur tout l'écran.
	for enfant in decor.get_children():
		if enfant.has_meta("incendie_renforce"):
			sources.append(enfant)
	if nombre_braises > 0 and not sources.is_empty(): _braises(parent, sources)

func _braises(_parent: Node3D, sources: Array[Node3D]) -> void:
	# Répartir le budget de la salle entre les émetteurs déjà présents dans les foyers.
	var par_foyer := nombre_braises / sources.size()
	var supplement := nombre_braises % sources.size()
	for i in range(sources.size()):
		var particules = sources[i].get_node("Braises")
		var nombre: int = par_foyer + (1 if i < supplement else 0)
		particules.amount = maxi(1, nombre)
		particules.emitting = nombre > 0
		particules.lifetime = duree_braises
		particules.force_vent = force_vent
		particules.force_rafales = force_rafales
		particules.periode_rafales = periode_rafales
		particules.direction = Vector3(0.65, 0.8, 0.3)
		particules.spread = 35.0
		particules.initial_velocity_min = 0.45
		particules.initial_velocity_max = 1.0
