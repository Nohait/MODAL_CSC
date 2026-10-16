shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"
void fragment() {
	vec4 surface = support_intervention(UV, vec3(0.118, 0.165, 0.192), teinte_pochette.rgb);
	vec2 p = UV * taille;
	float bande = step(8.0, p.y) * (1.0 - step(14.0, p.y));
	float fermeture = step(22.0, p.y) * (1.0 - step(24.0, p.y));
	surface.rgb = mix(surface.rgb, teinte_pochette.rgb, bande);
	surface.rgb = mix(surface.rgb, vec3(0.32, 0.39, 0.43), fermeture);
	surface.rgb += vec3(pression * 0.06);
	if (abs(cote_dechirure) > 0.5) {
		float cellule = UV.y * 11.0;
		float debut = hasard_surface(vec2(floor(cellule), 37.0));
		float fin = hasard_surface(vec2(floor(cellule) + 1.0, 37.0));
		float coupure = 0.5 + (mix(debut, fin, fract(cellule)) - 0.5) * 0.085;
		surface.a *= cote_dechirure < 0.0 ? step(UV.x, coupure) : step(coupure, UV.x);
	}
	COLOR = surface * modulation_noeud;
}
