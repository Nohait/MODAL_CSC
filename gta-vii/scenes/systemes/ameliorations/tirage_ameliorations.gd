extends RefCounted

const RARETES: Array[StringName] = [&"commun", &"rare", &"epique"]

static func tirer(pool: Array[Amelioration], poids: Vector3, puissances: Vector3, nombre: int = 3) -> Array[Dictionary]:
	var disponibles := pool.duplicate()
	var choix: Array[Dictionary] = []
	for i in range(mini(nombre, disponibles.size())):
		var groupes: Array = [[], [], []]
		for definition in disponibles:
			for indice in range(3):
				if definition.puissance_variable or definition.rarete == String(RARETES[indice]):
					groupes[indice].append(definition)
		var poids_effectifs := Vector3.ZERO
		for indice in range(3):
			if not groupes[indice].is_empty(): poids_effectifs[indice] = maxf(0.0, poids[indice])
		# Si une rareté n'a plus de carte, redistribuer automatiquement les chances.
		var total := poids_effectifs.x + poids_effectifs.y + poids_effectifs.z
		if total == 0.0:
			for indice in range(3):
				if not groupes[indice].is_empty(): poids_effectifs[indice] = 1.0
			total = poids_effectifs.x + poids_effectifs.y + poids_effectifs.z
		var hasard := randf() * total
		var rarete_choisie := 0
		for indice in range(3):
			if poids_effectifs[indice] <= 0.0: continue
			rarete_choisie = indice
			if hasard < poids_effectifs[indice]:
				rarete_choisie = indice
				break
			hasard -= poids_effectifs[indice]
		var definition: Amelioration = groupes[rarete_choisie].pick_random()
		choix.append(proposition(definition, RARETES[rarete_choisie], puissances[rarete_choisie] / 100.0))
		# Retirer toute la définition empêche deux versions de la même carte dans un choix.
		disponibles.erase(definition)
	return choix

static func proposition(definition: Amelioration, rarete: StringName, multiplicateur: float) -> Dictionary:
	return {"definition": definition,
		"rarete": rarete if definition.puissance_variable else StringName(definition.rarete),
		"multiplicateur": multiplicateur if definition.puissance_variable else 1.0}
