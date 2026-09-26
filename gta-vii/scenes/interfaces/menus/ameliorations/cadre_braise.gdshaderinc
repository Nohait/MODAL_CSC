// Fonctions communes aux deux surfaces : carte et illustration.
// Tous les calculs sont en pixels pour garder une bordure de même épaisseur
// quelle que soit la taille du Control.
uniform vec2 taille = vec2(320.0, 480.0);
uniform float largeur_bord : hint_range(2.0, 30.0) = 13.0;
uniform float rayon_coin : hint_range(0.0, 30.0) = 14.0;
uniform float survol : hint_range(0.0, 1.0) = 0.0;
uniform float horloge = 0.0;
uniform vec2 point_lumiere = vec2(0.25, 0.15);
uniform float intensite_braises : hint_range(0.0, 2.0) = 0.8;
varying vec4 modulation_noeud;

// Conserver la couleur/opacité du Control et de ses parents : un futur fondu
// d'ouverture du menu doit agir aussi sur les surfaces dessinées par shader.
void vertex() {
	modulation_noeud = COLOR;
}

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

// Interpolation de quatre valeurs : un motif irrégulier mais continu.
float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(hasard(i), hasard(i + vec2(1.0, 0.0)), f.x),
		mix(hasard(i + vec2(0.0, 1.0)), hasard(i + vec2(1.0)), f.x), f.y);
}

// Distance signée au bord d'un rectangle arrondi : positive vers l'intérieur.
float distance_bord(vec2 uv) {
	vec2 q = abs((uv - 0.5) * taille) - (taille * 0.5 - vec2(rayon_coin + 2.0));
	return -(length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - rayon_coin);
}

// Renvoie l'image avec charbon, relief simulé et fissures incandescentes.
// Le relief reste une illusion 2D : aucun matériau PBR ni lumière 3D n'est requis.
vec4 habiller(vec2 uv, vec4 image) {
	vec2 p = uv * taille;
	float n = bruit(p * 0.09);
	float d = distance_bord(uv) - (n - 0.5) * 2.5;
	float interieur = smoothstep(largeur_bord * 0.5, largeur_bord + 9.0, d);
	float grain = bruit(p * 0.65);
	vec3 charbon = mix(vec3(0.018, 0.013, 0.011), vec3(0.095, 0.06, 0.04), grain);
	// Un liseré clair et son ombre suggèrent l'épaisseur d'un bord biseauté.
	float biseau = exp(-pow((d - largeur_bord) / 2.2, 2.0));
	vec2 vers_lampe = normalize(point_lumiere - uv + vec2(0.0001));
	vec2 vers_centre = normalize(vec2(0.5) - uv + vec2(0.0001));
	float eclairage = dot(vers_lampe, vers_centre);
	vec3 couleur = mix(charbon, image.rgb, interieur);
	couleur += biseau * (0.06 + 0.045 * eclairage) * vec3(1.0, 0.73, 0.44);
	// L'animation change la chaleur, pas la silhouette : les bords ne « nagent » pas.
	float fissures = 1.0 - smoothstep(0.025, 0.085, abs(bruit(p * 0.22) - 0.5));
	float chaleur = smoothstep(0.25, 0.8, bruit(p * 0.035 + vec2(horloge * 0.18, 0.0)));
	float anneau = exp(-pow((d - 4.0 - n * 4.0) / 3.0, 2.0));
	float braise = anneau * fissures * chaleur * intensite_braises;
	vec3 feu = mix(vec3(0.95, 0.16, 0.025), vec3(1.0, 0.68, 0.2), chaleur);
	couleur += feu * braise * (0.75 + survol * 0.65);
	// Le survol éclaire doucement la matière, sans voile blanc sur les textes.
	float reflet = exp(-length((uv - point_lumiere) * vec2(1.0, 1.4)) * 3.0);
	couleur += vec3(0.07, 0.045, 0.02) * reflet * survol;
	float contour_focus = exp(-pow((d - 1.2) / 0.9, 2.0)) * survol;
	couleur += vec3(0.8, 0.45, 0.14) * contour_focus;
	return vec4(couleur, image.a * smoothstep(-0.7, 0.7, d));
}
