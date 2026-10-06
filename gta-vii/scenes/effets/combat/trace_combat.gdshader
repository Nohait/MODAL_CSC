shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;
uniform vec4 teinte : source_color = vec4(0.9, 0.95, 1.0, 0.35);
uniform float opacite = 1.0;
uniform float graine = 0.0;
float bruit(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float angle = atan(p.y, p.x);
	float bord = 0.7 + sin(angle * 5.0 + graine) * 0.08 + sin(angle * 9.0 - graine) * 0.04;
	float masque = 1.0 - smoothstep(bord - 0.18, bord, length(p));
	float grain = bruit(floor(UV * 50.0) + graine);
	ALBEDO = teinte.rgb * (0.85 + grain * 0.15);
	ROUGHNESS = 0.9;
	ALPHA = teinte.a * masque * opacite;
}
