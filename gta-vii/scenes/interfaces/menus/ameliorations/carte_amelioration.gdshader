shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"
uniform bool rarete_coloree = false;
uniform vec4 teinte_rarete : source_color = vec4(1.0);

// Le papier existant fournit la matière ; le centre reste clair pour les textes.
void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	papier.rgb *= vec3(0.91, 0.85, 0.73);
	// Colorer légèrement le papier sans masquer sa texture ni les textes.
	if (rarete_coloree) {
		papier.rgb *= mix(vec3(1.0), teinte_rarete.rgb, 0.24);
	}
	COLOR = habiller(UV, papier) * modulation_noeud;
}
