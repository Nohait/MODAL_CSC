shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform float rayon = 2.5;
uniform float hauteur = 0.55;
uniform float progression = 0.0;

void vertex() {
	float angle = UV.x * 6.283185;
	float mouvement = sin(angle * 9.0 + progression * 5.0) * 0.12 + sin(angle * 17.0) * 0.06;
	float jaillissement = sin(progression * 3.141593);
	float distance = mix(0.2, rayon, progression);
	VERTEX.xz *= max(0.05, distance + UV.y * hauteur * jaillissement * 0.3);
	VERTEX.y = UV.y * hauteur * jaillissement * (1.0 + mouvement) + 0.025;
}

void fragment() {
	float nervures = 0.65 + 0.35 * sin(UV.x * 150.0 + sin(UV.y * 12.0) + progression * 10.0);
	float sommet = smoothstep(0.72, 1.0, UV.y);
	ALBEDO = mix(vec3(0.4, 0.75, 0.9), vec3(0.92, 0.98, 1.0), sommet);
	ALPHA = (0.16 + sommet * 0.22) * nervures * (1.0 - smoothstep(0.6, 1.0, progression));
}
