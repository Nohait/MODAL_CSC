shader_type canvas_item;
uniform int nombre_braises : hint_range(4, 40) = 24;
uniform float vitesse : hint_range(0.1, 2.0) = 0.5;
float hasard(float p) { return fract(sin(p * 127.1) * 43758.5453); }
void fragment() {
	vec2 p = UV;
	vec3 fond = mix(vec3(0.025, 0.035, 0.05), vec3(0.10, 0.035, 0.015), pow(p.y, 3.0));
	float halo = exp(-length((p - vec2(0.5, 0.64)) * vec2(1.0, 1.7)) * 5.0);
	fond += vec3(0.08, 0.03, 0.01) * halo;
	for (int i = 0; i < 40; i++) {
		if (i >= nombre_braises) break;
		float graine = float(i) + 1.0;
		float age = fract(TIME * vitesse * (0.05 + hasard(graine) * 0.05) + hasard(graine + 8.0));
		vec2 position = vec2(hasard(graine + 3.0) + sin(TIME * 0.35 + graine) * 0.02, 1.1 - age * 1.3);
		vec2 distance_point = (p - position) * vec2(1.7, 1.0);
		float rayon = mix(0.001, 0.0023, hasard(graine + 5.0));
		float grain = exp(-dot(distance_point, distance_point) / (rayon * rayon));
		float lueur = exp(-length(distance_point) / (rayon * 4.0)) * 0.13;
		fond += vec3(1.0, 0.28, 0.025) * (grain + lueur) * sin(age * 3.14159);
	}
	COLOR = vec4(fond, 1.0);
}
