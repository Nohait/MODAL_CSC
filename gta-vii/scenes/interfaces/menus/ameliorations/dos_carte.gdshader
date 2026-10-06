shader_type canvas_item;

uniform float horloge = 0.0;
uniform float vitesse_coulee : hint_range(0.0, 0.3) = 0.08;
uniform float decalage = 0.0;
varying vec4 modulation_noeud;

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 cellule = floor(p);
	vec2 position = fract(p);
	position = position * position * (3.0 - 2.0 * position);
	return mix(mix(hasard(cellule), hasard(cellule + vec2(1.0, 0.0)), position.x),
		mix(hasard(cellule + vec2(0.0, 1.0)), hasard(cellule + vec2(1.0)), position.x), position.y);
}

float matiere(vec2 p) {
	return bruit(p) * 0.57 + bruit(p * 2.1) * 0.29 + bruit(p * 4.3) * 0.14;
}

void vertex() {
	modulation_noeud = COLOR;
}

void fragment() {
	float motif = texture(TEXTURE, UV).a;
	// Le bruit déforme le courant dans les deux axes : aucun sens de chute imposé.
	vec2 courant = UV * vec2(18.0, 12.0);
	float temps = horloge * vitesse_coulee * 5.0 + decalage;
	vec2 deformation = vec2(bruit(courant * 0.6 + vec2(temps, -temps * 0.7)),
		bruit(courant * 0.6 + vec2(-temps * 0.6, temps * 0.8) + vec2(7.0)));
	vec2 remous = vec2(sin(temps * 0.8), cos(temps * 0.65)) * 0.8;
	float roche = matiere(courant + deformation * 3.5 + remous);
	// Croûte sombre, lave rouge, puis orange très chaud au cœur des coulées.
	float fusion = smoothstep(0.32, 0.57, roche);
	float coeur = smoothstep(0.55, 0.73, roche);
	vec3 couleur = mix(vec3(0.12, 0.025, 0.012), vec3(0.95, 0.20, 0.015), fusion);
	couleur = mix(couleur, vec3(1.0, 0.73, 0.12), coeur);

	// Un halo discret reste autour du motif original.
	vec2 pas = TEXTURE_PIXEL_SIZE * 2.0;
	float halo = texture(TEXTURE, UV + vec2(pas.x, 0.0)).a;
	halo += texture(TEXTURE, UV - vec2(pas.x, 0.0)).a;
	halo += texture(TEXTURE, UV + vec2(0.0, pas.y)).a;
	halo += texture(TEXTURE, UV - vec2(0.0, pas.y)).a;
	float alpha = max(motif, halo * 0.04);
	COLOR = vec4(couleur, alpha * modulation_noeud.a);
}
