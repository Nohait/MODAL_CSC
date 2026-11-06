shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"
#include "res://scenes/interfaces/theme_intervention/couleurs_boutons.gdshaderinc"

uniform sampler2D plastique : source_color, repeat_enable, filter_linear_mipmap;
uniform float intensite_plastique : hint_range(0.0, 1.0) = 0.58;
uniform bool grise = false;

void fragment() {
	vec4 surface = support_intervention(UV, fond_bouton.rgb, contour_bouton.rgb);
	vec3 matiere = texture(plastique, UV * taille / 360.0).rgb;
	float luminosite = dot(matiere, vec3(0.2126, 0.7152, 0.0722));
	float relief = clamp(0.72 + luminosite * 3.7, 0.72, 1.45);
	surface.rgb *= mix(1.0, relief, intensite_plastique);
	if (grise) {
		surface.rgb = vec3(dot(surface.rgb, vec3(0.2126, 0.7152, 0.0722)));
	}
	COLOR = surface * modulation_noeud;
}
