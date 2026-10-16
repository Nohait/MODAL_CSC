// Supports d’intervention : mêmes proportions et états sur tous les menus.
uniform vec2 taille = vec2(320.0, 480.0);
uniform float survol = 0.0;
uniform float selection = 0.0;
uniform float horloge = 0.0;
uniform float eclaircissement = 0.0;
uniform vec4 teinte_pochette : source_color = vec4(0.67, 0.73, 0.75, 1.0);
uniform vec4 teinte_rarete : source_color = vec4(0.67, 0.73, 0.75, 1.0);
uniform bool rarete_coloree = false;
uniform float disparition = 0.0;
uniform float niveau_eclat = 0.0;
uniform float pression = 0.0;
uniform float luminosite_pochette = 1.0;
uniform float cote_dechirure = 0.0;
varying vec4 modulation_noeud;
void vertex() { modulation_noeud = COLOR; }
float distance_surface(vec2 uv) {
	vec2 q = abs((uv - 0.5) * taille) - (taille * 0.5 - vec2(5.0));
	return length(max(q, vec2(0.0))) + min(max(q.x, q.y), 0.0) - 4.0;
}
vec4 support_intervention(vec2 uv, vec3 fond, vec3 accent) {
	float d = distance_surface(uv);
	float actif = clamp(max(survol, selection), 0.0, 1.0);
	vec3 couleur = fond + vec3(actif * 0.035 + eclaircissement * 0.25);
	couleur = mix(couleur, mix(vec3(0.32, 0.39, 0.43), accent, actif), smoothstep(-2.0, -1.0, d));
	return vec4(couleur, (1.0 - smoothstep(-1.0, 0.0, d)) * (1.0 - disparition));
}
float hasard_surface(vec2 p) { return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453); }
