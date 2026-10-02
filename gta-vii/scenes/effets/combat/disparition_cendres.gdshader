shader_type spatial;
render_mode unshaded, cull_disabled;

uniform float progression : hint_range(0.0, 1.0) = 0.0;
uniform vec4 couleur_depart : source_color = vec4(0.85, 0.28, 0.04, 1.0);
uniform sampler2D texture_depart : source_color;
uniform bool texture_depart_active = false;
uniform vec3 minimum_modele = vec3(0.0);
uniform vec3 dimensions_modele = vec3(1.0);
varying vec3 position_locale;

void vertex() {
	position_locale = VERTEX;
}

float hasard(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

void fragment() {
	// Normaliser permet de conserver un motif comparable sur un petit ennemi et une tour.
	vec3 coordonnees = (position_locale - minimum_modele) / max(dimensions_modele, vec3(0.001));
	float grain = hasard(floor(coordonnees * 24.0));
	float seuil = smoothstep(0.18, 1.0, progression);
	// Supprimer progressivement des fragments, plutôt que rendre tout le corps transparent.
	if (grain < seuil || progression >= 0.999) {
		discard;
	}
	float charbon = smoothstep(0.0, 0.25, progression);
	vec3 teinte = couleur_depart.rgb;
	if (texture_depart_active) {
		teinte *= texture(texture_depart, UV).rgb;
	}
	ALBEDO = mix(teinte, vec3(0.045, 0.038, 0.03), charbon);
	// Quelques points chauds apparaissent uniquement sur le bord de la dissolution.
	float bord = (1.0 - smoothstep(0.0, 0.055, grain - seuil)) * charbon;
	EMISSION = vec3(1.0, 0.22, 0.025) * bord * 0.6;
}
