shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"
#include "res://scenes/interfaces/menus/metal_brosse.gdshaderinc"
uniform float selection = 0.0;
void fragment() {
	vec4 surface = texture(TEXTURE, UV);
	surface.rgb = metal_brosse(UV, taille, max(selection, survol));
	COLOR = habiller(UV, surface) * modulation_noeud;
}
