shader_type spatial;
render_mode unshaded, blend_add, cull_disabled, depth_draw_never;

uniform sampler2D flamme : repeat_enable, filter_linear;
uniform sampler2D lueur : filter_linear;

void vertex() {
	// Une petite ondulation casse la silhouette trop régulière du cône.
	float variation = 1.0 + sin(VERTEX.y * 12.0 - TIME * 12.0) * 0.16;
	variation += sin(VERTEX.y * 21.0 + TIME * 8.0) * 0.08;
	VERTEX.xz *= variation;
}

void fragment() {
	// Une texture défilante anime la traînée, sans laisser de particules au sol.
	vec2 coordonnees = vec2(UV.x + sin(UV.y * 15.0 - TIME * 6.0) * 0.05, UV.y * 1.5 - TIME * 3.0);
	float feu = texture(flamme, coordonnees).r;
	float halo = texture(lueur, vec2(UV.x, 0.5)).r;
	// UV.y vaut zéro à la pointe : fondre progressivement l'extrémité arrière.
	float longueur = smoothstep(0.0, 0.3, UV.y);
	vec3 couleur = mix(vec3(1.0, 0.08, 0.01), vec3(1.0, 0.75, 0.12), feu);
	ALBEDO = couleur;
	EMISSION = couleur * 2.0;
	// Dissoudre les zones froides casse la silhouette du cône rigide.
	ALPHA = halo * longueur * smoothstep(0.12, 0.65, feu) * 0.85;
}
