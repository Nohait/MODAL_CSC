shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 couleur : source_color = vec4(0.85, 0.9, 0.8, 0.35);
uniform float opacite = 1.0;
uniform float fonte : hint_range(0.0, 1.0) = 0.0;
uniform bool forme_libre = false;
varying vec2 point_sol;

void vertex() {
	point_sol = VERTEX.xz;
}

void fragment() {
	float angle = atan(point_sol.y, point_sol.x);
	// Quelques ondulations cassent le cercle parfait, sans déplacer la collision.
	float bord = 0.9 + sin(angle * 5.0) * 0.035 + sin(angle * 9.0 + 1.7) * 0.025;
	// La frontière se retire vers le centre et ondule légèrement pendant la fonte.
	bord *= 1.0 - fonte;
	bord += sin(angle * 7.0 + fonte * 5.0) * 0.035 * sin(fonte * 3.14159);
	float couverture = (1.0 - smoothstep(bord - 0.12, bord, length(point_sol))) * (1.0 - smoothstep(0.85, 1.0, fonte));
	if (forme_libre) {
		// UV décrit les côtés et les deux extrémités de l'empreinte du jet.
		float distance_bord = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		float irregularite = sin(point_sol.x * 37.0 + sin(point_sol.y * 23.0)) * 0.008;
		couverture = smoothstep(fonte * 0.5, fonte * 0.5 + 0.035, distance_bord + irregularite);
	}
	// De petites bulles éclaircissent la mousse ; aucun système de particules nécessaire.
	vec2 grille = point_sol * 13.0;
	vec2 cellule = floor(grille);
	vec2 hasard = fract(sin(vec2(dot(cellule, vec2(127.1, 311.7)), dot(cellule, vec2(269.5, 183.3)))) * 43758.5453);
	vec2 centre = vec2(0.25) + hasard * 0.5;
	float bulle = 1.0 - smoothstep(0.06 + hasard.x * 0.1, 0.18 + hasard.x * 0.12, length(fract(grille) - centre));
	float variation = 0.75 + sin(grille.x * 1.7 + sin(grille.y)) * 0.1;
	ALBEDO = mix(couleur.rgb * variation, vec3(0.9, 0.96, 1.0), bulle * 0.3);
	ALPHA = couleur.a * opacite * couverture * (0.65 + bulle * 0.35);
}
