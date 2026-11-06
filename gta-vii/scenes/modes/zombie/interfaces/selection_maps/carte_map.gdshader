shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"
void fragment() {
	vec4 image = texture(TEXTURE, UV);
	vec4 cadre = support_intervention(UV, image.rgb, vec3(0.960784, 0.960784, 0.941176));
	COLOR = vec4(cadre.rgb, cadre.a * image.a) * modulation_noeud;
}
