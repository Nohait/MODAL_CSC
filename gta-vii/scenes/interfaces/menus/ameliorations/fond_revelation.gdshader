shader_type canvas_item;

uniform float horloge = 0.0;
uniform float arrivee = 0.0;
uniform float eclat = 0.0;
uniform float puissance = 0.0;
uniform vec2 taille = vec2(1280.0, 720.0);
uniform vec4 teinte : source_color = vec4(0.85, 0.55, 0.2, 1.0);
uniform vec4 teinte_eclat : source_color = vec4(0.85, 0.55, 0.2, 1.0);

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 cellule = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hasard(cellule), hasard(cellule + vec2(1.0, 0.0)), f.x),
		mix(hasard(cellule + vec2(0.0, 1.0)), hasard(cellule + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = UV - vec2(0.5, 0.55);
	p.x *= taille.x / max(taille.y, 1.0);
	float distance_centre = length(p);
	float angle = atan(p.y, p.x);
	// Des rais larges tournent très lentement derrière les cartes.
	float rayons = pow(max(0.0, sin(angle * 9.0 + horloge * 0.10)), 5.0);
	float lumiere = exp(-distance_centre * 1.9) * (0.24 + rayons * 0.28);
	float fumee = bruit(UV * 5.0 + vec2(horloge * 0.035, -horloge * 0.025));
	fumee *= bruit(UV * 11.0 - vec2(horloge * 0.02, 0.0));
	vec3 couleur = vec3(0.065, 0.043, 0.029);
	couleur += teinte.rgb * arrivee * (0.07 + lumiere + fumee * 0.16) * (1.0 + puissance * 0.10);
	couleur += vec3(0.22, 0.065, 0.015) * pow(UV.y, 4.0) * arrivee;
	couleur += teinte_eclat.rgb * eclat * exp(-distance_centre * 3.5) * 0.45;

	// Les braises deviennent plus nombreuses à mesure que les raretés sont dévoilées.
	vec2 grille = UV * vec2(40.0, 24.0) + vec2(0.0, horloge * (0.55 + puissance * 0.10));
	vec2 cellule = floor(grille);
	float graine = hasard(cellule);
	vec2 centre_braise = vec2(0.25 + hasard(cellule + vec2(3.0)) * 0.5,
		0.2 + hasard(cellule + vec2(8.0)) * 0.6);
	centre_braise.x += sin(horloge + graine * 20.0) * 0.12;
	vec2 position = fract(grille) - centre_braise;
	float rayon = mix(0.04, 0.09, hasard(cellule + vec2(13.0)));
	float braise = 1.0 - smoothstep(rayon * 0.25, rayon, length(position));
	// La progression est volontairement forte : environ 115 / 210 / 355 / 530 braises.
	float densite = 0.12 + pow(clamp(puissance / 3.0, 0.0, 1.0), 1.35) * 0.43;
	braise *= step(1.0 - densite, graine) * (0.6 + 0.4 * sin(horloge * 1.6 + graine * 40.0));
	couleur += mix(vec3(1.0, 0.35, 0.05), teinte.rgb, 0.4) * braise * arrivee * 0.9;
	// Garder les angles sombres fait ressortir le papier et les gerbes de révélation.
	couleur *= 1.0 - smoothstep(0.3, 1.15, distance_centre) * 0.35;
	COLOR = vec4(couleur, 1.0);
}
