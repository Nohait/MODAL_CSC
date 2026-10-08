shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;

uniform bool enveloppe = false;
uniform float energie : hint_range(0.0, 5.0) = 1.8;
uniform float agitation : hint_range(0.0, 0.4) = 0.12;
uniform float vitesse_feu : hint_range(0.0, 10.0) = 3.0;
varying vec3 position_locale;

float hasard(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}
float bruit(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(hasard(i), hasard(i + vec3(1,0,0)), f.x),
		mix(hasard(i + vec3(0,1,0)), hasard(i + vec3(1,1,0)), f.x), f.y),
		mix(mix(hasard(i + vec3(0,0,1)), hasard(i + vec3(1,0,1)), f.x),
		mix(hasard(i + vec3(0,1,1)), hasard(i + vec3(1,1,1)), f.x), f.y), f.z);
}
void vertex() {
	position_locale = VERTEX;
	// Le bruit en 3D évite une couture visible sur la sphère.
	float turbulence = bruit(VERTEX * 17.0 + vec3(0.0, 0.0, -TIME * vitesse_feu));
	VERTEX *= 1.0 + (turbulence - 0.5) * agitation * 2.0;
}
void fragment() {
	float chaleur = bruit(position_locale * 24.0 + vec3(0.0, 0.0, -TIME * vitesse_feu));
	vec3 couleur = mix(vec3(1.0, 0.12, 0.015), vec3(1.0, 0.85, 0.3), smoothstep(0.25, 0.8, chaleur));
	float alpha = 1.0;
	if (enveloppe) {
		// Des ouvertures irrégulières révèlent le cœur, au lieu d'une seconde boule pleine.
		alpha = smoothstep(0.35, 0.7, chaleur) * 0.65;
		couleur = mix(vec3(1.0, 0.06, 0.005), vec3(1.0, 0.48, 0.025), chaleur);
	} else {
		couleur = mix(vec3(1.0, 0.4, 0.035), vec3(1.0, 0.95, 0.65), chaleur);
	}
	ALBEDO = couleur;
	EMISSION = couleur * energie;
	ALPHA = alpha;
}
