shader_type spatial;
render_mode cull_disabled, depth_draw_never;

uniform sampler2D bruit_surface : repeat_enable, filter_linear;
uniform vec4 couleur_sombre : source_color = vec4(0.055, 0.025, 0.015, 1.0);
uniform vec4 couleur_braise : source_color = vec4(0.95, 0.18, 0.025, 1.0);
uniform float intensite_braises : hint_range(0.0, 3.0) = 0.8;
instance uniform float variation = 0.0;

void fragment() {
	vec2 centre = UV - vec2(0.5);
	vec2 decalage = vec2(variation, variation * 0.37);
	float bruit = texture(bruit_surface, UV + decalage).r;
	// Le bruit déforme doucement le bord et le fondu l'intègre au sol.
	float rayon = 0.39 + (bruit - 0.5) * 0.14;
	float masque = 1.0 - smoothstep(rayon - 0.055, rayon, length(centre));
	float details = texture(bruit_surface, UV * 3.0 + decalage).r;
	// Quelques braises seulement : pas de grandes bandes orange répétées.
	float braise = smoothstep(0.55, 0.74, details);
	ALBEDO = mix(couleur_sombre.rgb, couleur_braise.rgb, braise * 0.5);
	EMISSION = couleur_braise.rgb * braise * intensite_braises;
	ROUGHNESS = 0.95;
	ALPHA = masque * 0.95;
}
