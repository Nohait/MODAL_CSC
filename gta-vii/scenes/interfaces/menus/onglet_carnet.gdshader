shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"

uniform sampler2D plastique : source_color, repeat_enable, filter_linear_mipmap;
uniform float intensite_plastique : hint_range(0.0, 1.0) = 0.48;

void fragment() {
	vec4 surface = support_intervention(UV, vec3(0.118, 0.165, 0.192), vec3(0.89, 0.776, 0.353));
	vec3 matiere = texture(plastique, UV * taille / 360.0).rgb;
	float luminosite = dot(matiere, vec3(0.2126, 0.7152, 0.0722));
	float relief = clamp(0.72 + luminosite * 3.7, 0.72, 1.45);
	surface.rgb *= mix(1.0, relief, intensite_plastique);
	COLOR = surface * modulation_noeud;
}
