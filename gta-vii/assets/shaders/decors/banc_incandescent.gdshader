shader_type spatial;

uniform sampler2D bois : source_color, hint_default_white, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosite : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform vec4 teinte : source_color = vec4(1.0);
uniform vec4 canal_rugosite = vec4(0.0, 1.0, 0.0, 0.0);
uniform float rugosite_de_base = 1.0;
uniform float relief = 0.7;
uniform float brulure : hint_range(0.0, 1.0) = 0.75;
uniform float intensite_braises : hint_range(0.0, 6.0) = 3.2;

varying vec3 position_monde;

float hasard(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float bruit(vec3 p) {
	vec3 cellule = floor(p);
	vec3 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	return mix(mix(mix(hasard(cellule), hasard(cellule + vec3(1, 0, 0)), local.x),
		mix(hasard(cellule + vec3(0, 1, 0)), hasard(cellule + vec3(1, 1, 0)), local.x), local.y),
		mix(mix(hasard(cellule + vec3(0, 0, 1)), hasard(cellule + vec3(1, 0, 1)), local.x),
		mix(hasard(cellule + vec3(0, 1, 1)), hasard(cellule + vec3(1, 1, 1)), local.x), local.y), local.z);
}

void vertex() {
	// Garder les UV et les tangentes du modèle : ses textures PBR restent en place.
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 couleur_bois = texture(bois, UV).rgb * teinte.rgb;
	float charbon = smoothstep(0.32, 0.72, bruit(position_monde * 3.5)) * brulure;
	ALBEDO = mix(couleur_bois, vec3(0.035, 0.025, 0.018), charbon);
	ROUGHNESS = mix(dot(texture(rugosite, UV), canal_rugosite) * rugosite_de_base, 0.95, charbon);
	NORMAL_MAP = texture(normale, UV).rgb;
	NORMAL_MAP_DEPTH = relief;
	// De fines fissures rougeoient seulement dans les parties carbonisées.
	float fissures = 1.0 - smoothstep(0.012, 0.055, abs(bruit(position_monde * 22.0) - 0.5));
	float braises = fissures * smoothstep(0.42, 0.65, charbon);
	braises *= smoothstep(0.4, 0.65, bruit(position_monde * 7.0 + vec3(9.2)));
	// Les fissures restent fixes ; seule leur luminosité respire lentement.
	float pulsation = 0.85 + 0.15 * sin(TIME * 2.0 + position_monde.x);
	EMISSION = vec3(1.0, 0.2, 0.025) * braises * intensite_braises * pulsation;
}
