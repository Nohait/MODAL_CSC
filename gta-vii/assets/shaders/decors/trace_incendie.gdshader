shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform vec4 teinte : source_color = vec4(0.045, 0.033, 0.025, 0.65);
uniform float graine = 0.0;

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 cellule = floor(p);
	vec2 local = fract(p);
	local = local * local * (3.0 - 2.0 * local);
	return mix(mix(hasard(cellule), hasard(cellule + vec2(1.0, 0.0)), local.x),
		mix(hasard(cellule + vec2(0.0, 1.0)), hasard(cellule + vec2(1.0)), local.x), local.y);
}

void fragment() {
	// Le bruit déforme le bord et crée des zones de suie plus ou moins denses.
	vec2 p = UV * 2.0 - 1.0;
	float taches = bruit(UV * 5.0 + graine) * 0.65 + bruit(UV * 17.0 + graine) * 0.35;
	float bord = 1.0 - smoothstep(0.35, 1.0, length(p) + (taches - 0.5) * 0.5);
	ALBEDO = teinte.rgb;
	ROUGHNESS = 1.0;
	ALPHA = bord * (0.25 + taches * 0.75) * teinte.a;
}
