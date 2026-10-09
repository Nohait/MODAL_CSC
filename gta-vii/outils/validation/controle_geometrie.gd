extends RefCounted

# Contrôles indépendants du placement : rectangles orientés des collisions et grille de sol.
const TOLERANCE := 0.015

static func verifier(generateur: Node3D, salle: Node3D) -> Array[Dictionary]:
	var problemes: Array[Dictionary] = []
	var murs: Array[Dictionary] = []
	var meubles: Array[Dictionary] = []
	for corps in salle.get_node("Navigation/Decor").get_children():
		for enfant in corps.get_children():
			if not enfant is CollisionShape3D or enfant.disabled or not enfant.shape is BoxShape3D:
				continue
			var boite := _boite(enfant)
			# Le contact avec le sol est voulu ; les murs et barrières commencent au-dessus.
			if boite.haut <= 0.31: continue
			boite["nom"] = str(corps.name)
			if corps.scene_file_path.is_empty(): murs.append(boite)
			else: meubles.append(boite)
	for i in range(meubles.size()):
		var meuble: Dictionary = meubles[i]
		for mur in murs:
			if _chevauche(meuble, mur):
				problemes.append({"type": "meuble_dans_mur", "objet": meuble.nom, "autre": mur.nom, "position": str(meuble.centre)})
		for j in range(i):
			if _chevauche(meuble, meubles[j]):
				problemes.append({"type": "meubles_superposes", "objet": meuble.nom, "autre": meubles[j].nom, "position": str(meuble.centre)})
		for coin in meuble.coins:
			if not _sur_sol(generateur, coin):
				problemes.append({"type": "meuble_hors_sol", "objet": meuble.nom, "position": str(coin)})
				break
	problemes.append_array(_verifier_pieces(generateur, salle))
	return problemes

static func _verifier_pieces(generateur: Node3D, salle: Node3D) -> Array[Dictionary]:
	var problemes: Array[Dictionary] = []
	var zones: Array[Rect2] = []
	for piece in salle.get_node("Habillage").get_children():
		var preparee: bool = piece.is_in_group("pieces_decoratives")
		if not preparee and piece.get_meta("type_espace_decoratif", "") != "procedural": continue
		# Lire la géométrie réelle des murs, pas l'emprise déclarée au générateur.
		var zones_piece: Array[Rect2] = []
		for surface in piece.get_children():
			if not surface is MeshInstance3D: continue
			if not surface.name.begins_with("Sol") and not surface.name.begins_with("Mur"): continue
			var boite: AABB = surface.transform * surface.get_aabb()
			if preparee:
				var fin := minf(boite.end.z, -0.25)
				if fin <= boite.position.z: continue
				boite.size.z = fin - boite.position.z
			boite = piece.transform * boite
			var zone := Rect2(Vector2(boite.position.x, boite.position.z), Vector2(boite.size.x, boite.size.z))
			for autre in zones:
				if zone.intersects(autre): problemes.append({"type": "pieces_decoratives_superposees", "objet": str(piece.name)})
			zones_piece.append(zone)
			for y in range(generateur.roomSize.y):
				for x in range(generateur.roomSize.x):
					if not generateur.grid[y][x] and not generateur.cellules_trous.has(Vector2i(x, y)): continue
					var case_sol := Rect2(Vector2(x * 5.0 - 2.5, y * 5.0 - 2.5), Vector2(5, 5))
					if zone.intersects(case_sol): problemes.append({"type": "piece_sur_salle_ou_trou", "objet": str(piece.name), "cellule": str(Vector2i(x, y))})
			for corps in salle.get_node("Navigation/Decor").get_children():
				for enfant in corps.get_children():
					if not enfant is CollisionShape3D or not enfant.shape is BoxShape3D: continue
					var collision := _boite(enfant)
					var obstacle := Rect2(collision.coins[0], Vector2.ZERO)
					for coin in collision.coins: obstacle = obstacle.expand(coin)
					if zone.intersects(obstacle): problemes.append({"type": "piece_dans_geometrie", "objet": str(piece.name), "autre": str(corps.name)})
		# Les sols et murs d'une même pièce se touchent volontairement.
		zones.append_array(zones_piece)
	return problemes

static func _boite(collision: CollisionShape3D) -> Dictionary:
	var taille: Vector3 = collision.shape.size
	var transfo := collision.global_transform
	var coins: Array[Vector2] = []
	for signe in [Vector2(-1, -1), Vector2(1, -1), Vector2(1, 1), Vector2(-1, 1)]:
		var coin: Vector3 = transfo * Vector3(signe.x * taille.x / 2, 0, signe.y * taille.z / 2)
		coins.append(Vector2(coin.x, coin.z))
	var centre := transfo.origin
	var hauteur := taille.y * transfo.basis.y.length()
	return {"coins": coins, "centre": centre, "bas": centre.y - hauteur / 2, "haut": centre.y + hauteur / 2}

static func _chevauche(a: Dictionary, b: Dictionary) -> bool:
	if minf(a.haut, b.haut) - maxf(a.bas, b.bas) <= TOLERANCE: return false
	# Le test des axes séparateurs distingue un vrai chevauchement d'un simple contact.
	for rectangle in [a, b]:
		for i in range(2):
			var bord: Vector2 = rectangle.coins[i + 1] - rectangle.coins[i]
			var axe := Vector2(-bord.y, bord.x).normalized()
			var pa := _projeter(a.coins, axe)
			var pb := _projeter(b.coins, axe)
			if minf(pa.y, pb.y) - maxf(pa.x, pb.x) <= TOLERANCE: return false
	return true

static func _projeter(coins: Array, axe: Vector2) -> Vector2:
	var intervalle := Vector2(INF, -INF)
	for coin in coins:
		var projection: float = coin.dot(axe)
		intervalle.x = minf(intervalle.x, projection)
		intervalle.y = maxf(intervalle.y, projection)
	return intervalle

static func _sur_sol(generateur: Node3D, point: Vector2) -> bool:
	var cellule := Vector2i(floori((point.x + 2.5) / 5), floori((point.y + 2.5) / 5))
	return cellule.x >= 0 and cellule.y >= 0 and cellule.x < generateur.roomSize.x and cellule.y < generateur.roomSize.y and generateur.grid[cellule.y][cellule.x]
