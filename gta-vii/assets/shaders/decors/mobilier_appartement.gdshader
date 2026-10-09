shader_type spatial;

uniform sampler2D couleur : source_color, hint_default_white, filter_linear_mipmap;
uniform sampler2D normale : hint_normal, filter_linear_mipmap;
uniform sampler2D rugosite : hint_default_white, filter_linear_mipmap;
uniform sampler2D metal : hint_default_white, filter_linear_mipmap;
uniform vec4 teinte : source_color = vec4(1.0);
uniform vec4 canal_rugosite = vec4(0.0, 1.0, 0.0, 0.0);
uniform vec4 canal_metal = vec4(0.0, 0.0, 1.0, 0.0);
uniform float rugosite_de_base = 1.0;
uniform float metal_de_base = 0.0;
uniform float relief = 1.0;
uniform float brulure : hint_range(0.0, 1.0) = 0.35;
uniform float intensite_braises : hint_range(0.0, 6.0) = 0.5;

varying vec3 position_monde;

float hasard(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float bruit(vec3 p) {
	vec3 c = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hasard(c), hasard(c + vec3(1, 0, 0)), f.x),
		mix(hasard(c + vec3(0, 1, 0)), hasard(c + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(hasard(c + vec3(0, 0, 1)), hasard(c + vec3(1, 0, 1)), f.x),
		mix(hasard(c + vec3(0, 1, 1)), hasard(c + vec3(1, 1, 1)), f.x), f.y), f.z);
}

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Le bruit assombrit certaines zones, tout en conservant les textures et leur relief.
	float charbon = smoothstep(0.25, 0.7, bruit(position_monde * 3.0)) * brulure;
	ALBEDO = mix(texture(couleur, UV).rgb * teinte.rgb, vec3(0.025, 0.02, 0.018), charbon);
	ROUGHNESS = mix(dot(texture(rugosite, UV), canal_rugosite) * rugosite_de_base, 0.95, charbon);
	METALLIC = dot(texture(metal, UV), canal_metal) * metal_de_base * (1.0 - charbon);
	NORMAL_MAP = texture(normale, UV).rgb;
	NORMAL_MAP_DEPTH = relief;
	float fissures = 1.0 - smoothstep(0.012, 0.045, abs(bruit(position_monde * 20.0) - 0.5));
	float braises = fissures * smoothstep(0.55, 0.8, charbon);
	braises *= smoothstep(0.55, 0.75, bruit(position_monde * 6.0 + vec3(9.2)));
	EMISSION = vec3(1.0, 0.18, 0.02) * braises * intensite_braises * (0.85 + 0.15 * sin(TIME * 2.0));
}
