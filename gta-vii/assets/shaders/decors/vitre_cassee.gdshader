shader_type spatial;
render_mode blend_mix, depth_draw_never, cull_disabled;

uniform sampler2D vitrage : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosite : filter_linear_mipmap, repeat_enable;
uniform vec4 teinte : source_color = vec4(1.0);
varying vec2 position_vitre;

void vertex() {
	// Les coordonnées du modèle permettent de cibler un carreau sans toucher au cadre.
	position_vitre = VERTEX.xy;
}

void fragment() {
	vec2 impact = position_vitre - vec2(-0.33, 1.38);
	float distance_impact = length(impact);
	float angle = atan(impact.y, impact.x);
	float bord_trou = 0.23 + sin(angle * 5.0) * 0.04 + sin(angle * 9.0) * 0.025;
	if (distance_impact < bord_trou) {
		discard;
	}
	// Des branches blanches prolongent la cassure dans le verre restant.
	float branche = abs(sin(angle * 3.5 + sin(distance_impact * 18.0) * 0.12));
	float fissure = (1.0 - smoothstep(0.015, 0.055, branche))
		* (1.0 - smoothstep(0.3, 0.52, distance_impact));
	vec4 couleur = texture(vitrage, UV) * teinte;
	ALBEDO = mix(couleur.rgb, vec3(0.55, 0.65, 0.68), fissure);
	ALPHA = max(couleur.a, fissure * 0.8);
	ROUGHNESS = mix(texture(rugosite, UV).g, 0.7, fissure);
	NORMAL_MAP = texture(normale, UV).rgb;
}
