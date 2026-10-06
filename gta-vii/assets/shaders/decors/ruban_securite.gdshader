shader_type spatial;
render_mode cull_disabled;

void vertex() {
	// Le vent déplace légèrement le milieu du ruban, en gardant ses extrémités fixes.
	VERTEX.z += sin(UV.x * 12.0 + TIME * 1.6) * sin(UV.x * 3.14159265) * 0.035;
}

void fragment() {
	// Des bandes diagonales pour une limite d'intervention, sans mur opaque.
	float bande = step(0.5, fract(UV.x * 12.0 + UV.y));
	ALBEDO = mix(vec3(0.06), vec3(0.85, 0.62, 0.12), bande);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
}
