extends Control

@export var logo: Texture2D = preload("res://assets/textures/interfaces/ameliorations/icone_victimes.svg")
@export var couleur := Color(0, 0.556863, 0.368627)
@export_range(16.0, 48.0, 1.0) var taille := 26.0
@export_range(30.0, 100.0, 1.0) var marge := 48.0
@export_range(25.0, 100.0, 1.0) var decalage_visible := 44.0
@export_range(0.1, 0.5, 0.05) var seuil_critique := 0.25
@export_range(0.2, 2.0, 0.1) var periode_alerte := 0.7
@export_range(0.5, 5.0, 0.1) var duree_mort := 2.0

var reperes: Dictionary = {}
var horloge := 0.0
var joueur: Node3D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func _process(delta: float) -> void:
	horloge += delta
	for victime in get_tree().get_nodes_in_group("victims"):
		if not _admissible(victime):
			continue
		var identifiant: int = victime.get_instance_id()
		if not reperes.has(identifiant):
			reperes[identifiant] = {"victime": weakref(victime), "position": victime.global_position, "mort": -1.0}
			var rappel := _sur_mort.bind(identifiant)
			if not victime.died.is_connected(rappel):
				victime.died.connect(rappel)
	for identifiant in reperes.keys():
		var repere: Dictionary = reperes[identifiant]
		if repere.mort >= 0.0:
			if horloge - repere.mort >= duree_mort:
				reperes.erase(identifiant)
			continue
		var victime: Node3D = repere.victime.get_ref()
		if not is_instance_valid(victime) or not _admissible(victime):
			reperes.erase(identifiant)
		else:
			repere.position = victime.global_position
	queue_redraw()

func _admissible(victime: Node3D) -> bool:
	return victime.is_visible_in_tree() and victime.can_process() and not victime.is_freed and not victime.est_morte

func _sur_mort(victime: Node3D, identifiant: int) -> void:
	if not reperes.has(identifiant):
		return
	reperes[identifiant].position = victime.global_position
	reperes[identifiant].mort = horloge

func _draw() -> void:
	var camera := get_viewport().get_camera_3d()
	if camera == null or not is_instance_valid(joueur) or not joueur.is_visible_in_tree():
		return
	var zone := get_viewport_rect().grow(-marge)
	var centre := zone.get_center()
	_dessiner_rassemblement(camera, zone)
	for repere: Dictionary in reperes.values():
		var monde: Vector3 = repere.position + Vector3.UP
		var projection := camera.unproject_position(monde)
		var derriere := camera.is_position_behind(monde)
		var direction := Vector2.UP
		var position_repere := projection + Vector2.UP * decalage_visible
		var hors_champ := derriere or not get_viewport_rect().has_point(projection)
		if hors_champ:
			var vers_bord := projection - centre
			if derriere:
				vers_bord = -vers_bord
			if vers_bord.is_zero_approx():
				vers_bord = Vector2.DOWN
			direction = vers_bord.normalized()
			var facteur := minf(zone.size.x * 0.5 / maxf(absf(direction.x), 0.001), zone.size.y * 0.5 / maxf(absf(direction.y), 0.001))
			position_repere = centre + direction * facteur
		else:
			position_repere = position_repere.clamp(zone.position, zone.end)
		_dessiner_repere(position_repere, direction, repere, hors_champ)

func _dessiner_rassemblement(camera: Camera3D, zone: Rect2) -> void:
	var gestion = joueur.get_node_or_null("../VictimManager")
	if not is_instance_valid(gestion): return
	var cible: Node3D = gestion.cible_deplacement
	if not is_instance_valid(cible) or not cible.is_in_group("fleche"): return
	var monde: Vector3 = cible.get_meta("position_rassemblement", cible.global_position)
	monde += Vector3.UP * 1.4
	var projection := camera.unproject_position(monde)
	var derriere := camera.is_position_behind(monde)
	var hors_champ := derriere or not get_viewport_rect().has_point(projection)
	var direction := Vector2.UP
	var centre := projection.clamp(zone.position, zone.end)
	if hors_champ:
		var vers_bord := projection - zone.get_center()
		if derriere: vers_bord = -vers_bord
		if vers_bord.is_zero_approx(): vers_bord = Vector2.DOWN
		direction = vers_bord.normalized()
		var facteur := minf(zone.size.x * 0.5 / maxf(absf(direction.x), 0.001), zone.size.y * 0.5 / maxf(absf(direction.y), 0.001))
		centre = zone.get_center() + direction * facteur
	# Chaque victime possède son propre compteur ; le premier expiré rappelle l'escorte.
	var restant := INF
	var duree := 0.0
	for victime in gestion.freed_victims:
		if not is_instance_valid(victime) or victime.est_morte or not victime.decompte_rassemblement_actif: continue
		if victime.waiting_timer < restant:
			restant = victime.waiting_timer
			duree = victime.waiting_cooldown
	if not is_finite(restant): return
	var teinte := couleur
	if restant <= duree * seuil_critique:
		teinte.a = lerpf(0.45, 1.0, (sin(horloge * TAU / periode_alerte) + 1.0) * 0.5)
	var fond := Color(0.96, 0.97, 0.98, 0.95)
	draw_circle(centre, taille * 0.58, fond)
	# Cadran dessiné avec les primitives du HUD, sans nouvel asset.
	var rayon := taille * 0.60
	draw_arc(centre, rayon, 0.0, TAU, 32, teinte, 4.0, true)
	draw_line(centre, centre + Vector2(0, -rayon * 0.65), teinte, 3.5, true)
	draw_line(centre, centre + Vector2(rayon * 0.5, 0), teinte, 3.5, true)
	var barre := Rect2(centre + Vector2(-taille * 0.6, taille * 0.65 + 4.0), Vector2(taille * 1.2, 5.0))
	draw_rect(barre, Color(0.78, 0.9, 0.83, 1.0))
	barre.size.x *= clampf(restant / maxf(duree, 0.001), 0.0, 1.0)
	draw_rect(barre, teinte)

func _dessiner_repere(centre: Vector2, direction: Vector2, repere: Dictionary, hors_champ: bool) -> void:
	var mort: bool = repere.mort >= 0.0
	var victime: Node3D = repere.victime.get_ref()
	var vie := 0.0
	if not mort and is_instance_valid(victime):
		vie = clampf(float(victime.vie) / maxf(float(victime.vie_max), 0.001), 0.0, 1.0)
	var teinte := couleur
	if mort:
		teinte = Color(0.929412, 0.32549, 0.333333)
	elif vie <= seuil_critique:
		teinte = Color(0.772549, 0.176471, 0.184314)
		teinte.a = lerpf(0.45, 1.0, (sin(horloge * TAU / periode_alerte) + 1.0) * 0.5)
	var fond := Color(0.062745, 0.062745, 0.062745, 0.9)
	draw_circle(centre, taille * 0.65, fond)
	if mort:
		var rayon := taille * 0.23
		draw_line(centre - Vector2(rayon, rayon), centre + Vector2(rayon, rayon), teinte, 3.0, true)
		draw_line(centre + Vector2(-rayon, rayon), centre + Vector2(rayon, -rayon), teinte, 3.0, true)
		var police := get_theme_default_font()
		var texte := "Décédée"
		var largeur := police.get_string_size(texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
		draw_string_outline(police, centre + Vector2(-largeur / 2.0, taille + 17.0), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, 4, fond)
		draw_string(police, centre + Vector2(-largeur / 2.0, taille + 17.0), texte, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, teinte)
	else:
		draw_texture_rect(logo, Rect2(centre - Vector2.ONE * taille * 0.5, Vector2.ONE * taille), false, teinte)
		if hors_champ:
			var pointe := centre + direction * (taille * 0.65 + 9.0)
			var base := pointe - direction * 8.0
			var cote := direction.orthogonal() * 4.0
			draw_colored_polygon(PackedVector2Array([pointe, base + cote, base - cote]), teinte)
	if hors_champ:
		var barre := Rect2(centre + Vector2(-taille * 0.6, taille * 0.65 + 3.0), Vector2(taille * 1.2, 4.0))
		draw_rect(barre.grow(1.0), fond)
		barre.size.x *= vie
		draw_rect(barre, teinte)
