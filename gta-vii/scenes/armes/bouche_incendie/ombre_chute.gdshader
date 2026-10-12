shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform float approche = 0.0;
void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	float taille = mix(0.9, 0.55, approche);
	float contour = mix(0.45, 0.15, approche);
	ALBEDO = vec3(0.015, 0.025, 0.03);
	ALPHA = (1.0 - smoothstep(taille - contour, taille, r)) * mix(0.08, 0.32, approche);
}
