shader_type spatial;

uniform sampler2D bois : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosite : filter_linear_mipmap, repeat_enable;
uniform float relief : hint_range(0.0, 2.0) = 0.7;
uniform float brulure : hint_range(0.0, 1.0) = 0.75;
uniform float intensite_braises : hint_range(0.0, 5.0) = 1.8;
varying vec3 position_monde;

float hasard(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
float bruit(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hasard(i), hasard(i + vec3(1,0,0)), f.x),
		mix(hasard(i + vec3(0,1,0)), hasard(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hasard(i + vec3(0,0,1)), hasard(i + vec3(1,0,1)), f.x),
		mix(hasard(i + vec3(0,1,1)), hasard(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	// Projeter le bois à la même échelle sur le corps et les petites traverses.
	TANGENT = abs(NORMAL.x) > 0.5 ? vec3(0, 0, -sign(NORMAL.x)) : vec3(1, 0, 0);
	BINORMAL = normalize(cross(NORMAL, TANGENT));
	UV = vec2(dot(VERTEX, TANGENT), dot(VERTEX, BINORMAL)) * 0.5;
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	vec3 couleur_bois = texture(bois, UV).rgb;
	float taches = bruit(position_monde * 3.5);
	float charbon = smoothstep(0.35, 0.7, taches + brulure * 0.25);
	ALBEDO = mix(couleur_bois * 0.65, vec3(0.035, 0.025, 0.019), charbon);
	ROUGHNESS = mix(texture(rugosite, UV).r, 0.95, charbon);
	NORMAL_MAP = texture(normale, UV).rgb;
	NORMAL_MAP_DEPTH = relief;
	// Des fissures fines rougeoient sur le charbon ; seule leur luminosité varie.
	float fissures = 1.0 - smoothstep(0.015, 0.055, abs(bruit(position_monde * 24.0) - 0.5));
	float braises = fissures * smoothstep(0.6, 0.8, charbon);
	braises *= smoothstep(0.45, 0.7, bruit(position_monde * 8.0 + vec3(15.0)));
	float pulsation = 0.8 + sin(TIME * 3.0 + position_monde.x * 2.0) * 0.2;
	EMISSION = vec3(1.0, 0.18, 0.015) * braises * intensite_braises * pulsation;
}
