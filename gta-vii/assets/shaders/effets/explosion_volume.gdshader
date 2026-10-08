shader_type spatial;
render_mode unshaded, cull_front, depth_draw_never, depth_test_disabled, fog_disabled;

uniform sampler3D volume_actuel : filter_linear, repeat_disable;
uniform sampler3D volume_suivant : filter_linear, repeat_disable;
uniform sampler2D profondeur : hint_depth_texture, filter_nearest, repeat_disable;
uniform float interpolation = 0.0;
uniform float opacite = 55.0;
uniform float luminosite = 2.4;
uniform float disparition = 1.0;
uniform float coeur = 0.0;
uniform float ombres_fumee = 1.8;
uniform bool encodage_racine = true;
uniform int nombre_pas = 48;
varying vec3 position_locale;
varying vec3 position_monde;

vec2 lire_volume(vec3 coordonnees) {
	vec2 actuel = texture(volume_actuel, coordonnees).rg;
	vec2 suivant = texture(volume_suivant, coordonnees).rg;
	// La version HD conserve davantage de nuances dans les faibles densités.
	if (encodage_racine) {
		actuel *= actuel;
		suivant *= suivant;
	}
	return mix(actuel, suivant, interpolation);
}

void vertex() {
	position_locale = VERTEX;
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Chaque pixel traverse réellement le volume, selon l'angle de la caméra.
	vec3 direction_monde = PROJECTION_MATRIX[3][3] > 0.5
		? -INV_VIEW_MATRIX[2].xyz : normalize(position_monde - CAMERA_POSITION_WORLD);
	vec3 direction = normalize((inverse(MODEL_MATRIX) * vec4(direction_monde, 0.0)).xyz);
	vec3 origine = position_locale - direction * 4.0;
	vec3 t1 = (-vec3(0.5) - origine) / direction;
	vec3 t2 = (vec3(0.5) - origine) / direction;
	vec3 debut = min(t1, t2);
	vec3 fin = max(t1, t2);
	float entree = max(max(debut.x, debut.y), debut.z);
	float sortie = min(min(fin.x, fin.y), fin.z);

	// Un mur ou une voiture peut cacher une partie de la fumée.
	float profondeur_scene = texture(profondeur, SCREEN_UV).r;
	vec4 point_vue = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, profondeur_scene, 1.0);
	point_vue /= point_vue.w;
	vec3 point_local = (inverse(MODEL_MATRIX) * INV_VIEW_MATRIX * point_vue).xyz;
	sortie = min(sortie, dot(point_local - origine, direction));
	float pas = max(sortie - entree, 0.0) / float(nombre_pas);
	vec3 couleur = vec3(0.0);
	float alpha = 0.0;
	for (int i = 0; i < nombre_pas; i++) {
		vec3 position = origine + direction * (entree + (float(i) + 0.5) * pas);
		vec2 contenu = lire_volume(position + 0.5);
		// Élargir brièvement la base avec les volutes réelles, sans ajouter de sphère lisse.
		vec3 base = vec3(position.x * 0.8 + 0.5, (position.y + 0.5) * 2.0, position.z * 0.8 + 0.5);
		if (coeur > 0.01 && base.y < 1.0) {
			vec2 dispersion = lire_volume(base);
			contenu = max(contenu, dispersion * vec2(2.0, 1.0) * coeur);
		}
		float densite = max(contenu.r, contenu.g * 0.5);
		if (densite < 0.001) { continue; }
		float absorption = 1.0 - exp(-densite * opacite * pas);
		// La fumée absorbe la lumière : les creux restent sombres entre les flammes.
		vec3 uv = position + 0.5;
		float ecran = texture(volume_actuel, clamp(uv + vec3(-0.025, 0.03, 0.02), 0.0, 1.0)).r;
		float ecran_lointain = texture(volume_actuel, clamp(uv + vec3(-0.06, 0.07, 0.045), 0.0, 1.0)).r;
		if (encodage_racine) { ecran *= ecran; ecran_lointain *= ecran_lointain; }
		float eclairage = exp(-(ecran + ecran_lointain) * ombres_fumee);
		float feu = smoothstep(0.025, 0.28, contenu.g);
		vec3 flamme = mix(vec3(1.0, 0.055, 0.004), vec3(1.0, 0.45, 0.045), smoothstep(0.05, 0.35, contenu.g));
		flamme = mix(flamme, vec3(1.0, 0.88, 0.6), smoothstep(0.35, 0.9, contenu.g));
		vec3 fumee = vec3(0.16, 0.135, 0.11) * (0.3 + 0.7 * eclairage);
		vec3 teinte = mix(fumee, flamme * luminosite * (0.65 + 0.35 * eclairage), feu);
		couleur += (1.0 - alpha) * absorption * teinte;
		alpha += (1.0 - alpha) * absorption;
		if (alpha > 0.995) { break; }
	}
	ALBEDO = couleur / max(alpha, 0.001);
	ALPHA = alpha * disparition;
}
