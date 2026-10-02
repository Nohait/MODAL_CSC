shader_type spatial;

uniform float intensite = 0.35;
varying vec3 position_locale;

void vertex() {
	position_locale = VERTEX;
}

void fragment() {
	// Coordonnées du modèle : le motif reste attaché à l'œil lorsqu'il tourne.
	vec2 p = position_locale.xy / vec2(0.65, 0.18);
	float angle = atan(p.y, p.x);
	float rayon = length(p);
	// Des stries radiales irrégulières, plutôt qu'une surface orange uniforme.
	float stries = sin(angle * 23.0 + sin(rayon * 19.0 - TIME * 0.7) * 1.8);
	float braise = smoothstep(0.35, 0.9, stries);
	braise *= smoothstep(0.15, 0.4, rayon);
	vec3 sombre = vec3(0.018, 0.009, 0.006);
	vec3 orange = vec3(1.0, 0.16, 0.012);
	ALBEDO = mix(sombre, orange * 0.3, braise);
	// Seules les stries émettent ; les intervalles restent sombres même en charge.
	EMISSION = orange * braise * intensite;
	ROUGHNESS = 0.8;
}
