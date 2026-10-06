shader_type spatial;
render_mode unshaded, blend_add, depth_draw_never, cull_disabled;
uniform vec4 teinte : source_color = vec4(0.15, 1.0, 0.65, 1.0);
uniform float puissance = 0.5;
uniform bool aura = false;

float ligne(float valeur, float centre, float largeur) {
	return 1.0 - smoothstep(largeur * 0.4, largeur, abs(valeur - centre));
}
float hash(float n) { return fract(sin(n * 127.1) * 43758.5453); }

void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float angle = atan(p.y, p.x);
	float t = TIME;
	// Le contour reste à la portée réelle ; seuls les ornements circulent.
	float bord = ligne(r, 0.975, aura ? 0.009 : 0.024);
	float halo = exp(-abs(r - 0.975) * (aura ? 65.0 : 30.0)) * 0.2;
	float arcs = smoothstep(0.4, 0.9, sin(angle * 3.0 - t * 0.65));
	float contre_arcs = smoothstep(0.6, 0.95, sin(angle * 4.0 + t * 0.45));
	float filaments = ligne(r, 0.94, 0.008) * arcs + ligne(r, 0.905, 0.005) * contre_arcs * 0.5;
	// Petites ponctuations sur le cercle, plutôt qu'un grand disque opaque.
	float graduations = pow(max(0.0, cos(angle * 24.0)), 22.0) * ligne(r, 0.958, 0.014);
	float souffle = (0.75 + 0.25 * sin(t * 2.0)) * exp(-abs(r - 0.94) * 16.0) * 0.045;
	float braises = 0.0;
	for (int i = 0; i < 12; i++) {
		float n = float(i);
		float phase = fract(t * (0.12 + hash(n + 8.0) * 0.08) + hash(n));
		float a = n * 0.5236 + t * 0.08;
		vec2 position = vec2(cos(a), sin(a)) * (0.93 - phase * 0.07);
		float distance_braise = length(p - position);
		braises += exp(-distance_braise * (aura ? 350.0 : 120.0)) * sin(phase * 3.14159);
	}
	float motif = bord * 0.45 + filaments * 0.8 + graduations * 0.55 + halo + souffle + braises;
	ALBEDO = teinte.rgb;
	// Un coeur pâle dans les traits les plus lumineux, entouré de la couleur de l'aura.
	EMISSION = mix(teinte.rgb * 1.4, vec3(1.0, 0.94, 0.8), clamp(braises * 0.4 + bord * 0.12, 0.0, 0.4));
	ALPHA = clamp(motif * puissance, 0.0, 0.8) * (1.0 - smoothstep(0.985, 1.0, r));
}
