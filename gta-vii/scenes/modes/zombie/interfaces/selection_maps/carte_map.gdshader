shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

void fragment() {
	// Garder les couleurs de la capture, avec le même cadre brûlé que les cartes.
	COLOR = habiller(UV, texture(TEXTURE, UV)) * modulation_noeud;
}
