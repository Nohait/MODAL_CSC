shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;

void vertex() {
	// Orienter chaque petit nuage vers la caméra, en conservant sa taille.
	vec3 taille = vec3(length(MODEL_MATRIX[0].xyz), length(MODEL_MATRIX[1].xyz), length(MODEL_MATRIX[2].xyz));
	MODELVIEW_MATRIX = VIEW_MATRIX * mat4(INV_VIEW_MATRIX[0] * taille.x,
		INV_VIEW_MATRIX[1] * taille.y, INV_VIEW_MATRIX[2] * taille.z, MODEL_MATRIX[3]);
}

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float contour = 1.0 - smoothstep(0.1, 1.0, length(p));
	float volutes = 0.7 + 0.3 * sin(UV.x * 13.0 + sin(UV.y * 11.0 + TIME * 0.2));
	ALBEDO = COLOR.rgb;
	// La rampe de couleur des particules assure l'apparition et la disparition douce.
	ALPHA = contour * volutes * COLOR.a;
}
