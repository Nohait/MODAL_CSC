shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform vec4 couleur : source_color = vec4(0.11, 0.16, 0.19, 0.48);
uniform float rugosite : hint_range(0.02, 1.0) = 0.09;

void fragment() {
	vec2 point = UV * 2.0 - 1.0;
	float angle = atan(point.y, point.x);
	// Plusieurs ondulations dessinent un bord irrégulier, fixe au fil du temps.
	float bord = 0.78 + sin(angle * 3.0) * 0.09 + sin(angle * 7.0 + 1.4) * 0.04;
	float masque = 1.0 - smoothstep(bord - 0.06, bord, length(point));
	ALBEDO = couleur.rgb;
	ROUGHNESS = rugosite;
	SPECULAR = 0.8;
	ALPHA = couleur.a * masque;
	// Un relief très faible anime les reflets sans donner l'impression de vagues.
	NORMAL_MAP = vec3(0.5 + sin(UV.y * 45.0 + TIME * 0.7) * 0.015,
		0.5 + cos(UV.x * 37.0 + TIME * 0.5) * 0.015, 1.0);
	NORMAL_MAP_DEPTH = 0.3;
}
