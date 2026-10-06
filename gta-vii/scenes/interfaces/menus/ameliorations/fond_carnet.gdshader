shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"
uniform vec4 zone_permanents = vec4(0.0);
uniform vec4 zone_temporaires = vec4(0.0);

// Un classeur métallique graphite, avec des filets cuivrés et des bords brûlés.
void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	float grain = dot(papier.rgb, vec3(0.299, 0.587, 0.114));
	papier.rgb = mix(vec3(0.075, 0.085, 0.095), vec3(0.23, 0.25, 0.27), smoothstep(0.3, 0.9, grain));
	// Un grain fin évite que l'agrandissement de la petite texture paraisse uniforme.
	papier.rgb *= 0.96 + 0.08 * bruit(UV * taille * 0.25);
	papier.rgb += sin(UV.y * taille.y * 2.0) * 0.006;
	// Une lumière douce suggère la matière brossée sans éclaircir tous les encarts.
	float lumiere = exp(-length((UV - vec2(0.25, 0.15)) * vec2(1.0, 1.3)) * 2.4);
	papier.rgb += vec3(0.075, 0.075, 0.07) * lumiere;
	vec2 p = UV * taille;
	float bord = min(min(p.x, taille.x - p.x), min(p.y, taille.y - p.y));
	float cadre = exp(-pow((bord - 24.0) / 1.2, 2.0)) + exp(-pow((bord - 29.0) / 0.6, 2.0)) * 0.4;
	papier.rgb += vec3(0.55, 0.34, 0.15) * cadre;
	for (int i = 0; i < 2; i++) {
		vec4 zone = i == 0 ? zone_permanents : zone_temporaires;
		if (zone.z > 0.0) {
			vec2 local = p - zone.xy;
			vec2 milieu = zone.zw * 0.5;
			vec2 q = abs(local - milieu) - (milieu - vec2(7.0));
			float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 7.0;
			float interieur = 1.0 - smoothstep(-1.0, 1.0, distance);
			papier.rgb *= 1.0 - interieur * 0.18;
			vec3 accent = i == 0 ? vec3(0.65, 0.40, 0.16) : vec3(0.25, 0.52, 0.43);
			papier.rgb += accent * exp(-abs(distance) * 0.7) * 0.4;
			// Le bandeau supérieur accueille les titres et sépare les vignettes du reste.
			papier.rgb += accent * exp(-abs(local.y - 70.0) * 0.8) * interieur * 0.35;
		}
	}
	COLOR = habiller(UV, papier) * modulation_noeud;
}
