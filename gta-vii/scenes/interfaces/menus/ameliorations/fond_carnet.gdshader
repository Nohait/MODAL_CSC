shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"
void fragment() {
	COLOR = support_intervention(UV, vec3(0.133333, 0.133333, 0.133333), vec3(0.960784, 0.960784, 0.941176)) * modulation_noeud;
}
