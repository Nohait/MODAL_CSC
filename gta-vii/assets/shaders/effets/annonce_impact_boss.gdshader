shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform vec4 couleur : source_color = vec4(1.0, 0.28, 0.035, 1.0);
uniform float charge : hint_range(0.0, 1.0) = 0.0;
uniform float opacite : hint_range(0.0, 1.0) = 1.0;

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 cellule = floor(p);
	vec2 fraction = fract(p);
	fraction = fraction * fraction * (3.0 - 2.0 * fraction);
	return mix(mix(hasard(cellule), hasard(cellule + vec2(1.0, 0.0)), fraction.x),
		mix(hasard(cellule + vec2(0.0, 1.0)), hasard(cellule + vec2(1.0)), fraction.x), fraction.y);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float rayon = length(p);
	// Adapter le lissage à la taille des pixels évite les contours crénelés de loin.
	float pixel = max(fwidth(rayon), 0.001);
	float bord = 1.0 - smoothstep(1.0 - pixel * 1.5, 1.0, rayon);
	// Un filet continu marque la portée ; la lumière et les braises restent à l'intérieur.
	float contour = smoothstep(0.983 - pixel, 0.99 + pixel, rayon) * bord;
	float halo = exp(-pow((rayon - 0.972) / 0.035, 2.0)) * bord;
	vec2 derive = vec2(TIME * 0.22, -TIME * 0.18);
	float detail = bruit(p * 28.0 + derive);
	float braises = smoothstep(0.82, 0.96, rayon) * bord * smoothstep(0.73, 0.9, detail);
	float onde = (1.0 - smoothstep(0.015, 0.045, abs(rayon - (1.0 - charge)))) * bord;
	float remplissage = (0.08 + charge * 0.09) * bord;
	float intensite = contour * 0.85 + halo * 0.22 + braises * (0.3 + charge * 0.6) + onde * charge * 0.3;
	ALBEDO = mix(couleur.rgb, vec3(1.0, 0.75, 0.3), clamp(intensite * (0.3 + charge * 0.5), 0.0, 0.7));
	EMISSION = couleur.rgb * intensite * (0.7 + charge * 1.3);
	ALPHA = clamp(remplissage + intensite * 0.65, 0.0, 0.9) * opacite;
}
