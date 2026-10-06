shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform vec4 teinte : source_color = vec4(0.08, 0.13, 0.16, 0.45);
uniform float vitesse : hint_range(0.0, 3.0) = 0.8;

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.y, p.x);
	// Le bord irrégulier masque le rectangle et évite un disque parfaitement rond.
	float bord = 0.87 + sin(angle * 5.0) * 0.05 + cos(angle * 9.0) * 0.025;
	float distance_centre = length(p);
	float masque = 1.0 - smoothstep(bord - 0.10, bord, distance_centre);
	float onde = sin(distance_centre * 28.0 - TIME * vitesse * 6.0);
	ALBEDO = teinte.rgb;
	ROUGHNESS = 0.22 + onde * 0.025;
	SPECULAR = 0.5;
	ALPHA = teinte.a * masque;
}
