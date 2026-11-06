shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform vec4 teinte : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float horloge = 0.0;
uniform float intensite = 1.0;
uniform float emission : hint_range(0.0, 2.0) = 0.1;
uniform float opacite_corps : hint_range(0.0, 0.8) = 0.45;
uniform bool fissures = false;
varying vec3 position_locale;
void vertex() { position_locale = VERTEX; }
void fragment() {
	float contour = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.5);
	vec3 couleur = teinte.rgb;
	ALBEDO = couleur;
	float veines = fissures ? pow(1.0 - abs(sin(position_locale.y * 19.0 + sin(position_locale.x * 16.0) * 3.0 + position_locale.z * 13.0)), 16.0) * 0.3 : 0.0;
	float halo = clamp((veines + contour) * (0.25 + 0.1 * sin(horloge * 3.0)) * intensite, 0.0, 1.0);
	// La couleur reste lisible de face et entre les pulsations du contour.
	float opacite = opacite_corps + halo * (1.0 - opacite_corps);
	ALPHA = opacite;
	// Renforcer la couleur du corps n'ajoute aucune émission lumineuse.
	EMISSION = couleur * emission * halo / max(opacite, 0.001);
}
