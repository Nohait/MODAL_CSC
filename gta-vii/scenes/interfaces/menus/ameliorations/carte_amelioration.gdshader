shader_type canvas_item;
#include "res://scenes/interfaces/menus/ameliorations/cadre_braise.gdshaderinc"
uniform bool rarete_coloree = false;
uniform vec4 teinte_rarete : source_color = vec4(1.0);
uniform float disparition = 0.0;
uniform float niveau_rarete = 0.0;
uniform vec2 centre_illustration = vec2(0.5, 0.32);
uniform float rayon_illustration = 55.0;
uniform float limite_metal = 0.55;

// Le papier existant fournit la matière ; le centre reste clair pour les textes.
void fragment() {
	vec4 papier = texture(TEXTURE, UV);
	papier.rgb *= vec3(0.91, 0.85, 0.73);
	// Colorer légèrement le papier sans masquer sa texture ni les textes.
	if (rarete_coloree) {
		vec2 p = UV * taille;
		float grain = bruit(p * 0.7);
		float brossage = sin(p.y * 2.5) * 0.013;
		float reflet = exp(-pow((UV.x + UV.y * 0.32 - 0.3 - survol * 0.3) / 0.18, 2.0));
		vec3 plaque = mix(vec3(0.22, 0.20, 0.17), teinte_rarete.rgb * 0.62, 0.7);
		plaque += (grain - 0.5) * 0.045 + brossage;
		plaque += mix(teinte_rarete.rgb, vec3(1.0), 0.3) * reflet * (0.24 + niveau_rarete * 0.045);
		// Une séparation légèrement déchirée raccorde métal sombre et parchemin clair.
		float separation = limite_metal + (bruit(vec2(UV.x * 22.0, 3.0)) - 0.5) * 0.012;
		float haut = 1.0 - smoothstep(separation - 0.002, separation + 0.002, UV.y);
		papier.rgb = mix(papier.rgb, plaque, haut);
		float joint = exp(-abs(UV.y - separation) * taille.y / 1.5);
		papier.rgb += mix(teinte_rarete.rgb, vec3(1.0), 0.35) * joint * 0.65;
	}
	COLOR = habiller(UV, papier) * modulation_noeud;
	if (rarete_coloree) {
		vec2 p = UV * taille;
		float bord = min(min(p.x, taille.x - p.x), min(p.y, taille.y - p.y));
		// Deux filets et des coins gravés gardent le centre en papier lisible.
		float cadre = exp(-pow((bord - 17.0) / 1.2, 2.0));
		cadre += exp(-pow((bord - 21.0) / 0.6, 2.0)) * step(1.0, niveau_rarete) * 0.45;
		vec2 coin = min(p, taille - p) - vec2(30.0);
		float ornement = exp(-pow((abs(coin.x) + abs(coin.y) - 10.0) / 1.4, 2.0));
		ornement *= (1.0 - smoothstep(18.0, 23.0, max(abs(coin.x), abs(coin.y))));
		float vague = 0.5 + 0.5 * sin(horloge * 1.6 + UV.y * 7.0);
		vec3 metal = mix(teinte_rarete.rgb * 0.5, mix(teinte_rarete.rgb, vec3(1.0), 0.45), vague);
		COLOR.rgb = mix(COLOR.rgb, metal, clamp(cadre + ornement * (0.5 + niveau_rarete * 0.15), 0.0, 1.0) * modulation_noeud.a);
		// La lueur reste autour du pictogramme ; aucune lumière ne traverse les descriptions.
		float distance_image = length((UV - centre_illustration) * taille);
		float anneau = exp(-pow((distance_image - rayon_illustration) / 1.5, 2.0));
		float halo = exp(-pow(distance_image / max(rayon_illustration, 1.0), 2.0));
		float vie = 0.8 + 0.2 * sin(horloge * 1.8);
		COLOR.rgb += teinte_rarete.rgb * (anneau * (0.12 + niveau_rarete * 0.08) + halo * niveau_rarete * 0.035) * vie * (1.0 + survol * 0.7) * modulation_noeud.a;
		// Les hautes raretés ont des éclats qui voyagent uniquement sur les filets.
		float scintillement = pow(max(0.0, sin(UV.y * 24.0 - UV.x * 13.0 - horloge * 2.0)), 18.0);
		COLOR.rgb += mix(teinte_rarete.rgb, vec3(1.0), 0.6) * cadre * scintillement * niveau_rarete * (0.12 + survol * 0.18) * modulation_noeud.a;
		if (niveau_rarete >= 2.0) {
			// Quelques étoiles lentes autour du médaillon, sans couvrir le pictogramme.
			vec2 relatif = (UV - centre_illustration) * taille;
			for (int i = 0; i < 4; i++) {
				float angle = float(i) * 1.5708 + horloge * 0.15;
				vec2 etoile = relatif - vec2(cos(angle), sin(angle)) * (rayon_illustration + 3.0);
				float croix = exp(-abs(etoile.x) * 1.4 - abs(etoile.y) * 0.3) + exp(-abs(etoile.y) * 1.4 - abs(etoile.x) * 0.3);
				float brillance = pow(0.5 + 0.5 * sin(horloge * 2.0 + float(i) * 2.0), 3.0);
				COLOR.rgb += mix(teinte_rarete.rgb, vec3(1.0), 0.5) * croix * brillance * (niveau_rarete - 1.0) * 0.22 * modulation_noeud.a;
			}
		}
	}
	if (disparition > 0.0) {
		// Le papier se consume depuis les bords, suivant une frontière irrégulière.
		float bord = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		float cendre = bord * 1.8 + bruit(UV * 18.0) * 0.15;
		float reste = smoothstep(disparition - 0.06, disparition + 0.02, cendre);
		float incandescent = 1.0 - smoothstep(0.0, 0.055, abs(cendre - disparition));
		COLOR.rgb = mix(COLOR.rgb, vec3(1.0, 0.4, 0.04), incandescent * 0.85);
		COLOR.a *= reste;
	}
}
