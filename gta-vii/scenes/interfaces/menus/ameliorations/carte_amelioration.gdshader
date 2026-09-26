shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

// Le papier existant fournit la matière ; le centre reste clair pour les textes.
void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	papier.rgb *= vec3(0.91, 0.85, 0.73);
	COLOR = habiller(UV, papier) * modulation_noeud;
}
