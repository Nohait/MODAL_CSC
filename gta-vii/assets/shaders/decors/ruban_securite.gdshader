shader_type spatial;
render_mode cull_disabled;

void fragment() {
	// Des bandes diagonales pour une limite d'intervention, sans mur opaque.
	float bande = step(0.5, fract(UV.x * 12.0 + UV.y));
	ALBEDO = mix(vec3(0.06), vec3(0.85, 0.62, 0.12), bande);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
