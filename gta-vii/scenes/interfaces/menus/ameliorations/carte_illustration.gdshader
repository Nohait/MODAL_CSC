shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

// Recadrage centré sans déformer l'illustration, quel que soit son format.
void fragment() {
	vec2 dimensions_image = vec2(textureSize(TEXTURE, 0));
	float ratio_image = dimensions_image.x / dimensions_image.y;
	float ratio_cadre = taille.x / taille.y;
	vec2 uv_image = UV - 0.5;
	if (ratio_image > ratio_cadre) {
		uv_image.x *= ratio_cadre / ratio_image;
	} else {
		uv_image.y *= ratio_image / ratio_cadre;
	}
	vec4 illustration = texture(TEXTURE, uv_image + 0.5);
	// Léger assombrissement aux bords pour encastrer l'image dans le papier.
	illustration.rgb *= 0.9 + 0.1 * smoothstep(0.0, 30.0, distance_bord(UV));
	COLOR = habiller(UV, illustration) * modulation_noeud;
}
