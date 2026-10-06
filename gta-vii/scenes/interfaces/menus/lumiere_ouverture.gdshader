shader_type canvas_item;
render_mode blend_add;

uniform float pression = 0.0;
uniform float horloge = 0.0;
uniform float aspect = 1.7778;

void fragment() {
	vec2 p = UV - vec2(0.5);
	p.x *= aspect;
	float distance = length(p);
	float angle = atan(p.y, p.x);
	// La lumière gagne les côtés de l'écran pendant le gonflement du paquet.
	float etendue = mix(7.0, 1.6, pression);
	float halo = exp(-distance * etendue);
	float rais = pow(max(0.0, sin(angle * 7.0 + horloge * 0.3)), 4.0);
	float coeur = exp(-distance * 12.0);
	vec3 couleur = mix(vec3(1.0, 0.38, 0.10), vec3(1.0, 0.80, 0.38), coeur);
	// Une addition douce éclaire l'interface sans la remplacer par un écran blanc.
	float lumiere = pression * (halo * (0.30 + rais * 0.28) + coeur * 0.18);
	COLOR = vec4(couleur, lumiere);
}
