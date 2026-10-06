shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

void fragment() {
	// Les stries avancent le long du jet, plutôt que de dessiner un tube uniforme.
	float stries = 0.5 + 0.5 * sin(UV.y * 90.0 - TIME * 55.0 + sin(UV.x * 20.0));
	ALBEDO = vec3(0.72, 0.86, 0.92);
	ALPHA = 0.12 + stries * 0.22;
}
