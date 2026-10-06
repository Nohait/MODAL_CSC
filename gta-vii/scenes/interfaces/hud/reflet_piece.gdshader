shader_type canvas_item;
uniform float eclat = 0.0;
void fragment() {
	vec4 dessin = texture(TEXTURE, UV) * COLOR;
	float passage = mix(-0.3, 1.3, 1.0 - eclat);
	float reflet = exp(-pow((UV.x + UV.y * 0.15 - passage) / 0.18, 2.0));
	dessin.rgb += vec3(0.8, 0.65, 0.3) * reflet * smoothstep(0.0, 0.15, eclat);
	COLOR = dessin;
}
