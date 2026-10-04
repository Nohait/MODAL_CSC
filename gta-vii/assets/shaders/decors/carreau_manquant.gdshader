shader_type spatial;
render_mode cull_disabled;

uniform sampler2D beton : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normale : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rugosite : filter_linear_mipmap, repeat_enable;

void fragment() {
	// Un bord légèrement ébréché laisse voir la texture du carrelage en dessous.
	vec2 p = abs(UV * 2.0 - 1.0);
	float bord = max(p.x, p.y);
	float ebrechure = sin(UV.x * 57.0) * sin(UV.y * 41.0) * 0.025;
	if (bord > 0.96 + ebrechure) {
		discard;
	}
	float rebord = smoothstep(0.83, 0.95, bord);
	ALBEDO = mix(texture(beton, UV * 0.25).rgb * 0.75, vec3(0.035, 0.03, 0.025), rebord);
	ROUGHNESS = texture(rugosite, UV * 0.25).r;
	NORMAL_MAP = texture(normale, UV * 0.25).rgb;
	NORMAL_MAP_DEPTH = 0.6;
}
