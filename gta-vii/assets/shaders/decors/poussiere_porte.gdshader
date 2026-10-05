shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

// Un grain doux sans texture supplémentaire, qui s'efface vers les bords.
void fragment() {
	float distance_centre = length(UV * 2.0 - 1.0);
	ALBEDO = COLOR.rgb;
	ALPHA = (1.0 - smoothstep(0.15, 1.0, distance_centre)) * COLOR.a;
}
