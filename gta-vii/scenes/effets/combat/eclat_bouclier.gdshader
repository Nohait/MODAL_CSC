shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;

void fragment() {
	// Le centre reste transparent : on voit surtout le contour du bouclier.
	float contour = pow(1.0 - abs(dot(normalize(NORMAL), normalize(VIEW))), 2.0);
	ALBEDO = vec3(0.12, 0.55, 1.0);
	ALPHA = contour * 0.55;
}
