shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

uniform vec4 teinte_pochette : source_color = vec4(0.4, 0.7, 0.7, 1.0);
// Intensité des reflets et finesse du brossage, réglables dans le matériau.
uniform float intensite_metal : hint_range(0.0, 2.0) = 1.0;
uniform float niveau_eclat : hint_range(0.0, 3.0) = 0.0;
// Éclaircir la matière sans modifier les textes ni les bords carbonisés.
uniform float luminosite_pochette : hint_range(0.5, 2.0) = 1.4;

// Zéro affiche la pochette entière ; -1 et 1 affichent ses deux moitiés.
uniform float cote_dechirure = 0.0;
uniform float pression = 0.0;

void fragment() {
	vec2 pixels = UV * taille;
	// Le grain est calculé à la taille réelle de la pochette : sa définition ne
	// dépend plus des 300 pixels de la texture de papier utilisée auparavant.
	float grain = hasard(floor(pixels * 1.5));
	float brossage = sin(pixels.y * 2.2) * 0.009 + (grain - 0.5) * 0.018;
	vec3 aluminium = vec3(0.42, 0.40, 0.36) + brossage;
	float diagonale = UV.y - UV.x * 0.17;
	float impression = smoothstep(0.155, 0.16, diagonale)
		* (1.0 - smoothstep(0.755, 0.76, diagonale));
	vec3 fond = mix(aluminium, teinte_pochette.rgb * 0.62 + brossage, impression);
	// Alternance de zones claires et sombres : une feuille métallisée réfléchit
	// fortement la lumière selon ses plis, même sans survol de la souris.
	float facettes = 0.85 + 0.20 * sin(UV.x * 17.0 + UV.y * 1.6);
	fond *= facettes;
	float ligne_reflet = UV.x + UV.y * 0.22 - 0.18 - survol * 0.48;
	float reflet_large = exp(-pow(ligne_reflet / 0.11, 2.0));
	float reflet_fin = exp(-pow((ligne_reflet - 0.035) / 0.008, 2.0));
	fond += vec3(0.78, 0.85, 0.90) * (reflet_large * 0.24 + reflet_fin * 0.30) * intensite_metal;
	// Une seconde lumière parcourt le métal pendant le survol, sans saut de position.
	float balayage = UV.x + UV.y * 0.3 - fract(horloge * 0.28) * 1.7 + 0.2;
	float eclair = exp(-pow(balayage / 0.09, 2.0));
	fond += mix(teinte_pochette.rgb, vec3(1.0), 0.65) * eclair * survol * (0.18 + niveau_eclat * 0.1);
	// Un sceau gravé derrière le chiffre donne une identité au centre du paquet.
	vec2 sceau = (UV - vec2(0.5, 0.43)) * vec2(1.0, taille.y / taille.x);
	float anneau_sceau = exp(-pow((length(sceau) - 0.23) / 0.006, 2.0));
	float losange = exp(-pow((abs(sceau.x) + abs(sceau.y) - 0.29) / 0.005, 2.0));
	fond += teinte_pochette.rgb * (anneau_sceau + losange) * (0.16 + survol * (0.2 + niveau_eclat * 0.08));
	// Chaque pli comporte un bord lumineux et une ombre juste à côté.
	float pli_gauche = exp(-pow((UV.x - 0.06) / 0.004, 2.0));
	float ombre_gauche = exp(-pow((UV.x - 0.075) / 0.007, 2.0));
	float pli_droit = exp(-pow((UV.x - 0.94) / 0.004, 2.0));
	fond += vec3(0.32) * (pli_gauche + pli_droit) * intensite_metal;
	fond *= 1.0 - ombre_gauche * 0.50;
	// Soudures crantées : des stries de quatre pixels, avec arête et creux nets.
	float soudure = max(1.0 - smoothstep(0.082, 0.086, UV.y), smoothstep(0.914, 0.918, UV.y));
	float strie = fract(pixels.x / 4.0);
	float relief_strie = smoothstep(0.0, 0.2, strie) * (1.0 - smoothstep(0.45, 0.9, strie));
	vec3 metal_soudure = mix(vec3(0.055), mix(vec3(0.7), teinte_pochette.rgb, 0.3), relief_strie);
	fond = mix(fond, metal_soudure, soudure);
	// Un liseré brillant sépare les soudures du centre de la pochette.
	float ourlet = max(exp(-pow((UV.y - 0.086) / 0.002, 2.0)), exp(-pow((UV.y - 0.914) / 0.002, 2.0)));
	fond += vec3(0.35) * ourlet * intensite_metal;
	// Conserver le charbon et les braises déjà utilisés par les cartes.
	// Une fissure lumineuse laisse deviner la pression avant la déchirure.
	float fissure = UV.x - 0.5 - sin(UV.y * 35.0) * 0.008;
	fond += mix(vec3(1.0, 0.7, 0.3), teinte_pochette.rgb, 0.5) * exp(-abs(fissure) * 120.0) * pression;
	COLOR = habiller(UV, vec4(fond * luminosite_pochette, 1.0)) * modulation_noeud;
	if (abs(cote_dechirure) > 0.5) {
		// Une ligne brisée fixe assure que les deux morceaux s’emboîtent exactement.
		float cellule = UV.y * 11.0;
		float debut = hasard(vec2(floor(cellule), 37.0));
		float fin = hasard(vec2(floor(cellule) + 1.0, 37.0));
		float coupure = 0.5 + (mix(debut, fin, fract(cellule)) - 0.5) * 0.085;
		float masque = cote_dechirure < 0.0 ? step(UV.x, coupure) : step(coupure, UV.x);
		float bord = 1.0 - smoothstep(0.001, 0.007, abs(UV.x - coupure));
		COLOR.rgb = mix(COLOR.rgb, vec3(0.85, 0.77, 0.59), bord * 0.65);
		COLOR.a *= masque;
	}
}
