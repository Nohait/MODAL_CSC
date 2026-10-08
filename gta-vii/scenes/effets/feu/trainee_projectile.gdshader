shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

void fragment() {
	// UV.x conserve la distance parcourue : aucune texture défilante qui boucle.
	float ondulation = sin(UV.x * 13.0 + TIME * 5.0) * sin(UV.x * 21.7 - TIME * 3.0);
	float bord = 1.0 - smoothstep(0.35 + ondulation * 0.12, 1.0, abs(UV.y));
	float coeur = pow(1.0 - abs(UV.y), 3.0) * COLOR.a;
	vec3 couleur = mix(vec3(1.0, 0.09, 0.005), vec3(1.0, 0.75, 0.18), coeur);
	ALBEDO = couleur;
	EMISSION = couleur * (0.8 + coeur * 1.4);
	ALPHA = bord * pow(COLOR.a, 1.4) * 0.75;
}
