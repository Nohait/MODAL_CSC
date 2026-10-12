shader_type spatial;
render_mode blend_mix, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 couleur : source_color = vec4(0.22, 0.38, 0.45, 0.28);
uniform float opacite = 1.0;
uniform float fonte = 0.0;
uniform bool forme_libre = false;
varying vec2 point_sol;

void vertex() {
	point_sol = VERTEX.xz;
}

void fragment() {
	float angle = atan(point_sol.y, point_sol.x);
	float bord = 0.9 + sin(angle * 5.0 + 0.5) * 0.04 + sin(angle * 11.0) * 0.02;
	float distance = length(point_sol);
	float couverture = 1.0 - smoothstep(bord - 0.12, bord, distance);
	// Les petites ondulations modifient surtout la normale, pas la luminosité du sol.
	float phase = distance * 32.0 - TIME * 2.8 + sin(angle * 3.0) * 0.4;
	vec2 pente = normalize(point_sol + vec2(0.001)) * cos(phase) * 0.08;
	NORMAL = normalize((VIEW_MATRIX * vec4(-pente.x, 1.0, -pente.y, 0.0)).xyz);
	float rides = pow(max(0.0, sin(phase)), 10.0) * 0.08;
	ALBEDO = mix(couleur.rgb, vec3(0.65, 0.83, 0.9), rides);
	ROUGHNESS = 0.35;
	SPECULAR = 0.25;
	ALPHA = couleur.a * opacite * couverture;
}
