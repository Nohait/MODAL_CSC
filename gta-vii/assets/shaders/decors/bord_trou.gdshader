// Shader de surface 3D : il colore les rebords construits par trous_plancher.gd.
// Il ne modifie ni la grille, ni les collisions, ni la forme de l'ouverture.
shader_type spatial;
// cull_disabled : visible des deux côtés. Le rebord conserve les reflets du sol.
// depth_prepass_alpha aide à gérer la profondeur des parties opaques du rebord transparent.
render_mode cull_disabled, depth_prepass_alpha;

// UV.y mesure la traversée du bord : 0 = parquet intact, 1 = lèvre carbonisée.
// La découpe est dans le maillage : aucun plan transparent ne bouche le trou.
// uniform = paramètre fourni par GDScript avec set_shader_parameter().
// sampler2D = image dans laquelle texture() lit une couleur.
// source_color permet à Godot d'interpréter correctement une texture de couleur.
// repeat_enable répète l'image au lieu d'étirer son dernier pixel hors de [0,1].
uniform sampler2D texture_sol : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_suie : source_color, filter_linear_mipmap, repeat_enable;
uniform bool avec_texture = false;
uniform sampler2D texture_rugosite : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform bool avec_rugosite = false;
uniform bool avec_normale = false;
uniform vec4 canal_rugosite = vec4(1.0, 0.0, 0.0, 0.0);
uniform float rugosite_sol = 0.8;
uniform float force_normale = 1.0;
uniform float speculaire_sol = 0.5;
uniform float metallique_sol = 0.0;
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

void fragment() {
	NORMAL = normalize((VIEW_MATRIX * vec4(0.0, 1.0, 0.0, 0.0)).xyz);
	vec2 p = position_monde.xz * vec2(1.0, -1.0);
	vec3 sol = teinte_sol.rgb;
	if (avec_texture) sol *= texture(texture_sol, p * echelle_sol).rgb;
	if (avec_suie) sol *= texture(texture_suie, p * echelle_suie).rgb;
	// Le revêtement reste intact presque jusqu'à la cassure : aucune ceinture orange.
	float charbon = smoothstep(0.78, 1.0, UV.y + (bruit(p * 3.5) - 0.5) * 0.18);
	ALBEDO = mix(sol, vec3(0.018), charbon * 0.88);
	// Même rugosité, relief et brillance que le sol ; seul le charbon devient mat.
	float rugosite = rugosite_sol;
	if (avec_rugosite) rugosite *= dot(texture(texture_rugosite, p * echelle_sol), canal_rugosite);
	ROUGHNESS = mix(rugosite, 1.0, charbon);
	SPECULAR = speculaire_sol * (1.0 - charbon);
	METALLIC = metallique_sol * (1.0 - charbon);
	if (avec_normale) {
		// La texture est projetée suivant X et -Z, comme la face supérieure du sol triplanaire.
		TANGENT = normalize((VIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz);
		BINORMAL = normalize((VIEW_MATRIX * vec4(0.0, 0.0, -1.0, 0.0)).xyz);
		NORMAL_MAP = texture(texture_normale, p * echelle_sol).rgb;
		NORMAL_MAP_DEPTH = force_normale * (1.0 - charbon);
	}
	ALPHA = smoothstep(0.0, 0.25, UV.y);
	// Quelques points seulement au bord ; zéro dans l'Inspector supprime aussi ces braises.
	float braise = smoothstep(0.94, 1.0, UV.y) * smoothstep(0.88, 0.96, bruit(p * 14.0));
	EMISSION = vec3(1.0, 0.15, 0.015) * braise * intensite_braises * 0.12;
}
