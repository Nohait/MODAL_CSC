shader_type spatial;

float bruit(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

void fragment() {
	// Un verre opaque sombre suggère l'extérieur sans laisser voir le mur derrière.
	float poussiere = bruit(floor(UV * 90.0));
	float voile = smoothstep(0.1, 1.0, UV.y);
	ALBEDO = mix(vec3(0.045, 0.08, 0.11), vec3(0.12, 0.17, 0.19), voile);
	ALBEDO *= 0.8 + poussiere * 0.2;
	ROUGHNESS = 0.35 + poussiere * 0.2;
	METALLIC = 0.2;
	EMISSION = vec3(0.09, 0.15, 0.2) * (1.0 - voile) * 0.18;
}
