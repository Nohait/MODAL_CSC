shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

// Le même papier et le même cadre que les cartes, teints en bordeaux.
// Le centre sombre laisse les titres crème et les cartes claires bien lisibles.
void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	float grain = dot(papier.rgb, vec3(0.299, 0.587, 0.114));
	papier.rgb = mix(vec3(0.055, 0.012, 0.02), vec3(0.30, 0.085, 0.10), smoothstep(0.3, 0.9, grain));
	// Un grain fin évite que l'agrandissement de la petite texture paraisse uniforme.
	papier.rgb *= 0.88 + 0.24 * bruit(UV * taille * 0.25);
	COLOR = habiller(UV, papier) * modulation_noeud;
}
