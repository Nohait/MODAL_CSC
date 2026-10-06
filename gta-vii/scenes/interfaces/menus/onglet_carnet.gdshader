shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

uniform float selection = 0.0;

void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	float grain = dot(papier.rgb, vec3(0.299, 0.587, 0.114));
	// Les onglets reprennent le métal graphite ; le cuivre souligne l'option active.
	vec3 sombre = mix(vec3(0.08, 0.095, 0.11), vec3(0.26, 0.29, 0.32), grain);
	vec3 actif = mix(vec3(0.18, 0.20, 0.22), vec3(0.39, 0.42, 0.44), grain);
	papier.rgb = mix(sombre, actif, selection);
	papier.rgb += sin(UV.y * taille.y * 2.0) * 0.008;
	float bord = min(UV.x * taille.x, (1.0 - UV.x) * taille.x);
	float filet = exp(-abs(UV.y * taille.y - (taille.y - 7.0)) * 0.9);
	papier.rgb += vec3(0.55, 0.34, 0.16) * filet * (0.25 + selection * 0.75) * smoothstep(8.0, 14.0, bord);
	COLOR = habiller(UV, papier) * modulation_noeud;
}
