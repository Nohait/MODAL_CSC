shader_type spatial;
uniform sampler2D couleur : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosite : filter_linear_mipmap, repeat_enable;
uniform float taille_texture : hint_range(2.0, 12.0) = 5.0;
uniform float humidite : hint_range(0.0, 1.0) = 0.65;
uniform float relief : hint_range(0.0, 1.0) = 0.35;
varying vec3 position_monde;

float bruit(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 v = fract(sin(vec4(dot(i, vec2(127.1, 311.7)), dot(i + vec2(1, 0), vec2(127.1, 311.7)), dot(i + vec2(0, 1), vec2(127.1, 311.7)), dot(i + vec2(1, 1), vec2(127.1, 311.7)))) * 43758.5453);
	return mix(mix(v.x, v.y, f.x), mix(v.z, v.w, f.x), f.y);
}

void vertex() { position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }

void fragment() {
	vec2 uv = position_monde.xz / taille_texture;
	float variation = bruit(position_monde.xz * 0.12);
	float mouille = smoothstep(0.34, 0.67, variation) * humidite;
	vec3 beton = texture(couleur, uv).rgb;
	// Des variations à grande échelle cassent la répétition et séparent les zones humides.
	ALBEDO = beton * mix(0.65, 0.92, bruit(position_monde.xz * 0.035)) * (1.0 - mouille * 0.28);
	ROUGHNESS = mix(max(0.65, texture(rugosite, uv).r), 0.16, mouille);
	METALLIC = 0.0;
	SPECULAR = 0.45;
	NORMAL_MAP = texture(normale, uv).rgb;
	NORMAL_MAP_DEPTH = relief * (1.0 - mouille * 0.65);
}
