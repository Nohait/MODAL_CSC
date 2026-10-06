extends SceneTree

func _initialize() -> void:
	verifier.call_deferred()

func verifier() -> void:
	var decor := Node3D.new()
	root.add_child(decor)
	var fumee := CPUParticles3D.new()
	fumee.name = "Fumee"
	fumee.amount = 10
	decor.add_child(fumee)
	var ventilation = load("res://scenes/modes/zombie/equipements/ventilation.gd").new()
	ventilation.racine_fumee = NodePath("..")
	decor.add_child(ventilation)
	ventilation.armer()
	assert(ventilation.arme and fumee.amount == 10)
	var etat: Dictionary = ventilation.capturer_sauvegarde()
	ventilation._debut_vague(decor)
	assert(not ventilation.arme and fumee.amount == 2)
	ventilation._process(31.0)
	assert(fumee.amount == 10 and ventilation.temps_restant == 0.0)
	ventilation.restaurer_sauvegarde(etat)
	assert(ventilation.arme)
	decor.queue_free()
	await process_frame
	print("VENTILATION_ACHAT_VAGUE_RESTAURATION_OK")
	quit()
