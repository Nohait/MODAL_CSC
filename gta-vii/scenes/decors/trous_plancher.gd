@tool
extends RefCounted
# Outil de construction utilisé seulement lors de la génération de la salle.
# Il ne déplace aucun personnage : les collisions sont créées par le générateur.


const BORD_SHADER = preload("res://assets/shaders/decors/bord_trou.gdshader")
const PROFONDEUR_SHADER = preload("res://assets/shaders/decors/profondeur_trou.gdshader")
const DIRECTIONS = [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]
const PROFONDEUR := 3.0
const SEGMENTS_PAR_CASE := 10


## Renvoie les coordonnées des cases vides qui ne sont pas reliées à l'extérieur.
## [param grille] contient des lignes : grille[y][x] vaut true pour le sol, false pour le vide.
## [param taille] donne le nombre de colonnes (x) et de lignes (y).
## Le résultat est un dictionnaire utilisé comme un ensemble : ses clés sont des Vector2i,
## et chaque valeur vaut true. On teste une présence avec resultat.has(Vector2i(x, y)).
## Ne modifie pas la grille et ne crée aucun nœud.
static func trouver_trous(grille: Array, taille: Vector2i) -> Dictionary:
	# Remplissage depuis le bord : toute case vide accessible depuis l'extérieur
	# reste une découpe extérieure. Les autres cases vides sont des trous intérieurs.
	# ÉTAPE 1 : enregistrer les cases de départ, au bord du rectangle.
	# Le dictionnaire sert à mémoriser les cases déjà trouvées ; la liste sert
	# à savoir lesquelles il reste à explorer. Une case n'entre qu'une fois.
	var exterieur := {}
	var attente: Array[Vector2i] = []
	for y in range(taille.y):
		for x in range(taille.x):
			if (x == 0 or y == 0 or x == taille.x - 1 or y == taille.y - 1) and not grille[y][x]:
				var cellule := Vector2i(x, y)
				exterieur[cellule] = true
				attente.append(cellule)
	# ÉTAPE 2 : explorer les voisines des cases trouvées.
	# La liste peut grandir dans la boucle. L'indice avance sans retirer d'éléments :
	# quand il atteint sa taille, toutes les cases découvertes ont été examinées.
	var indice := 0
	while indice < attente.size():
		var cellule := attente[indice]
		indice += 1
		for direction in DIRECTIONS:
			var voisine: Vector2i = cellule + direction
			if voisine.x < 0 or voisine.y < 0 or voisine.x >= taille.x or voisine.y >= taille.y:
				continue # Hors de la grille : ne pas essayer de lire grille[y][x].
			if grille[voisine.y][voisine.x] or exterieur.has(voisine):
				continue
			# Marquer AVANT d'ajouter évite que deux chemins ajoutent la même case.
			exterieur[voisine] = true
			attente.append(voisine)
	# ÉTAPE 3 : le vide non atteint depuis le bord est nécessairement intérieur.
	var trous := {}
	for y in range(taille.y):
		for x in range(taille.x):
			var cellule := Vector2i(x, y)
			if not grille[y][x] and not exterieur.has(cellule):
				trous[cellule] = true
	return trous


## Ajoute sous [param parent] un nœud TrousPlancher contenant tout l'habillage des trous.
## [param trous] est le dictionnaire renvoyé par trouver_trous().
## [param pas] est la largeur d'une case en mètres (5 dans le générateur).
## [param sol] fournit la texture et la teinte à prolonger ; null utilise les valeurs du shader.
## [param largeur] règle le débord irrégulier vers le vide ; [param braises] règle son émission.
## Crée les rebords, les parois et les fonds noirs, mais AUCUNE collision.
## Ne renvoie rien. À appeler une fois par salle, après la construction de son sol.
static func construire(parent: Node3D, trous: Dictionary, pas: float, sol: StandardMaterial3D, largeur: float, braises: float) -> void:
	if trous.is_empty():
		return
	var ensemble := Node3D.new()
	ensemble.name = "TrousPlancher"
	parent.add_child(ensemble)
	# SurfaceTool est un outil de fabrication de meshes : on lui fournit des
	# sommets, puis commit() produit le maillage final. Il n'est pas un nœud.
	# Deux outils séparent les triangles du dessus de ceux des parois verticales,
	# car ces surfaces utilisent des matériaux différents.
	var bords := SurfaceTool.new()
	var parois := SurfaceTool.new()
	# En mode TRIANGLES, chaque groupe de trois sommets forme une face.
	bords.begin(Mesh.PRIMITIVE_TRIANGLES)
	parois.begin(Mesh.PRIMITIVE_TRIANGLES)
	var materiau_bord := ShaderMaterial.new()
	materiau_bord.shader = BORD_SHADER
	# Chaque nom correspond à un "uniform" déclaré dans bord_trou.gdshader.
	# C'est le lien entre les réglages GDScript et les calculs du shader.
	materiau_bord.set_shader_parameter("intensite_braises", braises)
	if sol != null:
		# Reprendre la texture et la projection du sol actuel plutôt que charger
		# une autre image : le parquet se prolonge dans la frange qui brûle.
		materiau_bord.set_shader_parameter("teinte_sol", sol.albedo_color)
		materiau_bord.set_shader_parameter("avec_texture", sol.albedo_texture != null)
		materiau_bord.set_shader_parameter("texture_sol", sol.albedo_texture)
		materiau_bord.set_shader_parameter("echelle_sol", Vector2(sol.uv1_scale.x, sol.uv1_scale.z))
		materiau_bord.set_shader_parameter("avec_suie", sol.detail_enabled and sol.detail_albedo != null)
		materiau_bord.set_shader_parameter("texture_suie", sol.detail_albedo)
		materiau_bord.set_shader_parameter("echelle_suie", Vector2(sol.uv2_scale.x, sol.uv2_scale.z))
	var materiau_paroi := ShaderMaterial.new()
	materiau_paroi.shader = PROFONDEUR_SHADER
	# Les fonds noirs sont uniquement visuels : aucun sol physique ou navigable
	# n'est ajouté au trou. Avec les parois noires, leur profondeur est indiscernable.
	var noir := StandardMaterial3D.new()
	noir.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	noir.albedo_color = Color.BLACK
	noir.disable_fog = true
	var fond_mesh := PlaneMesh.new()
	fond_mesh.size = Vector2(pas, pas)
	fond_mesh.material = noir
	# Un seul PlaneMesh est partagé par tous les fonds. Chaque MeshInstance3D
	# possède sa propre position, mais ne recopie pas la forme du carré.
	for cellule: Vector2i in trous:
		var fond := MeshInstance3D.new()
		fond.name = "Obscurite"
		fond.mesh = fond_mesh
		fond.position = Vector3(cellule.x * pas, -PROFONDEUR + 0.1, cellule.y * pas)
		fond.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		ensemble.add_child(fond)
		for direction: Vector2i in DIRECTIONS:
			# Aucun bord entre deux cases du même trou, même si le trou fait un L.
			if trous.has(cellule + direction):
				continue
			# Coordonnées entières des sommets : deux bords voisins calculent
			# exactement la même extrémité, donc pas de fissure entre leurs franges.
			# Pour une case (x, y), ses coins sont (x,y), (x+1,y),
			# (x,y+1), (x+1,y+1). ONE vaut (1,1), RIGHT vaut (1,0).
			# UP/DOWN désignent ici l'axe y de la GRILLE, donc l'axe z du monde.
			var debut: Vector2i
			var fin: Vector2i
			if direction == Vector2i.UP:
				debut = cellule
				fin = cellule + Vector2i.RIGHT
			elif direction == Vector2i.DOWN:
				debut = cellule + Vector2i.DOWN
				fin = cellule + Vector2i.ONE
			elif direction == Vector2i.LEFT:
				debut = cellule
				fin = cellule + Vector2i.DOWN
			else:
				debut = cellule + Vector2i.RIGHT
				fin = cellule + Vector2i.ONE
			# Les centres du sol sont placés à x*pas et y*pas. Le coin précédent
			# est donc à une demi-case de moins : d'où "-0.5".
			# Le dessus du sol de 0.2 m d'épaisseur se trouve à la hauteur 0.1.
			var a := Vector3((debut.x - 0.5) * pas, 0.1, (debut.y - 0.5) * pas)
			var b := Vector3((fin.x - 0.5) * pas, 0.1, (fin.y - 0.5) * pas)
			# direction pointe du trou vers le sol : son opposé pointe vers le vide.
			var interieur := -Vector3(direction.x, 0, direction.y)
			var retrait_a := _retrait_sommet(debut, trous) * largeur
			var retrait_b := _retrait_sommet(fin, trous) * largeur
			for i in range(SEGMENTS_PAR_CASE):
				# Avec dix segments, le premier va de t=0 à 0.1, le suivant
				# de 0.1 à 0.2, etc. lerp(a,b,t) repère un point entre a et b.
				var t0 := float(i) / SEGMENTS_PAR_CASE
				var t1 := float(i + 1) / SEGMENTS_PAR_CASE
				# ex = bord extérieur côté parquet ; in = bord intérieur côté vide.
				# Les deux paires forment la bande de plancher brûlé de ce segment.
				var ex0 := a.lerp(b, t0)
				var ex1 := a.lerp(b, t1)
				var in0 := _point_irregulier(ex0, t0, interieur, retrait_a, retrait_b, largeur)
				var in1 := _point_irregulier(ex1, t1, interieur, retrait_a, retrait_b, largeur)
				# Commencer la brûlure sur le parquet encore solide, pas exactement
				# sur le bord carré de la grille : la transition masque ce quadrillage.
				ex0 -= retrait_a.lerp(retrait_b, t0).normalized() * 0.5
				ex1 -= retrait_a.lerp(retrait_b, t1).normalized() * 0.5
				# Surélever de 3 mm évite le scintillement de deux faces superposées
				# exactement à la même hauteur (appelé z-fighting).
				ex0.y = 0.103
				ex1.y = 0.103
				_quad(bords, ex0, ex1, in1, in0, t0, t1)
				# La paroi repart de la lèvre in0/in1 et conserve leurs x/z
				# jusqu'au bas : sa face descend verticalement dans le trou.
				_quad(parois, in0, in1, Vector3(in1.x, 0.1 - PROFONDEUR, in1.z),
					Vector3(in0.x, 0.1 - PROFONDEUR, in0.z), t0, t1)
	_ajouter_maillage(ensemble, "BordsBrules", bords, materiau_bord)
	_ajouter_maillage(ensemble, "ParoisSombres", parois, materiau_paroi)


## Calcule le décalage de base d'un coin de la grille vers l'intérieur du trou.
## [param sommet] désigne un COIN de case, pas son centre ; [param trous] contient les cases vides.
## Renvoie un vecteur horizontal, ensuite multiplié par la largeur du rebord.
## Un même coin donne le même décalage pour tous les côtés qui le touchent :
## ils peuvent donc se rejoindre sans laisser d'espace entre leurs extrémités.
static func _retrait_sommet(sommet: Vector2i, trous: Dictionary) -> Vector3:
	# Regarder les quatre cases qui touchent ce sommet et se décaler vers le vide.
	# Aux coins, les deux bords se rejoignent sur le même point en diagonale.
	var direction := Vector3.ZERO
	for offset in [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 0), Vector2i.ZERO]:
		if trous.has(sommet + offset):
			direction += Vector3(offset.x + 0.5, 0, offset.y + 0.5)
	# normalized() conserve la direction avec une longueur de 1.
	# 0.75 garde un retrait modéré aux coins ; largeur sera appliquée ensuite.
	# Si les contributions s'annulent, normalized() renvoie Vector3.ZERO.
	return direction.normalized() * 0.75


## Renvoie la position d'un point de la lèvre irrégulière, à partir du bord droit de la grille.
## [param point] est la position de départ dans la salle ; [param t] va de 0 à 1 le long du côté.
## [param interieur] pointe vers le trou. [param debut] et [param fin] sont des DÉCALAGES
## déjà calculés aux extrémités, et non les positions des extrémités.
## [param largeur] règle l'amplitude du débord. Ne crée ni sommet de mesh ni collision :
## cette fonction calcule seulement une position, qui sera ensuite transmise à _quad().
static func _point_irregulier(point: Vector3, t: float, interieur: Vector3, debut: Vector3, fin: Vector3, largeur: float) -> Vector3:
	# Variation déterministe dans l'espace : pas de scintillement entre deux images.
	# sin(PI*t) annule la variation aux extrémités pour conserver les raccords.
	# Les fréquences différentes des deux sinus créent de petites et grandes
	# irrégularités. Ces nombres règlent l'aspect du contour, pas la navigation.
	var variation := 0.65 + 0.4 * sin(point.x * 2.3 + point.z * 1.9) + 0.18 * sin(point.x * 7.3 - point.z * 6.1)
	# Premier lerp : interpoler les décalages des deux extrémités.
	# Second lerp : se rapprocher du décalage irrégulier au milieu du côté.
	# sin(PI*t) vaut 0 au début/à la fin, et 1 au milieu : les raccords restent fixes.
	var retrait := debut.lerp(fin, t).lerp(interieur * largeur * variation, sin(PI * t))
	return point + retrait


## Ajoute une surface à quatre coins dans le SurfaceTool fourni, sous forme de deux triangles.
## [param a], [param b], [param c], [param d] sont les coins successifs du contour.
## [param u0] et [param u1] situent le morceau le long du côté (entre 0 et 1).
## Les UV ajoutés avec les sommets donnent aussi un repère de traversée au shader :
## a/b sont au début (UV.y = 0), c/d à la fin (UV.y = 1).
## Ne crée pas encore de MeshInstance3D : les triangles s'accumulent dans [param surface].
static func _quad(surface: SurfaceTool, a: Vector3, b: Vector3, c: Vector3, d: Vector3, u0: float, u1: float) -> void:
	# Deux triangles font un quadrilatère. UV.y distingue le parquet du bord noir,
	# puis le haut du bas pour les parois. Le shader est visible des deux côtés.
	# Triangle 1 : a-b-c ; triangle 2 : a-c-d. La diagonale a-c est commune.
	# a et c apparaissent deux fois car on envoie ici des triangles sans indices.
	var points := [a, b, c, a, c, d]
	var uvs := [Vector2(u0, 0), Vector2(u1, 0), Vector2(u1, 1),
		Vector2(u0, 0), Vector2(u1, 1), Vector2(u0, 1)]
	for i in range(6):
		# set_uv configure les coordonnées DU PROCHAIN sommet ; il faut donc
		# l'appeler avant add_vertex, qui enregistre la position et les UV ensemble.
		surface.set_uv(uvs[i])
		surface.add_vertex(points[i])


## Termine la construction d'une surface et ajoute son objet visible sous [param parent].
## [param surface] contient les triangles préparés par _quad().
## [param nom] nomme le MeshInstance3D créé ; [param materiau] définit son apparence.
## Calcule les normales, transforme les données en ArrayMesh, puis l'attache au nœud.
## Ne renvoie rien et n'ajoute pas de collision.
static func _ajouter_maillage(parent: Node3D, nom: String, surface: SurfaceTool, materiau: Material) -> void:
	# Une normale est la direction perpendiculaire à une face. Elle sert notamment
	# au calcul d'éclairage. Godot peut la déduire des triangles que nous avons fournis.
	surface.generate_normals()
	var visuel := MeshInstance3D.new()
	visuel.name = nom
	# commit() fabrique la ressource ArrayMesh ; le MeshInstance3D permet de
	# l'afficher dans la scène. Ressource géométrique et nœud visible sont distincts.
	visuel.mesh = surface.commit()
	visuel.material_override = materiau
	visuel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(visuel)
