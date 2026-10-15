extends RefCounted

const ETAPES = preload("res://scenes/modes/tutoriel/debug/etapes_debug.gd")
var scene: Node
var proteger_victimes := false
var suspendre_ennemis := false
var reperes := false
var modes_ennemis: Dictionary = {}
var marqueurs: Node3D
var collisions_initiales := false
var navigation_initiale := false
var transition_en_cours := false

func _init(niveau: Node) -> void:
	scene = niveau
	collisions_initiales = scene.get_tree().debug_collisions_hint
	navigation_initiale = scene.get_tree().debug_navigation_hint

func contexte() -> Dictionary:
	return scene.debug_contexte()

func activer() -> void:
	# Ne jamais réactiver les récompenses pendant une session qui a été forcée.
	Engine.set_meta("tutoriel_debug_actif", true)

func rejoindre(identifiant: String) -> void:
	if transition_en_cours: return
	var fiche := ETAPES.definition(identifiant)
	if fiche.is_empty(): return
	transition_en_cours = true
	activer()
	reinitialiser()
	Engine.set_meta("tutoriel_debug_depart", identifiant)
	scene.get_tree().paused = false
	Reglages.chargement.ouvrir(fiche.scene)

func restaurer() -> void:
	activer()
	var joueur = contexte().joueur
	if joueur.est_mort: return
	joueur.BarreDeVie.value = joueur.BarreDeVie.max_value
	joueur.extincteur.stop_primary_attack()
	joueur.extincteur.vider_jet()
	joueur.extincteur.charge = joueur.extincteur.max_charge
	joueur.extincteur.is_overheated = false
	joueur.extincteur.attente_recharge = 0

func invulnerabilite(active: bool) -> void:
	activer()
	contexte().joueur.invincible = active

func vitesse(valeur: float) -> void:
	activer()
	Engine.time_scale = valeur

func protection_victimes(active: bool) -> void:
	activer()
	proteger_victimes = active
	actualiser_aides()

func activite_ennemie_suspendue(active: bool) -> void:
	activer()
	suspendre_ennemis = active
	actualiser_aides()

func liberer() -> void:
	var victime = contexte().get("victime")
	if not is_instance_valid(victime) or victime.is_freed or victime.est_morte: return
	activer()
	victime.free_victim()

func eteindre() -> void:
	activer()
	for foyer in contexte().get("foyers_exercice", []):
		foyer.recevoir_mousse(foyer.duree_extinction + 0.01)

func vaincre() -> void:
	var ennemi = contexte().get("ennemi")
	if not is_instance_valid(ennemi) or ennemi.est_mort: return
	activer()
	ennemi.prendre_degats(1000000000.0, &"mousse")

func actualiser_aides() -> void:
	for corps in scene.find_children("*", "CharacterBody3D", true, false):
		if corps.has_method("free_victim"):
			corps.set_meta("protection_debug_tutoriel", proteger_victimes)
		if not corps.has_method("choisir_cible"): continue
		var identifiant := corps.get_instance_id()
		if suspendre_ennemis:
			if not modes_ennemis.has(identifiant): modes_ennemis[identifiant] = corps.process_mode
			corps.process_mode = Node.PROCESS_MODE_DISABLED
		elif modes_ennemis.has(identifiant):
			corps.process_mode = modes_ennemis[identifiant]
			modes_ennemis.erase(identifiant)

func afficher_reperes(active: bool) -> void:
	activer()
	reperes = active
	scene.get_tree().debug_collisions_hint = active or collisions_initiales
	scene.get_tree().debug_navigation_hint = active or navigation_initiale
	if is_instance_valid(marqueurs): marqueurs.queue_free()
	if not active: return
	marqueurs = Node3D.new()
	scene.add_child(marqueurs)
	for emplacement: Vector3 in contexte().get("reperes", []):
		var mesh := MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = 0.15
		sphere.height = 0.3
		mesh.mesh = sphere
		mesh.position = emplacement + Vector3.UP * 0.25
		marqueurs.add_child(mesh)

func reinitialiser() -> void:
	contexte().joueur.invincible = false
	proteger_victimes = false
	suspendre_ennemis = false
	actualiser_aides()
	Engine.time_scale = 1.0
	if is_instance_valid(marqueurs): marqueurs.queue_free()
	reperes = false
	scene.get_tree().debug_collisions_hint = collisions_initiales
	scene.get_tree().debug_navigation_hint = navigation_initiale

func diagnostic() -> String:
	var c := contexte()
	var joueur = c.joueur
	var arme = joueur.extincteur
	var foyers_actifs := 0
	for foyer in c.get("foyers", []):
		if foyer.intensite > 0: foyers_actifs += 1
	var victime = c.get("victime")
	var captive: bool = is_instance_valid(victime) and not victime.is_freed and not victime.est_morte
	var ennemi = c.get("ennemi")
	var texte := "Salle : %s\nÉtape : %s\nObjectif : %s\nAcquis : %s\nManquant : %s\n" % [c.salle, c.etape, c.objectif, ", ".join(c.get("acquis", [])), ", ".join(c.get("manquants", []))]
	texte += "Vie %.0f/%.0f · réserve %.0f/%.0f · dash %s (%.2f s)\n" % [joueur.BarreDeVie.value, joueur.BarreDeVie.max_value, arme.charge, arme.max_charge, "actif" if joueur.is_dashing else "repos", maxf(0, joueur.dash_cooldown_left)]
	texte += "Victimes : captives %d · escorte %d · prises en charge %d\n" % [int(captive), c.escorte.freed_victims.size(), c.get("prises_en_charge", 0)]
	texte += "Ennemis restants : %d (actifs %d) · foyers actifs : %d · passage : %s · sortie : %s\n" % [c.get("ennemis_restants", 0), int(is_instance_valid(ennemi) and not ennemi.est_mort), foyers_actifs, c.get("passage", "sans objet"), c.get("sortie", "sans objet")]
	texte += "DEBUG %s · joueur invulnérable %s · victimes protégées %s · ennemis suspendus %s · repères %s · vitesse ×%.2f" % [Engine.get_meta("tutoriel_debug_actif", false), joueur.invincible, proteger_victimes, suspendre_ennemis, reperes, Engine.time_scale]
	return texte
