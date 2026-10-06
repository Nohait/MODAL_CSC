shader_type canvas_item;
#include "res://scenes/interfaces/menus/metal_brosse.gdshaderinc"
uniform float survol = 0.0;
uniform vec2 taille = vec2(74.0);
varying vec4 modulation;
void vertex() { modulation = COLOR; }
void fragment() {
	vec2 bord = min(UV, vec2(1.0) - UV) * taille;
	float coins = max(0.0, 10.0 - bord.x) + max(0.0, 10.0 - bord.y);
	float decoupe = 1.0 - smoothstep(9.0, 10.0, coins);
	vec3 metal = metal_brosse(UV, taille, survol);
	COLOR = vec4(metal * vec3(1.6, 0.35, 0.3) + vec3(0.12, 0.01, 0.01), decoupe) * modulation;
}
