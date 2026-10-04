shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

void fragment() {
	ALBEDO = vec3(0.25, 0.65, 1.0);
	ALPHA = 0.3;
}
