shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 teinte : source_color = vec4(1.0, 0.4, 0.1, 1.0);
uniform float horloge = 0.0;
uniform float intensite = 1.0;
void fragment() {
	float contour = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.5);
	ALBEDO = teinte.rgb;
	EMISSION = teinte.rgb * 1.4;
	ALPHA = contour * (0.25 + 0.1 * sin(horloge * 3.0)) * intensite;
}
