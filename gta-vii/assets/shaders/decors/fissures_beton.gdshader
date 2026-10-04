shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform float graine = 1.0;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float fissure = 0.0;
	// Trois branches irrégulières, peintes au sol autour du point d'impact.
	for (int i = 0; i < 3; i++) {
		float angle = float(i) * 2.1 + graine;
		mat2 rotation = mat2(vec2(cos(angle), sin(angle)), vec2(-sin(angle), cos(angle)));
		vec2 q = rotation * p;
		float trajet = q.x - sin(q.y * 12.0 + graine) * 0.035 - sin(q.y * 31.0) * 0.015;
		float ligne = 1.0 - smoothstep(0.002, 0.009, abs(trajet));
		float longueur = smoothstep(0.0, 0.08, q.y) * (1.0 - smoothstep(0.55, 0.9, q.y));
		fissure = max(fissure, ligne * longueur);
	}
	ALBEDO = vec3(0.055, 0.045, 0.035);
	ROUGHNESS = 1.0;
	ALPHA = fissure * 0.8;
}
