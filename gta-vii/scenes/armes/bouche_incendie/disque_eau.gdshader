shader_type spatial;
render_mode unshaded, blend_mix, cull_disabled, depth_draw_never;
uniform vec4 couleur : source_color = vec4(0.35, 0.85, 1.0, 0.6);
uniform float progression = -1.0;
uniform float cycle_visee = 0.0;
uniform float epaisseur_contour = 0.008;
void fragment() {
	float r = length(UV - vec2(0.5)) * 2.0;
	// L'anticrénelage suit les pixels à l'écran, même avec la caméra éloignée.
	float aa = max(fwidth(r), 0.001);
	float interieur = 1.0 - smoothstep(1.0 - aa, 1.0 + aa, r);
	float bord = (1.0 - smoothstep(epaisseur_contour, epaisseur_contour + aa, abs(r - (1.0 - epaisseur_contour)))) * interieur;
	float onde = (1.0 - smoothstep(0.03, 0.14, abs(r - progression))) * (1.0 - progression);
	float front = (1.0 - smoothstep(0.012, 0.012 + aa, abs(r - cycle_visee))) * interieur;
	float blanc = (1.0 - smoothstep(cycle_visee - aa, cycle_visee + aa, r)) * 0.13;
	float fondu = smoothstep(0.0, 0.08, cycle_visee) * (1.0 - smoothstep(0.8, 1.0, cycle_visee));
	float animation = (blanc + front * 0.45) * fondu * interieur;
	float fond = interieur * 0.07 + bord;
	ALBEDO = progression < 0.0 ? mix(couleur.rgb, vec3(1.0), animation / max(fond + animation, 0.001)) : couleur.rgb;
	ALPHA = couleur.a * (progression < 0.0 ? fond + animation : onde);
}
