shader_type canvas_item;

uniform float progression : hint_range(0.0, 1.0) = 1.0;
uniform float intensite : hint_range(0.0, 2.0) = 0.65;
uniform float vitesse : hint_range(0.0, 2.0) = 0.35;

float bruit(vec2 p) {
	vec2 cellule = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	vec4 h = fract(sin(vec4(dot(cellule, vec2(127.1, 311.7)), dot(cellule + vec2(1, 0), vec2(127.1, 311.7)), dot(cellule + vec2(0, 1), vec2(127.1, 311.7)), dot(cellule + vec2(1), vec2(127.1, 311.7)))) * 43758.5453);
	return mix(mix(h.x, h.y, f.x), mix(h.z, h.w, f.x), f.y);
}

void fragment() {
	// Le motif couvre toute la rainure ; seule sa chaleur bouge, sans flammes répétées.
	vec2 p = UV * vec2(45.0, 2.5);
	float n = bruit(p) * 0.7 + bruit(p * 2.7) * 0.3;
	float fissures = 1.0 - smoothstep(0.025, 0.095, abs(n - 0.5));
	float chaleur = 0.75 + 0.25 * sin(TIME * vitesse * 4.0 + n * 15.0 + UV.x * 8.0);
	float relief = pow(max(0.0, sin(UV.y * 3.14159)), 0.5);
	vec3 couleur = mix(vec3(0.22, 0.025, 0.025), vec3(0.65, 0.09, 0.035), relief);
	couleur = mix(couleur, vec3(1.0, 0.43, 0.10), fissures * chaleur * intensite);
	float bord = smoothstep(0.0, 0.09, UV.y) * smoothstep(0.0, 0.09, 1.0 - UV.y);
	COLOR = vec4(couleur, step(UV.x, progression) * bord);
}
