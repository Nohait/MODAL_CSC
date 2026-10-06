shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform float opacite : hint_range(0.0, 1.0) = 0.65;
uniform float courbure : hint_range(-1.0, 1.0) = 0.35;

float bruit(vec2 p) {
	vec2 i = floor(p), f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(fract(sin(dot(i, vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1, 0), vec2(127.1, 311.7))) * 43758.5453), f.x), mix(fract(sin(dot(i + vec2(0, 1), vec2(127.1, 311.7))) * 43758.5453), fract(sin(dot(i + vec2(1, 1), vec2(127.1, 311.7))) * 43758.5453), f.x), f.y);
}

void vertex() {
	// Une courbe douce fait suivre aux deux roues le même freinage.
	VERTEX.x += sin(UV.y * 3.14159) * courbure;
}

void fragment() {
	float grain = bruit(UV * vec2(18.0, 95.0));
	float bord = abs(UV.x - 0.5) * 2.0;
	float masque = 1.0 - smoothstep(0.65 + grain * 0.15, 1.0, bord);
	float extremites = smoothstep(0.0, 0.15, UV.y) * (1.0 - smoothstep(0.82, 1.0, UV.y));
	float stries = 0.65 + 0.35 * bruit(vec2(UV.x * 40.0, UV.y * 5.0));
	ALBEDO = vec3(0.025, 0.022, 0.020);
	ROUGHNESS = 0.95;
	ALPHA = masque * extremites * stries * mix(0.65, 1.0, grain) * opacite;
}
