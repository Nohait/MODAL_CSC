shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never;

// Une couche légère éclaircit le camion au survol sans remplacer sa peinture.
void fragment() {
	ALBEDO = vec3(1.0, 0.65, 0.22);
	ALPHA = 0.25;
}
