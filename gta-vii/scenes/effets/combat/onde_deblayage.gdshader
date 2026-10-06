shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

uniform float rayon = 0.0;
uniform float progression = 0.0;
uniform float opacite = 1.0;
varying vec2 position_sol;

void vertex() {
	position_sol = VERTEX.xz;
}

void fragment() {
	float distance_sol = length(position_sol);
	float angle = atan(position_sol.y, position_sol.x);
	// De petites irrégularités donnent un front vivant, sans masquer sa portée.
	float ondulation = sin(angle * 13.0 + progression * 8.0) * 0.035;
	float ecart = distance_sol - rayon + ondulation;
	float front = 1.0 - smoothstep(0.025, 0.12, abs(ecart));
	float halo = 1.0 - smoothstep(0.1, 0.32, abs(ecart));
	float sillage = (1.0 - smoothstep(0.0, 0.6, -ecart)) * step(ecart, 0.0);
	vec3 couleur = mix(vec3(0.25, 0.65, 0.8), vec3(0.9, 1.0, 1.0), front);
	ALBEDO = couleur;
	EMISSION = couleur * (front * 2.2 + halo * 0.4);
	ALPHA = clamp(front * 0.8 + halo * 0.2 + sillage * 0.15, 0.0, 1.0) * opacite;
}
