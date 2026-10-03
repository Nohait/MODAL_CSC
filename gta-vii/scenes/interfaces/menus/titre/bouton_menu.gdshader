shader_type canvas_item;
uniform float survol = 0.0;
varying vec4 modulation;

void vertex() {
	modulation = COLOR;
}

void fragment() {
	vec4 plaque = texture(TEXTURE, UV);
	float reflet = exp(-pow((UV.x + UV.y * 0.15 - mix(-0.2, 0.8, survol)) / 0.12, 2.0));
	plaque.rgb += vec3(0.24, 0.16, 0.07) * survol + vec3(0.22) * reflet * survol;
	COLOR = plaque * modulation;
}
