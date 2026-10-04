shader_type spatial;

uniform sampler2D texture_couleur : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_normal : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D texture_rugosite : filter_linear_mipmap_anisotropic, repeat_enable;
uniform vec4 teinte : source_color = vec4(0.78, 0.77, 0.74, 1.0);
uniform float taille_texture : hint_range(1.0, 12.0) = 4.0;
uniform float taille_variations : hint_range(1.0, 12.0) = 5.0;
uniform float intensite_relief : hint_range(0.0, 2.0) = 0.8;

varying vec3 position_monde;

void vertex() {
	// Les coordonnées du monde gardent une texture continue entre sol et couloir.
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	// Le sol est horizontal : ses deux axes de texture sont X et Z.
	TANGENT = (VIEW_MATRIX * vec4(1.0, 0.0, 0.0, 0.0)).xyz;
	BINORMAL = (VIEW_MATRIX * vec4(0.0, 0.0, 1.0, 0.0)).xyz;
}

vec2 hasard(vec2 cellule) {
	// Une même cellule donne toujours les mêmes valeurs : aucune animation du sol.
	return fract(sin(vec2(dot(cellule, vec2(127.1, 311.7)),
		dot(cellule, vec2(269.5, 183.3)))) * 43758.5453);
}

void lire_surface(vec2 cellule, vec2 uv, vec2 derivee_x, vec2 derivee_y,
	out vec3 couleur, out vec3 normale, out float rugosite) {
	vec2 aleatoire = hasard(cellule);
	float angle = floor(aleatoire.x * 4.0) * 1.5707963;
	mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
	vec2 coordonnees = rotation * uv + aleatoire;
	// Les trois textures suivent exactement le même décalage et la même rotation.
	// Des dérivées explicites évitent des lignes floues aux changements de cellule.
	couleur = textureGrad(texture_couleur, coordonnees, rotation * derivee_x, rotation * derivee_y).rgb;
	vec2 relief = textureGrad(texture_normal, coordonnees, rotation * derivee_x, rotation * derivee_y).rg * 2.0 - 1.0;
	// Remettre la normale dans les axes du sol après la rotation de la texture.
	relief = transpose(rotation) * relief;
	normale = vec3(relief, sqrt(max(0.001, 1.0 - dot(relief, relief))));
	rugosite = textureGrad(texture_rugosite, coordonnees, rotation * derivee_x, rotation * derivee_y).r;
}

void fragment() {
	vec2 uv = position_monde.xz / taille_texture;
	vec2 derivee_x = dFdx(uv);
	vec2 derivee_y = dFdy(uv);
	// Une grille triangulaire permet de mélanger trois versions de la texture.
	vec2 grille = mat2(vec2(1.0, 0.0), vec2(-0.5773503, 1.1547005))
		* (position_monde.xz / taille_variations);
	vec2 cellule = floor(grille);
	vec2 local = fract(grille);
	vec2 a;
	vec2 b;
	vec2 c;
	vec3 poids;
	if (local.x + local.y < 1.0) {
		a = cellule;
		b = cellule + vec2(1.0, 0.0);
		c = cellule + vec2(0.0, 1.0);
		poids = vec3(1.0 - local.x - local.y, local.x, local.y);
	} else {
		a = cellule + vec2(1.0, 1.0);
		b = cellule + vec2(0.0, 1.0);
		c = cellule + vec2(1.0, 0.0);
		poids = vec3(local.x + local.y - 1.0, 1.0 - local.x, 1.0 - local.y);
	}
	// Les poids se rejoignent aux frontières : pas de raccord entre les variantes.
	poids *= poids;
	poids /= poids.x + poids.y + poids.z;
	vec3 couleur_a, couleur_b, couleur_c;
	vec3 normale_a, normale_b, normale_c;
	float rugosite_a, rugosite_b, rugosite_c;
	lire_surface(a, uv, derivee_x, derivee_y, couleur_a, normale_a, rugosite_a);
	lire_surface(b, uv, derivee_x, derivee_y, couleur_b, normale_b, rugosite_b);
	lire_surface(c, uv, derivee_x, derivee_y, couleur_c, normale_c, rugosite_c);
	ALBEDO = (couleur_a * poids.x + couleur_b * poids.y + couleur_c * poids.z) * teinte.rgb;
	ROUGHNESS = rugosite_a * poids.x + rugosite_b * poids.y + rugosite_c * poids.z;
	vec3 normale = normalize(normale_a * poids.x + normale_b * poids.y + normale_c * poids.z);
	NORMAL_MAP = normale * 0.5 + 0.5;
	NORMAL_MAP_DEPTH = intensite_relief;
}
