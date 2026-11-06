extends Node

var effets: Node
var armee := true
@onready var gestion = effets.gestion
@onready var arme = gestion.extincteur
var indicateur: Control

func _ready() -> void:
	arme.reserve_classique = self
	arme.tir_relache.connect(_relacher)
	indicateur = preload("res://scenes/systemes/ameliorations/classique/indicateur_coupure.gd").new()
	indicateur.reserve = self
	gestion.joueur.get_node("Interface/Reserve/Jauge/Remplissage").add_child(indicateur)
	indicateur.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)

func definition(id: StringName) -> Amelioration:
	return gestion.catalogue_ameliorations.trouver(id) if effets.valeur(id) > 0.0 else null

func proportion() -> float:
	return clampf(arme.charge / maxf(arme.max_charge, 0.01), 0.0, 1.0)

func facteur_largeur() -> float:
	var carte := definition(&"dernier_metre")
	return lerpf(carte.largeur_minimale, 1.0, proportion()) if carte != null else 1.0

func facteur_degats() -> float:
	return 1.0 + effets.valeur(&"dernier_metre") * (1.0 - proportion()) / 100.0

func _physics_process(_delta: float) -> void:
	var carte := definition(&"coupure_nette")
	if carte != null and proportion() * 100.0 > carte.seuil_rearmement: armee = true
	indicateur.visible = carte != null
	if carte != null: indicateur.queue_redraw()

func _relacher() -> void:
	var carte := definition(&"coupure_nette")
	if carte == null or not armee or proportion() * 100.0 > carte.seuil_reserve: return
	if gestion.joueur.est_mort or gestion.joueur.entree_automatique or gestion.room_manager.transition_en_cours: return
	armee = false
	var fusion := definition(&"coup_de_pointe")
	if fusion != null: carte = fusion
	var origine: Vector3 = arme.muzzle.global_position
	var direction: Vector3 = arme.direction_jet()
	var angle := deg_to_rad(carte.demi_angle)
	# Une puissance fixe : la réserve décide du déclenchement, pas des dégâts de la bouffée.
	for ennemi in effets.ennemis_proches(origine, carte.rayon):
		var ecart: Vector3 = ennemi.global_position - origine
		ecart.y = 0.0
		if ecart.length_squared() > 0.001 and direction.dot(ecart.normalized()) < cos(angle): continue
		effets.infliger(ennemi, carte.valeur, &"mousse")
		if is_instance_valid(ennemi) and not ennemi.is_queued_for_deletion() and ennemi.get("est_mort") != true:
			effets.etat(ennemi).repousser(direction, carte.force_recul, carte.duree_recul, true)
	var visuel = preload("res://scenes/systemes/ameliorations/classique/bouffee_directionnelle.tscn").instantiate()
	visuel.distance = carte.rayon
	visuel.demi_angle = carte.demi_angle
	visuel.position = gestion.room_manager.salle_actuelle.to_local(origine)
	gestion.room_manager.salle_actuelle.add_child(visuel)
	visuel.look_at(origine + direction, Vector3.UP)
