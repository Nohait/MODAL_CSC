shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform sampler2D flamme : repeat_enable, filter_linear;
uniform sampler2D lueur : filter_linear;

void vertex() {
	// Une petite ondulation casse la silhouette trop régulière du cône.
	float variation = 1.0 + sin(VERTEX.y * 12.0 - TIME * 20.0) * 0.12;
	VERTEX.xz *= variation;
}

void fragment() {
	// Une texture défilante anime la traînée, sans laisser de particules au sol.
	float feu = texture(flamme, vec2(UV.x, UV.y * 1.5 - TIME * 3.0)).r;
	float halo = texture(lueur, vec2(UV.x, 0.5)).r;
	// UV.y vaut zéro à la pointe : fondre progressivement l'extrémité arrière.
	float longueur = smoothstep(0.0, 0.3, UV.y);
	vec3 couleur = mix(vec3(1.0, 0.08, 0.01), vec3(1.0, 0.75, 0.12), feu);
	ALBEDO = couleur;
	EMISSION = couleur * 2.0;
	ALPHA = halo * longueur * (0.35 + feu * 0.65);
}
