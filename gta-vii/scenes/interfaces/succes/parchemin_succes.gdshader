shader_type canvas_item;
#include "res://scenes/interfaces/theme_intervention/surface.gdshaderinc"

void fragment() {
	vec4 surface = support_intervention(UV, vec3(0.10), teinte_rarete.rgb);
	// Un liseré discret distingue les succès acquis sans colorer tout le panneau.
	vec2 pixel = UV * taille;
	float lisere = step(6.0, pixel.x) * (1.0 - step(9.0, pixel.x));
	lisere *= step(16.0, pixel.y) * (1.0 - step(taille.y - 16.0, pixel.y));
	surface.rgb = mix(surface.rgb, rarete_coloree ? teinte_rarete.rgb : vec3(0.337255), lisere);
	COLOR = surface * modulation_noeud;
}
