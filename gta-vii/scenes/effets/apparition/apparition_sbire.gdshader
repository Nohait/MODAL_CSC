shader_type spatial;
render_mode cull_disabled;

uniform float progression : hint_range(0.0, 1.0) = 0.0;
uniform float bas;
uniform float hauteur = 3.0;
uniform vec4 teinte : source_color = vec4(1.0);
uniform sampler2D texture_corps : source_color;
uniform bool utilise_texture = false;
uniform vec3 emission_initiale = vec3(0.0);
uniform sampler2D texture_emission : source_color;
uniform bool utilise_emission = false;
varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

float bruit(vec3 p) {
	return sin(p.x * 11.0 + p.z * 7.0) * sin(p.z * 13.0 + p.y * 5.0);
}

void fragment() {
	// Une frontière irrégulière monte des pieds vers la tête et forme le corps.
	float seuil = bas - 0.25 + progression * (hauteur + 0.5);
	float ecart = seuil - position_monde.y + bruit(position_monde * 1.7) * 0.12;
	if (ecart < 0.0) discard;
	vec3 corps = teinte.rgb;
	if (utilise_texture) corps *= texture(texture_corps, UV).rgb;
	float bord = 1.0 - smoothstep(0.0, 0.22, ecart);
	ALBEDO = mix(corps, vec3(0.95, 0.23, 0.025), bord);
	vec3 emission = emission_initiale;
	if (utilise_emission) emission *= texture(texture_emission, UV).rgb;
	EMISSION = emission + vec3(1.0, 0.35, 0.035) * bord * 2.0;
	ROUGHNESS = 0.8;
}
