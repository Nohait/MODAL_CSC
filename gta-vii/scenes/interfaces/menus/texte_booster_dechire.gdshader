shader_type canvas_item;

uniform vec2 taille = vec2(270.0, 420.0);
uniform vec2 decalage = vec2(0.0);
uniform float cote_dechirure = -1.0;
varying vec2 position_pochette;

float hasard(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453123);
}

void vertex() {
	// Position du texte dans la pochette avant sa rotation, indépendante de la fenêtre.
	position_pochette = (VERTEX + decalage) / taille;
}

void fragment() {
	COLOR *= texture(TEXTURE, UV);
	float cellule = position_pochette.y * 11.0;
	float debut = hasard(vec2(floor(cellule), 37.0));
	float fin = hasard(vec2(floor(cellule) + 1.0, 37.0));
	float coupure = 0.5 + (mix(debut, fin, fract(cellule)) - 0.5) * 0.085;
	COLOR.a *= cote_dechirure < 0.0 ? step(position_pochette.x, coupure) : step(coupure, position_pochette.x);
}
