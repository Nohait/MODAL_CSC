shader_type spatial;
render_mode cull_disabled, shadows_disabled;

uniform sampler2D texture_glace : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D texture_rugosite : filter_linear_mipmap, repeat_enable;
uniform vec4 couleur : source_color = vec4(0.74, 0.94, 1.0, 0.4);
uniform float taille_texture : hint_range(0.25, 4.0) = 1.5;
uniform float relief : hint_range(0.0, 1.0) = 0.3;
uniform float rugosite : hint_range(0.05, 1.0) = 0.2;
uniform float transparence : hint_range(0.0, 1.0) = 0.7;
uniform float opacite = 1.0;
uniform float fonte : hint_range(0.0, 1.0) = 0.0;
uniform bool forme_libre = false;
varying vec2 point_sol;
varying vec2 position_sol;

void vertex() {
	point_sol = VERTEX.xz;
	// Les dépôts voisins partagent la même texture, sans étirement selon la portée.
	position_sol = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 coordonnees = position_sol / taille_texture;
	vec3 glace = texture(texture_glace, coordonnees).rgb;
	float detail = dot(glace, vec3(0.299, 0.587, 0.114));
	float couverture;
	if (forme_libre) {
		float bord = min(min(UV.x, 1.0 - UV.x), min(UV.y, 1.0 - UV.y));
		couverture = smoothstep(fonte * 0.5, fonte * 0.5 + 0.035, bord + (detail - 0.5) * 0.025);
	} else {
		float angle = atan(point_sol.y, point_sol.x);
		float bord = (0.9 + sin(angle * 5.0) * 0.035 + sin(angle * 9.0 + 1.7) * 0.025) * (1.0 - fonte);
		couverture = 1.0 - smoothstep(bord - 0.12, bord, length(point_sol));
	}
	// Décolorer la texture d'origine pour garder une glace claire, plutôt que verte.
	ALBEDO = mix(vec3(0.48, 0.67, 0.75), vec3(0.92, 0.98, 1.0), detail) * mix(vec3(1.0), couleur.rgb, 0.25);
	NORMAL_MAP = texture(texture_normale, coordonnees).rgb;
	NORMAL_MAP_DEPTH = relief;
	ROUGHNESS = clamp(rugosite * mix(0.65, 1.4, texture(texture_rugosite, coordonnees).r), 0.05, 1.0);
	SPECULAR = 0.65;
	METALLIC = 0.0;
	ALPHA = transparence * opacite * couverture * (1.0 - smoothstep(0.85, 1.0, fonte));
}
