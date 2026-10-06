shader_type canvas_item;
#include "res://scenes/interfaces/menus/metal_brosse.gdshaderinc"
uniform float survol = 0.0;
// Les infobulles peuvent éclaircir leur métal sans changer les boutons.
uniform float eclaircissement : hint_range(0.0, 0.3) = 0.0;
uniform vec2 taille = vec2(300.0, 74.0);
varying vec4 modulation;
void vertex() { modulation = COLOR; }
void fragment() {
	vec2 bord = min(UV, vec2(1.0) - UV) * taille;
	float coins = max(0.0, 14.0 - bord.x) + max(0.0, 14.0 - bord.y);
	float decoupe = 1.0 - smoothstep(13.0, 14.0, coins);
	COLOR = vec4(metal_brosse(UV, taille, survol) + vec3(eclaircissement), decoupe) * modulation;
}
