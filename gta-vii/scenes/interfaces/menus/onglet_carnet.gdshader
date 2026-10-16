shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"
void fragment() {
	COLOR = support_intervention(UV, vec3(0.118, 0.165, 0.192), vec3(0.89, 0.776, 0.353)) * modulation_noeud;
}
