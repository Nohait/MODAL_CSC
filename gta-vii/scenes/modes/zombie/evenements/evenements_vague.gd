extends Node3D

const DORE = preload("res://scenes/systemes/ennemis/ennemi_dore.gd")
@onready var vagues = get_node("../Salles/RoomManager")
@onready var extincteur = get_node("../player").extincteur
@onready var ambiance: WorldEnvironment = get_node("../Eclairage/Ambiance")
var composition: CompositionVague
var restant := 0.0
var environnement_initial: Environment
var energies := {}
var lampe: OmniLight3D
var mutations := {}
var modification: ModificateurElite
var annonce: VBoxContainer
var titre: Label
var detail: Label
var animation: Tween
var temps_annonce := 0.0
var encre: ShaderMaterial

func _ready() -> void:
	CatalogueEnnemis.ennemi_enregistre.connect(_ennemi_ajoute)
	# Une annonce centrale lisible, sans bloquer les commandes ni le sauvetage.
	var hud := CanvasLayer.new()
	hud.layer = 20
	add_child(hud)
	annonce = VBoxContainer.new()
	annonce.set_anchors_and_offsets_preset(Control.PRESET_TOP_WIDE)
	annonce.offset_top = 125
	annonce.mouse_filter = Control.MOUSE_FILTER_IGNORE
	hud.add_child(annonce)
	titre = Label.new()
	titre.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	titre.add_theme_font_override("font", preload("res://assets/fonts/Almendra-Bold.ttf"))
	titre.add_theme_font_size_override("font_size", 48)
	titre.add_theme_color_override("font_color", Color("ffd898"))
	titre.add_theme_color_override("font_outline_color", Color("271215"))
	titre.add_theme_constant_override("outline_size", 8)
	annonce.add_child(titre)
	encre = ShaderMaterial.new()
	encre.shader = preload("res://scenes/modes/zombie/evenements/titre_incandescent.gdshader")
	titre.material = encre
	detail = Label.new()
	detail.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	detail.add_theme_font_override("font", preload("res://assets/fonts/Oswald-SemiBold.ttf"))
	detail.add_theme_font_size_override("font_size", 20)
	detail.add_theme_constant_override("outline_size", 5)
	annonce.add_child(detail)
	annonce.hide()

func commencer(choix: CompositionVague) -> void:
	# Une mutation reste active pendant 60 s, même si la vague finit plus tôt.
	if mutation_en_cours():
		if choix != vagues.difficulte.composition_classique: _annoncer(choix.titre, "Mutation encore active")
		return
	terminer()
	composition = choix
	restant = choix.duree_effet
	if choix == vagues.difficulte.composition_classique: return
	var explication := ""
	match choix.evenement:
		"blackout":
			_changer_ambiance()
			ambiance.environment.ambient_light_energy = 0.12
			for lumiere in get_parent().find_children("*", "Light3D", true, false):
				# Garder les foyers lumineux ; couper le soleil et les appliques électriques.
				if lumiere is DirectionalLight3D or "applique" in str(lumiere.get_path()).to_lower():
					energies[lumiere] = lumiere.light_energy
			lampe = OmniLight3D.new()
			lampe.omni_range = 7.0
			lampe.light_energy = 1.2
			lampe.light_color = Color("bad5ed")
			get_node("../player").add_child(lampe)
			explication = "Éclairage coupé pendant %d s" % restant
		"double_horde": explication = "nombre d’ennemis doublé"
		"brouillard":
			_changer_ambiance()
			ambiance.environment.fog_enabled = true
			ambiance.environment.fog_density = 0.018
			ambiance.environment.fog_light_color = Color("68615a")
			ambiance.environment.fog_light_energy = 0.5
			ambiance.environment.fog_sky_affect = 0.0
			explication = "Visibilité réduite"
		"chaleur":
			extincteur.consommation_evenement = choix.multiplicateur_consommation
			explication = "La mousse se consomme plus vite"
		"panne":
			extincteur.vider_jet()
			extincteur.panne_evenement = true
			explication = "Extincteur indisponible pendant %d s" % restant
		"doree": explication = "Ennemis dorés · butin ×5"
		"mutation":
			modification = CatalogueEnnemis.MODIFICATEURS.pick_random()
			explication = "%s pour tous les ennemis mobiles · %d s" % [modification.titre, restant]
			for ennemi in CatalogueEnnemis.ennemis:
				if is_instance_valid(ennemi): _ennemi_ajoute(ennemi)
	_annoncer(choix.titre, explication)

func _annoncer(nom: String, texte: String) -> void:
	if animation != null: animation.kill()
	titre.text = nom.to_upper()
	detail.text = texte
	annonce.modulate.a = 0.0
	annonce.show()
	temps_annonce = 0.0
	annonce.pivot_offset = annonce.size / 2.0
	annonce.scale = Vector2.ONE * 1.08
	var mouvement := create_tween()
	mouvement.tween_property(annonce, "scale", Vector2.ONE, 0.35).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	SonsInterface.annoncer_vague(composition.evenement if composition != null else "")
	# Le fondu est séquentiel : apparition, lecture, puis disparition.
	animation = create_tween()
	animation.tween_property(annonce, "modulate:a", 1.0, 0.2)
	animation.tween_interval(2.8)
	animation.tween_property(annonce, "modulate:a", 0.0, 0.7)
	animation.tween_callback(annonce.hide)

func _changer_ambiance() -> void:
	environnement_initial = ambiance.environment
	# Dupliquer évite de modifier la ressource partagée avec le jeu classique.
	ambiance.environment = environnement_initial.duplicate()

func _ennemi_ajoute(ennemi: Node3D) -> void:
	if composition == null or not vagues.vague_en_cours or ennemi.is_queued_for_deletion() or ennemi.get("est_mort") == true: return
	if not is_instance_valid(vagues.salle_actuelle) or not vagues.salle_actuelle.is_ancestor_of(ennemi): return
	if composition.evenement == "doree":
		if not ennemi.has_node("Dore"):
			var effet = DORE.new()
			effet.name = "Dore"
			ennemi.add_child(effet)
	if mutation_en_cours() and ennemi.has_method("multiplicateur_vitesse") and not mutations.has(ennemi):
		var elite = ennemi.get_node_or_null("Elite")
		mutations[ennemi] = elite.definition if elite != null else null
		if elite != null: elite.retirer()
		CatalogueEnnemis.appliquer_elite(ennemi, modification)

func mutation_en_cours() -> bool:
	return composition != null and composition.evenement == "mutation" and restant > 0.0

func _process(delta: float) -> void:
	if annonce.visible:
		temps_annonce += delta
		encre.set_shader_parameter("horloge", temps_annonce)
	if composition == null: return
	# Les scripts des appliques peuvent faire scintiller leur lumière : imposer la coupure après eux.
	for lumiere in energies:
		if is_instance_valid(lumiere): lumiere.light_energy = energies[lumiere] * 0.12
	if restant > 0.0:
		restant = maxf(0.0, restant - delta)
		if restant == 0.0:
			var panne := composition.evenement == "panne"
			terminer()
			if panne: _annoncer("Mousse rétablie", "")

func fin_vague() -> void:
	if not mutation_en_cours(): terminer()

func terminer() -> void:
	if is_instance_valid(extincteur):
		extincteur.consommation_evenement = 1.0
		extincteur.panne_evenement = false
	if environnement_initial != null and is_instance_valid(ambiance):
		ambiance.environment = environnement_initial
		environnement_initial = null
	for lumiere in energies:
		if is_instance_valid(lumiere): lumiere.light_energy = energies[lumiere]
	energies.clear()
	if is_instance_valid(lampe): lampe.queue_free()
	for ennemi in mutations:
		if not is_instance_valid(ennemi) or ennemi.is_queued_for_deletion(): continue
		var elite = ennemi.get_node_or_null("Elite")
		if elite != null: elite.retirer()
		if mutations[ennemi] != null:
			CatalogueEnnemis.appliquer_elite(ennemi, mutations[ennemi])
		else:
			ennemi.set_meta("variante_glossaire", "normal")
	mutations.clear()
	composition = null
	restant = 0.0

func _exit_tree() -> void:
	terminer()
