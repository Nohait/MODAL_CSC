shader_type spatial;
render_mode blend_mix, depth_prepass_alpha;

uniform vec4 peinture : source_color = vec4(0.62, 0.055, 0.035, 1.0);
uniform vec4 metal : source_color = vec4(0.26, 0.29, 0.31, 1.0);
uniform float rugosite = 0.85;
uniform bool electrique = false;
uniform bool givre = false;
uniform bool raccord_actif = false;
uniform bool fonte_lourde = false;
uniform float pression = 0.0;
uniform float charge_raccord = 0.0;
uniform vec4 couleur_jauge : source_color = vec4(1.0, 0.58, 0.08, 1.0);
uniform float impulsion = 0.0;
uniform sampler2D texture_givre : source_color, repeat_enable;
uniform float opacite = 1.0;
uniform mat4 transformation_modele;
uniform vec3 minimum_modele;
uniform vec3 taille_modele;
varying vec3 position_normalisee;

void vertex() {
	vec3 position = (transformation_modele * vec4(VERTEX, 1.0)).xyz;
	position_normalisee = (position - minimum_modele) / max(taille_modele, vec3(0.001));
}

void fragment() {
	float hauteur = position_normalisee.y;
	vec2 lateral = abs(position_normalisee.xz * 2.0 - 1.0);
	// Le socle et les extrémités des raccords distinguent le métal de la peinture.
	float socle = 1.0 - smoothstep(0.08, 0.12, hauteur);
	float raccord = smoothstep(0.66, 0.8, max(lateral.x, lateral.y));
	raccord *= smoothstep(0.25, 0.35, hauteur) * (1.0 - smoothstep(0.75, 0.82, hauteur));
	float metal_visible = max(socle, raccord);
	vec3 rouge = peinture.rgb * mix(0.85, 1.12, smoothstep(0.1, 0.95, hauteur));
	ALBEDO = mix(rouge, metal.rgb, metal_visible);
	if (electrique) {
		ALBEDO = mix(ALBEDO, vec3(0.08, 0.22, 0.36), 0.8);
		float bande = 1.0 - smoothstep(0.01, 0.03, abs(hauteur - 0.62));
		EMISSION = vec3(0.12, 0.65, 1.0) * bande * (1.5 + 0.3 * sin(TIME * 15.0));
	}
	if (fonte_lourde) {
		ALBEDO = mix(ALBEDO, vec3(0.12, 0.14, 0.16), metal_visible * 0.4);
	}
	float angle = atan(position_normalisee.z - 0.5, position_normalisee.x - 0.5) / 6.283185 + 0.5;
	float ceinture = 1.0 - smoothstep(0.018, 0.035, abs(hauteur - 0.56));
	float remplissage = 1.0 - smoothstep(charge_raccord - 0.015, charge_raccord + 0.015, angle);
	if (raccord_actif) {
		ALBEDO = mix(ALBEDO, vec3(0.025, 0.055, 0.07), ceinture * 0.85);
		EMISSION += couleur_jauge.rgb * ceinture * remplissage * step(0.01, charge_raccord) * 1.5;
	}
	EMISSION += vec3(0.25, 0.7, 0.9) * raccord * (pression * 0.7 + impulsion * 0.5);
	if (givre) {
		vec3 glace = texture(texture_givre, vec2(angle * 3.0, hauteur * 2.0)).rgb;
		float couverture = smoothstep(0.18, 0.7, glace.r) * 0.75;
		ALBEDO = mix(ALBEDO, glace * vec3(0.8, 0.95, 1.0), couverture);
	}
	if (raccord_actif) {
		// La jauge conserve sa couleur même sur une bouche givrée ou électrique.
		float niveau = remplissage * step(0.01, charge_raccord);
		ALBEDO = mix(ALBEDO, mix(vec3(0.065, 0.04, 0.015), couleur_jauge.rgb, niveau), ceinture * 0.9);
	}
	ROUGHNESS = givre ? 0.6 : rugosite;
	METALLIC = metal_visible * 0.15;
	SPECULAR = 0.18;
	ALPHA = opacite;
}
