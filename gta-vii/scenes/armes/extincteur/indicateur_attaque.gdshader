shader_type spatial;
render_mode unshaded, cull_disabled, shadows_disabled;

uniform vec4 couleur : source_color = vec4(1.0);
uniform float opacite_fond = 0.10;
uniform float opacite_contour = 0.65;
uniform float largeur_contour = 0.035;
uniform float rayon = 2.8;
uniform float demi_angle = 0.2618;
uniform vec2 origine_jet;
uniform vec2 direction_jet;
uniform vec2 centre_zone;
varying vec2 position_sol;

void vertex() {
	// Coordonnées dans la salle : X et Z représentent le sol horizontal.
	position_sol = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xz;
}

void fragment() {
	vec2 vers_point = position_sol - origine_jet;
	float distance_point = length(vers_point);
	float alignement = dot(vers_point / max(distance_point, 0.0001), direction_jet);
	float angle = acos(clamp(alignement, -1.0, 1.0));
	// Intersection du disque de DamageArea et du cône de visée.
	// Le départ du jet et le centre de DamageArea peuvent être décalés.
	float bord_cercle = rayon - length(position_sol - centre_zone);
	float bord_cone = sin(demi_angle - angle) * distance_point;
	if (bord_cercle < 0.0 || angle > demi_angle) {
		discard;
	}
	float distance_bord = min(bord_cercle, bord_cone);
	float contour = 1.0 - smoothstep(largeur_contour, largeur_contour + 0.015, distance_bord);
	ALBEDO = couleur.rgb;
	ALPHA = couleur.a * mix(opacite_fond, opacite_contour, contour);
}
