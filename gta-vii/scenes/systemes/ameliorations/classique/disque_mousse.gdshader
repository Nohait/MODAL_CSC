shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never;

uniform vec4 couleur : source_color = vec4(0.65, 0.95, 0.86, 0.8);
uniform float progression : hint_range(0.0, 1.0) = 0.0;

float grain(vec2 p) {
	return fract(sin(dot(p, vec2(127.1, 311.7))) * 43758.5453);
}

float bruit(vec2 p) {
	vec2 i = floor(p);
	vec2 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(grain(i), grain(i + vec2(1.0, 0.0)), f.x),
		mix(grain(i + vec2(0.0, 1.0)), grain(i + vec2(1.0)), f.x), f.y);
}

void fragment() {
	vec2 p = (UV - 0.5) * 2.0;
	float r = length(p);
	float front = mix(0.03, 1.0, 1.0 - pow(1.0 - progression, 3.0));
	float relief = bruit(p * 19.0 + progression * 1.4);
	float bord = front - (1.0 - relief) * 0.055;
	float disque = 1.0 - smoothstep(bord - 0.05, bord, r);
	float couronne = smoothstep(front - 0.23, front - 0.1, r);
	float fondu = 1.0 - smoothstep(0.45, 1.0, progression);
	ALBEDO = mix(couleur.rgb, vec3(0.94, 1.0, 0.98), relief * 0.7);
	ALPHA = disque * (0.18 + couronne * 0.72) * (0.45 + relief * 0.55) * fondu * couleur.a;
}
