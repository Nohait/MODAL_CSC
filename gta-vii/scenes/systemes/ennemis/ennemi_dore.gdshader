shader_type spatial;
// Un vrai matériau métallique uniforme pour distinguer l'or des auras jaunes.
void fragment() {
	ALBEDO = vec3(0.97, 0.69, 0.16);
	METALLIC = 0.85;
	ROUGHNESS = 0.25;
	EMISSION = vec3(0.27, 0.15, 0.02);
}
