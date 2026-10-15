shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, blend_mix;

uniform sampler2D atlas : source_color, filter_linear;
uniform vec2 grille = vec2(16.0, 4.0);
uniform float decalage = 0.0;
uniform float intensite : hint_range(0.0, 1.0) = 1.0;
uniform bool fumee = false;
uniform float opacite = 1.0;
uniform float agitation = 1.0;
uniform float horloge = -1.0;
uniform bool alignement_passage = false;
uniform vec2 limites_x = vec2(-1.5, 1.5);
varying vec3 position_monde;

void vertex() {
	vec3 droite = alignement_passage ? vec3(1.0, 0.0, 0.0) : normalize(vec3(INV_VIEW_MATRIX[0].x, 0.0, INV_VIEW_MATRIX[0].z));
	vec3 haut = vec3(0.0, 1.0, 0.0);
	mat4 monde = mat4(vec4(droite * length(MODEL_MATRIX[0].xyz), 0.0),
		vec4(haut * length(MODEL_MATRIX[1].xyz), 0.0),
		vec4(cross(droite, haut) * length(MODEL_MATRIX[2].xyz), 0.0), MODEL_MATRIX[3]);
	MODELVIEW_MATRIX = VIEW_MATRIX * monde;
	position_monde = (monde * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	if (position_monde.x < limites_x.x || position_monde.x > limites_x.y) { discard; }
	float temps = horloge >= 0.0 ? horloge : TIME * agitation;
	float image = mod(floor(temps * 25.0 + decalage), grille.x * grille.y);
	vec2 cellule = vec2(mod(image, grille.x), floor(image / grille.x));
	vec4 couleur = texture(atlas, (UV + cellule) / grille);
	float luminosite = max(couleur.r, max(couleur.g, couleur.b));
	ALBEDO = fumee ? vec3(0.09, 0.085, 0.08) : couleur.rgb * mix(0.2, 1.0, intensite);
	EMISSION = fumee ? vec3(0.0) : couleur.rgb * 2.0 * intensite;
	ALPHA = (fumee ? couleur.a : luminosite) * opacite;
}
