shader_type spatial;
render_mode unshaded, blend_mix, depth_draw_never, cull_disabled;
uniform sampler2D animation : source_color, filter_linear, repeat_disable;
uniform float decalage = 0.0;
uniform float vitesse = 18.0;
void fragment() {
	// L'atlas contient 40 images : 8 colonnes et 5 lignes.
	float image = mod(floor((TIME + decalage) * vitesse), 40.0);
	vec2 cellule = vec2(mod(image, 8.0), floor(image / 8.0));
	vec2 marge = vec2(0.5 / 81.0, 0.5 / 123.0);
	vec2 uv = (cellule + clamp(UV, marge, vec2(1.0) - marge)) / vec2(8.0, 5.0);
	vec4 feu = texture(animation, uv);
	ALBEDO = feu.rgb;
	EMISSION = feu.rgb * 1.35;
	ALPHA = feu.a * 0.85;
}
