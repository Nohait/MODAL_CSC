shader_type spatial;
render_mode unshaded;
uniform bool incendie = false;
void fragment() {
	vec2 p = UV;
	float vague = sin(p.x * 9.0 + sin(p.y * 7.0 + TIME * 0.5));
	float chaleur = smoothstep(0.0, 1.0, 1.0 - p.y + vague * 0.12);
	float bord = smoothstep(0.0, 0.18, p.x) * smoothstep(0.0, 0.18, 1.0 - p.x);
	vec3 teinte = incendie ? mix(vec3(0.025, 0.018, 0.015), vec3(0.52, 0.13, 0.025), chaleur * bord) : vec3(0.035, 0.055, 0.075);
	ALBEDO = teinte;
	EMISSION = incendie ? teinte * (0.65 + 0.1 * sin(TIME * 2.3)) : vec3(0.0);
}
