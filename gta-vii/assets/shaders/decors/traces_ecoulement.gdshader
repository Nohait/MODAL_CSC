shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

void fragment() {
	float salete = 0.0;
	// Quelques coulures fixes, de longueurs différentes, partent du haut de la surface.
	for (int i = 0; i < 6; i++) {
		float centre = 0.1 + float(i) * 0.15;
		float longueur = 0.35 + 0.5 * abs(sin(float(i) * 2.3));
		float trajet = centre + sin(UV.y * 14.0 + float(i)) * 0.009;
		float trace = 1.0 - smoothstep(0.008, 0.03, abs(UV.x - trajet));
		trace *= 1.0 - smoothstep(longueur - 0.2, longueur, UV.y);
		salete = max(salete, trace);
	}
	ALBEDO = vec3(0.09, 0.065, 0.035);
	ROUGHNESS = 1.0;
	ALPHA = salete * 0.3 * smoothstep(0.0, 0.08, UV.y);
}
