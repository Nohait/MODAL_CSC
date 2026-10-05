shader_type spatial;
render_mode blend_mix, depth_draw_never;

uniform float quantite : hint_range(0.0, 1.0) = 0.25;
varying vec3 position_monde;

void vertex() {
	position_monde = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	// Une couche irrégulière de suie laisse les matériaux et couleurs d'origine visibles.
	float tache = sin(position_monde.x * 3.1 + sin(position_monde.z * 2.0)) * sin(position_monde.y * 4.0 + position_monde.z);
	ALBEDO = vec3(0.035, 0.025, 0.018);
	ROUGHNESS = 1.0;
	SPECULAR = 0.0;
	ALPHA = quantite * smoothstep(-0.7, 0.5, tache);
}
