shader_type spatial;
uniform sampler2D texture_couleur : source_color, filter_linear_mipmap;
uniform sampler2D texture_normale : hint_normal, filter_linear_mipmap;
uniform vec4 couleur_base : source_color = vec4(1.0);
uniform vec4 peinture : source_color = vec4(0.3, 0.4, 0.5, 1.0);
uniform bool texture_presente = false;
uniform bool relief_present = false;
uniform bool recolorer = false;
uniform float salissure : hint_range(0.0, 1.0) = 0.25;
uniform float rugosite = 0.45;
uniform float metal = 0.0;
varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 base = couleur_base.rgb;
	if (texture_presente) base *= texture(texture_couleur, UV).rgb;
	// Préserver les parties sombres des textures, notamment les joints et les pneus.
	if (recolorer) base = mix(base, peinture.rgb * (0.4 + dot(base, vec3(0.333)) * 0.6), 0.82);
	float tache = sin(position_monde.x * 2.7 + sin(position_monde.z * 1.6)) * sin(position_monde.z * 3.1 + position_monde.y * 2.0);
	float suie = salissure * smoothstep(-0.8, 0.7, tache);
	ALBEDO = mix(base, vec3(0.035, 0.028, 0.023), suie);
	ROUGHNESS = mix(rugosite, 0.95, suie);
	METALLIC = metal * (1.0 - suie);
	SPECULAR = 0.4;
	if (relief_present) NORMAL_MAP = texture(texture_normale, UV).rgb;
}
