extends SceneTree

class CibleTest extends CharacterBody3D:
	var vie := 100.0
	func prendre_degats(degats: float) -> void:
		vie -= degats

func _initialize() -> void:
	verifier.call_deferred()

func verifier() -> void:
	var incendie = load("res://scenes/modes/zombie/evenements/incendie_progressif.gd").new()
	incendie.delai_avertissement = 0.1
	root.add_child(incendie)
	var cibles: Array[CibleTest] = []
	for couche in [2, 8, 4]:
		var cible := CibleTest.new()
		cible.collision_layer = couche
		cible.collision_mask = 0
		var collision := CollisionShape3D.new()
		collision.shape = SphereShape3D.new()
		cible.add_child(collision)
		root.add_child(cible)
		cible.position.y = 0.5
		cibles.append(cible)
	incendie.declencher()
	assert(not incendie.actif, "L'avertissement doit précéder le feu.")
	incendie.declencher()
	assert(incendie.get_child_count() == 1, "Un palier restauré ne doit pas doubler le foyer.")
	await create_timer(0.7).timeout
	assert(incendie.actif)
	assert(cibles[0].vie == 100.0 and cibles[1].vie == 100.0, "Cet incendie doit rester décoratif.")
	assert(cibles[2].vie == 100.0, "Les ennemis ne doivent pas recevoir ces dégâts.")
	incendie.queue_free()
	for cible in cibles: cible.queue_free()
	await process_frame
	print("INCENDIE_PARKING_DECORATIF_OK")
	quit()
