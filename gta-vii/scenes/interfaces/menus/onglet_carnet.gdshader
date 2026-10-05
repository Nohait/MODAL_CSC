shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"

uniform float selection = 0.0;

void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	float grain = dot(papier.rgb, vec3(0.299, 0.587, 0.114));
	// Le marque-page reprend le papier bordeaux et le bord brûlé du carnet.
	vec3 sombre = mix(vec3(0.10, 0.045, 0.04), vec3(0.30, 0.16, 0.12), grain);
	vec3 actif = mix(vec3(0.24, 0.10, 0.065), vec3(0.60, 0.37, 0.22), grain);
	papier.rgb = mix(sombre, actif, selection);
	COLOR = habiller(UV, papier) * modulation_noeud;
}
