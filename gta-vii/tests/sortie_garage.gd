extends SceneTree
func _initialize() -> void:
	verifier.call_deferred()
func verifier() -> void:
	var garage = load("res://scenes/modes/zombie/apparitions/garage_arrivee.tscn").instantiate()
	root.add_child(garage)
	garage.preparer(2.8)
	var figurant := Node3D.new()
	var destination: Vector3 = garage.ajouter_visuel(figurant, 0.0, 0)
	garage._process(1.4)
	assert(garage.fraction_ouverte > 0.99)
	assert(figurant.position.z > -1.0 and figurant.global_position.distance_to(destination) > 0.1)
	assert(garage.gyrophare.light_energy > 0.0 and garage.lampe_rampe.light_energy > 0.0)
	garage._process(1.4)
	assert(figurant.global_position.distance_to(destination) < 0.01)
	garage.terminer()
	garage.queue_free()
	await process_frame
	print("SORTIE_GARAGE_PROGRESSIVE_OK")
	quit()
