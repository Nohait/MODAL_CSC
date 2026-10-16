shader_type canvas_item;

uniform vec2 taille = vec2(320.0, 500.0);
uniform bool rarete_coloree = false;
uniform vec4 teinte_rarete : source_color = vec4(1.0);
uniform float survol = 0.0;
uniform float disparition = 0.0;
varying vec4 modulation;

void vertex() {
	modulation = COLOR;
}

void fragment() {
	vec2 p = UV * taille;
	vec2 q = abs(p - taille * 0.5) - (taille * 0.5 - vec2(6.0));
	float distance = length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 4.0;
	float masque = 1.0 - smoothstep(-1.0, 0.0, distance);
	float bord = smoothstep(-2.0, -1.0, distance);
	vec3 couleur = vec3(0.118, 0.165, 0.192);
	vec3 accent = rarete_coloree ? teinte_rarete.rgb : vec3(0.675, 0.729, 0.749);
	couleur = mix(couleur, mix(vec3(0.286, 0.357, 0.388), accent, survol), bord);
	// Une bande identifie la rareté ; le libellé reste la référence accessible.
	float bande = step(4.0, p.y) * (1.0 - step(8.0, p.y));
	couleur = mix(couleur, accent, bande);
	float repere = step(24.0, p.x) * (1.0 - step(48.0, p.x)) * step(49.0, p.y) * (1.0 - step(51.0, p.y));
	couleur = mix(couleur, vec3(0.675, 0.729, 0.749), repere);
	COLOR = vec4(couleur, masque * (1.0 - disparition)) * modulation;
}
