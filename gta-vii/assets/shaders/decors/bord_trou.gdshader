// Shader de surface 3D : il colore les rebords construits par trous_plancher.gd.
// Il ne modifie ni la grille, ni les collisions, ni la forme de l'ouverture.
shader_type spatial;
// cull_disabled : visible des deux côtés ; specular_disabled : pas de reflet brillant.
// depth_prepass_alpha aide à gérer la profondeur des parties opaques du rebord transparent.
render_mode cull_disabled, specular_disabled, depth_prepass_alpha;

// UV.y mesure la traversée du bord : 0 = parquet intact, 1 = lèvre carbonisée.
// La découpe est dans le maillage : aucun plan transparent ne bouche le trou.
// uniform = paramètre fourni par GDScript avec set_shader_parameter().
// sampler2D = image dans laquelle texture() lit une couleur.
// source_color permet à Godot d'interpréter correctement une texture de couleur.
// repeat_enable répète l'image au lieu d'étirer son dernier pixel hors de [0,1].
uniform sampler2D texture_sol : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_suie : source_color, filter_linear_mipmap, repeat_enable;
uniform bool avec_texture = false;
uniform bool avec_suie = false;
uniform vec4 teinte_sol : source_color = vec4(0.3, 0.32, 0.34, 1.0);
uniform vec2 echelle_sol = vec2(0.25);
uniform vec2 echelle_suie = vec2(0.04);
uniform float intensite_braises : hint_range(0.0, 5.0) = 1.5;
// varying transmet une donnée du calcul des sommets au calcul des fragments.
// Godot interpole cette position entre les sommets d'un même triangle.
varying vec3 position_monde;

// Bruit interpolé : donne des fissures irrégulières plutôt que des points répétés.
/**
 * Renvoie un nombre pseudo-aléatoire entre 0 et 1 à partir d'une position 2D.
 * Une même position donne toujours la même valeur : le motif reste stable.
 * Cette fonction ne lit aucune texture et n'utilise pas le temps.
 */
float hasard(vec2 p) {
	// dot combine les coordonnées ; sin les transforme ; fract garde la partie
	// fractionnaire. Les constantes dispersent les valeurs pour casser la régularité.
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

/**
 * Renvoie un bruit continu autour de p, en mélangeant les valeurs de quatre coins.
 * Contrairement à hasard(), deux positions proches donnent des résultats proches.
 * Utilisé pour dessiner des fissures dont les contours ne sont pas réguliers.
 */
float bruit(vec2 p) {
	// floor repère la case entière ; fract donne la position à l'intérieur de la case.
	vec2 cellule = floor(p);
	vec2 f = fract(p);
	// Cette courbe adoucit les raccords. mix(a,b,t) est l'équivalent shader de lerp :
	// les deux mix internes interpolent sur x, puis le dernier interpole sur y.
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hasard(cellule), hasard(cellule + vec2(1.0, 0.0)), f.x),
		mix(hasard(cellule + vec2(0.0, 1.0)), hasard(cellule + vec2(1.0)), f.x), f.y);
}

/**
 * Fonction appelée par Godot pour chaque sommet du rebord.
 * Convertit sa position locale en position dans le monde, transmise à fragment().
 * Ne déplace pas le sommet : la découpe a déjà été construite en GDScript.
 */
void vertex() {
	// MODEL_MATRIX contient la transformation du nœud (position, rotation, échelle).
	// Le 1 ajouté au vec4 indique une position : sa translation doit être appliquée.
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

/**
 * Fonction appelée par Godot pour chaque fragment de surface à dessiner.
 * Combine le parquet, le charbon, la transparence du raccord et les braises.
 * Les résultats sont écrits dans les variables de sortie ALBEDO, ALPHA, etc.
 */
void fragment() {
	// Tous les morceaux du rebord regardent vers le haut, quel que soit le sens
	// dans lequel on a parcouru leur côté de la grille.
	// VIEW_MATRIX convertit une direction du monde vers le repère de la caméra,
	// attendu par NORMAL. Le dernier 0 du vec4 exclut la translation.
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	// Projection horizontale comme le matériau triplanaire du parquet.
	vec2 p = position_monde.xz * vec2(1.0, -1.0);
	vec3 bois = teinte_sol.rgb;
	if (avec_texture) {
		bois *= texture(texture_sol, p * echelle_sol).rgb;
	}
	if (avec_suie) {
		bois *= texture(texture_suie, p * echelle_suie).rgb;
	}
	float irregularite = sin(p.x * 9.0 + sin(p.y * 5.0)) * sin(p.y * 13.0);
	// smoothstep(a,b,x) passe doucement de 0 à 1 lorsque x va de a à b.
	// La petite variation décale la transition pour éviter une frontière régulière.
	float brulure = smoothstep(0.08, 0.9, UV.y + irregularite * 0.06);
	// ALBEDO est la couleur de base, avant éclairage. mix rapproche progressivement
	// le parquet de la couleur du charbon ; ROUGHNESS=1 donne une surface mate.
	ALBEDO = mix(bois, vec3(0.006, 0.004, 0.003), brulure);
	ROUGHNESS = 1.0;
	// Le tout début recouvre le sol solide : le fondre évite une couture carrée.
	// Le rebord devient opaque bien avant d'atteindre le vide.
	ALPHA = smoothstep(0.0, 0.25, UV.y);
	// Des fragments de braises, plutôt qu'une bande orange parfaitement uniforme.
	// Le premier smoothstep allume la bande, le second l'éteint près de la lèvre.
	// Leur produit garde les braises entre le parquet intact et le bord noir.
	float bande = smoothstep(0.25, 0.5, UV.y) * (1.0 - smoothstep(0.65, 0.95, UV.y));
	// abs(bruit-0.5) est faible le long des contours où le bruit vaut environ 0.5.
	// On éclaire ces contours ; un second bruit en masque des portions.
	float fragments = (1.0 - smoothstep(0.025, 0.12, abs(bruit(p * 5.0) - 0.5)))
		* smoothstep(0.2, 0.7, bruit(p * 1.7));
	// TIME est le temps fourni par Godot. Le sinus fait varier l'intensité de 0.6 à 1.
	// L'ajout de la position décale la pulsation d'un endroit à l'autre.
	float pulsation = 0.8 + 0.2 * sin(TIME * 2.0 + p.x * 3.0 + p.y);
	// EMISSION ajoute la couleur lumineuse des braises. Ce n'est pas une Light3D :
	// cela rend le matériau lumineux sans créer ici de lumière sur les objets voisins.
	EMISSION = vec3(1.0, 0.24, 0.025) * bande * fragments * pulsation * intensite_braises;
}
