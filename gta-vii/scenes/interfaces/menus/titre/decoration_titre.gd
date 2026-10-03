extends Node3D

const POMPIER = preload("res://scenes/joueur/player_pompier.tscn")
const SBIRE = preload("res://assets/modeles/ennemis/fire_elemental.glb")
const FLAMMES = preload("res://scenes/effets/feu/flames.tscn")
const SOL = preload("res://assets/materiaux/sol_carbonise.tres")
const MUR = preload("res://assets/materiaux/mur_abime.tres")
var temps := 0.0
var lumiere_feu: OmniLight3D

func _ready() -> void:
	# Seulement les modèles visuels : ni IA, ni attaque, ni interface du joueur.
	var pompier = POMPIER.instantiate()
	pompier.scale *= 0.125
	# Comme dans player.tscn, l'origine du modèle est au centre du personnage.
	pompier.position = Vector3(-0.6, 1.1, 0.7)
	pompier.rotation.y += 0.65
	add_child(pompier)
	pompier.get_node("visual/Armature/AnimationTree").active = false
	pompier.get_node("visual/Armature/AnimationPlayer").play("Idle/Idle")
	var sbire = SBIRE.instantiate()
	sbire.position = Vector3(1.6, 0.0, -2.4)
	add_child(sbire)
	_normaliser_modele(sbire, 2.6)
	for position_feu in [Vector3(1.6, 0.3, -2.4), Vector3(-2.8, 0.0, -3.5), Vector3(3.0, 0.0, -4.5)]:
		var flammes = FLAMMES.instantiate()
		flammes.position = position_feu
		flammes.scale = Vector3.ONE * 1.5
		add_child(flammes)
	_bloc(Vector3(0, -0.15, -1.0), Vector3(14, 0.3, 16), SOL)
	_bloc(Vector3(0, 2, -6), Vector3(14, 4, 0.3), MUR)
	_bloc(Vector3(-4.5, 2, -1), Vector3(0.3, 4, 10), MUR)
	lumiere_feu = OmniLight3D.new()
	lumiere_feu.position = Vector3(1.2, 1.8, -1.8)
	lumiere_feu.light_color = Color("ff852f")
	lumiere_feu.omni_range = 9.0
	add_child(lumiere_feu)

func _process(delta: float) -> void:
	temps += delta
	# Deux fréquences donnent une lumière de feu moins mécanique qu'un seul sinus.
	lumiere_feu.light_energy = 2.0 + sin(temps * 5.0) * 0.15 + sin(temps * 8.7) * 0.1

func _bloc(position_bloc: Vector3, taille: Vector3, mat: Material) -> void:
	var visuel := MeshInstance3D.new()
	var mesh := BoxMesh.new()
	mesh.size = taille
	mesh.material = mat
	visuel.mesh = mesh
	visuel.position = position_bloc
	add_child(visuel)

func _normaliser_modele(modele: Node3D, hauteur: float) -> void:
	# Les modèles importés n'ont pas la même unité ; mesurer leur hauteur évite une échelle arbitraire.
	var limites := AABB()
	var premier := true
	for enfant in modele.find_children("*", "MeshInstance3D", true, false):
		var boite: AABB = (modele.global_transform.affine_inverse() * enfant.global_transform) * enfant.get_aabb()
		limites = boite if premier else limites.merge(boite)
		premier = false
	if limites.size.y > 0.0:
		var facteur := hauteur / limites.size.y
		modele.scale *= facteur
		modele.position.y -= limites.position.y * facteur
